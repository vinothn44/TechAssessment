# TechAssessment

Azure Integration Devloper Tech Assessment

**Design a simple integration to process student Records**

**Naming conventions:**

**Logic app name** : lap-uop-eas-sis
**Service bus namespace** : sbns-uop-admissionsystem

**Abbreviation:**

lap - logicapp 

uop - University of portsmouth

eas - [sourcesystem] - External Admission system

sis - [destinationsystem] - Student Information system

sbns - service bus namespace
  

**Logic App Design**

**Receive requests in Logic App using an HTTP trigger**


  <img width="1003" height="429" alt="image" src="https://github.com/user-attachments/assets/121c4862-ad8b-49ae-9181-9ecbbffbecba" />

  


**Initialize Translation Table for CourseMapping**


  <img width="584" height="294" alt="image" src="https://github.com/user-attachments/assets/989a5b3b-9ae4-4a5a-b76d-e573e95d83d4" />

  

**Validation for Each student record**

  
  <img width="1486" height="424" alt="image" src="https://github.com/user-attachments/assets/9aad7067-3e8b-4f6b-bec1-b0da9b970749" />

  

**If any validation issues**

  Eg: Missing email, surname, forename, duplicate student id, append in variable with reason

  
  <img width="1477" height="437" alt="image" src="https://github.com/user-attachments/assets/d1a4bafb-68db-483a-8e2f-89fc0477c764" />

  
  
  Example : 

  
  <img width="672" height="368" alt="image" src="https://github.com/user-attachments/assets/f416545a-9b7f-4959-b974-2dd037767acc" />

  

**If condition satisfied, apply transformation**

  
  _Transform Condition_

  
  <img width="1009" height="325" alt="image" src="https://github.com/user-attachments/assets/f2fa7c19-7532-41cb-8079-3493b9217074" />

  
  
  _Transformed Message_

  <img width="987" height="471" alt="image" src="https://github.com/user-attachments/assets/cce4a065-9435-4705-99d6-07d9e81aa376" />

  
  **Messages send to Queue**

  
  <img width="1156" height="370" alt="image" src="https://github.com/user-attachments/assets/33c581df-897c-4309-b9cc-515bff3b0823" />

  
  
  _Queued message_

  
  <img width="1880" height="829" alt="image" src="https://github.com/user-attachments/assets/c63e9510-49d0-4616-a039-297e88b1c199" />

  
  
  Exception Handling:

  Eg: If provided wrong queue name : 
  Logged the error code and status 

  
  <img width="1091" height="558" alt="image" src="https://github.com/user-attachments/assets/083537fb-87ee-4dbe-b2fc-d9d45e87c67b" />

  
  
  For testing purpose, logged the no of failed records/students, this can be fine tuned for logging and send error alert to operations team with reason 

  
  <img width="1549" height="536" alt="image" src="https://github.com/user-attachments/assets/d29ee584-6c4a-40ea-a3b6-ff731153aa96" />





  







