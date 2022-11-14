FROM ubuntu:22.04
MAINTAINER cezary.klos+docker@gmail.com

# setup envs
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV container docker
ENV DEBIAN_FRONTEND noninteractive

# systemd based on https://github.com/j8r/dockerfiles/blob/master/systemd/ubuntu/22.04.Dockerfile
RUN apt-get update \
    && apt-get install -y systemd systemd-sysv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && rm $(ls | grep -v systemd-tmpfiles-setup)

RUN rm -f /lib/systemd/system/multi-user.target.wants/* \
    /etc/systemd/system/*.wants/* \
    /lib/systemd/system/local-fs.target.wants/* \
    /lib/systemd/system/sockets.target.wants/*udev* \
    /lib/systemd/system/sockets.target.wants/*initctl* \
    /lib/systemd/system/basic.target.wants/* \
    /lib/systemd/system/anaconda.target.wants/* \
    /lib/systemd/system/plymouth* \
    /lib/systemd/system/systemd-update-utmp*

# setup locale for postgres and other packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y locales && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
    apt-get install -y  \
    wget nano htop git curl cron gosu \
    imagemagick \
    openssh-server redis \
    logrotate \
    nginx nginx-extras \
    dirmngr gnupg \
    apt-transport-https ca-certificates \
    openssl libssl-dev libreadline-dev make gcc \
    zlib1g-dev bzip2 software-properties-common \
    postgresql-client g++ openssl libssl-dev libpq-dev && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7 && \
    echo deb https://oss-binaries.phusionpassenger.com/apt/passenger jammy main > /etc/apt/sources.list.d/passenger.list && \
    apt-get update && apt-get install -y libnginx-mod-http-passenger passenger && \
    rm /etc/nginx/conf.d/mod-http-passenger.conf && \
    /usr/bin/passenger-config build-native-support && \
    /usr/bin/passenger-config validate-install && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    groupadd -g 1000 webapp && \
    useradd -m -s /bin/bash -g webapp -u 1000 webapp && \
    echo "webapp:Password1" | chpasswd && \
    mkdir -p /home/webapp/.ssh


# setup rbenv and install ruby
USER webapp
ARG RUBY_VERSION=2.7.6
RUN git clone https://github.com/sstephenson/rbenv.git /home/webapp/.rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git /home/webapp/.rbenv/plugins/ruby-build && \
    echo "export PATH=/home/webapp/.rbenv/bin:/home/webapp/.rbenv/shims:\$PATH" >> /home/webapp/.bashrc && \
    echo "export RBENV_ROOT=/home/webapp/.rbenv" >> /home/webapp/.bashrc && \
    echo "gem: --no-rdoc --no-ri" > /home/webapp/.gemrc
RUN /home/webapp/.rbenv/bin/rbenv install ${RUBY_VERSION} && \
    /home/webapp/.rbenv/bin/rbenv global ${RUBY_VERSION} && \
    /home/webapp/.rbenv/shims/gem update --system && \
    /home/webapp/.rbenv/shims/gem install bundler && \
    /home/webapp/.rbenv/bin/rbenv rehash

USER root

# install node
ARG NODE_VERSION=12.19.0
RUN apt-get update && apt-get install -y nodejs npm && \
    npm install -g n && n ${NODE_VERSION} && npm install -g npm

ARG RAILS_ENV=staging
ARG NODE_ENV=production
ARG FRIENDLY_ERROR_PAGES=on
ARG WITH_SUDO=true

RUN echo "RUBY_VERSION=${RUBY_VERSION}" >> /etc/environment && \
    echo "NODE_VERSION=${NODE_VERSION}" >> /etc/environment && \
    echo "RAILS_ENV=${RAILS_ENV}" >> /etc/environment && \
    echo "NODE_ENV=${NODE_ENV}" >> /etc/environment && \
    echo "FRIENDLY_ERROR_PAGES=${FRIENDLY_ERROR_PAGES}" >> /etc/environment && \
    echo "WITH_SUDO=${WITH_SUDO}" >> /etc/environment

## add webapp user to sudo
RUN if [ $WITH_SUDO = "true" ] ; then \
        apt-get update && \
        apt-get install -y sudo && \
        usermod -a -G sudo webapp && \
        echo "webapp ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/00_webapp_sudo_rules \
    ; fi

# setup passenger-prometheus monitoring
COPY --from=zappi/passenger-exporter /usr/local/bin/passenger-exporter /usr/local/bin/passenger-exporter

# setup logrotate
# https://www.juhomi.com/how-to-rotate-log-files-in-your-rails-application/
COPY rootfs /
COPY --chown=webapp:webapp homefs/webapp/ /home/webapp
RUN chmod g+x,o+x /home/webapp
RUN (crontab -l; echo "0 * * * * /usr/sbin/logrotate") | crontab -

# setup nginx
RUN sed -e "s/\${RAILS_ENV}/${RAILS_ENV}/" -e "s/\${FRIENDLY_ERROR_PAGES}/${FRIENDLY_ERROR_PAGES}/" -i /etc/nginx/sites-enabled/default
RUN nginx -t

## install docker-entrypoint and cleanup whole image with final setups
RUN chmod 700 /docker-entrypoint.sh && apt-get clean && rm -rf /tmp/* /var/tmp/*

VOLUME "/home/webapp/webapp"
VOLUME "/home/webapp/.ssh"
VOLUME "/sys/fs/cgroup"
EXPOSE 22 80
CMD ["/docker-entrypoint.sh"]
