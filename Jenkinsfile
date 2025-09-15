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
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
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
        GITHUB_REPO     = "https://github.com/group21cc/nginx.git"
        IMAGE_NAME      = "nginx"
        NEXUS_REGISTRY  = "nexus-service.jenkins.svc.cluster.local:8081"
        NEXUS_REPO_PATH = "repository/test"   // important: must include /repository/
        IMAGE_TAG       = "${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                container('kaniko') {
                    git "${GITHUB_REPO}"
                }
            }
        }

        stage('Build & Push Image') {
            steps {
                container('kaniko') {
                    sh """
                      /kaniko/executor \
                        --context `pwd` \
                        --dockerfile `pwd`/Dockerfile \
                        --destination=${NEXUS_REGISTRY}/${NEXUS_REPO_PATH}/${IMAGE_NAME}:${IMAGE_TAG} \
                        --insecure \
                        --skip-tls-verify
                    """
                }
            }
        }
    }
}
