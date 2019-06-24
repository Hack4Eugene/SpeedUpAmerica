#!/bin/sh

echo "Data procesing starting"
rake populate_census_tracts
rake populate_zip_boundaries
rake import_mlab_submissions
rake update_pending_census_codes
rake update_providers_statistics
echo "Data procesing complete"
