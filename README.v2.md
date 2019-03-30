# Speed Up Your City

## Setup

Install [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker Compose](https://docs.docker.com/compose/install/). 

    $ cp local.env.template local.env
    $ docker-compose up -d mysql
    $ docker-compose run frontend rake db:setup
    $ docker-compose run frontend rake secret

Use the ouput from `rake secret` as the value for `SECRET_KEY_BASE` in `local.env`. Go to [Mapbox](https://account.mapbox.com) and create an account. Set `MAPBOX_API_KEY` to the public token or make a new token.

## Running

    $ docker-compose up -d

The site can be accessed at `http://localhost:3000/`

## Stopping 

    $ docker-compose stop

