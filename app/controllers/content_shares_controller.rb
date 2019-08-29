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
#       "description": "Content shared between two users",
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
#           "description": "The user who shared the content. No sender information will be given for the sharing user.",
#           "example": {"id": 1, "display_name": "Matilda Vargas", "avatar_image_url": "http:\/\/localhost:3000\/image_url", "html_url": "http:\/\/localhost:3000\/users\/1"},
#           "type": "object"
#         },
#         "receivers": {
#           "description": "An Array of users the content is shared with.  An empty array will be returned for the receiving users.",
#           "example": [{"id": 1, "display_name": "Jon Snow", "avatar_image_url": "http:\/\/localhost:3000\/image_url2", "html_url": "http:\/\/localhost:3000\/users\/2"}],
#           "type": "array",
#           "items": {"type": "object"}
#         },
#         "read_state": {
#           "description": "Whether the recipient has viewed the content share.",
#           "example": "read",
#           "type": "string"
#         }
#       }
#     }
#
class ContentSharesController < ApplicationController
  include ContentExportApiHelper
  include Api::V1::ContentShare
  CONTENT_TYPES = {
    assignment: Assignment,
    discussion_topic: DiscussionTopic,
    page: WikiPage,
    quiz: Quizzes::Quiz,
    module: ContextModule,
    module_item: ContentTag,
    content_share: ContentShare
  }.freeze

  before_action :require_user
  before_action :require_direct_share_enabled

  def require_direct_share_enabled
    render json: { message: "Feature disabled" }, status: :forbidden unless @domain_root_account.feature_enabled?(:direct_share)
  end


  # @API Create a content share
  # Share content directly between two or more users
  #
  # @argument receiver_ids [Array]
  #   IDs of users to share the content with.
  #
  # @argument content_type [Required, String, "assignment"|"discussion_topic"|"page"|"quiz"|"module"|"module_item"]
  #   Type of content you are sharing.  'content_share' allows you to re-share content that is already shared.
  #
  # @argument content_id [Required, Integer]
  #   The id of the content that you are sharing
  #
  #
  # @example_request
  #
  #   curl 'https://<canvas>/api/v1/content_shares \
  #         -d 'content_type=assignment' \
  #         -d 'content_id=1' \
  #         -H 'Authorization: Bearer <token>' \
  #         -X POST
  #
  # @returns ContentShare
  #
  def create
    unless @current_user == api_find(User, params[:user_id])
      return render(json: { message: 'Cannot create content shares for other users'}, status: :forbidden)
    end
    create_params = params.permit(:content_type, :content_id, receiver_ids: [])
    allowed_types = ['assignment', 'discussion_topic', 'page', 'quiz', 'module', 'module_item']
    receivers = User.active.where(id: create_params[:receiver_ids])
    return render(json: { message: 'No valid receiving users found' }, status: :bad_request) unless receivers.any?
    unless create_params[:content_type] && create_params[:content_id]
      return render(json: { message: 'Content type and id required'}, status: :bad_request)
    end
    unless allowed_types.include?(create_params[:content_type])
      return render(json: { message: "Content type not allowed. Allowed types: #{allowed_types.join(',')}" }, status: :bad_request)
    end
    content_type = CONTENT_TYPES[create_params[:content_type]&.to_sym]
    content = content_type&.where(id: create_params[:content_id])
    content = if content_type.respond_to? :not_deleted
                content&.not_deleted
              elsif content_type.respond_to? :active
                content&.active
              end
    content = content&.where(tag_type: 'context_module') if content_type == ContentTag
    content = content&.take
    return render(json: { message: 'Requested share content not found'}, status: :bad_request) unless content

    export_params = ActionController::Parameters.new(skip_notifications: true,
      select: {create_params[:content_type].pluralize => [create_params[:content_id]]},
      export_type: ContentExport::COMMON_CARTRIDGE)
    export = create_content_export_from_api(export_params, content.context, @current_user)
    return unless export.class == ContentExport
    return render(json: { message: 'Unable to export content'}, status: :bad_request) unless export.id

    name = Context.asset_name(content)
    sender_share = @current_user.sent_content_shares.create(content_export: export, name: name, read_state: 'read')
    receivers.each do |receiver|
      receiver.received_content_shares.create(content_export: export, sender: @current_user, name: name, read_state: 'unread')
    end
    render json: content_share_json(sender_share, @current_user, session), status: :created
  end

end
