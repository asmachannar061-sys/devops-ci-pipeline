pipeline {
    agent any

    options {
        skipDefaultCheckout(true)
        timestamps()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh 'docker build --target test --tag devops-ci-pipeline:test .'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        sh "\"${scannerHome}/bin/sonar-scanner\""
                    }
                }
            }
        }

        stage('Build Docker image') {
            steps {
                sh 'docker build --tag devops-ci-pipeline:${BUILD_NUMBER} --tag devops-ci-pipeline:latest .'
            }
        }
    }
}
