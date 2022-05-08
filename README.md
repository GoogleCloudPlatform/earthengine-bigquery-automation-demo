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

## 5. Earth Engine analysis with in Code Editor
### run base script in Code Editor






