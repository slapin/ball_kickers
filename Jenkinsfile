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
				rm -f export-templates
				rm -Rf godot-templates
				TAG=$(curl -s https://api.github.com/repos/slapin/godot-templates-build/releases/latest|grep tag_name|cut -d : -f2|cut -d '"' -f2)
				rm -f godot-templates.tar.gz
				FILE_NAME=godot-templates-${TAG}.tar.gz
				curl -s https://api.github.com/repos/slapin/godot-templates-build/releases/latest|grep browser_download_url|cut -d : -f2-|cut -d '"' -f 2|wget -c -O${FILE_NAME} -i -
				tar xf ${FILE_NAME}
				ln -sf godot-templates export-templates
			'''
		}
		sh '''#!/bin/sh
			rm -Rf proto2-html5.zip BallKickers-windows.zip BallKickers-linux.zip \
				BallKickers BallKickers.zip proto1-html proto1-html5 proto1-html5.js \
				proto1-html5.pck proto1-html5.png proto1-html5.wasm \
				proto1-html5.zip proto2-html proto2-linux proto2-windows.exe
                        mkdir -p butler
                        cd butler
                        curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default
                        unzip butler.zip
                        chmod +x butler
                        ./butler -V
			cd ..
			ls -l
			ls -l godot-templates
			./godot-templates/godot_server.x11.tools.64  --help || true
			wget -c https://download.blender.org/release/Blender2.80/blender-2.80-linux-glibc217-x86_64.tar.bz2
			git clone git://github.com/godotengine/godot-blender-exporter
			tar xf blender-2.80-linux-glibc217-x86_64.tar.bz2
			cd blender-2.80-linux-glibc217-x86_64/2.80/scripts/addons
			ln -s ../../../../godot-blender-exporter/io_scene_godot .
			cd ../../../..
			./blender-2.80-linux-glibc217-x86_64/blender -b -P enable_addons.py
		'''
	}
	stage("blender-export") {
		sh '''#!/bin/sh
			cd proto2
			rm -f characters/accessory.json
			rm -Rf characters/accessory
			rm -Rf .import
			../blender-2.80-linux-glibc217-x86_64/blender -b --debug-io -P export.py
			rm -Rf exports
		'''
	}
	stage("build-blendmaps") {
		sh '''#!/bin/sh
			base=$(pwd)
			cd proto2
			rm -f characters/accessory.json
			rm -Rf characters/accessory
			rm -Rf .import
			ls -l
			${base}/godot-templates/godot_server.x11.tools.64 -e tests/quit.tscn
			${base}/godot-templates/godot_server.x11.tools.64 tests/test-triangles.tscn
		'''
	}
	stage("export-linux") {
		sh '''#!/bin/sh
			set -e
			base=$(pwd)
			rm -f ${base}/BallKickers-linux.zip
			cd proto2
			ls -l
			${base}/godot-templates/godot_server.x11.tools.64 \
				--export "linux" ${base}/proto2-linux
			cd ..
			if [ ! -f ${base}/proto2-linux ]; then
				exit 1
			fi
			ls -l
			rm -Rf BallKickers
			mkdir BallKickers
			mv ${base}/proto2-linux BallKickers/BallKickers
			zip -r BallKickers-linux.zip BallKickers
			rm -Rf BallKickers
		'''
	}
	stage("export-windows") {
		sh '''#!/bin/sh
			set -e
			base=$(pwd)
			rm -f ${base}/BallKickers-windows.zip
			cd proto2
			ls -l
			${base}/godot-templates/godot_server.x11.tools.64 \
				--export "windows" ${base}/proto2-windows.exe
			cd ..
			ls -l
			rm -Rf BallKickers
			mkdir BallKickers
			mv ${base}/proto2-windows.exe BallKickers/proto2.exe
			zip -r BallKickers-windows.zip BallKickers
			rm -Rf BallKickers
		'''
	}
	stage("export-html5") {
		sh '''#!/bin/sh
			set -e
			base=$(pwd)
			rm -f ${base}/proto2-html5.zip
			rm -Rf proto2-html
			mkdir proto2-html
			cd proto2
			ls -l
			cp project.godot project.godot.backup
			sed -e 's/GLES3/GLES2/g' -i project.godot
			cat project.godot
			${base}/godot-templates/godot_server.x11.tools.64 \
				--export "HTML5" ${base}/proto2-html/index.html
			cp project.godot.backup project.godot
			rm -f project.godot.backup

			cd ..
			cd proto2-html
			zip -r ${base}/proto2-html5.zip *
			cd ..
			ls -l
		'''
	}
	stage("artifacts") {
		archiveArtifacts artifacts: "proto2-html5.zip", onlyIfSuccessful: true
		archiveArtifacts artifacts: "BallKickers-windows.zip", onlyIfSuccessful: true
		archiveArtifacts artifacts: "BallKickers-linux.zip", onlyIfSuccessful: true
	}
	stage("itch.io") {
		withCredentials([string(credentialsId: 'itchio_token', variable: 'itchio_token')]) {
			withEnv(["BUTLER_API_KEY=$itchio_token"]) {
				sh '''#!/bin/sh
					exit 0
					export PATH=$PATH:$(pwd)/butler
					butler push proto2-html5.zip slapin/ball-kickers:html
					H=$?
					butler status slapin/ball-kickers:html
					butler push proto2-html5.zip slapin/ball-kickers-html:html
					H2=$?
					butler status slapin/ball-kickers-html:html
					butler push BallKickers-windows.zip slapin/ball-kickers:windows
					W=$?
					butler status slapin/ball-kickers:windows
					butler status slapin/ball-kickers:linux
					butler push BallKickers-linux.zip slapin/ball-kickers:linux
					L=$?
					butler status slapin/ball-kickers:linux
					if [ $H != 0 -o $H2 != 0 -o $W != 0 -o $L != 0 ]; then
						exit 1
					fi
				'''
			}
		}
	}
}

