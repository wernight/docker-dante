pipeline{
    agent {
        node {
            label "linux-large||docker"
        }
    }
    options {
        disableConcurrentBuilds()
        timeout(time: 3, unit: 'HOURS')
        buildDiscarder(logRotator(numToKeepStr: '40', artifactNumToKeepStr: '40')) 
    }    
    environment {
        BUILDNR = "${env.BUILD_NUMBER}"
        GIT_SHA = sh(returnStdout: true, script: 'git rev-parse HEAD').substring(0, 7)
        WORKSPACE = pwd()
        CURRENT_VERSION = readFile "${env.WORKSPACE}/version"
    }
    parameters {
        booleanParam(defaultValue: false, description: 'Skal prosjektet releases?', name: 'isRelease')
        string(name: "releaseVersion", defaultValue: "", description: "Hva er det nye versjonsnummeret?")
        string(name: "snapshotVersion", defaultValue: "", description: "Hva er den nye snapshotversjonen (uten -SNAPSHOT)?")
    }
    stages{
        stage('Initialize') {
            steps {
                rtBuildInfo(captureEnv: true, maxBuilds: 30)
                script {
                    if(params.isRelease) {
                        env.TARGET_REPO = 'docker-local'
                    } else {
                        env.TARGET_REPO = 'docker-local-snapshots'
                    }
                }
            }
        }
        stage('Release: Set new release version') {
            when {
                expression { params.isRelease }
            }

            steps {
                script {
                    if (params.releaseVersion == null || params.releaseVersion == "" || params.snapshotVersion == null || params.snapshotVersion == "") {
                        currentBuild.result = 'ABORTED'
                        error("release and snapshot version must be set")
                    }

                    env.IMAGE_TAG = params.releaseVersion
                    env.CURRENT_VERSION = params.releaseVersion
                    currentBuild.description = "Release: ${params.releaseVersion}"
                }
                gitCheckout()
                writeFile(file: "${env.WORKSPACE}/version", text: params.releaseVersion);
                sh 'git add version'
                sh 'git commit -m "new release version"'
                sh "git tag -a ${params.releaseVersion} -m \"Releasing jenkins build ${env.BUILD_NUMBER}\""
                gitPush()
            }
        }

        stage('Snapshot: Set image tag') {
            when {
                expression { !params.isRelease }
            }

            steps {
                script {
                    env.IMAGE_TAG = env.CURRENT_VERSION.replace("SNAPSHOT", env.GIT_SHA)
                }
            }
        }
        stage("Docker build and push") {
            environment {
                IMAGE_NAME_WITH_TAG = "fiks-socks:${env.IMAGE_TAG}"
                CONTEXT_NAME = "EDGE-$BUILD_NUMBER"
            }
            steps {
                withDockerRegistry(credentialsId: 'artifactory-token-based', url: "https://${env.TARGET_REPO}.artifactory.fiks.ks.no/") {
                    sh(script: 'docker run --privileged --rm tonistiigi/binfmt --install all', label: 'Setup emulation')
                    sh(script: "docker buildx create --name $CONTEXT_NAME --platform linux/amd64,linux/arm64 --bootstrap --use", label: 'Set up docker buildx environment')
                    sh(script: "docker buildx build --platform linux/amd64,linux/arm64 --tag ${TARGET_REPO}.artifactory.fiks.ks.no/${IMAGE_NAME_WITH_TAG} --push --progress plain .", label: 'Bygg med docker buildx build')
                    sh(script: "docker buildx rm $CONTEXT_NAME", returnStatus: true, label: "Cleanup")
                }
            }
        }
        stage('Release: Set new snapshot version') {
            when {
                expression { params.isRelease }
            }

            steps {
                writeFile(file: "${env.WORKSPACE}/version", text: "${params.snapshotVersion}-SNAPSHOT");
                sh 'git add version'
                sh "git commit -m \"Setting new snapshot version to ${params.snapshotVersion}-SNAPSHOT\""
                gitPush()
            }
        }
    }
    post{
        always {
            rtPublishBuildInfo(serverId: 'KS Artifactory')
        }

    }
}