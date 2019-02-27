#!/bin/bash -x

# Setup Sonarqube Analysis Server
# Create new project for Sonarqube server:
oc new-project xyz-sonarqube --display-name "Sonarqube Analysis Server"

# Create persistent database server based on PostgreSQL application template:
oc new-app --template=postgresql-persistent --param POSTGRESQL_USER=sonar --param POSTGRESQL_PASSWORD=sonar --param POSTGRESQL_DATABASE=sonar --param VOLUME_CAPACITY=4Gi --labels=app=sonarqube_db

# Wait for database to start-up. Create Sonarqube application from public image:
oc new-app --docker-image=wkulhanek/sonarqube:6.7.4 --env=SONARQUBE_JDBC_USERNAME=sonar --env=SONARQUBE_JDBC_PASSWORD=sonar --env=SONARQUBE_JDBC_URL=jdbc:postgresql://postgresql/sonar --labels=app=sonarqube

# Pause deployment based on configuration changes:
oc rollout pause dc sonarqube

# Expose default service as default route:
oc expose service sonarqube

# Create persistent volume claim for Sonarqube application data:
echo "apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: sonarqube-pvc
spec:
 accessModes:
 - ReadWriteOnce
 resources:
   requests:
     storage: 4Gi" | oc create -f -

# Associate PVC claim with pod mount path:
oc set volume dc/sonarqube --add --overwrite --name=sonarqube-volume-1 --mount-path=/opt/sonarqube/data/ --type persistentVolumeClaim --claim-name=sonarqube-pvc

# Set resources requests and limits:
oc set resources dc/sonarqube --limits=memory=2Gi,cpu=1 --requests=memory=1Gi,cpu=500m

# Change deployment strategy from Rollout to Recreate:
oc patch dc sonarqube --patch='{ "spec": { "strategy": { "type": "Recreate" }}}'

# Set liveness probe based on container command execution:
oc set probe dc/sonarqube --liveness --failure-threshold 3 --initial-delay-seconds 40 -- echo ok

# Set readiness probe based on HTTP check:
oc set probe dc/sonarqube --readiness --failure-threshold 3 --initial-delay-seconds 20 --get-url=http://:9000/about

# Resume deployment execution:
oc rollout resume dc sonarqube

