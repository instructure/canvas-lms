# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe BookmarkedCollection::SimpleBookmarker do
  before do
    @example_class = Class.new(ActiveRecord::Base) do
      self.table_name = "examples"
    end

    BookmarkedCollection.best_unicode_collation_key_proc = lambda do |col|
      "lower(#{col})"
    end

    @bookmarker = BookmarkedCollection::SimpleBookmarker.new(@example_class, :name, :id)
    @date_bookmarker = BookmarkedCollection::SimpleBookmarker.new(@example_class, :date, :id)
    @custom_bookmarker = BookmarkedCollection::SimpleBookmarker.new(@example_class,
                                                                    { unbobbed_name: { type: :string, null: false } },
                                                                    :id)

    @bob = @example_class.create!(name: "bob")
    @bob2 = @example_class.create!(name: "Bob", date: DateTime.now.to_s)
    @joe = @example_class.create!(name: "joe")
    @bobby = @example_class.create!(name: "bobby")
    @bill = @example_class.create!(name: "BILL!")
  end

  context "#bookmark_for" do
    it "is comparable" do
      expect(@bookmarker.bookmark_for(@bob)).to respond_to(:<=>)
    end

    it "matches the columns, in order" do
      expect(@bookmarker.bookmark_for(@bob)).to eq([@bob.name, @bob.id])
    end
  end

  context "#validate" do
    it "validates the bookmark and its contents" do
      expect(@bookmarker.validate({ name: "bob", id: 1 })).to be_falsey
      expect(@bookmarker.validate(["bob"])).to be_falsey
      expect(@bookmarker.validate(["bob", "1"])).to be_falsey
      expect(@bookmarker.validate(["bob", 1])).to be_truthy

      # With dates
      expect(@date_bookmarker.validate({ date: DateTime.now.to_s, id: 1 })).to be_falsey
      expect(@date_bookmarker.validate(["bob"])).to be_falsey
      expect(@date_bookmarker.validate([DateTime.now, 1])).to be true
      expect(@date_bookmarker.validate([DateTime.now.to_s, 1])).to be true

      # with custom stuff
      expect(@custom_bookmarker.validate(["llib", 1])).to be true
      expect(@custom_bookmarker.validate([2, 1])).to be_falsey
    end
  end

  context "#restrict_scope" do
    it "orders correctly" do
      pager = double(current_bookmark: nil)
      expect(@bookmarker.restrict_scope(@example_class, pager)).to eq(
        [@bill, @bob, @bob2, @bobby, @joe]
      )
    end

    it "orders with nullable columns, having non-null values first" do
      pager = double(current_bookmark: nil)
      expect(@date_bookmarker.restrict_scope(@example_class, pager)).to eq(
        [@bob2, @bob, @joe, @bobby, @bill]
      )
    end

    it "starts after the bookmark" do
      bookmark = @bookmarker.bookmark_for(@bob2)
      pager = double(current_bookmark: bookmark, include_bookmark: false)
      expect(@bookmarker.restrict_scope(@example_class, pager)).to eq(
        [@bobby, @joe]
      )
    end

    it "starts after the bookmark when nullable columns exist" do
      bookmark = @date_bookmarker.bookmark_for(@joe)
      pager = double(current_bookmark: bookmark, include_bookmark: false)
      expect(@date_bookmarker.restrict_scope(@example_class, pager)).to eq(
        [@bobby, @bill]
      )
    end

    it "includes the bookmark if and only if include_bookmark" do
      bookmark = @bookmarker.bookmark_for(@bob2)
      pager = double(current_bookmark: bookmark, include_bookmark: true)
      expect(BookmarkedCollection).to receive(:best_unicode_collation_key).at_least(:once).and_call_original
      expect(@bookmarker.restrict_scope(@example_class, pager)).to eq(
        [@bob2, @bobby, @joe]
      )
    end

    it "skips collation if specified" do
      @non_collated_bookmarker = BookmarkedCollection::SimpleBookmarker.new(@example_class,
                                                                            { name: { skip_collation: true } },
                                                                            :id)
      pager = double(current_bookmark: nil)
      expect(BookmarkedCollection).not_to receive(:best_unicode_collation_key)
      expect(@non_collated_bookmarker.restrict_scope(@example_class, pager)).to eq(
        [@bill, @bob2, @bob, @bobby, @joe]
      )
    end

    it "works with custom columns" do
      pager = double(current_bookmark: nil)
      scope = @example_class.select("examples.*, replace(examples.name, 'bob', 'robert') AS unbobbed_name")
      result = @custom_bookmarker.restrict_scope(scope, pager).to_a
      expect(result).to eq(
        [@bill, @bob2, @joe, @bob, @bobby]
      )
      @bob_with_custom = result[3]
      expect(@bob_with_custom.unbobbed_name).to eq "robert"

      bookmark = @custom_bookmarker.bookmark_for(@bob_with_custom)
      pager2 = double(current_bookmark: bookmark, include_bookmark: false)
      expect(@custom_bookmarker.restrict_scope(scope, pager2)).to eq(
        [@bobby]
      )
    end
  end
end
