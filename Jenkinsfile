pipeline {

    options {
        ansiColor('xterm')
        buildDiscarder logRotator(numToKeepStr: '20')
    }

    parameters {
        string(name: 'gui_image_tag', defaultValue: "${docker_repo}/cvs-gui:master-latest", description: 'The version of the application to deploy, default is latest if unspecified')
        choice choices: ['all', 'elasticsearch', 'flatdb', 'gui', 'mailrelay', 'mysql'], description: 'Choose which module to build', name: 'module'
    }

    environment {
        project_name = "cessda-dev"
        product_name = "cvs"
        es_module_name = "es"
        es_image_tag = "${docker_repo}/${product_name}-${es_module_name}:${env.BRANCH_NAME}-${env.BUILD_NUMBER}"
        flatdb_module_name = "flatdb"
		gui_module_name = "gui"
        mailrelay_module_name = "mailrelay"
        mailrelay_image_tag = "${docker_repo}/mailrelay:latest"
        mysql_module_name = "mysql"
        cluster = "development-cluster"
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
                image_tag = "${es_image_tag}"
                module_name = "${es_module_name}"
            }
            steps {
                dir('./elasticsearch/docker/') {
                    sh("gcloud auth configure-docker")
                    sh("docker build -t ${image_tag} .")
                    sh("docker push ${image_tag}")
                }
                dir('./elasticsearch/infrastructure/gcp/') {
                    sh("./es-creation.sh")
                }
            }
            when {
                anyOf {
                    environment name: 'module', value: 'elasticsearch'
                    environment name: 'module', value: 'all'
                }
            }
        }
        stage('Update CVS Flatdb') {
            environment {
                module_name = "${flatdb_module_name}"
            }
            steps {
                dir('./flatdb/infrastructure/gcp/') {
                    sh("./flatdb-creation.sh")
                }
            }
            when {
                anyOf {
                    environment name: 'module', value: 'flatdb'
                    environment name: 'module', value: 'all'
                }
            }
        }
        stage('Update CVS GUI') {
            environment {
                module_name = "${gui_module_name}"
                image_tag = "${gui_image_tag}"
            }
            steps {
                dir('./gui/infrastructure/gcp/') {
                    sh("./gui-creation.sh")
                }
            }
            when {
                anyOf {
                    environment name: 'module', value: 'gui'
                    environment name: 'module', value: 'all'
                }
            }
        }
        stage('Update CVS Mailrelay') {
            environment {
                module_name = "${mailrelay_module_name}"
                image_tag = "${mailrelay_image_tag}"
            }
            steps {
                dir('./mailrelay/infrastructure/gcp/') {
                    sh("./mailrelay-creation.sh")
                }
            }
            when {
                anyOf {
                    environment name: 'module', value: 'mailrelay'
                    environment name: 'module', value: 'all'
                }
            }
        }
        stage('Update CVS MySQL') {
            environment {
                module_name = "${mysql_module_name}"
            }
            steps {
                dir('./mysql/infrastructure/gcp/')
                {
                    sh("./mysql-creation.sh")
                }
            }
            when {
                anyOf {
                    environment name: 'module', value: 'mysql'
                    environment name: 'module', value: 'all'
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
