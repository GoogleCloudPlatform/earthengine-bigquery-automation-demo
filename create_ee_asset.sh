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
 
PROJECT_ID=$(gcloud config get-value project)
cd $HOME/.local/bin
./earthengine upload table --asset_id=projects/$PROJECT_ID/assets/May-8-2022 gs://$PROJECT_ID-bq_export_bucket/May-08-2022.csv --wait --force --csv_delimiter '|'
