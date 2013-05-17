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

describe "BookmarkedCollection::MergeProxy" do
  class MyBookmarker
    def self.bookmark_for(course)
      course.id
    end

    def self.validate(bookmark)
      true
    end

    def self.restrict_scope(scope, pager)
      if bookmark = pager.current_bookmark
        comparison = (pager.include_bookmark ? 'courses.id >= ?' : 'courses.id > ?')
        scope = scope.where(comparison, bookmark)
      end
      scope.order("courses.id ASC")
    end
  end

  describe "#paginate" do
    before :each do
      @scope = Course.order(:id)
      3.times{ @scope.create! }
      @collection = BookmarkedCollection.wrap(MyBookmarker, @scope)
      @proxy = BookmarkedCollection::MergeProxy.new([['label', @collection]])
    end

    it "should require per_page parameter" do
      expect{ @proxy.paginate() }.to raise_error(ArgumentError)
    end

    it "should ignore total_entries parameter" do
      @proxy.paginate(:per_page => 5, :total_entries => 10).total_entries.should be_nil
    end

    it "should require a bookmark-style page parameter" do
      value1 = 'bookmark'
      value2 = ['label', 0]
      bookmark1 = 1
      bookmark2 = "bookmark:W1td" # base64 of '[[]' which should fail to parse
      bookmark3 = "bookmark:#{JSONToken.encode(value1)}"
      bookmark4 = "bookmark:#{JSONToken.encode(value2)}"
      @proxy.paginate(:page => bookmark1, :per_page => 5).current_bookmark.should be_nil
      @proxy.paginate(:page => bookmark2, :per_page => 5).current_bookmark.should be_nil
      @proxy.paginate(:page => bookmark3, :per_page => 5).current_bookmark.should be_nil
      @proxy.paginate(:page => bookmark4, :per_page => 5).current_bookmark.should == value2
    end

    it "should produce an appropriate collection type" do
      @proxy.paginate(:per_page => 1).should be_a(BookmarkedCollection::CompositeCollection)
    end

    it "should include the results" do
      @proxy.paginate(:per_page => 1).should == [@scope.first]
      @proxy.paginate(:per_page => @scope.count).should == @scope.all
    end

    it "should set next_bookmark if the page wasn't the last" do
      @proxy.paginate(:per_page => 1).next_bookmark.should == ['label', MyBookmarker.bookmark_for(@scope.first)]
    end

    it "should not set next_bookmark if the page was the last" do
      @proxy.paginate(:per_page => @scope.count).next_bookmark.should be_nil
    end

    describe "with multiple collections" do
      before :each do
        @created_scope = Course.where(:workflow_state => 'created')
        @deleted_scope = Course.where(:workflow_state => 'deleted')

        Course.delete_all
        @courses = [
          @created_scope.create!,
          @created_scope.create!,
          @deleted_scope.create!,
          @created_scope.create!,
          @created_scope.create!,
          @deleted_scope.create!,
          @deleted_scope.create!,
          @deleted_scope.create!
        ]

        @created_collection = BookmarkedCollection.wrap(MyBookmarker, @created_scope)
        @deleted_collection = BookmarkedCollection.wrap(MyBookmarker, @deleted_scope)
        @proxy = BookmarkedCollection::MergeProxy.new([
          ['created', @created_collection],
          ['deleted', @deleted_collection]
        ])
      end

      it "should interleave" do
        @proxy.paginate(:per_page => 5).should == @courses[0, 5]
      end

      it "should start each collection after the bookmark" do
        page = @proxy.paginate(:per_page => 3)
        @proxy.paginate(:page => page.next_page, :per_page => 3).should == @courses[3, 3]
      end

      it "should handle inclusive bookmarks" do
        page = @proxy.paginate(:per_page => 3)
        @proxy.paginate(:page => page.next_page, :per_page => 3).should == @courses[3, 3]

        # indicates we've seen through @courses[2].id up through the 0th
        # collection, but haven't seen it from the 1th collection (the one that
        # has @courses[2]) yet
        page.next_bookmark = ['created', @courses[2].id]
        @proxy.paginate(:page => page.next_page, :per_page => 3).should == @courses[2, 3]
      end

      context "when multiple collections still have results" do
        before :each do
          @next_page = @proxy.paginate(:per_page => 3).next_page
        end

        it "should have next_page with more than a page left" do
          @proxy.paginate(:page => @next_page, :per_page => 4).next_page.should_not be_nil
        end

        it "should not have next_page with exactly a page left" do
          @proxy.paginate(:page => @next_page, :per_page => 5).next_page.should be_nil
        end
      end

      context "when just one collection still has results" do
        before :each do
          @next_page = @proxy.paginate(:per_page => 5).next_page
        end

        it "should have next_page with more than a page left" do
          @proxy.paginate(:page => @next_page, :per_page => 2).next_page.should_not be_nil
        end

        it "should not have next_page with exactly a page left" do
          @proxy.paginate(:page => @next_page, :per_page => 3).next_page.should be_nil
        end
      end
    end

    describe "with a merge proc" do
      before :each do
        Course.delete_all
        @courses = 6.times.map{ Course.create! }
        @scope1 = Course.select("id, 1 as scope").where("id<?", @courses[4].id)
        @scope2 = Course.select("id, 2 as scope").where("id>?", @courses[1].id)

        @collection1 = BookmarkedCollection.wrap(MyBookmarker, @scope1)
        @collection2 = BookmarkedCollection.wrap(MyBookmarker, @scope2)
        collections = [['1', @collection1], ['2', @collection2]]

        @yield = stub(:tally => nil)
        @proxy = BookmarkedCollection::MergeProxy.new(collections) do |c1, c2|
          @yield.tally(c1, c2)
        end
      end

      it "should yield each pair of duplicates" do
        @yield.expects(:tally).once.with(@scope1.all[2], @scope2.all[0])
        @yield.expects(:tally).once.with(@scope1.all[3], @scope2.all[1])
        @proxy.paginate(:per_page => 6)
      end

      it "should yield duplicates of the last element" do
        @yield.expects(:tally).once.with(@scope1.all[2], @scope2.first)
        @proxy.paginate(:per_page => 3)
      end

      it "should keep the first of each pair of duplicates" do
        results = @proxy.paginate(:per_page => 6)
        results.should == @courses
        results.map(&:scope).should == ['1', '1', '1', '1', '2', '2']
      end

      it "should indicate the first collection to provide the last value in the bookmark" do
        results = @proxy.paginate(:per_page => 3)
        results.next_bookmark.should == ['1', @courses[2].id]
      end

      it "should not repeat elements from prior pages regardless of duplicates" do
        @next_page = @proxy.paginate(:per_page => 3).next_page
        results = @proxy.paginate(:page => @next_page, :per_page => 3)
        results.first.should == @courses[3]
      end
    end
  end
end
