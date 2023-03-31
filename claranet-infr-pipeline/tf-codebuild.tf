# -------- Codebuild permissions --------
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "phoenix-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

#TODO limit permissions
data "aws_iam_policy_document" "codebuild" {
  statement {
    actions = [
      "iam:CreateRole"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRegistry",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "eks:DescribeCluster"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.codepipeline_artifact_store.arn}/*"
    ]
  }
  statement {
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:aws:ssm:${var.region}:*:parameter/codebuild/*"
    ]
  }
  statement {
    actions = [
      "codebuild:CreateReportGroup",
      "codebuild:CreateReport",
      "codebuild:UpdateReport",
      "codebuild:BatchPutTestCases",
      "codebuild:BatchPutCodeCoverages"
    ]
    resources = ["*"]
  }
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = ["arn:aws:iam::*:role/ccp-role"]
  }
}

data "aws_iam_policy" "dev_policy" {
  name = "PowerUserAccess"
}

resource "aws_iam_role_policy" "codebuild" {
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy_document.codebuild.json
}

resource "aws_iam_role_policy" "dev_access" {
  role   = aws_iam_role.codebuild.name
  policy = data.aws_iam_policy.dev_policy.policy
}


# --------- Validate CodeBuild Project --------
resource "aws_codebuild_project" "validate" {
  name          = "aws-automation-validate"
  description   = "CodeBuild project to Validate the Terraform IaC."
  build_timeout = "90"
  service_role  = aws_iam_role.codebuild.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode = false
  }
  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/aws-automation-validate"
    }
  }
  source {
    type      = "NO_SOURCE"
    buildspec = file("files/validateTerraform.yaml")
  }
  source_version = "master"
}

# ---------- Checkov Test CodeBuild Project -------
resource "aws_codebuild_project" "checkov_test" {
  name          = "aws-automation-checkov-test"
  description   = "CodeBuild project to test Terraform IaC with Checkov."
  build_timeout = "90"
  service_role  = aws_iam_role.codebuild.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode = false
  }
  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/aws-automation-checkov-test"
    }
  }
  source {
    type      = "NO_SOURCE"
    buildspec = file("files/checkovTestTerraform.yaml")
  }
  source_version = "master"
}

# ---------- Terraform Plan CodeBuild Project -------
resource "aws_codebuild_project" "terraform_plan" {
  name          = "aws-automation-terraform-plan"
  description   = "CodeBuild project to execute Terraform plan."
  build_timeout = "90"
  service_role  = aws_iam_role.codebuild.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode = false
  }
  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/aws-automation-terraform-plan"
    }
  }
  source {
    type      = "NO_SOURCE"
    buildspec = file("files/planTerraform.yaml")
  }
  source_version = "master"
}

# -------- Terraform apply CodeBuild Project ------
resource "aws_codebuild_project" "terraform_apply" {
  name          = "aws-automation-terraform-apply"
  description   = "CodeBuild project to execute Terraform Apply."
  build_timeout = "90"
  service_role  = aws_iam_role.codebuild.arn
  artifacts {
    type = "NO_ARTIFACTS"
  }
  environment {
    compute_type    = "BUILD_GENERAL1_MEDIUM"
    type            = "LINUX_CONTAINER"
    image           = "aws/codebuild/amazonlinux2-x86_64-standard:3.0"
    privileged_mode = false
  }
  logs_config {
    cloudwatch_logs {
      status     = "ENABLED"
      group_name = "/aws/codebuild/aws-automation-terraform-apply"
    }
  }
  source {
    type      = "NO_SOURCE"
    buildspec = file("files/applyTerraform.yaml")
  }
  source_version = "master"
}
