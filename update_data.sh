#!/bin/sh

echo "Data procesing starting"
rake populate_boundaries
rake populate_census_tracts
rake populate_zip_boundaries
rake import_mlab_submissions
rake update_pending_census_codes
rake populate_missing_isps
rake populate_missing_boundaries
rake update_providers_statistics
rake update_stats_cache
echo "Data procesing complete"
