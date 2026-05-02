# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module AccessibilityChecker
  module WikiPage
    def converted_paragraph
      f(".show-content p")
    end

    def heading_present?(level)
      element_exists?(".show-content h#{level}")
    end

    def body_heading_present?(level, text)
      fj(".show-content h#{level}:contains('#{text}')").displayed?
    rescue
      false
    end

    def content_list_items(tag)
      ff(".show-content #{tag} li")
    end

    def content_links
      ff(".show-content a")
    end

    def content_link
      f(".show-content a")
    end

    def content_image_alt_text
      f(".show-content img").attribute("alt")
    end

    def table_caption_text
      f(".show-content table caption").text
    end

    def table_first_row_all_headers?
      !element_exists?(".show-content table tr:first-child td")
    end

    def table_first_column_all_headers?
      !element_exists?(".show-content table tr td:first-child")
    end

    def table_header_scope
      f(".show-content table th").attribute("scope")
    end

    def text_color_style
      f(".show-content span[style]").attribute("style")
    end
  end
end
