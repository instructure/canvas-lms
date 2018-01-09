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

require 'spec_helper'

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
        comparison = (pager.include_bookmark ? 'id >= ?' : 'id > ?')
        scope = scope.where(comparison, bookmark)
      end
      scope.order("id ASC")
    end
  end

  describe "#paginate" do
    before :each do
      @example_class = Class.new(ActiveRecord::Base) do
        self.table_name = 'examples'
      end

      @scope = @example_class.order(:id)

      3.times{ @scope.create! }
      @collection = BookmarkedCollection.wrap(MyBookmarker, @scope)
      @proxy = BookmarkedCollection::MergeProxy.new([['label', @collection]])
    end

    it "should require per_page parameter" do
      expect{ @proxy.paginate() }.to raise_error(ArgumentError)
    end

    it "should ignore total_entries parameter" do
      expect(@proxy.paginate(:per_page => 5, :total_entries => 10).total_entries).to be_nil
    end

    it "should require a bookmark-style page parameter" do
      value1 = 'bookmark'
      value2 = ['label', 0]
      bookmark1 = 1
      bookmark2 = "bookmark:W1td" # base64 of '[[]' which should fail to parse
      bookmark3 = "bookmark:#{::JSONToken.encode(value1)}"
      bookmark4 = "bookmark:#{::JSONToken.encode(value2)}"
      expect(@proxy.paginate(:page => bookmark1, :per_page => 5).current_bookmark).to be_nil
      expect(@proxy.paginate(:page => bookmark2, :per_page => 5).current_bookmark).to be_nil
      expect(@proxy.paginate(:page => bookmark3, :per_page => 5).current_bookmark).to be_nil
      expect(@proxy.paginate(:page => bookmark4, :per_page => 5).current_bookmark).to eq(value2)
    end

    it "should produce an appropriate collection type" do
      expect(@proxy.paginate(:per_page => 1)).to be_a(BookmarkedCollection::CompositeCollection)
    end

    it "should include the results" do
      expect(@proxy.paginate(:per_page => 1)).to eq([@scope.first])
      expect(@proxy.paginate(:per_page => @scope.count)).to eq(@scope.to_a)
    end

    it "should set next_bookmark if the page wasn't the last" do
      expect(@proxy.paginate(:per_page => 1).next_bookmark).to eq(['label', MyBookmarker.bookmark_for(@scope.first)])
    end

    it "should not set next_bookmark if the page was the last" do
      expect(@proxy.paginate(:per_page => @scope.count).next_bookmark).to be_nil
    end

    describe "with multiple collections" do
      before :each do

        @created_scope = @example_class.where(:state => 'created')
        @deleted_scope = @example_class.where(:state => 'deleted')

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
        expect(@proxy.paginate(:per_page => 5)).to eq(@courses[0, 5])
      end

      it "should start each collection after the bookmark" do
        page = @proxy.paginate(:per_page => 3)
        expect(@proxy.paginate(:page => page.next_page, :per_page => 3)).to eq(@courses[3, 3])
      end

      it "should handle inclusive bookmarks" do
        page = @proxy.paginate(:per_page => 3)
        expect(@proxy.paginate(:page => page.next_page, :per_page => 3)).to eq(@courses[3, 3])

        # indicates we've seen through @courses[2].id up through the 0th
        # collection, but haven't seen it from the 1th collection (the one that
        # has @courses[2]) yet
        page.next_bookmark = ['created', @courses[2].id]
        expect(@proxy.paginate(:page => page.next_page, :per_page => 3)).to eq(@courses[2, 3])
      end

      context "when multiple collections still have results" do
        before :each do
          @next_page = @proxy.paginate(:per_page => 3).next_page
        end

        it "should have next_page with more than a page left" do
          expect(@proxy.paginate(:page => @next_page, :per_page => 4).next_page).not_to be_nil
        end

        it "should not have next_page with exactly a page left" do
          expect(@proxy.paginate(:page => @next_page, :per_page => 5).next_page).to be_nil
        end
      end

      context "when just one collection still has results" do
        before :each do
          @next_page = @proxy.paginate(:per_page => 5).next_page
        end

        it "should have next_page with more than a page left" do
          expect(@proxy.paginate(:page => @next_page, :per_page => 2).next_page).not_to be_nil
        end

        it "should not have next_page with exactly a page left" do
          expect(@proxy.paginate(:page => @next_page, :per_page => 3).next_page).to be_nil
        end
      end

      it "merges when bookmarks have nil values" do
        nil_bookmark = BookmarkedCollection::SimpleBookmarker.new(@example_class, :date, :id)
        course = @created_scope.create!(:date => "2017-11-30T00:00:00-06:00")
        created_collection = BookmarkedCollection.wrap(nil_bookmark, @created_scope.order('date DESC, id'))
        deleted_collection = BookmarkedCollection.wrap(nil_bookmark, @deleted_scope.order('date DESC, id'))
        proxy = BookmarkedCollection::MergeProxy.new([
          ['created', created_collection],
          ['deleted', deleted_collection]
        ])

        expect(proxy.paginate(:per_page => 5)).to eq([course] + @courses[0, 4])
      end
    end

    describe "with a merge proc" do
      before :each do
        @example_class.delete_all
        @courses = 6.times.map{ @example_class.create! }
        @scope1 = @example_class.select("id, '1' as scope").where("id<?", @courses[4].id).order(:id)
        @scope2 = @example_class.select("id, '2' as scope").where("id>?", @courses[1].id).order(:id)

        @collection1 = BookmarkedCollection.wrap(MyBookmarker, @scope1)
        @collection2 = BookmarkedCollection.wrap(MyBookmarker, @scope2)
        collections = [['1', @collection1], ['2', @collection2]]

        @yield = double(:tally => nil)
        @proxy = BookmarkedCollection::MergeProxy.new(collections) do |c1, c2|
          @yield.tally(c1, c2)
        end
      end

      it "should yield each pair of duplicates" do
        expect(@yield).to receive(:tally).once.with(@scope1.all[2], @scope2.all[0])
        expect(@yield).to receive(:tally).once.with(@scope1.all[3], @scope2.all[1])
        @proxy.paginate(:per_page => 6)
      end

      it "should yield duplicates of the last element" do
        expect(@yield).to receive(:tally).once.with(@scope1.all[2], @scope2.first)
        @proxy.paginate(:per_page => 3)
      end

      it "should keep the first of each pair of duplicates" do
        results = @proxy.paginate(:per_page => 6)
        expect(results).to eq(@courses)
        expect(results.map(&:scope)).to eq(['1', '1', '1', '1', '2', '2'])
      end

      it "should indicate the first collection to provide the last value in the bookmark" do
        results = @proxy.paginate(:per_page => 3)
        expect(results.next_bookmark).to eq(['1', @courses[2].id])
      end

      it "should not repeat elements from prior pages regardless of duplicates" do
        @next_page = @proxy.paginate(:per_page => 3).next_page
        results = @proxy.paginate(:page => @next_page, :per_page => 3)
        expect(results.first).to eq(@courses[3])
      end
    end
  end
end
