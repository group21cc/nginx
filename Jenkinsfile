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
      - mountPath: /kaniko/.docker
        name: docker-config
      - mountPath: /home/jenkins/agent
        name: workspace-volume
  - name: jnlp
    image: jenkins/inbound-agent:latest
    env:
      - name: JENKINS_AGENT_WORKDIR
        value: /home/jenkins/agent
    volumeMounts:
      - mountPath: /home/jenkins/agent
        name: workspace-volume
  volumes:
    - name: docker-config
      projected:
        sources:
          - secret:
              name: regcred
              items:
                - key: .dockerconfigjson
                  path: config.json
    - emptyDir:
        medium: ""
      name: workspace-volume
"""
        }
    }

    environment {
        GITHUB_REPO = "https://github.com/group21cc/nginx.git"
        IMAGE_TAG = "27"
        IMAGE_NAME = "nexus-service.jenkins.svc.cluster.local:8081/test/nginx"
    }

    stages {
        stage('Checkout') {
            steps {
                container('kaniko') {
                    git branch: 'main', url: "${GITHUB_REPO}"
                }
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
                sh """
                kubectl apply -f nginx-deployment.yaml
                kubectl apply -f nginx-service.yaml
                """
            }
        }
    }
}
