# Dev — free tier only. HTTP (no HTTPS cert). Single EC2 node. Short log retention.
# Set db_password via: export TF_VAR_db_password=<secret>

aws_region      = "ap-south-1"
webui_image_tag = "latest"
bff_image_tag   = "latest"
