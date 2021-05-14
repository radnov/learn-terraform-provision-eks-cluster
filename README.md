<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Cluster](#cluster)
- [RBAC](#rbac)
  - [Inspiration](#inspiration)
  - [Terraform](#terraform)
  - [K8s](#k8s)
  - [Apply cluster stack](#apply-cluster-stack)
  - [Retrieve kubectl config for development namespace](#retrieve-kubectl-config-for-development-namespace)
  - [Retrieve kubectl config as admin user](#retrieve-kubectl-config-as-admin-user)
- [Ingress Controller](#ingress-controller)
- [WhoAmI Application](#whoami-application)
- [DHIS2 Database](#dhis2-database)
- [DHIS2 Application](#dhis2-application)
- [Teardown](#teardown)
- [TODO](#todo)
- [Why's](#whys)
- [Learn Terraform - Provision an EKS Cluster](#learn-terraform---provision-an-eks-cluster)
- [Tasks](#tasks)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Cluster
```bash
./init.sh
time terraform apply -auto-approve
terraform output -raw kubectl_config > ~/.kube/dhis.yaml
export KUBECONFIG="$HOME/.kube/dhis.yaml"
kubectl get nodes
```

# RBAC
## Inspiration
* https://www.eksworkshop.com/beginner/091_iam-groups/intro/
* https://medium.com/swlh/secure-an-amazon-eks-cluster-with-iam-rbac-b78be0cd95c9
* https://marcincuber.medium.com/amazon-eks-rbac-and-iam-access-f124f1164de7

## Apply cluster stack
Install roles and rolebindings to the various namespaces, currently only done for "development"
```bash
cd stacks/cluster && helmfile --selector name=rbac-development sync && cd -
```

## Retrieve kubectl config for development namespace
```bash
export CLUSTER_NAME=(terraform output -raw cluster_name)
export REGION=(terraform output -raw region)
export ROLE_ARN=(terraform output -json group-to-role-arns | jq -r '."dhis-poc-development"')

aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME --profile dhis-rbac --kubeconfig ./eks.yaml

echo "[profile dev]
role_arn=$ROLE_ARN
source_profile=dhis-rbac" >> ~/.aws/config

# Update env.AWS_PROFILE in ./eks.yaml to "dev" ... Or to whatever is defined in ~/.aws/config 
k --kubeconfig ./eks.yaml get pods --namespace development
k --kubeconfig ./eks.yaml get pods --namespace default
```

## Retrieve kubectl config as admin user
```bash
export CLUSTER_NAME=(terraform output -raw cluster_name)
export REGION=(terraform output -raw region)
export ROLE_ARN=(terraform output -json group-to-role-arns | jq -r '."dhis-poc-admin"')

aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME --profile dhis-rbac --kubeconfig ./eks-admin.yaml

echo "[profile admin]
role_arn=$ADMIN_ROLE_ARN
source_profile=dhis-rbac" >> ~/.aws/config

# Update env.AWS_PROFILE in ./eks-admin.yaml to "admin" ... Or to whatever is defined in ~/.aws/config 
k --kubeconfig ./eks-admin.yaml get pods --namespace default
```

# Ingress Controller
```bash
cd stacks/cluster
helmfile --selector name=ingress-nginx sync
cd -
```

Wait until the load balancer ip is assigned
```bash
kubectl --namespace ingress get services ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].hostname}"
```

Retrieve IP
```bash
export LB_HOSTNAME=$(kubectl --namespace ingress get services ingress-nginx-controller -o jsonpath="{.status.loadBalancer.ingress[0].hostname}")
export LB_IP=$(dig $LB_HOSTNAME +short | head -n 1)
echo "LB: $LB_IP"
```

# WhoAmI Application
```bash
cd stacks/application
helmfile --selector name=whoami-go sync
cd -

http http://whoami-go-$LB_IP.nip.io
```

# DHIS2 Database
```bash
cd stacks/application
helmfile --selector name=dhis2-core-database sync
cd -
```

Tail database logs
```bash
kubectl logs --namespace dhis2-core dhis2-core-database-postgresql-0 -f
```

Configure Post GIS extension
```bash
export POSTGRES_ADMIN_PASSWORD=$(kubectl get secret --namespace dhis2-core dhis2-core-database-postgresql -o jsonpath="{.data.postgresql-postgres-password}" | base64 --decode)
kubectl run dhis2-core-database-postgresql-client --rm --tty -i --restart='Never' --namespace dhis2-core --image docker.io/bitnami/postgresql:10 --env="PGPASSWORD=$POSTGRES_ADMIN_PASSWORD" --command -- /bin/sh -c 'echo "create extension postgis; \dx;" | psql --host dhis2-core-database-postgresql -U postgres -d dhis2 -p 5432'
```

# DHIS2 Application
```bash
cd stacks/application
helmfile --selector name=dhis2-core sync
cd -
```

# Teardown
```bash
time terraform destroy -auto-approve
```

# TODO
* Create seed parameter in values.yaml
* Proper DNS handling, I'm merely getting the first ip associated with load balancer hostname... In reality, we should properly do a cname forward

# Learn Terraform - Provision an EKS Cluster

This repo is a companion repo to the [Provision an EKS Cluster learn guide](https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster), containing
Terraform configuration files to provision an EKS cluster on AWS.
