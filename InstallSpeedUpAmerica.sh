#!/bin/sh
cp local.env.template local.env
docker-compose up -d mysql
docker-compose run frontend rake db:setup
docker-compose exec -T mysql mysql -u suyc -psuyc suyc < db/submissions.sql
docker-compose exec -T mysql mysql -u suyc -psuyc suyc < db/zip_codes.sql
docker-compose exec -T mysql mysql -u suyc -psuyc suyc < db/census_tracts.sql
docker-compose run frontend rake secret
