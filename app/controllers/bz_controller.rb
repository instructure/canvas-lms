# This holds BZ custom endpoints for updating our
# custom data.

require 'google/api_client'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'

class BzController < ApplicationController

  before_filter :require_user, :only => [:last_user_url]
  skip_before_filter :verify_authenticity_token, :only => [:last_user_url]

  def last_user_url
    @current_user.last_url = params[:last_url]
    @current_user.last_url_title = params[:last_url_title]
    @current_user.save

    render :nothing => true
  end

  def video_link
    obj = {}

    client = Google::APIClient.new(:application_name => 'Braven Canvas')

    file_store = Google::APIClient::FileStore.new(File.join(Rails.root, "config", "google_calendar_auth.json"))
    storage = Google::APIClient::Storage.new(file_store)
    client.authorization = storage.authorize
    calendar_api = client.discovered_api('calendar', 'v3')

    event = {
      'summary' => 'Canvas event',
      'start' => {
        'dateTime' => DateTime.now.iso8601,
        'timeZone' => 'America/Los_Angeles',
      },
      'end' => {
        'dateTime' => (DateTime.now + 1.hours).iso8601,
        'timeZone' => 'America/Los_Angeles',
      }
    }

    results = client.execute!(
      :api_method => calendar_api.events.insert,
      :parameters => {
        :calendarId => 'primary'},
      :body_object => event)

    event = results.data

    obj['link'] = event.hangout_link
    obj['gcal_id'] = event.id
    render :json => obj
  end

end
