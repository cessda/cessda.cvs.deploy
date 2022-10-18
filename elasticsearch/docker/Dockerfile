# Elasticsearch Base Image
FROM elasticsearch:6.8.23

# Install required plugins
RUN bin/elasticsearch-plugin install --batch repository-gcs
RUN bin/elasticsearch-plugin list | grep -q analysis-icu || bin/elasticsearch-plugin install analysis-icu
