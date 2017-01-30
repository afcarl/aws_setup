#!/bin/bash

source ./aws_private
# Loads AWS_JUPYTER_HASHED_PWD 

CERTIFICATE_DIR="certificate"
JUPYTER_CONFIG_DIR=".jupyter"
DEFAULT_PORT="8888"
USER="carnd"

if [ ! -d "~/$CERTIFICATE_DIR" ]; then
    mkdir ~/$CERTIFICATE_DIR
    openssl req -x509 -nodes -days 365 -newkey rsa:1024 -keyout "$CERTIFICATE_DIR/mykey.key" -out "$CERTIFICATE_DIR/mycert.pem" -batch
    chown -R $USER $CERTIFICATE_DIR
fi

if [ ! -f "~/$JUPYTER_CONFIG_DIR/jupyter_notebook_config.py" ]; then
    # generate default config file
    #jupyter notebook --generate-config
    mkdir $JUPYTER_CONFIG_DIR

    # append notebook server settings
    cat <<EOF >> "$JUPYTER_CONFIG_DIR/jupyter_notebook_config.py"
# Set options for certfile, ip, password, and toggle off browser auto-opening
c.NotebookApp.certfile = u'$CERTIFICATE_DIR/mycert.pem'
c.NotebookApp.keyfile = u'$CERTIFICATE_DIR/mykey.key'
# Set ip to '*' to bind on all interfaces (ips) for the public server
c.NotebookApp.ip = '*'
c.NotebookApp.password = u'$AWS_JUPYTER_HASHED_PWD'
c.NotebookApp.open_browser = False
# It is a good idea to set a known, fixed port for server access
c.NotebookApp.port = $DEFAULT_PORT
EOF
    chown -R $USER $JUPYTER_CONFIG_DIR
fi

