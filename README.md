# GCP Scout Suite example

Runs Scout Suite and puts report in GCS bucket

## GCP Environment setup

Clone this repository

```sh
git clone https://github.com/icraytho/gcp-scoutsuite.git
cd gcp-scoutsuite
export WORKING_DIR=$(pwd)
```

Set PROJECT_ID, REGION, and GCP Domain

```sh
export REGION=asia-southeast1
export PROJECT_ID=<YOUR-PROJECT_ID>
export GCP_DOMAIN=<YOUR_GCP_ORG_DOMAIN>

gcloud config set project "${PROJECT_ID}"
```

## Terraform init, plan and apply

Use Terraform to provision the Scout Suite container and generate reports

```
export TF_VAR_gcp_domain=${GCP_DOMAIN}
export TF_VAR_project_id=${PROJECT_ID}

cd ${WORKING_DIR}
terraform init
terraform plan
terraform apply
```

## Get the Scout Suite Report

The result report is put in a GCS Bucket. Go to your bucket and open a public access url for `gcp-user-account.html`

```bash
terraform output -raw scoutsuite_report_url
```

```bash
echo "Open a report at URL: https://storage.googleapis.com/${PROJECT_ID}-scoutsuite/reports/gcp-user-account.html"
```

## Clean up

Delete all provisioned resource by using Terraform destroy

```
terraform destroy
```

-------

This is not an official Google product.