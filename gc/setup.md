# Setup

### Cluster Command

The help command will display all the project specific command that is needed for bootstrapping the application, running test and cleaning up the resources. The list doesnot include the complete list only has cluster specific commands.
```bash

❯ make help

Available commands:
  app.logs             📜 Show logs from pod
  app.pods             🔍 Get pod name for release
  app.service          🌐 Show service endpoint
  build                🛠️ Build Docker image for given app
  calico.init          🧬 Initial Calico CNI
  calico.test          🧪 Wait for Calico pods to be ready
  check_app_name       🧪 Ensure APP_NAME is set and folder exists
  clean                🧹 Remove Docker images
  create.cluster       🚀 Create K3d cluster with custom registry
  create.network       🌐 Create a K3d network
  delete               🧹 Delete resources created.
  delete.cluster       🧹 Delete the k3d cluster and registry
  delete.network       ❌ Delete a K3d network
  describe.cluster     🔍 Describe the k3d cluster
  fluentbit.install    🔧 Install Fluent Bit without broken /etc/machine-id mount
  fluentbit.logs       📜 Tail Fluent Bit logs
  fluentbit.test       ✅ Wait for Fluent Bit pods to be ready
  get.nodes            📋 List Kubernetes nodes
  helm.image           🔍 Show deployed image from Helm
  helm.install         📦 Install Helm chart
  helm.template        🔍 Dry-run Helm rendering
  helm.uninstall       ❌ Uninstall Helm release
  helm.upgrade         🔁 Upgrade Helm chart
  help                 📘 Show this help message
  init                 🧰 Initialize the resources needed
  init.observability   🔎 Setup logging tools
  inspect              🖼️ Print and inspect the image
  kubeconfig           🧾 Merge kubeconfig and switch context
  publish              🚀 Build, tag and push image
  push                 📤 Push the image to local registry
  start.registry       🏁 Start Docker registry using Compose
  stop.registry        🛑 Stop Docker registry
  tag                  🔖 Tag the built Docker image

```

### Create the infrastructure

The infrastructure for application is 

- K3d Cluster
- Docker Registry
- CNI - Calico
- Fluentbid 

The command will create necessary infrastructure for the application

![Init Cluster](docs/images/init_cluster.gif)


### Cleanup the resource 

![Delete Resource Created](docs/images/delete_cluster.gif)