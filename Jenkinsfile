pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24.0-dind
    securityContext:
      privileged: true
    command:
    - cat
    tty: true
"""
        }
    }

    environment {
        // GitHub repo
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"

        // Nexus internal DNS and port
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

        stage('Build & Push Docker Image') {
            steps {
                container('docker') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: "${DOCKER_CREDENTIALS}", 
                            usernameVariable: 'USER', 
                            passwordVariable: 'PASS'
                        )
                    ]) {
                        sh """
                        echo "Logging in to Nexus Docker Registry..."
                        docker login -u $USER -p $PASS $NEXUS_REGISTRY

                        echo "Building Docker image..."
                        docker build -t ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} .

                        echo "Pushing Docker image..."
                        docker push ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG}

                        docker logout $NEXUS_REGISTRY
                        """
                    }
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
