pipeline {
    agent any

    environment {
        // GitHub repo
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"

        // Nexus internal DNS and port (use namespace)
        NEXUS_REGISTRY = "nexus-service.jenkins.svc.cluster.local:8081"

        // Docker repository and tag
        DOCKER_REPO = "test/nginx"
        DOCKER_TAG = "v1.${env.BUILD_NUMBER}"

        // Jenkins credentials IDs
        DOCKER_CREDENTIALS = "nexus-docker-credentials"
        KUBECONFIG_CREDENTIALS = "kubeconfig"

        // Kubernetes deployment info
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
                withCredentials([
                    usernamePassword(
                        credentialsId: "${DOCKER_CREDENTIALS}",
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                    )
                ]) {
                    sh """
                    echo "$PASS" | docker login ${NEXUS_REGISTRY} --username $USER --password-stdin
                    docker build -t ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} .
                    docker push ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')
                ]) {
                    sh """
                    export KUBECONFIG=$KUBECONFIG_FILE
                    kubectl set image deployment/${K8S_DEPLOYMENT} ${K8S_CONTAINER}=${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} --record
                    kubectl rollout status deployment/${K8S_DEPLOYMENT}
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully! Docker image pushed and deployed."
        }
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}
