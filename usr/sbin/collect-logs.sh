#!/bin/bash

set -e 

TOOLS_BASE=/tmp/
# get tools
if [[ ! -x $(which git) ]]; then
    sudo apt-get install -y git
    git config --global user.email "u@exmaple.com"
    git config --global user.name "u"
fi
cd $TOOLS_BASE
git clone https://github.com/alex-tu-cc/collect-logs.git || true
cd $OLDPWD

# run tools to collect logs

bash $TOOLS_BASE/collect-logs/collect-logs.sh

