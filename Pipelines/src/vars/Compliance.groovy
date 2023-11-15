def pipeline
node() {
    stage('Compliance') {
        when {
            expression { env.branchName.startsWith('Release') || env.branchName.startsWith('release') }
        }
        steps {
            script {
                String[] diffMaster = sh(returnStdout: true, script: "git rev-list --left-right --count origin/master...Release/${env.branchName}").trim()

                def behind = ""
                def ahead = ""

                def isBehind = true

                for(def i = 0; i < diffMaster.length; i++) {
                    //echo "diffMaster[${i}] = '${diffMaster[i]}' ou '${diffMaster[i].trim()}'"
                    if(diffMaster[i].trim().length() > 0) {
                        if(isBehind) {
                            behind += diffMaster[i]
                        }
                        else {
                            ahead += diffMaster[i]
                        }
                    } 
                    else {
                        isBehind = false
                    }
                }

                echo "${behind} behind and ${ahead} ahead of master"

                if (behind != "0") {
                    currentBuild.result = 'ABORTED'
                    error("ERROR: Branch [${env.branchName}] ${behind} behind and ${ahead} ahead of master")
                }
            }
        }
    }
    pipeline.build()
}