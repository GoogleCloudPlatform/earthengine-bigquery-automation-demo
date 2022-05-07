PROJECT_ID=[your_project_id]
cd terraform
sed -i "s|PROJECT_ID|$PROJECT_ID|g" terraform.tfvars 
terraform init
terraform apply --auto-approve