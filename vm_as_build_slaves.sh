FROM jenkins:alpine

USER root

RUN apk add --no-cache \
  libvirt-qemu \
  libvirt-dev \
  qemu

RUN echo 'kvm:x:4242:jenkins'  >> /etc/group
RUN echo 'qemu:x:4243:jenkins' >> /etc/group

USER jenkins

RUN install-plugins.sh \
  libvirt-slave
