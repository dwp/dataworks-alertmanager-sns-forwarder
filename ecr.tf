resource "aws_ecr_repository" "dataworks-alertmanager-sns-forwarder" {
  name = "dataworks-alertmanager-sns-forwarder"
  tags = merge(
    local.common_tags,
    { DockerHub : "dwpdigital/dataworks-alertmanager-sns-forwarder" }
  )
}

resource "aws_ecr_repository_policy" "dataworks-alertmanager-sns-forwarder" {
  repository = aws_ecr_repository.dataworks-alertmanager-sns-forwarder.name
  policy     = data.terraform_remote_state.management.outputs.ecr_iam_policy_document
}

output "ecr_example_url" {
  value = aws_ecr_repository.dataworks-alertmanager-sns-forwarder.repository_url
}
