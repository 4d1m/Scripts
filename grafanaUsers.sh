#!/bin/bash
#title                  :grafanaUsers.sh
#description            :This script adds new users to Grafana using the CLI through use of the Grafana API
#date                   :29/06/2018
#version                :0.0.1
#usage                  :./grafanaUsers.sh
#notes                  : Please fill in all the relevant information;
#=====================================================================
GrafanaAdminUSER=
GrafanaAdminPASS=
GrafanaServerIP=

NewUserName=
NewUserEmail=
NewUserLogin=
NewUserPassword=

curl -X POST -H "Content-Type: application/json" -d '{"name":"$NewUserName", "email":"$NewUserEmail", "login":"$NewUserLogin", "password":"$NewUserPassword"}' http://$GrafanaAdminUSER:$GrafanaAdminPASS@$GrafanaServerIP/grafana/api/admin/users
