output "alb_dns_name" {
  value       = aws_lb.alb.dns_name
  description = "The DNS name of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.asg.name
  description = "The name of the Auto Scaling Group"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}