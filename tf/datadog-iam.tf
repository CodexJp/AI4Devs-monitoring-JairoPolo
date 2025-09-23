# Assume role policy document para Datadog - Basado en documentación oficial
data "aws_iam_policy_document" "datadog_aws_integration_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::464622532012:root"]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [
        "${datadog_integration_aws_account.datadog_integration.auth_config.aws_auth_config_role.external_id}"
      ]
    }
  }
}

# Policy document con permisos mínimos para Datadog
data "aws_iam_policy_document" "datadog_aws_integration" {
  statement {
    actions = [
      "cloudwatch:List*",
      "cloudwatch:Get*",
      "ec2:Describe*",
      "tag:GetResources",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

# IAM Policy para Datadog
resource "aws_iam_policy" "datadog_aws_integration" {
  name   = "DatadogAWSIntegrationPolicy"
  policy = data.aws_iam_policy_document.datadog_aws_integration.json
}

# IAM Role para Datadog siguiendo documentación oficial
resource "aws_iam_role" "datadog_aws_integration" {
  name               = "DatadogIntegrationRole"
  description        = "Role for Datadog AWS Integration"
  assume_role_policy = data.aws_iam_policy_document.datadog_aws_integration_assume_role.json

  tags = {
    Purpose = "DatadogIntegration"
    Region  = "us-west-2"
  }
}

# Attach custom policy
resource "aws_iam_role_policy_attachment" "datadog_aws_integration" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = aws_iam_policy.datadog_aws_integration.arn
}

# Attach AWS managed SecurityAudit policy
resource "aws_iam_role_policy_attachment" "datadog_aws_integration_security_audit" {
  role       = aws_iam_role.datadog_aws_integration.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# Instance Profile para EC2
resource "aws_iam_instance_profile" "datadog_instance_profile" {
  name = "ai4devs-datadog-instance-profile"
  role = aws_iam_role.datadog_aws_integration.name
}