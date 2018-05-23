#
# Copyright (C) 2011 - present Instructure, Inc.
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
  context "find_polymorphic" do
    it "should find a valid context" do
      course = Course.create!
      expect(Context.find_polymorphic("course", course.id)).to eql(course)
    end

    it "should not find a context with invalid type" do
      expect(Context.find_polymorphic("WRONG", 0)).to eql(nil)
    end

    it "should not find a context with invalid id" do
      expect(Context.find_polymorphic("course", 0)).to eql(nil)
    end
  end

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
      page = @course.wiki_pages.create!(:title => 'test')
      expect(@course.find_asset(page.asset_string)).to eql(page)
      expect(@course.find_asset(page.asset_string, [:wiki_page])).to eql(page)
    end
    it "should not find a valid wiki page if told to ignore wiki pages" do
      course_model
      page = @course.wiki_pages.create!(:title => 'test')
      expect(@course.find_asset(page.asset_string, [:assignment])).to eql(nil)
    end
    it "should not find an invalid assignment" do
      assignment_model
      @course2 = Course.create!
      expect(@course2.find_asset(@assignment.asset_string)).to eql(nil)
      expect(@course.find_asset("assignment_0")).to eql(nil)
      expect(@course.find_asset("")).to eql(nil)
    end

    describe "context" do
      before(:once) do
        @course = Course.create!
        @course2 = Course.create!
        attachment_model context: @course
      end

      it "should scope to context if context is provided" do
        expect(Context.find_asset_by_asset_string(@attachment.asset_string, @course)).to eq(@attachment)
        expect(Context.find_asset_by_asset_string(@attachment.asset_string, @course2)).to be_nil
      end

      it "should find in any context if context is not provided" do
        expect(Context.find_asset_by_asset_string(@attachment.asset_string)).to eq(@attachment)
      end
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

  describe '.get_account' do
    it 'returns the account given' do
      expect(Context.get_account(Account.default)).to eq(Account.default)
    end

    it "returns a course's account" do
      expect(Context.get_account(course_model(account: Account.default))).to eq(Account.default)
    end

    it "returns a course section's course's account" do
      expect(Context.get_account(course_model(account: Account.default).course_sections.first)).to eq(Account.default)
    end

    it "returns an account level group's account" do
      expect(Context.get_account(group_model(context: Account.default))).to eq(Account.default)
    end

    it "returns a course level group's course's account" do
      expect(Context.get_account(group_model(context: course_model(account: Account.default)))).to eq(Account.default)
    end
  end

  describe 'asset_name' do
    before :once do
      course_factory
    end

    it "finds names for outcomes" do
      outcome1 = @course.created_learning_outcomes.create! :display_name => 'blah', :title => 'bleh'
      expect(Context.asset_name(outcome1)).to eq 'blah'

      outcome2 = @course.created_learning_outcomes.create! :title => 'bleh'
      expect(Context.asset_name(outcome2)).to eq 'bleh'
    end

    it "finds names for calendar events" do
      event1 = @course.calendar_events.create! :title => 'thing'
      expect(Context.asset_name(event1)).to eq 'thing'

      event2 = @course.calendar_events.create! :title => ''
      expect(Context.asset_name(event2)).to eq ''
    end
  end

  describe '.rubric_contexts' do
    def add_rubric(context)
      r = Rubric.create!(context: context, title: 'testing')
      RubricAssociation.create!(context: context, rubric: r, purpose: :bookmark, association_object: context)
    end

    it 'returns contexts in alphabetically sorted order' do
      great_grandparent = Account.default
      grandparent = Account.create!(name: 'AAA', parent_account: great_grandparent)
      add_rubric(grandparent)
      parent = Account.create!(name: 'ZZZ', parent_account: grandparent)
      add_rubric(parent)
      course = Course.create!(:name => 'MMM', account: parent)
      add_rubric(course)

      contexts = course.rubric_contexts(nil).map { |r| r[:name] }
      expect(contexts).to eq(['AAA', 'MMM', 'ZZZ'])
    end
  end
end
