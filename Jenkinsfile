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
                        mkdir butler
                        cd butler
                        curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default
                        unzip butler.zip
                        chmod +x butler
                        ./butler -V
			cd ..
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
			rm -Rf BallKickers
			mkdir BallKickers
			mv ${base}/proto1-linux BallKickers/BallKickers
			zip -r BallKickers-linux.zip BallKickers
			rm -Rf BallKickers
		'''
	}
	stage("export-windows") {
		sh '''#!/bin/sh
			set -e
			base=$(pwd)
			cd proto1
			ls -l
			${base}/godot-templates/godot_server.x11.tools.64 --export "windows" ${base}/proto1-windows.exe
			cd ..
			ls -l
			rm -Rf BallKickers
			mkdir BallKickers
			mv ${base}/proto1-windows.exe BallKickers/proto1.exe
			zip -r BallKickers-windows.zip BallKickers
			rm -Rf BallKickers
		'''
	}
	stage("export-html5") {
		sh '''#!/bin/sh
			set -e
			base=$(pwd)
			cd proto1
			ls -l
			${base}/godot-templates/godot_server.x11.tools.64 --export "HTML5" ${base}/proto1-html5.zip
			cd ..
			ls -l
		'''
	}
	stage("itch.io") {
		withCredentials([string(credentialsId: 'itchio_token', variable: 'itchio_token')]) {
			withEnv(["BUTLER_API_KEY=$itchio_token"]) {
				sh '''#!/bin/sh
					export PATH=$PATH:$(pwd)/butler
					butler push proto1-html5.zip slapin/ball-kickers:html
					H=$?
					butler status slapin/ball-kickers:html
					butler push BallKickers-windows.zip slapin/ball-kickers:windows
					W=$?
					butler status slapin/ball-kickers:windows
					butler status slapin/ball-kickers:linux
					butler push BallKickers-linux.zip slapin/ball-kickers:linux
					L=$?
					butler status slapin/ball-kickers:linux
					if [ $H != 0 -o $W != 0 -o $L != 0 ]; then
						exit 1
					fi
				'''
			}
		}
	}
}

