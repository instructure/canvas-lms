# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class VideoCaptionService < ApplicationService
  def initialize(media_object, skip_polling: false)
    super()

    @skip_polling = skip_polling # for testing purposes
    @media_object = media_object
    @type = media_object.media_type
    @title = media_object.title
    @media_id = media_object.media_id
  end

  def call
    return unless pass_initial_checks

    # send to Notorious so it can process the media; grab and use the media_id from the handoff response
    @media_id = handoff
    return unless @media_id

    # tell Notorious to start generating captions -- must be complete with handoff first
    captions_request_successful = poll_for_caption_request
    return unless captions_request_successful

    # check if captions are available and what language was detected by whisper
    @srclang = poll_for_captions_ready
    return unless @srclang

    # grab the captions once they're ready
    captions = grab_captions

    # create media_track with the caption
    save_media_track(captions)
  end

  private

  def pass_initial_checks
    return false unless config["app-host"].present?
    return false unless auth_token.present?
    return false unless @type.include?("video")
    return false unless @media_id
    return false if url.nil?

    true
  end

  def save_media_track(content)
    if content.present?
      @media_object.media_tracks.first_or_create(user: @media_object.user, locale: @srclang, kind: "subtitles", content:)
    end
  end

  def handoff
    response = request_handoff
    response&.dig("media", "id")
  end

  def poll_for_caption_request
    if @skip_polling
      return request_caption
    end

    10.times do |i|
      response = request_caption
      if (200..299).cover?(response.code)
        return response
      end

      sleep(1.minute * (i + 1))
    end
    nil
  end

  def poll_for_captions_ready
    if @skip_polling
      response = media
      return response.dig("media", "captions", 0, "language")
    end

    10.times do |i|
      response = media
      if response.dig("media", "captions", 0, "language") && response.dig("media", "captions", 0, "status") == "succeeded"
        src_lang = response.dig("media", "captions", 0, "language")
        # dont' proceed if the language is not detected as English
        src_lang = nil unless src_lang.start_with?("en")
        return src_lang
      end

      sleep(1.minute * (i + 1))
    end
    nil
  end

  def grab_captions
    response = collect_captions
    if (200..299).cover?(response.code)
      return response.body
    end

    nil
  end

  def url
    @url ||= grab_url_from_media_sources
  end

  def grab_url_from_media_sources
    media_sources = @media_object.reload.media_sources
    media_source = media_sources.min_by { |ms| ms[:bitrate]&.to_i }
    media_source&.fetch(:url, nil)
  end

  def handoff_url
    "#{notorious_host}/api/media"
  end

  def caption_request_url
    "#{notorious_host}/api/media/#{@media_id}/captions?provider=whisper"
  end

  def media_url
    "#{notorious_host}/api/media/#{@media_id}"
  end

  def caption_collect_url
    "#{notorious_host}/api/media/#{@media_id}/captions/#{@srclang}?provider=whisper"
  end

  def notorious_host
    config["app-host"]
  end

  def auth_token
    Rails.application.credentials.send(:"notorious-admin")&.[](:client_authentication_key)
  end

  def request_headers
    { "Authorization" => auth_token }
  end

  def request_handoff
    HTTParty.post(handoff_url, body: { url:, name: @title }, headers: request_headers)
  end

  def request_caption
    HTTParty.post(caption_request_url, headers: request_headers)
  end

  def media
    HTTParty.get(media_url, headers: request_headers)
  end

  def collect_captions
    HTTParty.get(caption_collect_url, headers: request_headers)
  end

  def config
    @config ||= DynamicSettings.find("notorious-admin", tree: :private) || {}
  end
end
