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
			rm -f export-templates
			tar xf godot-templates.tar.gz
			ln -sf godot-templates export-templates
			ls -l
			ls -l godot-templates
			./godot-templates/godot_server.x11.tools.64  --help || true
			
		'''
	}
	stage("export-linux") {
		sh '''#!/bin/sh
			set -e
			base=$(pwd)
			cd proto1
			ls -l
			${base}/godot-templates/godot_server.x11.tools.64 --export "linux" ${base}/proto1-linux
			cd ..
			ls -l
		'''
	}
	stage("export-html5") {
		sh '''#!/bin/sh
			set -e
			base=$(pwd)
			cd proto1
			ls -l
			${base}/godot-templates/godot_server.x11.tools.64 --export "HTML5" ${base}/proto1-html5
			cd ..
			ls -l
		'''
	}
}

