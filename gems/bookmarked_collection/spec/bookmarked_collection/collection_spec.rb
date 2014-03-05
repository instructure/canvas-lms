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

require 'spec_helper'

describe "BookmarkedCollection::Collection" do
  before :each do
    @bookmark = double('bookmark')
    @bookmarker = double('bookmarker', :validate => true, :bookmark_for => @bookmark)
    @collection = BookmarkedCollection::Collection.new(@bookmarker)
  end

  describe "bookmark accessors" do
    it "should support current_bookmark" do
      value = 5
      @collection.current_bookmark.should be_nil
      @collection.current_bookmark = value
      @collection.current_bookmark.should == value
    end

    it "should support next_bookmark" do
      value = 5
      @collection.next_bookmark.should be_nil
      @collection.next_bookmark = value
      @collection.next_bookmark.should == value
    end

    it "should support include_bookmark" do
      value = true
      @collection.include_bookmark.should be_nil
      @collection.include_bookmark = value
      @collection.include_bookmark.should == value
    end
  end

  describe "#current_page" do
    it "should be first_page if current_bookmark is nil" do
      @collection.current_bookmark = nil
      @collection.current_page.should == @collection.first_page
    end

    it "should lead with a 'bookmark:' prefix otherwise" do
      @collection.current_bookmark = "some value"
      @collection.current_page.should match(/^bookmark:/)
    end

    it "should change with current_bookmark" do
      @collection.current_bookmark = "bookmark1"
      page1 = @collection.current_page
      page1.should_not be_nil

      @collection.current_bookmark = "bookmark2"
      page2 = @collection.current_page
      page2.should_not be_nil
      page2.should_not == page1

      @collection.current_bookmark = nil
      @collection.current_page.should == @collection.first_page
    end
  end

  describe "#next_page" do
    it "should be nil if next_bookmark is nil" do
      @collection.next_bookmark = nil
      @collection.next_page.should be_nil
    end

    it "should lead with a 'bookmark:' prefix otherwise" do
      @collection.next_bookmark = "some value"
      @collection.next_page.should match(/^bookmark:/)
    end

    it "should change with next_bookmark" do
      @collection.next_bookmark = "bookmark1"
      page1 = @collection.next_page
      page1.should_not be_nil

      @collection.next_bookmark = "bookmark2"
      page2 = @collection.next_page
      page2.should_not be_nil
      page2.should_not == page1

      @collection.next_bookmark = nil
      @collection.next_page.should be_nil
    end
  end

  describe "#current_page=" do
    it "should set current_bookmark to nil if nil" do
      @collection.current_bookmark = "some value"
      @collection.current_page = nil
      @collection.current_bookmark.should be_nil
    end

    it "should go to nil if missing 'bookmark:' prefix" do
      @collection.current_page = "invalid bookmark"
      @collection.current_bookmark.should be_nil
    end

    it "should go to nil if can't deserialize bookmark" do
      # "W1td" is the base64 encoding of "[[]", which should fail to parse as JSON
      @collection.current_page = "bookmark:W1td"
      @collection.current_bookmark.should be_nil
    end

    it "should preserve bookmark value through serialization" do
      bookmark = "bookmark value"
      @collection.current_bookmark = bookmark
      page = @collection.current_page
      @collection.current_bookmark = nil

      @collection.current_page = page
      @collection.current_bookmark.should == bookmark
    end
  end

  describe "#first_page" do
    it "should not be nil" do
      @collection.first_page.should_not be_nil
    end

    it "should set bookmark to nil when used to set page" do
      @collection.current_bookmark = "some value"
      @collection.current_page = @collection.first_page
      @collection.current_bookmark.should be_nil
    end
  end

  describe "#has_more!" do
    before :each do
      @item = double('item')
      @collection << @item
      @bookmark = double('bookmark')
    end

    it "should use the bookmarker on the last item" do
      expect(@bookmarker).to receive(:bookmark_for).once.with(@item).and_return(@bookmark)
      @collection.has_more!
      @collection.next_bookmark.should == @bookmark
    end
  end

  describe "last_page" do
    it "should assume the current_page is the last_page if there's no next_page" do
      @collection.current_bookmark = "bookmark1"
      @collection.next_bookmark = nil
      @collection.last_page.should == @collection.current_page
    end

    it "should assume the last_page is unknown if there's a next_page" do
      @collection.current_bookmark = "bookmark1"
      @collection.next_bookmark = "bookmark2"
      @collection.last_page.should be_nil
    end
  end

  describe "remaining will_paginate support" do
    it "should support per_page" do
      value = 5
      @collection.per_page.should == Folio.per_page
      @collection.per_page = value
      @collection.per_page.should == value
    end

    it "should support total_entries" do
      value = 5
      @collection.total_entries.should be_nil
      @collection.total_entries = value
      @collection.total_entries.should == value
    end

    it "should support reading empty previous_page" do
      @collection.previous_page.should be_nil
    end

    it "should support reading empty total_pages" do
      @collection.total_pages.should be_nil
    end
  end
end
