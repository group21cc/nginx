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
    - name: kaniko-secret
      mountPath: /kaniko/.docker
      readOnly: true
  volumes:
  - name: kaniko-secret
    secret:
      secretName: regcred   # secret for Nexus Docker registry creds
"""
        }
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/group21cc/nginx.git', branch: 'main'
            }
        }

        stage('Build & Push with Kaniko') {
    steps {
        container('kaniko') {
            sh '''
            /kaniko/executor \
              --context . \
              --dockerfile ./Dockerfile \
              --destination=nexus-service.jenkins.svc.cluster.local:8081/repository/test/nginx:${DOCKER_TAG} \
              --insecure \
              --skip-tls-verify
            '''
        }
    }
}


        stage('Deploy to Kubernetes') {
            steps {
                sh 'kubectl apply -f k8s-deployment.yaml -n jenkins'
            }
        }
    }
}
