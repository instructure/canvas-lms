#
# Copyright (C) 2016 Instructure, Inc.
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
        rest.start_with?('/preview')
      end
    end

    class ProcessedUrl
      include Rails.application.routes.url_helpers

      def initialize(match:, attachment:, is_public: false, in_app: false)
        @match = match
        @attachment = attachment
        @is_public = is_public
        @in_app = in_app
      end

      def url
        send(path, *args)
      end

      private
      attr_reader :match, :attachment, :is_public, :in_app

      # Returns either:
      #
      # [ attachment.id, url_options ]
      #
      # or:
      #
      # [ attachment.context_id, attachment.id, url_options ]
      def args
        [ attachment.id, options ].tap do |a|
          if Attachment.relative_context?(attachment.context_type)
            a.unshift(attachment.context_id)
          end
        end
      end

      def options
        { only_path: true }.tap do |h|
          h[:download] = 1 unless match.preview?
          h[:verifier] = attachment.uuid unless in_app && !is_public
          if !match.preview? && match.rest.include?('wrap=1')
            h[:wrap] = 1
          end
        end
      end

      def path
        if Attachment.relative_context?(attachment.context_type)
          if match.preview?
            "#{attachment.context_type.downcase}_file_preview_url"
          else
            "#{attachment.context_type.downcase}_file_download_url"
          end
        else
          "file_download_url"
        end
      end
    end

    def initialize(match:, context:, user:, preloaded_attachments: {}, is_public: false, in_app: false)
      @match = UriMatch.new(match)
      @context = context
      @user = user
      @preloaded_attachments = preloaded_attachments
      @is_public = is_public
      @in_app = in_app
    end

    def processed_url
      return unless attachment.present?

      if user_can_access_attachment?
        ProcessedUrl.new(match: match, attachment: attachment, is_public: is_public, in_app: in_app).url
      elsif attachment.previewable_media? && match.url.present?
        uri = URI.parse(match.url)
        uri.query = (uri.query.to_s.split("&") + ["no_preview=1"]).join("&")
        uri.to_s
      end
    end

    private
    attr_reader :match, :context, :user, :preloaded_attachments, :is_public, :in_app

    def attachment
      return nil unless match.obj_id
      unless @_attachment
        @_attachment = preloaded_attachments[match.obj_id]
        @_attachment ||= Attachment.find_by_id(match.obj_id) if context.is_a?(User) || context.nil?
        @_attachment ||= context.attachments.find_by_id(match.obj_id)
      end
      @_attachment
    end

    def user_can_access_attachment?
      attachment && !attachment.deleted? && (user_can_view_attachment? || user_can_download_attachment?)
    end

    def user_can_download_attachment?
      # checking on the context first can improve performance when checking many attachments for admins
      (context && context.grants_any_right?(user, :manage_files, :read_as_admin)) ||
        attachment.grants_right?(user, nil, :download)
    end

    def user_can_view_attachment?
      is_public && !attachment.locked_for?(user)
    end
  end
end
