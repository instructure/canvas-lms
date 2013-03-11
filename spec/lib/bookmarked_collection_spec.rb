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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe "BookmarkedCollection" do
  class IDBookmarker
    def self.bookmark_for(object)
      object.id
    end

    def self.validate(bookmark)
      # can't actually validate because sometimes it'll be a mock
      true
    end

    def self.restrict_scope(scope, pager)
      if bookmark = pager.current_bookmark
        comparison = (pager.include_bookmark ? 'id >= ?' : 'id > ?')
        scope = scope.scoped(:conditions => [comparison, bookmark])
      end
      scope.scoped(:order => "id ASC")
    end
  end

  class NameBookmarker
    def self.bookmark_for(course)
      course.name
    end

    def self.validate(bookmark)
      bookmark.is_a?(String)
    end

    def self.restrict_scope(scope, pager)
      if bookmark = pager.current_bookmark
        comparison = (pager.include_bookmark ? 'name >= ?' : 'name > ?')
        scope = scope.scoped(:conditions => [comparison, bookmark])
      end
      scope.scoped(:order => "name ASC")
    end
  end

  describe ".wrap" do
    before :each do
      @scope = Course
      3.times{ @scope.create! }
    end

    it "should return a WrapProxy" do
      BookmarkedCollection.wrap(IDBookmarker, @scope).should be_a(PaginatedCollection::Proxy)
    end

    it "should use the provided scope when executing pagination" do
      collection = BookmarkedCollection.wrap(IDBookmarker, @scope)
      collection.paginate(:per_page => 1).should == [@scope.first]
    end

    it "should use the bookmarker's bookmark generator to produce bookmarks" do
      bookmark = stub
      IDBookmarker.stubs(:bookmark_for).returns(bookmark)

      collection = BookmarkedCollection.wrap(IDBookmarker, @scope)
      collection.paginate(:per_page => 1).next_bookmark.should == bookmark
    end

    it "should use the bookmarker's bookmark applicator to restrict by bookmark" do
      bookmark = @scope.scoped(:order => 'courses.id').first.id
      bookmarked_scope = @scope.scoped(:order => 'courses.id', :conditions => ['courses.id > ?', bookmark])
      IDBookmarker.stubs(:restrict_scope).returns(bookmarked_scope)

      collection = BookmarkedCollection.wrap(IDBookmarker, @scope)
      collection.paginate(:per_page => 1).should == [bookmarked_scope.first]
    end

    it "should apply any options given to the scope" do
      course = @scope.scoped(:order => 'courses.id').last
      course.update_attributes(:name => 'Matching Name')

      collection = BookmarkedCollection.wrap(IDBookmarker, @scope, :conditions => {:name => course.name})
      collection.paginate(:per_page => 1).should == [course]
    end

    it "should apply any restriction block given to the scope" do
      course = @scope.scoped(:order => 'courses.id').last
      course.update_attributes(:name => 'Matching Name')

      collection = BookmarkedCollection.wrap(IDBookmarker, @scope) do |scope|
        scope.scoped(:conditions => {:name => course.name})
      end

      collection.paginate(:per_page => 1).should == [course]
    end
  end

  describe ".merge" do
    before :each do
      @created_scope = Course.scoped(:conditions => {:workflow_state => 'created'})
      @deleted_scope = Course.scoped(:conditions => {:workflow_state => 'deleted'})

      Course.delete_all
      @created_course1 = @created_scope.create!
      @deleted_course1 = @deleted_scope.create!
      @created_course2 = @created_scope.create!
      @deleted_course2 = @deleted_scope.create!

      @created_collection = BookmarkedCollection.wrap(IDBookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(IDBookmarker, @deleted_scope)
      @collection = BookmarkedCollection.merge(
        ['created', @created_collection],
        ['deleted', @deleted_collection]
      )
    end

    it "should return a merge proxy" do
      @collection.should be_a(BookmarkedCollection::MergeProxy)
    end

    it "should merge the given collections" do
      @collection.paginate(:per_page => 2).should == [@created_course1, @deleted_course1]
    end

    it "should have a next page when there's a non-exhausted collection" do
      @collection.paginate(:per_page => 3).next_page.should_not be_nil
    end

    it "should not have a next page when all collections are exhausted" do
      @collection.paginate(:per_page => 4).next_page.should be_nil
    end

    it "should pick up in the middle of a collection" do
      page = @collection.paginate(:per_page => 1)
      page.should == [@created_course1]
      page.next_bookmark.should_not be_nil

      @collection.paginate(:page => page.next_page, :per_page => 2).should == [@deleted_course1, @created_course2]
    end

    context "with ties across collections" do
      before :each do
        # the name bookmarker will generate the same bookmark for both of the
        # courses.
        Course.delete_all
        @created_course = @created_scope.create!(:name => "Same Name")
        @deleted_course = @deleted_scope.create!(:name => "Same Name")

        @created_collection = BookmarkedCollection.wrap(NameBookmarker, @created_scope)
        @deleted_collection = BookmarkedCollection.wrap(NameBookmarker, @deleted_scope)
        @collection = BookmarkedCollection.merge(
          ['created', @created_collection],
          ['deleted', @deleted_collection]
        )
      end

      it "should sort the ties by collection" do
        @collection.paginate(:per_page => 2).should == [@created_course, @deleted_course]
      end

      it "should pick up at the right place when a page break splits the tie" do
        page = @collection.paginate(:per_page => 1)
        page.should == [@created_course]
        page.next_bookmark.should_not be_nil

        page = @collection.paginate(:page => page.next_page, :per_page => 1)
        page.should == [@deleted_course]
        page.next_bookmark.should be_nil
      end
    end
  end

  describe ".concat" do
    before :each do
      @created_scope = Course.scoped(:conditions => {:workflow_state => 'created'})
      @deleted_scope = Course.scoped(:conditions => {:workflow_state => 'deleted'})

      Course.delete_all
      @created_course1 = @created_scope.create!
      @deleted_course1 = @deleted_scope.create!
      @created_course2 = @created_scope.create!
      @deleted_course2 = @deleted_scope.create!

      @created_collection = BookmarkedCollection.wrap(IDBookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(IDBookmarker, @deleted_scope)
      @collection = BookmarkedCollection.concat(
        ['created', @created_collection],
        ['deleted', @deleted_collection]
      )
    end

    it "should return a concat proxy" do
      @collection.should be_a(BookmarkedCollection::ConcatProxy)
    end

    it "should concatenate the given collections" do
      @collection.paginate(:per_page => 3).should == [@created_course1, @created_course2, @deleted_course1]
    end

    it "should have a next page when there's a non-exhausted collection" do
      @collection.paginate(:per_page => 3).next_page.should_not be_nil
    end

    it "should have a next page on the border between an exhausted collection and a non-exhausted collection" do
      @collection.paginate(:per_page => 2).next_page.should_not be_nil
    end

    it "should not have a next page when all collections are exhausted" do
      @collection.paginate(:per_page => 4).next_page.should be_nil
    end

    it "should pick up in the middle of a collection" do
      page = @collection.paginate(:per_page => 1)
      page.should == [@created_course1]
      page.next_bookmark.should_not be_nil

      @collection.paginate(:page => page.next_page, :per_page => 2).should == [@created_course2, @deleted_course1]
    end

    it "should pick up from a break between collections" do
      page = @collection.paginate(:per_page => 2)
      page.should == [@created_course1, @created_course2]
      page.next_bookmark.should_not be_nil

      @collection.paginate(:page => page.next_page, :per_page => 2).should == [@deleted_course1, @deleted_course2]
    end
  end

  describe "nested compositions" do
    before :each do
      @user_scope = User
      @created_scope = Course.scoped(:conditions => {:workflow_state => 'created'})
      @deleted_scope = Course.scoped(:conditions => {:workflow_state => 'deleted'})

      # user's names are so it sorts Created X < Creighton < Deanne < Deleted
      # X when using NameBookmarks
      Course.delete_all
      User.delete_all
      @user1 = @user_scope.create!(:name => "Creighton")
      @user2 = @user_scope.create!(:name => "Deanne")
      @created_course1 = @created_scope.create!(:name => "Created 1")
      @deleted_course1 = @deleted_scope.create!(:name => "Deleted 1")
      @created_course2 = @created_scope.create!(:name => "Created 2")
      @deleted_course2 = @deleted_scope.create!(:name => "Deleted 2")
    end

    it "should handle concat(A, merge(B, C))" do
      @user_collection = BookmarkedCollection.wrap(IDBookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(IDBookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(IDBookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.merge(
        ['created', @created_collection],
        ['deleted', @deleted_collection]
      )

      @collection = BookmarkedCollection.concat(
        ['users', @user_collection],
        ['courses', @course_collection]
      )

      page = @collection.paginate(:per_page => 4)
      page.should == [@user1, @user2, @created_course1, @deleted_course1]
      page.next_page.should_not be_nil

      page = @collection.paginate(:page => page.next_page, :per_page => 2)
      page.should == [@created_course2, @deleted_course2]
      page.next_page.should be_nil
    end

    it "should handle merge(A, merge(B, C))" do
      # use NameBookmarker to make user/course merge interesting
      @user_collection = BookmarkedCollection.wrap(NameBookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(NameBookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(NameBookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.merge(
        ['created', @created_collection],
        ['deleted', @deleted_collection]
      )

      @collection = BookmarkedCollection.merge(
        ['users', @user_collection],
        ['courses', @course_collection]
      )

      page = @collection.paginate(:per_page => 3)
      page.should == [@created_course1, @created_course2, @user1]
      page.next_page.should_not be_nil

      page = @collection.paginate(:page => page.next_page, :per_page => 3)
      page.should == [@user2, @deleted_course1, @deleted_course2]
      page.next_page.should be_nil
    end

    it "should handle concat(A, concat(B, C))" do
      @user_collection = BookmarkedCollection.wrap(IDBookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(IDBookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(IDBookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.concat(
        ['created', @created_collection],
        ['deleted', @deleted_collection])

      @collection = BookmarkedCollection.concat(
        ['users', @user_collection],
        ['courses', @course_collection])

      page = @collection.paginate(:per_page => 3)
      page.should == [@user1, @user2, @created_course1]
      page.next_page.should_not be_nil

      page = @collection.paginate(:page => page.next_page, :per_page => 3)
      page.should == [@created_course2, @deleted_course1, @deleted_course2]
      page.next_page.should be_nil
    end

    it "should not allow merge(A, concat(B, C))" do
      @user_collection = BookmarkedCollection.wrap(NameBookmarker, @user_scope)
      @created_collection = BookmarkedCollection.wrap(NameBookmarker, @created_scope)
      @deleted_collection = BookmarkedCollection.wrap(NameBookmarker, @deleted_scope)

      @course_collection = BookmarkedCollection.concat(
        ['created', @created_collection],
        ['deleted', @deleted_collection])

      expect{
        @collection = BookmarkedCollection.merge(
          ['users', @user_collection],
          ['courses', @course_collection])
      }.to raise_exception ArgumentError
    end
  end
end
