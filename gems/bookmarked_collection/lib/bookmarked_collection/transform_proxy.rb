# frozen_string_literal: true

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
class BookmarkedCollection::TransformedCollection < BookmarkedCollection::Collection
  def initialize(bookmarker)
    @bookmarks = []
    super(bookmarker)
  end

  def add(item, bookmark)
    self << item
    @bookmarks << bookmark
  end

  def shift
    item = super
    @bookmarks.shift
    item
  end

  def bookmark_for(item)
    @bookmarks[index(item)]
  end

  def leaf_bookmark_for(item)
    bookmark_for(item)
  end
end

class BookmarkedCollection::TransformProxy < BookmarkedCollection::Proxy
  def initialize(collection, &transform_proc)
    @collection = collection
    @transform_proc = transform_proc
    @bookmarks = []
    super(@collection.new_pager, nil)
  end

  def new_pager
    BookmarkedCollection::TransformedCollection.new(@bookmarker)
  end

  def execute_pager(pager)
    sub_pager = @collection.new_pager
    sub_pager.current_bookmark = pager.current_bookmark
    sub_pager.per_page = pager.per_page
    sub_pager = @collection.execute_pager(sub_pager)
    sub_pager.each do |x|
      bookmark = sub_pager.bookmark_for(x)
      pager.add(@transform_proc.call(x), bookmark)
    end
    pager.has_more! if sub_pager.next_page
    pager
  end
end
