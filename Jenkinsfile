pipeline {
    agent {
        kubernetes {
            label 'jenkins-kaniko'
            defaultContainer 'jnlp'
            yaml """
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-sa   # Use ServiceAccount with deploy permissions
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:debug
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  - name: kubectl
    image: bitnami/kubectl:latest
    command:
    - cat
    tty: true
  volumes:
  - name: docker-config
    projected:
      sources:
      - secret:
          name: regcred
          items:
          - key: .dockerconfigjson
            path: config.json
"""
        }
    }

    environment {
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"
        IMAGE_NAME = "nexus-service.jenkins.svc.cluster.local:8081/test/nginx"
        IMAGE_TAG  = "27"
        KUBE_NAMESPACE = "jenkins"  // Namespace for deployment
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }

        stage('Build & Push Image') {
            steps {
                container('kaniko') {
                    sh """
                    /kaniko/executor \
                        --context . \
                        --dockerfile ./Dockerfile \
                        --destination=${IMAGE_NAME}:${IMAGE_TAG} \
                        --insecure \
                        --skip-tls-verify
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                container('kubectl') {
                    sh """
                    # Apply deployment and service in one namespace
                    kubectl apply -n ${KUBE_NAMESPACE} -f nginx-deployment.yaml
                    kubectl apply -n ${KUBE_NAMESPACE} -f nginx-service.yaml
                    """
                }
            }
        }
    }
}
