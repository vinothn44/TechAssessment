param workflows_lap_uop_eas_sis_name string = 'lap-uop-eas-sis'
param connections_servicebus_externalid string = '/subscriptions/b770aa35-cb10-4aae-8076-718603ac0617/resourceGroups/rg-uop-studentinformation/providers/Microsoft.Web/connections/servicebus'

resource workflows_lap_uop_eas_sis_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: workflows_lap_uop_eas_sis_name
  location: 'centralindia'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'array'
              items: {
                type: 'object'
                properties: {
                  student_id: {
                    type: 'string'
                  }
                  forename: {
                    type: 'string'
                  }
                  surname: {
                    type: 'string'
                  }
                  course: {
                    type: 'string'
                  }
                  email_address: {
                    type: 'string'
                  }
                }
              }
            }
          }
        }
      }
      actions: {
        Initialize_exceptions: {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'courseMap'
                type: 'object'
                value: {
                  'BSc Computer Science': 'BCS'
                  'BSc Business Studies': 'BBS'
                  'BSc Psychology': 'BPS'
                }
              }
              {
                name: 'seenIds'
                type: 'array'
                value: []
              }
              {
                name: 'validTransformed'
                type: 'array'
                value: []
              }
              {
                name: 'exceptions'
                type: 'array'
                value: []
              }
            ]
          }
        }
        Try: {
          actions: {
            For_each_Validate_And_Transform: {
              foreach: '@triggerBody()'
              actions: {
                Condition_Is_Invalid: {
                  actions: {
                    Compose_Reason: {
                      type: 'Compose'
                      inputs: '@if(contains(variables(\'seenIds\'), item()?[\'student_id\']), concat(\'Duplicate student_id: \', item()?[\'student_id\']), if(empty(item()?[\'student_id\']), \'Missing mandatory field: student_id\', if(empty(item()?[\'forename\']), \'Missing mandatory field: forename\', if(empty(item()?[\'surname\']), \'Missing mandatory field: surname\', if(empty(item()?[\'email_address\']), \'Missing mandatory field: email_address\', concat(\'Unknown course mapping: \', item()?[\'course\']))))))'
                    }
                    Append_to_exceptions: {
                      runAfter: {
                        Compose_Reason: [
                          'Succeeded'
                        ]
                      }
                      type: 'AppendToArrayVariable'
                      inputs: {
                        name: 'exceptions'
                        value: {
                          student_id: '@item()?[\'student_id\']'
                          reason: '@outputs(\'Compose_Reason\')'
                        }
                      }
                    }
                  }
                  else: {
                    actions: {
                      Compose_TransformedRecord: {
                        type: 'Compose'
                        inputs: {
                          studentNumber: '@item()?[\'student_id\']'
                          fullName: '@{concat(item()?[\'forename\'], \' \', item()?[\'surname\'])}'
                          courseCode: '@{variables(\'courseMap\')?[item()?[\'course\']]}'
                          email: '@item()?[\'email_address\']'
                          status: 'Active'
                        }
                      }
                      Append_to_validTransformed: {
                        runAfter: {
                          Compose_TransformedRecord: [
                            'Succeeded'
                          ]
                        }
                        type: 'AppendToArrayVariable'
                        inputs: {
                          name: 'validTransformed'
                          value: '@outputs(\'Compose_TransformedRecord\')'
                        }
                      }
                      Append_to_seenIds: {
                        runAfter: {
                          Append_to_validTransformed: [
                            'Succeeded'
                          ]
                        }
                        type: 'AppendToArrayVariable'
                        inputs: {
                          name: 'seenIds'
                          value: '@item()?[\'student_id\']'
                        }
                      }
                    }
                  }
                  expression: {
                    or: [
                      {
                        equals: [
                          '@contains(variables(\'seenIds\'), item()?[\'student_id\'])'
                          true
                        ]
                      }
                      {
                        equals: [
                          '@empty(item()?[\'student_id\'])'
                          true
                        ]
                      }
                      {
                        equals: [
                          '@empty(item()?[\'forename\'])'
                          true
                        ]
                      }
                      {
                        equals: [
                          '@empty(item()?[\'surname\'])'
                          true
                        ]
                      }
                      {
                        equals: [
                          '@empty(item()?[\'email_address\'])'
                          true
                        ]
                      }
                      {
                        equals: [
                          '@equals(variables(\'courseMap\')?[item()?[\'course\']], null)'
                          true
                        ]
                      }
                    ]
                  }
                  type: 'If'
                }
              }
              type: 'Foreach'
              runtimeConfiguration: {
                concurrency: {
                  repetitions: 1
                }
              }
            }
            Response_ExceptionReport: {
              runAfter: {
                Send_message: [
                  'Succeeded'
                ]
              }
              type: 'Response'
              kind: 'Http'
              inputs: {
                statusCode: 200
                body: {
                  successCount: '@length(variables(\'validTransformed\'))'
                  exceptionCount: '@length(variables(\'exceptions\'))'
                  exceptions: '@variables(\'exceptions\')'
                }
              }
            }
            Send_message: {
              runAfter: {
                For_each_Validate_And_Transform: [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
                  }
                }
                method: 'post'
                body: {
                  ContentData: '@base64(variables(\'validTransformed\'))'
                }
                path: '/@{encodeURIComponent(encodeURIComponent(\'enrolment-processed\'))}/messages'
                queries: {
                  systemProperties: 'None'
                }
              }
            }
            Condition: {
              actions: {
                Compose: {
                  type: 'Compose'
                  inputs: '@variables(\'exceptions\')'
                }
                Terminate: {
                  runAfter: {
                    Compose: [
                      'Succeeded'
                    ]
                  }
                  type: 'Terminate'
                  inputs: {
                    runStatus: 'Failed'
                    runError: {
                      code: '500'
                      message: 'Invalid record for @{length(variables(\'exceptions\'))} students'
                    }
                  }
                }
              }
              runAfter: {
                Response_ExceptionReport: [
                  'Succeeded'
                ]
              }
              else: {
                actions: {}
              }
              expression: {
                and: [
                  {
                    greaterOrEquals: [
                      '@length(variables(\'exceptions\'))'
                      1
                    ]
                  }
                ]
              }
              type: 'If'
            }
          }
          runAfter: {
            Initialize_exceptions: [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
        Catch: {
          actions: {
            Filter_array: {
              type: 'Query'
              inputs: {
                from: '@result(\'Try\')'
                where: '@equals(item()[\'status\'], \'Failed\')'
              }
            }
            Error_Message: {
              runAfter: {
                Get_Error: [
                  'Succeeded'
                ]
              }
              type: 'Compose'
              inputs: {
                ErrorCode: '@{outputs(\'Get_Error\')?[0]?[\'outputs\']?[\'body\']?[\'status\']}'
                ErrorMessage: '@{outputs(\'Get_Error\')?[0]?[\'outputs\']?[\'body\']?[\'message\']}'
              }
            }
            Get_Error: {
              runAfter: {
                Filter_array: [
                  'Succeeded'
                ]
              }
              type: 'Compose'
              inputs: '@body(\'Filter_array\')'
            }
          }
          runAfter: {
            Try: [
              'Failed'
              'TimedOut'
              'Skipped'
            ]
          }
          type: 'Scope'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            id: '/subscriptions/b770aa35-cb10-4aae-8076-718603ac0617/providers/Microsoft.Web/locations/centralindia/managedApis/servicebus'
            connectionId: connections_servicebus_externalid
            connectionName: 'servicebus'
            connectionProperties: {
              authentication: {
                type: 'ManagedServiceIdentity'
              }
            }
          }
        }
      }
    }
  }
}
