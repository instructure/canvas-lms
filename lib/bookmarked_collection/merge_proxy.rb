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

class BookmarkedCollection::MergeProxy < BookmarkedCollection::CompositeProxy
  def initialize(collections, &merge_proc)
    if collections.any?{ |(_,coll)| coll.is_a?(BookmarkedCollection::ConcatProxy) }
      raise ArgumentError, "Cannot include a concatenation in a merge."
    end
    super(collections)
    @merge_proc = merge_proc
  end

  # a pair of (1) the leaf bookmark of the next value in collections[index] and
  # (2) the index
  def indexed_bookmark(collection, index)
    [collection.leaf_bookmark_for(collection.first), index]
  end

  def execute_pager(pager)
    # decompose current bookmark
    subbookmark, start_index = pager.decompose_bookmark

    # paginate each subcollection
    collections = []
    @collections.each_with_index do |collection, index|
      subpager = collection.new_pager
      subpager.per_page = pager.per_page
      subpager.current_bookmark = subbookmark
      subpager.include_bookmark = start_index && index > start_index && !@merge_proc
      collections << collection.execute_pager(subpager)
    end

    # create a sorted list of the next bookmarks for each collection and
    # the index of the collection the bookmark is from; empty collections
    # are omitted
    indexed_bookmarks = []
    collections.each_with_index do |collection, index|
      next if collection.empty?
      indexed_bookmarks << indexed_bookmark(collection, index)
    end
    indexed_bookmarks.sort!

    last_item, last_leaf_bookmark = nil, nil
    while indexed_bookmarks.present? && (pager.size < pager.per_page || @merge_proc && indexed_bookmarks.first.first == last_leaf_bookmark)
      # pull the index of the collection with the next lowest bookmark and
      # pull off its first item
      leaf_bookmark, index = indexed_bookmarks.shift
      collection = collections[index]
      item, bookmark = collection.shift_with_bookmark
      if last_leaf_bookmark == leaf_bookmark && @merge_proc
        # merge this item into the identical item that's already in the pager
        @merge_proc.call(last_item, item)
      else
        # add item to pager with bookmark
        pager.add(item, bookmark, index)
        last_item, last_leaf_bookmark = item, leaf_bookmark
      end

      unless collection.empty?
        # collection still has items, put the index back in the list with
        # the bookmark of the next item, and keep it sorted
        indexed_bookmarks << indexed_bookmark(collection, index)
        indexed_bookmarks.sort!
      end
    end

    # we have a bookmark if any collection has more pages or, even if this is
    # the last page of every collection, there were left over results
    if collections.any?{ |coll| !coll.empty? || !coll.next_bookmark.nil? }
      pager.has_more!
    end

    pager
  end
end
