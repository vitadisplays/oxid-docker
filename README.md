# oxid-docker

oxid docker images to run oxid-eshop systems on several enviornments.

- base image
  - php-fpm
  - php composer
  - zend guard loader
  - ioncube loader
  - image optimization libs (optipng, jpegoptim, gifsicle)
  - provisioning tools for oxid
- nginx image
  - nginx http server
  - nginx brotli support
  - nginx pagespeeg support
  - ssl + dhparam support
- nginx-dev image
  - nginx http server with xdebug
