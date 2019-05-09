#!/bin/bash

#############################
#          CESSDA           #
#      Cluster Setup        #
#############################

# Matthew Morris
# CESSDA ERIC
# matthew.morris(at)cessda.eu

# Namespace Creation
if kubectl get ns $product_name > /dev/null 2>&1;
    then
        echo "Namespace already exists"
    else
        kubectl create namespace $product_name
        echo "Namespace created"
fi;

### Kubernetes configuration generation ###
sed "s#DEPLOYMENTNAME#$product_name-$module_name#g; s#NAMESPACE#$product_name#g" ../k8s/template-statefulset.yaml > ../k8s/$product_name-$module_name-statefulset.yaml
sed "s/SERVICENAME/$product_name-$module_name/g; s/NAMESPACE/$product_name/g" ../k8s/template-service.yaml > ../k8s/$product_name-$module_name-service.yaml
sed "s/SERVICENAME/$product_name-$module_name/g; s/NAMESPACE/$product_name/g" ../k8s/template-discovery.yaml > ../k8s/$product_name-$module_name-discovery.yaml
sed "s/DEPLOYMENTNAME/$product_name-$module_name/g; s/NAMESPACE/$product_name/g" ../k8s/template-configmap.yaml > ../k8s/$product_name-$module_name-configmap.yaml

# Configmap
kubectl apply -f ../k8s/$product_name-$module_name-configmap.yaml

# Deployment
kubectl apply -f ../k8s/$product_name-$module_name-statefulset.yaml

# Service
kubectl apply -f ../k8s/$product_name-$module_name-service.yaml
kubectl apply -f ../k8s/$product_name-$module_name-discovery.yaml