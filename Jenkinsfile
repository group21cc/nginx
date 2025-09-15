pipeline {
    agent any  // Use the Jenkins agent that has Docker

    environment {
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"
        NEXUS_REGISTRY = "nexus-service.jenkins.svc.cluster.local:8081"
        DOCKER_REPO = "test/nginx"
        DOCKER_TAG = "v1.${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS = "nexus-docker-credentials"  // Jenkins credentials
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
                sh """
                    docker build -t ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} ./nginx
                """
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: "${DOCKER_CREDENTIALS}", 
                    usernameVariable: 'USER', 
                    passwordVariable: 'PASS'
                )]) {
                    sh """
                        echo "$PASS" | docker login ${NEXUS_REGISTRY} -u "$USER" --password-stdin
                        docker push ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    kubectl set image deployment/${K8S_DEPLOYMENT} ${K8S_CONTAINER}=${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} --record
                    kubectl rollout status deployment/${K8S_DEPLOYMENT}
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! Docker image pushed and deployed."
        }
        failure {
            echo "Pipeline failed. Check logs."
        }
    }
}
