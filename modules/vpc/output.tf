output "vpc_id" {
    value = aws_vpc.main.id
}

output "private_subnets_ids" {
    value = aws_subnet.private.*.id
}

output "public_subnets_ids" {
    value = aws_subnet.public.*.id
}

output "certicate_arn" {
    value = aws_acm_certificate_validation.sayu_cert_validation.certificate_arn
}
