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
		sh '''#!/bin/sh
			wget -c https://github.com/slapin/godot-templates-build/releases/download/2019_29_0717_0052/godot-templates.tar.gz
			tar xf godot-templates.tar.gz
			ls -l
			ls -l godot-templates
			./godot-templates/godot_server.x11.opt.tools.64  --help || true
			
		'''
	}
	stage("export-linux") {
		sh '''#!/bin/sh
			./godot-templates/godot_server.x11.opt.tools.64 --path $(pwd)/proto1 --export "Linux X11" $(pwd)/proto1-linux
		'''
	}
}
