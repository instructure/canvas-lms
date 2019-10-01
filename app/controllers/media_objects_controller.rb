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

# This isn't an API because it needs to work for non-logged in users (video in public course)
# API Media Objects
#
# When you upload or record webcam video/audio to kaltura, it makes a Media Object
#
# @object MediaObject
#   {
#     // whether or not the current user can upload media_tracks (subtitles) to this Media Object
#     "can_add_captions": true,
#     // an array of all the media_tracks uploaded to this Media Object
#     "media_tracks": [{
#       "kind": "captions",
#       "created_at": "2012-09-27T16:46:50-06:00",
#       "updated_at": "2012-09-27T16:46:50-06:00",
#       "url": "https://<canvas>/media_objects/0_r949z9lk/media_tracks/1",
#       "id": 1,
#       "locale": "af"
#     }, {
#       "kind": "subtitles",
#       "created_at": "2012-09-27T20:29:17-06:00",
#       "updated_at": "2012-09-27T20:29:17-06:00",
#       "url": "https://<canvas>/media_objects/0_r949z9lk/media_tracks/14",
#       "id": 14,
#       "locale": "cs"
#     }],
#     // an array of all the transcoded files (flavors) available for this Media Object
#     "media_sources": [{
#       "height": "240",
#       "width": "336",
#       "content_type": "video/mp4",
#       "containerFormat": "isom",
#       "url": "http://example.com/p/100/sp/10000/download/entry_id/0_r949z9lk/flavor/0_xdp3qrpc/ks/MjUxNjY4MjlhMTkxN2VmNTA0OGRkZjY2ODNjMjgxNTkwYWE3NGMyNHwxMDA7MTAwOzEzNDkyNzU5MDY7MDsxMzQ5MTg5NTA2LjUxOTk7O2Rvd25sb2FkOjBfcjk0OXo5bGs7/relocate/download.mp4",
#       "bitrate": "382",
#       "size": "204",
#       "isOriginal": "0",
#       "fileExt": "mp4"
#     }, {
#       "height": "252",
#       "width": "336",
#       "content_type": "video/x-flv",
#       "containerFormat": "flash video",
#       "url": "http://example.com/p/100/sp/10000/download/entry_id/0_r949z9lk/flavor/0_0f2x4odx/ks/NmY2M2Q2MDdhMjBlMzA2ZmRhMWZjZjAxNWUyOTg0MzA5MDI5NGE4ZXwxMDA7MTAwOzEzNDkyNzU5MDY7MDsxMzQ5MTg5NTA2LjI5MDM7O2Rvd25sb2FkOjBfcjk0OXo5bGs7/relocate/download.flv",
#       "bitrate": "797",
#       "size": "347",
#       "isOriginal": "1",
#       "fileExt": "flv"
#     }]
#   }
#
class MediaObjectsController < ApplicationController
  include Api::V1::MediaObject

  before_action :load_media_object, :except => [:index]
  before_action :require_user, :only => [:index]

  # @{not an}API Show Media Object Details
  #
  # Returns the Details of the given Media Object.
  #
  # @example_request
  #     curl https://<canvas>/media_objects/<media_object_id> \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns MediaObject
  def show
    render :json => media_object_api_json(@media_object, @current_user, session)
  end

  # @API List Media Objects
  #
  # Returns all Media Objects Created by the user making the request.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/media_objects \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [MediaObject]
  def index
    media_objects = Api.paginate(MediaObject.where(user: @current_user).active, self, api_v1_media_objects_url).
      map{ |mo| media_object_api_json(mo, @current_user, session)}
    render :json => media_objects
  end

  def iframe_media_player
    js_env media_object: media_object_api_json(@media_object, @current_user, session)
    js_bundle :media_player_iframe_content
    render html: "<div><div>#{I18n.t('Loading...')}</div></div>".html_safe, layout: 'layouts/bare'
  end

  private

  def load_media_object
    @media_object = MediaObject.by_media_id(params[:media_object_id]).first
    unless @media_object
      # Unfortunately, we don't have media_object entities created for everything,
      # so we use this opportunity to create the object if it does not exist.
      @media_object = MediaObject.create_if_id_exists(params[:media_object_id])
      @media_object.send_later_enqueue_args(:retrieve_details, {
        :singleton => "retrieve_media_details:#{@media_object.media_id}"
      })
      increment_request_cost(Setting.get("missed_media_additional_request_cost", "200").to_i)
    end

    @media_object.viewed!
  end
end
