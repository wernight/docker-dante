pipeline{
    agent any
    environment {
        BUILDNR = "${env.BUILD_NUMBER}"
        GIT_SHA = sh(returnStdout: true, script: 'git rev-parse HEAD').substring(0, 7)
        WORKSPACE = pwd()
        CURRENT_VERSION = readFile "${env.WORKSPACE}/version"
        DOCKER_IMAGE = ''
        UID = "${sh(script: 'echo $(id -u)', returnStdout: true, label: 'Finn UID')}"
        GID = "${sh(script: 'echo $(id -g)', returnStdout: true, label: 'Finn GID')}"
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
            agent {
                docker {
                    image 'data61/magda-builder-docker:latest'
                    args "-u $UID:$GID"
                    registryUrl "https://${env.TARGET_REPO}.artifactory.fiks.ks.no/"
                    registryCredentialsId 'artifactory-token-based'
                }
            }
            environment {
                IMAGE_NAME_WITH_TAG = "fiks-socks:${env.IMAGE_TAG}"

            }
            steps {
                sh "pwd && whoami"
                //sh "docker version"
                sh(script: "docker buildx build -t ${env.IMAGE_NAME_WITH_TAG} --platform linux/arm64,linux/amd64 --progress=plain .", label: "Build multiarch docker image") 
                // withDockerRegistry(credentialsId: 'artifactory-token-based', url: "https://${env.TARGET_REPO}.artifactory.fiks.ks.no/") {
                //    sh "docker buildx build -t ${env.IMAGE_NAME_WITH_TAG} --platform linux/arm64,linux/amd64 --push -o type=registry --progress=plain ."                   
                //}
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