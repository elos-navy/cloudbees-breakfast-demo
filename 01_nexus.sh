#!/bin/bash -x

# Setup Nexus Artifact Repository Server
# Create project for setting-up Nexus repository:
oc new-project lsm-nexus --display-name "Nexus Repository Server"

# Install new application from publicly available image for Sonatype Nexus:
oc new-app sonatype/nexus3:latest

# Expose default service nexus3 on (default) route:
oc expose svc nexus3

# Service and route for nexus registry
oc expose dc nexus3 --port=5000 --name=nexus-registry
oc create route edge nexus-registry --service=nexus-registry --port=5000

# Pause rollouts to execute deployment configuration changes in one step:
oc rollout pause dc nexus3

# Set deployment strategy from Rollout to Recreate:
oc patch dc nexus3 --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'

# Set resources requests (min.) and limits (max.) values:
oc set resources dc nexus3 --limits=memory=4Gi,cpu=1 --requests=memory=500Mi,cpu=500m

# Create persistent volume claim for storing Nexus data (echo command injects configuration file into oc create command by pipe):
echo "apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: nexus-pvc
spec:
 accessModes:
 - ReadWriteOnce
 resources:
   requests:
     storage: 4Gi" | oc create -f -

# Associate mountpoint in Pod filesystem with created PVC claim:
oc set volume dc/nexus3 --add --overwrite --name=nexus3-volume-1 --mount-path=/nexus-data/ --type persistentVolumeClaim --claim-name=nexus-pvc

# Set liveness probe for Pod monitoring:
oc set probe dc/nexus3 --liveness --failure-threshold 3 --initial-delay-seconds 60 -- echo ok

# Set readiness probe for Pod monitoring:
oc set probe dc/nexus3 --readiness --failure-threshold 3 --initial-delay-seconds 60 --get-url=http://:8081/repository/maven-public/

# Resume paused changes and execute new configuration:
oc rollout resume dc nexus3

# Setup Repositories Structure
# Login into the running Nexus pod either by OCP web console or by using the command:

while true; do
  PODS_COUNT=$(oc get rc | grep nexus | awk '{ print $4 }')
  [ "$PODS_COUNT" -eq 1 ] && break
  sleep 10
done

POD_NAME=$(oc get pod | grep nexus | grep -v deploy | awk '{ print $1 }')
oc rsync ./ ${POD_NAME}:/tmp/
oc rsh ${POD_NAME} /tmp/setup_nexus3.sh admin admin123 http://localhost:8081

