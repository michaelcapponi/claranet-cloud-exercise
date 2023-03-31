
# ----- Codepipeline permissions ------
data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "phoenix-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    actions = [
      "codedeploy:CreateDeployment",
      "codedeploy:GetApplicationRevision",
      "codedeploy:RegisterApplicationRevision",
      "codedeploy:GetDeploymentConfig",
      "codedeploy:GetDeployment",
      "codedeploy:GetApplication",
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codecommit:GetCommit",
      "codecommit:GetUploadArchiveStatus",
      "codecommit:GetBranch",
      "codecommit:CancelUploadArchive",
      "codecommit:UploadArchive",
      "ecr:DescribeImages"
    ]
    resources = ["*"]
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values = [
        "cloudformation.amazonaws.com",
        "elasticbeanstalk.amazonaws.com",
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "lambda:InvokeFunction",
      "s3:GetBucketVersioning",
      "s3:GetObjectVersion",
      "s3:PutObjectAcl",
      "s3:PutObjectVersionAcl"
    ]
    resources = [
      aws_s3_bucket.codepipeline_artifact_store.arn,
      "${aws_s3_bucket.codepipeline_artifact_store.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "codepipeline_policy"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline.json
}

# -------- Artifact Store S3 bucket -------
resource "aws_s3_bucket" "codepipeline_artifact_store" {
  bucket = "phoenix-codepipeline-artifact-s3"
  tags = {
    Role = "storage"
  }
}

resource "aws_s3_bucket_acl" "codepipeline_artifact_store" {
  bucket = aws_s3_bucket.codepipeline_artifact_store.id
  acl    = "private"
}

resource "aws_s3_bucket_lifecycle_configuration" "codepipeline_artifact_store" {
  bucket = aws_s3_bucket.codepipeline_artifact_store.id
  rule {
    id     = "clean-deleted"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    expiration {
      expired_object_delete_marker = true
    }
    noncurrent_version_expiration {
      newer_noncurrent_versions = 2
      noncurrent_days           = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifact_store" {
  bucket                  = aws_s3_bucket.codepipeline_artifact_store.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifact_store" {
  bucket = aws_s3_bucket.codepipeline_artifact_store.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "codepipeline_artifact_store" {
  bucket = aws_s3_bucket.codepipeline_artifact_store.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ------------ Terraform Apply Pipeline -----------
resource "aws_codepipeline" "aws_automation" {
  name     = "aws-infra-automation"
  role_arn = aws_iam_role.codepipeline.arn
  artifact_store {
    location = aws_s3_bucket.codepipeline_artifact_store.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]

      configuration = {
        Owner      = "michaelcapponi"
        Repo       = "claranet-cloud-exercise"
        Branch     = "main"
        OAuthToken = var.github_token
      }
    }
  }
  stage {
    name = "Validate"
    action {
      name             = "Validate"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source"]
      output_artifacts = ["validate"]
      namespace        = "VALIDATE"
      configuration = {
        ProjectName = aws_codebuild_project.validate.name
      }
    }
  }
  stage {
    name = "TestCheckov"
    action {
      name             = "TestCheckov"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      run_order        = 1
      input_artifacts  = ["source"]
      output_artifacts = ["checkov"]
      namespace        = "CHECKOV"
      configuration = {
        ProjectName = aws_codebuild_project.checkov_test.name
        EnvironmentVariables = jsonencode([
          {
            name  = "ACCOUNT"
            value = local.account
            type  = "PLAINTEXT"
          }
        ])
      }
    }
    #action {
    #  name      = "CheckovApproval"
    #  category  = "Approval"
    #  owner     = "AWS"
    #  provider  = "Manual"
    #  version   = "1"
    #  run_order = 2
    #
    #  configuration = {
    #    CustomData         = "checkov: #{CHECKOV.failures}, #{CHECKOV.tests}"
    #    ExternalEntityLink = "#{CHECKOV.review_link}"
    #  }
    #}
  }

  stage {
    name = "TerraformBuild"
    action {
      name             = "TerraformPlan"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["plan"]
      namespace        = "TF"
      version          = "1"
      run_order        = 1

      configuration = {
        ProjectName = aws_codebuild_project.terraform_plan.name
      }
    }
    #action {
    #  name      = "TerraformApplyApproval"
    #  category  = "Approval"
    #  owner     = "AWS"
    #  provider  = "Manual"
    #  version   = "1"
    #  run_order = 2
    #
    #  configuration = {
    #    CustomData         = "Please review and approve the terraform plan"
    #    ExternalEntityLink = "https://#{TF.pipeline_region}.console.aws.amazon.com/codesuite/codebuild/${local.account}/projects/#{TF.build_id}/build/#{TF.build_id}%3A#{TF.build_tag}/?region=#{TF.pipeline_region}"
    #  }
    #}
    action {
      name             = "TerraformApply"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["plan"]
      output_artifacts = ["apply"]
      run_order        = 3
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform_apply.name
        # EnvironmentVariables = jsonencode([
        #TODO add TerraformCloud API Key
        # ])
      }
    }
  }
}
