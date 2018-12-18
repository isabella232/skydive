#!/bin/bash

set -v
set -e

VPP_POOLING=0.25

dir="$(dirname "$0")"
TEMP_DIR=${TEMP_DIR:-/tmp/skydive-vpp}
mkdir -p $TEMP_DIR/skydive-etcd

vpp_create_loopback() {
    loop=$(vppctl loopback create-interface | tr -d '\r')
    ret=$?
    if [ -z "$loop" ] ; then
        echo "can't create loopback $loop interface : $ret"
        exit 1
    fi
    # skydive vpp probe poll every 200ms
    sleep $VPP_POOLING
    echo "$loop"
}

cd ${GOPATH}/src/github.com/skydive-project/skydive
make WITH_VPP=true VERBOSE=true install

cat <<EOF >> $TEMP_DIR/skydive.yml
logging:
  level: DEBUG
etcd:
  embedded: true
  data_dir: $TEMP_DIR/skydive-etcd
agent:
  topology:
    probes:
      - vpp
analyzer:
  flow:
    backend: elasticsearch
  topology:
    backend: elasticsearch
EOF

echo "VPP tests ..."

loop1=$(vpp_create_loopback)

export SKYDIVE_ANALYZERS="127.0.0.1:8082"
sudo $GOPATH/bin/skydive allinone -c $TEMP_DIR/skydive.yml &
SKYDIVE_PID=$!
sleep 5

t1=$(skydive client query "g.V().Has('Driver','vpp','Name','$loop1')" | wc -l)
if [ $t1 -le 1 ] ; then
    echo "$loop1 test failed : $t1"
    exit 1
fi
echo "Test t1 : OK"


loop2=$(vpp_create_loopback)
t2=$(skydive client query "g.V().Has('Driver','vpp','Name','$loop2')" | wc -l)
if [ $t2 -le 1 ] ; then
    echo "$loop2 test failed : $t2"
    exit 1
fi
echo "Test t2 : OK"


vppctl loopback delete-interface intfc $loop1 ; sleep $VPP_POOLING
t3=$(skydive client query "g.V().Has('Driver','vpp','Name','$loop1')" | wc -l)
if [ $t3 -gt 1 ] ; then
    echo "del $loop1 test failed : $t3"
    exit 1
fi
echo "Test t3 : OK"
vppctl loopback delete-interface intfc $loop2

echo "Waiting Skydive exit ..."
sudo pkill -f "$GOPATH/bin/skydive allinone"
wait %1
echo "Skydive exit $?"
