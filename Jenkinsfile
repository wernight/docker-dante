pipeline{
    agent any
    environment {
        BUILDNR = "${env.BUILD_NUMBER}"
        GIT_SHA = sh(returnStdout: true, script: 'git rev-parse HEAD').substring(0, 7)
        WORKSPACE = pwd()
        CURRENT_VERSION = readFile "${env.WORKSPACE}/version"
        DOCKER_IMAGE = ''
    }
    parameters {
        booleanParam(defaultValue: false, description: 'Skal prosjektet releases?', name: 'isRelease')
        string(name: "releaseVersion", defaultValue: "", description: "Hva er det nye versjonsnummeret?")
        string(name: "snapshotVersion", defaultValue: "", description: "Hva er den nye snapshotversjonen?")
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
            steps {
                script {
                    def image = docker.build("fiks-socks:${env.IMAGE_TAG}")
                    docker.withRegistry("https://${env.TARGET_REPO}.artifactory.fiks.ks.no/", 'artifactory-token-based')
                    {
                        image.push()
                    }
                    /* rtDockerPush(serverId: 'KS Artifactory',
                    image: "${image}",
                    targetRepo: "${env.TARGET_REPO}") */
                }
            }
        }
    }
    post{
        always {
            rtPublishBuildInfo(serverId: 'KS Artifactory')
        }

    }
}