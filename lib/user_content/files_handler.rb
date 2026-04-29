# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

module UserContent
  class FilesHandler
    def initialize(match:, context:, user:, preloaded_attachments: {}, is_public: false, in_app: false, no_verifiers: false, location: nil)
      @match = match
      @context = context
      @user = user
      @preloaded_attachments = preloaded_attachments
      @is_public = is_public
      @in_app = in_app
      @no_verifiers = no_verifiers
      @location = location
    end

    def processed_url
      uri = Addressable::URI.parse(match.url.gsub("&amp;", "&"))
      uri = replace_with_current_attachment(uri)
      return unless attachment.present?

      query_values = uri.query_values || {}

      if location.nil?
        query_values.delete(:location)
      else
        query_values[:location] = location
      end

      unless user_can_access_attachment?
        @no_verifiers = true
        if attachment.previewable_media?
          query_values[:no_preview] = 1
        elsif /^image/.match?(attachment.content_type)
          query_values[:hidden] = 1
        end
      end
      unless @no_verifiers || location
        query_values[:verifier] = attachment.uuid if is_public || (!in_app && !attachment.root_account.feature_enabled?(:disable_adding_uuid_verifier_in_api))
      end
      uri.query_values = query_values unless query_values.blank?
      uri.to_s
    end

    private

    attr_reader :match, :context, :user, :preloaded_attachments, :is_public, :in_app, :no_verifiers, :location, :attachment

    def replace_with_current_attachment(uri)
      return uri unless match.obj_id

      uri_shard = uri.host.present? ? LoadAccount.infer_shard(uri.host) : Shard.current
      if uri_shard == Shard.current
        @attachment = if preloaded_attachments[match.obj_id]&.replacement_attachment_id
                        preloaded_attachments[preloaded_attachments[match.obj_id].replacement_attachment_id]
                      else
                        preloaded_attachments[match.obj_id]
                      end
      end
      uri_shard.activate do
        # NOTE: Attachment#find has special logic to find overwritten files; see FindInContextAssociation
        @attachment ||= if match.context_type && match.context_id && (file_context = match.context_type.classify.constantize.find_by(id: match.context_id)) && file_context.respond_to?(:attachments)
                          file_context&.attachments&.find_by(id: match.obj_id)
                        else
                          att = Attachment.find_by(id: match.obj_id)
                          att = att.context.attachments.find_by(id: match.obj_id) if att&.context.respond_to?(:attachments)
                          att
                        end
        return uri unless @attachment

        if match.obj_id != @attachment.id
          uri.path = uri.path.gsub(%r{/(files|media_attachments_iframe)/#{match.obj_id}/}, "/\\1/#{@attachment.id}/")
        end
      end
      uri
    end

    def user_can_access_attachment?
      attachment && !attachment.deleted? && (user_can_view_attachment? || user_can_download_attachment?)
    end

    def user_can_download_attachment?
      # checking on the context first can improve performance when checking many attachments for admins
      context&.grants_any_right?(
        user,
        :read_as_admin,
        *RoleOverride::GRANULAR_FILE_PERMISSIONS
      ) || attachment&.grants_right?(user, nil, :download)
    end

    def user_can_view_attachment?
      (is_public || (user && attachment.context.try(:is_public_to_auth_users?))) && !attachment.locked_for?(user)
    end
  end
end
