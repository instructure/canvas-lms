#
# Copyright (C) 2014 Instructure, Inc.
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

module Api
  module Html
    class Link
      attr_reader :link
      def initialize(link_string)
        @link = link_string
      end

      def to_corrected_s
        return link if is_not_actually_a_link? || should_skip_correction?
        strip_verifier_params(scope_link_to_context(link))
      end

      private

      APPLICABLE_CONTEXT_TYPES = ["Course", "Group", "Account"]
      SKIP_CONTEXT_TYPES = ["User"]
      LINK_REGEX = %r{/files/(\d+)/(?:download|preview)}
      VERIFIER_REGEX = %r{(\?)verifier=[^&]*&?|&verifier=[^&]*}

      def strip_verifier_params(local_link)
        if local_link.include?('verifier=')
          return local_link.gsub(VERIFIER_REGEX, '\1')
        end

        local_link
      end

      def scope_link_to_context(local_link)
        if local_link.start_with?('/files')
          if attachment && APPLICABLE_CONTEXT_TYPES.include?(attachment.context_type)
            return "/#{attachment.context_type.underscore.pluralize}/#{attachment.context_id}" + local_link
          end
        end

        local_link
      end

      def should_skip_correction?
        attachment && SKIP_CONTEXT_TYPES.include?(attachment.context_type)
      end

      def is_not_actually_a_link?
        !(link =~ LINK_REGEX)
      end

      def attachment
        return @_attachment unless @_attachment.nil?
        @_attachment = Attachment.where(id: attachment_id).first
      end

      def attachment_id
        match = link.match(LINK_REGEX)
        return nil unless match
        match.captures[0]
      end

    end
  end
end
