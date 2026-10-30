output "plan_role_arn" {
  description = "Put this in the GitHub secret AWS_PLAN_ROLE_ARN."
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "Put this in the GitHub secret AWS_APPLY_ROLE_ARN."
  value       = aws_iam_role.apply.arn
}

output "oidc_provider_arn" {
  value = local.provider_arn
}
