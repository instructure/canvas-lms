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
  MAX_RETRY_ATTEMPTS = 10

  def initialize(media_object)
    super()

    @media_object = media_object
    @type = media_object.media_type
    @title = media_object.title
    @media_id = media_object.media_id
  end

  def call
    update_status(:processing)
    return update_status(:failed_initial_validation) unless pass_initial_checks

    @media_object.update_attribute(:auto_caption_media_id, @media_id)
    delay.poll_if_we_can_request_captions_yet
  end

  private

  def pass_initial_checks
    return false unless @type&.include?("video")
    return false unless @media_id
    return false if @media_object.media_tracks.where(kind: "subtitles").exists?

    true
  end

  def save_media_track(content, srclang)
    if content.present?
      @media_object.media_tracks.first_or_create(user: @media_object.user, locale: srclang, kind: "subtitles", content:)
      update_status(:complete)
    else
      update_status(:failed_to_pull)
    end
  end

  def update_status(status)
    @media_object.update_attribute(:auto_caption_status, status)
  end

  def poll_if_we_can_request_captions_yet(attempts = 1)
    response = kaltura_client.mediaGet(@media_id)

    if CanvasKaltura::ClientV3::Enums::KalturaEntryStatus[response&.dig(:status)] == :READY
      delay.request_to_start_caption_generation
    elsif attempts < 10
      delay(run_at: reschedule_time(attempts)).poll_if_we_can_request_captions_yet(attempts + 1)
    else
      update_status(:failed_request)
    end
  end

  def request_to_start_caption_generation(attempts = 1)
    caption_asset = kaltura_client.create_caption_asset(@media_id)

    if (@caption_id = caption_asset&.dig(:id))
      delay.check_if_captions_are_ready
    elsif attempts < MAX_RETRY_ATTEMPTS
      delay(run_at: reschedule_time(attempts)).request_to_start_caption_generation(attempts + 1)
    else
      update_status(:failed_request)
    end
  end

  def check_if_captions_are_ready(attempts = 1)
    caption_asset = kaltura_client.caption_asset(@caption_id)

    if CanvasKaltura::ClientV3::Enums::KalturaCaptionAssetStatus[caption_asset&.dig(:status)] == :READY
      save_media_track(kaltura_client.caption_asset_contents(@caption_id), caption_asset[:languageCode])
    elsif attempts < MAX_RETRY_ATTEMPTS
      delay(run_at: reschedule_time(attempts)).check_if_captions_are_ready(attempts + 1)
    else
      update_status(:failed_captions)
    end
  end

  def reschedule_time(attempt)
    # This mimics the exponential backoff algorithm used by inst jobs
    (5 + (attempt**4)).seconds.from_now
  end

  def kaltura_client
    CanvasKaltura::ClientV3.new.tap { it.startSession(CanvasKaltura::SessionType::ADMIN) }
  end
end
