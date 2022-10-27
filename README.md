# Eventarc trigger Cloud Workflows Service chaining to Cloud Function and Cloud Run

In this sample, you will create Eventarc triggers to trigger from Cloud Storage and PubSub event, which will then trigger a workflow to orchestrate multiple Cloud Functions, Cloud Run and external services in a workflow.

## GCP Environment setup

Clone this repository

```sh
git clone https://github.com/nuttea/workflows-eventarc-demo.git
cd workflows-eventarc-demo
export WORKING_DIR=$(pwd)
```

Set PROJECT_ID, REGION

```sh
REGION=asia-southeast1
gcloud config set run/region ${REGION}
gcloud config set functions/region ${REGION}
gcloud config set workflows/location ${REGION}

echo "Get the project id"
gcloud config set project "<YOUR-PROJECT_ID>"
export PROJECT_ID=$(gcloud config get-value project)
```

Enable required services on the project

```sh
echo "Enable required services"
gcloud services enable \
  eventarc.googleapis.com \
  pubsub.googleapis.com \
  run.googleapis.com \
  cloudfunctions.googleapis.com \
  storage.googleapis.com \
  containerregistry.googleapis.com \
  artifactregistry.googleapis.com \
  workflows.googleapis.com
```

## Cloud Function - Random number

Inside [randomgen](randomgen) folder, deploy a function that generates a random number:

```sh
cd ${WORKING_DIR}/randomgen
gcloud functions deploy randomgen \
    --gen2 \
    --runtime python39 \
    --trigger-http \
    --entry-point randomgen \
    --source . \
    --allow-unauthenticated
```

Test:

```sh
export URL_RANDOMGEN=$(gcloud functions describe randomgen --gen2 --format='value(serviceConfig.uri)')
curl $URL_RANDOMGEN
```

## Cloud Function - Multiply

Inside [multiply](multiply) folder, deploy a function that multiplies a given number:

```sh
cd ${WORKING_DIR}/multiply
gcloud functions deploy multiply \
    --gen2 \
    --runtime python39 \
    --trigger-http \
    --entry-point multiply \
    --source . \
    --allow-unauthenticated
```

Test:

```sh
export URL_MULTIPLY=$(gcloud functions describe multiply --gen2 --format='value(serviceConfig.uri)')
curl -X POST ${URL_MULTIPLY} \
    -H "content-type: application/json" \
    -d '{"input":5}'
```

## External Function - MathJS

For an external function, use [MathJS](https://api.mathjs.org/).

Test:

```sh
curl https://api.mathjs.org/v4/?expr=log(56)
```

## Cloud Run - Floor

Inside [floor](floor) folder, deploy an authenticated Cloud Run service that floors a number.

Deploy:

```sh
cd ${WORKING_DIR}/floor
export SERVICE_NAME=floor
gcloud run deploy ${SERVICE_NAME} \
  --source . \
  --platform managed \
  --no-allow-unauthenticated
```

Add Cloud Run Invoker permission to your current account before the test:

```sh
CURRENT_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "user:${CURRENT_ACCOUNT}" \
    --role "roles/run.invoker"
```

Test:

```sh
export URL_FLOOR=$(gcloud run services describe floor --format='value(status.url)')

gcloud auth application-default login
export TOKEN=$(gcloud auth print-identity-token)
curl -X POST ${URL_FLOOR} \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d '{"input": "6.86"}'
```

## Service account for Workflows

Create a service account for Workflows:

```sh
export WORKFLOW_SERVICE_ACCOUNT=workflows-sa
gcloud iam service-accounts create ${WORKFLOW_SERVICE_ACCOUNT}
```

Grant `run.invoker`, `cloudfunctions.invoker`, and `logging.logWriter` role to the service account:

```sh
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${WORKFLOW_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/run.invoker"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${WORKFLOW_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/cloudfunctions.invoker"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member "serviceAccount:${WORKFLOW_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role "roles/logging.logWriter"
```

## Workflow

Deploy workflow:

```sh
WORKFLOW_NAME=event-payload-workflow
gcloud workflows deploy ${WORKFLOW_NAME} \
    --source=workflows/workflow.yaml \
    --service-account=${WORKFLOW_SERVICE_ACCOUNT}@${PROJECT_ID}.iam.gserviceaccount.com \
    --location=asia-southeast1
```

## Trigger a Workflow with PubSub

Setup Eventarc with PubSub as a trigger source

```sh
EVENTARC_SERVICE_ACCOUNT=eventarc-workflows

echo "Create an Eventarc trigger to listen for events from a Pub/Sub topic and route to $WORKFLOW_NAME workflow"
PUBSUB_TRIGGER_NAME=$WORKFLOW_NAME-pubsub
gcloud eventarc triggers create $PUBSUB_TRIGGER_NAME \
  --location=$REGION \
  --destination-workflow=$WORKFLOW_NAME \
  --destination-workflow-location=$REGION \
  --event-filters="type=google.cloud.pubsub.topic.v1.messagePublished" \
  --service-account=$EVENTARC_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
```

Test trigger with manual publish pubsub message

```sh
echo "Get the id of the underlying topic"
TOPIC=$(basename $(gcloud eventarc triggers describe $PUBSUB_TRIGGER_NAME --format='value(transport.pubsub.topic)' --location=$REGION))

echo "Publish a message to the topic: $TOPIC"
gcloud pubsub topics publish $TOPIC --message="Hello World"
```

## Trigger a Workflow with Cloud Storage

Setup Cloud Storage Bucket and Eventarc with Cloud Storage Event

```sh
echo "Grant the pubsub.publisher role to the Cloud Storage service account needed for Eventarc's Cloud Storage trigger"
SERVICE_ACCOUNT_STORAGE="$(gsutil kms serviceaccount -p $PROJECT_ID)"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT_STORAGE \
    --role roles/pubsub.publisher

echo "Create a Cloud Storage bucket"
BUCKET=$PROJECT_ID-workflow
gsutil mb -l $REGION gs://$BUCKET

echo "Create an Eventarc trigger to listen for events from a Cloud Storage bucket and route to $WORKFLOW_NAME workflow"
GCS_TRIGGER_NAME=$WORKFLOW_NAME-storage
gcloud eventarc triggers create $GCS_TRIGGER_NAME \
  --location=$REGION \
  --destination-workflow=$WORKFLOW_NAME \
  --destination-workflow-location=$REGION \
  --event-filters="type=google.cloud.storage.object.v1.finalized" \
  --event-filters="bucket=$BUCKET" \
  --service-account=$EVENTARC_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com
```

Test trigger with manual upload a file to Cloud Storage Bucket

```sh
echo "Upload a file to the bucket: $BUCKET"
echo "Hello World" > /tmp/random.txt
gsutil cp /tmp/random.txt gs://$BUCKET/random.txt
```

-------

This is not an official Google product.