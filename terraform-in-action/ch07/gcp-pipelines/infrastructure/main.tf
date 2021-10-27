locals {
  services = [
    "sourcerepo.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "enabled_service" {
  for_each = toset(local.services)
  project  = var.project_id
  service  = each.key

  # Creation-time provisioner
  provisioner "local-exec" {
    command = "sleep 60"
  }

  # Destruction-time provisioner
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 15"
  }
}