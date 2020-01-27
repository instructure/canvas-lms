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

# Partially an API

# @API Media Objects
# @subtopic Media Tracks
#
# Closed captions added to a video MediaObject
#
# @object MediaTrack
#   {
#     "id": 42,
#     "user_id": 1,
#     "media_object_id": 14,
#     "kind": "subtitles",
#     "locale": "es",
#     "content": "1]\\n00:00:00,000 --> 00:00:01,251\nI'm spanish",
#     "created_at": "Mon, 24 Feb 2020 16:04:02 EST -05:00",
#     "updated_at": "Mon, 24 Feb 2020 16:59:05 EST -05:00",
#     "webvtt_content": "WEBVTT\n\n1]\\n00:00:00.000 --> 00:00:01.251\nI'm spanish"
#   }
#
class MediaTracksController < ApplicationController
  include Api::V1::MediaObject

  TRACK_SETTABLE_ATTRIBUTES = [:kind, :locale, :content].freeze

  # @API List media tracks for a Media Object
  #
  # List the media tracks associated with a media object
  #
  # @argument include[] [String, "content"|"webvtt_content"|"updated_at"|"created_at"]
  #   By default, index returns id, locale, kind, media_object_id, and user_id for each of the
  #   result MediaTracks. Use include[] to
  #   add additional fields. For example include[]=content
  #
  # @example_request
  #     curl https://<canvas>/api/v1/media_objects/<media_object_id>/media_tracks?include[]=content
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns [MediaTrack]
  def index
    @media_object = MediaObject.active.by_media_id(params[:media_object_id]).first
    return render_unauthorized_action unless @media_object

    # assume that if I have access to the MediaObject, I can list its tracks
    media_tracks = []
    @media_object.media_tracks.where(user_id: @current_user.id).each do |t|
      track = {
        :id => t.id,
        :locale => t.locale,
        :kind => t.kind,
        :media_object_id => t.media_object_id,
        :user_id => t.user_id
      }
      if params[:include].present?
        whitelist = ["content", "webvtt_content", "updated_at", "created_at"]
        params[:include].each do |field|
          track[field] = t[field] if whitelist.include? field
        end
      end
      media_tracks << track
    end

    render :json => media_tracks
  end

  # @{not an}API Create a media track
  #
  # Create a new media track to be used as captions for different languages or deaf users.
  # For more info, {https://developer.mozilla.org/en-US/docs/HTML/HTML_Elements/track read the MDN docs}
  #
  # @argument kind [String, "subtitles"|"captions"|"descriptions"|"chapters"|"metadata"]
  #   Default is 'subtitles'.
  #
  # @argument locale [String]
  #   Language code of the track being uploaded, examples: ["en", "es", "ru"]
  #
  # @argument content [String]
  #   The contents of the track, in SRT or WebVTT format
  #
  # @example_request
  #     curl https://<canvas>/media_objects/<media_object_id>/media_tracks \
  #         -F kind='subtitles' \
  #         -F locale='es' \
  #         -F content='0\n00:00:00,000 --> 00:00:01,000\nInstructor…This is the first sentance\n\n\n1\n00:00:01,000 --> 00:00:04,000\nand a second...' \
  #         -H 'Authorization: Bearer <token>'
  #
  # @returns MediaObject
  def create
    @media_object = MediaObject.active.by_media_id(params[:media_object_id]).first
    if authorized_action(@media_object, @current_user, :add_captions)
      track = @media_object.media_tracks.where(user_id: @current_user.id, locale: params[:locale]).first_or_initialize
      track.update! params.permit(*TRACK_SETTABLE_ATTRIBUTES)
      render :json => media_object_api_json(@media_object, @current_user, session)
    end
  end

  # @{not an}API Get the content of a Media Track
  #
  # returns the actual content of the uploaded media track.
  #
  # @example_request
  #     curl https://<canvas>/media_objects/<media_object_id>/media_tracks/<media_track_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  def show
    @media_track = MediaTrack.find params[:id]
    @media_track.validate! # in case this somehow got saved to the database in the xss-vulnerable TTML format
    if stale? :etag => @media_track, :last_modified => @media_track.updated_at.utc
      render :plain => @media_track.webvtt_content
    end
  end



  # @{not an}API Delete a Media Track
  #
  # Deletes the media track.
  #
  # @example_request
  #     curl -X DELETE https://<canvas>/media_objects/<media_object_id>/media_tracks/<media_track_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns MediaObject
  def destroy
    @media_object = MediaObject.by_media_id(params[:media_object_id]).first
    if authorized_action(@media_object, @current_user, :delete_captions)
      @track = @media_object.media_tracks.find(params[:media_track_id])
      if @track.destroy
        render :json => media_object_api_json(@media_object, @current_user, session)
      else
        render :json => @track.errors, :status => :bad_request
      end
    end
  end

  # @API Update Media Tracks
  #
  # Replace the media tracks associated with a media object with
  # the array of tracks provided in the body.
  # Update will
  # delete any existing tracks not listed,
  # leave untouched any tracks with no content field,
  # and update or create tracks with a content field.
  #
  # @argument include[] [String]
  #   By default, index returns id and locale for each of the
  #   result MediaTracks. Use include[] to
  #   add additional fields. For example include[]=content
  #   See #index for allowed values.
  #
  # @example_request
  #   curl -X PUT https://<canvas>/api/v1/media_objects/<media_object_id>/mediatracksinclude[]=content \
  #     -H 'Authorization: Bearer <token>'
  #     -d '[{"locale": "en"}, {"locale": "af","content": "1\r\n00:00:00,000 --> 00:00:01,251\r\nThis is the content\r\n"}]'
  #
  # @returns [MediaTrackk]
  def update
    @media_object = MediaObject.active.by_media_id(params[:media_object_id]).first
    return render_unauthorized_action unless @media_object
    return render_unauthorized_action unless @current_user

    if @media_object.grants_all_rights?(@current_user, session, :add_captions, :delete_captions)
      new_tracks = JSON.parse(request.body.read) || []
      old_track_locales = @media_object.media_tracks.where(user_id: @current_user.id).pluck(:locale)

      # delete the tracks that don't exist in the new set
      removed_track_locales = old_track_locales - new_tracks.pluck('locale')
      removed_tracks = @media_object.media_tracks.where(user_id: @current_user.id, locale: removed_track_locales)
      removed_tracks.destroy_all

      # create or update the new tracks
      new_tracks.each do |t|
        # if the new track coming from the client has no content, it hasn't been updated. Leave it alone.
        next if t["content"].blank?


        track = @media_object.media_tracks.where(user_id: @current_user.id, locale: t['locale']).first_or_initialize
        track.update! ActionController::Parameters.new(t).permit(*TRACK_SETTABLE_ATTRIBUTES)
      end
      index
    else
      return render_unauthorized_action
    end
  end
end
