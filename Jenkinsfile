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
        stage("Docker build") {
            steps {
                script {
                    env.DOCKER_IMAGE = docker.build("") 
                }
            }
        }

        stage("A"){
            steps{
                echo "========executing A========"
            }
            post{
                always{
                    echo "========always========"
                }
                success{
                    echo "========A executed successfully========"
                }
                failure{
                    echo "========A execution failed========"
                }
            }
        }
    }
    post{
        always{
            echo "========always========"
        }
        success{
            echo "========pipeline executed successfully ========"
        }
        failure{
            echo "========pipeline execution failed========"
        }
    }
}