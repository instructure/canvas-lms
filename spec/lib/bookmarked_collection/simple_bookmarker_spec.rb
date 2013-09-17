#
# Copyright (C) 2013 Instructure, Inc.
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

describe BookmarkedCollection::SimpleBookmarker do

  before do
    @bookmarker = BookmarkedCollection::SimpleBookmarker.new(User, :name, :id)
    @bob = user(name: "bob")
    @bob2 = user(name: "Bob")
    @joe = user(name: "joe")
    @bobby = user(name: "bobby")
    @bill = user(name: "BILL!")
    @in_order = [@bill, @bob, @bob2, @bobby, @joe]
  end

  context "#bookmark_for" do
    it "should be comparable" do
      @bookmarker.bookmark_for(@bob).should be_respond_to(:<=>)
    end

    it "should match the columns, in order" do
      @bookmarker.bookmark_for(@bob).should == [@bob.name, @bob.id]
    end
  end

  context "#validate" do
    it "should validate the bookmark and its contents" do
      @bookmarker.validate({name: "bob", id: 1}).should be_false
      @bookmarker.validate(["bob"]).should be_false
      @bookmarker.validate(["bob", "1"]).should be_false
      @bookmarker.validate(["bob", 1]).should be_true
    end
  end

  context "#restrict_scope" do
    it "should order correctly" do
      pager = stub(current_bookmark: nil)
      @bookmarker.restrict_scope(User, pager).should ==
        [@bill, @bob, @bob2, @bobby, @joe]
    end

    it "should start after the bookmark" do
      bookmark = @bookmarker.bookmark_for(@bob2)
      pager = stub(current_bookmark: bookmark, include_bookmark: false)
      @bookmarker.restrict_scope(User, pager).should ==
        [@bobby, @joe]
    end

    it "should include the bookmark iff include_bookmark" do
      bookmark = @bookmarker.bookmark_for(@bob2)
      pager = stub(current_bookmark: bookmark, include_bookmark: true)
      @bookmarker.restrict_scope(User, pager).should ==
        [@bob2, @bobby, @joe]
    end
  end
end
