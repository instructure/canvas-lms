#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

require 'nokogiri'

class BigBlueButtonConference < WebConference
  include ActionDispatch::Routing::PolymorphicRoutes
  include CanvasRails::Application.routes.url_helpers
  before_destroy :end_meeting
  before_destroy :delete_all_recordings

  SHOW_RECORDING_OPTION = '1'
  HIDE_RECORDING_OPTION = '2'
  RECORD_EVERYTHING = '3'

  RECORDING_OPTIONS = {
    SHOW_RECORDING_OPTION.to_i => t('settings_show_option','Show record option'),
    HIDE_RECORDING_OPTION.to_i => t('settings_hide_option','Hide record option (true by default)'),
    RECORD_EVERYTHING.to_i => t('settings_record_everything','Record everything')
  }

  user_setting_field :record, {
    name: ->{ t('recording_setting', 'Recording') },
    description: ->{ t('recording_setting_enabled_description', 'Enable recording for this conference') },
    type: :boolean,
    default: ->{ WebConference.config(BigBlueButtonConference.to_s) && WebConference.config(BigBlueButtonConference.to_s).key?(:recording_option_enabled) ? WebConference.config(BigBlueButtonConference.to_s)[:recording_option_enabled] : false },
    visible: ->{ WebConference.config(BigBlueButtonConference.to_s) && WebConference.config(BigBlueButtonConference.to_s).key?(:recording_options) ? WebConference.config(BigBlueButtonConference.to_s)[:recording_options]==SHOW_RECORDING_OPTION : false },
  }

  def initiate_conference
    return conference_key if conference_key && !retouch?
    unless self.conference_key
      self.conference_key = "instructure_#{self.feed_code}".gsub(/[^a-zA-Z0-9_]/, "_")
      chars = ('a'..'z').to_a + ('0'..'9').to_a
      # create user/admin passwords for this conference. we may want to show
      # the admin passwords in the ui in case moderators need them for any
      # admin-specific functionality within the BBB ui (or we could provide
      # ui for them to specify the password/key)
      settings[:user_key] = 8.times.map{ chars[chars.size * rand] }.join
      settings[:admin_key] = 8.times.map{ chars[chars.size * rand] }.join until settings[:admin_key] && settings[:admin_key] != settings[:user_key]
    end
    current_host = URI(settings[:default_return_url] || "http://www.instructure.com").host

    requestBody = {
      :meetingID => conference_key,
      :name => title,
      :voiceBridge => "%020d" % self.global_id,
      :attendeePW => settings[:user_key],
      :moderatorPW => settings[:admin_key],
      :logoutURL => settings[:default_return_url] ? "javascript:window.close()" : "http://www.instructure.com",
      :welcome => config[:recording_enabled] ? t("This conference may be recorded.") : ""
    }
    requestBody["meta_bn-recording-ready-url"] = recording_ready_url(current_host)

    if config[:recording_enabled]
      case config[:recording_options]
      when SHOW_RECORDING_OPTION
        requestBody[:record] = settings[:record]
      when HIDE_RECORDING_OPTION
        requestBody[:record] = true
      when RECORD_EVERYTHING
        requestBody[:record] = true
        requestBody[:autoStartRecording] = true
        requestBody[:allowStartStopRecording] = false
      end
    else
      requestBody[:record] = false
    end

    send_request(:create, requestBody) or return nil
    @conference_active = true
    save
    conference_key
  end

  def recording_ready_url(current_host = nil)
    polymorphic_url([:api_v1, context, :conferences, :recording_ready],
                    conference_id: self.id,
                    protocol: HostUrl.protocol,
                    host: HostUrl.context_host(context, current_host))
  end

  def conference_status
    if (result = send_request(:isMeetingRunning, :meetingID => conference_key)) && result[:running] == 'true'
      :active
    else
      :closed
    end
  end

  def admin_join_url(user, return_to = "http://www.instructure.com")
    join_url(user, :admin)
  end

  def participant_join_url(user, return_to = "http://www.instructure.com")
    join_url(user)
  end

  def recordings
    fetch_recordings.map do |recording|
      recording_formats = recording.fetch(:playback, {})
      recordingObj = {
        recording_id:       recording[:recordID],
        recording_vendor:   "big_blue_button",
        published:          recording[:published]=="true" ? true : false,
        protected:          recording[:protected] ? recording[:protected]=="true" ? true : false : nil,
        ended_at:           recording[:endTime].to_i,
        duration_minutes:   recording_formats.first[:length].to_i,
        recording_formats:  [],
        images:             []
      }
      recording_formats.each do |recording_format|
        recordingObj[:recording_formats] << {
          type:             recording_format[:type].capitalize,
          playback_url:     recording_format[:url]
        }
        if recording_format[:preview] && recording_format[:preview][:images] && recording_format[:preview][:images].length > recordingObj[:images].length
          recordingObj[:images] = recording_format[:preview][:images]
        end
      end
      recordingObj
    end
  end

  def delete_all_recordings
    recordings = fetch_recordings.map!{ |recording| recording[:recordID] }
    if recordings.length > 0
      page_size = 25
      for page in 0..(recordings.length / page_size + 1)
        offset = page * page_size
        recs = recordings[(offset)..(offset + page_size)]
        send_request(:deleteRecordings, {
          :recordID => recs.join(","),
          })
      end
    end
  end

  def delete_recording(recording_id)
    send_request(:deleteRecordings, {
      :recordID => recording_id,
      })
    get_recording(recording_id)
  end

  def publish_recording(recording_id, publish)
    send_request(:publishRecordings, {
      :recordID => recording_id,
      :publish  => publish
      })
    get_recording(recording_id)
  end

  def protect_recording(recording_id, protect)
    send_request(:updateRecordings, {
      :recordID => recording_id,
      :protect  => protect
      })
    get_recording(recording_id)
  end

  def get_recording(recording_id)
    response_recordings = send_request(:getRecordings, {
      :meetingID => conference_key
      })
    recording = response_recordings[:recordings].find{ |r| r[:recordID]==recording_id }
    if recording
      response = { :published => recording[:published], :protected => recording[:protected], :recording_formats => [] }
      recording[:playback].each{ |formats| response[:recording_formats] << { :type => formats[:type].capitalize, :url => formats[:url] } }
    end
    response if response
  end

  def close
    end_meeting
    super
  end

  private

  def retouch?
    # If we've queried the room status recently, use that result to determine if
    # we need to recreate it.
    return !@conference_active unless @conference_active.nil?

    # BBB removes chat rooms that have been idle fairly quickly.
    # There's no harm in "creating" a room that already exists; the api will
    # just return the room info. So we'll just go ahead and recreate it
    # to make sure we don't accidentally redirect people to an inactive room.
    return true
  end

  def join_url(user, type = :user)
    generate_request :join,
      :fullName => user.name,
      :meetingID => conference_key,
      :password => settings[(type == :user ? :user_key : :admin_key)],
      :userID => user.id
  end

  def end_meeting
    if self.ended_at.nil?
      response = send_request(:end, {
        :meetingID => conference_key,
        :password => settings[(type == :user ? :user_key : :admin_key)],
        })
      response[:ended] if response
    end
  end

  def fetch_recordings
    return [] unless conference_key && config[:recording_enabled]
    response = send_request(:getRecordings, {
      :meetingID => conference_key,
      })
    result = response[:recordings] if response
    result = [] if result.is_a?(String)
    Array(result)
  end

  def generate_request(action, options)
    query_string = options.to_query
    query_string << ("&checksum=" + Digest::SHA1.hexdigest(action.to_s + query_string + config[:secret_dec]))
    returnUrl = config[:domain]
    returnUrl.slice!(-1) if returnUrl[-1]=="/"
    unless returnUrl.include?("http://") && returnUrl.include?("/api")
      returnUrl = if returnUrl.include?("http://") && !returnUrl.include?("/api")
                    returnUrl.include?("/bigbluebutton") ? "#{returnUrl}/api" : "#{returnUrl}/bigbluebutton/api"
                  elsif !returnUrl.include?("http://") && returnUrl.include?("/api")
                    #We assume that we have a URL in the type "domain/bigbluebutton/api"
                    "http://#{returnUrl}"
                  else
                    #For URLs only including the IP address
                    "http://#{returnUrl}/bigbluebutton/api"
                  end
    end
    "#{returnUrl}/#{action}?#{query_string}"
  end

  def send_request(action, options)
    url_str = generate_request(action, options)

    http_response = nil
    Canvas.timeout_protection("big_blue_button") do
      logger.debug "big blue button api call: #{url_str}"
      http_response = CanvasHttp.get(url_str, redirect_limit: 5)
    end

    case http_response
      when Net::HTTPSuccess
        response = xml_to_hash(http_response.body)
        if response[:returncode] == 'SUCCESS'
          return response
        else
          logger.error "big blue button api error #{response[:message]} (#{response[:messageKey]})"
        end
      else
        logger.error "big blue button http error #{http_response}"
    end
    nil
  rescue
    logger.error "big blue button unhandled exception #{$!}"
    nil
  end

  def xml_to_hash(xml_string)
    doc = Nokogiri::XML(xml_string)
    # assumes the top level value will be a hash
    xml_to_value(doc.root)
  end

  def xml_to_value(node)
    child_elements = node.element_children

    # if there are no children at all, then this is an empty node
    if node.children.empty?
      nil
    # If no child_elements, this is probably a text node, so just return its content
    elsif child_elements.empty?
      if node.name == "image"
        {
          :width            =>  node.attributes["width"].value,
          :height           =>  node.attributes["height"].value,
          :title            =>  node.attributes["alt"].value,
          :thumbnail_url    =>  node.content
        }
      else
        node.content
      end
    # The BBB API follows the pattern where a plural element (ie <bars>)
    # contains many singular elements (ie <bar>) and nothing else. Detect this
    # and return an array to be assigned to the plural element.
    # Also if the node name is playback, so that it returns an array of all the available recording formats
    elsif node.name.singularize == child_elements.first.name || node.name=="playback"
      child_elements.map { |child| xml_to_value(child) }
    # otherwise, make a hash of the child elements
    else
      child_elements.reduce({}) do |hash, child|
        hash[child.name.to_sym] = xml_to_value(child)
        hash
      end
    end
  end
end
