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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "BookmarkedCollection::Proxy" do
  describe "#paginate" do
    before :each do
      @scope = Course.order(:id)
      3.times{ @scope.create! }

      @next_bookmark = stub
      @bookmarker = stub(:bookmark_for => @next_bookmark, :validate => true)
      @proxy = BookmarkedCollection::Proxy.new(@bookmarker, lambda{ |pager|
        results = @scope.paginate(:page => 1, :per_page => pager.per_page)
        pager.replace results
        pager.has_more! if results.next_page
        pager
      })
    end

    it "should require per_page parameter" do
      expect{ @proxy.paginate() }.to raise_error(ArgumentError)
    end

    it "should ignore total_entries parameter" do
      @proxy.paginate(:per_page => 5, :total_entries => 10).total_entries.should be_nil
    end

    it "should require a bookmark-style page parameter" do
      value = 1
      bookmark1 = 1
      bookmark2 = "bookmark:W1td" # base64 of '[[]' which should fail to parse
      bookmark3 = "bookmark:#{JSONToken.encode(value)}"
      @proxy.paginate(:page => bookmark1, :per_page => 5).current_bookmark.should be_nil
      @proxy.paginate(:page => bookmark2, :per_page => 5).current_bookmark.should be_nil
      @proxy.paginate(:page => bookmark3, :per_page => 5).current_bookmark.should == value
    end

    it "should produce an appropriate collection type" do
      @proxy.paginate(:per_page => 1).should be_a(BookmarkedCollection::Collection)
    end

    it "should include the results" do
      @proxy.paginate(:per_page => 1).should == [@scope.first]
      @proxy.paginate(:per_page => @scope.count).should == @scope.all
    end

    it "should set next_bookmark if the page wasn't the last" do
      @proxy.paginate(:per_page => 1).next_bookmark.should == @next_bookmark
    end

    it "should not set next_bookmark if the page was the last" do
      @proxy.paginate(:per_page => @scope.count).next_bookmark.should be_nil
    end
  end
end
