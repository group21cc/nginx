pipeline {
    agent {
        kubernetes {
            label 'docker-agent'
            defaultContainer 'docker'
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:24.0-dind
    command:
    - cat
    tty: true
    securityContext:
      privileged: true
    volumeMounts:
    - name: docker-graph-storage
      mountPath: /var/lib/docker
  volumes:
  - name: docker-graph-storage
    emptyDir: {}
"""
        }
    }
    environment {
        NEXUS_URL = 'nexus-service.nexus.svc.cluster.local:8081'
        IMAGE_NAME = 'test/nginx'
        IMAGE_TAG = 'v1.8'
    }
    stages {
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
                }
            }
        }
        stage('Push Docker Image to Nexus') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh "docker login -u \$USER -p \$PASS ${NEXUS_URL}"
                        sh "docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${NEXUS_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
                        sh "docker push ${NEXUS_URL}/${IMAGE_NAME}:${IMAGE_TAG}"
                    }
                }
            }
        }
    }
    post {
        always {
            container('docker') {
                sh 'docker logout ${NEXUS_URL}'
            }
        }
    }
}
