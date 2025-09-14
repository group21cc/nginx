pipeline {
    agent any

    environment {
        // GitHub repo
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"

        // Docker & Nexus settings
        NEXUS_REGISTRY = "localhost:8888"                 // registry host:port
        DOCKER_REPO = "docker-hosted/nginx"               // repo in Nexus
        DOCKER_TAG = "v1.${env.BUILD_NUMBER}"             // dynamic tag per build
        DOCKER_CREDENTIALS = "nexus-docker-credentials"

        // Kubernetes credentials
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

        stage('Build & Push with Kaniko') {
            agent {
                docker {
                    image 'gcr.io/kaniko-project/executor:latest'
                    args '-v /kaniko/.docker:/kaniko/.docker -v $WORKSPACE:/workspace'
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        mkdir -p /kaniko/.docker
                        echo "{\\"auths\\":{\\"${NEXUS_REGISTRY}\\":{\\"username\\":\\"$USER\\",\\"password\\":\\"$PASS\\"}}}" > /kaniko/.docker/config.json

                        /kaniko/executor \
                          --context /workspace \
                          --dockerfile /workspace/Dockerfile \
                          --destination ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} \
                          --insecure --skip-tls-verify
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl set image deployment/${K8S_DEPLOYMENT} ${K8S_CONTAINER}=${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} --record
                        kubectl rollout status deployment/${K8S_DEPLOYMENT}
                    """
                }
            }
        }
    }
}
