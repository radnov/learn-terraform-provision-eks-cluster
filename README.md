<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->


- [Cluster](#cluster)
- [RBAC](#rbac)
  - [Inspiration](#inspiration)
  - [Terraform](#terraform)
  - [K8s](#k8s)
  - [AWS to K8s link](#aws-to-k8s-link)
    - [Namespace: development](#namespace-development)
  - [Add user to development group](#add-user-to-development-group)
    - [Namespace: something](#namespace-something)
  - [Add user to something group](#add-user-to-something-group)
    - [Admin access](#admin-access)
  - [Retrieve kubectl config for development namespace](#retrieve-kubectl-config-for-development-namespace)
  - [Add user to admin group](#add-user-to-admin-group)
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
terraform init
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

input: namespaces
do some for each with list of namespaces from values

## Terraform
Create module for resources found in rbac.tf
Invoke for each namespace we wish to have

output: $CLUSTER_NAME, $ROLE_ARN

## K8s
Create helm chart for the resources found in rbac.yaml
Apply in each namespace we wish to have
All done in the cluster stack

## AWS to K8s link
### Namespace: development
```bash
export NAMESPACE=development
export CLUSTER_NAME=(terraform output -raw cluster_name)

cd stacks/cluster && helmfile --selector name=rbac-development sync && cd -

export ROLE_ARN=(terraform output -raw development-role-arn)
# $NAMESPACE-user has to match the user specified in the RoleBinding
eksctl create iamidentitymapping --cluster $CLUSTER_NAME --arn $ROLE_ARN --username $NAMESPACE-user
```

## Add user to development group
```bash
aws iam list-groups-for-user --user rbac
export GROUP_NAME=(terraform output -raw development-group-name)
aws iam add-user-to-group --group-name $GROUP_NAME --user-name rbac
aws iam list-groups-for-user --user rbac
```

### Namespace: something
```bash
export NAMESPACE=something
export CLUSTER_NAME=(terraform output -raw cluster_name)

cd stacks/cluster && helmfile --selector name=rbac-something sync && cd -

export ROLE_ARN=(terraform output -raw something-role-arn)
# $NAMESPACE-user has to match the user specified in the RoleBinding
eksctl create iamidentitymapping --cluster $CLUSTER_NAME --arn $ROLE_ARN --username $NAMESPACE-user
```

## Add user to something group
```bash
aws iam list-groups-for-user --user rbac
export GROUP_NAME=(terraform output -raw something-group-name)
aws iam add-user-to-group --group-name $GROUP_NAME --user-name rbac
aws iam list-groups-for-user --user rbac
```

### Admin access
```bash
# Group, role and policy is created for admins just like for normal users but the admin role is associated with the existing user "admin" and the group "system:masters"
export ADMIN_ROLE_ARN=(terraform output -raw admin-role-arn)
eksctl create iamidentitymapping --cluster $CLUSTER_NAME --arn $ADMIN_ROLE_ARN --username admin --group system:masters
```

## Retrieve kubectl config for development namespace
```bash
export CLUSTER_NAME=(terraform output -raw cluster_name)
export REGION=(terraform output -raw region)
aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME --profile dhis-rbac --kubeconfig ./eks.yaml
#eksctl utils write-kubeconfig $CLUSTER_NAME --profile dhis-rbac --region $REGION --kubeconfig ./eks.yaml

echo "[profile dev]
role_arn=$ROLE_ARN
source_profile=dhis-rbac" >> ~/.aws/config

# Update env.AWS_PROFILE in ./eks.yaml to "dev" ... Or to whatever is defined in ~/.aws/config 
k --kubeconfig ./eks.yaml get pods --namespace development
k --kubeconfig ./eks.yaml get pods --namespace default
```

## Add user to admin group
```bash
aws iam list-groups-for-user --user rbac
export ADMIN_GROUP_NAME=(terraform output -raw admin-group-name)
aws iam add-user-to-group --group-name $ADMIN_GROUP_NAME --user-name rbac
aws iam list-groups-for-user --user rbac
```

## Retrieve kubectl config as admin user
```bash
export CLUSTER_NAME=(terraform output -raw cluster_name)
export REGION=(terraform output -raw region)
aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME --profile dhis-rbac --kubeconfig ./eks-admin.yaml
#eksctl utils write-kubeconfig $CLUSTER_NAME --profile dhis-rbac --region $REGION --kubeconfig ./eks-admin.yaml

echo "[profile admin]
role_arn=$ADMIN_ROLE_ARN
source_profile=dhis-rbac" >> ~/.aws/config

# Update env.AWS_PROFILE in ./eks.yaml to "admin" ... Or to whatever is defined in ~/.aws/config 
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
aws iam list-groups-for-user --user rbac

export GROUP_NAME=(terraform output -raw admin-group-name)
aws iam remove-user-from-group --group-name $GROUP_NAME --user-name rbac

export GROUP_NAME=(terraform output -raw development-group-name)
aws iam remove-user-from-group --group-name $GROUP_NAME --user-name rbac

aws iam list-groups-for-user --user rbac

time terraform destroy -auto-approve
```

# TODO
* Create seed parameter in values.yaml
* Proper DNS handling, I'm merely getting the first ip associated with load balancer hostname... In reality, we should properly do a cname forward

# Learn Terraform - Provision an EKS Cluster

This repo is a companion repo to the [Provision an EKS Cluster learn guide](https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster), containing
Terraform configuration files to provision an EKS cluster on AWS.
