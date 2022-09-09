/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
locals {
  bq_export_bucket = "${var.project_id}-bq_export_bucket"
  ee_export_bucket = "${var.project_id}-ee_export_bucket"
  cron_topic="${var.project_id}-cron_topic"
  dataset_id="earth_engine_demo"
  table_id="plantboundaries"
  
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
    "pubsub.googleapis.com",
    "cloudscheduler.googleapis.com",
    "cloudbuild.googleapis.com"
  ]

  disable_services_on_destroy = false
  
}

resource "time_sleep" "sleep_after_activate_service_apis" {
  create_duration = "60s"

  depends_on = [
    module.activate_service_apis
  ]
}

/******************************************
2. Project-scoped Org Policy Relaxing
*****************************************/

module "org_policy_allow_ingress_settings" {
source = "terraform-google-modules/org-policy/google"
policy_for = "project"
project_id = var.project_id
constraint = "constraints/cloudfunctions.allowedIngressSettings"
policy_type = "list"
enforce = false
allow= ["IngressSettings.ALLOW_ALL"]
depends_on = [
time_sleep.sleep_after_activate_service_apis
]
}

module "org_policy_allow_domain_membership" {
source = "terraform-google-modules/org-policy/google"
policy_for = "project"
project_id = var.project_id
constraint = "constraints/iam.allowedPolicyMemberDomains"
policy_type = "list"
enforce = false
depends_on = [
time_sleep.sleep_after_activate_service_apis
]
}

/******************************************
3. Create 2 Storge Buckets
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
4. Create a pubsub topic
 *****************************************/
resource "google_pubsub_topic" "bq_export_topic" {
  name = local.cron_topic

  labels = {
    job = "cron-job"
  }

  message_retention_duration = "86600s"
}

/******************************************
5.Create a cloud scheduler
 *****************************************/
resource "google_cloud_scheduler_job" "job" {
  name        = "cron-bq-export-job"
  description = "bq export job"
  schedule    = "0 12 * * SUN"
  pubsub_target {
    # topic.id is the topic's full resource name.
    topic_name = google_pubsub_topic.bq_export_topic.id
    data       = base64encode("test")
  }
}
/******************************************
6. Create cloud functions
 *****************************************/
resource "google_storage_bucket" "function_bucket" {
    name     = "${var.project_id}-function"
    location = var.region
    uniform_bucket_level_access       = true
    force_destroy                     = true
}
#clean up the main.py variables
resource "null_resource" "clean_up_main_python" {
  provisioner "local-exec" {
    command = <<-EOT
    sed -i "s|PROJECT_ID|${var.project_id}|g" ../src/bq_export/main.py 
    sed -i "s|BUCKET_NAME|${local.bq_export_bucket}|g" ../src/bq_export/main.py 
    sed -i "s|DATASET_ID|${local.dataset_id}|g" ../src/bq_export/main.py 
    sed -i "s|TABLE_ID|${local.table_id}|g" ../src/bq_export/main.py 
    sed -i "s|PROJECT_ID|${var.project_id}|g" ../src/ee_upload/main.py 
   EOT
  }

  depends_on = [google_bigquery_dataset.ee_dataset]
}

data "archive_file" "bq_export_source" {
    type        = "zip"
    source_dir  = "../src/bq_export"
    output_path = "tmp/bq_export_function.zip"
    depends_on   = [ 
        null_resource.clean_up_main_python
    ]
}


data "archive_file" "ee_upload_source" {
    type        = "zip"
    source_dir  = "../src/ee_upload"
    output_path = "tmp/ee_upload_function.zip"
    depends_on   = [ 
        null_resource.clean_up_main_python
    ]
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
      resource= "${local.cron_topic}"
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
7. Create BigQuery Dataset
 *****************************************/

resource "google_bigquery_dataset" "ee_dataset" {
  dataset_id                  = local.dataset_id
  friendly_name               = "ee_dataset"
  description                 = "This is a earth engine dataset"
  location                    = var.region
  default_table_expiration_ms = 604800000

  labels = {
    env = "default"
  }

}


/******************************************
8. Upload csv file to bigquery table
 *****************************************/

 resource "null_resource" "import_csv_to_bq" {
  provisioner "local-exec" {
    command = <<-EOT
    bq load --source_format=CSV --allow_quoted_newlines=true --field_delimiter='|' ${local.dataset_id}.${local.table_id} ${local.table_id}.csv Geography:string
  EOT
  }

  depends_on = [google_bigquery_dataset.ee_dataset]
}

/******************************************
9. Create earth engine service account
 *****************************************/
resource "google_service_account" "earth_engine_sa" {
  account_id   = "earth-engine-demo-sa"
  display_name = "A service account that for earth engine"
}


/******************************************
10. Cloud function SA IAM policy bindings
 *****************************************/
resource "google_project_iam_binding" "set_storage_binding" {
  project = var.project_id
  role               = "roles/storage.admin"
  members  =  ["serviceAccount:${var.project_id}@appspot.gserviceaccount.com"]
  
}

resource "google_project_iam_binding" "set_bq_data_binding" {
  project = var.project_id
  role               = "roles/bigquery.dataEditor"
  members  =  ["serviceAccount:${var.project_id}@appspot.gserviceaccount.com"]
  
}

resource "google_project_iam_binding" "set_bq_jb_binding" {
  project = var.project_id
  role               = "roles/bigquery.jobUser"
  members  =  ["serviceAccount:${var.project_id}@appspot.gserviceaccount.com"]
  
}
# Gets the default Compute Engine Service Account of GKE
data "google_project" "project" {
  project_id = var.project_id
}

data "google_compute_default_service_account" "default" {
  project = data.google_project.project.project_id
}

resource "google_project_iam_binding" "set_ee_binding" {
  project = var.project_id
  role               = "roles/earthengine.writer"
  members  =  ["serviceAccount:${data.google_compute_default_service_account.default.email}"]

}

/******************************************
11. Earth Engine Python API installation
 *****************************************/
resource "null_resource" "earth_engine_python_Api" {
  provisioner "local-exec" {
    command = <<-EOT
    pip install earthengine-api --upgrade
  EOT
  }

  depends_on = [google_bigquery_dataset.ee_dataset]
}
