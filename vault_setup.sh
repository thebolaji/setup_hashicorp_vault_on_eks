aws eks --region us-east-1 update-kubeconfig --name VAULT-CLUSTER --profile <profilename>
kubectl create namespace vault
helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault