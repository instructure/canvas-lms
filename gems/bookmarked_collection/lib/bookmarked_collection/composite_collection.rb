# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

class BookmarkedCollection::CompositeCollection < BookmarkedCollection::Collection
  attr_reader :bookmarks

  def initialize(depth, labels)
    super(nil)
    @depth = depth
    @labels = labels
    @bookmarks = []
  end

  def add(item, bookmark, index)
    self << item
    @bookmarks << compose_bookmark(bookmark, index)
  end

  def shift
    item = super
    @bookmarks.shift
    item
  end

  def compose_bookmark(bookmark, index)
    label = @labels[index]
    bookmark = [bookmark] if @depth == 1
    [label, *bookmark]
  end

  def decompose_bookmark(bookmark = current_bookmark)
    return unless bookmark

    label, *bookmark = bookmark
    index = @labels.index(label)
    bookmark = bookmark.first if @depth == 1
    [bookmark, index]
  end

  def bookmark_for(item)
    @bookmarks[index(item)]
  end

  def leaf_bookmark_for(item)
    bookmark_for(item).last
  end

  def validate(bookmark)
    return false unless bookmark
    return false unless bookmark.is_a?(Array) && bookmark.size == @depth + 1

    bookmark, _ = decompose_bookmark(bookmark)
    return false if bookmark.nil?

    true
  end
end
