output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web.dns_name
}

output "alb_url" {
  description = "Full URL to access the load balanced web app"
  value       = "http://${aws_lb.web.dns_name}"
}