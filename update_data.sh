#!/bin/sh

echo "Data procesing starting"
rake import_mlab_submissions
rake update_pending_census_codes
rake update_providers_statistics
echo "Data procesing complete"
