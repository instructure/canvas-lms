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

require 'uri'

module Api
  module Html
    class Link
      attr_reader :link
      def initialize(link_string, host: nil, port: nil)
        @link, @host, @port = link_string, host, port
      end

      def to_corrected_s
        local_link = strip_host(link)
        return local_link if is_not_actually_a_file_link? || should_skip_correction?
        strip_verifier_params(scope_link_to_context(local_link))
      end

      private

      APPLICABLE_CONTEXT_TYPES = ["Course", "Group", "Account"]
      SKIP_CONTEXT_TYPES = ["User"]
      FILE_LINK_REGEX = %r{/files/(\d+)/(?:download|preview)}
      VERIFIER_REGEX = %r{(\?)verifier=[^&]*&?|&verifier=[^&]*}

      def strip_host(link)
        return link if @host.nil?
        begin
          uri = URI.parse(link)
          if uri.host == @host && (uri.port.nil? || uri.port == @port)
            fragment = "##{uri.fragment}" if uri.fragment
            "#{uri.request_uri}#{fragment}"
          else
            link
          end
        rescue URI::InvalidURIError
          link
        end
      end

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

      def is_not_actually_a_file_link?
        !(link =~ FILE_LINK_REGEX)
      end

      def attachment
        return @_attachment unless @_attachment.nil?
        @_attachment = Attachment.where(id: attachment_id).first
      end

      def attachment_id
        match = link.match(FILE_LINK_REGEX)
        return nil unless match
        match.captures[0]
      end

    end
  end
end
