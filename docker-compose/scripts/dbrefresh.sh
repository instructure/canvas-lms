#!/bin/bash
echo "Refreshing your local dev database from the staging db"
 
dbfilename='lms_staging_db_latest.sql.gz'

docker-compose down
docker volume rm canvas-lms_canvas-db
docker-compose up -d canvasdb
sleep 5 # wait for canvasdb container to be accepting connections

aws s3 cp "s3://canvas-staging-db-dumps/$dbfilename" - | gunzip | sed -e "

  s/https:\/\/stagingsso.bebraven.org/http:\/\/platformweb:3020\/cas/g;
  s/https:\/\/stagingplatform.bebraven.org/http:\/\/platformweb:3020/g;
  s/https:\/\/stagingjoin.bebraven.org/http:\/\/joinweb:3001/g;

  # Also fix up internal links in assignments to stay on staging as we navigate
  s/https:\/\/stagingportal.bebraven.org/http:\/\/canvasweb:3000/g;

  # If we have links to the kits from the LC playbook, fix that up.
  s/https:\/\/stagingkits.bebraven.org/http:\/\/kitsweb:3005/g;

  # Also fix up links to custom CSS/JS. Note: we could do this on this row but it's a pain
  # select id, name, settings from accounts where id = 1;
  s/https:\/\/s3.amazonaws.com\/canvas-stag-assets/http:\/\/cssjsweb:3004/g;

" | docker-compose exec -T canvasdb psql -U canvas canvas
if [ $? -ne 0 ]
then
 echo "Failed restoring from s3://canvas-staging-db-dumps/$dbfilename"
 echo "Make sure that awscli is installed: pip3 install awscli"
 echo "Also, make sure and run 'aws configure' and put in your Access Key and Secret."
 echo "Lastly, make sure your IAM account is in the Developers group. That's where the policy to access this bucket is defined."
 exit 1;
fi

# Adjust some settings for dev
# - Set the dev encryption key hash so that dev passwords are encrypted using a dev value.
# - Set the dev access token and access token hint, used for other apps to be able to call into the Canvas API.
# - Make the timeout to wait for the SSO server 15 seconds since dev can be slow, especially on first start.
# - Disable Canvas analytics which relies on a Cassandra DB. No need for this and it clutter the error log.
cat <<EOF | docker-compose exec -T canvasdb psql -U canvas canvas

  -- This is the hashed value of the dev only encryption key used in security.yml
  update settings set value = '40ed0028ef3004ed37cbec550a57bcde82472631' where name = 'encryption_key_hash';

  -- The 'Beyond Z Platform Integration' access token for dev is:
  -- BEW8ldtbMypKZiCs8EmW2eQXfOoBpfOEwNJXwyvfIKZIpMgQzBfYUugc4V20oFgt
  -- These are the encrypted values that the above accces token works against:
  update access_tokens set crypted_token = 'd3cb10787c10be0c15bd036f1ae502360e4cc7c4', token_hint = 'BEW8l' where id = 2;

  insert into settings (name, value, created_at, updated_at)
  select 'cas_timelimit', '15', NOW(), NOW()
  where not exists (select id from settings where name = 'cas_timelimit');

  delete from settings where name = 'enable_page_views';
EOF

./docker-compose/scripts/restart.sh
