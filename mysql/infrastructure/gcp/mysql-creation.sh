#!/bin/bash

#############################
#          CESSDA           #
#      Cluster Setup        #
#############################

# Matthew Morris
# CESSDA ERIC
# matthew.morris(at)cessda.eu

### Kubernetes configuration generation ###
sed "s/SERVICENAME/$product_name-$module_name/g; s/NAMESPACE/$product_name/g" ../k8s/template-service.yaml > ../k8s/$product_name-$module_name-service.yaml

# Service
kubectl apply -f ../k8s/$product_name-$module_name-service.yaml
