# CESSDA Vocabularies Service Deployment

This repository contains all the scripts and infrastructure definitions needed to deploy the CESSDA Vocabularies Service.

## Prerequisites

In order to deploy the Vocabularies Service, you need:

* Access to the CESSDA Jenkins infrastructure
* Permissions to use kubectl and `gcloud` commands in Jenkins
	* This should already be set up
* Permissions to access the CESSDA Bitbucket repos
* Deployed images for the following components:
	* `cvs-gui`

## Project Structure

```bash
<ROOT>
├── ./charts/es/              # Deployment manifests for Elasticsearch
├── ./charts/frontend/        # Deployment manifests for the Frontend
├── ./charts/mysql/           # Deployment manifests for MySQL
├─ Chart.yaml                 # Declares chart metadata
├─ Jenkinsfile                # Jenkins script to control the deployment
├─ values.yaml                # Declares configuration for the chart, can be overridden with --set
```

## Technology Stack

Several frameworks are used for the Vocabularies Service.

| Framework/Technology                                 | Description                                              |
| ---------------------------------------------------- | -------------------------------------------------------- |
| [Kubernetes](http://www.kubernetes.io)               | Kubernetes is a container orchestrator                   |
| [Elasticsearch](https://www.elastic.co/products/elasticsearch)| Used for indexing and storing indexed data.     |

Frameworks used in other components are mentioned in their respective readme files.

## Deploying

All deployments to the CESSDA infrastructure are done via Jenkins. This is to ensure continuous deployments with known centralised configuration. Deployment to the non-production environments (development, staging) is automated - checking code in to the Master branch causes the application to be built and deployed via a Jenkins pipeline (provided the various quality checks are successful). Deployment to production is a manual process, started by an administrator running a Jenkins job.

## Technical Details

### Elasticsearch

Elasticsearch is configured to run as a cluster with 3 replicas. Each replica can perform any Elasticsearch role. The minimum number of masters is set at 2 to avoid a split-brain cluster from happening. The version of Elasticsearch used is 6.8.

Elasticsearch is run as a stateful set with Persistent Volumes for each node so that state persists over restarts of the nodes in Kubernetes. Two services expose the Elasticsearch cluster, `cvs-es` is a standard service used for the frontend to access the cluster and `cvs-es-discovery` is a headless service used so Elasticsearch nodes can find each other and cluster.

### MySQL

MySQL is hosted on [Google Cloud SQL](https://cloud.google.com/sql/). This is a managed SQL solution that takes care of maintenance and backups. The chart contains service and endpoint definitions that act as pointers to the Cloud SQL database so that it can be swapped with a database that runs on Kubernetes without application changes.

### Other Components

Details for other components can be viewed in their respective repositories.

## Resources

* [Issue tracker](https://bitbucket.org/cessda/cessda.cvs.gui/issues)

## Authors

**Matthew Morris (matthew.morris@cessda.eu)** - *CESSDA Technical Officer*  
**Joshua Ocansey (joshua.ocancey@cessda.eu)** - *CESSDA Technical Officer*
