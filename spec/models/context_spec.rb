#
# Copyright (C) 2011 Instructure, Inc.
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

describe Context do
  context "find_by_asset_string" do
    it "should find a valid course" do
      course = Course.create!
      expect(Context.find_by_asset_string(course.asset_string)).to eql(course)
    end
    
    it "should not find an invalid course" do
      expect(Context.find_by_asset_string("course_0")).to eql(nil)
    end
    
    it "should find a valid group" do
      group = Group.create!(:context => Account.default)
      expect(Context.find_by_asset_string(group.asset_string)).to eql(group)
    end
    
    it "should not find an invalid group" do
      expect(Context.find_by_asset_string("group_0")).to eql(nil)
    end
    
    it "should find a valid account" do
      account = Account.create!(:name => "test")
      expect(Context.find_by_asset_string(account.asset_string)).to eql(account)
    end
    
    it "should not find an invalid account" do
      expect(Context.find_by_asset_string("account_0")).to eql(nil)
    end
    
    it "should find a valid user" do
      user = User.create!
      expect(Context.find_by_asset_string(user.asset_string)).to eql(user)
    end
    
    it "should not find an invalid user" do
      expect(Context.find_by_asset_string("user_0")).to eql(nil)
    end
    
    it "should not find an invalid asset string" do
      expect(Context.find_by_asset_string("")).to eql(nil)
      expect(Context.find_by_asset_string("loser_5")).to eql(nil)
    end
    
    it "should not find a valid asset" do
      assignment_model
      Context.find_by_asset_string(@assignment.asset_string)
    end
  end
  
  context "find_asset_by_asset_string" do
    it "should find a valid assignment" do
      assignment_model
      expect(@course.find_asset(@assignment.asset_string)).to eql(@assignment)
    end
    it "should find a valid wiki page" do
      course_model
      page = @course.wiki.wiki_pages.create!(:title => 'test')
      expect(@course.find_asset(page.asset_string)).to eql(page)
      expect(@course.find_asset(page.asset_string, [:wiki_page])).to eql(page)
    end
    it "should not find a valid wiki page if told to ignore wiki pages" do
      course_model
      page = @course.wiki.wiki_pages.create!(:title => 'test')
      expect(@course.find_asset(page.asset_string, [:assignment])).to eql(nil)
    end
    it "should not find an invalid assignment" do
      assignment_model
      @course2 = Course.create!
      expect(@course2.find_asset(@assignment.asset_string)).to eql(nil)
      expect(@course.find_asset("assignment_0")).to eql(nil)
      expect(@course.find_asset("")).to eql(nil)
    end
  end

  context "self.names_by_context_types_and_ids" do
    it "should find context names" do
      contexts = []
      contexts << course1 = Course.create!(:name => "a course")
      contexts << course2 = Course.create!(:name => "another course")
      contexts << group1 = Account.default.groups.create!(:name => "a group")
      contexts << group2 = Account.default.groups.create!(:name => "another group")
      contexts << user = User.create!(:name => "a user")
      names = Context.names_by_context_types_and_ids(contexts.map{|c| [c.class.name, c.id]})
      contexts.each do |c|
        expect(names[[c.class.name, c.id]]).to eql(c.name)
      end
    end
  end
end
