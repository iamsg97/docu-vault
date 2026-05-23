# Preprod — mirrors prod config but with free-tier instance sizes.
# Used for integration testing before prod deploys.
# Set db_password via: export TF_VAR_db_password=<secret>

aws_region      = "ap-south-1"
webui_image_tag = "latest"
bff_image_tag   = "latest"
