#! /bin/sh

set -x

k3d cluster create demo-cluster

docker build -t task-producer -f Dockerfile-producer .
docker build -t task-consumer -f Dockerfile-consumer .

k3d image import task-producer --cluster demo-cluster
k3d image import task-consumer --cluster demo-cluster


echo "taskpassword" > postgres-password.txt
kubectl create secret generic postgres-secret --from-file=password=postgres-password.txt

kubectl create secret generic postgres-secret \
  --from-literal=host=postgres-service \
  --from-literal=port=5432 \
  --from-literal=dbName=taskdb \
  --from-literal=user=taskuser \
  --from-literal=password=taskpassword \
  --from-literal=sslmode=disable

helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda 

kubectl apply -f postgres-deployment.yaml
kubectl apply -f task-producer-deployment.yaml
kubectl apply -f task-consumer-deployment.yaml

kubectl apply -f keda-scaledobject.yaml
