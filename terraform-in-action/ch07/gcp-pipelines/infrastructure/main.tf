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

  # these pauses are here to avoid potential race conditions when
  # enabling/disabling service APIs

  # Creation-time provisioner - pause 60 seconds after Create()
  provisioner "local-exec" {
    # if you don't specify 'when' it defaults to apply
    # when    = apply
    command = "sleep 60"
  }

  # Destruction-time provisioner - pause 15 seconds before Delete()
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 15"
  }
}

resource "google_sourcerepo_repository" "repo" {
  depends_on = [
    google_project_service.enabled_service["sourcerepo.googleapis.com"]
  ]

  name = "${var.namespace}-repo"
}