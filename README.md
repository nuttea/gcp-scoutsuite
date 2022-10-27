# GCP Scout Suite example

Run Scout Suite and put report in GCS

## GCP Environment setup

Clone this repository

```sh
git clone https://github.com/nuttea/gcp-scoutsuite.git
cd gcp-scoutsuite
export WORKING_DIR=$(pwd)
```

Set PROJECT_ID, REGION

```sh
REGION=asia-southeast1

echo "Get the project id"
gcloud config set project "<YOUR-PROJECT_ID>"
export PROJECT_ID=$(gcloud config get-value project)
```

## Terraform init, plan and apply

Use Terraform to provision the Scout Suite container and generate reports

```
export TF_VAR_gcp_domain=<YOUR_GCP_ORG_DOMAIN>
export TF_VAR_project_id=${PROJECT_ID}

cd ${WORKING_DIR}
terraform init
terraform plan
terraform apply
```


-------

This is not an official Google product.