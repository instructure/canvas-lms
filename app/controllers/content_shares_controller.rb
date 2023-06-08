# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

# @API Content Shares
#
# API for creating, accessing and updating Content Sharing. Content shares are used
# to share content directly between users.
#
# @model ContentShare
#     {
#       "id": "ContentShare",
#       "description": "Content shared between users",
#       "properties": {
#         "id": {
#           "description": "The id of the content share for the current user",
#           "example": 1,
#           "type": "integer"
#         },
#         "name": {
#           "description": "The name of the shared content",
#           "example": "War of 1812 homework",
#           "type": "string"
#         },
#         "content_type": {
#           "description": "The type of content that was shared. Can be assignment, discussion_topic, page, quiz, module, or module_item.",
#           "example": "assignment",
#           "type": "string"
#         },
#         "created_at": {
#           "description": "The datetime the content was shared with this user.",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         },
#         "updated_at": {
#           "description": "The datetime the content was updated.",
#           "example": "2017-05-09T10:12:00Z",
#           "type": "datetime"
#         },
#         "user_id": {
#           "description": "The id of the user who sent or received the content share.",
#           "example": 1578941,
#           "type": "integer"
#         },
#         "sender": {
#           "description": "The user who shared the content. This field is provided only to receivers; it is not populated in the sender's list of sent content shares.",
#           "example": {"id": 1, "display_name": "Matilda Vargas", "avatar_image_url": "http:\/\/localhost:3000\/image_url", "html_url": "http:\/\/localhost:3000\/users\/1"},
#           "type": "object"
#         },
#         "receivers": {
#           "description": "An Array of users the content is shared with.  This field is provided only to senders; an empty array will be returned for the receiving users.",
#           "example": [{"id": 1, "display_name": "Jon Snow", "avatar_image_url": "http:\/\/localhost:3000\/image_url2", "html_url": "http:\/\/localhost:3000\/users\/2"}],
#           "type": "array",
#           "items": {"type": "object"}
#         },
#         "source_course": {
#           "description": "The course the content was originally shared from.",
#           "example": {"id": 787, "name": "History 105"},
#           "type": "object"
#         },
#         "read_state": {
#           "description": "Whether the recipient has viewed the content share.",
#           "example": "read",
#           "type": "string"
#         },
#         "content_export": {
#           "description": "The content export record associated with this content share",
#           "example": {"id": 42},
#           "$ref": "ContentExport"
#         }
#       }
#     }
#
class ContentSharesController < ApplicationController
  include ContentExportApiHelper
  include Api::V1::ContentShare

  before_action :require_user
  before_action :get_user_param
  before_action :require_current_user, except: %w[show index unread_count]
  before_action :get_receivers, only: %w[create add_users]

  def get_user_param
    @user = api_find(User, params[:user_id])
  end

  def require_current_user
    render json: { message: "You cannot create or modify other users' content shares" }, status: :forbidden unless @user == @current_user
  end

  # @API Create a content share
  # Share content directly between two or more users
  #
  # @argument receiver_ids [Required, Array]
  #   IDs of users to share the content with.
  #
  # @argument content_type [Required, String, "assignment"|"discussion_topic"|"page"|"quiz"|"module"|"module_item"]
  #   Type of content you are sharing.
  #
  # @argument content_id [Required, Integer]
  #   The id of the content that you are sharing
  #
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/content_shares \
  #         -d 'content_type=assignment' \
  #         -d 'content_id=1' \
  #         -H 'Authorization: Bearer <token>' \
  #         -X POST
  #
  # @returns ContentShare
  def create
    create_params = params.permit(:content_type, :content_id)
    allowed_types = %w[assignment attachment discussion_topic page quiz module module_item]
    unless create_params[:content_type] && create_params[:content_id]
      return render(json: { message: "Content type and id required" }, status: :bad_request)
    end
    unless allowed_types.include?(create_params[:content_type])
      return render(json: { message: "Content type not allowed. Allowed types: #{allowed_types.join(",")}" }, status: :bad_request)
    end

    content_type = ContentShare::TYPE_TO_CLASS[create_params[:content_type]]
    content = content_type&.where(id: create_params[:content_id])
    content = if content_type.respond_to? :not_deleted
                content&.not_deleted
              elsif content_type.respond_to? :active
                content&.active
              end
    content = content&.where(tag_type: "context_module") if content_type == ContentTag
    content = content&.take
    return render(json: { message: "Requested share content not found" }, status: :bad_request) unless content

    export_params = ActionController::Parameters.new(skip_notifications: true,
                                                     select: { create_params[:content_type].pluralize => [create_params[:content_id]] },
                                                     export_type: ContentExport::COMMON_CARTRIDGE)
    export = create_content_export_from_api(export_params, content.context, @current_user)
    return unless export.instance_of?(ContentExport)
    return render(json: { message: "Unable to export content" }, status: :bad_request) unless export.id

    name = Context.asset_name(content)
    sender_share = @current_user.sent_content_shares.create(content_export: export, name:, read_state: "read")
    create_receiver_shares(sender_share, @receivers)
    render json: content_share_json(sender_share, @current_user, session), status: :created
  end

  # @API List content shares
  # Return a paginated list of content shares a user has sent or received. Use +self+ as the user_id
  # to retrieve your own content shares. Only linked observers and administrators may view other users'
  # content shares.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/content_shares/received'
  #
  # @returns [ContentShare]
  def index
    if authorized_action(@user, @current_user, :read)
      if params[:list] == "received"
        shares = Api.paginate(@user.received_content_shares.by_date, self, api_v1_user_received_content_shares_url)
        render json: received_content_shares_json(shares, @current_user, session)
      else
        shares = Api.paginate(@user.sent_content_shares.by_date, self, api_v1_user_sent_content_shares_url)
        render json: sent_content_shares_json(shares, @current_user, session)
      end
    end
  end

  # @API Get unread shares count
  # Return the number of content shares a user has received that have not yet been read. Use +self+ as the user_id
  # to retrieve your own content shares. Only linked observers and administrators may view other users'
  # content shares.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/content_shares/unread_count'
  #
  # @returns { "unread_count": "integer" }
  def unread_count
    if authorized_action(@user, @current_user, :read)
      unread_shares = @user.received_content_shares.where(read_state: "unread")
      render json: { unread_count: unread_shares.count }
    end
  end

  # @API Get content share
  # Return information about a single content share. You may use +self+ as the user_id to retrieve your own content share.
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/users/self/content_shares/123'
  #
  # @returns ContentShare
  def show
    if authorized_action(@user, @current_user, :read)
      @content_share = @user.content_shares.find(params[:id])
      render json: content_share_json(@content_share, @current_user, session)
    end
  end

  # @API Remove content share
  # Remove a content share from your list. Use +self+ as the user_id. Note that this endpoint does not delete other users'
  # copies of the content share.
  #
  # @example_request
  #
  #   curl -X DELETE 'https://<canvas>/api/v1/users/self/content_shares/123'
  def destroy
    @content_share = @current_user.content_shares.find(params[:id])
    @content_share.destroy
    render json: { message: "content share deleted" }
  end

  # @API Add users to content share
  # Send a previously created content share to additional users
  #
  # @argument receiver_ids [Array]
  #   IDs of users to share the content with.
  #
  # @example_request
  #
  #   curl -X POST 'https://<canvas>/api/v1/users/self/content_shares/123/add_users?receiver_ids[]=789'
  #
  # @returns ContentShare
  def add_users
    @content_share = @current_user.content_shares.find(params[:id])
    reject!("Content share not owned by you") unless @content_share.is_a?(SentContentShare)

    create_receiver_shares(@content_share, @receivers - @content_share.receivers)
    @content_share.reload
    render json: content_share_json(@content_share, @current_user, session)
  end

  # @API Update a content share
  # Mark a content share read or unread
  #
  # @argument read_state [String, "read"|"unread"]
  #   Read state for the content share
  #
  # @example_request
  #
  #   curl -X PUT 'https://<canvas>/api/v1/users/self/content_shares/123?read_state=read'
  #
  # @returns ContentShare
  def update
    @content_share = @current_user.content_shares.find(params[:id])
    update_params = params.permit(:read_state)
    if @content_share.update(update_params)
      render json: content_share_json(@content_share, @current_user, session)
    else
      render json: @content_share.errors.to_json, status: :bad_request
    end
  end

  private

  def get_receivers
    receiver_ids = params.require(:receiver_ids)
    @receivers = api_find_all(User, Array(receiver_ids))

    unless @receivers.any?
      render(json: { message: "No valid receiving users found" }, status: :bad_request)
      false
    end

    # TODO: verify we're allowed to send content to these users, once we decide how to do that
  end

  def create_receiver_shares(sender_share, receivers)
    receivers.each do |receiver|
      sender_share.clone_for(receiver)
    end
  end
end
