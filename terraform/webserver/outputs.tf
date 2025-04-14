output "web_instance_ids" {
  value = aws_instance.web[*].id
}

output "web_instance_ips" {
  value = aws_instance.web[*].public_ip
}

output "bastion_ip" {
  value = aws_instance.web[1].public_ip
}

output "db_private_ip" {
  value = aws_instance.db.private_ip
}

output "vm6_private_ip" {
  value = aws_instance.vm6.private_ip
}

output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
}
