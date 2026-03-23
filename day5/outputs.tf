output "alb_dns_name" {
  description = "The domain name of the load balancer"
  value       = aws_lb.web.dns_name
}

output "alb_url" {
  description = "Full URL to hit in the browser"
  value       = "http://${aws_lb.web.dns_name}"
}