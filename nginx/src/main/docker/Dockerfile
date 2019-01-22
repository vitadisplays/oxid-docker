FROM vitadisplays/oxid-eshop-server-base:php5.6

ENV PHP_VERSION=5.6

# nginx
ENV OXID_SHOP_HOME /srv/www/oxid

ARG SGNGX_VERSION 
ENV SGNGX_VERSION ${SGNGX_VERSION:-jj_nginx_pagespeed_unknown} 
ARG INSTALL_NGINX_VERSION 
ENV INSTALL_NGINX_VERSION ${INSTALL_NGINX_VERSION:-1.14.2} 
ARG INSTALL_PAGESPEED_VERSION 
ENV INSTALL_PAGESPEED_VERSION ${INSTALL_PAGESPEED_VERSION:-latest-stable} 

RUN apt-get update && apt-get upgrade -y 
ONBUILD RUN apt-get update && apt-get upgrade -y 
RUN apt-get install -y --no-install-recommends curl sudo build-essential zlib1g-dev libpcre3 libpcre3-dev unzip wget libssl-dev ca-certificates git
RUN apt-get install -y optipng jpegoptim gifsicle

RUN echo "USING NGINX: ${INSTALL_NGINX_VERSION}" && \
      echo "USING PAGESPEED: ${INSTALL_PAGESPEED_VERSION}" && \
      echo "USING brotli: master" && \
      git clone --recursive https://github.com/google/ngx_brotli.git  && \
      curl -f -L -sS https://ngxpagespeed.com/install | tee install_ngxpagespeed.bash && \
      bash install_ngxpagespeed.bash \
      --assume-yes \
      --ngx-pagespeed-version ${INSTALL_PAGESPEED_VERSION} \
      --nginx-version ${INSTALL_NGINX_VERSION} \
      --dynamic-module \
      --additional-nginx-configure-arguments '\
        --add-module=/ngx_brotli \
        --with-http_ssl_module \
        --with-http_gzip_static_module \
        --with-file-aio \
        --with-http_v2_module \
        --with-http_stub_status_module \
        --with-http_realip_module \
        --without-http_autoindex_module \
        --without-http_browser_module \
        --without-http_memcached_module \
        --without-http_userid_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module \
        --without-http_split_clients_module \
        --without-http_scgi_module \
        --without-http_referer_module \
        --without-http_upstream_ip_hash_module \
        --prefix=/etc/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --http-log-path=/var/log/nginx/access.log \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx.pid \
        --sbin-path=/usr/sbin \
        --modules-path=/usr/lib/nginx \
      '
RUN apt-get remove -y --auto-remove build-essential git
RUN rm -Rf /nginx-*
RUN rm -Rf /ngx_pagespeed-*
RUN rm -Rf /ngx_brotli*
	
#RUN adduser --system --no-create-home --disabled-login --disabled-password --group nginx

RUN mkdir -p /etc/nginx/sites-available && \
	mkdir -p /etc/nginx/sites-enabled && \
	mkdir -p /etc/nginx/modules-available && \
	mkdir -p /etc/nginx/modules-enabled && \
	mkdir -p /etc/nginx/conf.d && \
	mkdir -p /etc/nginx/common && \
	mkdir -p /etc/nginx/ssl && \
    ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    mkdir -p /var/cache/ngx_pagespeed

RUN echo "load_module "/usr/lib/nginx/ngx_pagespeed.so";" > /etc/nginx/modules-available/pagespeed.conf

RUN openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/nginx/ssl/oxid.key -out /etc/nginx/ssl/oxid.crt -subj "/C=DE/ST=Niedersachsen/L=Doeverden/O=VITAdisplays International Holding GmbH/OU=IT Department/CN=localhost"
RUN openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

COPY nginx/ /etc/nginx/
COPY pagespeed/ /etc/nginx/

RUN sed -i "s|<PHP_VERSION>|$PHP_VERSION|g" /etc/nginx/sites-available/oxid.conf && \
	sed -i "s|<ROOT_DIR>|$OXID_SHOP_HOME|g" /etc/nginx/sites-available/oxid.conf && \
	sed -i "s|<REDIS_PASSWORD>|$REDIS_PASSWORD|g" /etc/nginx/conf.d/pagespeed.conf && \
	rm -f /etc/nginx/sites-enabled/* && \
	ln -s /etc/nginx/sites-available/oxid.conf /etc/nginx/sites-enabled/ && \
	ln -s /etc/nginx/modules-available/pagespeed.conf /etc/nginx/modules-enabled/
	
RUN chown -R www-data:www-data /var/cache/ngx_pagespeed && \
    chown -R root:www-data /etc/nginx/* && \
    find /etc/nginx -type d -exec chmod g+rx,g-w,o-rwx {} \; && \
    find /etc/nginx -type f -exec chmod g+r,g-wx,o-rwx {} \;
    
COPY supervisor/ /etc/supervisor/

VOLUME ["/srv/www/oxid"]
VOLUME ["/etc/nginx/sites-enabled"]
VOLUME ["/etc/nginx/ssl"]

EXPOSE 80
EXPOSE 443