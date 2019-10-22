# Speed Up America

SpeedUpAmerica provides on-the-ground truth about the Internet in America. Our national and localized broadband maps provide transparency: real Internet speeds received, actual prices paid, and level of service experienced. This information helps guide public and private investments in Internet infrastructure to the places that need it the most. We also see this approach as a better solution to national broadband mapping than that currently used by the FCC.

If you are a software developer, [we would love your help and we can pay you for your time](https://github.com/Hack4Eugene/SpeedUpAmerica/wiki)!

It is easy to speculate about what areas of a community have slow internet access, but without the data, it’s nearly impossible to know who is getting good, reliable service and where opportunities exist for improvement. Accurate information on the availability of Internet Service Providers, actual prices paid, and real speeds received is very hard to come by. There is a lack of real data and information about underserved areas. This is where communities in Oregon and throughout the nation need help.

In partnership with US Ignite, this effort works to advance the technology that was originally built in Louisville Kentucky that helped that city’s digital inclusion efforts, and make it available to all cities and rural communities across America.

The envisioned solution combines crowdsourced internet speed test results with a map of the entire United States that is filterable by state, zip code, census tract, cencus block and other statistical boundaries.

In the end, we believe this tool will give us the most accurate on-the-ground data about what is actually happening in terms of Internet connectivity across America. And, it can serve as a starting point for conversations between neighbors, elected officials, and Internet service providers.

The goal of this project is to increase awareness of inequities in speed and quality of internet provided to everyone in the US. If you have questions about anything, please join the conversation.

Welcome!

_The current implementation of SpeedUpAmerica has scaled to cover the state of Oregon in June 2019. Washington and Idaho were added in July 2019. State and county boundaries are being added sometime during August 2019._

## Digital Inclusion

The project can be used as part of a digital inclusion strategy to learn where inequities are in your community.  SpeedUpAmerica can help citizens, businesses, policymakers and others better understand where Americans can access high-quality Internet service, and where there are needs, allowing cities to track and improve performance through key policies, ISP agreements, and partnerships.

### Replace FCC 477 Data

All current digital inclusion maps rely on [FCC 477](https://www.fcc.gov/general/broadband-deployment-data-fcc-form-477) data which is ISP self-reported, notoriously incomplete, misleading, gameable by ISPs, and not detailed enough.  Let's get better, more accurate, crowd-source speed data directly from citizens to make better decisions and drive policy.

## Project History

In March 2019, [Louisville worked with the tech community in Eugene, Oregon and Hack for a Cause](https://medium.com/louisville-metro-opi2/the-pathway-forward-for-mapping-broadband-speeds-in-america-da7df35320c2) to develop a codebase that could scale to be a single unified national map.

This new application, SpeedUpAmerica.com, collects and publicly shares crowd sourced information about local broadband service speeds, prices paid, and quality of service all across america. It also incorporates the TestIT tests and Measurement Lab tests (which is integrated with Google.com) and greatly increases the number of tests that the application collects.

In April 2016, Louisville Metro Government’s OPI2 Innovation Team,  PowerUp Labs and other partners launched a web-based application aimed to increase transparency about Internet service quality in Louisville at a hackathon. Louisville worked partners to open source "SpeedUp" so that any local government or organization can launch this application for their community.

The SpeedUpLouisville.com project oreginally started at a local civic hackathon led by the Civic Data Alliance and hosted by Code Louisville and Code for America. Eric Littleton, Jon Matar and the PowerUp Labs software development team later volunteered to continue the work started during the hackathon. LVL1, a local makerspace, also provided funding for the paid web tools required to complete the project.

## Articles and Write-Ups

- [US Ignite](https://www.us-ignite.org/speed-up-america-building-a-better-broadband-map/)
- [CBS News](https://kval.com/news/local/how-fast-is-internet-service-in-rural-oregon-speed-up-america-aims-to-find-out)
- [Converge Network Digest](https://www.convergedigest.com/2019/06/speed-up-america-seeks-better-data-on.html)
- [The Register-Guard](https://www.registerguard.com/news/20190616/lane-county-asking-broadband-users-to-help-speed-up-america)

## About the Speed Test and the Data

The data is displayed on an interactive map and available for free download, with the goal of increasing transparency about Internet service quality in America and to continue the conversation around internet access in your community.
Citizens can visit the site from any device to take the free Internet service test, and is supplemented by Google's M-Lab tests. The data provided by the test and short survey is stored in a publicly available database, combined with other results, and published to the online map in a form that does not identify contributors, and allows direct raw data download.

This test does not collect information about personal Internet traffic such as emails, web searches, or other personally identifiable information. 

# Deployment & Operation

The SpeedUpAmerica project utilizes the following technologies for operation:

- Ruby on Rails
- MySQL
- MapBox (API Key Required)
- MLab (Special configuration instructions)

# Setup

These instructions work on Linux, Windows and MacOS and only need to be performed once, unless you reset your database or config files.

Install [Git](https://git-scm.com/downloads) Windows/Mac/Linux

Install [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker Compose](https://docs.docker.com/compose/install/) (Docker Compose is already included with Mac and Windows Docker installs, but not Linux. Please also note the Win Home install differs from Pro).

> A minimum of 6GB of local memory allocation is needed. After starting Docker, go into it's settings and adjust the amount of memory it's allowed to use.
>
> [Memory - Docker Desktop for Mac](https://docs.docker.com/docker-for-mac/#memory)
>
> [Memory - Docker Desktop for Windows](https://docs.docker.com/docker-for-windows/)

> Depending on your OS, you may have to make sure to use `copy` instead of `cp`.

```bash
$ git clone https://github.com/Hack4Eugene/SpeedUpAmerica.git
$ git clone https://github.com/Hack4Eugene/speedupamerica-migrator.git
$ cd SpeedUpAmerica
$ cp local.env.template local.env
$ docker-compose up -d mysql
$ docker-compose up --build migrator
$ docker-compose run migrator rake db:seed
$ docker-compose run frontend rake secret
```

Locate your `local.env` in the root of the SpeedUpAmerica directory which now resides on your local system.
Use the long alphanermeric string output from `rake secret` as the value for `SECRET_KEY_BASE`.
Go to [Mapbox](https://account.mapbox.com) and create a free account, to get a mapbox api access token.
Use and set the Default pulic token as your `MAPBOX_API_KEY` in the `local.env`file.

> These instructions assume Windows users are not using the WSL, which has documented problems with Docker's bind mounts. Installing and configuring Docker for Windows to work with the WSL is outside the scope of this document.

## Load a dataset

Download one of the two SQL files and place it in the projects `data` directory:

* https://sua-datafiles.s3-us-west-2.amazonaws.com/sua_lane_20190915.sql - Lane County (121MB)
* https://sua-datafiles.s3-us-west-2.amazonaws.com/sua_20190803.sql - OR, WA, ID (4.3GB, requires Docker being allocated 8GB RAM and an SSD is recommended)

> Contributors: If you update any of these files, make sure to change the filename and
> update all references in this document.

Replace the filename and run this line:

```bash
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/<SQL filename>
```

## Running

```bash
$ docker-compose up -d
```

The site can be accessed at `http://localhost:3000/`. The Ruby app is configured to not cache and it doesn't require restarting the Docker container to load changes, unless it's a config change. Just make your changes and reload the page. First page load make take a little bit. See `docker-compose logs frontend` for stdout/stderr.

### Notebooks

The `docker-compose.yml` includes a Jupyter Hub container based on `jupyter/datascience-notebook`. It includes some addition Python modules for working with MySQL, and Mapbox. After setting up the database and loading a dataset you can start Jupyter Hub by running `docker-compose up notebooks`. Once ready it will output a URL and token that you will need to use to access the Jypyter Hub in your browser. Notebooks and other files are saved in `./notebooks`, make sure to check in and PR new/updated notebooks.

## Stopping

```bash
$ docker-compose stop
```

# Troubleshooting

If the site doesn't load correctly on localhost after pulling in new changes from git and restarting Docker, try the following:

```bash
# Show the docker tasks and their exit statuses
$ docker-compose ps

# You might also be interested in seeing the logs for a failing process
# Choose the option below for the process you're interested in:
$ docker-compose logs frontend
$ docker-compose logs migrator
$ docker-compose logs mysql
```

## Frontend is exiting

If `docker-compose ps` shows "Exit 1" for any process, one likely cause is that the process's Docker image needs to be rebuilt. This is generally due to dependencies having changed since the last time you built the image. An additional hint that this is the cause is if the logs show errors indicating that a dependency could not be found.

To resolve this, rebuild the Docker image for that specific process. For example, if the `frontend` process exited with an error status:

```bash
$ docker-compose up --build frontend
```

If `docker-compose ps` continues to throw an "Exit 1" error for any process after rebuilding the frontend, please ensure that your machines firewall permissions allow the applications. After you set your firewall permissions, you will need to close your workflow, restart docker, and restart the app.

If after enabling your firewall persmissions you still have trouble with an "Exit 1", you may need to delete tmp/pids/server.pid and then `docker-compose up -d`

## Running Docker on Ubuntu
Installation on [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

Running the environment locally on a Linux-based OS could require running `docker-compose` commands as super user, `sudo docker-compose [commands]`.

[Here is a guide for managing Docker as a non-root user](https://docs.docker.com/install/linux/linux-postinstall/).

# Tasks contributors need to do occassionally

## Reload the database from most recent backup

> Assumes you have the recent `.sql` file downloaded from the setup instructions.

When boundaries are updated each developer must reload their boundaries. As new boundaries
can also require adding columns to the submissions table it's best to completely reload your
database.

```bash
$ docker-compose stop mysql
$ docker-compose rm mysql
$ docker-compose up mysql
$ docker-compose up --build migrator
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/sua_20190803.sql
```

## Creating database dump

> When updating the SQL files make sure to remove the warning from the first line of the file.

Make sure to replace `<date>` with todays date in a concise format (e.g. `20190801`).

```bash
$ docker-compose exec mysql mysqldump --no-create-info -u suyc -psuyc suyc --ignore-table=suyc.schema_migrations > data/sua_<date>.sql
```

## Updating your boundaries the long way

Follow the next three sections to download the latest data, clear your
boundaries tables, and load the data. You should only be following
these directions if deleting your DB and loading the lastest SQL dump is not
an option.

### Download boundary data files

Assumes you have these files in `data/`:
* https://s3-us-west-2.amazonaws.com/sua-datafiles/cb_2016_us_census_tracts
* https://s3-us-west-2.amazonaws.com/sua-datafiles/us_zip_codes.json
* https://s3-us-west-2.amazonaws.com/sua-datafiles/tl_2018_16_tabblock10.json
* https://s3-us-west-2.amazonaws.com/sua-datafiles/tl_2018_41_tabblock10.json
* https://s3-us-west-2.amazonaws.com/sua-datafiles/tl_2018_53_tabblock10.json
* https://s3-us-west-2.amazonaws.com/sua-datafiles/tl_2018_us_zcta510.json
* https://s3-us-west-2.amazonaws.com/sua-datafiles/tl_2018_us_county.json
* https://s3-us-west-2.amazonaws.com/sua-datafiles/tl_2018_us_state.json

### Empty your boundaries tables

For Linux and MacOS please use the following:

```bash
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc <<< "TRUNCATE zip_boundaries;"
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc <<< "TRUNCATE census_boundaries;"
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc <<< "TRUNCATE boundaries;"
```

For Windows OS please use the following:

```
$ docker-compose exec mysql mysql -u suyc -psuyc suyc
$ mysql> TRUNCATE census_boundaries;
$ mysql> TRUNCATE zip_boundaries;
$ mysql> TRUNCATE boundaries;
$ mysql> exit
```

### Load

```
$ docker-compose run frontend rake populate_zip_boundaries
$ docker-compose run frontend rake populate_census_tracts
$ docker-compose run frontend rake populate_boundaries
```

## Data import process

Each night the Test and Production environments run the data import process, which imports
recent M-Lab data, updates boundaries, recalcualtes the caches, and other data related tasks.

> Some steps of the nightly import process requires a BigQuery Service Key with access to the Measurement Lab data.

The nightly process is start by running `./update_data.sh`. On your local enviornment you can:

```bash
$ docker-compose run frontend ./update_data.sh
```

### Importing M-Lab submissions:

Requires a BigQuery Service Key with access to the Measurement Lab data.

```bash
$ docker-compose run frontend rake import_mlab_submissions
```

### Populating submissions with missing boundaries

```bash
$ docker-compose run frontend rake populate_missing_boundaries
```

### Updating provider statistics

```bash
$ docker-compose run frontend rake update_providers_statistics
```

### Updating cached data

```
$ docker-compose run frontend rake update_stats_cache
```

# Governance and contribution

See [CONTRIBUTING.md](CONTRIBUTING.md).

Committers:

* Diego Kourchenko
* Noah Brenner
* Kirk Hutchison
* Bishop Lafer
* Cory Borman
* James Coulter

Technical Committee:

* Matt Sayre
* Chris Ritzo
* Chris Sjoblom
* Antonio Ortega
* Ryan Olds
