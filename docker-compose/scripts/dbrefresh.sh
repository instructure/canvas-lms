#!/bin/bash
echo "Refreshing your local dev database from the staging db"

dbfilename='lms_dev_db_dump_latest.sql.gz'
dbfilepathgz="/tmp/$dbfilename"

aws s3 --region us-west-1 cp "s3://canvas-dev-db-dumps/$dbfilename" $dbfilepathgz
if [ $? -ne 0 ]
then
 echo "Failed downloading s3://canvas-dev-db-dumps/$dbfilename"
 exit 1;
fi

gunzip < $dbfilepathgz | docker-compose exec -T canvasdb psql -U canvas canvas
if [ $? -ne 0 ]
then
   echo "Error: failed loading the dev database into the dev db. File we tried to load: $dbfilepathgz"
   exit 1;
fi

rm $dbfilepathgz
