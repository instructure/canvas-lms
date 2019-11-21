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

# @API Media Objects
#
# When you upload or record webcam video/audio to kaltura, it makes a Media Object
#
# @object MediaObject
#   {
#     // whether or not the current user can upload media_tracks (subtitles) to this Media Object
#     "can_add_captions": true,
#     "user_entered_title": "User Entered Title",
#     "title": "filename-or-user-title-or-untitled",
#     "media_id": "m-JYmy6TLsHkxcrhgYmqa7XW1HCH3wEYc",
#     "media_type": "video",
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

  before_action :load_media_object, :except => [:index, :update_media_object]
  before_action :require_user, :except => [:show]

  # @{not an}API Show Media Object Details
  # This isn't an API because it needs to work for non-logged in users (video in public course)
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
  # Returns Media Objects created by the user making the request. When
  # using the second version, returns
  # only those Media Objects associated with the given course.
  #
  # @argument sort [String, "title"|"created_at"]
  #   Field to sort on. Default is "title"
  #
  #   title:: sorts on user_entered_title if available, title if not.
  #
  #   created_at:: sorts on the object's creation time.
  # @argument order [String, "asc"|"desc"]
  #   Sort direction. Default is "asc"
  #
  # @argument exclude[] [String, "sources"|"tracks"]
  #   Array of data to exclude. By excluding "sources" and "tracks",
  #   the api will not need to query kaltura, which greatly
  #   speeds up its response.
  #
  #   sources:: Do not query kaltura for media_sources
  #   tracks:: Do not query kaltura for media_tracks
  #
  # @example_request
  #     curl https://<canvas>/api/v1/media_objects?exclude[]=sources&exclude[]=tracks \
  #          -H 'Authorization: Bearer <token>'
  #
  #     curl https://<canvas>/api/v1/courses/17/media_objects?exclude[]=sources&exclude[]=tracks \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [MediaObject]
  def index
    if params[:course_id]
      context = Course.find(params[:course_id])
    end

    where_hash = {user: @current_user}
    where_hash[:context] = context if context

    order_dir = params[:order] == "desc" ? "desc" : "asc"
    order_by = params[:sort] || "title"
    order_by = MediaObject.best_unicode_collation_key('COALESCE(user_entered_title, title)') if order_by == "title"
    order_clause = {
      order_by => order_dir
    }

    exclude = params[:exclude] || []
    media_objects = Api.paginate(MediaObject.where(where_hash).active.order(order_clause), self, api_v1_media_objects_url).
      map{ |mo| media_object_api_json(mo, @current_user, session, exclude)}
    render :json => media_objects
  end

  # @API Update Media Object
  #
  # @argument user_entered_title [String] The new title.
  #
  def update_media_object
    if params[:media_object_id]
      @media_object = MediaObject.by_media_id(params[:media_object_id]).first

      return render_unauthorized_action unless @media_object
      return render_unauthorized_action unless @current_user&.id
      # media objects don't have any permissions associated with them,
      # so we just check that this is the user's media
      return render_unauthorized_action unless @media_object.user_id == @current_user.id
      return render json: {message: "The user_entered_title parameter must have a value"}, status: :bad_request if params[:user_entered_title].blank?

      self.extend TextHelper
      @media_object.user_entered_title = CanvasTextHelper.truncate_text(params[:user_entered_title], :max_length => 255)
      @media_object.save!
      render :json => media_object_api_json(@media_object, @current_user, session, ["sources", "tracks"])
    end
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
