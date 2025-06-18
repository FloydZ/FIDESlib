
pipeline {
    stages{
        stage('Build') {
            steps {
                script {
                    sh './build.sh'
                }
            }
        }
        stage("Run tests") {
            steps {
                script {
                    sh ' ./build/fideslib-test'
                }
            }
        }
        stage('SonarQube analysis') {
             steps {
                dir('build'){
                    script {
                        sh 'cp ../sonar-project.properties .'
                        sonar.scanCProject("wrapper_output", "-Dsonar.projectBaseDir=${WORKSPACE} -Dsonar.scanner.metadataFilePath=${WORKSPACE}/build/report-task.txt")
                    }
                }
            }
        }
    }
    post {
        always {
            script {
                notify currentBuild.result
            }
        }
    }
}
