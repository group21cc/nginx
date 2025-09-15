pipeline {
    agent {
        kubernetes {
            label 'docker-agent'
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

    stages {
        stage('Build Docker Image') {
            steps {
                container('docker') {
                    sh 'docker build -t test/nginx:v1.8 .'
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                        sh 'docker login -u $USER -p $PASS nexus-service.nexus.svc.cluster.local:8081'
                        sh 'docker tag test/nginx:v1.8 nexus-service.nexus.svc.cluster.local:8081/test/nginx:v1.8'
                        sh 'docker push nexus-service.nexus.svc.cluster.local:8081/test/nginx:v1.8'
                    }
                }
            }
        }
    }
}
