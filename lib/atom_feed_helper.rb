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
    feed = Atom::Feed.new do |f|
      f.title = title
      f.links << Atom::Link.new(href: link, rel: "self")
      f.updated = updated || Time.now
      f.id = id || link
    end

    entries.each do |e|
      hash = if block_given?
               e.to_atom(**yield(e))
             else
               e.to_atom(**kwargs)
             end

      raise "unknown key(s) found" unless (hash.keys - ALLOWED_ENTRY_KEYS).empty?

      feed.entries << Atom::Entry.new do |entry|
        entry.title = hash[:title] if hash.key?(:title)
        entry.authors << Atom::Person.new(name: hash[:author]) if hash.key?(:author)
        entry.updated = hash[:updated] if hash.key?(:updated)
        entry.published = hash[:published] if hash.key?(:published)
        entry.id = hash[:id] if hash.key?(:id)
        entry.links << Atom::Link.new(rel: "alternate", href: hash[:link]) if hash.key?(:link)
        entry.content = Atom::Content::Html.new(hash[:content]) if hash.key?(:content)

        if hash.key?(:attachment_links)
          hash[:attachment_links].each do |href|
            entry.links << Atom::Link.new(rel: "enclosure", href:)
          end
        end
      end
    end

    feed.to_xml
  end
end
