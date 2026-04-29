# frozen_string_literal: true

# Copyright (C) 2013 - present Instructure, Inc.
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

# SyncConcatProxy is a variant of ConcatProxy that synchronously fetches items
# from each subcollection (regions) in order until the requested number of items is
# reached. This is useful when the order of items across collections matters,
# and we want to ensure that items are fetched in a predictable manner like in
# PageView history.

class BookmarkedCollection::SyncConcatProxy < BookmarkedCollection::ConcatProxy
  def execute_pager(pager)
    # decompose current bookmark
    next_bookmark, start_index = pager.decompose_bookmark
    start_index ||= 0

    # paginate subcollections in order until we fill the pager with the requested number of items
    remaining = pager.per_page - pager.size
    (start_index...@collections.size).each do |index|
      break if remaining <= 0 # pager is full, stop fetching

      # fetch a page from the current collection
      collection = @collections[index]
      subpager = collection.new_pager
      subpager.per_page = remaining
      subpager.current_bookmark = next_bookmark

      subpager = collection.execute_pager(subpager)

      # add each item to the pager
      subpager.size.times do
        # pop item from subpager and add to main pager with its bookmark associated with the current collection index
        item, bookmark = subpager.shift_with_bookmark
        pager.add(item, bookmark, index)
        remaining -= 1
      end

      # reset next_bookmark for the next collection
      next_bookmark = nil
    end

    # we consider more pages can be fetched if pager size is greater or equal to per_page
    pager.has_more! if pager.size >= pager.per_page

    pager
  end
end
