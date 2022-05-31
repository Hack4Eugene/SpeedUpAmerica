# CHANGELOG
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and aims to adhere to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [6.3.6] - 2022-05-30

### Fixed

- oregon-es theme is now included in the stylesheets, it had been defaulting to generic regional style
- submit button was appearing too low for oregon-es region. This is fixed now.

### Changed

- Regional autocomplete is now using the Mapbox API instead of Algolia Places. Algolia was inaccurate and will soon be sunsetted as well.

### Added

- This changelog file. This application hasn't had a changelog or versions. Adding now, including the last several commits. This file can be added to retractively based on Github commits.
- Mapbox autocomplete utility page: /mapbox

## [6.3.5] - 2022-05-23

### Removed

- Removed accuracy and connected_with fields from regional CSV exports, not working at the moment

## [6.3.4] - 2022-05-23

### Removed

- Removed connected_with field from regional CSV exports, not being collected

## [6.3.3] - 2022-05-23

### Added

- Added ip_address field to regional CSV exports


