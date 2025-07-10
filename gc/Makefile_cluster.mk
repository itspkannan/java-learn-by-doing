CLUSTER_NAME = java-gc-cluster
K3D_TEMPLATE = k3d-config.template.yaml
K3D_CONFIG = k3d-config.yaml
DEFAULT_REG = localhost:5000
DOCKER_COMPOSE_CMD = CLUSTER_NAME=$(CLUSTER_NAME) docker compose

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
	@env CLUSTER_NAME=$(CLUSTER_NAME) envsubst < $(K3D_TEMPLATE) > $(K3D_CONFIG)
	@echo "[INFO] Config generated: $(K3D_CONFIG)"

.PHONY: create.cluster
create.cluster: generate.k3d.config ## 🚀 Create K3d cluster with custom registry
	@echo "[INFO] Creating K3d cluster: $(CLUSTER_NAME)"
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

.PHONY: init
init: create.network start.registry create.cluster clean.temp.cluster.config calico.init calico.test ## 🧰 Initialize the resources needed
	@echo "[INFO] Started initialization of $(CLUSTER_NAME) Cluster"
	@echo "[INFO] Completed initialization of $(CLUSTER_NAME) Cluster"

.PHONY: delete.network
delete.network: ## ❌ Delete a K3d network
	@echo "[INFO] Deleting network for $(CLUSTER_NAME)"
	@docker network rm k3d-$(CLUSTER_NAME) || true
	@echo "[INFO] Network deleted for $(CLUSTER_NAME)"

.PHONY: delete.cluster
delete.cluster: ## 🧹 Delete the k3d cluster and registry
	@echo "[INFO] Deleting K3d cluster: $(CLUSTER_NAME)"
	@k3d cluster delete $(CLUSTER_NAME)
	@echo "[INFO] Cluster deleted: $(CLUSTER_NAME)"

.PHONY: delete
delete: delete.cluster stop.registry delete.network ## 🧹 Delete resources created.
	@echo "[INFO] All resources deleted for $(CLUSTER_NAME)"
