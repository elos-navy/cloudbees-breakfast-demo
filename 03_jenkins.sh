#!/bin/bash -x

# Setup Jenkins Master Server
# Create new project hosting our Jenkins application:
oc new-project xyz-jenkins --display-name "Jenkins Master Server"

# Create new application based on public container image:
oc new-app jenkins-persistent \
  --param ENABLE_OAUTH=true

# Create custom jenkins agent pod
oc new-build  -D $'FROM docker.io/openshift/jenkins-agent-maven-35-centos7:v3.11\n
      USER root\nRUN yum -y install skopeo && yum clean all\n
      USER 1001' --name=jenkins-agent-appdev -n xyz-jenkins

while true; do
  PODS_COUNT=$(oc get rc | grep jenkins | awk '{ print $4 }')
  [ "$PODS_COUNT" == "1" ] && break
  sleep 10
done

oc create -f bc-pipeline.yaml
oc start-build bc/pipeline
