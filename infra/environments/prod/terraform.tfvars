# Prod — larger instances, multi-AZ RDS, deletion protection, 30-day logs.
# acm_certificate_arn and domain_names are set here once a domain is registered.
# Set db_password via: export TF_VAR_db_password=<secret>

aws_region      = "ap-south-1"
webui_image_tag = "latest"
bff_image_tag   = "latest"

# Uncomment and fill in once you have a domain and ACM cert:
# acm_certificate_arn            = "arn:aws:acm:ap-south-1:<ACCOUNT_ID>:certificate/<CERT_ID>"
# acm_certificate_arn_us_east_1  = "arn:aws:acm:us-east-1:<ACCOUNT_ID>:certificate/<CERT_ID>"
# domain_names                   = ["app.docuvault.io"]
