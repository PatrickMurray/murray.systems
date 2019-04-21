variable "region" {
	default = "us-east-1"
}


variable "logging_bucket" {
	default = "murray-systems-log-bucket"
}


variable "static_bucket" {
	default = "murray-systems"
}


variable "environment" {
	default = "prod"
}


variable "logging_prefix" {
	default = "murray-systems/"
}


variable "index_document" {
	default = "index.html"
}


variable "error_document" {
	default = "error.html"
}


variable "domain_name" {
	default = "murray.systems"
}


provider "aws" {
	region = "${var.region}"
}


resource "aws_s3_bucket" "logging_bucket" {
	bucket = "${var.logging_bucket}"
	acl    = "log-delivery-write"
}


resource "aws_s3_bucket" "static_bucket" {
	bucket = "${var.static_bucket}"

	tags = {
		Name        = "${var.static_bucket}"
		Environment = "${var.environment}"
	}

	versioning {
		enabled = true
	}

	logging {
		target_bucket = "${aws_s3_bucket.logging_bucket.id}"
		target_prefix = "${var.logging_prefix}"
	}

	website {
		index_document = "${var.index_document}"
		error_document = "${var.error_document}"
	}
}




resource "aws_acm_certificate" "certificate" {
	domain_name       = "${var.domain_name}"
	validation_method = "DNS"

	tags = {
		Environment = "${var.environment}"
	}

	lifecycle {
		create_before_destroy = true
	}
}


data "aws_route53_zone" "dns_zone" {
	name         = "${var.domain_name}"
	private_zone = false
}


resource "aws_route53_record" "certificate_verification" {
	name    = "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_name}"
	type    = "${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_type}"
	zone_id = "${data.aws_route53_zone.dns_zone.id}"
	records = [
		"${aws_acm_certificate.certificate.domain_validation_options.0.resource_record_value}"
	],
	ttl     = 60
}


resource "aws_acm_certificate_validation" "certificate_validation" {
	certificate_arn = "${aws_acm_certificate.certificate.arn}"
	validation_record_fqdns = [
		"${aws_route53_record.certificate_verification.fqdn}"
	]
}
