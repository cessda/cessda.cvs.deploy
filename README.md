# CESSDA Vocabularies Service Deployment

This repository contains all the scripts and infrastructure definitions needed to deploy the CESSDA Vocabularies Service.

## Prerequisites

In order to deploy the Vocabularies Service, you need:

* Access to the CESSDA Jenkins infrastructure
* Permissions to use kubectl and gcloud commands in Jenkins
  * This should already be set up
* Permissions to access the CESSDA Bitbucket repos
* Deployed images for the following components:
  * cvs-gui

## Project Structure

```bash
<ROOT>
├── elasticsearch/		# Deployment manifests for Elasticsearch
├── flatdb/				# Deployment manifests for the flatdb component
├── gui/				# Deployment manifests for the gui component
├── mysql/				# Deployment manifests for the MySQL component
├─ Jenkinsfile			# Jenkins script to control the deployment
```

## Technology Stack

Several frameworks are used for the Vocabularies Service.

| Framework/Technology                                 | Description                                              |
| ---------------------------------------------------- | -------------------------------------------------------- |
| [Kubernetes](http://www.kubernetes.io)               | Kubernetes is a container orchestrator                   |
| [Elasticsearch](https://www.elastic.co/products/elasticsearch)| Used for indexing and storing indexed data.     |
| [stardat-ddiflatdb](https://git.gesis.org/stardat/stardat-ddiflatdb)|                                           |

Frameworks used in other components are mentioned in their respective readme files.

## Deploying

All deployments to the CESSDA infrastructure are done via Jenkins. This is to ensure continuous deployments with known centralised configuration. Deployment to each environment (development, staging and live) is done by selecting the branch corresponding to the environment to be deployed to.

## Manually Running the Deployment

Deployments are generally run as part of the pipeline. If necessary, deployments can be run outside of the pipeline. In Jenkins when the job is run you may select the component to be deployed and the image used in that deployment.

## Technical Details

### Elasticsearch

Elasticsearch is configured to run as a cluster with 3 replicas. Each replica can perform any Elasticsearch role. The minimum number of masters is set at 2 to avoid a split-brain cluster from happening. The version of Elasticsearch used is 5.6.

Elasticsearch is run as a stateful set with Persistent Volumes for each node so that state persists over restarts of the nodes in Kubernetes. Two services expose the Elasticsearch cluster, cvs-es is a standard service used for the indexer and Searchkit to access the cluster and cvs-es-discovery is a headless service used so Elasticsearch nodes can find each other and cluster.

### Other Components

Details for other components can be viewed in their respective repos

## Resources

* [Issue tracker](https://bitbucket.org/cessda/cessda.cvs.deploy/issues)

## Authors

**Matthew Morris (matthew.morris@cessda.eu)** - *CESSDA Technical Officer*
**Joshua Ocansey (joshua.ocancey@cessda.eu)** - *CESSDA Technical Officer*
