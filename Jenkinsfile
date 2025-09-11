pipeline {
    agent any

    environment {
        // GitHub Repo
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"

        // Docker settings
        DOCKER_IMAGE = "nexus.yourdomain.com/repository/docker-hosted/nginx"
        DOCKER_TAG = "v1.0"
        DOCKER_CREDENTIALS = "nexus-docker-credentials"

        // K8s kubeconfig credentials (stored in Jenkins)
        KUBECONFIG_CREDENTIALS = "kubeconfig"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                }
            }
        }

        stage('Push to Nexus') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "echo $PASS | docker login nexus.yourdomain.com -u $USER --password-stdin"
                        sh "docker push ${DOCKER_IMAGE}:${DOCKER_TAG}"
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
                        sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl apply -f nginx-deployment.yaml
                        kubectl apply -f nginx-service.yaml
                        """
                    }
                }
            }
        }
    }
}
