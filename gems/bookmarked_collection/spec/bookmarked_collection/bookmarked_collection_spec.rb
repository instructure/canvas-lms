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

describe "BookmarkedCollection" do
  let(:id_bookmarker) do
    Class.new do
      def self.bookmark_for(object)
        object.id
      end

      def self.validate(_bookmark)
        # can't actually validate because sometimes it'll be a mock
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

  let(:name_bookmarker) do
    Class.new do
      def self.bookmark_for(course)
        course.name
      end

      def self.validate(bookmark)
        bookmark.is_a?(String)
      end

      def self.restrict_scope(scope, pager)
        if (bookmark = pager.current_bookmark)
          comparison = (pager.include_bookmark ? "name >= ?" : "name > ?")
          scope = scope.where(comparison, bookmark)
        end
        scope.order("name ASC")
      end
    end
  end

  describe ".wrap" do
    before do
      example_class = Class.new(ActiveRecord::Base) do
        self.table_name = "examples"
      end
      3.times { example_class.create! }
      @scope = example_class
    end

    it "returns a WrapProxy" do
      expect(BookmarkedCollection.wrap(id_bookmarker, @scope)).to be_a(PaginatedCollection::Proxy)
    end

    it "uses the provided scope when executing pagination" do
      collection = BookmarkedCollection.wrap(id_bookmarker, @scope)
      expect(collection.paginate(per_page: 1)).to eq([@scope.first])
    end

    it "uses the bookmarker's bookmark generator to produce bookmarks" do
      bookmark = double
      allow(id_bookmarker).to receive(:bookmark_for) { bookmark }

      collection = BookmarkedCollection.wrap(id_bookmarker, @scope)
      expect(collection.paginate(per_page: 1).next_bookmark).to eq(bookmark)
    end

    it "uses the bookmarker's bookmark applicator to restrict by bookmark" do
      bookmark = @scope.order(:id).first.id
      bookmarked_scope = @scope.order(:id).where("id>?", bookmark)
      allow(id_bookmarker).to receive(:restrict_scope) { bookmarked_scope }

      collection = BookmarkedCollection.wrap(id_bookmarker, @scope)
      expect(collection.paginate(per_page: 1)).to eq([bookmarked_scope.first])
    end

    it "applies any restriction block given to the scope" do
      course = @scope.order(:id).last
      course.update(name: "Matching Name")

      collection = BookmarkedCollection.wrap(id_bookmarker, @scope) do |scope|
        scope.where(name: course.name)
      end

      expect(collection.paginate(per_page: 1)).to eq([course])
    end
  end

  describe ".merge" do
    before do
      example_class = Class.new(ActiveRecord::Base) do
        self.table_name = "examples"
      end

      @created_course1 = example_class.create!(state: "created")
      @deleted_course1 = example_class.create!(state: "deleted")
      @created_course2 = example_class.create!(state: "created")
      @deleted_course2 = example_class.create!(state: "deleted")

      @created_scope = example_class.where(state: "created")
      @deleted_scope = example_class.where(state: "deleted")

      @created_collection = BookmarkedCollection.wrap(id_bookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(id_bookmarker, @deleted_scope)
      @collection = BookmarkedCollection.merge(
        ["created", @created_collection],
        ["deleted", @deleted_collection]
      )
    end

    it "returns a merge proxy" do
      expect(@collection).to be_a(BookmarkedCollection::MergeProxy)
    end

    it "merges the given collections" do
      expect(@collection.paginate(per_page: 2)).to eq([@created_course1, @deleted_course1])
    end

    it "has a next page when there's a non-exhausted collection" do
      expect(@collection.paginate(per_page: 3).next_page).not_to be_nil
    end

    it "does not have a next page when all collections are exhausted" do
      expect(@collection.paginate(per_page: 4).next_page).to be_nil
    end

    it "picks up in the middle of a collection" do
      page = @collection.paginate(per_page: 1)
      expect(page).to eq([@created_course1])
      expect(page.next_bookmark).not_to be_nil

      expect(@collection.paginate(page: page.next_page, per_page: 2)).to eq([@deleted_course1, @created_course2])
    end

    context "with a merge proc" do
      before do
        @created_scope.delete_all
        @deleted_scope.delete_all

        # the name bookmarker will generate the same bookmark for both of the
        # courses.
        @created_course = @created_scope.create!(name: "Same Name")
        @deleted_course = @deleted_scope.create!(name: "Same Name")

        @created_collection = BookmarkedCollection.wrap(name_bookmarker, @created_scope)
        @deleted_collection = BookmarkedCollection.wrap(name_bookmarker, @deleted_scope)
        @collection = BookmarkedCollection.merge(
          ["created", @created_collection],
          ["deleted", @deleted_collection]
        ) { nil }
      end

      it "collapses duplicates" do
        expect(@collection.paginate(per_page: 2)).to eq([@created_course])
      end
    end

    context "with ties across collections" do
      before do
        @created_scope.delete_all
        @deleted_scope.delete_all

        # the name bookmarker will generate the same bookmark for both of the
        # courses.
        @created_course = @created_scope.create!(name: "Same Name")
        @deleted_course = @deleted_scope.create!(name: "Same Name")

        @created_collection = BookmarkedCollection.wrap(name_bookmarker, @created_scope)
        @deleted_collection = BookmarkedCollection.wrap(name_bookmarker, @deleted_scope)
        @collection = BookmarkedCollection.merge(
          ["created", @created_collection],
          ["deleted", @deleted_collection]
        )
      end

      it "sorts the ties by collection" do
        expect(@collection.paginate(per_page: 2)).to eq([@created_course, @deleted_course])
      end

      it "picks up at the right place when a page break splits the tie" do
        page = @collection.paginate(per_page: 1)
        expect(page).to eq([@created_course])
        expect(page.next_bookmark).not_to be_nil

        page = @collection.paginate(page: page.next_page, per_page: 1)
        expect(page).to eq([@deleted_course])
        expect(page.next_bookmark).to be_nil
      end
    end
  end

  describe ".concat" do
    before do
      example_class = Class.new(ActiveRecord::Base) do
        self.table_name = "examples"
      end

      @created_scope = example_class.where(state: "created")
      @deleted_scope = example_class.where(state: "deleted")

      @created_course1 = @created_scope.create!
      @deleted_course1 = @deleted_scope.create!
      @created_course2 = @created_scope.create!
      @deleted_course2 = @deleted_scope.create!

      @created_collection = BookmarkedCollection.wrap(id_bookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(id_bookmarker, @deleted_scope)
      @collection = BookmarkedCollection.concat(
        ["created", @created_collection],
        ["deleted", @deleted_collection]
      )
    end

    it "returns a concat proxy" do
      expect(@collection).to be_a(BookmarkedCollection::ConcatProxy)
    end

    it "concatenates the given collections" do
      expect(@collection.paginate(per_page: 3)).to eq([@created_course1, @created_course2, @deleted_course1])
    end

    it "has a next page when there's a non-exhausted collection" do
      expect(@collection.paginate(per_page: 3).next_page).not_to be_nil
    end

    it "has a next page on the border between an exhausted collection and a non-exhausted collection" do
      expect(@collection.paginate(per_page: 2).next_page).not_to be_nil
    end

    it "does not have a next page when all collections are exhausted" do
      expect(@collection.paginate(per_page: 4).next_page).to be_nil
    end

    it "picks up in the middle of a collection" do
      page = @collection.paginate(per_page: 1)
      expect(page).to eq([@created_course1])
      expect(page.next_bookmark).not_to be_nil

      expect(@collection.paginate(page: page.next_page, per_page: 2)).to eq([@created_course2, @deleted_course1])
    end

    it "picks up from a break between collections" do
      page = @collection.paginate(per_page: 2)
      expect(page).to eq([@created_course1, @created_course2])
      expect(page.next_bookmark).not_to be_nil

      expect(@collection.paginate(page: page.next_page, per_page: 2)).to eq([@deleted_course1, @deleted_course2])
    end

    it "doesn't get confused by subcollections that don't respect per_page" do
      bookmarker = id_bookmarker
      created_collection = BookmarkedCollection.build(bookmarker) do |pager|
        scope = @created_scope
        scope = bookmarker.restrict_scope(scope, pager)
        items = scope.limit(2).to_a
        pager.replace(items[0..0])
        pager.has_more! if items.length == 2
        pager
      end

      @collection = BookmarkedCollection.concat(
        ["created", created_collection],
        ["deleted", @deleted_collection]
      )
      expect(created_collection.paginate(per_page: 3)).to eq([@created_course1])
      expect(@collection.paginate(per_page: 3)).to eq([@created_course1, @created_course2, @deleted_course1])
    end

    it "efficiently has a next page that coincides with a partial read" do
      bookmarker = id_bookmarker
      created_collection = BookmarkedCollection.build(bookmarker) do |pager|
        scope = @created_scope
        scope = bookmarker.restrict_scope(scope, pager)
        items = scope.limit(2).to_a
        pager.replace(items[0..0])
        pager.has_more! if items.length == 2
        pager
      end

      @collection = BookmarkedCollection.concat(
        ["created", created_collection],
        ["deleted", @deleted_collection]
      )

      expect(@deleted_collection).not_to receive(:execute_pager)
      expect(@collection.paginate(per_page: 1).next_page).not_to be_nil
    end
  end

  describe "nested compositions" do
    before do
      example_class = Class.new(ActiveRecord::Base) do
        self.table_name = "examples"
      end

      user_class = Class.new(ActiveRecord::Base) do
        self.table_name = "users"
      end

      @created_scope = example_class.where(state: "created")
      @deleted_scope = example_class.where(state: "deleted")

      # user's names are so it sorts Created X < Creighton < Deanne < Deleted
      # X when using NameBookmarks
      @user1 = user_class.create!(name: "Creighton")
      @user2 = user_class.create!(name: "Deanne")
      @user_scope = user_class.where(id: [@user1, @user2])
      @created_course1 = @created_scope.create!(name: "Created 1")
      @deleted_course1 = @deleted_scope.create!(name: "Deleted 1")
      @created_course2 = @created_scope.create!(name: "Created 2")
      @deleted_course2 = @deleted_scope.create!(name: "Deleted 2")
    end

    it "handles concat(A, merge(B, C))" do
      @user_collection = BookmarkedCollection.wrap(id_bookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(id_bookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(id_bookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.merge(
        ["created", @created_collection],
        ["deleted", @deleted_collection]
      )

      @collection = BookmarkedCollection.concat(
        ["users", @user_collection],
        ["courses", @course_collection]
      )

      page = @collection.paginate(per_page: 4)
      expect(page).to eq([@user1, @user2, @created_course1, @deleted_course1])
      expect(page.next_page).not_to be_nil

      page = @collection.paginate(page: page.next_page, per_page: 2)
      expect(page).to eq([@created_course2, @deleted_course2])
      expect(page.next_page).to be_nil
    end

    it "handles merge(A, merge(B, C))" do
      # use name_bookmarker to make user/course merge interesting
      @user_collection = BookmarkedCollection.wrap(name_bookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(name_bookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(name_bookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.merge(
        ["created", @created_collection],
        ["deleted", @deleted_collection]
      )

      @collection = BookmarkedCollection.merge(
        ["users", @user_collection],
        ["courses", @course_collection]
      )

      page = @collection.paginate(per_page: 3)
      expect(page).to eq([@created_course1, @created_course2, @user1])
      expect(page.next_page).not_to be_nil

      page = @collection.paginate(page: page.next_page, per_page: 3)
      expect(page).to eq([@user2, @deleted_course1, @deleted_course2])
      expect(page.next_page).to be_nil
    end

    it "handles concat(A, concat(B, C))" do
      @user_collection = BookmarkedCollection.wrap(id_bookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(id_bookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(id_bookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.concat(
        ["created", @created_collection],
        ["deleted", @deleted_collection]
      )

      @collection = BookmarkedCollection.concat(
        ["users", @user_collection],
        ["courses", @course_collection]
      )

      page = @collection.paginate(per_page: 3)
      expect(page).to eq([@user1, @user2, @created_course1])
      expect(page.next_page).not_to be_nil

      page = @collection.paginate(page: page.next_page, per_page: 3)
      expect(page).to eq([@created_course2, @deleted_course1, @deleted_course2])
      expect(page.next_page).to be_nil
    end

    it "does not allow merge(A, concat(B, C))" do
      @user_collection = BookmarkedCollection.wrap(name_bookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(name_bookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(name_bookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.concat(
        ["created", @created_collection],
        ["deleted", @deleted_collection]
      )

      expect do
        @collection = BookmarkedCollection.merge(
          ["users", @user_collection],
          ["courses", @course_collection]
        )
      end.to raise_exception ArgumentError
    end
  end

  describe ".best_unicode_collation_key" do
    it "returns col if proc is not set" do
      BookmarkedCollection.best_unicode_collation_key_proc = nil
      expect(BookmarkedCollection.best_unicode_collation_key("key_name")).to eq("key_name")
    end

    it "uses proc to calculate key" do
      BookmarkedCollection.best_unicode_collation_key_proc = lambda do |col|
        "lower(#{col})"
      end

      expect(BookmarkedCollection.best_unicode_collation_key("key_name")).to eq("lower(key_name)")
    end
  end
end
