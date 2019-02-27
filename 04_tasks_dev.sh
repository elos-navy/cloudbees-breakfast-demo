#!/bin/bash -x

# Setup Development Project
# Create new project for our application deployment:
oc new-project xyz-tasks-dev --display-name "Tasks Application Development"

# Grant edit rights on this project to jenkins user:
oc policy add-role-to-user edit system:serviceaccount:xyz-jenkins:jenkins -n xyz-tasks-dev
oc policy add-role-to-user edit system:serviceaccount:xyz-jenkins:default -n xyz-tasks-dev

# Create build configuration for our image build stage in pipeline:
oc create -f bc-tasks-dev.yaml
oc create -f is-tasks.yaml
oc create -f is-wildfly.yaml

# Create new application to host our deliverables for integration and user testing:
oc new-app xyz-tasks-dev/tasks:0.0-0 --name=tasks --allow-missing-imagestream-tags=true --allow-missing-images -n xyz-tasks-dev

# Remove deployment triggers, deployment will be executed from CICD pipeline:
oc set triggers dc/tasks --remove-all -n xyz-tasks-dev

# Expose port 8080 as application service:
oc expose dc tasks --port 8080 -n xyz-tasks-dev

# Expose configured service as external route:
oc expose svc tasks -n xyz-tasks-dev

# Create configuration maps holding application config data and init with placeholder values (wildfly authentication properties files):
oc create configmap tasks-config --from-literal="application-users.properties=Placeholder" --from-literal="application-roles.properties=Placeholder" -n xyz-tasks-dev

# Associate config maps with path on logical filesystem:
oc set volume dc/tasks --add --name=jboss-config --mount-path=/opt/jboss/wildfly/standalone/configuration/application-users.properties --sub-path=application-users.properties --configmap-name=tasks-config -n xyz-tasks-dev

# Associate config maps with path on logical filesystem:
oc set volume dc/tasks --add --name=jboss-config1 --mount-path=/opt/jboss/wildfly/standalone/configuration/application-roles.properties --sub-path=application-roles.properties --configmap-name=tasks-config -n xyz-tasks-dev

