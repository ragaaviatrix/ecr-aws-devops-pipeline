output "creds_username" {
  value = aws_iam_service_specific_credential.get_creds.service_user_name
}

output "creds_password" {
  value = nonsensitive(aws_iam_service_specific_credential.get_creds.service_password)
}

output "https_clone_url" {
  value = aws_codecommit_repository.transit_repo.clone_url_http
}