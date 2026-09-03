pipeline {
    agent {
        kubernetes {
            label 'eks-rds-showcase'
            defaultContainer 'dagger'
            yaml '''
apiVersion: v1
kind: Pod
spec:
  serviceAccountName: jenkins-agent
  containers:
    - name: dagger
      image: python:3.12-slim
      imagePullPolicy: Always
      command:
        - sleep
        - infinity
      tty: true
      env:
        - name: HOME
          value: /home/jenkins
        - name: KUBECONFIG
          value: /home/jenkins/.kube/config
      volumeMounts:
        - name: workspace
          mountPath: /home/jenkins/agent
    - name: kubectl
      image: bitnami/kubectl:latest
      imagePullPolicy: Always
      command:
        - sleep
        - infinity
      tty: true
      env:
        - name: HOME
          value: /home/jenkins
        - name: KUBECONFIG
          value: /home/jenkins/.kube/config
      volumeMounts:
        - name: workspace
          mountPath: /home/jenkins/agent
  volumes:
    - name: workspace
      emptyDir: {}
'''
        }
    }

    parameters {
        choice(
            name: 'TARGET_CLUSTER',
            choices: ['diskless-k8s', 'k3s-dev'],
            description: 'Target Kubernetes cluster'
        )
        booleanParam(
            name: 'FLOCI_ENABLED',
            defaultValue: true,
            description: 'Enable Floci (LocalStack) for CI'
        )
        booleanParam(
            name: 'EPHEMERAL_CLEANUP',
            defaultValue: false,
            description: 'Delete resources after testing'
        )
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '10'))
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Setup Kubeconfig') {
            steps {
                container('dagger') {
                    withCredentials([file(credentialsId: 'jenkins-kubeconfig-diskless-k8s', variable: 'KUBECONFIG_SECRET')]) {
                        sh '''
                            mkdir -p /home/jenkins/.kube
                            cp ${KUBECONFIG_SECRET} /home/jenkins/.kube/config
                            chmod 600 /home/jenkins/.kube/config
                        '''
                    }
                }
            }
        }

        stage('Start Floci') {
            when {
                equals expected: true, actual: params.FLOCI_ENABLED
            }
            steps {
                container('kubectl') {
                    sh '''
                        kubectl delete pod floci --namespace=default --ignore-not-found=true || true
                        kubectl run floci \
                            --image=floci/floci:latest \
                            --namespace=default \
                            --env="SERVICES=ec2,iam,eks,rds,logs,cloudwatch,sts,kms" \
                            --env="DEBUG=1" \
                            --port=4566 \
                            --labels="app=floci" \
                            --restart=Never \
                            --detach
                    '''
                    sh 'sleep 15'
                    sh 'kubectl get pods -l app=floci'
                }
            }
        }

        stage('Install Dependencies') {
            steps {
                container('dagger') {
                    sh '''
                        pip install --upgrade pip && \
                        pip install dagger-io ansible kubernetes
                    '''
                    sh 'go mod download'
                }
            }
        }

        stage('Run Dagger CI') {
            steps {
                container('dagger') {
                    sh 'go run ./ci/main.go'
                }
            }
        }

        stage('Cleanup') {
            when {
                equals expected: true, actual: params.EPHEMERAL_CLEANUP
            }
            steps {
                container('dagger') {
                    sh 'terraform destroy -auto-approve -var-file=environments/ci.tfvars || true'
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: '*.log', allowEmptyArchive: true
            deleteDir()
        }
        success {
            echo 'EKS+RDS CI pipeline succeeded!'
        }
        failure {
            echo 'EKS+RDS CI pipeline failed!'
        }
    }
}
