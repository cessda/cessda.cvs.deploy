pipeline {

    options {
        buildDiscarder logRotator(numToKeepStr: '20')
        disableConcurrentBuilds()
    }

    parameters {
        string(name: 'frontend_image_tag', defaultValue: "master-latest", description: 'The version of the application to deploy, default is latest if unspecified')
        choice choices: ['development-cluster', 'staging-cluster'], description: 'Choose which cluster to deploy to', name: 'cluster'
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
                elasticsearchSecrets = "./charts/es/secret/" 
            }
            steps {
                script {
                    def mysqlAddress
                    if (cluster == 'staging-cluster') {
                        mysqlAddress = "172.19.209.17"
                    } else {
                        mysqlAddress = "172.19.209.15"
                    }
                    withCredentials([usernamePassword(credentialsId: '733c02c4-428f-4c84-b0e1-b05b44ab21e4', passwordVariable: 'mysqlPassword', usernameVariable: 'mysqlUsername'), 
                    usernamePassword(credentialsId: '2e89ebbf-9b6a-423a-8cf4-5b20e396b2c2', passwordVariable: 'flatdbPassword', usernameVariable: 'flatdbUsername'),
                    file(credentialsId: '845ba95a-2c30-4e5f-82b7-f36265434815', variable: 'elasticsearchBackupCredentials')]) {
                        sh "mkdir -p ${elasticsearchSecrets} && cp ${elasticsearchBackupCredentials} ${elasticsearchSecrets}"
                        sh("${helmHome}/helm upgrade ${product_name} . -n ${product_name} -i --atomic" +
                        // By default, the chart uses the standard Elasticsearch image
                        " --set es.image.repository=eu.gcr.io/cessda-prod/cvs-es"
                        " --set es.image.tag=${es_image_tag} --set frontend.image.tag=${frontend_image_tag}" +
                        " --set mysql.location.address=${mysqlAddress} --set mysql.username=${mysqlUsername} --set mysql.password=${mysqlPassword}")
                    }
                }
            }
            post {
                always {
                    // Clear secrets directory
                    sh "rm -rf ${elasticsearchSecrets}"
                }
            }
        }
        stage('Run Tests') {
            steps {
                build job: 'cessda.cvs.test', wait: false
            }
        when { branch 'master' }
        }
    }
}
