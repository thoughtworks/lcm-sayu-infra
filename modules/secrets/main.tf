resource "random_password" "password" {
  length = 16
  special = false
  override_special = "_%@"
}

resource "random_string" "random" {
  length = 16
  special = false
  number = false
  override_special = "_%@"
}
