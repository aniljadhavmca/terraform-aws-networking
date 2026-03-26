resource "tls_private_key" "key" {
  algorithm = "RSA"
}

resource "local_file" "pem" {
  content  = tls_private_key.key.private_key_pem
  filename = "${path.root}/mykey.pem"
}

resource "aws_key_pair" "key" {
  key_name   = "mykey"
  public_key = tls_private_key.key.public_key_openssh
}

output "key_name" {
  value = aws_key_pair.key.key_name
}
