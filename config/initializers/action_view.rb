# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

if Rails.version >= "6.1" && Rails.version < "7.0"
  # From https://github.com/rails/rails/pull/42056/files
  module SaferPreloadLinksHeader
    MAX_HEADER_SIZE = 8_000 # Some HTTP client and proxies have a 8kiB header limit

    def send_preload_links_header(preload_links, max_header_size: MAX_HEADER_SIZE)
      if respond_to?(:request) && request
        request.send_early_hints("Link" => preload_links.join("\n"))
      end

      # INST: add `&& !response.sending?` to support template streaming
      if respond_to?(:response) && response && !response.sending?
        header = response.headers["Link"]
        header = header ? header.dup : +""

        # rindex count characters not bytes, but we assume non-ascii characters
        # are rare in urls, and we have a 192 bytes margin.
        last_line_offset = header.rindex("\n")
        last_line_size = if last_line_offset
                           header.bytesize - last_line_offset
                         else
                           header.bytesize
                         end

        preload_links.each do |link|
          if link.bytesize + last_line_size + 1 < max_header_size
            unless header.empty?
              header << ","
              last_line_size += 1
            end
          else
            header << "\n"
            last_line_size = 0
          end
          header << link
          last_line_size += link.bytesize
        end

        response.headers["Link"] = header
      end
    end
  end

  # Directly put it in ActionView::Base in case that has already been loaded
  ActionView::Helpers::AssetTagHelper.prepend(SaferPreloadLinksHeader)
  ActionView::Base.prepend(SaferPreloadLinksHeader)
end
