variable "region" {
	default = "us-east-1"
}


variable "environment" {
        default = "prod"
}


variable "domain_name" {
	default = "murray.systems"
}


variable "static_bucket" {
	default = "murray-systems"
}


variable "logging_bucket" {
	default = "murray-systems-logs"
}


variable "s3_logging_prefix" {
	default = "murray-systems-s3/"
}


variable "cloudfront_logging_prefix" {
        default = "murray-systems-cloudfront/"
}


variable "index_document" {
	default = "index.html"
}


variable "error_document" {
	default = "404.html"
}


provider "aws" {
	region = var.region
}


resource "aws_s3_bucket" "logging_bucket" {
	bucket = var.logging_bucket
	acl    = "log-delivery-write"

        tags = {
                Name        = var.logging_bucket
                Environment = var.environment
        }
}


resource "aws_s3_bucket" "static_bucket" {
	bucket = var.static_bucket
        policy = <<EOF
{
	"Id": "public_bucket_policy",
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "public_bucket_policy_primary",
			"Action": [
				"s3:GetObject"
			],
			"Effect": "Allow",
			"Resource": "arn:aws:s3:::${ var.static_bucket }/*",
			"Principal": "*"
		}
	]
}
EOF


	tags = {
		Name        = var.static_bucket
		Environment = var.environment
	}

	versioning {
		enabled = true
	}

	logging {
		target_bucket = aws_s3_bucket.logging_bucket.id
		target_prefix = var.s3_logging_prefix
	}

	website {
		index_document = var.index_document
		error_document = var.error_document
	}
}


resource "aws_acm_certificate" "certificate" {
	domain_name       = var.domain_name
	validation_method = "DNS"

	subject_alternative_names = [
		"www.${ var.domain_name }"
	]

	tags = {
		Environment = var.environment
	}

	lifecycle {
		create_before_destroy = true
	}
}


data "aws_route53_zone" "dns_zone" {
	name         = var.domain_name
	private_zone = false
}


resource "aws_route53_record" "certificate_verification" {
        for_each = {
                for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
                        name   = dvo.resource_record_name
                        record = dvo.resource_record_value
                        type   = dvo.resource_record_type
                }
        }

	name            = each.value.name
	type            = each.value.type
	zone_id         = data.aws_route53_zone.dns_zone.id
	records         = [
                each.value.record
        ]
	ttl             = 60
        allow_overwrite = true
}


resource "aws_acm_certificate_validation" "certificate_validation" {
	certificate_arn = aws_acm_certificate.certificate.arn
	validation_record_fqdns = [
                for record in aws_route53_record.certificate_verification : record.fqdn
	]
}


resource "aws_cloudfront_distribution" "cloudfront_distribution" {
	enabled             = true
	is_ipv6_enabled     = true
	comment             = "${var.domain_name} CloudFront Distribution"
	default_root_object = var.index_document

	aliases = [
		var.domain_name,
		"www.${var.domain_name}"
	]

	origin {
		domain_name = "${var.static_bucket}.s3-website-${var.region}.amazonaws.com"
		origin_id   = var.domain_name

                custom_origin_config {
                        http_port = 80
                        https_port = 443
                        origin_protocol_policy = "http-only"
                        origin_ssl_protocols = [
                                "TLSv1.1",
                                "TLSv1.2"
                        ]
                }
	}

	default_cache_behavior {
		target_origin_id       = var.domain_name
		viewer_protocol_policy = "redirect-to-https"
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

	viewer_certificate {
		acm_certificate_arn = aws_acm_certificate.certificate.arn
		ssl_support_method  = "sni-only"
	}

        logging_config {
                bucket = "${var.logging_bucket}.s3.amazonaws.com"
                prefix = var.cloudfront_logging_prefix
                
                include_cookies = false
        }

        tags = {
		Environment = var.environment
        }
}


resource "aws_route53_record" "root_domain_ipv4" {
	zone_id         = data.aws_route53_zone.dns_zone.id
	name            = var.domain_name
	type            = "A"
        allow_overwrite = true

	alias {
		zone_id = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
		name    = aws_cloudfront_distribution.cloudfront_distribution.domain_name
		evaluate_target_health = false
	}
}


resource "aws_route53_record" "root_domain_ipv6" {
	zone_id         = data.aws_route53_zone.dns_zone.id
	name            = var.domain_name
	type            = "AAAA"
        allow_overwrite = true

	alias {
		zone_id = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
		name    = aws_cloudfront_distribution.cloudfront_distribution.domain_name
		evaluate_target_health = false
	}
}


resource "aws_route53_record" "www_domain_ipv4" {
	zone_id         = data.aws_route53_zone.dns_zone.id
	name            = "www"
	type            = "CNAME"
        allow_overwrite = true

	alias {
		zone_id = aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id
		name    = aws_cloudfront_distribution.cloudfront_distribution.domain_name
		evaluate_target_health = false
	}
}
