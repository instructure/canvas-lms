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

class BookmarkedCollection::Collection < Array
  include Folio::Page

  FIRST_TOKEN = "first"

  def initialize(bookmarker)
    @bookmarker = bookmarker
  end

  def shift_with_bookmark
    return if empty?
    bookmark = bookmark_for(first)
    [shift, bookmark]
  end

  def bookmark_for(item)
    @bookmarker.bookmark_for(item)
  end

  def leaf_bookmark_for(item)
    bookmark_for(item)
  end

  attr_reader :current_bookmark
  attr_reader :next_bookmark

  def validate(bookmark)
    @bookmarker.validate(bookmark)
  end

  def current_bookmark=(bookmark)
    if bookmark.nil? || validate(bookmark)
      @current_bookmark = bookmark
    else
      @current_bookmark = nil
    end
  end

  def next_bookmark=(bookmark)
    if bookmark.nil? || validate(bookmark)
      @next_bookmark = bookmark
    else
      @next_bookmark = nil
    end
  end

  # typically not set unless part of a merger of many collections
  # (including merging by sharding).
  #
  # if true, the code that populates the collection should start on the
  # bookmark value (e.g. field >= bookmark). if false, that code should start
  # just after the bookmark value (e.g. field > bookmark).
  #
  # only applies to current_bookmark; next_bookmark is always assumed
  # included in this collection, and should be excluded from the next page
  attr_accessor :include_bookmark

  def bookmark_to_page(bookmark)
    bookmark && "bookmark:#{::JSONToken.encode(bookmark)}"
  end

  def page_to_bookmark(page)
    page = first_page if page.nil?
    if page == first_page
      nil
    else
      if page =~ /^bookmark:/
        begin
          ::JSONToken.decode(page.gsub(/^bookmark:/, ''))
        rescue
          # bookmark value could not be decoded
          nil
        end
      else
        # not tagged as a bookmark
        nil
      end
    end
  end

  def current_page=(page)
    self.current_bookmark = page_to_bookmark(page)
    page
  end

  def first_page
    FIRST_TOKEN
  end

  def current_page
    bookmark_to_page(current_bookmark) || first_page
  end

  def next_page
    bookmark_to_page(next_bookmark)
  end

  def has_more!
    self.next_bookmark = bookmark_for(last)
  end
end
