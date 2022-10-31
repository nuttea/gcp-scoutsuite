# GCP Scout Suite example

Run Scout Suite and put report in GCS

## GCP Environment setup

Clone this repository

```sh
git clone https://github.com/nuttea/gcp-scoutsuite.git
cd gcp-scoutsuite
export WORKING_DIR=$(pwd)
```

Set PROJECT_ID, REGION, and GCP Domain

```sh
REGION=asia-southeast1

echo "Get the project id"
gcloud config set project "<YOUR-PROJECT_ID>"
export PROJECT_ID=$(gcloud config get-value project)
export GCP_DOMAIN=<YOUR_GCP_ORG_DOMAIN>
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

- Open the Cloud Storage page in the Google Cloud console.
- Open the GCS Bucket provisioned by Terraform (ex. "<YOUR PROJECT ID>-scoutsuite")
- Go to folder `reports` and copy public URL of `gcp-user-account.html` and open in your web browser.

## Clean up

Delete all provisioned resource by using Terraform destroy

```
terraform destroy
```

-------

This is not an official Google product.