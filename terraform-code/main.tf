resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "example_dataset"
  friendly_name               = "test"
  description                 = "This is a test description"
  location                    = var.location
  default_table_expiration_ms = 3600000
  project                     = var.project_id

}
resource "google_bigquery_table" "table1" {
  table_id   = "table1"
  dataset_id = google_bigquery_dataset.dataset.dataset_id

  schema  = <<EOF
[
  {
    "name": "permalink",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "The Permalink"
  },
  {
    "name": "state",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "State where the head office is located"
  }
]
EOF
  project = var.project_id
}

resource "google_storage_bucket" "bucket" {
  name     = "test-bucket-dhetsei-jamf2"
  location = var.location
  project  = var.project_id
}


resource "google_storage_bucket_object" "archive" {
  name         = "src-${data.archive_file.source.output_md5}.zip"
  bucket       = google_storage_bucket.bucket.name
  source       = data.archive_file.source.output_path
  content_type = "application/zip"
  depends_on = [
    google_storage_bucket.bucket,
    data.archive_file.source
  ]

}

# Create the Cloud function triggered by a `Finalize` event on the bucket
resource "google_cloudfunctions_function" "Cloud_function" {
  name                  = "Cloud-function-trigger-using-terraform"
  description           = "Cloud-function will get trigger once file is uploaded in input-${var.project_id}"
  runtime               = "python312"
  project               = var.project_id
  region                = var.region
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  entry_point           = "main"
   
  #   event_trigger {
  #     event_type = "google.storage.object.finalize"
  #     resource   = "input-${var.project_id}"
  #   }
  trigger_http = true
  depends_on = [
    google_storage_bucket.bucket,
    google_storage_bucket_object.archive,
  ]

}

# IAM entry for all users to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.Cloud_function.project
  region         = google_cloudfunctions_function.Cloud_function.region
  cloud_function = google_cloudfunctions_function.Cloud_function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# Generates an archive of the source code compressed as a .zip file.
data "archive_file" "source" {
  type = "zip"
  #source_dir  = "../automation"
  #source_file = "../automation/GetJamfdata.py"
  source {
    content  = data.local_file.py_main.content
    filename = "main.py"
  }
  source {
    content  = data.local_file.py_req.content
    filename = "requirements.txt"
  }
  output_path = "${path.module}/function.zip"
}

data "google_iam_policy" "admin" {
  depends_on = [google_storage_bucket.bucket]
  binding {
    role = "roles/storage.admin"
    members = [
      "serviceAccount:246337671244-compute@developer.gserviceaccount.com"
    ]
  }
}


resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.admin"
  members = [
    "user:narbeh.davoodian@deliveryhero.com",
    "serviceAccount:246337671244-compute@developer.gserviceaccount.com"
  ]
}


resource "google_storage_bucket_iam_binding" "binding1" {
  bucket = "gcf-sources-246337671244-europe-west3"
  role   = "roles/storage.admin"
  members = [
    "user:narbeh.davoodian@deliveryhero.com",
    "serviceAccount:246337671244-compute@developer.gserviceaccount.com"
  ]
}


data "local_file" "py_main" {
  filename = "../automation/GetJamfdata.py"
  depends_on = [
    # Make sure archive is created in apply stage
    null_resource.trigger
  ]
}

data "local_file" "py_req" {
  filename = "../automation/requirements.txt"
  depends_on = [
    # Make sure archive is created in apply stage
    null_resource.trigger
  ]
}

# Dummy resource to ensure archive is created at apply stage
resource "null_resource" "trigger" {
  triggers = {
    timestamp = timestamp()
  }
}