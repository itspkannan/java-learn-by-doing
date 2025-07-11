CLUSTER_NAME = java-gc-cluster
K3D_TEMPLATE = k3d-config.template.yaml
K3D_CONFIG = k3d-config.yaml
DEFAULT_REG = localhost:5000
DOCKER_COMPOSE_CMD = CLUSTER_NAME=$(CLUSTER_NAME) docker compose
FLUENT_BIT_NAMESPACE=logging
FLUENT_BIT_RELEASE=fluent-bit
ROOT_DIR := $(realpath $(dir $(lastword $(MAKEFILE_LIST))))
FLUENT_BIT_DIR ?= $(ROOT_DIR)/.fluent-bit

.PHONY: create.network
create.network: ## 🌐 Create a K3d network
	@echo "[INFO] Creating network for $(CLUSTER_NAME)"
	@docker network create k3d-$(CLUSTER_NAME)
	@echo "[INFO] Network created for $(CLUSTER_NAME)"

.PHONY: start.registry
start.registry: ## 🏁 Start Docker registry using Compose
	@echo "[INFO] Starting registry for $(CLUSTER_NAME)"
	@$(DOCKER_COMPOSE_CMD) up -d
	@echo "[INFO] Registry started for $(CLUSTER_NAME)"

.PHONY: stop.registry
stop.registry: ## 🛑 Stop Docker registry
	@echo "[INFO] Stopping registry for $(CLUSTER_NAME)"
	@$(DOCKER_COMPOSE_CMD) down
	@echo "[INFO] Registry stopped for $(CLUSTER_NAME)"

.PHONY: generate.k3d.config
generate.k3d.config:
	@echo "[INFO] Generating config for $(CLUSTER_NAME)"
	@CLUSTER_NAME="$(CLUSTER_NAME)" FLUENT_BIT_DIR="$(FLUENT_BIT_DIR)" \
		envsubst < $(K3D_TEMPLATE) > $(K3D_CONFIG)
	@echo "[INFO] Config generated: $(K3D_CONFIG)"

.PHONY: create.cluster
create.cluster: generate.k3d.config ## 🚀 Create K3d cluster with custom registry
	@echo "[INFO] Creating K3d cluster: $(CLUSTER_NAME)"
	@mkdir -p $(FLUENT_BIT_DIR)/data/gc-logs
	@touch $(FLUENT_BIT_DIR)/dummy-machine-id
	@mkdir -p $(FLUENT_BIT_DIR)/sim-k8s-logs/var/log/containers
	@mkdir -p $(FLUENT_BIT_DIR)/logs
	@chmod 777 $(FLUENT_BIT_DIR)/data/gc-logs
	@chmod 777 $(FLUENT_BIT_DIR)/logs
	@chmod 777 $(FLUENT_BIT_DIR)/sim-k8s-logs/var/log/containers
	@k3d cluster create --config $(K3D_CONFIG)
	@echo "[INFO] Cluster $(CLUSTER_NAME) created"

.PHONY: clean.temp.cluster.config
clean.temp.cluster.config:
	@echo "[INFO] Cleaning up config: $(K3D_CONFIG)"
	@rm -f $(K3D_CONFIG)
	@echo "[INFO] Config cleanup done"

.PHONY: calico.init
calico.init: ## 🧬 Initial Calico CNI 
	@echo "[INFO] Applying Calico CNI to $(CLUSTER_NAME)"
	@kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml
	@echo "[INFO] Calico CNI applied"

.PHONY: calico.test
calico.test: ## 🧪 Wait for Calico pods to be ready
	@echo "[INFO] Waiting for Calico pods in $(CLUSTER_NAME)"
	@kubectl wait --for=condition=Ready pod --all -n kube-system --timeout=180s
	@echo "[INFO] Calico pods are ready"

PHONY: fluentbit.install
fluentbit.install: ## 🔧 Install Fluent Bit with file output (no /etc/machine-id mount)
	@echo "[INFO] Adding Fluent Bit Helm repo (if needed)..."
	@helm repo add fluent https://fluent.github.io/helm-charts || true
	@helm repo update
	@echo "[INFO] Installing Fluent Bit to namespace: $(FLUENT_BIT_NAMESPACE)"
	@helm upgrade --install $(FLUENT_BIT_RELEASE) fluent/fluent-bit \
		--namespace $(FLUENT_BIT_NAMESPACE) \
		--create-namespace \
		-f fluentbit-values.yaml
	@echo "[INFO] Fluent Bit installed with file output to /fluent-bit/logs"

.PHONY: fluentbit.test
fluentbit.test: ## ✅ Wait for Fluent Bit pods to be ready
	@echo "[INFO] Waiting for Fluent Bit pods..."
	@kubectl wait --for=condition=Ready pod --all -n $(FLUENT_BIT_NAMESPACE) --timeout=180s
	@echo "[INFO] Fluent Bit is ready"

.PHONY: fluentbit.logs
fluentbit.logs: ## 📜 Tail Fluent Bit logs
	@POD=$$(kubectl get pod -n $(FLUENT_BIT_NAMESPACE) -l "app.kubernetes.io/name=fluent-bit" -o jsonpath="{.items[0].metadata.name}"); \
	echo "📜 [LOGS] Fluent Bit pod: $$POD"; \
	kubectl logs -n $(FLUENT_BIT_NAMESPACE) $$POD -f

.PHONY: fluentbit.list
fluentbit.info:
	@echo "[INFO] Flient Bit Daemonset..." 
	@kubectl get daemonset -n logging
	@echo ""
	@echo "[INFO] Fluent Bit Pods and Daemons"
	@echo ""
	@kubectl get pod -n $(FLUENT_BIT_NAMESPACE)" 
	@echo ""
	@echo "[INFO] Fluent Bit Configmap"
	@kubectl get configmap fluent-bit -n $(FLUENT_BIT_NAMESPACE) -o yaml | grep -A20 '\[OUTPUT\]'


.PHONY: init.observability
init.observability: fluentbit.install fluentbit.test ## 🔎 Setup logging tools
	@echo "[INFO] Observability stack ready (Fluent Bit)"

.PHONY: get.nodes
get.nodes: ## 📋 List Kubernetes nodes
	@echo "[INFO] Getting nodes in $(CLUSTER_NAME)"
	@kubectl get nodes -o wide

.PHONY: describe.cluster
describe.cluster: ## 🔍 Describe the k3d cluster
	@echo "[INFO] Describing cluster: $(CLUSTER_NAME)"
	@k3d cluster list $(CLUSTER_NAME)


.PHONY: kubeconfig
kubeconfig: ## 🧾 Merge kubeconfig and switch context
	@echo "[INFO] Merging kubeconfig and switching context to $(CLUSTER_NAME)"
	@k3d kubeconfig merge $(CLUSTER_NAME) --switch-context

.PHONY: init.cluster
init.cluster: create.network start.registry create.cluster clean.temp.cluster.config calico.init calico.test ## 🧰 Initialize the resources needed
	@echo "[INFO] Started initialization of $(CLUSTER_NAME) Cluster"
	@echo "[INFO] Completed initialization of $(CLUSTER_NAME) Cluster"

.PHONY: init
init: init.cluster init.observability ## 🧰 Initialize the resources needed
	@echo "[INFO] Started initialization of $(CLUSTER_NAME) Cluster"
	@echo "[INFO] Completed initialization of $(CLUSTER_NAME) Cluster"

.PHONY: delete.network
delete.network: ## ❌ Delete a K3d network
	@echo "[INFO] Deleting network for $(CLUSTER_NAME)"
	@docker network rm k3d-$(CLUSTER_NAME) || true
	@rm -rf $(FLUENT_BIT_DIR)
	@echo "[INFO] Network deleted for $(CLUSTER_NAME)"

.PHONY: delete.cluster
delete.cluster: ## 🧹 Delete the k3d cluster and registry
	@echo "[INFO] Deleting K3d cluster: $(CLUSTER_NAME)"
	@k3d cluster delete $(CLUSTER_NAME)
	@echo "[INFO] Cluster deleted: $(CLUSTER_NAME)"

.PHONY: delete
delete: delete.cluster stop.registry delete.network ## 🧹 Delete resources created.
	@echo "[INFO] All resources deleted for $(CLUSTER_NAME)"
