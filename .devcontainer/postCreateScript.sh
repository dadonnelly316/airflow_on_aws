#! /bin/bash

apt-get update && apt-get install -y \
    php5-mcrypt \
    python3-pip

echo "echo test..."
echo $(python3 --version)

pip install --no-cache-dir -r ./.devcontainer/dev.requirements.txt