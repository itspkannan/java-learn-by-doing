.DEFAULT_GOAL := help

include Makefile_cluster.mk
include Makefile_java.mk

.PHONY: help

help: ## 📘 Show this help message
	@echo "\n\033[1;33mAvailable commands:\033[0m" \
	    && awk -F ':.*## ' '/^[a-zA-Z0-9_.-]+:.*## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) \
	    | sort && echo ""
