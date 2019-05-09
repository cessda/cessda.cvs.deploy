#!/bin/bash

#############################
#          CESSDA           #
#      Cluster Setup        #
#############################

# Matthew Morris
# CESSDA ERIC
# matthew.morris(at)cessda.eu

### Kubernetes configuration generation ###
sed "s#DEPLOYMENTNAME#$product_name-$module_name#g; s#NAMESPACE#$product_name#g" ../k8s/template-deployment.yaml > ../k8s/$product_name-$module_name-deployment.yaml
sed "s/SERVICENAME/$product_name-$module_name/g; s/NAMESPACE/$product_name/g" ../k8s/template-service.yaml > ../k8s/$product_name-$module_name-service.yaml
sed "s/DEPLOYMENTNAME/$product_name-$module_name/g; s/NAMESPACE/$product_name/g" ../k8s/template-secret.yaml > ../k8s/$product_name-$module_name-secret.yaml

# Secret
kubectl apply -f ../k8s/$product_name-$module_name-secret.yaml

# Deployment
kubectl apply -f ../k8s/$product_name-$module_name-deployment.yaml

# Service
kubectl apply -f ../k8s/$product_name-$module_name-service.yaml
