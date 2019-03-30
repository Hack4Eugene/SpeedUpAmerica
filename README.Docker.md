# Speed Up Your City

## Setup

These instructions work on Linux, Windows and MacOS. The setup instructions only need to be performed once, unless you reset your database or config files. 

Install [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker Compose](https://docs.docker.com/compose/install/). 

> Depending on your OS, you will have to make sure to use `copy` instead of `cp`.

    $ cp local.env.template local.env
    $ docker-compose up -d mysql
    $ docker-compose run frontend rake db:setup
    $ docker-compose run frontend rake secret

Use the ouput from `rake secret` as the value for `SECRET_KEY_BASE` in your `local.env`. Go to [Mapbox](https://account.mapbox.com) and create an account. Set `MAPBOX_API_KEY` to the public token or make a new token.

> These instructions assume Windows users are not using the WSL, which has documented problems with Docker's bind mounts. Installing and configuring Docker to work with the WSL is outside the scope of this document. 

## Running

    $ docker-compose up -d

The site can be accessed at `http://localhost:3000/`. The Ruby app is configured to not cache and it doesn't require restarting the Docker container to load changes, unless it's a config change. Just make your changes and reload the page. First page load make take a little bit. See `docker-compose logs frontend` for stdout/stderr.

## Stopping 

    $ docker-compose stop


