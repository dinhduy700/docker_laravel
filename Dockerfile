# Stage 1: Build Node.js dependencies
FROM node:14 AS node-build

# Set working directory for Node.js
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Stage 2: Build PHP dependencies
FROM php:8.2-fpm-alpine AS php-build

# Install system dependencies
RUN apk update && apk add --no-cache \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    freetype-dev \
    libzip-dev \
    zip \
    bash \
    dos2unix \
    nodejs \
    npm

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_mysql \
    && docker-php-ext-install mysqli && docker-php-ext-enable mysqli \
    && docker-php-ext-install exif \
    && docker-php-ext-install zip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd

# Sync php.ini
COPY ./docker/php/php.ini /usr/local/etc/php/

# Set working directory for PHP
ARG workdir=/var/www
WORKDIR $workdir

# Copy application files
COPY . .

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

ENV COMPOSER_ALLOW_SUPERUSER=1
# Install PHP dependencies
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress

# Copy Node.js dependencies from the previous stage
COPY --from=node-build /app/node_modules ./node_modules

# Copy the docker-start.sh script from the local directory into the container
COPY docker-start.sh /var/www/docker-start.sh

# Set executable permission for docker-start.sh
RUN chmod +x /var/www/docker-start.sh

# Install MailDev
RUN npm install -g maildev

# Expose MailDev ports
EXPOSE 1081 1026

CMD ["/var/www/docker-start.sh"]
