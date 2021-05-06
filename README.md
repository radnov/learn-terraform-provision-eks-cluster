# Configuration
## Cluster
```bash
terraform init
time terraform apply -auto-approve
terraform output -raw kubectl_config > ~/.kube/dhis.yaml
export KUBECONFIG="$HOME/.kube/dhis.yaml"
kubectl get nodes
```

## Ingress Controller
```bash
cd stacks/cluster
LB_IP="-" helmfile --selector name=ingress-nginx sync
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

## WhoAmI Application
```bash
cd stacks/application
helmfile --selector name=whoami-go sync
cd -

http http://whoami-go-$LB_IP.nip.io
```

## DHIS2 Database
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

## DHIS2 Application
```bash
cd stacks/application
helmfile --selector name=dhis2-core sync
cd -
```

# Teardown
```bash
terraform destroy -auto-approve
```

# TODO
* Create seed parameter in values.yaml
* Set default storage class so we don't have specify gp2 on our pvc's
* Proper DNS handling, I'm merely getting the first ip associated with load balancer hostname... In reality, we should properly do a cname forward

# Learn Terraform - Provision an EKS Cluster

This repo is a companion repo to the [Provision an EKS Cluster learn guide](https://learn.hashicorp.com/terraform/kubernetes/provision-eks-cluster), containing
Terraform configuration files to provision an EKS cluster on AWS.
