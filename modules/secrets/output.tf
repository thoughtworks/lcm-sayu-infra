output "random_password" {
    value = random_password.password.result
}

output "random_username" {
    value = random_string.random.result
}