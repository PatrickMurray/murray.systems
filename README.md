# murray.systems

The purpose of this repository is to contain the source code and content for
the personal website of Patrick Murray, located at https://murray.systems/.


## Technology Stack

### Terraform

[Terraform](https://www.terraform.io/) is utilized to manage Amazon Web
Services resources.

### Hugo

The [Hugo](https://gohugo.io/) static site generator is utilized to compile
the website's content and metadata. A custom, built from scratch, template is
used.

### Make

[make(1)](https://man7.org/linux/man-pages/man1/make.1.html) is utilized to
script tasks surrounding the build, deployment, and cleanup of website assets.

### AWS CLI

[AWS CLI](https://pypi.org/project/awscli/) is utilized, by necessity, to
upload website assets to AWS S3.

### Google Analytics

[Google Analytics](https://analytics.google.com) was selected to provide
insight (when possible) into the website's visitors.


## Infrastructure

### AWS Route53

[AWS Route53](https://aws.amazon.com/route53/) is utilized to host the
website's DNS zone and public records.

### AWS S3

#### Website Bucket

[AWS S3](https://aws.amazon.com/s3/) is utilized to host the website's static
assets. The AWS S3 bucket is configured as a static website and logs access
requests to a dedicated logging bucket. While the asset bucket is configured as
a website, external traffic is not routed to it directly; rather, an AWS
Cloudfront distribution acts as a proxy for caching and negotiate TLS
connections.

#### Logging Bucket

As mentioned previously, the website asset bucket logs all access requests to a
dedicated logging bucket. This bucket consumes logs from both AWS S3 and
Cloudfront. These logs are organized into two directories: `murray-systems-s3/`
and `murray-systems-cloudfront/`. S3 logs are ingested in near real-time;
however, Cloudfront logs are written approximately every hour.


### AWS Certificate Manager

[AWS Certificate Manager](https://aws.amazon.com/certificate-manager/) is
utilized to issue & manage X.509 certificates for the website. Certificates are
issued and verified automatically via a DNS challenge performed by Terraform.
Issued certificates are then pinned to the AWS Cloudfront distribution to proxy
TLS traffic.

### AWS Cloudfront

[AWS Cloudfront](https://aws.amazon.com/cloudfront/) is utilized as a cache and
HTTP & TLS proxy. Cloudfront utilizes an X.509 certificate issued & managed by
AWS Certificate Manager. Furthermore, Cloudfront caches content from the
website's S3 asset bucket. Finally, Cloudfront will produce hourly traffic logs
in the dedicate S3 logging bucket.


## Local Development

### AWS Provisioning

```bash
cd terraform
terraform init
terraform plan
terraform apply --auto-approve
```

### Static-Site Generation

#### Development

```bash
cd src
hugo server
```

#### Deployment

```bash
cd src
make deploy
```
