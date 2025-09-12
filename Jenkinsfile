pipeline {
    agent any

    environment {
        // GitHub repo
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"

        // Docker & Nexus settings
        NEXUS_URL = "http://localhost:8888/repository/test/"
        DOCKER_IMAGE = "${NEXUS_URL}/repository/docker-hosted/nginx"
        DOCKER_TAG = "v1.${env.BUILD_NUMBER}"  // dynamic tag per build
        DOCKER_CREDENTIALS = "nexus-docker-credentials"

        // Kubernetes credentials (stored in Jenkins)
        KUBECONFIG_CREDENTIALS = "kubeconfig"
        K8S_DEPLOYMENT = "nginx-deployment"
        K8S_CONTAINER = "nginx"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        echo $PASS | docker login ${NEXUS_URL} -u $USER --password-stdin
                        docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl set image deployment/${K8S_DEPLOYMENT} ${K8S_CONTAINER}=${DOCKER_IMAGE}:${DOCKER_TAG} --record
                        kubectl rollout status deployment/${K8S_DEPLOYMENT}
                    """
                }
            }
        }
    }
}
