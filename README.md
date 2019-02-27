# CloudBees Breakfast OpenShift Demo

## Vytvorenie komponent

Pre komponenty je nutne vytvorit 4 persistent volumes objekty s velkostou aspon 4G. Napriklad s pripravenym NFS exportom:

```
oc create -f pv1.yaml
oc create -f pv2.yaml
oc create -f pv3.yaml
oc create -f pv4.yaml
```

Nasledne je mozne vytvorit vsetky potrebne komponenty:

```
./01_nexus.sh
./02_sonarqube.sh
./03_jenkins.sh
./04_tasks_dev.sh
./05_tasks_prod.sh
```

## Pipeline

V tuto chvilu by mala bit pipeline uz pripravena v OpenShifte v projekte `xyz-jenkins` a tiez v jenkins aplikacii pre spustenie.


## Kontakt

V pripade otazok a problemov prosim kontaktujte: Lukas Stanek <ls@elostech.cz>

