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

describe GroupCategory do
  let_once(:account) { Account.default }
  before(:once) { course_with_teacher(active_all: true) }

  it 'delegates time_zone through to its context' do
    zone = ActiveSupport::TimeZone["America/Denver"]
    course = Course.new(time_zone: zone)
    category = GroupCategory.new(context: course)
    expect(category.time_zone.to_s).to match /Mountain Time/
  end

  context "protected_name_for_context?" do
    it "should be false for 'Student Groups' in accounts" do
      is_protected = GroupCategory.protected_name_for_context?('Student Groups', account)
      expect(is_protected).to be_falsey
    end

    it "should be true for 'Student Groups' in courses" do
      course = @course
      expect(GroupCategory.protected_name_for_context?('Student Groups', course)).to be_truthy
    end

    it "should be true for 'Imported Groups' in both accounts and courses" do
      course = @course
      expect(GroupCategory.protected_name_for_context?('Imported Groups', account)).to be_truthy
      expect(GroupCategory.protected_name_for_context?('Imported Groups', course)).to be_truthy
    end
  end

  context "student_organized_for" do
    it "should be nil in accounts" do
      expect(GroupCategory.student_organized_for(account)).to be_nil
    end

    it "should be a category belonging to the course with role 'student_organized' in courses" do
      course = @course
      category = GroupCategory.student_organized_for(course)
      expect(category).not_to be_nil
      expect(category.role).to eql('student_organized')
      expect(category.context).to eql(course)
    end

    it "should be the the same category every time for the same course" do
      course = @course
      category1 = GroupCategory.student_organized_for(course)
      category2 = GroupCategory.student_organized_for(course)
      expect(category1.id).to eql(category2.id)
    end
  end

  context "communities_for" do
    it "should be nil in courses" do
      expect(GroupCategory.communities_for(@course)).to be_nil
    end

    it "should be a category belonging to the account with role 'communities'" do
      category = GroupCategory.communities_for(account)
      expect(category).not_to be_nil
      expect(category.role).to eql('communities')
      expect(category.context).to eql(account)
    end

    it "should be the the same category every time for the same account" do
      category1 = GroupCategory.communities_for(account)
      category2 = GroupCategory.communities_for(account)
      expect(category1.id).to eql(category2.id)
    end
  end

  context "imported_for" do
    it "should be a category belonging to the account with role 'imported' in accounts" do
      category = GroupCategory.imported_for(account)
      expect(category).not_to be_nil
      expect(category.role).to eql('imported')
      expect(category.context).to eql(account)
    end

    it "should be a category belonging to the course with role 'imported' in courses" do
      course = @course
      category = GroupCategory.imported_for(course)
      expect(category).not_to be_nil
      expect(category.role).to eql('imported')
      expect(category.context).to eql(course)
    end

    it "should be the the same category every time for the same context" do
      course = @course
      category1 = GroupCategory.imported_for(course)
      category2 = GroupCategory.imported_for(course)
      expect(category1.id).to eql(category2.id)
    end
  end

  context 'student_organized?' do
    it "should be true iff the role is 'student_organized', regardless of name" do
      course = @course
      expect(GroupCategory.student_organized_for(course)).to be_student_organized
      expect(account.group_categories.create(:name => 'Student Groups')).not_to be_student_organized
      expect(GroupCategory.imported_for(course)).not_to be_student_organized
      expect(GroupCategory.imported_for(course)).not_to be_student_organized
      expect(course.group_categories.create(:name => 'Random Category')).not_to be_student_organized
      expect(GroupCategory.communities_for(account)).not_to be_student_organized
    end
  end

  context 'communities?' do
    it "should be true iff the role is 'communities', regardless of name" do
      course = @course
      expect(GroupCategory.student_organized_for(course)).not_to be_communities
      expect(account.group_categories.create(:name => 'Communities')).not_to be_communities
      expect(GroupCategory.imported_for(course)).not_to be_communities
      expect(GroupCategory.imported_for(course)).not_to be_communities
      expect(course.group_categories.create(:name => 'Random Category')).not_to be_communities
      expect(GroupCategory.communities_for(account)).to be_communities
    end
  end

  context 'allows_multiple_memberships?' do
    it "should be true iff the category is student organized or communities" do
      course = @course
      expect(GroupCategory.student_organized_for(course).allows_multiple_memberships?).to be_truthy
      expect(account.group_categories.create(:name => 'Student Groups').allows_multiple_memberships?).to be_falsey
      expect(GroupCategory.imported_for(course).allows_multiple_memberships?).to be_falsey
      expect(GroupCategory.imported_for(course).allows_multiple_memberships?).to be_falsey
      expect(course.group_categories.create(:name => 'Random Category').allows_multiple_memberships?).to be_falsey
      expect(GroupCategory.communities_for(account).allows_multiple_memberships?).to be_truthy
    end
  end

  context 'protected?' do
    it "should be true iff the category has a role other than 'imported'" do
      course = @course
      expect(GroupCategory.student_organized_for(course)).to be_protected
      expect(account.group_categories.create(:name => 'Student Groups')).not_to be_protected
      expect(GroupCategory.imported_for(course)).not_to be_protected
      expect(course.group_categories.create(:name => 'Random Category')).not_to be_protected
      expect(GroupCategory.communities_for(account)).to be_protected
    end
  end

  context 'destroy' do
    it "should not remove the database row" do
      category = GroupCategory.create(name: "foo", course: @course)
      category.destroy
      expect{ GroupCategory.find(category.id) }.not_to raise_error
    end

    it "should set deleted_at upon destroy" do
      category = GroupCategory.create(name: "foo", course: @course)
      category.destroy
      category.reload
      expect(category.deleted_at?).to eq true
    end

    it "should destroy dependent groups" do
      course = @course
      category = group_category
      group1 = category.groups.create(:context => course)
      group2 = category.groups.create(:context => course)
      course.reload
      expect(course.groups.active.count).to eq 2
      category.destroy
      course.reload
      expect(course.groups.active.count).to eq 0
      expect(course.groups.count).to eq 2
    end
  end


  it "can pass through selfsignup info given (enabled, restricted)" do
    @category = GroupCategory.new
    @category.name = "foo"
    @category.context = course_factory()
    @category.self_signup = 'enabled'
    expect(@category.self_signup?).to be_truthy
    expect(@category.unrestricted_self_signup?).to be_truthy
  end

  it "should default to no self signup" do
    category = GroupCategory.new
    expect(category.self_signup?).to be_falsey
    expect(category.unrestricted_self_signup?).to be_falsey
  end

  context "has_heterogenous_group?" do
    it "should be false for accounts" do
      category = group_category(context: account)
      group = category.groups.create(:context => account)
      expect(category).not_to have_heterogenous_group
    end

    it "should be true if two students that don't share a section are in the same group" do
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      category = group_category
      group = category.groups.create(:context => @course)
      group.add_user(user1)
      group.add_user(user2)
      expect(category).to have_heterogenous_group
    end

    it "should be false if all students in each group have a section in common" do
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      category = group_category
      group = category.groups.create(:context => @course)
      group.add_user(user1)
      group.add_user(user2)
      expect(category).not_to have_heterogenous_group
    end
  end

  describe "max_membership_change" do
    it "should update groups if the group limit changed" do
      category = group_category
      category.group_limit = 2
      category.save
      group = category.groups.create(:context => @course)
      expect(group.max_membership).to eq 2
      category.group_limit = 4
      category.save
      expect(group.reload.max_membership).to eq 4
    end
  end

  describe "group_for" do
    before :once do
      student_in_course(:active_all => true)
      @category = group_category
    end

    it "should return nil if no groups in category" do
      expect(@category.group_for(@student)).to be_nil
    end

    it "should return nil if no active groups in category" do
      group = @category.groups.create(:context => @course)
      gm = group.add_user(@student)
      group.destroy
      expect(@category.group_for(@student)).to be_nil
    end

    it "should return the group the student is in" do
      group1 = @category.groups.create(:context => @course)
      group2 = @category.groups.create(:context => @course)
      group2.add_user(@student)
      expect(@category.group_for(@student)).to eq group2
    end
  end

  context "#distribute_members_among_groups" do
    it "should prefer groups with fewer users" do
      category = @course.group_categories.create(:name => "Group Category")
      group1 = category.groups.create(:name => "Group 1", :context => @course)
      group2 = category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      student3 = @course.enroll_student(user_model).user
      student4 = @course.enroll_student(user_model).user
      student5 = @course.enroll_student(user_model).user
      student6 = @course.enroll_student(user_model).user
      group1.add_user(student1)
      group1.add_user(student2)

      groups = category.groups.active
      potential_members = @course.users_not_in_groups(groups)
      memberships = category.distribute_members_among_groups(potential_members, groups)
      student_ids = [student3.id, student4.id, student5.id, student6.id]
      expect(memberships.map { |m| m.user_id }.sort).to eq student_ids.sort

      grouped_memberships = memberships.group_by { |m| m.group_id }
      expect(grouped_memberships[group1.id].size).to eq 1
      expect(grouped_memberships[group2.id].size).to eq 3
    end

    it "assigns leaders according to policy" do
      category = @course.group_categories.create(:name => "Group Category")
      category.update_attribute(:auto_leader, 'first')
      (1..3).each{|n| category.groups.create(:name => "Group #{n}", :context => @course) }
      create_users_in_course(@course, 6)

      groups = category.groups.active
      groups.each{|group| expect(group.reload.leader).to be_nil}
      potential_members = @course.users_not_in_groups(groups)
      category.distribute_members_among_groups(potential_members, groups)
      groups.each{|group| expect(group.reload.leader).not_to be_nil}
    end

    it "should update cached due dates for affected assignments" do
      category = @course.group_categories.create(:name => "Group Category")
      assignment1 = @course.assignments.create!
      assignment2 = @course.assignments.create! group_category: category
      group = category.groups.create(:name => "Group 1", :context => @course)
      student = @course.enroll_student(user_model).user

      expect(DueDateCacher).to receive(:recompute_course).with(@course.id, assignments: [assignment2.id])
      category.distribute_members_among_groups([student], [group])
    end
  end

  context "#assign_unassigned_members_in_background" do
    it "should use the progress object" do
      category = @course.group_categories.create(:name => "Group Category")
      group1 = category.groups.create(:name => "Group 1", :context => @course)
      group2 = category.groups.create(:name => "Group 2", :context => @course)
      student1, student2 = create_users_in_course(@course, 2, return_type: :record)
      group2.add_user(student1)

      category.assign_unassigned_members_in_background
      expect(category.current_progress.completion).to eq 0

      run_jobs

      expect(category.progresses.last).to be_completed
    end
  end

  context "#assign_unassigned_members" do
    before(:once) do
      @category = @course.group_categories.create(:name => "Group Category")
    end

    it "should not assign inactive users to groups" do
      group1 = @category.groups.create(:name => "Group 1", :context => @course)
      student1 = @course.enroll_student(user_model).user
      inactive_en = @course.enroll_student(user_model)
      inactive_en.deactivate

      # group1 now has fewer students, and would be favored if it weren't
      # destroyed. make sure the unassigned student (student2) is assigned to
      # group2 instead of group1
      memberships = @category.assign_unassigned_members
      expect(memberships.size).to eq 1
      expect(memberships.first.user).to eq student1
    end

    it "should not assign users to inactive groups" do
      group1 = @category.groups.create(:name => "Group 1", :context => @course)
      group2 = @category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      group2.add_user(student1)
      group1.destroy


      # group1 now has fewer students, and would be favored if it weren't
      # destroyed. make sure the unassigned student (student2) is assigned to
      # group2 instead of group1
      memberships = @category.assign_unassigned_members
      expect(memberships.size).to eq 1
      expect(memberships.first.group_id).to eq group2.id
    end

    it "should not assign users already in group in the @category" do
      group1 = @category.groups.create(:name => "Group 1", :context => @course)
      group2 = @category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      group2.add_user(student1)

      # student1 shouldn't get assigned, already being in a group
      memberships = @category.assign_unassigned_members
      expect(memberships.map { |m| m.user }).not_to include(student1)
    end

    it "should otherwise assign ungrouped users to groups in the @category" do
      group1 = @category.groups.create(:name => "Group 1", :context => @course)
      group2 = @category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      group2.add_user(student1)

      # student2 should get assigned, not being in a group
      memberships = @category.assign_unassigned_members
      expect(memberships.map { |m| m.user }).to include(student2)
    end

    it "should handle unequal group sizes" do
      initial_spread  = [0, 0, 0]
      max_memberships = [2, 3, 4]
      result_spread   = [2, 3, 4]
      assert_random_group_assignment(@category, @course, initial_spread, result_spread, max_memberships: max_memberships)
    end

    it "should not overassign to groups" do
      groups = (2..4).map{ |i| @category.groups.create(name: "Group #{i}", max_membership: i, context: @course)}
      students = (1..10).map { |i| @course.enroll_student(user_model).user }
      memberships = @category.assign_unassigned_members
      expect(memberships.size).to be 9
      groups.each(&:reload)
      expect(groups[0].users.size).to be 2
      expect(groups[1].users.size).to be 3
      expect(groups[2].users.size).to be 4
    end

    it "puts leftovers into groups with no cap" do
      initial_spread  = [0, 0, 0]
      max_memberships = [nil, 2, 5]
      result_spread   = [2, 5, 14]
      assert_random_group_assignment(@category, @course, initial_spread, result_spread, max_memberships: max_memberships)
    end

    it "should assign unassigned users while respecting group limits in the category" do
      initial_spread = [0, 0, 0]
      result_spread = [2, 2, 2]
      opts = {group_limit: 2,
              expected_leftover_count: 1}
      assert_random_group_assignment(@category, @course, initial_spread, result_spread, opts)
    end

    it "should assign unassigned users correctly to empty groups in the category" do
      initial_spread = [0, 0, 0]
      result_spread = [3, 3, 3]
      assert_random_group_assignment(@category, @course, initial_spread, result_spread)
    end

    it "should assign unassigned users correctly to evenly sized groups in the category" do
      initial_spread = [2, 2, 2]
      result_spread = [5, 5, 5]
      assert_random_group_assignment(@category, @course, initial_spread, result_spread)
    end

    it "should assign unassigned users correctly to unevenly sized groups where member_count > delta_required in the category" do
      initial_spread = [1, 2, 3]
      result_spread = [5, 5, 6]
      assert_random_group_assignment(@category, @course, initial_spread, result_spread)
    end

    it "should assign unassigned users correctly to unevenly sized groups where member_count = delta_required in the category" do
      initial_spread = [0, 1, 5]
      result_spread = [5, 5, 5]
      assert_random_group_assignment(@category, @course, initial_spread, result_spread)
    end

    it "should assign unassigned users correctly to unevenly sized groups where member_count < delta_required in the category" do
      initial_spread = [0, 1, 7]
      result_spread = [4, 5, 7]
      assert_random_group_assignment(@category, @course, initial_spread, result_spread)
    end
  end

  context "#current_progress" do
    it "should return a new progress if the other progresses are completed" do
      category = @course.group_categories.create!(:name => "Group Category")
      # given existing completed progress
      expect(category.current_progress).to be_nil
      category.send :start_progress
      category.send :complete_progress
      category.reload
      expect(category.progresses.count).to eq 1
      expect(category.current_progress).to be_nil
      # expect new progress
      category.send :start_progress
      expect(category.progresses.count).to eq 2
    end
  end

  context "#clone_groups_and_memberships" do
    it "should not duplicate wiki ids" do
      category = @course.group_categories.create!(:name => "Group Category")
      group = category.groups.create!(name: "Group 1", context: @course)
      group.wiki # this creates a wiki for the group
      expect(group.wiki_id).not_to be_nil

      new_category = @course.group_categories.create!(:name => "New Group Category")
      category.clone_groups_and_memberships(new_category)
      new_category.reload
      new_group = new_category.groups.first

      expect(new_group.wiki_id).to be_nil
    end
  end

  describe "randomly assigning by section" do
    context "group size distribution" do
      def test_group_distribution(section_counts, group_count)
        calc = GroupCategory::GroupBySectionCalculator.new(nil)
        mock_users_by_section = {}
        section_counts.each_with_index do |u_count, idx|
          mock_users_by_section[idx] = double(:count => u_count)
        end
        calc.users_by_section_id = mock_users_by_section
        calc.user_count = section_counts.sum
        calc.groups = double(:count => group_count)
        dist = calc.determine_group_distribution
        dist.sort_by{|k, v| k}.map(&:last)
      end

      it "should handle small sections" do
        # it would normally try to go for 5 students per group since 20 / 4
        # but since we have small sections we'll have to increase the group sizes for the big section
        expect(test_group_distribution([2, 3, 15], 4)).to eq [[2], [3], [8, 7]]
      end

      it "should try to smartishly distribute users" do
        # can't keep things perfectly evenly distributed, but we can try our best
        expect(test_group_distribution([2, 3, 14, 11], 10)).to eq [[2], [3], [3, 3, 3, 3, 2], [4, 4, 3]]
      end

      it "should not split up groups twice in a row" do
        # my original implementation would have made split the last section up into 5 groups
        # because it still had the largest remainder after splitting once
        expect(test_group_distribution([5, 5, 9, 11], 10)).to eq [[5], [3, 2], [3, 3, 3], [3, 3, 3, 2]]
        expect(test_group_distribution([9, 5, 5, 11], 10)).to eq [[3, 3, 3], [5], [3, 2], [3, 3, 3, 2]] # order shouldn't matter - should split the big one first
      end

      it "should not split up a small section (with comparitively large group sizes) if it would be smarter to not" do
        expect(test_group_distribution([8, 8, 30, 8, 8], 10)).to eq [[8], [8], [5, 5, 5, 5, 5, 5], [8], [8]] # would rather go to size 5 in the big section than size 4 in the other
      end
    end

    before :once do
      @category = @course.group_categories.create!(:name => "category")
    end

    it "should require as many groups as sections" do
      section2 = @course.course_sections.create!
      student_in_course(:course => @course)
      student_in_course(:course => @course, :section => section2)
      @category.groups.create!(:name => "group", :context => @course)

      expect(@category.distribute_members_among_groups_by_section).to be_falsey
      expect(@category.errors.full_messages.first).to include("Must have at least as many groups as sections")
    end

    it "should require empty groups" do
      student_in_course(:course => @course)
      group = @category.groups.create!(:name => "group", :context => @course)
      group.add_user(@student)

      expect(@category.distribute_members_among_groups_by_section).to be_falsey
      expect(@category.errors.full_messages.first).to include("Groups must be empty")
    end

    it "should complain if groups have size restrictions" do
      group = @category.groups.create!(:name => "group", :context => @course)
      group.max_membership = 2
      group.save!

      expect(@category.distribute_members_among_groups_by_section).to be_falsey
      expect(@category.errors.full_messages.first).to include("Groups cannot have size restrictions")
    end

    it "should be able to randomly distribute members into groups" do
      section1 = @course.default_section
      section2 = @course.course_sections.create!
      section3 = @course.course_sections.create!

      users_to_section = {}
      create_users_in_course(@course, 2, return_type: :record, section_id: section1.id).each do |user|
        users_to_section[user] = section1
      end
      create_users_in_course(@course, 4, return_type: :record, section_id: section2.id).each do |user|
        users_to_section[user] = section2
      end
      create_users_in_course(@course, 6, return_type: :record, section_id: section3.id).each do |user|
        users_to_section[user] = section3
      end

      groups = []
      6.times { |i| groups << @category.groups.create(:name => "Group #{i}", :context => @course) }

      expect(@category.distribute_members_among_groups_by_section).to be_truthy
      groups.each do |group|
        group.reload
        expect(group.users.count).to eq 2
        u1, u2 = group.users.to_a
        expect(users_to_section[u1]).to eq users_to_section[u2] # should be in same section
      end
      expect(groups.map(&:users).flatten).to match_array users_to_section.keys # should have distributed everybody
    end

    it "should catch errors and fail the current progress" do
      expect_any_instantiation_of(@category).to receive(:distribute_members_among_groups_by_section).and_raise("oh noes")
      @category.assign_unassigned_members_in_background(true)
      run_jobs

      progress = @category.progresses.last
      expect(progress).to be_failed
      expect(progress.message).to include("oh noes")
    end

    it "should not explode when there are more groups than students" do
      student_in_course(:course => @course)

      groups = []
      2.times { |i| groups << @category.groups.create(:name => "Group #{i}", :context => @course) }

      expect(@category.distribute_members_among_groups_by_section).to be_truthy
      expect(groups.map(&:users).flatten).to eq [@student]
    end

    it "should auto-assign leaders if necessary" do
      student_in_course(:course => @course)

      group = @category.groups.create(:name => "Group", :context => @course)
      @category.update_attribute(:auto_leader, 'first')

      @category.assign_unassigned_members(true)
      expect(group.reload.users).to eq [@student]
      expect(group.leader).to eq @student
    end
  end

  it 'should set root_account_id when created' do
    group_category = GroupCategory.create!(name: 'Test', account: account)
    group_category_course = GroupCategory.create!(name: 'Test', course: @course)

    expect(group_category.root_account_id).to eq(account.id)
    expect(group_category_course.root_account_id).to eq(account.id)
  end

  it 'should require a group category to belong to an account or course' do
    expect {
      GroupCategory.create!(name: 'Test') # don't provide an account or course; should fail
    }.to raise_error(ActiveRecord::RecordInvalid)

    gc = GroupCategory.create(name: 'Test')
    expect(gc.errors.full_messages).to include('Context Must have an account or course ID')
    expect(gc.errors.full_messages).to include('Context type Must belong to an account or course')
  end

  it 'should make sure sis_batch_id is valid' do
    expect {
      GroupCategory.create!(name: 'Test', account: account, sis_batch_id: 1)
    }.to raise_error(ActiveRecord::InvalidForeignKey)

    sis_batch = SisBatch.create!(account: account)
    gc = GroupCategory.create!(name: 'Test2', account: account, sis_batch: sis_batch)
    expect(gc.sis_batch_id).to eq(sis_batch.id)
  end

  it 'should make sure sis_source_id is unique per root_account' do
    GroupCategory.create!(name: 'Test', account: account, sis_source_id: '1')

    expect {
      GroupCategory.create!(name: 'Test2', account: account, sis_source_id: '1')
    }.to raise_error(ActiveRecord::RecordInvalid)

    new_account = Account.create
    gc = GroupCategory.create!(name: 'Test3', account: new_account, sis_source_id: 1)
    expect(gc.sis_source_id).to eq('1')
  end

end

def assert_random_group_assignment(category, course, initial_spread, result_spread, opts={})
  if (group_limit = opts[:group_limit])
    category.group_limit = group_limit
    category.save!
  end

  expected_leftover_count = opts[:expected_leftover_count] || 0

  # set up course groups
  group_count = result_spread.size
  max_memberships = opts[:max_memberships] || []
  group_count.times do |i|
    category.groups.create(
      name: "Group #{i}",
      context: course,
      max_membership: max_memberships[i]
    )
  end

  # set up course users
  user_count = result_spread.inject(:+) + expected_leftover_count
  course_users = create_users_in_course(course, user_count, return_type: :record)

  # set up initial spread
  initial_memberships = []
  category.groups.each_with_index do |group, group_index|
    initial_spread[group_index].times { initial_memberships << group.add_user(course_users.pop, 'accepted') }
  end

  # perform random assignment
  memberships = category.assign_unassigned_members

  # verify that the results == result_spread
  expect(category.groups.map { |group| group.users.size }.sort).to eq result_spread.sort

  if group_limit && expected_leftover_count > 0
    expect(course.students.size - memberships.size).to eq expected_leftover_count
  else
    expect(memberships.concat(initial_memberships).map(&:user_id).sort).to eq course.students.order(:id).pluck(:id)
  end
end
