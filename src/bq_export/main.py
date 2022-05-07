"""Generates a CSV from a Big Query Table."""
import datetime
import google.cloud
import google.cloud.bigquery

def bq_to_gcs(event, context):
  """Generates CSV from Big Query Table and places it in Cloud Storage bucket."""
  client = google.cloud.bigquery.Client()

  # Set the necessary values for Big Query Assets
  bucket_name = "ee_export_bucket"
  project = "rick-geo-enterprise"
  dataset_id = "earth_engine_demo"
  table_id = "plantboundaries"

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
