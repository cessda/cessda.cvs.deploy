#!/bin/bash

#############################
#          CESSDA           #
#      Cluster Setup        #
#############################

# Matthew Morris
# CESSDA ERIC
# matthew.morris@cessda.eu


#OpenAPI configuration
sed "s/BRANCHNAME/$ENVIRONMENT/g; s/ENDPOINTSNAME/$product_name-$ENVIRONMENT/g;" ./template-api-docs.json > $product_name-$module_name-api-docs.json

### Kubernetes configuration generation ###
sed "s/DEPLOYMENTNAME/$CLIENT-$product_name-$module_name-$ENVIRONMENT/g; s/NAMESPACE/$CLIENT-$product_name-$ENVIRONMENT/g; s/ENVIRONMENT/$ENVIRONMENT/g" ../k8s/template-$product_name-$module_name-deployment.yaml > ../k8s/$product_name-$module_name-deployment.yaml
sed "s/SERVICENAME/$product_name-$module_name-$ENVIRONMENT/g; s/NAMESPACE/$CLIENT-$product_name-$ENVIRONMENT/g" ../k8s/template-service.yaml > ../k8s/$product_name-$module_name-service.yaml
sed "s/NAMESPACE/$product_name-$/g" ../k8s/template-serviceaccount.yaml > ../k8s/$product_name-$module_name-$-serviceaccount.yaml

# OpenAPI Deployment
gcloud endpoints services deploy $product_name-$module_name-api-docs.json

#Sesrvice Account
kubectl apply -f ../k8s/$product_name-$module_name-serviceaccount.yaml

# Deployment
kubectl apply -f ../k8s/$product_name-$module_name-deployment.yaml

# Service
kubectl apply -f ../k8s/$product_name-$module_name-service.yaml

