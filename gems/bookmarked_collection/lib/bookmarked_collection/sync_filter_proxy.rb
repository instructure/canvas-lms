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
#

# this class differs from FilterProxy in that it keeps the pager and subpager
# in sync, to allow filtering collections which must be retrieved sequentially,
# at the expense of returning fewer items than the requested per_page

class BookmarkedCollection::SyncFilterProxy < BookmarkedCollection::Proxy
  def initialize(collection, &filter_proc)
    @collection = collection
    @filter_proc = filter_proc
    super(@collection.new_pager, nil)
  end

  def execute_pager(pager)
    bookmark = pager.current_bookmark
    subpager = @collection.new_pager

    loop do
      subpager.per_page = pager.per_page
      subpager.current_bookmark = bookmark
      subpager.next_bookmark = nil # reset the next_bookmark so we don't re-use the old one forever if the next_bookmark is not set next time
      subpager = @collection.execute_pager(subpager)

      bookmark = subpager.next_bookmark
      break if subpager.empty?

      until subpager.empty?
        item = subpager.shift
        next unless @filter_proc.call(item)

        pager << item
      end

      # keep paginating until we hit EOF or get *some* results post-filter
      break if bookmark.nil?
      break unless pager.empty?
    end

    pager.next_bookmark = bookmark
    pager
  end
end
