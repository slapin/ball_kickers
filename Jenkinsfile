properties([
  parameters([
    booleanParam(defaultValue: true, description: 'Redownlad large file', name: 'DOWNLOAD_TEMPLATES')
   ])
])

def git_clone(url, branch, dirname)
{ 
        checkout([$class: 'GitSCM',
        branches: [[name: "*/${branch}"]],
        doGenerateSubmoduleConfigurations: false,
        extensions: [[$class: 'LocalBranch', localBranch: branch],
                    [$class: 'RelativeTargetDirectory',
        relativeTargetDir: dirname]],
        submoduleCfg: [],
        userRemoteConfigs: [[url: url]]])
}
node('docker && ubuntu-16.04') {
	stage("clone") {
		checkout scm
	}
	stage("download") {
		if (params.DOWNLOAD_TEMPLATES) {
			sh '''#!/bin/sh
				rm -f godot-templates.tar.gz
				wget -c https://github.com/slapin/godot-templates-build/releases/download/2019_29_0717_2355/godot-templates.tar.gz
			'''
		}
		sh '''#!/bin/sh
			tar xf godot-templates.tar.gz
			ls -l
			ls -l godot-templates
			./godot-templates/godot_server.x11.tools.64  --help || true
			
		'''
	}
	stage("export-linux") {
		sh '''#!/bin/sh
			strace -e open ./godot-templates/godot_server.x11.tools.64 --path $(pwd)/proto1 --export "linux" $(pwd)/proto1-linux
		'''
	}
}

