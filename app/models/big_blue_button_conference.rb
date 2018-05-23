#
# Copyright (C) 2011 - present Instructure, Inc.
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
  after_destroy :end_meeting
  after_destroy :delete_all_recordings

  user_setting_field :record, {
    name: ->{ t('recording_setting', 'Recording') },
    description: ->{ t('recording_setting_enabled_description', 'Enable recording for this conference') },
    type: :boolean,
    default: false,
    visible: ->{ WebConference.config(BigBlueButtonConference.to_s)[:recording_enabled] },
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
    settings[:record] &&= config[:recording_enabled]
    current_host = URI(settings[:default_return_url] || "http://www.instructure.com").host
    send_request(:create, {
      :meetingID => conference_key,
      :name => title,
      :voiceBridge => format("%020d", self.global_id),
      :attendeePW => settings[:user_key],
      :moderatorPW => settings[:admin_key],
      :logoutURL => (settings[:default_return_url] || "http://www.instructure.com"),
      :record => settings[:record] ? "true" : "false",
      :welcome => settings[:record] ? t("This conference may be recorded.") : "",
      "meta_canvas-recording-ready-url" => recording_ready_url(current_host)
    }) or return nil
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

  def admin_join_url(user, _return_to = "http://www.instructure.com")
    join_url(user, :admin)
  end

  def participant_join_url(user, _return_to = "http://www.instructure.com")
    join_url(user)
  end

  def recordings
    fetch_recordings.map do |recording|
      recording_formats(recording)
    end
  end

  def recording(recording_id = nil)
    unless recording_id.nil?
      recording = fetch_recordings.find{ |r| r[:recordID]==recording_id }
      recording_formats(recording) if recording
    end
  end

  def recording_formats(recording)
    recording_formats = recording.fetch(:playback, [])
    {
      recording_id:     recording[:recordID],
      title:            recording[:name],
      duration_minutes: filter_duration(recording_formats),
      playback_url:     nil,
      playback_formats: recording_formats,
      created_at:       recording[:startTime].to_i,
    }
  end

  def delete_recording(recording_id)
    return { deleted: false } if recording_id.nil?
    response = send_request(:deleteRecordings, recordID: recording_id)
    { deleted: response.present? && response[:deleted].casecmp('true') == 0 }
  end

  def delete_all_recordings
    fetch_recordings.map do |recording|
      delete_recording recording[:recordID]
    end
  end

  def close
    end_meeting
    super
  end

  private

  def retouch?
    # If we've queried the room status recently, use that result to determine if
    # we need to recreate it.
    unless @conference_active.nil?
      return !@conference_active
    end

    # BBB removes chat rooms that have been idle fairly quickly.
    # There's no harm in "creating" a room that already exists; the api will
    # just return the room info. So we'll just go ahead and recreate it
    # to make sure we don't accidentally redirect people to an inactive room.
    true
  end

  def join_url(user, type = :user)
    generate_request :join,
      :fullName => user.name,
      :meetingID => conference_key,
      :password => settings[(type == :user ? :user_key : :admin_key)],
      :userID => user.id
  end

  def end_meeting
    response = send_request(:end, {
      :meetingID => conference_key,
      :password => settings[(type == :user ? :user_key : :admin_key)],
      })
    response[:ended] if response
  end

  def fetch_recordings
    return [] unless conference_key && settings[:record]
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
    "https://#{config[:domain]}/bigbluebutton/api/#{action}?#{query_string}"
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
    logger.error "big blue button unhandled exception #{$ERROR_INFO}"
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
      node.content
    # The BBB API follows the pattern where a plural element (ie <bars>)
    # contains many singular elements (ie <bar>) and nothing else. Detect this
    # and return an array to be assigned to the plural element.
    # It excludes the playback node as all of them may be showing different content.
    elsif node.name.singularize == child_elements.first.name || node.name == "playback"
      child_elements.map { |child| xml_to_value(child) }
    # otherwise, make a hash of the child elements
    else
      child_elements.each_with_object({}) do |child, hash|
        hash[child.name.to_sym] = xml_to_value(child)

      end
    end
  end

  def filter_duration(recording_formats)
    # As not all the formats are the actual recording, identify the one that has :length
    recording_formats.each do |recording_format|
      return recording_format[:length].to_i if recording_format.key?(:length)
    end
  end
end
