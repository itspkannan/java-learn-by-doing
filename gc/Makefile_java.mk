ROOT_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
VERSION        ?= latest
GRADLE_IMAGE   ?= gradle:8.4-jdk17
RUNTIME_IMAGE  ?= azul/zulu-openjdk:17.0.15-17.58
REGISTRY       ?= localhost:5000
CHART_DIR      ?= $(ROOT_DIR)/app-helm-charts
FULL_IMAGE_NAME := $(REGISTRY)/$(APP_NAME):$(VERSION)
HELM_NAMESPACE ?= $(APP_NAME)


.PHONY: check_app_name
check_app_name: ## 🧪 Ensure APP_NAME is set and folder exists
	@if [ -z "$(APP_NAME)" ]; then \
		echo "❌ APP_NAME is not set. Usage: make <target> APP_NAME=app-1 [VERSION=latest] [JDK_VERSION=17]"; \
		exit 1; \
	elif [ ! -d "$(APP_NAME)" ]; then \
		echo "❌ Folder '$(APP_NAME)' does not exist."; \
		exit 1; \
	else \
		echo "✅ Using app: $(APP_NAME)"; \
	fi

.PHONY: build
build: check_app_name ## 🛠️ Build Docker image for given app
	@echo "🛠️  [BUILD] Building Docker image: $(FULL_IMAGE_NAME)"
	@echo "     ├─ Gradle image : $(GRADLE_IMAGE)"
	@echo "     └─ Runtime image: $(RUNTIME_IMAGE)"
	docker build \
		--build-arg SERVICE_NAME=$(APP_NAME) \
		--build-arg FULL_IMAGE_NAME=$(FULL_IMAGE_NAME) \
		--build-arg GRADLE_IMAGE=$(GRADLE_IMAGE) \
		--build-arg RUNTIME_IMAGE=$(RUNTIME_IMAGE) \
		-t $(APP_NAME) \
		-f Dockerfile .
	@echo "✅ [BUILD] Done building $(APP_NAME)"

.PHONY: tag
tag: check_app_name ## 🔖 Tag the built Docker image
	@echo "🔖 [TAG] Tagging image as $(FULL_IMAGE_NAME)..."
	docker tag $(APP_NAME) $(FULL_IMAGE_NAME)
	@echo "✅ [TAG] Done tagging image"

.PHONY: push
push: check_app_name ## 📤 Push the image to local registry
	@echo "📤 [PUSH] Pushing image to local registry..."
	docker push $(FULL_IMAGE_NAME)
	@echo "✅ [PUSH] Done pushing to $(REGISTRY)"

.PHONY: publish
publish: check_app_name build tag push ## 🚀 Build, tag and push image
	@echo "🚀 [PUBLISH] Image published: $(FULL_IMAGE_NAME)"

.PHONY: clean
clean: check_app_name ## 🧹 Remove Docker images
	@echo "🧹 [CLEAN] Removing local Docker images..."
	docker rmi $(APP_NAME) $(FULL_IMAGE_NAME) || true
	@echo "✅ [CLEAN] Images removed"

.PHONY: inspect
inspect: check_app_name ## 🖼️ Print and inspect the image
	@echo "🖼️  [INFO] Built image: $(FULL_IMAGE_NAME)"
	@dive $(FULL_IMAGE_NAME)


helm.install: check_app_name ## 📦 Install Helm chart
	@echo "📦 [HELM INSTALL] Installing chart for $(APP_NAME)..."
	helm install $(APP_NAME) $(CHART_DIR) \
		--set image.repository=$(REGISTRY)/$(APP_NAME) \
		--set image.tag=$(VERSION) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace
	@echo "✅ [HELM INSTALL] Done"

helm.upgrade: check_app_name ## 🔁 Upgrade Helm chart
	@echo "🔁 [HELM UPGRADE] Upgrading chart for $(APP_NAME)..."
	helm upgrade $(APP_NAME) $(CHART_DIR) \
		--set image.repository=$(REGISTRY)/$(APP_NAME) \
		--set image.tag=$(VERSION) \
		--namespace $(HELM_NAMESPACE) \
		--create-namespace
	@echo "✅ [HELM UPGRADE] Done"


helm.uninstall: check_app_name ## ❌ Uninstall Helm release
	@echo "❌ [HELM UNINSTALL] Uninstalling release: $(APP_NAME) from namespace: $(HELM_NAMESPACE)"
	@helm uninstall $(APP_NAME) --namespace $(HELM_NAMESPACE) || true

	@echo "🧹 [NAMESPACE DELETE] Deleting namespace: $(HELM_NAMESPACE)"
	@kubectl delete namespace $(HELM_NAMESPACE) --ignore-not-found=true

	@echo "✅ [CLEANUP] $(APP_NAME) and namespace $(HELM_NAMESPACE) removed"

helm.template: check_app_name ## 🔍 Dry-run Helm rendering
	@echo "🔍 [HELM TEMPLATE] Rendering chart for $(APP_NAME)..."
	helm template $(APP_NAME) $(CHART_DIR) \
		--set image.repository=$(REGISTRY)/$(APP_NAME) \
		--set image.tag=$(VERSION) \
		--namespace $(HELM_NAMESPACE)

helm.image: check_app_name ## 🔍 Show deployed image from Helm
	@echo "🔍 [HELM IMAGE] Deployed image for release $(APP_NAME):"
	@helm get values $(APP_NAME) -o yaml | grep 'repository\|tag' | sed 's/^/   /'

app.service: check_app_name ## 🌐 Show service endpoint
	@echo ""
	@echo "🌐 [HELM SERVICE] Service info for $(APP_NAME):"
	@kubectl get svc -n $(HELM_NAMESPACE) -l app.kubernetes.io/instance=$(APP_NAME) -o jsonpath='{.items[0].metadata.name}'
	@echo ""

app.pods: check_app_name ## 🔍 Get pod name for release
	@echo ""
	@echo "🌐 [HELM SERVICE] Pod info for $(APP_NAME):"
	@kubectl get pods -n $(HELM_NAMESPACE) -l app.kubernetes.io/instance=$(APP_NAME) -o jsonpath='{.items[0].metadata.name}'
	@echo ""

app.logs: check_app_name ## 📜 Show logs from pod 
	@POD=$$(kubectl get pods -n $(HELM_NAMESPACE) -l app.kubernetes.io/instance=$(APP_NAME) -o jsonpath='{.items[0].metadata.name}'); \
	if [ -z "$$POD" ]; then \
		echo "❌ No pod found for app '$(APP_NAME)' in namespace '$(HELM_NAMESPACE)'"; \
		exit 1; \
	fi; \
	echo "📜 [LOGS] Logs from $$POD:"; \
	kubectl logs -n $(HELM_NAMESPACE) $$POD