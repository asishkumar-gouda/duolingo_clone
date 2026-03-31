pipeline {
    agent any

    parameters {
        string(name: 'TAG', defaultValue: '', description: 'Git tag to deploy (e.g., v1.0.0)')
    }

    environment {
        REGISTRY     = 'localhost:5001'
        IMAGE_NAME   = 'duolingo-clone'
        DOCKER_TAG   = "${params.TAG.replaceFirst('^v', '')}"
        FULL_IMAGE   = "${REGISTRY}/${IMAGE_NAME}:${DOCKER_TAG}"
    }

    stages {
        stage('Validate') {
            steps {
                script {
                    if (!params.TAG?.trim()) {
                        error('TAG parameter is required (e.g., v1.0.0)')
                    }
                    echo "Deploying version: ${params.TAG} (image tag: ${env.DOCKER_TAG})"
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Image') {
            steps {
                script {
                    // Source NEXT_PUBLIC_ vars from .env if it exists
                    def clerkKey = ''
                    def appUrl = 'http://localhost'
                    if (fileExists('.env')) {
                        def envContent = readFile('.env')
                        def clerkMatch = envContent =~ /NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=(.*)/
                        def urlMatch = envContent =~ /NEXT_PUBLIC_APP_URL=(.*)/
                        if (clerkMatch) { clerkKey = clerkMatch[0][1].trim() }
                        if (urlMatch) { appUrl = urlMatch[0][1].trim() }
                    }

                    sh """
                        docker build \
                            -t ${env.FULL_IMAGE} \
                            -t ${env.REGISTRY}/${env.IMAGE_NAME}:latest \
                            --build-arg NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=${clerkKey} \
                            --build-arg NEXT_PUBLIC_APP_URL=${appUrl} \
                            .
                    """
                }
            }
        }

        stage('Push Image') {
            steps {
                sh "docker push ${env.FULL_IMAGE}"
                sh "docker push ${env.REGISTRY}/${env.IMAGE_NAME}:latest"
            }
        }

        stage('Update Helm Values') {
            steps {
                sh """
                    sed -i 's|^  tag:.*|  tag: "${env.DOCKER_TAG}"|' deploy/values.yaml
                    sed -i 's|^appVersion:.*|appVersion: "${env.DOCKER_TAG}"|' deploy/Chart.yaml
                """
            }
        }

        stage('Commit & Push') {
            steps {
                sh """
                    git config user.email "jenkins@local"
                    git config user.name "Jenkins CI"
                    git add deploy/values.yaml deploy/Chart.yaml
                    git diff --cached --quiet || git commit -m "ci: update image tag to ${env.DOCKER_TAG}"
                    git push origin HEAD:main
                """
            }
        }
    }

    post {
        success {
            echo """
            ==========================================
            Deploy complete!
            Image: ${env.FULL_IMAGE}
            ArgoCD will auto-sync the new version.
            ==========================================
            """
        }
        failure {
            echo 'Deploy failed. Check the logs above.'
        }
    }
}
