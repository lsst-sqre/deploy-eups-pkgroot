resource "aws_s3_bucket" "eups" {
  region = "${var.aws_default_region}"
  bucket = "${replace("${var.env_name}-eups.${var.domain_name}", "prod-", "")}"
  acl    = "private"

  versioning {
    enabled = false
  }

  force_destroy = false
}

# the bucket postfix is "-backups" (note the plural) to be consistent with what
# other sqre devs have done while the non-plural is used in tf resource names.
resource "aws_s3_bucket" "eups_backups" {
  region = "${var.aws_default_region}"
  bucket = "${aws_s3_bucket.eups.id}-backups"
  acl    = "private"

  # lifecycle rules still need to handle versioned object to work with buckets
  # on which versioning has been disabled (suspended)
  versioning {
    enabled = false
  }

  force_destroy = false

  lifecycle_rule {
    id      = "daily"
    enabled = true
    prefix  = "daily/"

    expiration {
      days = 8
    }

    noncurrent_version_expiration {
      days = 8
    }
  }

  lifecycle_rule {
    id      = "weekly"
    enabled = true
    prefix  = "weekly/"

    expiration {
      days = 35
    }

    noncurrent_version_expiration {
      days = 35
    }
  }

  # note that
  # * STANDARD-IA has a min cost size of 128KiB per object -- transistion
  # supposedly will not migrate objects < 128KiB
  # * GLACIER adds 8KiB for "metadata" per object
  # * min days before transition is 30 for non-versioned / current objects
  lifecycle_rule {
    id      = "monthly"
    enabled = true
    prefix  = "monthly/"

    expiration {
      days = 217
    }

    noncurrent_version_expiration {
      days = 217
    }

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}