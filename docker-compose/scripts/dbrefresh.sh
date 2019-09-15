#!/bin/bash
echo "Refreshing your local dev database from the staging db"

dbfilename='lms_dev_db_dump_latest.sql.gz'
dbfilepathgz="/tmp/$dbfilename"

aws s3 --region us-west-1 cp "s3://canvas-dev-db-dumps/$dbfilename" $dbfilepathgz
if [ $? -ne 0 ]
then
 echo "Failed downloading s3://canvas-dev-db-dumps/$dbfilename"
 echo "Make sure that awscli is installed: pip3 install awscli"
 echo "Also, make sure and run 'aws configure' and put in your Access Key and Secret."
 echo "Lastly, make sure your IAM account is in the Developers group. That's where the policy to access this bucket is defined."
 exit 1;
fi

gunzip < $dbfilepathgz | docker-compose exec -T canvasdb psql -U canvas canvas
if [ $? -ne 0 ]
then
   echo "Error: failed loading the dev database into the dev db. File we tried to load: $dbfilepathgz"
   exit 1;
fi

rm $dbfilepathgz

# Adjust some settings for dev
# - Make the timeout to wait for the SSO server 15 seconds since dev can be slow, especially on first start.
# - Disable Canvas analytics which relies on a Cassandra DB. No need for this and it clutter the error log.
cat <<EOF | docker-compose exec -T canvasdb psql -U canvas canvas
  insert into settings (name, value, created_at, updated_at).
  select 'cas_timelimit', '15', NOW(), NOW()
  where not exists (select id from settings where name = 'cas_timelimit');

  delete from settings where name = 'enable_page_views';
EOF

