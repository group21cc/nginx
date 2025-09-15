pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - cat
    tty: true
"""
        }
    }

    environment {
    GITHUB_REPO = "https://github.com/group21cc/nginx.git"
    NEXUS_REGISTRY = "nexus-service.nexus.svc.cluster.local:8888"   // <--- FIXED
    DOCKER_REPO = "test/nginx"
    DOCKER_TAG = "v1.${env.BUILD_NUMBER}"
    DOCKER_CREDENTIALS = "nexus-docker-credentials"
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
            steps {
                container('kaniko') {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS}", usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh """
                          mkdir -p /kaniko/.docker
                          echo "{\\"auths\\":{\\"${NEXUS_REGISTRY}\\":{\\"username\\":\\"$USER\\",\\"password\\":\\"$PASS\\"}}}" > /kaniko/.docker/config.json

                          /kaniko/executor \
                            --context `pwd` \
                            --dockerfile `pwd`/Dockerfile \
                            --destination ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} \
                            --insecure --skip-tls-verify
                        """
                    }
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
