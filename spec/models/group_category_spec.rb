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

describe GroupCategory do
  context "protected_name_for_context?" do
    it "should be false for 'Student Groups' in accounts" do
      account = Account.default
      GroupCategory.protected_name_for_context?('Student Groups', account).should be_false
    end

    it "should be true for 'Student Groups' in courses" do
      course = course_model
      GroupCategory.protected_name_for_context?('Student Groups', course).should be_true
    end

    it "should be true for 'Imported Groups' in both accounts and courses" do
      account = Account.default
      course = course_model
      GroupCategory.protected_name_for_context?('Imported Groups', account).should be_true
      GroupCategory.protected_name_for_context?('Imported Groups', course).should be_true
    end
  end

  context "student_organized_for" do
    it "should be nil in accounts" do
      account = Account.default
      GroupCategory.student_organized_for(account).should be_nil
    end

    it "should be a category belonging to the course with role 'student_organized' in courses" do
      course = course_model
      category = GroupCategory.student_organized_for(course)
      category.should_not be_nil
      category.role.should eql('student_organized')
      category.context.should eql(course)
    end

    it "should be the the same category every time for the same course" do
      course = course_model
      category1 = GroupCategory.student_organized_for(course)
      category2 = GroupCategory.student_organized_for(course)
      category1.id.should eql(category2.id)
    end
  end

  context "communities_for" do
    it "should be nil in courses" do
      course_model
      GroupCategory.communities_for(@course).should be_nil
    end

    it "should be a category belonging to the account with role 'communities'" do
      account = Account.default
      category = GroupCategory.communities_for(account)
      category.should_not be_nil
      category.role.should eql('communities')
      category.context.should eql(account)
    end

    it "should be the the same category every time for the same account" do
      account = Account.default
      category1 = GroupCategory.communities_for(account)
      category2 = GroupCategory.communities_for(account)
      category1.id.should eql(category2.id)
    end
  end

  context "imported_for" do
    it "should be a category belonging to the account with role 'imported' in accounts" do
      account = Account.default
      category = GroupCategory.imported_for(account)
      category.should_not be_nil
      category.role.should eql('imported')
      category.context.should eql(account)
    end

    it "should be a category belonging to the course with role 'imported' in courses" do
      course = course_model
      category = GroupCategory.imported_for(course)
      category.should_not be_nil
      category.role.should eql('imported')
      category.context.should eql(course)
    end

    it "should be the the same category every time for the same context" do
      course = course_model
      category1 = GroupCategory.imported_for(course)
      category2 = GroupCategory.imported_for(course)
      category1.id.should eql(category2.id)
    end
  end

  context 'student_organized?' do
    it "should be true iff the role is 'student_organized', regardless of name" do
      account = Account.default
      course = course_model
      GroupCategory.student_organized_for(course).should be_student_organized
      account.group_categories.create(:name => 'Student Groups').should_not be_student_organized
      GroupCategory.imported_for(course).should_not be_student_organized
      GroupCategory.imported_for(course).should_not be_student_organized
      course.group_categories.create(:name => 'Random Category').should_not be_student_organized
      GroupCategory.communities_for(account).should_not be_student_organized
    end
  end

  context 'communities?' do
    it "should be true iff the role is 'communities', regardless of name" do
      account = Account.default
      course = course_model
      GroupCategory.student_organized_for(course).should_not be_communities
      account.group_categories.create(:name => 'Communities').should_not be_communities
      GroupCategory.imported_for(course).should_not be_communities
      GroupCategory.imported_for(course).should_not be_communities
      course.group_categories.create(:name => 'Random Category').should_not be_communities
      GroupCategory.communities_for(account).should be_communities
    end
  end

  context 'allows_multiple_memberships?' do
    it "should be true iff the category is student organized or communities" do
      account = Account.default
      course = course_model
      GroupCategory.student_organized_for(course).allows_multiple_memberships?.should be_true
      account.group_categories.create(:name => 'Student Groups').allows_multiple_memberships?.should be_false
      GroupCategory.imported_for(course).allows_multiple_memberships?.should be_false
      GroupCategory.imported_for(course).allows_multiple_memberships?.should be_false
      course.group_categories.create(:name => 'Random Category').allows_multiple_memberships?.should be_false
      GroupCategory.communities_for(account).allows_multiple_memberships?.should be_true
    end
  end

  context 'protected?' do
    it "should be true iff the category has a role" do
      account = Account.default
      course = course_model
      GroupCategory.student_organized_for(course).should be_protected
      account.group_categories.create(:name => 'Student Groups').should_not be_protected
      GroupCategory.imported_for(course).should be_protected
      GroupCategory.imported_for(course).should be_protected
      course.group_categories.create(:name => 'Random Category').should_not be_protected
      GroupCategory.communities_for(account).should be_protected
    end
  end

  context 'destroy' do
    it "should not remove the database row" do
      category = GroupCategory.create(name: "foo")
      category.destroy
      lambda{ GroupCategory.find(category.id) }.should_not raise_error
    end

    it "should set deleted_at" do
      category = GroupCategory.create(name: "foo")
      category.destroy
      category.reload
      category.deleted_at.should_not be_nil
    end

    it "should destroy dependent groups" do
      course = course_model
      category = group_category
      group1 = category.groups.create(:context => course)
      group2 = category.groups.create(:context => course)
      course.reload
      course.groups.active.count.should == 2

      category.destroy
      course.reload
      course.groups.active.count.should == 0
      course.groups.count.should == 2
    end
  end

  context 'configure_self_signup(enabled, restricted)' do
    before :each do
      @category = GroupCategory.new
      @category.name = "foo"
    end

    it "should make self_signup? true and unrestricted_self_signup? true given (true, false)" do
      @category.configure_self_signup(true, false)
      @category.self_signup?.should be_true
      @category.unrestricted_self_signup?.should be_true
    end

    it "should make self_signup? true and unrestricted_self_signup? false given (true, true)" do
      @category.configure_self_signup(true, true)
      @category.self_signup?.should be_true
      @category.unrestricted_self_signup?.should be_false
    end

    it "should make self_signup? false and unrestricted_self_signup? false given (false, *)" do
      @category.configure_self_signup(false, false)
      @category.self_signup?.should be_false
      @category.unrestricted_self_signup?.should be_false

      @category.configure_self_signup(false, true)
      @category.self_signup?.should be_false
      @category.unrestricted_self_signup?.should be_false
    end

    it "should persist to the DB" do
      @category.context = course()
      @category.configure_self_signup(true, true)
      @category.save!
      @category.reload
      @category.self_signup?.should be_true
      @category.unrestricted_self_signup?.should be_false
    end
  end

  it "should default to no self signup" do
    category = GroupCategory.new
    category.self_signup?.should be_false
    category.unrestricted_self_signup?.should be_false
  end

  context "has_heterogenous_group?" do
    it "should be false for accounts" do
      account = Account.default
      category = group_category(context: account)
      group = category.groups.create(:context => account)
      category.should_not have_heterogenous_group
    end

    it "should be true if two students that don't share a section are in the same group" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      category = group_category
      group = category.groups.create(:context => @course)
      group.add_user(user1)
      group.add_user(user2)
      category.should have_heterogenous_group
    end

    it "should be false if all students in each group have a section in common" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      category = group_category
      group = category.groups.create(:context => @course)
      group.add_user(user1)
      group.add_user(user2)
      category.should_not have_heterogenous_group
    end
  end

  describe "group_for" do
    before :each do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @category = group_category
    end

    it "should return nil if no groups in category" do
      @category.group_for(@student).should be_nil
    end

    it "should return nil if no active groups in category" do
      group = @category.groups.create(:context => @course)
      group.add_user(@student)
      group.destroy!
      @category.group_for(@student).should be_nil
    end

    it "should return the group the student is in" do
      group1 = @category.groups.create(:context => @course)
      group2 = @category.groups.create(:context => @course)
      group2.add_user(@student)
      @category.group_for(@student).should == group2
    end
  end

  context "#distribute_members_among_groups" do
    it "should prefer groups with fewer users" do
      course_with_teacher_logged_in(:active_all => true)
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
      memberships.map { |m| m.user_id }.sort.should == student_ids.sort

      grouped_memberships = memberships.group_by { |m| m.group_id }
      grouped_memberships[group1.id].size.should == 1
      grouped_memberships[group2.id].size.should == 3
    end
  end

  context "#assign_unassigned_members_in_background" do
    it "should use the progress object" do
      course_with_teacher_logged_in(:active_all => true)
      category = @course.group_categories.create(:name => "Group Category")
      group1 = category.groups.create(:name => "Group 1", :context => @course)
      group2 = category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      group2.add_user(student1)

      category.assign_unassigned_members_in_background
      category.current_progress.completion.should == 0

      run_jobs

      category.progresses.last.should be_completed
    end
  end

  context "#assign_unassigned_members" do
    it "should not assign users to inactive groups" do
      course_with_teacher_logged_in(:active_all => true)
      category = @course.group_categories.create(:name => "Group Category")
      group1 = category.groups.create(:name => "Group 1", :context => @course)
      group2 = category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      group2.add_user(student1)
      group1.destroy

      # group1 now has fewer students, and would be favored if it weren't
      # destroyed. make sure the unassigned student (student2) is assigned to
      # group2 instead of group1
      memberships = category.assign_unassigned_members
      memberships.size.should == 1
      memberships.first.group_id.should == group2.id
    end

    it "should not assign users already in group in the category" do
      course_with_teacher_logged_in(:active_all => true)
      category = @course.group_categories.create(:name => "Group Category")
      group1 = category.groups.create(:name => "Group 1", :context => @course)
      group2 = category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      group2.add_user(student1)

      # student1 shouldn't get assigned, already being in a group
      memberships = category.assign_unassigned_members
      memberships.map { |m| m.user }.should_not include(student1)
    end

    it "should otherwise assign ungrouped users to groups in the category" do
      course_with_teacher_logged_in(:active_all => true)
      category = @course.group_categories.create(:name => "Group Category")
      group1 = category.groups.create(:name => "Group 1", :context => @course)
      group2 = category.groups.create(:name => "Group 2", :context => @course)
      student1 = @course.enroll_student(user_model).user
      student2 = @course.enroll_student(user_model).user
      group2.add_user(student1)

      # student2 should get assigned, not being in a group
      memberships = category.assign_unassigned_members
      memberships.map { |m| m.user }.should include(student2)
    end
  end

  context "#current_progress" do
    it "should return a new progress if the other progresses are completed" do
      course_with_teacher_logged_in(:active_all => true)
      category = @course.group_categories.create!(:name => "Group Category")
      # given existing completed progress
      category.current_progress.should be_nil
      category.send :start_progress
      category.send :complete_progress
      category.progresses.count.should == 1
      category.current_progress.should be_nil
      # expect new progress
      category.send :start_progress
      category.progresses.count.should == 2
    end
  end
end
