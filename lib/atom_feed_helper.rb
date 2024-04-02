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
  def self.render_xml(title:, link:, entries:, updated: nil, id: nil, **kwargs)
    feed = Atom::Feed.new do |f|
      f.title = title
      f.links << Atom::Link.new(href: link, rel: "self")
      f.updated = updated || Time.now
      f.id = id || link
    end

    entries.each do |e|
      feed.entries << if block_given?
                        e.to_atom(**yield(e))
                      else
                        e.to_atom(**kwargs)
                      end
    end

    feed.to_xml
  end
end
