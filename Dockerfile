# Use CentOS 7 base image from Docker Hub
FROM redhat/ubi8
MAINTAINER Joe Manifold "https://github.com/wolviex"
#MAINTAINER Steve Kamerman "https://github.com/kamermans"
#MAINTAINER Jose De la Rosa "https://github.com/jose-delarosa"

# Environment variables
ENV PATH $PATH:/opt/dell/srvadmin/bin:/opt/dell/srvadmin/sbin
ENV TERM xterm
ENV USER root
ENV PASS password

# Prevent daemon helper scripts from making systemd calls
ENV SYSTEMCTL_SKIP_REDIRECT=1
ENV container docker

# Do overall update and install missing packages needed for OpenManage
RUN mkdir -p /run/lock/subsys \
    && echo "$USER:$PASS" | chpasswd \
    # Add OMSA repo
    && yum -y install \
        gcc passwd which \
        dmidecode \
    # Strip systemd so it can run inside Docker
    # Note: "srvadmin-services.sh enable" doesn't work here because systemd is not PID 1 at build-time (it will be when it's run)
    && (cd /usr/lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == \
    systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /usr/lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /usr/lib/systemd/system/local-fs.target.wants/*; \
    rm -f /usr/lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /usr/lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /usr/lib/systemd/system/basic.target.wants/*; \
    rm -f /usr/lib/systemd/system/anaconda.target.wants/*
RUN curl -O https://linux.dell.com/repo/hardware/dsu/bootstrap.cgi && echo "y" | bash bootstrap.cgi && sed -ie "s/dsu/DSU_23.04.14/g" /etc/yum.repos.d/*
RUN yum -y install dell-system-update \
    && yum clean all \ 
    && echo "dmidecode -t1" >> ~/.bashrc

# Replace systemctl with a partial reimplementation for docker images
# @see: https://github.com/gdraheim/docker-systemctl-replacement
COPY ./resources/systemctl.py /usr/bin/systemctl

# Note: the entrypoint script must contain systemd in the first
# 16 characters of its name so that the Dell srvadmin-services.sh script
# thinks its running with systemd as PID 1 and executes systemd services
COPY ./resources/entrypoint.sh /fake-systemd-entrypoint.sh

ENTRYPOINT ["/fake-systemd-entrypoint.sh"]
CMD ["tail", "-f", "/opt/dell/srvadmin/var/log/openmanage/*.xml"]

WORKDIR /opt/dell/srvadmin/bin

#EXPOSE 1311 161 162
