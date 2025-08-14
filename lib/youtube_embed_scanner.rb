# frozen_string_literal: true

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

require "nokogiri"

class YoutubeEmbedScanner
  YOUTUBE_EMBED = "youtube.com/embed/"
  YOUTUBE_NOCOOKIE_EMBED = "youtube-nocookie.com/embed/"

  def self.embeds_from_html(html_string)
    return [] if html_string.blank?

    doc = Nokogiri::HTML5(html_string, nil, **CanvasSanitize::SANITIZE[:parser_options])

    doc.search("iframe").filter_map do |iframe_node|
      src = iframe_node["src"]
      if src && (src.include?(YOUTUBE_NOCOOKIE_EMBED) || src.include?(YOUTUBE_EMBED))
        {
          path: iframe_node.path,
          src:,
          width: iframe_node["width"],
          height: iframe_node["height"]
        }
      end
    end
  end
end
