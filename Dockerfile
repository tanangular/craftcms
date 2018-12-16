FROM php:7.3-fpm-alpine

LABEL maintainer="tanangular@gmail.com"

ENV COMPOSER_NO_INTERACTION=1
ENV TIMEZONE=Asia/Bangkok
ENV PHALCON_VERSION=3.4.2

RUN set -ex \
  && apk add --update --no-cache \
  freetype \
  libpng \
  libjpeg-turbo \
  freetype-dev \
  libpng-dev \
  libjpeg-turbo-dev \
  libxml2-dev \
  autoconf \
  g++ \
  imagemagick \
  imagemagick-dev \
  libtool \
  make \
  pcre-dev \
  postgresql-dev \
  postgresql \
  libintl \
  icu \
  icu-dev \
  bash \
  jq \
  git \
  findutils \
  gzip \
  && docker-php-ext-configure gd \
  --with-freetype-dir=/usr/include/ \
  --with-png-dir=/usr/include/ \
  --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install mbstring iconv gd soap zip intl pdo_pgsql \
  && pecl install imagick redis \
  && docker-php-ext-enable imagick redis \
  && rm -rf /tmp/pear \
  && apk del freetype-dev libpng-dev libjpeg-turbo-dev autoconf g++ libtool make pcre-dev \
  && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
  && echo ${TIMEZONE} > /etc/timezone

# Compile Phalcon
RUN set -xe && \
  curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
  tar xzf v${PHALCON_VERSION}.tar.gz && cd cphalcon-${PHALCON_VERSION}/build && sh install && \
  echo "extension=phalcon.so" > /usr/local/etc/php/conf.d/phalcon.ini && \
  cd ../.. && rm -rf v${PHALCON_VERSION}.tar.gz cphalcon-${PHALCON_VERSION}

RUN apk add gnu-libiconv --update-cache --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ --allow-untrusted
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

COPY ./php.ini /usr/local/etc/php/

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY scripts/ /scripts/
RUN chown -R www-data:www-data /scripts \
  && chmod -R +x /scripts

WORKDIR /var/www/html
RUN chown -R www-data:www-data .
USER www-data

# Install Craft CMS and save original dependencies in file
RUN composer create-project craftcms/craft . \
  && cp composer.json composer.base

VOLUME [ "/var/www/html" ]

ENTRYPOINT [ "/scripts/run.sh" ]

CMD [ "docker-php-entrypoint", "php-fpm"]
