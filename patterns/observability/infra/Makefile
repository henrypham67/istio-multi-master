SHELL       := /bin/bash
.DEFAULT_GOAL := help

.PHONY: help init plan apply destroy fmt validate clean check-sync get-kubeconfig

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / { printf "  %-10s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

init: ## Initialize Terraform (downloads providers, modules)
	terraform init -upgrade

plan: ## Show Terraform plan
	terraform plan

apply: ## Apply Terraform changes
	terraform apply -auto-approve

destroy: ## Destroy Terraform-managed infrastructure
	terraform destroy -auto-approve

fmt: ## Format Terraform code
	terraform fmt -recursive

validate: ## Validate Terraform code
	terraform validate

clean: ## Remove local Terraform state & cache
	rm -rf .terraform
	rm -f terraform.tfstate* .terraform.lock.hcl

check-sync:
	@echo "→ Running cross-cluster sync check…"
	bash ../../scripts/check-cross-cluster-sync.sh

deploy:
	bash ./scripts/deploy.sh

get-kubeconfig: ## Get kubeconfig for EKS cluster
	@if [ -f kubeconfig ]; then \
		rm -f kubeconfig; \
	fi
	touch kubeconfig
	aws eks update-kubeconfig --name my-cluster --kubeconfig kubeconfig --region us-east-1 --alias ${CLUSTER1}
