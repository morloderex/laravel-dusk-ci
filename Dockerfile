
FROM ubuntu:xenial
MAINTAINER Michael

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true
ENV LC_ALL=en_US.UTF-8
ENV DISPLAY :99
ENV SCREEN_RESOLUTION 1920x720x24
ENV CHROMEDRIVER_PORT 9515

ENV TMPDIR=/tmp
RUN apt-get update && apt-get install -yq apt-utils zip unzip
RUN apt-get update && apt-get install -yq openssl language-pack-en-base
RUN apt-get update && apt-get install -yq software-properties-common curl sudo
RUN add-apt-repository ppa:ondrej/php
RUN add-apt-repository ppa:nginx/development
RUN sed -i'' 's/archive\.ubuntu\.com/us\.archive\.ubuntu\.com/' /etc/apt/sources.list
RUN apt-get update
RUN apt-get upgrade -yq
RUN apt-get update && apt-get install -yq libgd-tools
RUN apt-get update && apt-get install -yq --fix-missing php7.1-fpm php7.1-cli php7.1-xml php7.1-zip php7.1-curl php7.1-bcmath php7.1-json \
    php7.1-mbstring php7.1-pgsql php7.1-mysql php7.1-mcrypt php7.1-gd php7.1-soap php7.1-sqlite php-xdebug php-imagick imagemagick nginx

RUN apt-get update && apt-get install -yq mc lynx mysql-client bzip2 make g++

ENV COMPOSER_HOME /usr/local/share/composer
ENV COMPOSER_ALLOW_SUPERUSER 1
ENV PATH "$COMPOSER_HOME:$COMPOSER_HOME/vendor/bin:$PATH"
RUN \
  mkdir -pv $COMPOSER_HOME && chmod -R g+w $COMPOSER_HOME \
  && curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
  && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
  && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) \
    !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); \
    echo 'Invalid installer' . PHP_EOL; exit(1); }" \
  && php /tmp/composer-setup.php --filename=composer --install-dir=$COMPOSER_HOME 

ADD commands/xvfb.init.sh /etc/init.d/xvfb 

ADD commands/start-nginx-ci-project.sh /usr/bin/start-nginx-ci-project

ADD configs/.bowerrc /root/.bowerrc

RUN chmod +x /usr/bin/start-nginx-ci-project
ADD commands/configure-laravel.sh /usr/bin/configure-laravel

RUN chmod +x /usr/bin/configure-laravel

RUN \
  apt-get update && apt-get install -yq xvfb gconf2 fonts-ipafont-gothic xfonts-cyrillic xfonts-100dpi xfonts-75dpi xfonts-base \
    xfonts-scalable \
  && chmod +x /etc/init.d/xvfb \
  && CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` \
  && mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION \
  && curl -sS -o /tmp/chromedriver_linux64.zip \
    http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip \
  && unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION \
  && rm /tmp/chromedriver_linux64.zip \
  && chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver \
  && ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver \
  && curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
  && apt-get -yqq update && apt-get -yqq install google-chrome-stable x11vnc

RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit
RUN apt-get install -y supervisor
ADD configs/supervisord.conf /etc/supervisor/supervisord.conf
ADD configs/nginx-default-site /etc/nginx/sites-available/default

ADD configs/hosts /etc/hosts

VOLUME [ "/var/log/supervisor" ]

RUN apt-get -y upgrade
RUN apt-get -y autoremove
RUN apt-get -yq clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN php --version
RUN php -m
RUN nginx -v
RUN phpunit --version

EXPOSE 80 9515

CMD ["php7.1-fpm", "-g", "daemon off;"]
CMD ["nginx", "-g", "daemon off;"]
