ARG  BASE=ubuntu:18.04
FROM $BASE
ARG  ARCH=x86_64
RUN apt-get -y update \
    && apt-get -y install openvswitch-common libpcap0.8 libxml2 libvirt0 curl
RUN curl -s https://packagecloud.io/install/repositories/fdio/1901/script.deb.sh | bash
RUN apt-get -y install vpp-lib=19.01-16~gd30202244~b42
COPY skydive.$ARCH /usr/bin/skydive
COPY skydive.yml /etc/skydive.yml
ENTRYPOINT ["/usr/bin/skydive", "--conf", "/etc/skydive.yml"]
