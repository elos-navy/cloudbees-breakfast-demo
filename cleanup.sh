#!/bin/bash -x

oc delete project lsm-nexus
oc delete project xyz-sonarqube
oc delete project xyz-jenkins
oc delete project xyz-tasks-dev
oc delete project xyz-tasks-prod
