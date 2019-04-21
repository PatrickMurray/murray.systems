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
policy = <<EOF
{
	"Id": "public_bucket_policy",
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "public_bucket_policy_promary",
			"Action": [
				"s3:GetObject"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::${var.static_bucket}/*",
			"Principal": "*"
		}
	]
}
EOF


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



resource "aws_cloudfront_distribution" "cloudfront_distribution" {
	enabled             = true
	is_ipv6_enabled     = true
	comment             = "${var.domain_name} CloudFront Distribution"
	default_root_object = "${var.index_document}"

	aliases = [
		"${var.domain_name}"
	]

	origin {
		domain_name = "${aws_s3_bucket.static_bucket.bucket_domain_name}"
		origin_id   = "${var.domain_name}"
	}

	default_cache_behavior {
		target_origin_id       = "${var.domain_name}"
		viewer_protocol_policy = "redirect-to-https",
		compress               = true
		min_ttl                = 0
		default_ttl            = 86400
		max_ttl                = 31536000
		allowed_methods        = [
			"GET",
			"HEAD"
		]
		cached_methods         = [
			"GET",
			"HEAD"
		]

		forwarded_values {
			query_string = false

			cookies {
				forward = "none"
			}
		}
	}

	restrictions {
		geo_restriction {
			restriction_type = "none"
		}
	}

	// TODO - logging

	viewer_certificate {
		acm_certificate_arn = "${aws_acm_certificate.certificate.arn}"
		ssl_support_method  = "sni-only"
	}
}



resource "aws_route53_record" "root_domain_ipv4" {
	zone_id = "${data.aws_route53_zone.dns_zone.id}"
	name    = "${var.domain_name}"
	type    = "A"

	alias {
		zone_id = "${aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id}"
		name    = "${aws_cloudfront_distribution.cloudfront_distribution.domain_name}"
		evaluate_target_health = false
	}
}


resource "aws_route53_record" "root_domain_ipv6" {
	zone_id = "${data.aws_route53_zone.dns_zone.id}"
	name    = "${var.domain_name}"
	type    = "AAAA"

	alias {
		zone_id = "${aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id}"
		name    = "${aws_cloudfront_distribution.cloudfront_distribution.domain_name}"
		evaluate_target_health = false
	}
}


resource "aws_route53_record" "www_domain_ipv4" {
	zone_id = "${data.aws_route53_zone.dns_zone.id}"
	name    = "www"
	type    = "CNAME"

	alias {
		zone_id = "${aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id}"
		name    = "${aws_cloudfront_distribution.cloudfront_distribution.domain_name}"
		evaluate_target_health = false
	}
}
