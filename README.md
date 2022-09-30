# BigQuery to Earth Engine automation with Cloud Function

## 1. Sign-up Earth Engine
Sign up with the project owner/admin email account
-   [Earth Engine Sign-up](https://signup.earthengine.google.com/#!/)

## 2. Provision artifacts for demo
Go to cloud shell, run the following commands
```shellcript
cd $HOME
git clone https://github.com/GoogleCloudPlatform/earthengine-bigquery-automation-demo.git
cd $HOME/earthengine-bigquery-automation-demo && chmod +x start.sh
./start.sh
```
If something goes wrong, run ./start/sh again.

Set permissions
- Sign up with the service account with Earth Engine
- [Earth Engine Service account Sign-up](https://signup.earthengine.google.com/#!/service_accounts)
- Go to Service Accounts under IAM in your cloud project
- Identify the service account named 'App Engine default service account' and copy the email address
- In Earth Engine registration sign-up screen, enter the service account email in box: Register a new service account for XXXX,
  click "Register service account" button, the service account will show up in the Current service accounts list


Validation steps:
- Go to BigQuery console, check the dataset and table created. 
- Go to Cloud Scheduler screen, run the job task manually
- Go to Cloud storage, and check the PROJECT_ID-bq_export_bucket, verify one csv file created with current date as file name( Month-DD-YYYY)

## 3. Open Earth Engine Code Editor and connect to GCP project
-   [Web Code Editor](https://code.earthengine.google.com/)
When prompted user, use the project owner who has signed-up the earth engine. 
Click the user/profile Icon on top right screen, 
Click Choose Cloud Project, choose "select existing project", choose the cloud project from dropdown list
Validation steps:
- Code Editor console, click the Asset tab, verify there is asset listed under PROJECT_ID with name of MONTH-DD-YYYY

## 4. Earth Engine analysis with in Code Editor
### run base script in Code Editor
Create a script
- Click Script tab in Code Editor console. Create a new Script, give name as app.js (you may need to create a folder first when prompt to do so)
- Copy the contents of cloud shell $HOME/earthengine-bigquery-automation-demo/ee_app.js to app.js in Code Editor screen
- Change line 10 with proper values for PROJECT_ID 
<!--- - Change line 11 with proper values for ASSET_ID (check the asset tab from Code Editor) --->
- Click Save and Run button in Code Editor console
- Verify no error, and you can see the polygon areas created. 

### run advanced analytics script in Code Editor
Create a script
- Click Script tab in Code Editor console. Create a new Script, give name as adavanceAnalytics.js
- Copy the contents of cloud shell $HOME/earthengine-bigquery-automation-demoo/ee_advanceAnlytics.js to advanceAnalytics.js in Code Editor screen
- Change line 9 and line 13 with proper values for PROJECT_ID 
<!--- - Change line 110 with proper values for ASSET_ID (check the asset tab from Code Editor) --->
- Click Save and Run button in Code Editor console
- Verify no error, and you can see the polygon areas created. 
- Click Tasks tab( with yellow color in top right panel), click Run button.
- After task run completed, go to Cloud Storage bucket PROJECT_ID-ee_export_bucket and verify file created

## 5. Create Earth Engine apps
Update link for app.js
- From advanceAnalytics.js in Code Editor, click Get Link dropdown, click Copy script path,
- Switch to app.js in Code Editor, in line 14, replace the ADVANCE_URL with script path just copied. Save app.js

Create apps for app.js
- Click apps from app.js Code Editor
- Click New App
- Provide App Name, Choose Existing Project
- In source code step, choose Repository script Path.
- In next screen, type in app.js.
- Click Next, and then Publish
- In next screen, there will be URL link below the app-name. Validate the URL works after a minute

Set permissions
- Go to Service Accounts under IAM in your cloud project
- Identify the service account named 'Service Account for Earth Engine App' and copy the email address
- On the IAM page, click Add
- Set New Principal: copied email address and Role: Earth Engine Resource Viewer

Validations:
- Open the app link
- Click "Advanced Analytics" button in right panel
- A separate window will open 
- Click the Run button, 
- Check on/off different Tree Cover layers

## Congratulations! Demo completed successfully

