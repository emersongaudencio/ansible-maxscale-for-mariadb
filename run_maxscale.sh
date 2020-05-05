#!/bin/bash

export SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export PYTHON_BIN=/usr/bin/python
export ANSIBLE_CONFIG=$SCRIPT_PATH/ansible.cfg

cd $SCRIPT_PATH

VAR_HOST=${1}
VAR_MX_MODE=${2}
VAR_MAXSCALE_USER=${3}
VAR_MAXSCALE_PASS=${4}
VAR_MONITOR_USER=${5}
VAR_MONITOR_PASS=${6}
VAR_PRIMARY=${7}
VAR_BACKUP=${8}

if [ "${VAR_HOST}" == '' ] ; then
  echo "No host specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_MX_MODE}" == '' ] ; then
  echo "No MaxScale Mode specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_MAXSCALE_USER}" == '' ] ; then
  echo "No MaxScale User specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_MAXSCALE_PASS}" == '' ] ; then
  echo "No MaxScale Password specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_MONITOR_USER}" == '' ] ; then
  echo "No MaxScale Monitor user specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_MONITOR_PASS}" == '' ] ; then
  echo "No MaxScale Monitor password specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_PRIMARY}" == '' ] ; then
  echo "No PRIMARY Database backend specified. Please have a look at README file for futher information!"
  exit 1
elif [ "${VAR_BACKUP}" == '' ] ; then
  VAR_BACKUP=${VAR_PRIMARY}
fi

### MaxScale Setup ####
ansible-playbook -v -i $SCRIPT_PATH/hosts -e "{mx_mode: '$VAR_MX_MODE', maxscale_user: '$VAR_MAXSCALE_USER', maxscale_pass: '$VAR_MAXSCALE_PASS', monitor_user: '$VAR_MONITOR_USER', monitor_pass: '$VAR_MONITOR_PASS', primary: '$VAR_PRIMARY', backup: '$VAR_BACKUP'}" $SCRIPT_PATH/playbook/maxscale.yml -l $VAR_HOST
