#
# Copyright (C) 2012 Instructure, Inc.
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

# Not yet an API, for reasons outlined in MediaObjectsController
class MediaTracksController < ApplicationController
  include Api::V1::MediaObject

  TRACK_SETTABLE_ATTRIBUTES = [:kind, :locale, :content]

  # @{not an}API Create a media track
  #
  # Create a new media track to be used as captions for different languages or deaf users. for more info, {https://developer.mozilla.org/en-US/docs/HTML/HTML_Elements/track read the MDN docs}
  #
  # @argument kind [String, "subtitles"|"captions"|"descriptions"|"chapters"|"metadata"]
  #   Default is 'subtitles'.
  #
  # @argument locale [String]
  #   Language code of the track being uploaded, examples: ["en", "es", "ru"]
  #
  # @argument content [String]
  #   The contets of the track, in SRT or WebVTT format
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
      track.update_attributes! params.slice(*TRACK_SETTABLE_ATTRIBUTES)
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
    if stale? :etag => @media_track, :last_modified => @media_track.updated_at.utc
      render :text => @media_track.content
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

end
