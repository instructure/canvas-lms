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

require "spec_helper"

describe "BookmarkedCollection::MergeProxy" do
  let(:my_bookmarker) do
    Class.new do
      def self.bookmark_for(course)
        course.id
      end

      def self.validate(_bookmark)
        true
      end

      def self.restrict_scope(scope, pager)
        if (bookmark = pager.current_bookmark)
          comparison = (pager.include_bookmark ? "id >= ?" : "id > ?")
          scope = scope.where(comparison, bookmark)
        end
        scope.order("id ASC")
      end
    end
  end

  describe "#paginate" do
    before do
      @example_class = Class.new(ActiveRecord::Base) do
        self.table_name = "examples"
      end

      @scope = @example_class.order(:id)

      3.times { @scope.create! }
      @collection = BookmarkedCollection.wrap(my_bookmarker, @scope)
      @proxy = BookmarkedCollection::MergeProxy.new([["label", @collection]])
    end

    it "requires per_page parameter" do
      expect { @proxy.paginate }.to raise_error(ArgumentError)
    end

    it "ignores total_entries parameter" do
      expect(@proxy.paginate(per_page: 5, total_entries: 10).total_entries).to be_nil
    end

    it "requires a bookmark-style page parameter" do
      value1 = "bookmark"
      value2 = ["label", 0]
      bookmark1 = 1
      bookmark2 = "bookmark:W1td" # base64 of '[[]' which should fail to parse
      bookmark3 = "bookmark:#{JSONToken.encode(value1)}"
      bookmark4 = "bookmark:#{JSONToken.encode(value2)}"
      expect(@proxy.paginate(page: bookmark1, per_page: 5).current_bookmark).to be_nil
      expect(@proxy.paginate(page: bookmark2, per_page: 5).current_bookmark).to be_nil
      expect(@proxy.paginate(page: bookmark3, per_page: 5).current_bookmark).to be_nil
      expect(@proxy.paginate(page: bookmark4, per_page: 5).current_bookmark).to eq(value2)
    end

    it "produces an appropriate collection type" do
      expect(@proxy.paginate(per_page: 1)).to be_a(BookmarkedCollection::CompositeCollection)
    end

    it "includes the results" do
      expect(@proxy.paginate(per_page: 1)).to eq([@scope.first])
      expect(@proxy.paginate(per_page: @scope.count)).to eq(@scope.to_a)
    end

    it "sets next_bookmark if the page wasn't the last" do
      expect(@proxy.paginate(per_page: 1).next_bookmark).to eq(["label", my_bookmarker.bookmark_for(@scope.first)])
    end

    it "does not set next_bookmark if the page was the last" do
      expect(@proxy.paginate(per_page: @scope.count).next_bookmark).to be_nil
    end

    describe "with multiple collections" do
      before do
        @created_scope = @example_class.where(state: "created")
        @deleted_scope = @example_class.where(state: "deleted")

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

        @created_collection = BookmarkedCollection.wrap(my_bookmarker, @created_scope)
        @deleted_collection = BookmarkedCollection.wrap(my_bookmarker, @deleted_scope)
        @proxy = BookmarkedCollection::MergeProxy.new([
                                                        ["created", @created_collection],
                                                        ["deleted", @deleted_collection]
                                                      ])
      end

      it "interleaves" do
        expect(@proxy.paginate(per_page: 5)).to eq(@courses[0, 5])
      end

      it "starts each collection after the bookmark" do
        page = @proxy.paginate(per_page: 3)
        expect(@proxy.paginate(page: page.next_page, per_page: 3)).to eq(@courses[3, 3])
      end

      it "handles inclusive bookmarks" do
        page = @proxy.paginate(per_page: 3)
        expect(@proxy.paginate(page: page.next_page, per_page: 3)).to eq(@courses[3, 3])

        # indicates we've seen through @courses[2].id up through the 0th
        # collection, but haven't seen it from the 1th collection (the one that
        # has @courses[2]) yet
        page.next_bookmark = ["created", @courses[2].id]
        expect(@proxy.paginate(page: page.next_page, per_page: 3)).to eq(@courses[2, 3])
      end

      context "when multiple collections still have results" do
        before do
          @next_page = @proxy.paginate(per_page: 3).next_page
        end

        it "has next_page with more than a page left" do
          expect(@proxy.paginate(page: @next_page, per_page: 4).next_page).not_to be_nil
        end

        it "does not have next_page with exactly a page left" do
          expect(@proxy.paginate(page: @next_page, per_page: 5).next_page).to be_nil
        end
      end

      context "when just one collection still has results" do
        before do
          @next_page = @proxy.paginate(per_page: 5).next_page
        end

        it "has next_page with more than a page left" do
          expect(@proxy.paginate(page: @next_page, per_page: 2).next_page).not_to be_nil
        end

        it "does not have next_page with exactly a page left" do
          expect(@proxy.paginate(page: @next_page, per_page: 3).next_page).to be_nil
        end
      end

      it "merges when bookmarks have nil values" do
        nil_bookmark = BookmarkedCollection::SimpleBookmarker.new(@example_class, :date, :id)
        course = @created_scope.create!(date: "2017-11-30T00:00:00-06:00")
        created_collection = BookmarkedCollection.wrap(nil_bookmark, @created_scope.order("date DESC, id"))
        deleted_collection = BookmarkedCollection.wrap(nil_bookmark, @deleted_scope.order("date DESC, id"))
        proxy = BookmarkedCollection::MergeProxy.new([
                                                       ["created", created_collection],
                                                       ["deleted", deleted_collection]
                                                     ])

        expect(proxy.paginate(per_page: 5)).to eq([course] + @courses[0, 4])
      end
    end

    describe "with a merge proc" do
      before do
        @example_class.delete_all
        @courses = Array.new(6) { @example_class.create! }
        @scope1 = @example_class.select("id, '1' as scope").where("id<?", @courses[4].id).order(:id)
        @scope2 = @example_class.select("id, '2' as scope").where("id>?", @courses[1].id).order(:id)

        @collection1 = BookmarkedCollection.wrap(my_bookmarker, @scope1)
        @collection2 = BookmarkedCollection.wrap(my_bookmarker, @scope2)
        collections = [["1", @collection1], ["2", @collection2]]

        @yield = double(tally: nil)
        @proxy = BookmarkedCollection::MergeProxy.new(collections) do |c1, c2|
          @yield.tally(c1, c2)
        end
      end

      it "yields each pair of duplicates" do
        expect(@yield).to receive(:tally).once.with(@scope1.all[2], @scope2.all[0])
        expect(@yield).to receive(:tally).once.with(@scope1.all[3], @scope2.all[1])
        @proxy.paginate(per_page: 6)
      end

      it "yields duplicates of the last element" do
        expect(@yield).to receive(:tally).once.with(@scope1.all[2], @scope2.first)
        @proxy.paginate(per_page: 3)
      end

      it "keeps the first of each pair of duplicates" do
        results = @proxy.paginate(per_page: 6)
        expect(results).to eq(@courses)
        expect(results.map(&:scope)).to eq(%w[1 1 1 1 2 2])
      end

      it "indicates the first collection to provide the last value in the bookmark" do
        results = @proxy.paginate(per_page: 3)
        expect(results.next_bookmark).to eq(["1", @courses[2].id])
      end

      it "does not repeat elements from prior pages regardless of duplicates" do
        @next_page = @proxy.paginate(per_page: 3).next_page
        results = @proxy.paginate(page: @next_page, per_page: 3)
        expect(results.first).to eq(@courses[3])
      end
    end
  end
end
