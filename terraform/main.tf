locals {
  bq_export_bucket = "${var.project_id}-bq_export_bucket"
  ee_export_bucket = "${var.project_id}-ee_export_bucket"
  cron_topic="${var.project_id}-cron_topic"
}
/******************************************
1. Project Services Configuration
 *****************************************/
module "activate_service_apis" {
  source                      = "terraform-google-modules/project-factory/google//modules/project_services"
  project_id                  = var.project_id
  enable_apis                 = true

  activate_apis = [
    "orgpolicy.googleapis.com",
    "compute.googleapis.com",
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "earthengine.googleapis.com",
    "cloudfunctions.googleapis.com",
    "pubsub.googleapis.com"
  ]

  disable_services_on_destroy = false
  
}

/******************************************
2. Create 2 Storge Buckets
 *****************************************/

resource "google_storage_bucket" "bq_export_bucket" {
  name                              = local.bq_export_bucket
  location                          = var.region
  uniform_bucket_level_access       = true
  force_destroy                     = true
}

resource "google_storage_bucket" "ee_export_bucket" {
  name                              = local.ee_export_bucket
  location                          = var.region
  uniform_bucket_level_access       = true
  force_destroy                     = true
}

/******************************************
3. Create a pubsub topic
 *****************************************/
resource "google_pubsub_topic" "bq_export_topic" {
  name = "cron-bq-export-topic"

  labels = {
    job = "cron bq to gcs"
  }

  message_retention_duration = "86600s"
}

/******************************************
4.Create a cloud scheduler
 *****************************************/
resource "google_cloud_scheduler_job" "job" {
  name        = "cron-bq-export-job"
  description = "bq export job"
  schedule    = "* * * * *"
  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.bq_export_topic.id
    data       = base64encode("test")
  }
}
/******************************************
5. Create cloud functions
 *****************************************/
resource "google_storage_bucket" "function_bucket" {
    name     = "${var.project_id}-function"
    location = var.region
    uniform_bucket_level_access       = true
    force_destroy                     = true
}

data "archive_file" "bq_export_source" {
    type        = "zip"
    source_dir  = "../src/bq_export"
    output_path = "tmp/bq_export_function.zip"
}


data "archive_file" "ee_upload_source" {
    type        = "zip"
    source_dir  = "../src/ee_upload"
    output_path = "tmp/ee_upload_function.zip"
}

# Add source code zip to the Cloud Function's bucket
resource "google_storage_bucket_object" "bq_export_zip" {
    source       = data.archive_file.bq_export_source.output_path
    content_type = "application/zip"

    # Append to the MD5 checksum of the files's content
    # to force the zip to be updated as soon as a change occurs
    name         = "src-${data.archive_file.bq_export_source.output_md5}.zip"
    bucket       = google_storage_bucket.function_bucket.name

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on   = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        data.archive_file.bq_export_source
    ]
}

# Add source code zip to the Cloud Function's bucket
resource "google_storage_bucket_object" "ee_upload_zip" {
    source       = data.archive_file.ee_upload_source.output_path
    content_type = "application/zip"

    # Append to the MD5 checksum of the files's content
    # to force the zip to be updated as soon as a change occurs
    name         = "src-${data.archive_file.ee_upload_source.output_md5}.zip"
    bucket       = google_storage_bucket.function_bucket.name

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on   = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        data.archive_file.ee_upload_source
    ]
}


# Create the Cloud function triggered by a `Finalize` event on the bucket
resource "google_cloudfunctions_function" "bq_export_function" {
    name                  = "bq-export-to-gcs"
    runtime               = "python39"  # of course changeable

    # Get the source code of the cloud function as a Zip compression
    source_archive_bucket = google_storage_bucket.function_bucket.name
    source_archive_object = google_storage_bucket_object.bq_export_zip.name

    # Must match the function name in the cloud function `main.py` source code
    entry_point           = "bq_to_gcs"
    
    # 
    event_trigger {
      event_type= "google.pubsub.topic.publish"
      resource= "projects/${var.project_id}/${local.cron_topic}"
      #service= "pubsub.googleapis.com"
   }

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on            = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        google_storage_bucket_object.bq_export_zip
    ]
}


# Create the Cloud function triggered by a pubsub
resource "google_cloudfunctions_function" "ee_upload_function" {
    name                  = "ee-upload-from-gcs"
    runtime               = "python39"  # of course changeable

    # Get the source code of the cloud function as a Zip compression
    source_archive_bucket = google_storage_bucket.function_bucket.name
    source_archive_object = google_storage_bucket_object.ee_upload_zip.name

    # Must match the function name in the cloud function `main.py` source code
    entry_point           = "gcs_to_ee"
    
    # 
    event_trigger {
        event_type = "google.storage.object.finalize"
        resource   = local.bq_export_bucket
    }

    # Dependencies are automatically inferred so these lines can be deleted
    depends_on            = [
        google_storage_bucket.function_bucket,  # declared in `storage.tf`
        google_storage_bucket_object.ee_upload_zip
    ]
}
/******************************************
6. Create BigQuery Dataset
 *****************************************/

resource "google_bigquery_dataset" "ee_dataset" {
  dataset_id                  = "ee_dataset"
  friendly_name               = "ee_dataset"
  description                 = "This is a earth engine dataset"
  location                    = var.region
  default_table_expiration_ms = 3600000

  labels = {
    env = "default"
  }

  access {
    role          = "EDITOR"
    user_by_email = "${var.project_id}@appspot.gserviceaccount.com"
  }

}


/******************************************
7. Upload csv file to bigquery table
 *****************************************/

 resource "null_resource" "import_csv_to_bq" {
  provisioner "local-exec" {
    command = <<-EOT
    bq load --source_format=CSV --allow_quoted_newlines=true --field_delimiter='|' ${google_bigquery_dataset.ee_dataset} plantboundaries.csv Geography:string
  EOT
  }

  depends_on = [google_bigquery_dataset.ee_dataset]
}
