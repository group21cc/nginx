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
    volumeMounts:
      - mountPath: /var/lib/docker
        name: docker-graph-storage
    command:
      - cat
    tty: true
  - name: jnlp
    image: jenkins/inbound-agent:latest
    args: ['\$(JENKINS_SECRET)', '\$(JENKINS_NAME)']
  volumes:
    - name: docker-graph-storage
      emptyDir: {}
"""
        }
    }

    environment {
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"
        NEXUS_REGISTRY = "nexus-service.jenkins.svc.cluster.local:8081"
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
                        sh '''
                        echo "$PASS" | docker login ${NEXUS_REGISTRY} --username "$USER" --password-stdin
                        docker build -t ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} .
                        docker push ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG}
                        '''
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(credentialsId: "${KUBECONFIG_CREDENTIALS}", variable: 'KUBECONFIG_FILE')
                ]) {
                    sh '''
                    export KUBECONFIG=$KUBECONFIG_FILE
                    kubectl set image deployment/${K8S_DEPLOYMENT} ${K8S_CONTAINER}=${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} --record
                    kubectl rollout status deployment/${K8S_DEPLOYMENT}
                    '''
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
