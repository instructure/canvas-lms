#
# Copyright (C) 2012 Instructure, Inc.
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

class BookmarkedCollection::ConcatProxy < BookmarkedCollection::CompositeProxy
  def new_pager
    BookmarkedCollection::ConcatCollection.new(@depth, @labels)
  end

  def execute_pager(pager)
    # decompose current bookmark
    subbookmark, start_index = pager.decompose_bookmark

    # paginate subcollections in order until we fill the pager *and* know
    # whether there's at least one more item in some collection. (e.g. if I
    # filled the pager exactly after pulling every remaining item from the
    # Nth collection, I need to check whether the (N+1)th collection has
    # items)
    index = start_index || 0
    while index < @collections.size
      collection = @collections[index]
      remaining = pager.per_page - pager.size

      # fetch a page from the current collection
      subpager = collection.new_pager
      subpager.per_page = remaining + 1
      subpager.current_bookmark = subbookmark
      subpager = collection.execute_pager(subpager)

      # add each item to the pager
      [remaining, subpager.size].min.times do
        item, bookmark = subpager.shift_with_bookmark
        pager.add(item, bookmark, index)
      end

      # if there's still more in this collection, we're done
      if !subpager.empty?
        pager.has_more!
        break
      end

      # move on to start of the next collection
      index += 1
      subbookmark = nil
    end

    pager
  end
end
