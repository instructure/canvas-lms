# frozen_string_literal: true

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

describe GroupMembership do
  it "ensures a mutually exclusive relationship" do
    category = Account.default.group_categories.create!(name: "blah")
    group1 = category.groups.create!(context: Account.default)
    group2 = category.groups.create!(context: Account.default)
    user_model

    # start with one active membership
    gm1 = group1.group_memberships.create!(user: @user, workflow_state: "accepted")
    expect(gm1.reload).to be_accepted

    # adding another should mark the first as deleted
    gm2 = group2.group_memberships.create!(user: @user, workflow_state: "accepted")
    expect(gm2.reload).to be_accepted
    expect(gm1.reload).to be_deleted

    # restoring the first should mark the second as deleted
    gm1.workflow_state = "accepted"
    gm1.save!
    expect(gm1.reload).to be_accepted
    expect(gm2.reload).to be_deleted

    # should work even if we start with bad data (two accepted memberships)
    GroupMembership.where(id: gm2).update_all(workflow_state: "accepted")
    gm1.save!
    expect(gm1.reload).to be_accepted
    expect(gm2.reload).to be_deleted
  end

  it "is not valid if the group is full" do
    course_factory
    category = @course.group_categories.build(name: "category 1")
    category.group_limit = 2
    category.save!
    group = category.groups.create!(context: @course)
    # when the group is full
    group.group_memberships.create!(user: user_model, workflow_state: "accepted")
    group.group_memberships.create!(user: user_model, workflow_state: "accepted")
    # expect
    membership = group.group_memberships.build(user: user_model, workflow_state: "accepted")
    expect(membership).not_to be_valid
    expect(membership.errors[:group_id]).to eq ["The group is full."]
  end

  context "section homogeneity" do
    # can't use 'course' because it is defined in spec_helper, so use 'course1'
    let_once(:course1) do
      course_with_teacher(active_all: true)
      @course
    end
    let_once(:student) do
      student = user_model
      course1.enroll_student(student)
      student
    end
    let_once(:group_category) { GroupCategory.student_organized_for(course1) }
    let_once(:group) { course1.groups.create(group_category:) }
    let_once(:group_membership) { group.group_memberships.create(user: student) }

    it "has a validation error on new record" do
      membership = GroupMembership.new

      allow(membership).to receive_messages(user: double(name: "test user"),
                                            group: double(name: "test group"),
                                            restricted_self_signup?: true,
                                            has_common_section_with_me?: false)
      expect(membership.save).not_to be_truthy
      expect(membership.errors.size).to eq 1
      expect(membership.errors[:user_id].to_s).to match(/test user does not share a section/)
    end

    it "passes validation on update" do
      expect do
        group_membership.save!
      end.not_to raise_error
    end
  end

  context "Notifications" do
    context "in published course" do
      before do
        course_with_teacher(active_all: true)
        @student1 = student_in_course(active_all: true).user
        @group1 = @course.groups.create(group_category: GroupCategory.student_organized_for(@course))
      end

      it "sends message if the first membership in a student organized group", priority: "1" do
        Notification.create(name: "New Student Organized Group", category: "TestImmediately")
        communication_channel(@teacher, { username: "test_channel_email_#{@teacher.id}@test.com", active_cc: true })

        group_membership = @group1.group_memberships.create(user: @student1)
        expect(group_membership.messages_sent["New Student Organized Group"]).not_to be_empty
      end

      it "sends message when a new student is invited to group and auto-joins", priority: "1" do
        Notification.create!(name: "New Context Group Membership", category: "TestImmediately")
        student2 = student_in_course(active_all: true).user
        communication_channel(student2, { username: "test_channel_email_#{student2.id}@test.com", active_cc: true })
        group_membership = @group1.group_memberships.create(user: @student1)
        @group1.add_user(student2)
        expect(group_membership.messages_sent["New Context Group Membership"]).not_to be_empty
      end

      it "does not dispatch a message if the membership has been created with SIS" do
        membership = @group1.group_memberships.build(user: @student1)
        Notification.create!(name: "New Context Group Membership", category: "TestImmediately")
        Notification.create!(name: "New Context Group Membership Invitation", category: "TestImmediately")
        batch = @course.root_account.sis_batches.create!
        membership.sis_batch_id = batch.id
        membership.save!
        expect(membership.messages_sent).to be_empty
      end

      it "dispatches a message if the course is available and has started" do
        membership = @group1.group_memberships.build(user: @student1)
        Notification.create!(name: "New Context Group Membership", category: "TestImmediately")
        membership.save!
        expect(membership.messages_sent["New Context Group Membership"]).not_to be_empty
      end

      it "does not dispatch a message if the course is available and has not started yet" do
        course = course_factory(active_all: true)
        course.start_at = 1.day.from_now
        course.restrict_enrollments_to_course_dates = true
        course.save!
        student_in_course(active_all: true, course:)
        group1 = course.groups.create(group_category: GroupCategory.student_organized_for(course))
        membership = group1.group_memberships.build(user: @student)
        Notification.create!(name: "New Context Group Membership", category: "TestImmediately")
        Notification.create!(name: "New Context Group Membership Invitation", category: "TestImmediately")
        membership.save!
        expect(membership.messages_sent).to be_empty
      end
    end

    it "does not dispatch a message if the course is unpublished" do
      course_with_teacher
      student = user_model
      group = @course.groups.create(group_category: GroupCategory.student_organized_for(@course))
      membership = group.group_memberships.build(user: student)
      @course.enroll_student(student)
      Notification.create!(name: "New Context Group Membership", category: "TestImmediately")
      membership.save!
      expect(membership.messages_sent).to be_empty
    end

    it "does not dispatch a message if the course is soft-concluded" do
      course_with_teacher(active_all: true)
      @course.soft_conclude!
      @course.save!
      student = user_model
      group = @course.groups.create(group_category: GroupCategory.student_organized_for(@course))
      membership = group.group_memberships.build(user: student)
      @course.enroll_student(student)
      Notification.create!(name: "New Context Group Membership", category: "TestImmediately")
      membership.save!
      expect(membership.messages_sent).to be_empty
    end
  end

  it "is invalid if group wants a common section, but doesn't have one with the user" do
    course_with_teacher(active_all: true)
    section1 = @course.course_sections.create
    section2 = @course.course_sections.create
    user1 = section1.enroll_user(user_model, "StudentEnrollment").user
    user2 = section2.enroll_user(user_model, "StudentEnrollment").user
    group_category = @course.group_categories.build(name: "My Category")
    group_category.configure_self_signup(true, true)
    group_category.save
    group = group_category.groups.create(context: @course)
    group.add_user(user1)
    membership = group.group_memberships.build(user: user2)
    expect(membership).not_to be_valid
    expect(membership.errors[:user_id]).not_to be_nil
  end

  context "active_given_enrollments?" do
    before :once do
      @enrollment = course_with_student(active_all: true)
      @course_group = @course.groups.create!
      @membership = @course_group.add_user(@student)
    end

    it "is false if the membership is pending (requested)" do
      @membership.workflow_state = "requested"
      expect(@membership.active_given_enrollments?([@enrollment])).to be_falsey
    end

    it "is false if the membership is terminated (deleted)" do
      @membership.workflow_state = "deleted"
      expect(@membership.active_given_enrollments?([@enrollment])).to be_falsey
    end

    it "is false given a course group without an enrollment in the list" do
      expect(@membership.active_given_enrollments?([])).to be_falsey
    end

    it "is true for other course groups" do
      expect(@membership.active_given_enrollments?([@enrollment])).to be_truthy
    end

    it "is true for account groups regardless of enrollments" do
      @account_group = Account.default.groups.create!
      @membership = @account_group.add_user(@student)
      expect(@membership.active_given_enrollments?([])).to be_truthy
    end

    it "is not deleted when the enrollment is destroyed" do
      @enrollment.destroy
      @membership.reload
      expect(@membership.workflow_state).to eq "deleted"
    end

    it "softs delete when membership destroyed" do
      @membership.destroy
      @membership.reload
      expect(@membership.workflow_state).to eq "deleted"
    end
  end

  it "auto_joins for backwards compatibility" do
    user_model
    group_model
    group_membership_model(workflow_state: "invited")
    expect(@group_membership.workflow_state).to eq "accepted"
  end

  it "does not auto_join for communities" do
    user_model
    @communities = GroupCategory.communities_for(Account.default)
    group_model(name: "Algebra Teachers", group_category: @communities, join_level: "parent_context_request")
    group_membership_model(user: @user, workflow_state: "requested")
    expect(@group_membership.workflow_state).to eq "requested"
  end

  context "permissions" do
    before :once do
      course_with_teacher(active_all: true)
    end

    it "allows someone to join an open, non-community group" do
      student_in_course(active_all: true)
      student_organized = GroupCategory.student_organized_for(@course)
      student_group = student_organized.groups.create!(context: @course, join_level: "parent_context_auto_join")
      expect(GroupMembership.new(user: @student, group: student_group).grants_right?(@student, :create)).to be_truthy

      course_groups = group_category
      course_groups.configure_self_signup(true, false)
      course_groups.save!
      course_group = course_groups.groups.create!(context: @course, join_level: "invitation_only")
      expect(GroupMembership.new(user: @student, group: course_group).grants_right?(@student, :create)).to be_truthy
    end

    it "allows someone to be added to a non-community group" do
      student_in_course(active_all: true)
      course_groups = group_category
      course_group = course_groups.groups.create!(context: @course, join_level: "invitation_only")
      expect(GroupMembership.new(user: @student, group: course_group).grants_right?(@teacher, :create)).to be_truthy

      @account = @course.root_account
      account_admin_user(active_all: true, account: @account)
      account_groups = group_category(context: @account)
      account_group = account_groups.groups.create!(context: @account)
      expect(GroupMembership.new(user: @student, group: account_group).grants_right?(@admin, :create)).to be_truthy
    end

    it "allows a teacher to join a student to a group in an unpublished course" do
      @course.claim!
      student_in_course(active_all: true)
      course_groups = group_category
      course_group = course_groups.groups.create!(context: @course, join_level: "invitation_only")
      expect(GroupMembership.new(user: @student, group: course_group).grants_right?(@teacher, :create)).to be_truthy
    end

    it "allows someone to join an open community group" do
      @account = @course.root_account
      community_groups = GroupCategory.communities_for(@account)
      community_group = community_groups.groups.create!(context: @account, join_level: "parent_context_auto_join")
      expect(GroupMembership.new(user: @teacher, group: community_group).grants_right?(@teacher, :create)).to be_truthy
    end

    it "does not allow someone to be added to a community group" do
      @account = @course.root_account
      account_admin_user(active_all: true, account: @account)
      community_groups = GroupCategory.communities_for(@account)
      community_group = community_groups.groups.create!(context: @account, join_level: "parent_context_auto_join")
      expect(GroupMembership.new(user: @teacher, group: community_group).grants_right?(@admin, :create)).to be_falsey
    end

    it "allows a moderator to kick someone from a community" do
      @account = @course.root_account
      account_admin_user(active_all: true, account: @account)
      community_groups = GroupCategory.communities_for(@account)
      community_group = community_groups.groups.create!(context: @account, join_level: "parent_context_auto_join")
      community_group.add_user(@admin, "accepted", true)
      community_group.add_user(@teacher, "accepted", false)
      expect(GroupMembership.where(group_id: community_group.id, user_id: @teacher.id).first.grants_right?(@admin, :delete)).to be_truthy
    end
  end

  it "updates group leadership as membership changes" do
    course_factory
    @category = @course.group_categories.build(name: "category 1")
    @category.save!
    @group = @category.groups.create!(context: @course)
    @category.auto_leader = "first"
    @category.save!
    leader = user_model
    @group.group_memberships.create!(user: leader, workflow_state: "accepted")
    expect(@group.reload.leader).to eq leader
  end

  describe "updating cached due dates" do
    before :once do
      course_factory
      @group_category = @course.group_categories.create!(name: "category")
      @membership = group_with_user(group_context: @course, group_category: @group_category)

      # back-populate associations so we don't need to reload
      @membership.group = @group
      @group.group_category = @group_category

      @assignments = Array.new(3) { assignment_model(course: @course) }
      @assignments.last.group_category = nil
      @assignments.last.save!
    end

    it "triggers a batch when membership is created" do
      new_user = user_factory

      expect(SubmissionLifecycleManager).not_to receive(:recompute)
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).with(
        new_user.id,
        @course.id,
        match_array(@assignments[0..1].map(&:id))
      )

      @group.group_memberships.create(user: new_user)
    end

    it "triggers a batch when membership is deleted" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute)
      expect(SubmissionLifecycleManager).to receive(:recompute_users_for_course).with(
        @membership.user.id,
        @course.id,
        match_array(@assignments[0..1].map(&:id))
      )
      @membership.destroy
    end

    it "does not trigger when nothing changed" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute)
      expect(SubmissionLifecycleManager).not_to receive(:recompute_course)
      @membership.save
    end

    it "does not trigger when it's an account group" do
      expect(SubmissionLifecycleManager).not_to receive(:recompute)
      expect(SubmissionLifecycleManager).not_to receive(:recompute_course)
      @group = Account.default.groups.create!(name: "Group!")
      @group.group_memberships.create!(user: user_factory)
    end
  end

  it "runs due date updates for discussion assignments" do
    group_discussion_assignment
    @assignment.update_attribute(:only_visible_to_overrides, true)
    @assignment.assignment_overrides.create!(set: @group1)
    @student1 = student_in_course(course: @course, active_all: true).user
    membership = @group1.add_user(@student1)
    @topic.child_topic_for(@student1).reply_from(user: @student1, text: "sup")
    sub = @assignment.submission_for_student(@student1)
    expect(sub).to be_submitted
    membership.destroy
    expect(sub.reload).to be_deleted # no longer part of the group so the assignment no longer applies to them
    membership.update_attribute(:workflow_state, "accepted")
    expect(sub.reload).to be_submitted # back to the way it was
  end

  describe "root_account_id" do
    let(:category) { course.group_categories.create!(name: "category 1") }
    let(:course) { course_factory && @course }
    let(:group) { category.groups.create!(context: course) }
    let(:user) { user_model }

    it "assigns it on save if it is not set" do
      membership = group.group_memberships.create!(user:)
      membership.root_account_id = nil

      expect do
        membership.save!
      end.to change {
        membership.root_account_id
      }.from(nil).to(group.root_account_id)
    end

    it "preserves it on save if it was already set" do
      membership = group.group_memberships.create!(user:)

      expect(membership.group).not_to receive(:root_account_id)

      expect do
        membership.save!
      end.not_to change {
        GroupMembership.find(membership.id).root_account_id
      }
    end
  end
end
