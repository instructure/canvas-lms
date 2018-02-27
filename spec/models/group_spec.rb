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

describe Group do

  before :once do
    course_model
    group_model(:context => @course)
  end

  context "validation" do
    it "should create a new instance given valid attributes" do
      group_model
    end
  end

  it "should have a wiki" do
    expect(@group.wiki).not_to be_nil
  end

  it "should be private by default" do
    expect(@group.is_public).to be_falsey
  end

  it "should allow a private group to be made public" do
    @communities = GroupCategory.communities_for(Account.default)
    group_model(:group_category => @communities, :is_public => false)
    @group.is_public = true
    @group.save!
    expect(@group.reload.is_public).to be_truthy
  end

  it "should not allow a public group to be made private" do
    @communities = GroupCategory.communities_for(Account.default)
    group_model(:group_category => @communities, :is_public => true)
    @group.is_public = false
    expect(@group.save).to be_falsey
    expect(@group.reload.is_public).to be_truthy
  end

  it 'delegates time_zone through to its context' do
    zone = ActiveSupport::TimeZone["America/Denver"]
    @course.time_zone = zone
    expect(@group.time_zone.to_s).to match /Mountain Time/
  end

  it "should correctly identify group as active" do
    course_with_student(:active_all => true)
    group_model(:group_category => @communities, :is_public => true)
    group.add_user(@student)
    expect(@group.inactive?).to eq false
  end

  it "should correctly identify destroyed course as not active" do
    course_with_student(:active_all => true)
    group_model(:group_category => @communities, :is_public => true)
    group.add_user(@student)
    @group.context = @course
    @course.destroy!
    expect(@group.inactive?).to eq true
  end

  it "should correctly identify concluded course as not active" do
    course_with_student(:active_all => true)
    group_model(:group_category => @communities, :is_public => true)
    group.add_user(@student)
    @group.context = @course
    @course.complete!
    expect(@group.inactive?).to eq true
  end

  it "should correctly identify account group as not active" do
    @account = account_model
    group_model(:group_category => @communities, :is_public => true, :context => @account)
    group.add_user(@student)
    @group.context.destroy
    expect(@group.inactive?).to eq true
  end

  it "should correctly identify account group as active" do
    @account = account_model
    group_model(:group_category => @communities, :is_public => true, :context => @account)
    group.add_user(@student)
    expect(@group.inactive?).to eq false
  end

  describe '#grading_standard_or_default' do
    context 'when the Group belongs to a Course' do
      it 'returns the grading scheme being used by the course, if one exists' do
        standard = grading_standard_for(@course)
        @course.update!(default_grading_standard: standard)
        expect(@group.grading_standard_or_default).to be standard
      end

      it 'returns the Canvas default grading scheme if the course is not using a grading scheme' do
        expect(@group.grading_standard_or_default.data).to eq GradingStandard.default_grading_standard
      end
    end

    context 'Group belonging to an Account' do
      it 'returns the Canvas default grading scheme' do
        group = group_model(context: Account.default)
        expect(group.grading_standard_or_default.data).to eq GradingStandard.default_grading_standard
      end
    end
  end

  context "#peer_groups" do
    it "should find all peer groups" do
      context = course_model
      group_category = context.group_categories.create(:name => "worldCup")
      other_category = context.group_categories.create(:name => "other category")
      group1 = Group.create!(:name=>"group1", :group_category => group_category, :context => context)
      group2 = Group.create!(:name=>"group2", :group_category => group_category, :context => context)
      group3 = Group.create!(:name=>"group3", :group_category => group_category, :context => context)
      group4 = Group.create!(:name=>"group4", :group_category => other_category, :context => context)
      expect(group1.peer_groups.length).to eq 2
      expect(group1.peer_groups).to be_include(group2)
      expect(group1.peer_groups).to be_include(group3)
      expect(group1.peer_groups).not_to be_include(group1)
      expect(group1.peer_groups).not_to be_include(group4)
    end

    it "should not find peer groups for student organized groups" do
      context = course_model
      group_category = GroupCategory.student_organized_for(context)
      group1 = Group.create!(:name=>"group1", :group_category=>group_category, :context => context)
      group2 = Group.create!(:name=>"group2", :group_category=>group_category, :context => context)
      expect(group1.peer_groups).to be_empty
    end
  end

  context "atom" do
    it "should have an atom name as it's own name" do
      group_model(:name => 'some unique name')
      expect(@group.to_atom.title).to eql('some unique name')
    end

    it "should have a link to itself" do
      link = @group.to_atom.links.first.to_s
      expect(link).to eql("/groups/#{@group.id}")
    end
  end

  context "add_user" do
    it "should be able to add a person to the group" do
      user_model
      pseudonym_model(:user_id => @user.id)
      @group.add_user(@user)
      expect(@group.users).to be_include(@user)
    end

    it "shouldn't be able to add a person to the group twice" do
      user_model
      pseudonym_model(:user_id => @user.id)
      @group.add_user(@user)
      expect(@group.users).to be_include(@user)
      expect(@group.users.count).to eq 1
      @group.add_user(@user)
      @group.reload
      expect(@group.users).to be_include(@user)
      expect(@group.users.count).to eq 1
    end

    it "should remove that user from peer groups" do
      context = course_model
      group_category = context.group_categories.create!(:name => "worldCup")
      group1 = Group.create!(:name=>"group1", :group_category=>group_category, :context => context)
      group2 = Group.create!(:name=>"group2", :group_category=>group_category, :context => context)
      user_model
      pseudonym_model(:user_id => @user.id)
      group1.add_user(@user)
      expect(group1.users).to be_include(@user)

      group2.add_user(@user)
      expect(group2.users).to be_include(@user)
      group1.reload
      expect(group1.users).not_to be_include(@user)
    end

    it "should add a user at the right workflow_state by default" do
      @communities = GroupCategory.communities_for(Account.default)
      user_model
      {
        'invitation_only'          => 'invited',
        'parent_context_request'   => 'requested',
        'parent_context_auto_join' => 'accepted'
      }.each do |join_level, workflow_state|
        group = group_model(:join_level => join_level, :group_category => @communities)
        group.add_user(@user)
        expect(group.group_memberships.where(:workflow_state => workflow_state, :user_id => @user).first).not_to be_nil
      end
    end

    it "should allow specifying a workflow_state" do
      @communities = GroupCategory.communities_for(Account.default)
      @group.group_category = @communities
      @group.save!
      user_model

      [ 'invited', 'requested', 'accepted' ].each do |workflow_state|
        @group.add_user(@user, workflow_state)
        expect(@group.group_memberships.where(:workflow_state => workflow_state, :user_id => @user).first).not_to be_nil
      end
    end

    it "should allow specifying that the user should be a moderator" do
      user_model
      @membership = @group.add_user(@user, 'accepted', true)
      expect(@membership.moderator).to eq true
    end

    it "should change the workflow_state of an already active user" do
      @communities = GroupCategory.communities_for(Account.default)
      @group.group_category = @communities
      @group.save!
      user_model
      @group.add_user(@user, 'accepted')
      @membership = @group.add_user(@user, 'requested')
      expect(@membership.workflow_state).to eq 'accepted'
    end
  end

  it "should grant manage permissions for associated objects to group managers" do
    e = course_with_teacher(active_course: true)
    course = e.context
    teacher = e.user
    group = course.groups.create
    expect(course.grants_right?(teacher, :manage_groups)).to be_truthy
    expect(group.grants_right?(teacher, :manage_wiki)).to be_truthy
    expect(group.grants_right?(teacher, :manage_files)).to be_truthy
    expect(group.wiki.grants_right?(teacher, :update_page)).to be_truthy
    attachment = group.attachments.build
    expect(attachment.grants_right?(teacher, :create)).to be_truthy
  end

  it "should not allow a concluded student to participate" do
    course_with_student(:active_all => true)
    group = @course.groups.create
    group.add_user(@student)

    @student.enrollments.first.conclude
    expect(group.grants_right?(@student, :participate)).to be_falsey
  end

  it "should only allow me to moderate_forum if I can moderate_forum of group's context" do
    course_with_teacher(active_course: true)
    student_in_course
    group = @course.groups.create

    expect(group.grants_right?(@teacher, :moderate_forum)).to be_truthy
    expect(group.grants_right?(@student, :moderate_forum)).to be_falsey
  end

  it "should grant messaging rights to students if messaging permissions are enabled" do
    course_with_teacher(active_course: true)
    student_in_course(:course => @course)
    group = @course.groups.create
    group.add_user(@student)

    expect(group.grants_right?(@teacher, :send_messages)).to be_truthy
    expect(group.grants_right?(@student, :send_messages)).to be_truthy # by default
    expect(group.grants_right?(@student, :send_messages_all)).to be_truthy
  end

  it "should not grant messaging rights to students if messaging permissions are disabled" do
    course_with_teacher(active_course: true)
    student_in_course(:course => @course)
    group = @course.groups.create
    group.add_user(@student)
    @course.account.role_overrides.create!(:permission => :send_messages, :role => student_role, :enabled => false)

    expect(group.grants_right?(@teacher, :send_messages)).to be_truthy
    expect(group.grants_right?(@student, :send_messages)).to be_falsey
    expect(group.grants_right?(@student, :send_messages_all)).to be_falsey
  end

  it "should grant read_roster permissions to students that can freely join or request an invitation to the group" do
    course_with_teacher(active_course: true)
    student_in_course.accept!

    # default join_level == 'invitation_only' and default category is not self-signup
    group = @course.groups.create
    expect(group.grants_right?(@student, :read_roster)).to be_falsey

    # join_level allows requesting group membership
    group = @course.groups.create(:join_level => 'parent_context_request')
    expect(group.grants_right?(@student, :read_roster)).to be_truthy

    # category is self-signup
    category = @course.group_categories.build(name: 'category name')
    category.self_signup = 'enabled'
    category.save
    group = @course.groups.create(:group_category => category)
    expect(group.grants_right?(@student, :read_roster)).to be_truthy
  end

  describe "root account" do
    it "should get the root account assigned" do
      e = course_with_teacher
      group = @course.groups.create!
      expect(group.account).to eq Account.default
      expect(group.root_account).to eq Account.default

      new_root_acct = account_model
      new_sub_acct = new_root_acct.sub_accounts.create!(:name => 'sub acct')
      group.context = new_sub_acct
      group.save!
      expect(group.account).to eq new_sub_acct
      expect(group.root_account).to eq new_root_acct
    end
  end

  context "auto_accept?" do
    it "should be false unless join level is 'parent_context_auto_join'" do
      course_with_student

      group_category = GroupCategory.student_organized_for(@course)
      group1 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group2 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_request')
      group3 = @course.groups.create(:group_category => group_category, :join_level => 'invitation_only')
      expect([group1, group2, group3].map{|g| g.auto_accept?}).to eq [true, false, false]
    end

    it "should be false unless the group is student organized or a community" do
      course_with_student
      @account = @course.root_account

      jl = 'parent_context_auto_join'
      group1 = @course.groups.create(:group_category => @course.group_categories.create(:name => "random category"), :join_level => jl)
      group2 = @course.groups.create(:group_category => GroupCategory.student_organized_for(@course), :join_level => jl)
      group3 = @account.groups.create(:group_category => GroupCategory.communities_for(@account), :join_level => jl)
      expect([group1, group2, group3].map{|g| g.auto_accept?}).to eq [false, true, true]
    end
  end

  context "allow_join_request?" do
    it "should be false unless join level is 'parent_context_auto_join' or 'parent_context_request'" do
      course_with_student

      group_category = GroupCategory.student_organized_for(@course)
      group1 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group2 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_request')
      group3 = @course.groups.create(:group_category => group_category, :join_level => 'invitation_only')
      expect([group1, group2, group3].map{|g| g.allow_join_request?}).to eq [true, true, false]
    end

    it "should be false unless the group is student organized or a community" do
      course_with_student
      @account = @course.root_account

      jl = 'parent_context_auto_join'
      group1 = @course.groups.create(:group_category => @course.group_categories.create(:name => "random category"), :join_level => jl)
      group2 = @course.groups.create(:group_category => GroupCategory.student_organized_for(@course), :join_level => jl)
      group3 = @account.groups.create(:group_category => GroupCategory.communities_for(@account), :join_level => jl)
      expect([group1, group2, group3].map{|g| g.allow_join_request?}).to eq [false, true, true]
    end
  end

  context "allow_self_signup?" do
    it "should follow the group category self signup option" do
      course_with_student

      group_category = GroupCategory.student_organized_for(@course)
      group_category.configure_self_signup(true, false)
      group_category.save!
      group1 = @course.groups.create(:group_category => group_category)
      expect(group1.allow_self_signup?(@student)).to be_truthy

      group_category.configure_self_signup(true, true)
      group_category.save!
      group2 = @course.groups.create(:group_category => group_category)
      expect(group2.allow_self_signup?(@student)).to be_truthy

      group_category.configure_self_signup(false, false)
      group_category.save!
      group3 = @course.groups.create(:group_category => group_category)
      expect(group3.allow_self_signup?(@student)).to be_falsey
    end

    it "should correctly handle restricted course sections" do
      course_with_student
      @other_section = @course.course_sections.create!(:name => "Other Section")
      @other_student = @course.enroll_student(user_model, {:section => @other_section}).user

      group_category = GroupCategory.student_organized_for(@course)
      group_category.configure_self_signup(true, true)
      group_category.save!
      group1 = @course.groups.create(:group_category => group_category)
      expect(group1.allow_self_signup?(@student)).to be_truthy
      group1.add_user(@student)
      group1.reload
      expect(group1.allow_self_signup?(@other_student)).to be_falsey
    end
  end

  context "#full?" do
    it "returns true when category group_limit has been met" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 1
      @group.add_user user_model, 'accepted'
      expect(@group).to be_full
    end

    it "returns true when max_membership has been met" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 0
      @group.max_membership = 1
      @group.add_user user_model, 'accepted'
      expect(@group).to be_full
    end

    it "returns false when max_membership has not been met" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 0
      @group.max_membership = 2
      @group.add_user user_model, 'accepted'
      expect(@group).not_to be_full
    end

    it "returns false when category group_limit has not been met" do
      # no category
      expect(@group).not_to be_full
      # not full
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 2
      @group.add_user user_model, 'accepted'
      expect(@group).not_to be_full
    end
  end

  context "has_member?" do
    it "should be true for accepted memberships, regardless of moderator flag" do
      @user1 = user_model
      @user2 = user_model
      @user3 = user_model
      @user4 = user_model
      @user5 = user_model

      @group.add_user(@user1, 'accepted')
      @group.add_user(@user2, 'accepted')
      @group.add_user(@user3, 'invited')
      @group.add_user(@user4, 'requested')
      @group.add_user(@user5, 'rejected')
      GroupMembership.where(:group_id => @group, :user_id => @user2).update_all(:moderator => true)

      expect(@group.has_member?(@user1)).to be_truthy
      expect(@group.has_member?(@user2)).to be_truthy
      expect(@group.has_member?(@user3)).to be_truthy # false when we turn auto_join off
      expect(@group.has_member?(@user4)).to be_truthy # false when we turn auto_join off
      expect(@group.has_member?(@user5)).to be_falsey
    end
  end

  context "has_moderator?" do
    it "should be true for accepted memberships, with moderator flag" do
      @user1 = user_model
      @user2 = user_model
      @user3 = user_model
      @user4 = user_model
      @user5 = user_model

      @group.add_user(@user1, 'accepted')
      @group.add_user(@user2, 'accepted')
      @group.add_user(@user3, 'invited')
      @group.add_user(@user4, 'requested')
      @group.add_user(@user5, 'rejected')
      GroupMembership.where(:group_id => @group, :user_id => [@user2, @user3, @user4, @user5]).update_all(:moderator => true)

      expect(@group.has_moderator?(@user1)).to be_falsey
      expect(@group.has_moderator?(@user2)).to be_truthy
      expect(@group.has_moderator?(@user3)).to be_truthy # false when we turn auto_join off
      expect(@group.has_moderator?(@user4)).to be_truthy # false when we turn auto_join off
      expect(@group.has_moderator?(@user5)).to be_falsey
    end
  end

  context "user_can_manage_own_discussion_posts" do
    it "returns true if the context is an account" do
      account = Account.default
      group = account.groups.create
      expect( group.user_can_manage_own_discussion_posts?(nil) ).to be_truthy
    end

    it "defers to the context if that context is a course" do
      course_with_student
      group = @course.groups.create
      allow(group.context).to receive(:user_can_manage_own_discussion_posts?).and_return(false)
      expect( group.user_can_manage_own_discussion_posts?(nil) ).to be_falsey
    end
  end

  context "invite_user" do
    it "should auto accept invitations" do
      course_with_student(:active_all => true)

      group_category = GroupCategory.student_organized_for(@course)

      group = @course.groups.create!(:group_category => group_category)
      gm = group.invite_user(@student)
      expect(gm).to be_accepted
    end
  end

  context "request_user" do
    it "should auto accept invitations" do
      course_with_student(:active_all => true)

      group_category = GroupCategory.student_organized_for(@course)

      group = @course.groups.create!(:group_category => group_category, :join_level => 'parent_context_auto_join')
      gm = group.request_user(@student)
      expect(gm).to be_accepted
    end
  end

  it "should default group_category to student organized category on save" do
    course_with_teacher
    group = @course.groups.create
    expect(group.group_category).to eq GroupCategory.student_organized_for(@course)

    group_category = @course.group_categories.create(:name => "random category")
    group = @course.groups.create(:group_category => group_category)
    expect(group.group_category).to eq group_category
  end

  it "as_json should include group_category" do
    course_factory()
    gc = group_category(name: "Something")
    group = Group.create(:group_category => gc)
    hash = group.as_json
    expect(hash["group"]["group_category"]).to eq "Something"
  end

  it "should maintain the deprecated category attribute" do
    course = course_model
    group = course.groups.create
    default_category = GroupCategory.student_organized_for(course)
    expect(group.read_attribute(:category)).to eql(default_category.name)
    group.group_category = group.context.group_categories.create(:name => "my category")
    group.save
    group.reload
    expect(group.read_attribute(:category)).to eql("my category")
    group.group_category = nil
    group.save
    group.reload
    expect(group.read_attribute(:category)).to eql(default_category.name)
  end

  context "has_common_section?" do
    it "should be false for accounts" do
      account = Account.default
      group = account.groups.create
      expect(group).not_to have_common_section
    end

    it "should not be true if two members don't share a section" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.add_user(user2)
      expect(group).not_to have_common_section
    end

    it "should be true if all members group have a section in common" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.add_user(user2)
      expect(group).to have_common_section
    end
  end

  context "has_common_section_with_user?" do
    it "should be false for accounts" do
      account = Account.default
      group = account.groups.create
      expect(group).not_to have_common_section_with_user(user_model)
    end

    it "should not be true if the new member does't share a section with an existing member" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      expect(group).not_to have_common_section_with_user(user2)
    end

    it "should be true if all members group have a section in common with the new user" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      expect(group).to have_common_section_with_user(user2)
    end
  end

  context "tabs_available" do
    before :once do
      course_with_teacher(active_course: true)
      @teacher = @user
      @group = group(:group_context => @course)
      @group.users << @student = student_in_course(:course => @course).user
    end

    it "should let members see everything" do
      expect(@group.tabs_available(@student).map{|t|t[:id]}).to eql [
        Group::TAB_HOME,
        Group::TAB_ANNOUNCEMENTS,
        Group::TAB_PAGES,
        Group::TAB_PEOPLE,
        Group::TAB_DISCUSSIONS,
        Group::TAB_FILES,
        Group::TAB_CONFERENCES,
        Group::TAB_COLLABORATIONS,
        Group::TAB_COLLABORATIONS_NEW
      ]
    end

    it "should let admins see everything" do
      expect(@group.tabs_available(@teacher).map{|t|t[:id]}).to eql [
        Group::TAB_HOME,
        Group::TAB_ANNOUNCEMENTS,
        Group::TAB_PAGES,
        Group::TAB_PEOPLE,
        Group::TAB_DISCUSSIONS,
        Group::TAB_FILES,
        Group::TAB_CONFERENCES,
        Group::TAB_COLLABORATIONS,
        Group::TAB_COLLABORATIONS_NEW
      ]
    end

    it "should not let nobodies see conferences" do
      expect(@group.tabs_available(nil).map{|t|t[:id]}).not_to include Group::TAB_CONFERENCES
    end
  end

  describe "quota" do
    it "should default to Group.default_storage_quota" do
      expect(@group.quota).to eq Group.default_storage_quota
    end

    it "should be overridden by the account's default_group_storage_quota" do
      a = @group.account
      a.default_group_storage_quota = 10.megabytes
      a.save!

      @group.reload
      expect(@group.quota).to eq 10.megabytes
    end

    it "should inherit from a parent account's default_group_storage_quota" do
      enable_cache do
        account = account_model
        subaccount = account.sub_accounts.create!

        account.default_group_storage_quota = 10.megabytes
        account.save!

        course_factory(:account => subaccount)
        @group = group(:group_context => @course)

        expect(@group.quota).to eq 10.megabytes

        # should reload
        account.default_group_storage_quota = 20.megabytes
        account.save!
        @group = Group.find(@group.id)

        expect(@group.quota).to eq 20.megabytes
      end
    end
  end

  describe "#update_max_membership_from_group_category" do
    it "should set max_membership if there is a group category" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 1
      @group.update_max_membership_from_group_category
      expect(@group.max_membership).to eq 1
    end

    it "should do nothing if there is no group category" do
      expect(@group.max_membership).to be_nil
      @group.update_max_membership_from_group_category
      expect(@group.max_membership).to be_nil
    end
  end

  describe '#destroy' do
    before :once do
      @gc = GroupCategory.create! name: "groups", course: @course
      @group = @gc.groups.create! name: "group1", context: @course
    end

    it "should soft delete" do
      expect(@group.deleted_at).to be_nil
      @group.destroy
      expect(@group.deleted_at).not_to be_nil
    end

    it "should not delete memberships" do
      student_in_course active_all: true
      @group.users << @student
      @group.save!

      expect(@group.users).to eq [@student]
      @group.destroy
      expect(@group.users.reload).to eq [@student]
    end
  end

  describe 'includes_user?' do
    before do
      user_model
      pseudonym_model(:user_id => @user.id)
    end

    it "returns true if a user is in the group" do
      @group.add_user(@user)
      expect(@group.includes_user?(@user)).to be_truthy
    end

    it "returns false if the user is not in the group" do
      expect(@group.includes_user?(@user)).to be_falsey
    end

    it "returns false if no user object is given" do
      expect(@group.includes_user?(nil)).to be_falsey
    end

    it "returns false if an unsaved user is given" do
      @user = User.new
      expect(@group.includes_user?(@user)).to be_falsey
    end
  end

  describe '#favorite_for_user?' do
    before :each do
      context = course_model
      @group_fave = Group.create!(:name=>"group1", :context=>context)
      @group_not_fave = Group.create!(:name=>"group2", :context=>context)
      @group_fave.add_user(@user)
      @group_not_fave.add_user(@user)
      @user.favorites.build(:context => @group_fave)
      @user.save
    end

    it "should return true if a user has a course set as a favorite" do
      expect(@group_fave.favorite_for_user?(@user)).to eql(true)
    end

    it "should return false if a user has not set a group to be a favorite" do
      expect(@group_not_fave.favorite_for_user?(@user)).to eql(false)
    end
  end

  describe "submissions_folder" do
    it "creates the root submissions folder on demand" do
      f = @group.submissions_folder
      expect(@group.submissions_folders.where(parent_folder_id: Folder.root_folders(@group).first, name: 'Submissions').first).to eq f
    end

    it "finds the existing root submissions folder" do
      f = @group.folders.build
      f.parent_folder_id = Folder.root_folders(@group).first
      f.name = 'blah'
      f.submission_context_code = 'root'
      f.save!
      expect(@group.submissions_folder).to eq f
    end
  end

  describe 'participating_users_in_context' do
    before :once do
      context = course_model
      @group = Group.create(:name => "group1", :context => context)
      @group.add_user(@user)
      @user.enrollments.first.deactivate
    end

    it "filter inactive users if requested" do
      users = @group.participating_users_in_context
      expect(users.length).to eq 0
    end

    it "don't filter inactive users if not requested" do
      users = @group.participating_users_in_context(include_inactive_users: true)
      expect(users.length).to eq 1
      expect(users.first.id).to eq @user.id
    end
  end
end
