#
# Copyright (C) 2017 - present Instructure, Inc.
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

class BookmarkedCollection::FilterProxy < BookmarkedCollection::Proxy
  def initialize(collection, &filter_proc)
    @collection = collection
    @filter_proc = filter_proc
    super(@collection.new_pager, nil)
  end

  def execute_pager(pager)
    bookmark = pager.current_bookmark
    subpager = @collection.new_pager

    # keep paginating until we fill the pager
    loop do
      # always grab a full page, to avoid situations where we keep
      # repeating the underlying query over and over searching for
      # a single non-filtered item
      subpager.per_page = pager.per_page + 1
      subpager.current_bookmark = bookmark
      subpager = @collection.execute_pager(subpager)

      break if subpager.empty?
      bookmark = subpager.next_bookmark

      while pager.size < pager.per_page && !subpager.empty?
        item = subpager.shift
        next unless @filter_proc.call(item)
        pager << item
      end

      break if bookmark.nil?
      break if pager.per_page == pager.size
    end

    pager.next_bookmark = subpager.bookmark_for(pager.last) if !subpager.empty? || subpager.next_bookmark

    pager
  end
end
