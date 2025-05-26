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
    class UriMatch < SimpleDelegator
      def preview?
        rest.start_with?("/preview")
      end

      def download?
        rest.start_with?("/download")
      end

      def download_frd?
        rest.include?("download_frd=1")
      end

      def with_verifier?
        rest.include?("verifier=")
      end

      def media_iframe_url?
        url.start_with?("/media_attachments_iframe")
      end
    end

    class ProcessedUrl
      include Rails.application.routes.url_helpers

      def initialize(match:, attachment:, is_public: false, in_app: false, no_verifiers: false, location: nil)
        @match = match
        @attachment = attachment
        @is_public = is_public
        @in_app = in_app
        @no_verifiers = no_verifiers
        @location = location
      end

      def url
        send(path, *args)
      end

      private

      attr_reader :match, :attachment, :is_public, :in_app, :no_verifiers, :location

      # Returns either:
      #
      # [ attachment.id, url_options ]
      #
      # or:
      #
      # [ attachment.context_id, attachment.id, url_options ]
      def args
        [attachment.id, options].tap do |a|
          if Attachment.relative_context?(attachment.context_type) && !match.media_iframe_url?
            a.unshift(attachment.context_id)
          end
        end
      end

      def options
        { only_path: true }.tap do |h|
          h[:download] = 1 if match.download_frd?
          unless attachment.root_account.feature_enabled?(:disable_adding_uuid_verifier_in_api)
            h[:verifier] = attachment.uuid unless (in_app && !is_public && !match.with_verifier?) || no_verifiers || location
          end
          h[:location] = location if location
          if !match.preview? && match.rest.include?("wrap=1")
            h[:wrap] = 1
          end
        end
      end

      def path
        if Attachment.relative_context?(attachment.context_type)
          if match.preview?
            "#{attachment.context_type.downcase}_file_preview_url"
          elsif match.download? || match.download_frd?
            "#{attachment.context_type.downcase}_file_download_url"
          elsif match.media_iframe_url?
            "media_attachment_iframe_url"
          else
            "#{attachment.context_type.downcase}_file_url"
          end
        else
          "file_download_url"
        end
      end
    end

    def initialize(match:, context:, user:, preloaded_attachments: {}, is_public: false, in_app: false, no_verifiers: false, location: nil)
      @match = UriMatch.new(match)
      @context = context
      @user = user
      @preloaded_attachments = preloaded_attachments
      @is_public = is_public
      @in_app = in_app
      @no_verifiers = no_verifiers
      @location = location
    end

    def processed_url
      return unless attachment.present?

      if user_can_access_attachment?
        ProcessedUrl.new(match:, attachment:, is_public:, in_app:, no_verifiers:, location:).url
      else
        # Setting is_public: false and in_app: true to force never adding verifier query param
        processed_url = ProcessedUrl.new(match:, attachment:, is_public: false, in_app: true, no_verifiers:, location:).url
        begin
          uri = URI.parse(processed_url)
        rescue URI::InvalidURIError
          uri = URI.parse(Addressable::URI.escape(processed_url))
        end
        if attachment.previewable_media? && match.url.present?
          uri.query = (uri.query.to_s.split("&") + ["no_preview=1"]).join("&")
        elsif attachment.locked_for?(user) && attachment.content_type =~ /^image/
          # hidden=1 tells the browser to strip the alt attribute for locked files
          uri.query = (uri.query.to_s.split("&") + ["hidden=1"]).join("&")
        end
        uri.to_s
      end
    end

    private

    attr_reader :match, :context, :user, :preloaded_attachments, :is_public, :in_app, :no_verifiers, :location

    def attachment
      return nil unless match.obj_id

      unless @_attachment
        @_attachment = preloaded_attachments[match.obj_id] unless preloaded_attachments[match.obj_id]&.replacement_attachment_id
        @_attachment ||= Attachment.find_by(id: match.obj_id) if context.is_a?(User) || context.nil? || location.present?
        @_attachment ||= context.attachments.find_by(id: match.obj_id)
      end
      @_attachment
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
      (is_public || (user && attachment.context.respond_to?(:is_public_to_auth_users?) && attachment.context.is_public_to_auth_users?)) && !attachment.locked_for?(user)
    end
  end
end
