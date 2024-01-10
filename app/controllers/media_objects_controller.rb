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
  include FilesHelper

  MISSED_MEDIA_ADDITIONAL_COST = 200

  before_action :load_media_object, except: %i[create_media_object index]
  before_action :load_media_object_from_service, only: %i[show iframe_media_player]
  before_action :check_media_permissions, except: %i[create_media_object index media_object_thumbnail update_media_object]
  before_action(only: %i[update_media_object]) { check_media_permissions(access_type: :update) }
  before_action :require_user, only: %i[index update_media_object]
  protect_from_forgery only: %i[create_media_object media_object_redirect media_object_inline media_object_thumbnail], with: :exception

  # @{not an}API Show Media Object Details
  # This isn't an API because it needs to work for non-logged in users (video in public course)
  #
  # Returns the Details of the given Media Object.
  #
  # @example_request
  #     curl https://<canvas>/media_objects/<media_object_id>/info \
  #          -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #     curl https://<canvas>/media_attachments/<attachment_id>/info \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns MediaObject
  def show
    if Account.site_admin.feature_enabled?(:media_links_use_attachment_id) && @attachment
      render json: media_attachment_api_json(@attachment, @media_object, @current_user, session)
    else
      render json: media_object_api_json(@media_object, @current_user, session)
    end
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
    media_attachment = Account.site_admin.feature_enabled?(:media_links_use_attachment_id)
    url = if params[:course_id]
            context = Course.find(params[:course_id])
            media_attachment ? api_v1_course_media_attachments_url : api_v1_course_media_objects_url
          elsif params[:group_id]
            context = Group.find(params[:group_id])
            media_attachment ? api_v1_group_media_attachments_url : api_v1_group_media_objects_url
          else
            media_attachment ? api_v1_media_attachments_url : api_v1_media_objects_url
          end
    scope = if context
              root_folder = Folder.root_folders(context).first

              if root_folder.grants_right?(@current_user, :read_contents)
                if media_attachment
                  attachment_scope = Attachment.not_deleted.is_media_object.where(context:)
                  attachment_scope = attachment_scope.select { |att| access_allowed(att, @current_user, :download) }

                  MediaObject.by_media_id(attachment_scope.pluck(:media_entry_id))
                else
                  MediaObject.active.where(context:)
                end
              else
                render_unauthorized_action # not allowed to view files in the context
              end
            elsif media_attachment
              attachment_scope = Attachment.not_deleted.is_media_object.where(context: @current_user)
              MediaObject.by_media_id(attachment_scope.pluck(:media_entry_id))
            else
              MediaObject.active.where(context: @current_user)
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
    # so we just check that this is the user's media unless the media
    # is linked by attachment
    if params[:media_object_id]
      return render_unauthorized_action unless @current_user&.id
      return render_unauthorized_action unless @media_object.user_id == @current_user.id
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
      media_object_json = @media_object.as_json
      if Account.site_admin.feature_enabled?(:media_links_use_attachment_id)
        embedded_iframe_url = media_attachment_iframe_url(@media_object.attachment_id)
        media_object_json["media_object"]["uuid"] = @media_object.attachment.uuid
      else
        embedded_iframe_url = media_object_iframe_url(@media_object.media_id)
      end
      render json: media_object_json.merge(embedded_iframe_url:)
    end
  end

  def media_object_inline
    @show_embedded_chat = false
    @show_left_side = false
    @show_right_side = false
    js_env(MEDIA_OBJECT_ID: params[:id],
           MEDIA_OBJECT_TYPE: @media_object ? @media_object.media_type.to_s : "video")
    render
  end

  def media_object_redirect
    @media_object&.viewed!
    config = CanvasKaltura::ClientV3.config
    if config
      if Account.site_admin.feature_enabled?(:authenticated_iframe_content)
        begin
          media_source = @media_object.media_sources.find { |ms| ms[:bitrate].to_s == params[:bitrate].to_s } || @media_object.media_sources.min_by { |ms| ms[:bitrate]&.to_i }
          url = media_source[:url]
          # keep track of the redirects and use the last one
          redirect_spy = ->(res) { url = res.header["location"] }
          CanvasHttp.get(url, redirect_spy:) do |res|
            raise CanvasHttp::InvalidResponseCodeError, res.code.to_i unless /^2/.match?(res.code.to_s)

            # don't load body
          end
          redirect_to url
        rescue CanvasHttp::InvalidResponseCodeError => e
          render plain: e.message, status: e.code
        rescue Errno::ECONNREFUSED, CanvasHttp::Error => e
          render plain: e.message, status: :bad_request
        end
      else
        redirect_to CanvasKaltura::ClientV3.new.assetSwfUrl(params[:id])
      end
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
                                                            width:,
                                                            height:,
                                                            type:),
                  status: :moved_permanently
    else
      render plain: t(:media_objects_not_configured, "Media Objects not configured")
    end
  end

  def iframe_media_player
    if !Account.site_admin.feature_enabled?(:media_links_use_attachment_id) && @attachment
      return redirect_to(media_object_iframe_path(@media_object.media_id, params: request.query_parameters))
    end

    # Exclude all global includes from this page
    @exclude_account_js = true
    @embeddable = true

    media_api_json = if @attachment && @media_object
                       media_attachment_api_json(@attachment, @media_object, @current_user, session, verifier: params[:verifier])
                     elsif @media_object
                       media_object_api_json(@media_object, @current_user, session)
                     end

    js_env media_object: media_api_json if media_api_json
    js_env attachment: !!@attachment
    js_env attachment_id: @attachment.id if Account.site_admin.feature_enabled?(:media_links_use_attachment_id) && @attachment
    js_bundle :media_player_iframe_content
    css_bundle :media_player
    render html: "<div id='player_container'>#{I18n.t("Loading...")}</div>".html_safe,
           layout: "layouts/bare"
  end

  private

  def load_media_object_from_service
    return unless params[:media_object_id].present?

    unless @media_object
      # Unfortunately, we don't have media_object entities created for everything,
      # so we use this opportunity to create the object if it does not exist.
      @media_object = MediaObject.create_if_id_exists(params[:media_object_id])
      raise ActiveRecord::RecordNotFound, "invalid media_object_id" unless @media_object

      @media_object.delay(singleton: "retrieve_media_details:#{@media_object.media_id}").retrieve_details
      increment_request_cost(MISSED_MEDIA_ADDITIONAL_COST)
    end

    @media_object.viewed!
  end
end
