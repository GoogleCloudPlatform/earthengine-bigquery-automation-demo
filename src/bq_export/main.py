"""
Copyright 2022 Google LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
 
      http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

"""Generates a CSV from a Big Query Table."""
import datetime
import google.cloud
import google.cloud.bigquery

def bq_to_gcs(event, context):
  """Generates CSV from Big Query Table and places it in Cloud Storage bucket."""
  client = google.cloud.bigquery.Client()

  # Set the necessary values for Big Query Assets
  bucket_name = "BUCKET_NAME"
  project = "PROJECT_ID"
  dataset_id = "DATASET_ID"
  table_id = "TABLE_ID"

  # Create params for ingestion
  # Month abbreviation, day and year
  today = datetime.date.today()
  import_date = today.strftime("%b-%-d-%Y")
  print("import_date= ", import_date)

  destination_uri = "gs://{}/{}".format(bucket_name, import_date + ".csv")
  dataset_ref = google.cloud.bigquery.DatasetReference(project, dataset_id)
  table_ref = dataset_ref.table(table_id)

  extract_job = client.extract_table(
      table_ref,
      destination_uri,
      # Location must match that of the source table.
      location="us-east1",
  )  # API request
  extract_job.result()  # Waits for job to complete
