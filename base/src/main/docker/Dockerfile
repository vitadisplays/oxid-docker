FROM debian:stretch

#RUN mkdir /docker-entrypoint-initoxid-sources.d /docker-entrypoint-initdb.d /docker-entrypoint-initoxid-scripts.d

ENV DEBIAN_FRONTEND noninteractive
RUN echo "deb http://deb.debian.org/debian stretch non-free" > /etc/apt/sources.list.d/debian-non-free.list && apt-get update -y  && apt-get install -y supervisor apt-utils wget curl ca-certificates sudo cron apt-transport-https lsb-release rsync ssh unzip p7zip-rar gzip

# php
ENV PHP_VERSION 5.6
RUN wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list && \
	apt-get update -y && apt-get install -y php$PHP_VERSION-fpm php$PHP_VERSION-cli php$PHP_VERSION-mysqlnd php$PHP_VERSION-imagick php$PHP_VERSION-mcrypt php$PHP_VERSION-xml php$PHP_VERSION-json php$PHP_VERSION-gd php$PHP_VERSION-curl php$PHP_VERSION-mbstring php$PHP_VERSION-soap php$PHP_VERSION-tidy php$PHP_VERSION-bcmath php$PHP_VERSION-zip php-apcu php-igbinary php-redis libphp-predis make php-yaml php$PHP_VERSION-dev php-pear

RUN update-alternatives --set php /usr/bin/php$PHP_VERSION && \
	update-alternatives --set phar /usr/bin/phar$PHP_VERSION && \
	update-alternatives --set phar.phar /usr/bin/phar.phar$PHP_VERSION

RUN pecl -v install rar && \
	echo "; configuration for php zip module" > /etc/php/$PHP_VERSION/mods-available/rar.ini && \
	echo "; priority=20" >> /etc/php/$PHP_VERSION/mods-available/rar.ini && \
	echo "extension=rar.so" >> /etc/php/$PHP_VERSION/mods-available/rar.ini && \
    phpenmod -v $PHP_VERSION rar
   
RUN phpenmod -v $PHP_VERSION yaml
       
# mysql
RUN apt-get install -y mysql-client

# install php zend guard loader 
RUN mkdir -p /tmp/zendguardloader && \
	cd /tmp/zendguardloader && \
	wget http://downloads.zend.com/guard/7.0.0/zend-loader-php5.6-linux-x86_64.tar.gz && \
	tar xvf zend-loader-php5.6-linux-x86_64.tar.gz && \
	cd `php5.6 -i | grep extension_dir | cut -d' ' -f 5` && \
	cp /tmp/zendguardloader/zend-loader-php5.6-linux-x86_64/ZendGuardLoader.so . && \
	cp /tmp/zendguardloader/zend-loader-php5.6-linux-x86_64/opcache.so . && \
	echo "zend_extension=ZendGuardLoader.so" > /etc/php/$PHP_VERSION/mods-available/zendguardloader.ini && \
	echo "zend_loader.enable=1" >> /etc/php/$PHP_VERSION/mods-available/zendguardloader.ini && \
	echo "zend_loader.disable_licensing=1" >> /etc/php/$PHP_VERSION/mods-available/zendguardloader.ini && \
	echo "zend_optimizer.optimization_level=15" >> /etc/php/$PHP_VERSION/mods-available/zendguardloader.ini && \
	echo zend_extension=opcache.so > /etc/php/$PHP_VERSION/mods-available/zendopcache.ini && \
	rm -rf /tmp/zendguardloader && \
	phpdismod opcache && \
	phpenmod -v $PHP_VERSION zendguardloader && \
	phpenmod -v $PHP_VERSION zendopcache

# install php ioncube 
RUN mkdir -p /tmp/ioncube && \
	cd /tmp/ioncube && \
	wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz && \
	tar xvf ioncube_loaders_lin_x86-64.tar.gz && \
	cd `php5.6 -i | grep extension_dir | cut -d' ' -f 5` && \
	cp /tmp/ioncube/ioncube/ioncube_loader_lin_5.6.so . && \
	echo "zend_extension=ioncube_loader_lin_5.6.so" > /etc/php/$PHP_VERSION/mods-available/ioncube.ini && \
	rm -rf /tmp/ioncube && \
	phpenmod -v $PHP_VERSION ioncube

# configure php5-fpm 
ADD php-fpm/www.conf /etc/php/$PHP_VERSION/fpm/pool.d/www.conf
RUN mkdir -p -m ugo+w /var/run/php
RUN mkdir -p -m ugo+w /var/log/php
RUN sed -i "s|<PHP_VERSION>|$PHP_VERSION|g" /etc/php/$PHP_VERSION/fpm/pool.d/www.conf

# install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

COPY supervisor/ /etc/supervisor/
RUN sed -i "s|<PHP_VERSION>|$PHP_VERSION|g" /etc/supervisor/conf.d/20-php-fpm.conf

VOLUME ["/var/log/php"]
VOLUME ["/docker-entrypoint-initoxid"]

# oxid tools
COPY ./docker-entrypoint.sh /
COPY tools/ /

RUN chmod +x /docker-entrypoint.sh /oxid-installer.sh /oxid-admin-tools.phar
 
ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/bin/supervisord"]