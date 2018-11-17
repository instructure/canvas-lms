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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper.rb')

describe Context do
  context "find_by_asset_string" do
    it "should find a valid course" do
      course = Course.create!
      expect(Context.find_by_asset_string(course.asset_string)).to eql(course)
    end

    it "should not find an invalid course" do
      expect(Context.find_by_asset_string("course_0")).to be nil
    end

    it "should find a valid group" do
      group = Group.create!(:context => Account.default)
      expect(Context.find_by_asset_string(group.asset_string)).to eql(group)
    end

    it "should not find an invalid group" do
      expect(Context.find_by_asset_string("group_0")).to be nil
    end

    it "should find a valid account" do
      account = Account.create!(:name => "test")
      expect(Context.find_by_asset_string(account.asset_string)).to eql(account)
    end

    it "should not find an invalid account" do
      expect(Context.find_by_asset_string("account_0")).to be nil
    end

    it "should find a valid user" do
      user = User.create!
      expect(Context.find_by_asset_string(user.asset_string)).to eql(user)
    end

    it "should not find an invalid user" do
      expect(Context.find_by_asset_string("user_0")).to be nil
    end

    it "should not find an invalid asset string" do
      expect(Context.find_by_asset_string("")).to be nil
      expect(Context.find_by_asset_string("loser_5")).to be nil
    end

    it "should not find a valid asset" do
      assignment_model
      expect(Context.find_by_asset_string(@assignment.asset_string)).to be nil
    end

    it "should not find a context with invalid type" do
      expect(Context.find_by_asset_string("WRONG_1")).to be nil
    end
  end

  context "from_context_codes" do
    it "should give contexts for all context_codes sent" do
      account = Account.create!
      user = User.create!
      course = Course.create!
      course2 = Course.create!
      group = Group.create!(context: account)
      context_codes = [account.asset_string, course.asset_string, course2.asset_string, group.asset_string, user.asset_string]
      expect(Context.from_context_codes(context_codes)).to eq [account, course, course2, group, user]
    end

    it "should skip invalid context types" do
      assignment_model
      course = Course.create!
      context_codes = [@assignment.asset_string, course.asset_string, "thing_1"]
      expect(Context.from_context_codes(context_codes)).to eq [course]
    end

    it "should skip invalid context ids" do
      account = Account.default
      context_codes = ["course_hi", "group_0", "user_your_mom", "account_-1", account.asset_string]
      expect(Context.from_context_codes(context_codes)).to eq [account]
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
      expect(@course.find_asset(page.asset_string, [:assignment])).to be nil
    end
    it "should not find an invalid assignment" do
      assignment_model
      @course2 = Course.create!
      expect(@course2.find_asset(@assignment.asset_string)).to be nil
      expect(@course.find_asset("assignment_0")).to be nil
      expect(@course.find_asset("")).to be nil
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

      contexts = course.rubric_contexts(nil).map { |c| c.slice(:name, :rubrics) }
      expect(contexts).to eq([
        { name: 'AAA', rubrics: 1},
        { name: 'MMM', rubrics: 1},
        { name: 'ZZZ', rubrics: 1}
      ])
    end

    context "sharding" do
      specs_require_sharding

      it "should retrieve rubrics from other shard courses the teacher belongs to" do
        course1 = Course.create!(:name => 'c1')
        course2 = Course.create!(:name => 'c2')
        course3 = @shard1.activate do
          a = Account.create!
          Course.create!(:name => 'c3', :account => a)
        end
        user = user_factory(:active_all => true)
        [course1, course2, course3].each do |c|
          c.shard.activate do
            r = Rubric.create!(context: c, title: 'testing')
            RubricAssociation.create!(context: c, rubric: r, purpose: :bookmark, association_object: c)
            c.enroll_user(user, "TeacherEnrollment", :enrollment_state => "active")
          end
        end
        expected = -> { [
          { name: 'c1', rubrics: 1, context_code: course1.asset_string},
          { name: 'c2', rubrics: 1, context_code: course2.asset_string},
          { name: 'c3', rubrics: 1, context_code: course3.asset_string}
        ] }
        expect(course1.rubric_contexts(user)).to match_array(expected.call)
        @shard1.activate do
          expect(course2.rubric_contexts(user)).to match_array(expected.call)
        end
      end
    end
  end

  describe "#active_record_types" do
    let(:course) { Course.create! }

    it "looks at the 'everything' cache if asking for just one thing and doesn't have a cache for that" do

      # it should look first for the cache for just the thing we are asking for
      expect(Rails.cache).to receive(:read).
        with(['active_record_types3', [:assignments], course].cache_key).
        and_return(nil)

      # if that ^ returns nil, it should then look for for the "everything" cache
      expect(Rails.cache).to receive(:read).
        with(['active_record_types3', 'everything', course].cache_key).
        and_return({
          other_thing_we_are_not_asking_for: true,
          assignments: "the cached value for :assignments from the 'everything' cache"
        })

      expect(course.active_record_types(only_check: [:assignments])).to eq({
        assignments: "the cached value for :assignments from the 'everything' cache"
      })
    end

    it "raises an ArgumentError if you pass (only_check: [])" do
      expect{
        course.active_record_types(only_check: [])
      }.to raise_exception ArgumentError
    end

    it "raises an ArgumentError if you pass bogus values as only_check" do
      expect{
        course.active_record_types(only_check: [:bogus_type, :other_bogus_tab])
      }.to raise_exception ArgumentError
    end
  end

  describe "last_updated_at" do
    before :once do
      @course1 = Course.create!(name: "course1", updated_at: 1.year.ago)
      @course2 = Course.create!(name: "course2", updated_at: 1.day.ago)
      @user1 = User.create!(name: "user1", updated_at: 1.year.ago)
      @user2 = User.create!(name: "user2", updated_at: 1.day.ago)
      @group1 = Account.default.groups.create!(:name => "group1", updated_at: 1.year.ago)
      @group2 = Account.default.groups.create!(:name => "group2", updated_at: 1.day.ago)
      @account1 = Account.create!(name: "account1", updated_at: 1.year.ago)
      @account2 = Account.create!(name: "account2", updated_at: 1.day.ago)
    end

    it "returns the latest updated_at date for a given set of context ids" do
      expect(Context.last_updated_at(Course, [@course1.id, @course2.id])).to eq @course2.updated_at
      expect(Context.last_updated_at(User, [@user1.id, @user2.id])).to eq @user2.updated_at
      expect(Context.last_updated_at(Group, [@group1.id, @group2.id])).to eq @group2.updated_at
      expect(Context.last_updated_at(Account, [@account1.id, @account2.id])).to eq @account2.updated_at
    end

    it "raises an error if the class passed is not a context type" do
      expect {Context.last_updated_at(Hash, [1])}.to raise_error ArgumentError
    end

    it "ignores contexts with null updated_at values" do
      @course2.updated_at = nil
      @course2.save!

      expect(Context.last_updated_at(Course, [@course1.id, @course2.id])).to eq @course1.updated_at
    end

    it "returns nil when no updated_at is found for the given contexts" do
      [@course1, @course2].each do |c|
        c.updated_at = nil
        c.save!
      end

      expect(Context.last_updated_at(Course, [@course1.id, @course2.id])).to be_nil
    end
  end
end
