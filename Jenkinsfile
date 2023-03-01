def product_name = 'cvs-v2'
pipeline {

    options {
        buildDiscarder logRotator(numToKeepStr: '20')
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'contentguide_image_tag', defaultValue: 'main-latest', description: 'The version of the content guide to deploy, default is latest if unspecified')
        string(name: 'frontend_image_tag', defaultValue: "main-latest", description: 'The version of the application to deploy, default is latest if unspecified')
        string(name: 'userguide_image_tag', defaultValue: "main-latest", description: 'The version of the userguide to deploy, default is latest if unspecified')
        choice choices: ['development-cluster', 'staging-cluster', 'production-cluster'], description: 'Choose which cluster to deploy to', name: 'cluster'
        booleanParam defaultValue: true, description: 'Deploy the CVS application, uncheck to only deploy the documentation.', name: 'deployApp'
    }

    environment {
        es_image_tag = '6.8'
        kubeScoreHome = tool 'kube-score'
        helmHome = tool 'helm'
    }

    agent any

    stages {
        stage('Set up gcloud') {
            steps {
                script {
                    if (cluster == 'production-cluster') {
                        sh 'gcloud config set project cessda-prod'
                    } else {
                        sh 'gcloud config set project cessda-dev'
                    }
                    sh "gcloud container clusters get-credentials ${cluster} --zone=${zone}"
                }
            }
            when { branch 'main' }
        }
        stage('Update CVS Elasticsearch') {
            environment {
                image_tag = "${docker_repo}/cvs-es:${es_image_tag}"
                module_name = "${es_module_name}"
            }
            steps {
                dir('./elasticsearch/docker/') {
                    sh 'gcloud auth configure-docker'
                    sh "docker build -t ${image_tag} ."
                    sh "docker push ${image_tag}"
                }
            }
            when { branch 'main' }
        }
        stage('Run kube-score') {
            steps {
                sh "${helmHome}/helm plugin install https://github.com/hayorov/helm-gcs || true"
                sh "${helmHome}/helm dependency update cvs"
                sh "${helmHome}/helm template ${product_name} cvs | ${kubeScoreHome}/kube-score score - || true"
            }
        }
        stage('Create Namespace') {
            steps {
                withEnv(["product_name=${product_name}"]) {
                sh script: '''
                    set -eu
                    if kubectl get ns $product_name
                        then
                            echo "Namespace already exists"
                        else
                            kubectl create namespace $product_name
                    fi;
                '''
                }
            }
            when { branch 'main' }
        }
        stage('Deploy CVS') {
            environment {
                ELASTICSEARCH_SECRETS = 'cvs/charts/es/secret/'
            }
            steps {
                script {

                    // By default, the chart uses the standard Elasticsearch image, override it here with the CESSDA specific variant
                    def imageSettings = ' --set es.image.repository=eu.gcr.io/cessda-prod/cvs-es --set es.image.tag=${es_image_tag}' + 
                        '  --set frontend.image.tag=${frontend_image_tag} '
                    def mysqlSettings = ' --set mysql.location.address=${MYSQL_ADDRESS} --set mysql.username=${MYSQL_USERNAME} --set mysql.password=${MYSQL_PASSWORD}'
                    def productionSettings = ' --set frontend.mail.baseURL=https://vocabularies-dev.cessda.eu'
                    def elasticsearchCredentialsId = '845ba95a-2c30-4e5f-82b7-f36265434815'
                    def mysqlAddress // Defined based on the cluster CVS is deployed to
                    def mysqlCredentialsId = '733c02c4-428f-4c84-b0e1-b05b44ab21e4'

                    if (cluster == 'production-cluster') {
                        elasticsearchCredentialsId = '331f25ae-554f-4a4a-b879-b944f4035dd5'
                        mysqlAddress = '10.119.209.26'
                        mysqlCredentialsId = '0178c267-e257-49e9-9b0c-fdd6033b5137'
                        // Enable high availability mode in Elasticsearch and the frontend
                        productionSettings = ' --set es.elasticsearch.minimumMasterNodes=2 --set es.replicaCount=3 --set frontend.replicaCount=1 --set frontend.mail.baseURL=https://vocabularies.cessda.eu'
                        product_name = 'cvs'
                    } else if (cluster == 'staging-cluster') {
                        mysqlAddress = '172.19.209.45'
                        mysqlCredentialsId = '9910a0d9-b7be-4031-8d3f-a2259b46070f'
                        productionSettings = ' --set frontend.mail.baseURL=https://vocabularies-staging.cessda.eu'
                    } else {
                        mysqlAddress = '172.19.209.43'
                        mysqlCredentialsId = '5788c551-7669-421a-be05-ef6428292fd8'
                    }

                    withEnv(["MYSQL_ADDRESS=${mysqlAddress}", "product_name=${product_name}"]) {
                        withCredentials([
                            usernamePassword(credentialsId: mysqlCredentialsId, passwordVariable: 'MYSQL_PASSWORD', usernameVariable: 'MYSQL_USERNAME'),
                            file(credentialsId: elasticsearchCredentialsId, variable: 'ELASTICSEARCH_BACKUP_CREDENTIALS')
                        ]) {
                            sh 'set -u; mkdir -p ${ELASTICSEARCH_SECRETS}; cp ${ELASTICSEARCH_BACKUP_CREDENTIALS} ${ELASTICSEARCH_SECRETS}'
                            sh 'set -u; ${helmHome}/helm upgrade ${product_name} cvs -n ${product_name} -i --atomic' + imageSettings + mysqlSettings + productionSettings
                            
                        }
                    }
                }
            }
            post {
                always {
                    // Clear secrets directory
                    sh 'rm -rf ${ELASTICSEARCH_SECRETS}'
                }
            }
            when { 
                allOf {
                    branch 'main'
                    environment name: 'deployApp', value: 'true'
                }
            }
        }
        stage('Deploy Documentation'){
            steps{
                script {
                    withEnv(["product_name=${product_name}"]) {
                        sh 'set -u; ${helmHome}/helm upgrade ${product_name}-doc cvs-doc -n ${product_name} -i --atomic' + 
                            ' --set contentguide.image.tag=${contentguide_image_tag} --set userguide.image.tag=${userguide_image_tag}'
                    }
                }
            }
            when { branch 'main' }
        }
        stage('Run Tests') {
            steps {
                build job: 'cessda.cvs.test/main', wait: false
            }
            when { 
                allOf { 
                    branch 'main'
                    environment name: 'cluster', value: 'development-cluster' 
                } 
            }
        }
    }
}
