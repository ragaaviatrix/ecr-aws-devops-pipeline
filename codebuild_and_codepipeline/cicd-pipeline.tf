resource "aws_codebuild_project" "create-nat-gw" {
  name         = "create-nat-gw"
  description  = "Create a NAT gateway"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.awscli_ecr_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    environment_variable {
      name  = "subnet_id_for_NATgw"
      value = var.subnet_id_for_NATgw
    }

    environment_variable {
      name  = "eip_alloc_id"
      value = aws_eip.natgw_eip.allocation_id
    }

    environment_variable {
      name  = "route_table_id"
      value = aws_route_table.rt_for_codebuild.id
    }


  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("codebuild_and_codepipeline/buildspec/create-nat-gw-buildspec.yml")
  }
}

resource "aws_codebuild_project" "delete-nat-gw" {
  name         = "delete-nat-gw"
  description  = "Deleta a NAT gateway"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.awscli_ecr_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"

    environment_variable {
      name  = "route_table_id"
      value = aws_route_table.rt_for_codebuild.id
    }

  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("codebuild_and_codepipeline/buildspec/delete-nat-gw-buildspec.yml")
  }
}

resource "aws_codebuild_project" "tf-plan" {
  name         = "tf-cicd-plan"
  description  = "Plan stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.terraform_ecr_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("codebuild_and_codepipeline/buildspec/plan-buildspec.yml")
  }

  vpc_config {
    vpc_id = var.avtx_ctrl_vpc

    subnets = [
      aws_subnet.codebuild_subnet.id,
    ]

    security_group_ids = [
      aws_security_group.CodebuildSecurityGroup.id,
    ]
  }

}

resource "aws_codebuild_project" "tf-apply" {
  name         = "tf-cicd-apply"
  description  = "Apply stage for terraform"
  service_role = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = var.terraform_ecr_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
  }
  source {
    type      = "CODEPIPELINE"
    buildspec = file("codebuild_and_codepipeline/buildspec/apply-buildspec.yml")
  }

  vpc_config {
    vpc_id = var.avtx_ctrl_vpc

    subnets = [
      aws_subnet.codebuild_subnet.id,
    ]

    security_group_ids = [
      aws_security_group.CodebuildSecurityGroup.id,
    ]
  }
}


resource "aws_codepipeline" "cicd_pipeline" {

  name     = "tf-cicd"
  role_arn = aws_iam_role.tf-codepipeline-role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.codepipeline_artifacts.id
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["tf-code"]
      configuration = {
        RepositoryName = var.codecommit_repo_name
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "NAT_create_gw"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = aws_codebuild_project.create-nat-gw.name
      }
    }
  }

  stage {
    name = "Plan"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = aws_codebuild_project.tf-plan.name
      }
    }
  }

  stage {
    name = "Approve"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
      configuration = {
        NotificationArn = aws_sns_topic.approval_alerts.arn
      }
    }


  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = aws_codebuild_project.tf-apply.name
      }
    }
  }


  stage {
    name = "NAT_delete_gw"
    action {
      name            = "Build"
      category        = "Build"
      provider        = "CodeBuild"
      version         = "1"
      owner           = "AWS"
      input_artifacts = ["tf-code"]
      configuration = {
        ProjectName = aws_codebuild_project.delete-nat-gw.name
      }
    }
  }

}
