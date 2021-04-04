output "aws_alb" {
  value = aws_lb.app-alb.dns_name
}
