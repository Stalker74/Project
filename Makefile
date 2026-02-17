.PHONY: help init plan apply destroy validate fmt clean setup

help:
	@echo "Available commands:"
	@echo "  make setup      - Create S3 bucket and DynamoDB table for remote state"
	@echo "  make init       - Initialize Terraform"
	@echo "  make validate   - Validate Terraform configuration"
	@echo "  make fmt        - Format Terraform files"
	@echo "  make plan-dev   - Plan dev environment"
	@echo "  make plan-prod  - Plan prod environment"
	@echo "  make apply-dev  - Apply dev environment"
	@echo "  make apply-prod - Apply prod environment"
	@echo "  make destroy-dev  - Destroy dev environment"
	@echo "  make destroy-prod - Destroy prod environment"
	@echo "  make clean      - Clean Terraform files"

setup:
	@bash setup.sh

init:
	cd terraform && terraform init

validate:
	cd terraform && terraform validate

fmt:
	cd terraform && terraform fmt -recursive

plan-dev:
	cd terraform && terraform workspace select dev || terraform workspace new dev
	cd terraform && terraform plan

plan-prod:
	cd terraform && terraform workspace select prod || terraform workspace new prod
	cd terraform && terraform plan

apply-dev:
	cd terraform && terraform workspace select dev
	cd terraform && terraform apply

apply-prod:
	cd terraform && terraform workspace select prod
	cd terraform && terraform apply

destroy-dev:
	cd terraform && terraform workspace select dev
	cd terraform && terraform destroy

destroy-prod:
	cd terraform && terraform workspace select prod
	cd terraform && terraform destroy

clean:
	cd terraform && rm -rf .terraform .terraform.lock.hcl *.tfplan *.tfstate*

output:
	cd terraform && terraform output
