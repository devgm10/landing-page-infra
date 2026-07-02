output "public_ip" {
    value = module.compute.public_ip
}

output "ssh_command" {
    value = "ssh ubuntu@${module.compute.public_ip}" 
}
