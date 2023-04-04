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

  before_action :check_attachment, except: %i[index update_media_object create_media_object]
  before_action :load_media_object, only: %i[show iframe_media_player]
  before_action :require_user, only: %i[index update_media_object]
  protect_from_forgery only: %i[create_media_object media_object_redirect media_object_inline media_object_thumbnail], with: :exception

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
    render json: media_object_api_json(@media_object, @current_user, session)
  end

  # @API List Media Objects
  #
  # Returns media objects created by the user making the request. When
  # using the second version, returns media objects associated with
  # the given course.
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
      url = api_v1_course_media_objects_url
    elsif params[:group_id]
      context = Group.find(params[:group_id])
      url = api_v1_group_media_objects_url
    end
    if context
      root_folder = Folder.root_folders(context).first

      if root_folder.grants_right?(@current_user, :read_contents)
        # if the user has access to the context's root folder, let's
        # assume they have access to the context's media, even if it's
        # media not associated with an Attachment in there
        scope = MediaObject.active.where(context: context)
      else
        return render_unauthorized_action # not allowed to view files in the context
      end
    else
      scope = MediaObject.active.where(context: @current_user)
      url = api_v1_media_objects_url
    end

    order_dir = (params[:order] == "desc") ? "desc" : "asc"
    order_by = params[:sort] || "title"
    if order_by == "title"
      order_by = MediaObject.best_unicode_collation_key("COALESCE(user_entered_title, title)")
    end
    scope = scope.order(order_by => order_dir)
    scope = MediaObject.search_by_attribute(scope, :title, params[:search_term])

    exclude = params[:exclude] || []
    media_objects =
      Api.paginate(scope, self, url).map do |mo|
        media_object_api_json(mo, @current_user, session, exclude)
      end
    render json: media_objects
  end

  # @API Update Media Object
  #
  # @argument user_entered_title [String] The new title.
  #
  def update_media_object
    # media objects don't have any permissions associated with them,
    # so we just check that this is the user's media

    if params[:media_object_id]
      @media_object = MediaObject.by_media_id(params[:media_object_id]).first

      return render_unauthorized_action unless @media_object
      return render_unauthorized_action unless @current_user&.id

      return render_unauthorized_action unless @media_object.user_id == @current_user.id

    elsif params[:attachment_id]
      attachment = Attachment.find(params[:attachment_id])

      return render_unauthorized_action unless attachment
      return render_unauthorized_action unless attachment.media_entry_id

      if params[:verifier]
        verifier_checker = Attachments::Verification.new(attachment)
        return render_unauthorized_action unless verifier_checker.valid_verifier_for_permission?(params[:verifier], :update, session)
      else
        return render_unauthorized_action unless attachment.grants_right?(@current_user, session, :update)
      end

      @media_id = attachment.media_entry_id
      @media_object = MediaObject.by_media_id(@media_id).take
    end
    if params[:user_entered_title].blank?
      return(
        render json: { message: "The user_entered_title parameter must have a value" },
               status: :bad_request
      )
    end
    extend TextHelper
    @media_object.user_entered_title =
      CanvasTextHelper.truncate_text(params[:user_entered_title], max_length: 255)
    @media_object.save!
    render json: media_object_api_json(@media_object, @current_user, session, %w[sources tracks])
  end

  def create_media_object
    @context = Context.find_by_asset_string(params[:context_code])

    if authorized_action(@context, @current_user, :read)
      if params[:id] && params[:type] && @context.respond_to?(:media_objects)
        extend TextHelper

        # The MediaObject will be created on the current shard,
        # not the @context's shard.
        @media_object = MediaObject.where(
          media_id: params[:id],
          media_type: params[:type],
          context: @context
        ).first_or_initialize

        @media_object.title = CanvasTextHelper.truncate_text(params[:title], max_length: 255) if params[:title]
        @media_object.user = @current_user
        @media_object.media_type = params[:type]
        @media_object.root_account_id = @domain_root_account.id if @domain_root_account && @media_object.respond_to?(:root_account_id)
        @media_object.user_entered_title = CanvasTextHelper.truncate_text(params[:user_entered_title], max_length: 255) if params[:user_entered_title].present?
        @media_object.save
      end
      render json: @media_object.as_json.merge(embedded_iframe_url: media_object_iframe_url(@media_object.media_id))
      # render :json => media_object_api_json(@media_object, @current_user, session, %w[sources tracks])
    end
  end

  def media_object_inline
    @show_embedded_chat = false
    @show_left_side = false
    @show_right_side = false
    @media_object = MediaObject.by_media_id(params[:id]).first
    js_env(MEDIA_OBJECT_ID: params[:id],
           MEDIA_OBJECT_TYPE: @media_object ? @media_object.media_type.to_s : "video")
    render
  end

  def media_object_redirect
    mo = MediaObject.by_media_id(params[:id]).first
    mo&.viewed!
    config = CanvasKaltura::ClientV3.config
    if config
      redirect_to CanvasKaltura::ClientV3.new.assetSwfUrl(params[:id])
    else
      render plain: t(:media_objects_not_configured, "Media Objects not configured")
    end
  end

  def media_object_thumbnail
    width = params[:width]
    height = params[:height]
    type = (params[:type].presence || 2).to_i
    config = CanvasKaltura::ClientV3.config
    if config
      redirect_to CanvasKaltura::ClientV3.new.thumbnail_url(@media_object.try(:media_id) || @media_id,
                                                            width: width,
                                                            height: height,
                                                            type: type),
                  status: :moved_permanently
    else
      render plain: t(:media_objects_not_configured, "Media Objects not configured")
    end
  end

  def iframe_media_player
    # Exclude all global includes from this page
    @exclude_account_js = true
    @embeddable = true

    js_env media_object: media_object_api_json(@media_object, @current_user, session) if @media_object
    js_bundle :media_player_iframe_content
    css_bundle :media_player
    render html: "<div id='player_container'>#{I18n.t("Loading...")}</div>".html_safe,
           layout: "layouts/bare"
  end

  private

  def load_media_object
    unless @media_object
      # Unfortunately, we don't have media_object entities created for everything,
      # so we use this opportunity to create the object if it does not exist.
      @media_object = MediaObject.create_if_id_exists(params[:media_object_id])
      raise ActiveRecord::RecordNotFound, "invalid media_object_id" unless @media_object

      @media_object.delay(singleton: "retrieve_media_details:#{@media_object.media_id}").retrieve_details
      increment_request_cost(Setting.get("missed_media_additional_request_cost", "200").to_i)
    end

    @media_object.viewed!
  end

  def check_attachment
    if params[:attachment_id].present?
      attachment = Attachment.find(params[:attachment_id])

      return render_unauthorized_action unless attachment
      return render_unauthorized_action unless attachment.media_entry_id

      if params[:verifier]
        verifier_checker = Attachments::Verification.new(attachment)
        return render_unauthorized_action unless verifier_checker.valid_verifier_for_permission?(params[:verifier], :read, session)
      else
        return render_unauthorized_action unless attachment.grants_right?(@current_user, session, :read)
      end

      @media_id = attachment.media_entry_id
      @media_object = MediaObject.by_media_id(@media_id).take

    elsif params[:media_object_id].present?
      @media_id = params[:media_object_id]
      @media_object = MediaObject.by_media_id(params[:media_object_id]).take

    else
      nil
    end
  end
end
