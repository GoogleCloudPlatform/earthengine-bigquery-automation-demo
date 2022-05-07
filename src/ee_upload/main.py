import ee
import google.auth


def gcs_to_ee(event, context):
  """Creates an Earth Engine asset from data in Cloud Storage.

  When an object is created in a specified Cloud Storage Bucket, an Earth Engine
  Task that creates an asset from that object.

  Args:
    event: Event payload.
  """
  # Get GCS location of file creation that triggered function
  project_id = "MY_PROJECT_ID"
  file = event
  path = "gs://" + file["bucket"] + "/" + file["name"]
  file_title = file["name"].rsplit(".", 1)[0]

  # Set up auth
  service_account = 'earth-engine-sa@rick-geo-enterprise.iam.gserviceaccount.com'
  credentials = ee.ServiceAccountCredentials(service_account, '.private-key.json')
  ee.Initialize(credentials)

  # Create request id
  request_id = ee.data.newTaskId()
  request_id = request_id[0]

  # Create params for ingestion
  name = "projects/"+ project_id +"/assets/" + file_title
  sources = [
      {
          "uris": [path],
          "csvDelimiter": "|"
      },
  ]
  params = {"name": name, "sources": sources}

  # Start ingestion
  ee.data.startTableIngestion(
      request_id, params, allow_overwrite=True)