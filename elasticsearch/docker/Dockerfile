# Elasticsearch Base Image
FROM elasticsearch:5.6

# Update base image
USER root
RUN apt-get -qq update && apt-get -qq -y upgrade

# Install required plugins
RUN bin/elasticsearch-plugin install repository-gcs -s

# Switch to non-root user
USER elasticsearch
