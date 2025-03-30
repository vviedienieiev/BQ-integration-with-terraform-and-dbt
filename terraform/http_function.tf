resource "google_storage_bucket" "functions_bucket" {
  name     = "${var.project_id}-gcf-source-bucket"
  location = "US"
}

data "archive_file" "function_src" {
  for_each = { for f in var.http_functions: f.name => f}

  type        = "zip"
  source_dir  = "${each.value.source_dir}"
  output_path = "${path.module}/.terraform/tmp/${each.key}.zip"
}

resource "google_storage_bucket_object" "function_sources" {
  for_each = { for f in var.http_functions : f.name => f }

  name   = "${each.value.name}-${data.archive_file.function_src[each.key].output_md5}.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = "${path.module}/.terraform/tmp/${each.key}.zip"
}

resource "google_cloudfunctions2_function" "http_functions" {
  for_each = { for f in var.http_functions : f.name => f }

  name        = each.value.name
  location    = "us-central1"
  description = each.value.description

  build_config {
    runtime     = each.value.runtime
    entry_point = each.value.entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = "${each.value.name}-${data.archive_file.function_src[each.key].output_md5}.zip"
      }
    }
  }

  service_config {
    available_memory = "256M"
    timeout_seconds  = 60
  }

  depends_on = [google_storage_bucket_object.function_sources]
}

resource "google_cloudfunctions2_function_iam_member" "invoker" {
  for_each = { for f in var.http_functions : f.name => f }

  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.http_functions[each.key].name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers" 
}

resource "google_cloud_run_service_iam_member" "public_invoker" {
  for_each = { for f in var.http_functions : f.name => f }

  location = "us-central1"
  project  = var.project_id
  service  = google_cloudfunctions2_function.http_functions[each.key].name

  role   = "roles/run.invoker"
  member = "allUsers"
}