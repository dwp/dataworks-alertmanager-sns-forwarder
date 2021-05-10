SHELL:=bash

aws_profile=default
aws_region=eu-west-2

PROJECT_NAME := alertmanager-sns-forwarder
GOFILES:=$(shell find . -name '*.go' | grep -v -E '(./vendor)')

default: help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: bootstrap
bootstrap: ## Bootstrap local environment for first use
	@make git-hooks
	pip3 install --user Jinja2 PyYAML boto3
	@{ \
		export AWS_PROFILE=$(aws_profile); \
		export AWS_REGION=$(aws_region); \
		python3 bootstrap_terraform.py; \
	}
	terraform fmt -recursive

.PHONY: git-hooks
git-hooks: ## Set up hooks in .githooks
	@git submodule update --init .githooks ; \
	git config core.hooksPath .githooks \


.PHONY: terraform-init
terraform-init: ## Run `terraform init` from repo root
	terraform init

.PHONY: terraform-plan
terraform-plan: ## Run `terraform plan` from repo root
	terraform plan

.PHONY: terraform-apply
terraform-apply: ## Run `terraform apply` from repo root
	terraform apply

.PHONY: terraform-workspace-new
terraform-workspace-new: ## Creates new Terraform workspace with Concourse remote execution. Run `terraform-workspace-new workspace=<workspace_name>`
	fly -t aws-concourse execute --config create-workspace.yml --input repo=. -v workspace="$(workspace)"

.PHONY all: clean test bin

bin: bin/linux/${PROJECT_NAME}

bin/%: LDFLAGS=-X github.com/DataReply/${PROJECT_NAME}/${PROJECT_NAME}.Version=${APP_VERSION}
bin/%: $(GOFILES)
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o "bin/darwin/${PROJECT_NAME}" github.com/DataReply/${PROJECT_NAME}/
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o "bin/linux/${PROJECT_NAME}" github.com/DataReply/${PROJECT_NAME}/
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags "$(LDFLAGS)" -o "bin/windows/${PROJECT_NAME}" github.com/DataReply/${PROJECT_NAME}/

test:
	CGO_ENABLED=0 go test github.com/DataReply/${PROJECT_NAME}/...

clean:
	rm -rf bin
