# frozen_string_literal: true

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

require "nokogiri"

class BigBlueButtonConference < WebConference
  include ActionDispatch::Routing::PolymorphicRoutes
  include CanvasRails::Application.routes.url_helpers
  after_destroy :end_meeting
  after_destroy :delete_all_recordings

  user_setting_field :record, {
    name: -> { t("recording_setting", "Recording") },
    description: -> { t("recording_setting_enabled_description", "Enable recording for this conference") },
    type: :boolean,
    default: false,
    visible: -> { WebConference.config(class_name: BigBlueButtonConference.to_s)[:recording_enabled] },
  }

  user_setting_field :scheduled_date, {
    name: -> { t("Scheduled Date") },
    description: -> { t("Enable recording for this conference") },
    type: :date,
    default: false,
    visible: false
  }

  user_setting_field :create_time, {
    name: -> { t("create_time", "Create Time") },
    description: -> { t("Security setting to restrict join URLs to a conference") },
    type: :integer,
    default: false,
    visible: false
  }

  user_setting_field :share_webcam, {
    name: -> { t("Share webcam") },
    description: -> { t("Share webcam") },
    type: :boolean,
    default: true,
    visible: false
  }

  user_setting_field :share_microphone, {
    name: -> { t("Share microphone") },
    description: -> { t("Share microphone") },
    type: :boolean,
    default: true,
    visible: false
  }

  user_setting_field :send_public_chat, {
    name: -> { t("Send public chat messages") },
    description: -> { t("Send public chat messages") },
    type: :boolean,
    default: true,
    visible: false
  }

  user_setting_field :send_private_chat, {
    name: -> { t("Send private chat messages") },
    description: -> { t("Send private chat messages") },
    type: :boolean,
    default: true,
    visible: false
  }

  user_setting_field :enable_waiting_room, {
    name: -> { t("Enable waiting room") },
    description: -> { t("Enable waiting room") },
    type: :boolean,
    default: false,
    visible: false
  }

  user_setting_field :share_other_webcams, {
    name: -> { t("See other viewers webcams") },
    description: -> { t("See other viewers webcams") },
    type: :boolean,
    default: true,
    visible: false
  }

  class << self
    def send_request(action, options, use_fallback_config: false)
      url_str = generate_request(action, options, use_fallback_config:)
      http_response = nil
      Canvas.timeout_protection("big_blue_button") do
        logger.debug "big blue button api call: #{url_str}"
        http_response = CanvasHttp.get(url_str, redirect_limit: 5)
      end
      case http_response
      when Net::HTTPSuccess
        response = xml_to_hash(http_response.body)
        if response[:returncode] == "SUCCESS"
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

    def generate_request(action, options, use_fallback_config: false)
      config_to_use = (use_fallback_config && fallback_config.presence) || config
      query_string = options.to_query
      query_string << ("&checksum=" + Digest::SHA1.hexdigest(action.to_s + query_string + config_to_use[:secret_dec]))
      "https://#{config_to_use[:domain]}/bigbluebutton/api/#{action}?#{query_string}"
    end

    private

    def fallback_config
      Canvas::Plugin.find(:big_blue_button_fallback).settings&.with_indifferent_access
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
  end

  def initiate_conference
    return conference_key if conference_key && !retouch?

    unless conference_key
      self.conference_key = "instructure_#{feed_code}".gsub(/[^a-zA-Z0-9_]/, "_")
      chars = ("a".."z").to_a + ("0".."9").to_a
      # create user/admin passwords for this conference. we may want to show
      # the admin passwords in the ui in case moderators need them for any
      # admin-specific functionality within the BBB ui (or we could provide
      # ui for them to specify the password/key)
      settings[:user_key] = Array.new(8) { chars.sample }.join
      settings[:admin_key] = Array.new(8) { chars.sample }.join until settings[:admin_key] && settings[:admin_key] != settings[:user_key]
    end
    settings[:record] &&= config[:recording_enabled]
    settings[:domain] ||= config[:domain] # save the domain
    current_host = URI(settings[:default_return_url] || "http://www.instructure.com").host
    req_params = {
      :meetingID => conference_key,
      :name => title,
      :voiceBridge => format("%020d", global_id),
      :attendeePW => settings[:user_key],
      :moderatorPW => settings[:admin_key],
      :logoutURL => settings[:default_return_url] || "http://www.instructure.com",
      :record => settings[:record] ? true : false,
      "meta_canvas-recording-ready-user" => recording_ready_user,
      "meta_canvas-recording-ready-url" => recording_ready_url(current_host)
    }

    if context.is_a?(Course)
      req_params[:bbbCanvasCourseName] = context.name
      req_params[:bbbCanvasCourseCode] = context.course_code
    end

    if Account.site_admin.feature_enabled? :bbb_modal_update
      req_params.merge!({
                          lockSettingsDisableCam: settings[:share_webcam] ? false : true,
                          lockSettingsDisableMic: settings[:share_microphone] ? false : true,
                          lockSettingsDisablePublicChat: settings[:send_public_chat] ? false : true,
                          lockSettingsDisablePrivateChat: settings[:send_private_chat] ? false : true,
                          guestPolicy: settings[:enable_waiting_room] ? "ASK_MODERATOR" : "ALWAYS_ACCEPT",
                          webcamsOnlyForModerator: settings[:share_other_webcams] ? false : true,
                        })
    end
    response = send_request(:create, req_params) or return nil
    @conference_active = true
    settings[:create_time] = response[:createTime] if response.present?
    save
    InstStatsd::Statsd.increment("bigbluebutton.started")
    InstStatsd::Statsd.increment("bigbluebutton.start.setting.record") if req_params[:record] == true
    InstStatsd::Statsd.increment("bigbluebutton.start.setting.share_webcam") if req_params[:lockSettingsDisableCam] == false
    InstStatsd::Statsd.increment("bigbluebutton.start.setting.share_microphone") if req_params[:lockSettingsDisableMic] == false
    InstStatsd::Statsd.increment("bigbluebutton.start.setting.send_public_chat") if req_params[:lockSettingsDisablePublicChat] == false
    InstStatsd::Statsd.increment("bigbluebutton.start.setting.send_private_chat") if req_params[:lockSettingsDisablePrivateChat] == false
    InstStatsd::Statsd.increment("bigbluebutton.start.setting.enable_waiting_room") if req_params[:guestPolicy] == "ASK_MODERATOR"
    InstStatsd::Statsd.increment("bigbluebutton.start.setting.share_other_webcams") if req_params[:webcamsOnlyForModerator] == false
    conference_key
  end

  def recording_ready_user
    if grants_right?(user, :create)
      "#{user["name"]} <#{user.email}>"
    end
  end

  def recording_ready_url(current_host = nil)
    polymorphic_url([:api_v1, context, :conferences, :recording_ready],
                    conference_id: id,
                    protocol: HostUrl.protocol,
                    host: HostUrl.context_host(context, current_host))
  end

  def conference_status
    if (result = send_request(:isMeetingRunning, meetingID: conference_key)) && result[:running] == "true"
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
      recording = fetch_recordings.find { |r| r[:recordID] == recording_id }
      recording_formats(recording) if recording
    end
  end

  def recording_formats(recording)
    recording_formats = recording.fetch(:playback, []).map do |format|
      show_to_students = !!format[:length] || format[:type] == "notes" # either is an actual recording or shared notes
      format[:translated_type] = translate_playback_format_type(format[:type])
      format.merge(show_to_students:)
    end
    {
      recording_id: recording[:recordID],
      title: recording[:name],
      duration_minutes: filter_duration(recording_formats),
      playback_url: nil,
      playback_formats: recording_formats,
      created_at: recording[:startTime].to_i,
    }
  end

  def translate_playback_format_type(format_type)
    case format_type
    when "notes"
      I18n.t("playback.notes", "Notes")
    when "presentation"
      I18n.t("playback.presentation", "Presentation")
    when "statistics"
      I18n.t("playback.statistics", "Statistics")
    when "podcast"
      I18n.t("playback.podcast", "Podcast")
    when "video"
      I18n.t("playback.video", "Video")
    else
      format_type
    end
  end

  def delete_recording(recording_id)
    return { deleted: false } if recording_id.nil?

    response = send_request(:deleteRecordings, recordID: recording_id)
    { deleted: response.present? && response[:deleted].casecmp("true") == 0 }
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

  attr_writer :loaded_recordings

  # we can use the same API method with multiple meeting ids to load all the recordings up in one go
  # instead of making a bunch of individual calls
  def self.preload_recordings(conferences)
    filtered_conferences = conferences.select { |c| c.conference_key && c.settings[:record] }
    return unless filtered_conferences.any?

    fallback_conferences, current_conferences = filtered_conferences.partition(&:use_fallback_config?)
    fetch_and_preload_recordings(fallback_conferences, use_fallback_config: true) if fallback_conferences.any?
    fetch_and_preload_recordings(current_conferences, use_fallback_config: false) if current_conferences.any?
  end

  def self.fetch_and_preload_recordings(conferences, use_fallback_config: false)
    # have a limit so we don't send a ridiculously long URL over
    conferences.each_slice(50) do |sliced_conferences|
      meeting_ids = sliced_conferences.map(&:conference_key).join(",")
      response = send_request(:getRecordings,
                              { meetingID: meeting_ids },
                              use_fallback_config:)
      result = response[:recordings] if response
      result = [] if result.is_a?(String)
      grouped_result = Array(result).group_by { |r| r[:meetingID] }
      sliced_conferences.each do |c|
        c.loaded_recordings = grouped_result[c.conference_key] || []
      end
    end
  end

  def use_fallback_config?
    # use the fallback config (if possible) if it wasn't created with the current config
    self.class.config[:use_fallback] &&
      settings[:domain] != self.class.config[:domain]
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
    additional_params = {}

    if config[:send_avatar]
      additional_params[:avatarUrl] = user.avatar_url
    end

    unless user.pronouns.nil?
      additional_params[:userdataPronouns] = user.pronouns
    end

    generate_request :join,
                     fullName: user.short_name,
                     meetingID: conference_key,
                     password: settings[((type == :user) ? :user_key : :admin_key)],
                     userID: user.id,
                     createTime: settings[:create_time],
                     **additional_params
  end

  def end_meeting
    response = send_request(:end, {
                              meetingID: conference_key,
                              password: settings[((type == :user) ? :user_key : :admin_key)],
                            })
    response[:ended] if response
  end

  def fetch_recordings
    @loaded_recordings ||= if conference_key && settings[:record]
                             response = send_request(:getRecordings, {
                                                       meetingID: conference_key,
                                                     })
                             result = response[:recordings] if response
                             result = [] if result.is_a?(String)
                             Array(result)
                           else
                             []
                           end
  end

  def generate_request(*args)
    self.class.generate_request(*args)
  end

  def send_request(action, options)
    self.class.send_request(action, options, use_fallback_config: use_fallback_config?)
  end

  def filter_duration(recording_formats)
    # This is a filter to take the duration from any of the playback formats that include a value in length.
    # As not all the formats are the actual recording, identify the first one that has :length <> nil
    recording_formats.each do |recording_format|
      return recording_format[:length].to_i if recording_format[:length].present?
    end
  end
end
