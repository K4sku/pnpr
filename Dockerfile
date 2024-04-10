FROM --platform=linux/amd64 ubuntu:20.04 AS nginx_brotli_modules
ENV DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install --no-install-recommends -y  \
    wget git gcc cmake libpcre3 libpcre3-dev make libbrotli-dev \
    zlib1g zlib1g-dev openssl libssl-dev ca-certificates
RUN wget https://nginx.org/download/nginx-1.18.0.tar.gz && \
    tar zxvf nginx-1.18.0.tar.gz && \
    git clone --recurse-submodules -j8 https://github.com/google/ngx_brotli.git
RUN cd nginx-1.18.0 && \
    ./configure --with-compat --add-dynamic-module=../ngx_brotli && \
    make modules

FROM --platform=linux/amd64 ubuntu:20.04
LABEL author="docker@cklos.com"

# setup envs
ENV DEBIAN_FRONTEND=noninteractive LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# setup locale for postgres and other packages
RUN apt-get update && apt-get upgrade -y && apt-get install -y locales && \
    localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    echo 'LANG="en_US.UTF-8"' > /etc/default/locale && \
    echo 'LANGUAGE="en_US:en"' >> /etc/default/locale && \
    apt-get install --no-install-recommends -y  \
    wget nano htop git curl cron gosu psmisc \
    imagemagick libvips brotli \
    shared-mime-info \
    openssh-server redis \
    logrotate \
    nginx nginx-extras \
    dirmngr gnupg \
    libjemalloc-dev libyaml-dev libffi-dev rustc \
    apt-transport-https ca-certificates \
    openssl libssl-dev libreadline-dev make gcc \
    zlib1g-dev bzip2 software-properties-common build-essential \
    postgresql-client g++ openssl libssl-dev libpq-dev && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7 && \
    echo deb https://oss-binaries.phusionpassenger.com/apt/passenger focal main > /etc/apt/sources.list.d/passenger.list && \
    apt-get update && apt-get install -y libnginx-mod-http-passenger passenger && \
    rm /etc/nginx/conf.d/mod-http-passenger.conf && \
    /usr/bin/passenger-config build-native-support && \
    /usr/bin/passenger-config validate-install && \
    apt-get clean && rm -rf /tmp/* /var/tmp/* && \
    groupadd -g 1000 webapp && \
    useradd -m -s /bin/bash -g webapp -u 1000 webapp && \
    echo "webapp:Password1" | chpasswd && \
    mkdir -p /home/webapp/.ssh

# copy brotli nginx module
COPY --from=nginx_brotli_modules /nginx-1.18.0/objs/*.so /usr/share/nginx/modules

USER webapp

# setup rbenv and install ruby
ARG RUBY_VERSION=3.2.3
RUN git clone https://github.com/sstephenson/rbenv.git /home/webapp/.rbenv && \
    git clone https://github.com/sstephenson/ruby-build.git /home/webapp/.rbenv/plugins/ruby-build && \
    echo "export PATH=/home/webapp/.rbenv/bin:/home/webapp/.rbenv/shims:\$PATH" >> /home/webapp/.bashrc && \
    echo "export RBENV_ROOT=/home/webapp/.rbenv" >> /home/webapp/.bashrc && \
    echo "gem: --no-rdoc --no-ri" > /home/webapp/.gemrc

RUN RUBY_CONFIGURE_OPTS="--with-jemalloc --enable-yjit" /home/webapp/.rbenv/bin/rbenv install 3.2.3
RUN /home/webapp/.rbenv/bin/rbenv global 3.2.3 && \
    /home/webapp/.rbenv/shims/gem install bundler:2.5.4 && \
    /home/webapp/.rbenv/shims/gem install foreman && \
    /home/webapp/.rbenv/bin/rbenv rehash

USER root

# install node
# https://github.com/nodesource/distributions/blob/master/README.md#using-debian-as-root-2
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &&\
    apt-get install --no-install-recommends -y nodejs=20.12.1-1nodesource1 &&  \
    apt-get clean && rm -rf  /tmp/* /var/tmp/*
RUN npm install -g yarn@1.22.19

# setup passenger-prometheus monitoring
COPY --from=zappi/passenger-exporter:1.0.0 /opt/app/bin/passenger-exporter /usr/local/bin/passenger-exporter
COPY --chown=webapp:webapp homefs/webapp/ /home/webapp
COPY rootfs /

# setup logrotate
# https://www.juhomi.com/how-to-rotate-log-files-in-your-rails-application/
RUN chown -R webapp:webapp /usr/lib/node_modules && \
    chmod g+x,o+x /home/webapp &&  \
    chmod +x /docker-entrypoint.sh && \
    chmod +x /usr/local/bin/foremand && \
    chmod +x /usr/local/bin/foremand-supervisor && \
    chmod 0600 /etc/logrotate.d/* && \
    rm /etc/init.d/dbus /etc/init.d/hwclock.sh /etc/init.d/procps && \
    (crontab -l; echo "33 3 * * * /usr/sbin/logrotate /etc/logrotate.d/*") | crontab -

ARG RAILS_ENV=production
ARG NODE_ENV=production
ARG FRIENDLY_ERROR_PAGES=off

RUN echo "RUBY_VERSION=${RUBY_VERSION}" >> /erb.templates/templates/etc-environment.rb && \
    echo "RAILS_ENV=${RAILS_ENV}" >> /erb.templates/templates/etc-environment.rb && \
    echo "NODE_ENV=${NODE_ENV}" >> /erb.templates/templates/etc-environment.rb && \
    echo "FRIENDLY_ERROR_PAGES=${FRIENDLY_ERROR_PAGES}" >> /erb.templates/templates/etc-environment.rb

RUN nginx -t && bash /erb.templates/render.sh && nginx -t

HEALTHCHECK --interval=5s --timeout=3s --start-period=30s --retries=3 CMD curl -f http://localhost/healtcheck || exit 1
VOLUME "/home/webapp/.ssh"
VOLUME "/home/webapp/webapp"
EXPOSE 22 80 9149 8080 8081 8082
CMD ["/docker-entrypoint.sh"]
