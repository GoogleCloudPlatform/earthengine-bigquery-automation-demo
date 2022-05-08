# earth-engine-demo

## 1. Sign-up Earth Engine
Sign up with the project owner/admin email account
-   [Earth Engine Sign-up](https://signup.earthengine.google.com/#!/)

## 2. Provision artifacts for demo
Go to cloud shell, run the following commands
```shellcript
cd $HOME
git clone https://github.com/rick-c-goog/earth-engine-demo.git
cd $HOME/earth-engine-demo && chmod +x start.sh
./start.sh
```
If something goes wrong, run ./start/sh again.

Validation steps:
- Go to BigQuery console, check the dataset and table created. 
- Go to Cloud Scheduler screen, run the job task manually
- Go to Cloud storage, and check the PROJECT_ID-bq_export_bucket, verify one cs file created with current date as file name( Month-DD-YYYY)

## 3. Authenticate earth engine and import an asset
In cloud shell, authenticate earthengine
```shellcript
cd .local/bin
./earthengine authenticate
```

Then run the following script to create asset
```shellcript
cd $HOME/earth-engine-demo && chmod +x create_ee_asset.sh
./create_ee_asset.sh
```

## 4. Open Earth Engine Code Editor and connect to GCP project
-   [Web Code Editor](https://code.earthengine.google.com/)
When prompted user, use the project owner who has signed-up the earth engine. 
Click the user/profile Icon on top right screen, 
Ckick Choose Cloud Project, choose "select existing project", choose the cloud project from dropdown list
Validation steps:
- Code Editor console, click the Asset tab, verify there is asset listed under PROJECT_ID with name of MONTH-DD-YYYY

## 5. Earth Engine analysis with in Code Editor
### run base script in Code Editor
Create a script
- Click Script tab in Code Editor console. Create a new Script, give name as app.js( you may need to create a folder first when prompt to do so)
- Copy the contents of cloud shell $HOME/earth-engine-demo/ee_app.js to app.js in Code Editor screen
- Change line 10 with proper values for PROJECT_ID 
- Change line 11 with proper values for ASSET_ID (check the asset tab from Code Editor)
- Click Save and Run button in Code Editor console
- Verify no error, and you can see the polygon areas created. 

### run advanced analytics script in Code Editor
Create a script
- Click Script tab in Code Editor console. Create a new Script, give name as adavanceAnalytics.js
- Copy the contents of cloud shell $HOME/earth-engine-demo/ee_advanceAnlytics.js to advanceAnalytics.js in Code Editor screen
- Change line 9 and line 13 with proper values for PROJECT_ID 
- Change line 110 with proper values for ASSET_ID (check the asset tab from Code Editor)
- Click Save and Run button in Code Editor console
- Verify no error, and you can see the polygon areas created. 
- Click Tasks tab( with yellow color in top right panel), click Run button.
- After task run completed, go to Cloud Storage bucket PROJECT_ID-ee_export_bucket and verify file created

## 6. Create Earth Engine apps

