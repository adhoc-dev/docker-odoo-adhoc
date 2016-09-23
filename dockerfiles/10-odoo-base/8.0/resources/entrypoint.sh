#!/bin/bash
#
# This script is designed to be run inside the container
#

# fail hard and fast even on pipelines
set -eo pipefail

function help {
    set +e
    cat bin/help.txt
    set -e
}

function login  {
    echo "Running bash"
    set +e
    if [[ ! -e $1 && $1 = "root" ]]; then
        /bin/bash
    else
        sudo su - odoo
    fi
    SERVICE_PID=$!
    set -e
}

function start {
    echo "Running odoo..."
    set +e
    if [ ! -e $1 ]; then
        echo "...with additional args: $*"
    fi
    sudo -i -u odoo /usr/bin/python \
                    /opt/odoo/sources/odoo/openerp-server \
                    -c $file \
                    $*

    SERVICE_PID=$!
    set -e
}

# smart shutdown on SIGINT and SIGTERM
function on_exit() {
    kill -TERM $SERVICE_PID
    wait $SERVICE_PID 2>/dev/null
    exit 0
}
trap on_exit INT TERM

echo "Search conf file"
if [[ -z "$ODOO_CONF" ]];
then
    file="/opt/odoo/etc/odoo.conf"
else
    file=$ODOO_CONF
fi
if [ ! -f "$file" ]; then
    cp /opt/odoo/resources/template-odoo.conf $file 
    echo "Copy template as conf file $file"
fi
chown -R odoo /opt/odoo
echo "Running command..."
for arg in "$*"
do
    $arg
done

wait
