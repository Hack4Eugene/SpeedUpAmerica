# Speed Up America

The project vision is an open source nation-wide map that pulls individual internet speed test data from [M-Lab](https://viz.measurementlab.net/location/nauskylouisville?isps=AS10796x_AS10774x_AS11486x) and breaking down the results on maps and charts by points, census blocks, ISP, date range, and speed.  Census block data and [FCC 477](https://www.fcc.gov/general/broadband-deployment-data-fcc-form-477) data will used to supplement both the analysis and maps.

The current implementation of SpeedUp has been deployed to these cities.

- [Lane County](https://speedupamerica.com/)
- [Louisville, KY](https://www.speeduplouisville.com/)
- [San Jose, CA](https://www.speedupsanjose.com/all-results)
- Montgomery County, MD

## Digital Inclusion

The project can be used as part of a digital inclusion strategy to learn where inequities are in your community.  SpeedUp can help citizens, businesses, policymakers and others better understand where Americans can access high-quality Internet service, and where there are needs, allowing cities to track and improve performance through key policies, ISP agreements, and partnerships.

### Replace FCC 477 Data

All current digital inclusion maps rely on [FCC 477](https://www.fcc.gov/general/broadband-deployment-data-fcc-form-477) data which is ISP self-reported, notoriously incomplete, misleading, gameable by ISPs, and not detailed enough.  Let's get better, more accurate, crowd-source speed data directly from citizens to make better decisions and drive policy.

## Project History

In April 2016, Louisville Metro Government’s OPI2 Innovation Team,  PowerUp Labs and other partners launched a web-based application aimed to increase transparency about Internet service quality in Louisville at a hackathon. Louisville worked partners to open source "SpeedUp" so that any local government or organization can launch this application for their community.

The application, SpeedUpYourCity.com, the local deployment of "SpeedUp", collects and publicly shares user-generated information about local broadband service speeds, rates and service quality in Louisville. It also incorporates the Measurement Lab Test, which is integrated with Google.com, and greatly increases the number of tests that the application collects.

## Articles and Write-Ups

- [Harvard Ash Center](https://datasmart.ash.harvard.edu/news/article/louisville-leverages-crowdsourcing-for-civic-good-919)
- [San Jose Blog](https://medium.com/@SJ_DigitalDolan/broadband-and-digital-inclusion-in-san-jose-c225d54b2ed1)
- [San Jose Page](https://www.sanjoseca.gov/index.aspx?NID=5346)
- [NPR Affiliate](https://wfpl.org/louisville-city-internet-speed-map/)
- [PowerUp Labs](https://poweruplabs.co/introducing-speed-up-louisville/) - How it Works
- [Sales Site](https://www.speedupyourcity.com/) - not being sold any more, now open source

## About the Speed Test and the Data

The data is displayed on an interactive map and available for free download, with the goal of increasing transparency about Internet service quality in America and to continue the conversation around fiber in your community.
Citizens can visit the site from any device to take the free Internet service test, and is supplemented by Google's M-Lab tests. The data provided by the test and short survey is stored in a publicly available database, combined with other results, and published to the online map in a form that does not identify contributors, and allows direct raw data download.

This test does not collect information about personal Internet traffic such as emails, web searches, or other personally identifiable information. 

## About the Original Developers

The SpeedUpLouisville.com project started at a local civic hackathon led by the Civic Data Alliance and hosted by Code Louisville and Code for America. Eric Littleton, Jon Matar and the PowerUp Labs software development team later volunteered to continue the work started during the hackathon. LVL1, a local makerspace, also provided funding for the paid web tools required to complete the project.

# Deployment & Operation

The SpeedUpAmerica project utilizes the following technologies for operation:

- Ruby on Rails
- MySQL
- MapBox (API Key Required)
- Map Technica (API Key Required)
- MLab (Special configuration instructions)

# Setup

These instructions work on Linux, Windows and MacOS and only need to be performed once, unless you reset your database or config files.

Install [Git](https://git-scm.com/downloads) Windows/Mac/Linux

Install [Docker](https://docs.docker.com/install/#supported-platforms) and [Docker Compose](https://docs.docker.com/compose/install/).

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

Use the output from `rake secret` as the value for `SECRET_KEY_BASE` in your `local.env`. Go to [Mapbox](https://account.mapbox.com) and create an account. Set `MAPBOX_API_KEY` to the public token or a new token.

If you want a basic dataset to work with run:

```bash
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/zip_codes.sql
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/census_tracts.sql
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/submissions.sql
$ docker-compose run frontend rake update_providers_statistics
$ docker-compose run frontend rake update_stats_cache
```

> These instructions assume Windows users are not using the WSL, which has documented problems with Docker's bind mounts. Installing and configuring Docker for Windows to work with the WSL is outside the scope of this document.

## Running

```bash
$ docker-compose up -d
```

The site can be accessed at `http://localhost:3000/`. The Ruby app is configured to not cache and it doesn't require restarting the Docker container to load changes, unless it's a config change. Just make your changes and reload the page. First page load make take a little bit. See `docker-compose logs frontend` for stdout/stderr.

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

If `docker-compose ps` shows "Exit 1" for any process, one likely cause is that the process's Docker image needs to be rebuilt. This is generally due to dependencies having changed since the last time you built the image. An additional hint that this is the cause is if the logs show errors indicating that a dependency could not be found.

To resolve this, rebuild the Docker image for that specific process. For example, if the `frontend` process exited with an error status:

```bash
$ docker-compose up --build frontend
```

If `docker-compose ps` continues to throw an "Exit 1" error for any process after rebuilding the frontend, please ensure that your machines firewall permissions allow the applications. After you set your firewall permissions, you will need to close your workflow, restart docker, and restart the app.

### Running Docker on Ubuntu
Installation on [Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/).

Running the environment locally on a Linux-based OS could require running `docker-compose` commands as super user, `sudo docker-compose [commands]`.

[Here is a guide for managing Docker as a non-root user](https://docs.docker.com/install/linux/linux-postinstall/).

# Data tasks

There are just the tasks that have been run to populate and prepare the data for operation. The other tasks need investigated and documented.

### Importing M-Lab submissions:

```bash
$ docker-compose run frontend rake import_mlab_submissions
```

### Populating submissions with Census Tract

```bash
$ docker-compose run frontend rake update_pending_census_codes
```

### Updating provider statistics

```bash
$ docker-compose run frontend rake update_providers_statistics
```

### Updating cached data 

```
$ docker-compose run frontend rake update_stats_cache
```

## Updating boundaries

When boundaries are updated each developer must reload their boundary tables:
```bash
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc <<< "TRUNCATE census_boundaries;"
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc <<< "TRUNCATE zip_boundaries;"
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/zip_codes.sql
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/census_tracts.sql
```

>For Windows OS please use the following:
```bash
$ docker-compose exec mysql mysql -u suyc -psuyc suyc
$ mysql> TRUNCATE census_boundaries;
$ mysql> TRUNCATE zip_boundaries;
$ mysql> exit
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/zip_codes.sql
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc < data/census_tracts.sql
```

### Importing Census and Zip Code boundaries

Assumes you have these files in `data/`:
* https://s3-us-west-2.amazonaws.com/sua-datafiles/cb_2016_us_census_tracts
* https://s3-us-west-2.amazonaws.com/sua-datafiles/us_zip_codes.json

```bash 
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc <<< "TRUNCATE census_boundaries;"
$ docker-compose exec -T mysql mysql -u suyc -psuyc suyc <<< "TRUNCATE zip_boundaries;"
$ docker-compose run frontend rake populate_census_tracts
$ docker-compose run frontend rake populate_zip_boundaries
```

Once imported you can update the SQL files by:
```bash
$ docker-compose exec mysql mysqldump --no-create-info -u suyc -psuyc suyc census_boundaries > data/census_tracts.sql
$ docker-compose exec mysql mysqldump --no-create-info -u suyc -psuyc suyc zip_boundaries > data/zip_codes.sql
```

### Creating new submissions.sql

```bash
$ docker-compose exec mysql mysqldump --no-create-info -u suyc -psuyc suyc submissions > data/submissions.sql
```

### Creating test data

> This should only be used to test newly loaded boundaries.

After loading boundaries and submissions you can distribute the submissions across all Zip Codes and Census Tracts by running:

```bash
$ docker-compose run frontend rake create_test_data
```

# Governance and contribution

See [CONTRIBUTING.md](CONTRIBUTING.md).

Committers:

* Diego Kourchenko
* Noah Brenner
* Kirk Hutchison
* Bishop Lafer
* Cory Borman

Technical Committee:

* Matt Sayre
* Chris Ritzo
* Chris Sjoblom
* Antonio Ortega
* Ryan Olds
