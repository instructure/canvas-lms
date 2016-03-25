# This script is used to create the refresh token set in
# the google_calendar_auth.json config file

# These credentials are required access to the Calendar API
#
# To get these values, we did the following:
# NOTE: for now all instructions were actually done for the braven.developers@gmail account and NOT braven.portal@gmail.
#       But we do want to cutover to the new account so the event invites are a bit more user friendly.
# * Created a new normal gmail account called Braven Portal (braven.portal@gmail.com)
#    * Note: it can't be a bebraven.org account b/c there are frequently permissions issues with external folks.
# * Login to the Google account
# * Go to the Calendar settings and enable "Automatically add video calls to events I create".  Make sure and Save it.
# * Now, create a developer project in the Google Developer Console: https://console.developers.google.com/project
#   * It's under "Select a project -> Create a project..."
#   * Name it "Braven Portal Integration"
#   * Add the general braven accounts as Editor members of the project so that it will not dissappear if one account
#     is deleted here: https://console.developers.google.com/project/braven-portal-integration/permissions/projectpermissions
#     Added: brian@bebraven.org, app.integration@bebraven.org, no-reply@beyondz.org, info@beyondz.org
# * Enable the Calendar and Drive API: https://console.developers.google.com/apis/enabled
# * Add credentials: https://console.developers.google.com/apis/credentials
#   - Choose OAuth 2.0 client ID
#   - Choose Web Application (and a good name, e.g. 'Braven Portal Calendar Integration'
#   - Set the Authorized Redirect URI to the following b/c that is what the ruby script we use 
#     below specifies: http://localhost:9292/
#   - When it shows the client id and secret, just hit Ok.
#   - Download the credentials as JSON using the little down arrow button next to the OAuth client ID
#     and save them next to this file with the name client_secrets.json
#     (specified in the CLIENT_SECRETS_PATH below)
# * The client_secrets.json give the client ID and client secret, but you still need to
#   get a refresh token so that the application can make requests on behalf
#   of a specific user.
#   - In your default browser, login as: braven.portal@bebraven.org
#   - Install the API client gem: gem install google-api-client
#   - Make sure there isn't already a file called google_calendar_auth.json next to this script.
#   - Run: ruby create_google_calendar_auth.rb
#   - Click "Allow" when the browser asks you to give access to 
# * The refresh token and other settings are now saved in the google_calendar_auth.json file
# * Copy this file to the server in the config directory.
# * DON'T CHECK IT INTO SRC CTRL
#
# * ERRORS: on a Mac especially, running the create_google_calendar_auth.rb script may fail with SSL
#   errors or hang.  Here is what I did to get it working
#   - Updated my certs on my local machine:
#     - rvm osx-ssl-certs status all
#     - rvm osx-ssl-certs update all 
#     - rvm reinstall 2.2.3 --disable-binary
#   - This got me past the initial SSL failure, but then it would hang.
#   - So I unpacked the google-api-client gem, put in some console logging to narrow
#     down the issue, and found it was another SSL failure.  So I disabled SSL
#     verification directly in the little ruby server that it launches to handle the
#     requests:
#       - gem unpack google-api-client
#       - vim google-api-client-0.8.6/lib/google/api_client/auth/installed_app.rb
#           # At the top of the file add:
#           # The call to fetch_access_token! fails with SSL error without this.
#           require 'openssl'
#           OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
#       - ruby -I google-api-client-0.8.6/lib create_google_calendar_auth.rb

# The call to fetch_access_token! fails with SSL error without this.
require 'openssl'
OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/installed_app'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'

# NOTE: I was having trouble getting ruby to load the above scripts from the unpacked gem, so I commented out
# the above requires and hardcoded the paths below to my custom installed_app.rb dir
##require '~/src/google-api-client/lib/google/api_client'
#require '~/src/google-api-client/lib/google/api_client/client_secrets'
#require '~/src/google-api-client/lib/google/api_client/auth/installed_app'
#require '~/src/google-api-client/lib/google/api_client/auth/storage'
#require '~/src/google-api-client/lib/google/api_client/auth/storages/file_store'

require 'fileutils'

APPLICATION_NAME = 'Canvas To Google Calendar Integration'
CLIENT_SECRETS_PATH = 'client_secrets.json'
CREDENTIALS_PATH = File.join("google_calendar_auth.json")
SCOPE = 'https://www.googleapis.com/auth/calendar https://spreadsheets.google.com/feeds https://www.googleapis.com/auth/drive'

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization request via InstalledAppFlow.
# If authorization is required, the user's default browser will be launched
# to approve the request.
#
# @return [Signet::OAuth2::Client] OAuth2 credentials
def authorize
  puts "Entering authorize"
  FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

  file_store = Google::APIClient::FileStore.new(CREDENTIALS_PATH)
  storage = Google::APIClient::Storage.new(file_store)
  puts "Calling: auth = storage.authorize"
  auth = storage.authorize

  if auth.nil? || (auth.expired? && auth.refresh_token.nil?)
    puts "Loading client secrets"
    app_info = Google::APIClient::ClientSecrets.load(CLIENT_SECRETS_PATH)
    flow = Google::APIClient::InstalledAppFlow.new({
      :client_id => app_info.client_id,
      :client_secret => app_info.client_secret,
      :scope => SCOPE})
    puts "Calling: flow.authorize(storage)"
    auth = flow.authorize(storage)
    puts "Credentials saved to #{CREDENTIALS_PATH}" unless auth.nil?
  end
  auth
end

puts "Starting script"
# Initialize the API
#client = Google::APIClient.new(:application_name => APPLICATION_NAME)
client = Google::APIClient.new()
client.authorization = authorize
