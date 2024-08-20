#!/bin/bash
# composer install --no-dev --prefer-dist --no-interaction --no-progress

php /var/www/artisan key:generate
php /var/www/artisan migrate
#php /var/www/artisan queue:listen --timeout=0 &

php-fpm

# Start MailDev
maildev --web 1081 --smtp 1026 &

# Keep the container running
tail -f /dev/null