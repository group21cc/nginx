pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins   # Use the correct service account
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - cat
    tty: true
    volumeMounts:
      - name: workspace-volume
        mountPath: /workspace
  - name: jnlp
    image: jenkins/inbound-agent:latest
    volumeMounts:
      - name: workspace-volume
        mountPath: /home/jenkins/agent
  volumes:
    - name: workspace-volume
      emptyDir: {}
"""
        }
    }

    environment {
        // GitHub repo
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"

        // Nexus internal DNS and port (use namespace)
        NEXUS_REGISTRY = "nexus-service.jenkins.svc.cluster.local:8081"

        // Docker repository and tag
        DOCKER_REPO = "test/nginx"
        DOCKER_TAG = "v1.${env.BUILD_NUMBER}"

        // Jenkins credentials ID for Nexus
        DOCKER_CREDENTIALS = "nexus-docker-credentials"

        // Kubernetes deployment info
        K8S_DEPLOYMENT = "nginx-deployment"
        K8S_CONTAINER = "nginx"
        K8S_NAMESPACE = "jenkins"  // adjust if needed
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
                    withCredentials([
                        usernamePassword(
                            credentialsId: "${DOCKER_CREDENTIALS}", 
                            usernameVariable: 'USER', 
                            passwordVariable: 'PASS'
                        )
                    ]) {
                        sh """
                        mkdir -p /workspace/.docker
                        echo '{ "auths": { "${NEXUS_REGISTRY}": { "username": "$USER", "password": "$PASS" } } }' > /workspace/.docker/config.json

                        /kaniko/executor \
                          --context /workspace \
                          --dockerfile /workspace/Dockerfile \
                          --destination ${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} \
                          --insecure --skip-tls-verify \
                          --verbosity debug \
                          --cache=true
                        """
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kaniko') { // reuse same pod; kaniko container has access
                    sh """
                    # Use in-cluster service account, no kubeconfig file needed
                    kubectl --namespace=${K8S_NAMESPACE} set image deployment/${K8S_DEPLOYMENT} ${K8S_CONTAINER}=${NEXUS_REGISTRY}/${DOCKER_REPO}:${DOCKER_TAG} --record
                    kubectl --namespace=${K8S_NAMESPACE} rollout status deployment/${K8S_DEPLOYMENT}
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
