terraform {
  required_version = ">= 0.12"
}

locals {
  stage             = "schedule"
  stage_description = "Execute a job/buildspec on a schedule"
}

module "handler" {
  source = "../_internal/handler"

  handler           = "schedule_handler"
  name_prefix       = var.name_prefix
  repo_name         = var.repo_name
  stage             = local.stage
  stage_description = local.stage_description
  project_arn       = module.runner.codebuild_project_arn
  python_runtime    = var.python_runtime
}

module "runner" {
  source = "../_internal/runner"

  name_prefix           = var.name_prefix
  repo_name             = var.repo_name
  stage                 = local.stage
  stage_description     = local.stage_description
  buildspec             = var.buildspec
  artifacts             = var.artifacts
  environment           = var.environment
  environment_variables = var.environment_variables
  policy_override       = var.policy_override
  policy_arns           = var.policy_arns
  vpc_config            = var.vpc_config

  badge_enabled  = var.badge_enabled
  build_timeout  = var.build_timeout
  queued_timeout = var.queued_timeout
  encryption_key = var.encryption_key
  source_version = var.source_version
  tags           = var.tags
}

module "trigger" {
  source = "../_internal/trigger"

  name_prefix         = var.name_prefix
  repo_name           = var.repo_name
  stage               = local.stage
  stage_description   = local.stage_description
  target_arn          = module.handler.function_arn
  schedule_expression = var.schedule_expression
}

resource "aws_lambda_permission" "trigger" {
  action        = "lambda:InvokeFunction"
  function_name = module.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = module.trigger.events_rule_arn
}
