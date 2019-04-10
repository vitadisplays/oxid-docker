FROM vitadisplays/oxid-eshop-server-nginx:php5.6

ENV PHP_VERSION=5.6

# configure xdebug

RUN apt-get update && apt-get upgrade -y 
ONBUILD RUN apt-get update && apt-get upgrade -y 
RUN apt-get install -y php-xdebug && \
    echo "zend_extension=xdebug.so" > /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_enable=on" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_autostart=off" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_handler=dbgp" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.remote_port=9000" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.show_local_vars=1" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.var_display_max_depth=-1" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.var_display_max_children=-1" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.var_display_max_data=-1 " >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.profiler_enable=on" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.profiler_enable_trigger=on" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
    echo "xdebug.profiler_output_dir=/var/log/php/$PHP_VERSION/profiler" >> /etc/php/$PHP_VERSION/mods-available/xdebug.ini && \
	phpenmod -v $PHP_VERSION xdebug
	
RUN mkdir -p -m ugo+w /var/log/php/$PHP_VERSION/profiler

EXPOSE 9000