# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module AtomFeedHelper
  ALLOWED_ENTRY_KEYS = %i[title author updated published id link content attachment_links].freeze

  def self.render_xml(title:, link:, entries:, updated: nil, id: nil, **kwargs)
    require "rss/maker"

    content = RSS::Maker.make("atom") do |maker|
      maker.channel.author = "canvas-lms"
      maker.channel.updated = updated ? updated.to_s : Time.now.to_s
      maker.channel.about = id || link
      maker.channel.title = title
      maker.channel.links.new_link do |rss_link|
        rss_link.href = link
        rss_link.rel = "self"
      end

      entries.each do |e|
        hash = if block_given?
                 e.to_atom(**yield(e))
               else
                 e.to_atom(**kwargs)
               end

        raise "unknown key(s) found" unless (hash.keys - ALLOWED_ENTRY_KEYS).empty?

        maker.items.new_item do |item|
          item.author = hash[:author] if hash.key?(:author)
          item.link = hash[:link] if hash.key?(:link)
          item.title = hash[:title] if hash.key?(:title)
          item.updated = hash[:updated].to_s if hash.key?(:updated)
          item.published = hash[:published].rfc3339.to_s if hash.key?(:published)
          item.content.content = hash[:content] if hash.key?(:content)
          item.content.type = "html" if hash.key?(:content)
          item.id = hash[:id] if hash.key?(:id)

          if hash.key?(:attachment_links)
            hash[:attachment_links].each do |href|
              item.links.new_link do |rss_link|
                rss_link.href = href
                rss_link.rel = "enclosure"
              end
            end
          end
        end
      end
    end

    Nokogiri::XML(content.to_s)
  end
end
