variable "project_id" {
  type    = string
  default = "bigquery-dbt-and-terraform"
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-c"
}

variable "http_functions" {
  type = list(object({
    name         = string
    description  = string
    entry_point  = string
    runtime      = string
    source_dir   = string
  }))
}