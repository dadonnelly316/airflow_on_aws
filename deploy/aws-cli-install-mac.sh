#!/bin/sh

# todo - don't use a command that requires manual user input
# todo - install ibm cloud cli on linux for CI hosted in production-like environments

which aws
if [ $? -ne 0 ]; then 

    echo "installing aws cli"

    mkdir _tmp ./
    curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "./_tmp/AWSCLI.pkg"
    sudo installer -pkg ./_tmp/AWSCLI.pkg -target /
    rm -rf ./_tmp

else
    echo "aws cli is already installed"
fi

aws --version
