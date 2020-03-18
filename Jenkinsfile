pipeline {

    options {
        ansiColor('xterm')
        buildDiscarder logRotator(numToKeepStr: '20')
    }

    parameters {
        string(name: 'gui_image_tag', defaultValue: "master-latest", description: 'The version of the application to deploy, default is latest if unspecified')
    }

    environment {
        project_name = "cessda-dev"
        product_name = "cvs"
        cluster = "development-cluster"
        es_image_tag = "${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        kubeScoreHome = tool 'kube-score'
        helmHome = tool 'helm'
    }
    agent any

    stages {
        stage('Set up gcloud') {
            steps {
                sh("gcloud config set project ${project_name}")
                sh("gcloud container clusters get-credentials ${cluster} --zone=${zone}")
            }
        }
        stage('Update CVS Elasticsearch') {
            environment {
                image_tag = "${docker_repo}/${product_name}-es:${es_image_tag}"
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
                sh "${helmHome}/helm dependency update cvs"
                sh "${helmHome}/helm template ${product_name} cvs | ${kubeScoreHome}/kube-score score - || true"
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
            steps {
                withCredentials([usernamePassword(credentialsId: '733c02c4-428f-4c84-b0e1-b05b44ab21e4', passwordVariable: 'mysqlPassword', usernameVariable: 'mysqlUsername'), 
                usernamePassword(credentialsId: '2e89ebbf-9b6a-423a-8cf4-5b20e396b2c2', passwordVariable: 'flatdbPassword', usernameVariable: 'flatdbUsername'),
                file(credentialsId: '845ba95a-2c30-4e5f-82b7-f36265434815', variable: 'elasticsearchBackupCredentials')]) {
                    sh "cp ${elasticsearchBackupCredentials} ./cvs/charts/es/secret/"
                    sh("${helmHome}/helm upgrade ${product_name} cvs -n ${product_name} -i --atomic" +
                    " --set es.image.tag=${es_image_tag} --set gui.image.tag=${gui_image_tag}" +
                    " --set mysql.username=${mysqlUsername} --set mysql.password=${mysqlPassword}" +
                    " --set mysql.flatdb.username=${flatdbUsername} --set mysql.flatdb.password=${flatdbPassword}")
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
