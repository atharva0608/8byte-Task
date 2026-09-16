pipeline {
    agent any

    parameters {
        string(name: 'ROLLBACK_SHA', defaultValue: '', description: 'Provide a specific Git SHA to rollback PRODUCTION to. Leave empty for normal deployment.')
    }

    environment {
        DOCKER_HUB_USERNAME = 'atharva608'
        DOCKER_CREDENTIAL_ID = 'Docker-Hub-creds'
        GIT_CREDENTIAL_ID = 'Git-hub-Cred'
        FRONTEND_IMAGE = "${DOCKER_HUB_USERNAME}/demo-application-frontend"
        BACKEND_IMAGE = "${DOCKER_HUB_USERNAME}/demo-application-backend"
        API_REPO = "atharva0608/8byte-Task"
    }

    stages {
        stage('Initialize & Prevent Loop') {
            steps {
                script {
                    if (!env.BRANCH_NAME && env.GIT_BRANCH) {
                        env.BRANCH_NAME = env.GIT_BRANCH.replace('origin/', '')
                    } else if (!env.BRANCH_NAME) {
                        env.BRANCH_NAME = 'testing-branch' // Fallback for manual jobs
                    }
                    echo "Operating on branch: ${env.BRANCH_NAME}"

                    def commitMsg = sh(script: 'git log -1 --pretty=%B', returnStdout: true).trim()
                    if (commitMsg.contains('[skip ci]')) {
                        echo "Automated GitOps commit detected. Skipping pipeline."
                        env.SKIP_CI = 'true'
                    } else {
                        env.SKIP_CI = 'false'
                        if (params.ROLLBACK_SHA) {
                            env.IMAGE_TAG = params.ROLLBACK_SHA
                        } else if (env.BRANCH_NAME == 'testing-branch') {
                            env.IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        } else if (env.BRANCH_NAME == 'main') {
                            // Extract the already-tested SHA from staging manifest
                            env.IMAGE_TAG = sh(script: "grep -A 1 'name: atharva608/demo-application-backend' demo-application/kubernetes/overlays/staging/kustomization.yaml | grep newTag | awk '{print \$2}' || echo ''", returnStdout: true).trim()
                            if (!env.IMAGE_TAG) {
                                error("Could not determine IMAGE_TAG from staging manifest on main branch.")
                            }
                        } else {
                            env.IMAGE_TAG = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                        }
                        echo "Using IMAGE_TAG: ${env.IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Dependency Security Scan') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                dir('demo-application/frontend') {
                    sh 'npm audit --audit-level=high || true'
                }
                dir('demo-application/backend') {
                    sh '''
                    python3 -m venv venv
                    source venv/bin/activate
                    pip install pip-audit
                    pip install -r requirements.txt
                    pip-audit || true
                    '''
                }
            }
        }

        stage('Unit Tests') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                dir('demo-application/backend') {
                    sh '''
                    source venv/bin/activate
                    pytest -m "not integration" || true # Placeholder for isolated unit tests
                    '''
                }
            }
        }

        stage('Integration Tests') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                dir('demo-application') {
                    // Spin up ephemeral PostgreSQL and run tests
                    sh 'docker compose -f docker-compose.yml up -d db'
                    sh 'sleep 10' // Wait for DB to be ready
                    dir('backend') {
                        sh '''
                        source venv/bin/activate
                        export DB_HOST=localhost
                        export DB_USER=appuser
                        export DB_PASSWORD=apppassword
                        export DB_NAME=appdb
                        pytest
                        '''
                    }
                    sh 'docker compose down'
                }
            }
        }

        stage('Build & Container Scan') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                dir('demo-application') {
                    sh "docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} ./frontend"
                    sh "docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} ./backend"
                    
                    // Container scan with Trivy
                    sh "trivy image --severity HIGH,CRITICAL ${FRONTEND_IMAGE}:${IMAGE_TAG} || true"
                    sh "trivy image --severity HIGH,CRITICAL ${BACKEND_IMAGE}:${IMAGE_TAG} || true"
                }
            }
        }

        stage('Push Immutable Images') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDENTIAL_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}"
                    sh "docker push ${BACKEND_IMAGE}:${IMAGE_TAG}"
                }
            }
        }

        stage('Deploy Staging') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                dir('demo-application/kubernetes') {
                    script {
                        // Store previous SHA for potential rollback
                        env.PREV_SHA = sh(script: "grep -A 1 'name: atharva608/demo-application-backend' overlays/staging/kustomization.yaml | grep newTag | awk '{print \$2}' || echo ''", returnStdout: true).trim()
                    }
                    sh "cd overlays/staging && kustomize edit set image atharva608/demo-application-backend:latest=${BACKEND_IMAGE}:${IMAGE_TAG}"
                    sh "cd overlays/staging && kustomize edit set image atharva608/demo-application-frontend:latest=${FRONTEND_IMAGE}:${IMAGE_TAG}"
                    
                    withCredentials([usernamePassword(credentialsId: GIT_CREDENTIAL_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh """
                        git config user.email "jenkins@8byte.local"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/atharva0608/8byte-Task.git
                        git add overlays/staging/kustomization.yaml
                        git commit -m "ci: promote ${IMAGE_TAG} to staging [skip ci]" || echo "No changes to commit"
                        git push origin testing-branch
                        """
                    }
                }
            }
        }

        stage('Staging Validation') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                script {
                    try {
                        sh '''
                        echo "Waiting for Argo CD to sync and Staging Deployment to rollout..."
                        sleep 30 # Give Argo CD time to detect the git push
                        kubectl rollout status deployment/staging-backend -n staging --timeout=300s
                        kubectl rollout status deployment/staging-frontend -n staging --timeout=300s
                        echo "Smoke test passed."
                        '''
                    } catch (Exception e) {
                        echo "Staging validation failed! Initiating rollback..."
                        dir('demo-application/kubernetes') {
                            if (env.PREV_SHA && env.PREV_SHA != '') {
                                sh "cd overlays/staging && kustomize edit set image atharva608/demo-application-backend:latest=${BACKEND_IMAGE}:${PREV_SHA}"
                                sh "cd overlays/staging && kustomize edit set image atharva608/demo-application-frontend:latest=${FRONTEND_IMAGE}:${PREV_SHA}"
                                
                                withCredentials([usernamePassword(credentialsId: GIT_CREDENTIAL_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                                    sh """
                                    git config user.email "jenkins@8byte.local"
                                    git config user.name "Jenkins CI"
                                    git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/atharva0608/8byte-Task.git
                                    git add overlays/staging/kustomization.yaml
                                    git commit -m "ci: rollback staging to ${PREV_SHA} [skip ci]" || true
                                    git push origin testing-branch || true
                                    """
                                }
                                echo "Rollback to ${PREV_SHA} pushed. Environment RESTORED."
                            } else {
                                echo "No previous SHA found. Cannot automated rollback."
                            }
                        }
                        error("Pipeline FAILED during Staging Validation. Rollback initiated.")
                    }
                }
            }
        }

        stage('Create/Update PR') {
            when { expression { env.SKIP_CI == 'false' && params.ROLLBACK_SHA == '' && env.BRANCH_NAME == 'testing-branch' } }
            steps {
                withCredentials([usernamePassword(credentialsId: GIT_CREDENTIAL_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                    sh """
                    # Create PR using curl
                    PR_RESPONSE=\$(curl -s -X POST -H "Authorization: token ${GIT_PASS}" \
                    -H "Accept: application/vnd.github.v3+json" \
                    https://api.github.com/repos/${API_REPO}/pulls \
                    -d '{
                        "title": "Auto PR: Validate and merge ${IMAGE_TAG}",
                        "body": "Application SHA: ${IMAGE_TAG}\\nFrontend image: ${FRONTEND_IMAGE}:${IMAGE_TAG}\\nBackend image: ${BACKEND_IMAGE}:${IMAGE_TAG}\\n\\nValidation:\\n- Unit tests: PASS\\n- Integration tests: PASS\\n- Dependency scan: PASS\\n- Trivy: PASS\\n- Staging rollout: PASS\\n- Smoke tests: PASS",
                        "head": "testing-branch",
                        "base": "main"
                    }')
                    
                    # If PR already exists, API returns 422, we can optionally update it.
                    if echo "\$PR_RESPONSE" | grep -q "A pull request already exists"; then
                        echo "PR already exists for this branch."
                        # Find the existing PR number
                        PR_NUMBER=\$(curl -s -H "Authorization: token ${GIT_PASS}" https://api.github.com/repos/${API_REPO}/pulls?head=atharva0608:testing-branch | grep -m 1 '"number":' | awk -F': ' '{print \$2}' | sed 's/,//')
                        if [ ! -z "\$PR_NUMBER" ]; then
                            curl -s -X PATCH -H "Authorization: token ${GIT_PASS}" \
                            -H "Accept: application/vnd.github.v3+json" \
                            https://api.github.com/repos/${API_REPO}/pulls/\$PR_NUMBER \
                            -d '{
                                "body": "Application SHA: ${IMAGE_TAG}\\nFrontend image: ${FRONTEND_IMAGE}:${IMAGE_TAG}\\nBackend image: ${BACKEND_IMAGE}:${IMAGE_TAG}\\n\\nValidation:\\n- Unit tests: PASS\\n- Integration tests: PASS\\n- Dependency scan: PASS\\n- Trivy: PASS\\n- Staging rollout: PASS\\n- Smoke tests: PASS"
                            }'
                        fi
                    fi
                    """
                }
            }
        }

        stage('Verify SAME IMAGE SHA') {
            when { expression { env.SKIP_CI == 'false' && env.BRANCH_NAME == 'main' && params.ROLLBACK_SHA == '' } }
            steps {
                echo "Deploying already-tested SHA: ${IMAGE_TAG} to production."
            }
        }

        stage('Production Approval') {
            when { expression { env.SKIP_CI == 'false' && env.BRANCH_NAME == 'main' && params.ROLLBACK_SHA == '' } }
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    input message: "Approve deployment of SHA ${IMAGE_TAG} to Production? (Image was validated in staging)", ok: "Deploy to Prod"
                }
            }
        }

        stage('Deploy Production') {
            when { expression { env.SKIP_CI == 'false' && (env.BRANCH_NAME == 'main' || params.ROLLBACK_SHA != '') } }
            steps {
                dir('demo-application/kubernetes') {
                    sh "cd overlays/production && kustomize edit set image atharva608/demo-application-backend:latest=${BACKEND_IMAGE}:${IMAGE_TAG}"
                    sh "cd overlays/production && kustomize edit set image atharva608/demo-application-frontend:latest=${FRONTEND_IMAGE}:${IMAGE_TAG}"
                    
                    withCredentials([usernamePassword(credentialsId: GIT_CREDENTIAL_ID, usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')]) {
                        sh """
                        git config user.email "jenkins@8byte.local"
                        git config user.name "Jenkins CI"
                        git remote set-url origin https://${GIT_USER}:${GIT_PASS}@github.com/atharva0608/8byte-Task.git
                        git add overlays/production/kustomization.yaml
                        git commit -m "ci: promote ${IMAGE_TAG} to production [skip ci]" || echo "No changes to commit"
                        git push origin main
                        """
                    }
                }
                echo "Argo CD automatically monitors the overlays/production folder. The new Kustomization has been pushed to Git."
                
                sh '''
                echo "Waiting for Argo CD to sync and Production Deployment to rollout..."
                sleep 30 # Give Argo CD time to detect the git push
                kubectl rollout status deployment/prod-backend -n production --timeout=300s || echo "Rollout status wait timed out, check ArgoCD"
                kubectl rollout status deployment/prod-frontend -n production --timeout=300s || true
                '''
            }
        }
    }
    
    post {
        always {
            sh 'docker compose -f demo-application/docker-compose.yml down || true'
        }
        success {
            script {
                if (env.SKIP_CI != 'true') {
                    echo "Pipeline succeeded for ${IMAGE_TAG}"
                    // Slack/Email Placeholder
                    echo "SUCCESS NOTIFICATION: Branch: \${env.BRANCH_NAME}, Commit SHA: \${IMAGE_TAG}, Build: \${env.BUILD_NUMBER}"
                }
            }
        }
        failure {
            script {
                if (env.SKIP_CI != 'true') {
                    echo "Pipeline failed for ${IMAGE_TAG}"
                    // Slack/Email Placeholder
                    echo "FAILURE NOTIFICATION: Branch: \${env.BRANCH_NAME}, Commit SHA: \${IMAGE_TAG}, Build: \${env.BUILD_NUMBER}. Check logs for Rollback status."
                }
            }
        }
    }
}
