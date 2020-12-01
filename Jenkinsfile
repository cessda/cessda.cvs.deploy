pipeline {

    options {
        buildDiscarder logRotator(numToKeepStr: '20')
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'frontend_image_tag', defaultValue: "master-latest", description: 'The version of the application to deploy, default is latest if unspecified')
        choice choices: ['development-cluster', 'staging-cluster', 'production-cluster'], description: 'Choose which cluster to deploy to', name: 'cluster'
    }

    environment {
        product_name = "cvs-v2"
        es_image_tag = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        kubeScoreHome = tool 'kube-score'
        helmHome = tool 'helm'
    }
    agent any

    stages {
        stage('Set up gcloud') {
            steps {
                script {
                    if (cluster == 'production-cluster') {
                        sh("gcloud config set project cessda-prod")
                    } else {
                        sh("gcloud config set project cessda-dev")
                    }
                    sh("gcloud container clusters get-credentials ${cluster} --zone=${zone}")
                }
            }
        }
        stage('Update CVS Elasticsearch') {
            environment {
                image_tag = "${docker_repo}/cvs-es:${es_image_tag}"
                module_name = "${es_module_name}"
            }
            steps {
                dir('./elasticsearch/docker/') {
                    sh("gcloud auth configure-docker")
                    sh("docker build -t ${image_tag} .")
                    sh("docker push ${image_tag}")
                }
            }
        }
        stage('Run kube-score') {
            steps {
                sh "${helmHome}/helm plugin install https://github.com/hayorov/helm-gcs || true"
                sh "${helmHome}/helm dependency update ."
                sh "${helmHome}/helm template ${product_name} . | ${kubeScoreHome}/kube-score score - || true"
            }
        }
        stage('Create Namespace') {
            steps {
                sh script: '''
                    if kubectl get ns $product_name
                        then
                            echo "Namespace already exists"
                        else
                            kubectl create namespace $product_name
                    fi;
                '''
            }
        }
        stage('Deploy CVS') {
            environment {
                ELASTICSEARCH_SECRETS = 'charts/es/secret/'
            }
            steps {
                script {

                    // By default, the chart uses the standard Elasticsearch image
                    def imageSettings = ' --set es.image.repository=eu.gcr.io/cessda-prod/cvs-es --set es.image.tag=${es_image_tag} --set frontend.image.tag=${frontend_image_tag}'
                    def mysqlSettings = ' --set mysql.location.address=${MYSQL_ADDRESS} --set mysql.username=${MYSQL_USERNAME} --set mysql.password=${MYSQL_PASSWORD}'
                    def mysqlAddress

                    if (cluster == 'production-cluster') {

                        mysqlAddress = "10.119.209.11"

                        // For production, set high availability mode for Elasticsearch and the frontend
                        withEnv(["MYSQL_ADDRESS=${mysqlAddress}"]) {
                            withCredentials([usernamePassword(credentialsId: '0178c267-e257-49e9-9b0c-fdd6033b5137', passwordVariable: 'MYSQL_PASSWORD', usernameVariable: 'MYSQL_USERNAME'),
                            file(credentialsId: '331f25ae-554f-4a4a-b879-b944f4035dd5', variable: 'ELASTICSEARCH_BACKUP_CREDENTIALS')]) {
                                sh 'mkdir -p ${ELASTICSEARCH_SECRETS} && cp ${ELASTICSEARCH_BACKUP_CREDENTIALS} ${ELASTICSEARCH_SECRETS}'
                                sh('${helmHome}/helm upgrade ${product_name} . -n ${product_name} -i --atomic' + imageSettings + mysqlSettings
                                    ' --set es.elasticsearch.minimumMasterNodes=2 --set es.replicaCount=3 --set frontend.replicaCount=2')
                            }
                        }
                    } else {

                        if (cluster == 'staging-cluster') {
                            mysqlAddress = '172.19.209.17'
                        } else {
                            mysqlAddress = '172.19.209.15'
                        }

                        withEnv(["MYSQL_ADDRESS=${mysqlAddress}"]) {
                            withCredentials([usernamePassword(credentialsId: '733c02c4-428f-4c84-b0e1-b05b44ab21e4', passwordVariable: 'MYSQL_PASSWORD', usernameVariable: 'MYSQL_USERNAME'),
                            file(credentialsId: '845ba95a-2c30-4e5f-82b7-f36265434815', variable: 'ELASTICSEARCH_BACKUP_CREDENTIALS')]) {
                                sh 'mkdir -p ${ELASTICSEARCH_SECRETS} && cp ${ELASTICSEARCH_BACKUP_CREDENTIALS} ${ELASTICSEARCH_SECRETS}'
                                sh '${helmHome}/helm upgrade ${product_name} . -n ${product_name} -i --atomic' + imageSettings + mysqlSettings
                            }
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
            when { branch 'master' }
        }
        stage('Run Tests') {
            steps {
                build job: 'cessda.cvs.test/master', wait: false
            }
            when { 
                allOf { 
                    branch 'master'
                    environment name: 'cluster', value: 'development-cluster' 
                } 
            }
        }
    }
}
