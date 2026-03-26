MODULES := eks clickhouse-operator clickhouse-cluster
EXAMPLES := default eks-cluster-only arm-graviton public-loadbalancer public-subnets-only

.PHONY: fmt validate lint validate-examples check check-all

fmt:
	@find . -name '*.tf' -not -path '*/.terraform/*' -execdir terraform fmt -check {} +

validate:
	@for m in $(MODULES); do \
		echo "==> Validating $$m"; \
		[ -d "$$m/.terraform" ] || terraform -chdir=$$m init -backend=false -no-color > /dev/null 2>&1; \
		terraform -chdir=$$m validate -no-color; \
	done

lint:
	tflint --init > /dev/null 2>&1
	tflint

validate-examples:
	@for e in $(EXAMPLES); do \
		echo "==> Validating example $$e"; \
		[ -d "examples/$$e/.terraform" ] || terraform -chdir=examples/$$e init -backend=false -no-color > /dev/null 2>&1; \
		terraform -chdir=examples/$$e validate -no-color; \
	done

check: fmt validate lint

check-all: check validate-examples
