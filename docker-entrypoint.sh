#!/bin/sh
set -e
mkdir -p tmp
if [ -f tmp/pids/server.pid ]; then
    rm tmp/pids/server.pid
fi
if [ ! -f "tmp/init_db_for_$POSTGRES_DB" ]; then
    bundle exec rake db:migrate
    bundle exec rake db:seed
    touch "tmp/init_db_for_$POSTGRES_DB"
fi
if [ ! -d "node_modules" ]; then
    bun install
fi
if [ ! -d "app/assets/stylesheets" ]; then
    bin/rails tailwindcss:install
fi
exec "$@"
