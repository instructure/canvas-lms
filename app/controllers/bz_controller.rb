# This holds BZ custom endpoints for updating our
# custom data.

require 'google/api_client'
require 'google/api_client/auth/storage'
require 'google/api_client/auth/storages/file_store'

class BzController < ApplicationController

  before_filter :require_user, :only => [:last_user_url]
  skip_before_filter :verify_authenticity_token, :only => [:last_user_url, :set_user_retained_data]

  def accessibility_check
    @items = []
    WikiPage.all.each do |page|
      doc = Nokogiri::HTML(page.body)
      doc.css('img:not(.bz-magic-viewer)').each do |img|
        if img.attributes["alt"].nil?
          @items << { :page => page, :html => img.to_html, :problem => 'Missing alt text' }
        elsif img.attributes["alt"].value == ""
          @items << { :page => page, :html => img.to_html, :problem => 'Empty alt text' }
        elsif img.attributes["alt"].value.ends_with?(".png")
          @items << { :page => page, :html => img.to_html, :problem => 'Poor alt text' }
        elsif img.attributes["alt"].value.ends_with?(".jpg")
          @items << { :page => page, :html => img.to_html, :problem => 'Poor alt text' }
        elsif img.attributes["alt"].value.ends_with?(".svg")
          @items << { :page => page, :html => img.to_html, :problem => 'Poor alt text' }
        elsif img.attributes["alt"].value.ends_with?(".gif")
          @items << { :page => page, :html => img.to_html, :problem => 'Poor alt text' }
        end
      end
      doc.css('iframe[src*="vimeo"]').each do |img|
        @items << { :page => page, :html => img.to_html, :problem => 'Ensure video has CC' }
      end
      doc.css('iframe[src*="youtu"]').each do |img|
        @items << { :page => page, :html => img.to_html, :problem => 'Ensure video has CC' }
      end
    end
  end

  def full_module_view
    @course_id = params[:course_id]
    @module_sequence = params[:module_sequence]
    items = Course.find(@course_id.to_i).context_modules[@module_sequence.to_i].content_tags_visible_to(@current_user)
    @pages = []
    items.each do |item|
      if item.content_type == "WikiPage"
        wp = WikiPage.find(item.content_id)
        @pages << wp
      end
    end
  end

  def user_retained_data
    result = RetainedData.where(:user_id => @current_user.id, :name => params[:name])
    data = ''
    unless result.empty?
      data = result.first.value
    end
    render :json => data
  end

  def set_user_retained_data
    result = RetainedData.where(:user_id => @current_user.id, :name => params[:name])
    data = nil
    if result.empty?
      data = RetainedData.new()
      data.user_id = @current_user.id
      data.name = params[:name]
    else
      data = result.first
    end

    data.value = params[:value]
    data.save
    render :nothing => true
  end

  def last_user_url
    @current_user.last_url = params[:last_url]
    @current_user.last_url_title = params[:last_url_title]
    @current_user.save

    render :nothing => true
  end

  def event_rsvps
    result = []
    CalendarEvent.find(params[:id]).get_gcal_rsvp_status.each do |attendee|
      obj = {}
      # Going to look up unconfirmed emails too because the imported emails might
      # not be formally confirmed in canvas while still being good for us (we confirmed
      # via the join server already)
      cc = CommunicationChannel.where(:path => attendee["email"], :path_type => 'email', :workflow_state => ['active', 'unconfirmed'])
      next if cc.empty?
      canvas_user = User.find(cc.first.user_id)
      obj['user_link'] = user_path(canvas_user)
      obj['user_name'] = canvas_user.name
      obj['user_status'] = attendee["responseStatus"]
      obj['user_status_text'] = case attendee["responseStatus"]
       when 'needsAction'
         'Not answered'
       else
         attendee["responseStatus"]
       end
      result << obj
    end

    render :json => result
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

  # The official Canvas API doesn't offer user deletion but
  # we want it, so I'm implementing myself (based on the code
  # from the users_controller through the admin interface)
  def delete_user
    user = api_find(User, params[:id])
    if user.allows_user_to_remove_from_account?(@domain_root_account, @current_user)
      # this will not delete the record completely, but will mark it as deleted,
      # same as if you manually hit the button in the admin page.
      user.destroy
    end
    render :nothing => true
  end

end
