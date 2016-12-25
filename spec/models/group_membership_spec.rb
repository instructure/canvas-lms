#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

describe GroupMembership do

  it "should ensure a mutually exclusive relationship" do
    category = Account.default.group_categories.create!(:name => "blah")
    group1 = category.groups.create!(:context => Account.default)
    group2 = category.groups.create!(:context => Account.default)
    user_model

    # start with one active membership
    gm1 = group1.group_memberships.create!(:user => @user, :workflow_state => "accepted")
    expect(gm1.reload).to be_accepted

    # adding another should mark the first as deleted
    gm2 = group2.group_memberships.create!(:user => @user, :workflow_state => "accepted")
    expect(gm2.reload).to be_accepted
    expect(gm1.reload).to be_deleted

    # restoring the first should mark the second as deleted
    gm1.workflow_state = "accepted"
    gm1.save!
    expect(gm1.reload).to be_accepted
    expect(gm2.reload).to be_deleted

    # should work even if we start with bad data (two accepted memberships)
    GroupMembership.where(:id => gm2).update_all(:workflow_state => "accepted")
    gm1.save!
    expect(gm1.reload).to be_accepted
    expect(gm2.reload).to be_deleted
  end

  it "should not be valid if the group is full" do
    course_factory
    category = @course.group_categories.build(:name => "category 1")
    category.group_limit = 2
    category.save!
    group = category.groups.create!(:context => @course)
    # when the group is full
    group.group_memberships.create!(:user => user_model, :workflow_state => 'accepted')
    group.group_memberships.create!(:user => user_model, :workflow_state => 'accepted')
    # expect
    membership = group.group_memberships.build(:user => user_model, :workflow_state => 'accepted')
    expect(membership).not_to be_valid
    expect(membership.errors[:group_id]).to eq ["The group is full."]
  end

  context "section homogeneity" do
    # can't use 'course' because it is defined in spec_helper, so use 'course1'
    let_once(:course1) { course_with_teacher(:active_all => true); @course }
    let_once(:student) { student = user_model; course1.enroll_student(student); student }
    let_once(:group_category) { GroupCategory.student_organized_for(course1) }
    let_once(:group) { course1.groups.create(:group_category => group_category) }
    let_once(:group_membership) { group.group_memberships.create(:user => student) }

    it "should have a validation error on new record" do
      membership = GroupMembership.new
      membership.stubs(:user).returns(mock(:name => 'test user'))
      membership.stubs(:group).returns(mock(:name => 'test group'))
      membership.stubs(:restricted_self_signup?).returns(true)
      membership.stubs(:has_common_section_with_me?).returns(false)
      expect(membership.save).not_to be_truthy
      expect(membership.errors.size).to eq 1
      expect(membership.errors[:user_id].to_s).to match(/test user does not share a section/)
    end

    it "should pass validation on update" do
      expect {
        group_membership.save!
      }.not_to raise_error
    end
  end

  context "Notifications" do
    context "in published course" do
      before :each do
        course_with_teacher(active_all: true)
        @student1 = student_in_course(active_all: true).user
        @group1 = @course.groups.create(group_category: GroupCategory.student_organized_for(@course))
      end

      it "should send message if the first membership in a student organized group", priority: "1", test_id: 193157 do
        Notification.create(name: 'New Student Organized Group', category: 'TestImmediately')
        @teacher.communication_channels.create(path: "test_channel_email_#{@teacher.id}", path_type: 'email').confirm

        group_membership = @group1.group_memberships.create(user: @student1)
        expect(group_membership.messages_sent['New Student Organized Group']).not_to be_empty
      end

      it "should send message when a new student is invited to group and auto-joins", priority: "1", test_id: 193155 do
        Notification.create!(name: 'New Context Group Membership', category: 'TestImmediately')
        student2 = student_in_course(active_all: true).user
        student2.communication_channels.create(path: "test_channel_email_#{student2.id}", path_type: 'email').confirm
        group_membership = @group1.group_memberships.create(user: @student1)
        @group1.add_user(student2)
        expect(group_membership.messages_sent['New Context Group Membership']).not_to be_empty
      end

      it "should not dispatch a message if the membership has been created with SIS" do
        membership = @group1.group_memberships.build(user: @student1)
        Notification.create!(name: 'New Context Group Membership', category: 'TestImmediately')
        Notification.create!(name: 'New Context Group Membership Invitation', category: 'TestImmediately')
        batch = @course.root_account.sis_batches.create!
        membership.sis_batch_id = batch.id
        membership.save!
        expect(membership.messages_sent).to be_empty
      end

      it "should dispatch a message if the course is available" do
        membership = @group1.group_memberships.build(user: @student1)
        Notification.create!(name: 'New Context Group Membership', category: 'TestImmediately')
        membership.save!
        expect(membership.messages_sent['New Context Group Membership']).not_to be_empty
      end
    end

    it "should not dispatch a message if the course is unpublished" do
      course_with_teacher
      student = user_model
      group = @course.groups.create(group_category: GroupCategory.student_organized_for(@course))
      membership = group.group_memberships.build(user: student)
      @course.enroll_student(student)
      Notification.create!(name: 'New Context Group Membership', category: 'TestImmediately')
      membership.save!
      expect(membership.messages_sent).to be_empty
    end

    it "should not dispatch a message if the course is soft-concluded" do
      course_with_teacher(:active_all => true)
      @course.soft_conclude!
      @course.save!
      student = user_model
      group = @course.groups.create(group_category: GroupCategory.student_organized_for(@course))
      membership = group.group_memberships.build(user: student)
      @course.enroll_student(student)
      Notification.create!(name: 'New Context Group Membership', category: 'TestImmediately')
      membership.save!
      expect(membership.messages_sent).to be_empty
    end
  end

  it "should be invalid if group wants a common section, but doesn't have one with the user" do
    course_with_teacher(:active_all => true)
    section1 = @course.course_sections.create
    section2 = @course.course_sections.create
    user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
    user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
    group_category = @course.group_categories.build(:name => "My Category")
    group_category.configure_self_signup(true, true)
    group_category.save
    group = group_category.groups.create(:context => @course)
    group.add_user(user1)
    membership = group.group_memberships.build(:user => user2)
    expect(membership).not_to be_valid
    expect(membership.errors[:user_id]).not_to be_nil
  end

  context 'active_given_enrollments?' do
    before :once do
      @enrollment = course_with_student(:active_all => true)
      @course_group = @course.groups.create!
      @membership = @course_group.add_user(@student)
    end

    it 'should be false if the membership is pending (requested)' do
      @membership.workflow_state = 'requested'
      expect(@membership.active_given_enrollments?([@enrollment])).to be_falsey
    end

    it 'should be false if the membership is terminated (deleted)' do
      @membership.workflow_state = 'deleted'
      expect(@membership.active_given_enrollments?([@enrollment])).to be_falsey
    end

    it 'should be false given a course group without an enrollment in the list' do
      expect(@membership.active_given_enrollments?([])).to be_falsey
    end

    it 'should be true for other course groups' do
      expect(@membership.active_given_enrollments?([@enrollment])).to be_truthy
    end

    it 'should be true for account groups regardless of enrollments' do
      @account_group = Account.default.groups.create!
      @membership = @account_group.add_user(@student)
      expect(@membership.active_given_enrollments?([])).to be_truthy
    end

    it 'should not be deleted when the enrollment is destroyed' do
      @enrollment.destroy
      @membership.reload
      expect(@membership.workflow_state).to eq 'deleted'
    end

    it 'should soft delete when membership destroyed' do
      @membership.destroy
      @membership.reload
      expect(@membership.workflow_state).to eq 'deleted'
    end
  end

  it "should auto_join for backwards compatibility" do
    user_model
    group_model
    group_membership_model(:workflow_state => "invited")
    expect(@group_membership.workflow_state).to eq "accepted"
  end

  it "should not auto_join for communities" do
    user_model
    @communities = GroupCategory.communities_for(Account.default)
    group_model(:name => "Algebra Teachers", :group_category => @communities, :join_level => "parent_context_request")
    group_membership_model(:user => @user, :workflow_state => "requested")
    expect(@group_membership.workflow_state).to eq "requested"
  end

  context 'permissions' do
    before :once do
      course_with_teacher(:active_all => true)
    end

    it "should allow someone to join an open, non-community group" do
      student_in_course(:active_all => true)
      student_organized = GroupCategory.student_organized_for(@course)
      student_group = student_organized.groups.create!(:context => @course, :join_level => "parent_context_auto_join")
      expect(GroupMembership.new(:user => @student, :group => student_group).grants_right?(@student, :create)).to be_truthy

      course_groups = group_category
      course_groups.configure_self_signup(true, false)
      course_groups.save!
      course_group = course_groups.groups.create!(:context => @course, :join_level => "invitation_only")
      expect(GroupMembership.new(:user => @student, :group => course_group).grants_right?(@student, :create)).to be_truthy
    end

    it "should allow someone to be added to a non-community group" do
      student_in_course(:active_all => true)
      course_groups = group_category
      course_group = course_groups.groups.create!(:context => @course, :join_level => "invitation_only")
      expect(GroupMembership.new(:user => @student, :group => course_group).grants_right?(@teacher, :create)).to be_truthy

      @account = @course.root_account
      account_admin_user(:active_all => true, :account => @account)
      account_groups = group_category(context: @account)
      account_group = account_groups.groups.create!(:context => @account)
      expect(GroupMembership.new(:user => @student, :group => account_group).grants_right?(@admin, :create)).to be_truthy
    end

    it 'should allow a teacher to join a student to a group in an unpublished course' do
      @course.claim!
      student_in_course(active_all: true)
      course_groups = group_category
      course_group = course_groups.groups.create!(:context => @course, :join_level => "invitation_only")
      expect(GroupMembership.new(user: @student, group: course_group).grants_right?(@teacher, :create)).to be_truthy
    end

    it "should allow someone to join an open community group" do
      @account = @course.root_account
      community_groups = GroupCategory.communities_for(@account)
      community_group = community_groups.groups.create!(:context => @account, :join_level => "parent_context_auto_join")
      expect(GroupMembership.new(:user => @teacher, :group => community_group).grants_right?(@teacher, :create)).to be_truthy

    end

    it "should not allow someone to be added to a community group" do
      @account = @course.root_account
      account_admin_user(:active_all => true, :account => @account)
      community_groups = GroupCategory.communities_for(@account)
      community_group = community_groups.groups.create!(:context => @account, :join_level => "parent_context_auto_join")
      expect(GroupMembership.new(:user => @teacher, :group => community_group).grants_right?(@admin, :create)).to be_falsey
    end

    it "should allow a moderator to kick someone from a community" do
      @account = @course.root_account
      account_admin_user(:active_all => true, :account => @account)
      community_groups = GroupCategory.communities_for(@account)
      community_group = community_groups.groups.create!(:context => @account, :join_level => "parent_context_auto_join")
      community_group.add_user(@admin, 'accepted', true)
      community_group.add_user(@teacher, 'accepted', false)
      expect(GroupMembership.where(:group_id => community_group.id, :user_id => @teacher.id).first.grants_right?(@admin, :delete)).to be_truthy
    end
  end

  it 'updates group leadership as membership changes' do
    course_factory
    @category = @course.group_categories.build(:name => "category 1")
    @category.save!
    @group = @category.groups.create!(:context => @course)
    @category.auto_leader = "first"
    @category.save!
    leader = user_model
    @group.group_memberships.create!(:user => leader, :workflow_state => 'accepted')
    expect(@group.reload.leader).to eq leader
  end

  describe "updating cached due dates" do
    before :once do
      course_factory
      @group_category = @course.group_categories.create!(:name => "category")
      @membership = group_with_user(:group_context => @course, :group_category => @group_category)

      # back-populate associations so we don't need to reload
      @membership.group = @group
      @group.group_category = @group_category

      @assignments = 3.times.map{ assignment_model(:course => @course) }
      @assignments.last.group_category = nil
      @assignments.last.save!
    end

    it "triggers a batch when membership is created" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).with { |course_id, assignment_ids|
        course_id == @course.id && assignment_ids.sort == [@assignments[0].id, @assignments[1].id].sort
      }.once
      @group.group_memberships.create(:user => user_factory)
    end

    it "triggers a batch when membership is deleted" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).with { |course_id, assignment_ids|
        course_id == @course.id && assignment_ids.sort == [@assignments[0].id, @assignments[1].id].sort
      }.once
      @membership.destroy
    end

    it "does not trigger when nothing changed" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).never
      @membership.save
    end

    it "does not trigger when it's an account group" do
      DueDateCacher.expects(:recompute).never
      DueDateCacher.expects(:recompute_course).never
      @group = Account.default.groups.create!(:name => 'Group!')
      @group.group_memberships.create!(:user => user_factory)
    end
  end
end
