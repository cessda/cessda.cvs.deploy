pipeline {

    parameters
    {
        string(name: 'gui_image_tag', defaultValue: "${docker_repo}/cvs-gui:master-latest", description: 'The version of the application to deploy, default is latest if unspecified')
        choice choices: ['all', 'elasticsearch', 'gui'], description: 'Choose which module to build', name: 'module'
    }

    environment
    {
        project_name = "cessda-dev"
        product_name = "eqb"
		gui_module_name = "gui"
        es_module_name = "es"
        cluster = "development-cluster"
    }

    agent any

    stages
    {
        stage('Set up gcloud'){
            steps{
                sh("gcloud config set project ${project_name}")
                sh("gcloud config set compute/region ${region}")
                sh("gcloud config set compute/zone ${zone}")
                sh("gcloud container clusters get-credentials ${cluster} --zone=${zone}")
            }
        }
        stage('Update CVS Elasticsearch')
        {
            environment
            {
                module_name = "${es_module_name}"
            }
            steps
            {
                dir('./elasticsearch/infrastructure/gcp/')
                {
                    sh("bash es-creation.sh")
                }
            }
            when {
                anyOf {
                    environment name: 'module', value: 'elasticsearch'
                    environment name: 'module', value: 'all'
                }
            }
        }
        stage('Update CVS GUI')
        {
            environment
            {
                module_name = "${gui_module_name}"
                image_tag = "${gui_image_tag}"
            }
            steps
            {
                dir('./gui/infrastructure/gcp/')
                {
                    sh("bash gui-creation.sh")
                }
            }
            when {
                anyOf {
                    environment name: 'module', value: 'gui'
                    environment name: 'module', value: 'all'
                }
            }
        }
    }
}
