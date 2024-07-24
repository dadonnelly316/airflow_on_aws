#! /bin/bash

apt-get update && apt-get install -y \
    pylint

echo "echo test..."
echo $(python3 --version)

pip install --no-cache-dir -r ./.devcontainer/dev.requirements.txt

# pylint needs an _init__.py file
echo pass > ./app/__init__.py

echo $(pylint --version)
pylint ./app