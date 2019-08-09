#!/bin/bash
ME=" * bcBuildr:"

echo "$ME -=-=-=- proxy config -=-=-=-"
echo "		http_proxy=$http_proxy"
echo "		https_proxy=$https_proxy"
echo "		no_proxy=$no_proxy"

#not sure how portable these are...
JENKINS_CLI="/var/cache/jenkins/war/WEB-INF/jenkins-cli.jar"
#.lastStarted is guaranteed to appear on a fresh boot of this stateless container
JENKINS_STARTED="/var/lib/jenkins/.lastStarted"
JENKINS_UPDATES="http://updates.jenkins-ci.org/latest"
JENKINS_ADMINPASSWD_FILE="/var/lib/jenkins/secrets/initialAdminPassword"
JENKINS_PLUGINS_TGZ="/tmp/jenkins_plugins.tgz"

#fetch & install jenkins plug-in.
#atm, there's no cli-method to set the jenkins proxy we use wget
getNinstall_jenkins_plugin() {
	#check for existing, else wget
	printf "$1: "
	if [ ! -f /tmp/$1.hpi ]; then
		printf "not found in cache, fetching... "
		wget -qP/tmp $JENKINS_UPDATES/$1.hpi
		printf "done.\n"
	else
		printf "found in local cache.\n"
	fi
	java -jar $JENKINS_CLI -s http://127.0.0.1:8080/ -auth admin:$ADMINPASSWD install-plugin file:///tmp/$1.hpi
	#rm -f /tmp/$1.hpi
}

wait_for() {
	timeleft=$(expr $2)
	while [ $timeleft -ne 0 ]
	do
		if sudo test -f $1; then
			printf "\n$ME Found %s!" $1
			break
		fi
		sleep 1
		timeleft=$(expr $timeleft - 1)
		printf "\r$ME Waiting for %d more seconds for %s to show-up..." $timeleft $1
	done
	#now check if it really appeared or we just timed-out
	if sudo test ! -f $1; then
		printf "\n$ME *** time-out waiting for $1 to appear ***"
		printf "\n$ME cannot continue so I'm giving-up. Here's a terminal for your troubles.\n\n"
		exec "/bin/bash"
	else
		echo "$ME $1 has appeared!"
	fi
}

#1. Start Jenkins then wait for it to come-up
sudo service jenkins start

echo "$ME Waiting for Jenkins to start-up..."
wait_for $JENKINS_STARTED "60"
echo "$ME Jenkins started."
wait_for $JENKINS_ADMINPASSWD_FILE "60"

ADMINPASSWD=$(sudo cat $JENKINS_ADMINPASSWD_FILE)
echo "$ME jenkins admin password: $ADMINPASSWD"

#2. Install plugins
echo "$ME Installing Jenkins plug-ins from $JENKINS_UPDATES."
echo "$ME This may take a few minutes..."

echo "(using proxy config: http:$http_proxy https:$https_proxy no:$no_proxy)"

getNinstall_jenkins_plugin 'scm-api'
getNinstall_jenkins_plugin 'gitlab-api'
getNinstall_jenkins_plugin 'gitlab-plugin'
getNinstall_jenkins_plugin 'git-client'
getNinstall_jenkins_plugin 'git-server'
getNinstall_jenkins_plugin 'publish-over-ssh'
getNinstall_jenkins_plugin 'structs'
getNinstall_jenkins_plugin 'apache-httpcomponents-client-4-api'
getNinstall_jenkins_plugin 'ssh-credentials'
getNinstall_jenkins_plugin 'credentials'
getNinstall_jenkins_plugin 'jsch'
getNinstall_jenkins_plugin 'publish-over'
getNinstall_jenkins_plugin 'pipeline-github'
getNinstall_jenkins_plugin 'pipeline-build-step'
getNinstall_jenkins_plugin 'pipeline-input-step'
getNinstall_jenkins_plugin 'pipeline-model-api'
getNinstall_jenkins_plugin 'pipeline-rest-api'
getNinstall_jenkins_plugin 'pipeline-stage-step'
getNinstall_jenkins_plugin 'pipeline-stage-view'
getNinstall_jenkins_plugin 'pipeline-utility-steps'
getNinstall_jenkins_plugin 'workflow-support'
getNinstall_jenkins_plugin 'workflow-step-api'
getNinstall_jenkins_plugin 'workflow-api'
getNinstall_jenkins_plugin 'pipeline-graph-analysis'
getNinstall_jenkins_plugin 'jackson2-api'
getNinstall_jenkins_plugin 'workflow-job'
getNinstall_jenkins_plugin 'script-security'
getNinstall_jenkins_plugin 'workflow-cps'
getNinstall_jenkins_plugin 'github-branch-source'
getNinstall_jenkins_plugin 'github-api'
getNinstall_jenkins_plugin 'github'
getNinstall_jenkins_plugin 'display-url-api'
getNinstall_jenkins_plugin 'git'
getNinstall_jenkins_plugin 'workflow-scm-step'
getNinstall_jenkins_plugin 'ace-editor'
getNinstall_jenkins_plugin 'jquery-detached'
getNinstall_jenkins_plugin 'mailer'
getNinstall_jenkins_plugin 'matrix-project'
getNinstall_jenkins_plugin 'handlebars'
getNinstall_jenkins_plugin 'momentjs'
getNinstall_jenkins_plugin 'junit'
getNinstall_jenkins_plugin 'token-macro'
getNinstall_jenkins_plugin 'plain-credentials'
getNinstall_jenkins_plugin 'envinject'
getNinstall_jenkins_plugin 'envinject-api'
getNinstall_jenkins_plugin 'environment-script'
getNinstall_jenkins_plugin 'ivy'
getNinstall_jenkins_plugin 'multi-branch-project-plugin'
getNinstall_jenkins_plugin 'branch-api'
getNinstall_jenkins_plugin 'ant'
getNinstall_jenkins_plugin 'config-file-provider'
getNinstall_jenkins_plugin 'cloudbees-folder'

echo "$ME Done installing plugins. You're welcome."

#java -jar $JENKINS_CLI -s http://127.0.0.1:8080/ -auth admin:$ADMINPASSWD create-job</home/user/job.xml

echo "$ME Adding Jenkins web UI user, user:pass"
echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount("user", "pass")' | java -jar $JENKINS_CLI -s http://127.0.0.1:8080/ -auth admin:$ADMINPASSWD -noKeyAuth groovy =

#add job... need to do it AFTER setting-up users, otherwise we never get a admin passwd  
sudo mkdir -p /var/lib/jenkins/jobs/bcBuildr/builds
sudo cp -av /home/user/job1-config.xml /var/lib/jenkins/jobs/bcBuildr/config.xml
sudo chown -R jenkins: /var/lib/jenkins

#set installation to RUNNING
sudo sed -i 's/NEW/RUNNING/g' /var/lib/jenkins/config.xml

echo "$ME Restarting Jenkins..."
sudo service jenkins restart

echo "$ME All done!"

exec "/bin/bash"
