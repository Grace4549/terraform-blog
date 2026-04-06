variables {
  cluster_name  = "test-cluster"
  instance_type = "t3.micro"
  min_size      = 1
  max_size      = 2
  environment   = "dev"
}

run "validate_asg_name_prefix" {
  command = plan

  assert {
    condition     = startswith(aws_autoscaling_group.asg.name_prefix, "test-cluster-asg-")
    error_message = "ASG name prefix must start with the cluster name"
  }
}

run "validate_instance_type" {
  command = plan

  assert {
    condition     = aws_launch_template.lt.instance_type == "t3.micro"
    error_message = "Instance type must match the instance_type variable"
  }
}

run "validate_environment_tag" {
  command = plan

  assert {
    condition     = aws_vpc.main.tags["Environment"] == "dev"
    error_message = "VPC must have the correct Environment tag"
  }
}

run "validate_min_max_size" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.asg.min_size == 1
    error_message = "ASG min size must match the min_size variable"
  }
}

run "validate_invalid_environment" {
  command = plan

  expect_failures = [var.environment]

  variables {
    environment = "invalid"
  }
}