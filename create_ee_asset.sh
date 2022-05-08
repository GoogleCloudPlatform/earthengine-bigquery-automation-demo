PROJECT_ID=$(gcloud config get-value project)
cd $HOME/.local/bin
./earthengine upload table --asset_id=projects/$PROJECT_ID/assets/May-8-2022 gs://$PROJECT_ID-bq_export_bucket/May-08-2022.csv --wait --force --csv_delimiter '|'
