output "server_public_ip" {
    description = "The public IP address of the web server instance."
    value       = aws_instance.web_server.public_ip 
}

output "website_url" {
    description = "The URL to access the web server."
    value       = "http://${aws_instance.web_server.public_ip}:${var.server_port}"
}

output "ami_id_used" {
    description = "The ID of the AMI used for the web server instance."
    value       = data.aws_ami.amazon_linux.id
  
}