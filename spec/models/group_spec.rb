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

describe Group do

  before do
    course_model
    group_model(:context => @course)
  end

  context "validation" do
    it "should create a new instance given valid attributes" do
      group_model
    end
  end

  it "should have a wiki" do
    @group.wiki.should_not be_nil
  end

  it "should be private by default" do
    @group.is_public.should be_false
  end

  it "should allow a private group to be made public" do
    @communities = GroupCategory.communities_for(Account.default)
    group_model(:group_category => @communities, :is_public => false)
    @group.is_public = true
    @group.save!
    @group.reload.is_public.should be_true
  end

  it "should not allow a public group to be made private" do
    @communities = GroupCategory.communities_for(Account.default)
    group_model(:group_category => @communities, :is_public => true)
    @group.is_public = false
    @group.save.should be_false
    @group.reload.is_public.should be_true
  end

  it 'delegates time_zone through to its context' do
    zone = ActiveSupport::TimeZone["America/Denver"]
    @course.time_zone = zone
    @group.time_zone.should =~ /Mountain Time/
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
      group1.peer_groups.length.should == 2
      group1.peer_groups.should be_include(group2)
      group1.peer_groups.should be_include(group3)
      group1.peer_groups.should_not be_include(group1)
      group1.peer_groups.should_not be_include(group4)
    end

    it "should not find peer groups for student organized groups" do
      context = course_model
      group_category = GroupCategory.student_organized_for(context)
      group1 = Group.create!(:name=>"group1", :group_category=>group_category, :context => context)
      group2 = Group.create!(:name=>"group2", :group_category=>group_category, :context => context)
      group1.peer_groups.should be_empty
    end
  end

  context "atom" do
    it "should have an atom name as it's own name" do
      group_model(:name => 'some unique name')
      @group.to_atom.title.should eql('some unique name')
    end

    it "should have a link to itself" do
      link = @group.to_atom.links.first.to_s
      link.should eql("/groups/#{@group.id}")
    end
  end

  context "add_user" do
    it "should be able to add a person to the group" do
      user_model
      pseudonym_model(:user_id => @user.id)
      @group.add_user(@user)
      @group.users.should be_include(@user)
    end

    it "shouldn't be able to add a person to the group twice" do
      user_model
      pseudonym_model(:user_id => @user.id)
      @group.add_user(@user)
      @group.users.should be_include(@user)
      @group.users.count.should == 1
      @group.add_user(@user)
      @group.reload
      @group.users.should be_include(@user)
      @group.users.count.should == 1
    end

    it "should remove that user from peer groups" do
      context = course_model
      group_category = context.group_categories.create!(:name => "worldCup")
      group1 = Group.create!(:name=>"group1", :group_category=>group_category, :context => context)
      group2 = Group.create!(:name=>"group2", :group_category=>group_category, :context => context)
      user_model
      pseudonym_model(:user_id => @user.id)
      group1.add_user(@user)
      group1.users.should be_include(@user)

      group2.add_user(@user)
      group2.users.should be_include(@user)
      group1.reload
      group1.users.should_not be_include(@user)
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
        group.group_memberships.where(:workflow_state => workflow_state, :user_id => @user).first.should_not be_nil
      end
    end

    it "should allow specifying a workflow_state" do
      @communities = GroupCategory.communities_for(Account.default)
      @group.group_category = @communities
      @group.save!
      user_model

      [ 'invited', 'requested', 'accepted' ].each do |workflow_state|
        @group.add_user(@user, workflow_state)
        @group.group_memberships.where(:workflow_state => workflow_state, :user_id => @user).first.should_not be_nil
      end
    end

    it "should allow specifying that the user should be a moderator" do
      user_model
      @membership = @group.add_user(@user, 'accepted', true)
      @membership.moderator.should == true
    end

    it "should change the workflow_state of an already active user" do
      @communities = GroupCategory.communities_for(Account.default)
      @group.group_category = @communities
      @group.save!
      user_model
      @group.add_user(@user, 'accepted')
      @membership = @group.add_user(@user, 'requested')
      @membership.workflow_state.should == 'accepted'
    end
  end

  it "should grant manage permissions for associated objects to group managers" do
    e = course_with_teacher
    course = e.context
    teacher = e.user
    group = course.groups.create
    course.grants_right?(teacher, nil, :manage_groups).should be_true
    group.grants_right?(teacher, nil, :manage_wiki).should be_true
    group.grants_right?(teacher, nil, :manage_files).should be_true
    group.wiki.grants_right?(teacher, nil, :update_page).should be_true
    attachment = group.attachments.build
    attachment.grants_right?(teacher, nil, :create).should be_true
  end

  it "should only allow me to moderate_forum if I can moderate_forum of group's context" do
    course_with_teacher
    student_in_course
    group = @course.groups.create

    group.grants_right?(@teacher, nil, :moderate_forum).should be_true
    group.grants_right?(@student, nil, :moderate_forum).should be_false
  end

  it "should grant read_roster permissions to students that can freely join or request an invitation to the group" do
    course_with_teacher
    student_in_course

    # default join_level == 'invitation_only' and default category is not self-signup
    group = @course.groups.create
    group.grants_right?(@student, nil, :read_roster).should be_false

    # join_level allows requesting group membership
    group = @course.groups.create(:join_level => 'parent_context_request')
    group.grants_right?(@student, nil, :read_roster).should be_true

    # category is self-signup
    category = @course.group_categories.build(name: 'category name')
    category.self_signup = 'enabled'
    category.save
    group = @course.groups.create(:group_category => category)
    group.grants_right?(@student, nil, :read_roster).should be_true
  end

  describe "root account" do
    it "should get the root account assigned" do
      e = course_with_teacher
      group = @course.groups.create!
      group.account.should == Account.default
      group.root_account.should == Account.default

      new_root_acct = account_model
      new_sub_acct = new_root_acct.sub_accounts.create!(:name => 'sub acct')
      group.context = new_sub_acct
      group.save!
      group.account.should == new_sub_acct
      group.root_account.should == new_root_acct
    end
  end

  context "auto_accept?" do
    it "should be false unless join level is 'parent_context_auto_join'" do
      course_with_student

      group_category = GroupCategory.student_organized_for(@course)
      group1 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group2 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_request')
      group3 = @course.groups.create(:group_category => group_category, :join_level => 'invitation_only')
      [group1, group2, group3].map{|g| g.auto_accept?}.should == [true, false, false]
    end

    it "should be false unless the group is student organized or a community" do
      course_with_student
      @account = @course.root_account

      jl = 'parent_context_auto_join'
      group1 = @course.groups.create(:group_category => @course.group_categories.create(:name => "random category"), :join_level => jl)
      group2 = @course.groups.create(:group_category => GroupCategory.student_organized_for(@course), :join_level => jl)
      group3 = @account.groups.create(:group_category => GroupCategory.communities_for(@account), :join_level => jl)
      [group1, group2, group3].map{|g| g.auto_accept?}.should == [false, true, true]
    end
  end

  context "allow_join_request?" do
    it "should be false unless join level is 'parent_context_auto_join' or 'parent_context_request'" do
      course_with_student

      group_category = GroupCategory.student_organized_for(@course)
      group1 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_auto_join')
      group2 = @course.groups.create(:group_category => group_category, :join_level => 'parent_context_request')
      group3 = @course.groups.create(:group_category => group_category, :join_level => 'invitation_only')
      [group1, group2, group3].map{|g| g.allow_join_request?}.should == [true, true, false]
    end

    it "should be false unless the group is student organized or a community" do
      course_with_student
      @account = @course.root_account

      jl = 'parent_context_auto_join'
      group1 = @course.groups.create(:group_category => @course.group_categories.create(:name => "random category"), :join_level => jl)
      group2 = @course.groups.create(:group_category => GroupCategory.student_organized_for(@course), :join_level => jl)
      group3 = @account.groups.create(:group_category => GroupCategory.communities_for(@account), :join_level => jl)
      [group1, group2, group3].map{|g| g.allow_join_request?}.should == [false, true, true]
    end
  end

  context "allow_self_signup?" do
    it "should follow the group category self signup option" do
      course_with_student

      group_category = GroupCategory.student_organized_for(@course)
      group_category.configure_self_signup(true, false)
      group_category.save!
      group1 = @course.groups.create(:group_category => group_category)
      group1.allow_self_signup?(@student).should be_true

      group_category.configure_self_signup(true, true)
      group_category.save!
      group2 = @course.groups.create(:group_category => group_category)
      group2.allow_self_signup?(@student).should be_true

      group_category.configure_self_signup(false, false)
      group_category.save!
      group3 = @course.groups.create(:group_category => group_category)
      group3.allow_self_signup?(@student).should be_false
    end

    it "should correctly handle restricted course sections" do
      course_with_student
      @other_section = @course.course_sections.create!(:name => "Other Section")
      @other_student = @course.enroll_student(user_model, {:section => @other_section}).user

      group_category = GroupCategory.student_organized_for(@course)
      group_category.configure_self_signup(true, true)
      group_category.save!
      group1 = @course.groups.create(:group_category => group_category)
      group1.allow_self_signup?(@student).should be_true
      group1.add_user(@student)
      group1.reload
      group1.allow_self_signup?(@other_student).should be_false
    end
  end

  context "#full?" do
    it "returns true when category group_limit has been met" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 1
      @group.add_user user_model, 'accepted'
      @group.should be_full
    end

    it "returns true when max_membership has been met" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 0
      @group.max_membership = 1
      @group.add_user user_model, 'accepted'
      @group.should be_full
    end

    it "returns false when max_membership has not been met" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 0
      @group.max_membership = 2
      @group.add_user user_model, 'accepted'
      @group.should_not be_full
    end

    it "returns false when category group_limit has not been met" do
      # no category
      @group.should_not be_full
      # not full
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 2
      @group.add_user user_model, 'accepted'
      @group.should_not be_full
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

      @group.has_member?(@user1).should be_true
      @group.has_member?(@user2).should be_true
      @group.has_member?(@user3).should be_true # false when we turn auto_join off
      @group.has_member?(@user4).should be_true # false when we turn auto_join off
      @group.has_member?(@user5).should be_false
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

      @group.has_moderator?(@user1).should be_false
      @group.has_moderator?(@user2).should be_true
      @group.has_moderator?(@user3).should be_true # false when we turn auto_join off
      @group.has_moderator?(@user4).should be_true # false when we turn auto_join off
      @group.has_moderator?(@user5).should be_false
    end
  end

  context "invite_user" do
    it "should auto accept invitations" do
      course_with_student(:active_all => true)

      group_category = GroupCategory.student_organized_for(@course)

      group = @course.groups.create!(:group_category => group_category)
      gm = group.invite_user(@student)
      gm.should be_accepted
    end
  end

  context "request_user" do
    it "should auto accept invitations" do
      course_with_student(:active_all => true)

      group_category = GroupCategory.student_organized_for(@course)

      group = @course.groups.create!(:group_category => group_category, :join_level => 'parent_context_auto_join')
      gm = group.request_user(@student)
      gm.should be_accepted
    end
  end

  it "should default group_category to student organized category on save" do
    course_with_teacher
    group = @course.groups.create
    group.group_category.should == GroupCategory.student_organized_for(@course)

    group_category = @course.group_categories.create(:name => "random category")
    group = @course.groups.create(:group_category => group_category)
    group.group_category.should == group_category
  end

  it "as_json should include group_category" do
    course()
    gc = group_category(name: "Something")
    group = Group.create(:group_category => gc)
    hash = group.as_json
    hash["group"]["group_category"].should == "Something"
  end

  it "should maintain the deprecated category attribute" do
    course = course_model
    group = course.groups.create
    default_category = GroupCategory.student_organized_for(course)
    group.read_attribute(:category).should eql(default_category.name)
    group.group_category = group.context.group_categories.create(:name => "my category")
    group.save
    group.reload
    group.read_attribute(:category).should eql("my category")
    group.group_category = nil
    group.save
    group.reload
    group.read_attribute(:category).should eql(default_category.name)
  end

  context "has_common_section?" do
    it "should be false for accounts" do
      account = Account.default
      group = account.groups.create
      group.should_not have_common_section
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
      group.should_not have_common_section
    end

    it "should be true if all members group have a section in common" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.add_user(user2)
      group.should have_common_section
    end
  end

  context "has_common_section_with_user?" do
    it "should be false for accounts" do
      account = Account.default
      group = account.groups.create
      group.should_not have_common_section_with_user(user_model)
    end

    it "should not be true if the new member does't share a section with an existing member" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      section2 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section2.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.should_not have_common_section_with_user(user2)
    end

    it "should be true if all members group have a section in common with the new user" do
      course_with_teacher(:active_all => true)
      section1 = @course.course_sections.create
      user1 = section1.enroll_user(user_model, 'StudentEnrollment').user
      user2 = section1.enroll_user(user_model, 'StudentEnrollment').user
      group = @course.groups.create
      group.add_user(user1)
      group.should have_common_section_with_user(user2)
    end
  end

  context "tabs_available" do
    before do
      course_with_teacher
      @teacher = @user
      @group = group(:group_context => @course)
      @group.users << @student = student_in_course(:course => @course).user
    end

    it "should let members see everything" do
      @group.tabs_available(@student).map{|t|t[:id]}.should eql [
        Group::TAB_HOME,
        Group::TAB_ANNOUNCEMENTS,
        Group::TAB_PAGES,
        Group::TAB_PEOPLE,
        Group::TAB_DISCUSSIONS,
        Group::TAB_FILES,
        Group::TAB_CONFERENCES,
        Group::TAB_COLLABORATIONS,
      ]
    end

    it "should let admins see everything" do
      @group.tabs_available(@teacher).map{|t|t[:id]}.should eql [
        Group::TAB_HOME,
        Group::TAB_ANNOUNCEMENTS,
        Group::TAB_PAGES,
        Group::TAB_PEOPLE,
        Group::TAB_DISCUSSIONS,
        Group::TAB_FILES,
        Group::TAB_CONFERENCES,
        Group::TAB_COLLABORATIONS,
      ]
    end

    it "should not let nobodies see conferences" do
      @group.tabs_available(nil).map{|t|t[:id]}.should_not include Group::TAB_CONFERENCES
    end
  end

  describe "quota" do
    it "should default to Group.default_storage_quota" do
      @group.quota.should == Group.default_storage_quota
    end

    it "should be overridden by the account's default_group_storage_quota" do
      a = @group.account
      a.default_group_storage_quota = 10.megabytes
      a.save!

      @group.reload
      @group.quota.should == 10.megabytes
    end
  end

  describe "#feature_enabled?" do
    before(:each) do
      course_with_teacher(active_all: true)
      @course.root_account.allow_feature!(:draft_state)
    end

    context "a course with :draft_state enabled" do
      it "should pass its setting on to its groups" do
        @course.enable_feature!(:draft_state)
        group(group_context: @course).should be_feature_enabled(:draft_state)
      end
    end

    context "an account with :draft_state enabled" do
      before do
        @course.root_account.enable_feature!(:draft_state)
      end

      it "should pass its setting on to course groups" do
        group(group_context: @course).should be_feature_enabled(:draft_state)
      end

      it "should pass its setting on to account groups" do
        group(group_context: @course.root_account).should be_feature_enabled(:draft_state)
      end
    end
  end

  describe "#update_max_membership_from_group_category" do
    it "should set max_membership if there is a group category" do
      @group.group_category = @course.group_categories.build(:name => 'foo')
      @group.group_category.group_limit = 1
      @group.update_max_membership_from_group_category
      @group.max_membership.should == 1
    end

    it "should do nothing if there is no group category" do
      @group.max_membership.should be_nil
      @group.update_max_membership_from_group_category
      @group.max_membership.should be_nil
    end
  end
end
