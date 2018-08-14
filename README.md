# Speed Up Your City

The project vision is an open source nation-wide map that pulls individual internet speed test data from [M-Lab](https://viz.measurementlab.net/location/nauskylouisville?isps=AS10796x_AS10774x_AS11486x) and breaking down the results on maps and charts by points, census blocks, ISP, date range, and speed.  Census block data and [FCC 477](https://www.fcc.gov/general/broadband-deployment-data-fcc-form-477) data will used to supplement both the analysis and maps.

The current implentation of SpeedUp has been deployed to these cities.

- [Louisville, KY](https://www.speeduplouisville.com/)
- [San Jose, CA](https://www.speedupsanjose.com/all-results)
- Montgomery County, MD

## Digital Inclusion

The project can be used as part of a digital inclusion strategy to learn where inequities are in your community.  SpeedUp can help citizens, businesses, policymakers and others better understand where Louisville residents can access high-quality Internet service, and where there are needs, allowing cities to track and improve performance through key policies, ISP agreements, and partnerships.

### Replace FCC 477 Data

All current digital inclusion maps rely on [FCC 477](https://www.fcc.gov/general/broadband-deployment-data-fcc-form-477) data which is ISP self-reported, notriously incomplete, misleading, gameable by ISPs, and not detailed enough.  Let's get better, more accurate, crowd-source speed data directly from citizens to make better decisions and drive policy.

## Project History

In April 2016, Louisville Metro Government’s OPI2 Innovation Team,  PowerUp Labs and other partners launched a web-based application aimed to increase transparency about Internet service quality in Louisville at a hackathon. Louisville worked partners to open source "SpeedUp" so that any local government or organization can launch this application for their community.

The application, SpeedUpLouisville.com, the local deployment of "SpeedUp", collects and publicly shares user-generated information about local broadband service speeds, rates and service quality in Louisville. It also incorporates the Measurement Lab Test, which is integrated with Google.com, and greatly increases the number of tests that the application collects.

## Articles and Write-Ups

- [Harvard Ash Center](https://datasmart.ash.harvard.edu/news/article/louisville-leverages-crowdsourcing-for-civic-good-919)
- [San Jose Blog](https://medium.com/@SJ_DigitalDolan/broadband-and-digital-inclusion-in-san-jose-c225d54b2ed1)
- [San Jose Page](http://www.sanjoseca.gov/index.aspx?NID=5346)
- [NPR Affiliate](http://wfpl.org/louisville-city-internet-speed-map/)
- [PowerUp Labs](http://poweruplabs.co/introducing-speed-up-louisville/) - How it Works
- [Sales Site](http://www.speedupyourcity.com/) - not being sold any more, now open source

## About the Speed Test and the Data

The data is displayed on an interactive map and available for free download, with the goal of increasing transparency about Internet service quality in Louisville and to continue the conversation around fiber in your community.
Citizens can visit the site from any device to take the free Internet service test, and is supplemented by Google's M-Lab tests. The data provided by the test and short survey is stored in a publicly available database, combined with other results, and published to the online map in a form that does not identify contributors, and allows direct raw data download.

This test does not collect information about personal Internet traffic such as emails, web searches, or other personally identifiable information. 

## About the Original Developers

The SpeedUpLouisville.com  project started at a local civic hackathon led by the Civic Data Alliance and hosted by Code Louisville and Code for America. Eric Littleton, Jon Matar and the PowerUp Labs software development team later volunteered to continue the work started during the hackathon. LVL1, a local makerspace, also provided funding for the paid web tools required to complete the project.

# Deployment & Operation

The SpeedUpYourCity project utilizes the following technologies for operation:

- Ruby on Rails
- MySQL
- MapBox (API Key Required)
- Map Technica (API Key Required)
- MLab (Special configuration instructions)

### Install & Configure Web Server
We utilize Puma with this project, although it was tested locally with Passenger.

### Install & Configure MySQL

### Bundle Install

### Configure Environment Variables (local environment)

Open and rename the .env_sample file to .env, and configure the listed options. By default, this application is set to "development" mode. 

~~~~
# MLab's Big Query Configuration #
##################################
MLAB_BIGQUERY_DATASET:
MLAB_BIGQUERY_EMAIL:
MLAB_BIGQUERY_PRIVATE_KEY:
MLAB_BIGQUERY_PRIVATE_KEY_PASSPHRASE:
MLAB_BIGQUERY_AUTH_METHOD:

# General Configuration #
#########################
LANG=en_US.UTF-8
RAILS_SERVE_STATIC_FILES=
SECRET_KEY_BASE=
SECRET_TOKEN=

# 3rd party API integrations #
##############################
MAPBOX_API_KEY=
MAPTECHNICA_API_KEY=

# Environment Configuration #
#############################
RACK_ENV=development
RAILS_ENV=development

# Development Environment Variables #
#####################################
RDS_DEV_DB_NAME=
RDS_DEV_HOSTNAME=
RDS_DEV_PASSWORD=
RDS_DEV_PORT=
RDS_DEV_USERNAME=

# Staging Environment Variables #
####################################
RDS_DB_NAME=
RDS_HOSTNAME=
RDS_PASSWORD=
RDS_PORT=
RDS_USERNAME=

# Production Environment Variables #
####################################
RDS_DB_NAME=
RDS_HOSTNAME=
RDS_PASSWORD=
RDS_PORT=
RDS_USERNAME=
~~~~

### Seed Database
rake db:setup

### Migrate Database Changes
rake db:migrate:status  
rake db:migrate                         # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)

### Run Local (optional)
rails s

### Familiarize yourself with rake tasks
Run "rake -t" to get the following output of rake tasks:

~~~~
rake about                              # List versions of all Rails frameworks and the environment
rake assets:clean[keep]                 # Remove old compiled assets
rake assets:clobber                     # Remove compiled assets
rake assets:environment                 # Load asset compile environment
rake assets:precompile                  # Compile all the assets named in config.assets.precompile / Create nondigest versions of all chosen digest assets
rake cache_digests:dependencies         # Lookup first-level dependencies for TEMPLATE (like messages/show or comments/_comment.html)
rake cache_digests:nested_dependencies  # Lookup nested dependencies for TEMPLATE (like messages/show or comments/_comment.html)
rake db:create                          # Creates the database from DATABASE_URL or config/database.yml for the current RAILS_ENV (use db:create:all to create...
rake db:drop                            # Drops the database from DATABASE_URL or config/database.yml for the current RAILS_ENV (use db:drop:all to drop all d...
rake db:fixtures:load                   # Load fixtures into the current environment's database
rake db:migrate                         # Migrate the database (options: VERSION=x, VERBOSE=false, SCOPE=blog)
rake db:migrate:status                  # Display status of migrations
rake db:rollback                        # Rolls the schema back to the previous version (specify steps w/ STEP=n)
rake db:schema:cache:clear              # Clear a db/schema_cache.dump file
rake db:schema:cache:dump               # Create a db/schema_cache.dump file
rake db:schema:dump                     # Create a db/schema.rb file that is portable against any DB supported by AR
rake db:schema:load                     # Load a schema.rb file into the database
rake db:seed                            # Load the seed data from db/seeds.rb
rake db:setup                           # Create the database, load the schema, and initialize with the seed data (use db:reset to also drop the database first)
rake db:structure:dump                  # Dump the database structure to db/structure.sql
rake db:structure:load                  # Recreate the databases from the structure.sql file
rake db:version                         # Retrieves the current schema version number
rake doc:app                            # Generate docs for the app -- also available doc:rails, doc:guides (options: TEMPLATE=/rdoc-template.rb, TITLE="Custo...
rake geocode:all                        # Geocode all objects without coordinates
rake geocoder:maxmind:geolite:download  # Download MaxMind GeoLite City data
rake geocoder:maxmind:geolite:extract   # Extract (unzip) MaxMind GeoLite City data
rake geocoder:maxmind:geolite:insert    # Load/refresh MaxMind GeoLite City data
rake geocoder:maxmind:geolite:load      # Download and load/refresh MaxMind GeoLite City data
rake log:clear                          # Truncates all *.log files in log/ to zero bytes (specify which logs with LOGS=test,development)
rake middleware                         # Prints out your Rack middleware stack
rake notes                              # Enumerate all annotations (use notes:optimize, :fixme, :todo for focus)
rake notes:custom                       # Enumerate a custom annotation, specify with ANNOTATION=CUSTOM
rake rails:template                     # Applies the template supplied by LOCATION=(/path/to/template) or URL
rake rails:update                       # Update configs and some other initially generated files (or use just update:configs or update:bin)
rake routes                             # Print out all defined routes in match order, with names
rake secret                             # Generate a cryptographically secure secret key (this is typically used to generate a secret for cookie sessions)
rake stats                              # Report code statistics (KLOCs, etc) from the application or engine
rake test                               # Runs all tests in test folder
rake test:all                           # Run tests quickly by merging all types and not resetting db
rake test:all:db                        # Run tests quickly, but also reset db
rake test:db                            # Run tests quickly, but also reset db
rake time:zones:all                     # Displays all time zones, also available: time:zones:us, time:zones:local -- filter with OFFSET parameter, e.g., OFFS...
rake tmp:clear                          # Clear session, cache, and socket files from tmp/ (narrow w/ tmp:sessions:clear, tmp:cache:clear, tmp:sockets:clear)
rake tmp:create                         # Creates tmp directories for sessions, cache, sockets, and pids
~~~~

### Push to Web Based Development Environment
This stage of implementation is dependent on what environment you will be deploying to. We currently have 3 methods that we're testing, with Heroku and dedicated hosting being operational.

## Heroku
This implementation of Speed Up Your City has been tested on Heroku, on a free dyno, with a small MySQL instance add-on ($9.99 a month, only recommend for testing purposes)

## Elastic Beanstalk
This project currently does not run on Elastic Beanstalk, although we do intend to implement this. There is a placeholder .ebextensions folder in preparation for this. This would utilize Elastic Beanstalk, in conjunction with a small to medium EC2 instance, and a MySQL RDS instance.

## Dedicated Hosting
Speeduplouisville.com is currently running on a dedicated server hosted by Smart Data Systems.
