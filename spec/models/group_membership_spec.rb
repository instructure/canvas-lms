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

describe GroupMembership do
  
  it "should ensure a mutually exclusive relationship" do
    group_model
    user_model
    @gm = group_membership_model(:save => false)
    @gm.expects(:ensure_mutually_exclusive_membership)
    @gm.save!
  end
  
  it "should dispatch a 'new_student_organized_group' message if the first membership in a student organized group" do
    course_with_teacher
    student = user_model
    @course.enroll_student(student)
    group = @course.groups.create(:group_category => GroupCategory.student_organized_for(@course))

    Notification.create(:name => "New Student Organized Group", :category => "TestImmediately")
    @teacher.communication_channels.create(:path => "test_channel_email_#{@teacher.id}", :path_type => "email").confirm

    group_membership = group.group_memberships.create(:user => student)
    group_membership.messages_sent.should be_include("New Student Organized Group")
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
    membership.should_not be_valid
    membership.errors[:user_id].should_not be_nil
  end

  context 'active_given_enrollments?' do
    before do
      @enrollment = course_with_student(:active_all => true)
      @course_group = @course.groups.create!
      @membership = @course_group.add_user(@student)
    end

    it 'should be false if the membership is pending (requested)' do
      @membership.workflow_state = 'requested'
      @membership.active_given_enrollments?([@enrollment]).should be_false
    end

    it 'should be false if the membership is terminated (deleted)' do
      @membership.workflow_state = 'deleted'
      @membership.active_given_enrollments?([@enrollment]).should be_false
    end

    it 'should be false given a course group without an enrollment in the list' do
      @membership.active_given_enrollments?([]).should be_false
    end

    it 'should be true for other course groups' do
      @membership.active_given_enrollments?([@enrollment]).should be_true
    end

    it 'should be true for account groups regardless of enrollments' do
      @account_group = Account.default.groups.create!
      @membership = @account_group.add_user(@student)
      @membership.active_given_enrollments?([]).should be_true
    end
  end

  it "should auto_join for backwards compatibility" do
    user_model
    group_model
    group_membership_model(:workflow_state => "invited")
    @group_membership.workflow_state.should == "accepted"
  end

  it "should not auto_join for communities" do
    user_model
    @communities = GroupCategory.communities_for(Account.default)
    group_model(:name => "Algebra Teachers", :group_category => @communities, :join_level => "parent_context_request")
    group_membership_model(:user => @user, :workflow_state => "requested")
    @group_membership.workflow_state.should == "requested"
  end

  context 'following' do
    before do
      user_model
      @communities = GroupCategory.communities_for(Account.default)
      group_model(:name => "Algebra Teachers", :group_category => @communities, :join_level => "parent_context_request")
    end

    it "should auto-follow the group when joining the group" do
      @group.add_user(@user, 'accepted')
      @user.reload.user_follows.find(:first, :conditions => { :followed_item_id => @group.id, :followed_item_type => 'Group' }).should_not be_nil
    end

    it "should auto-follow the group when a request is accepted" do
      @membership = @group.add_user(@user, 'requested')
      @user.reload.user_follows.find(:first, :conditions => { :followed_item_id => @group.id, :followed_item_type => 'Group' }).should be_nil
      @membership.workflow_state = 'accepted'
      @membership.save!
      @user.reload.user_follows.find(:first, :conditions => { :followed_item_id => @group.id, :followed_item_type => 'Group' }).should_not be_nil
    end

    it "should auto-follow the group when an invitation is accepted" do
      @membership = @group.add_user(@user, 'invited')
      @user.reload.user_follows.find(:first, :conditions => { :followed_item_id => @group.id, :followed_item_type => 'Group' }).should be_nil
      @membership.workflow_state = 'accepted'
      @membership.save!
      @user.reload.user_follows.find(:first, :conditions => { :followed_item_id => @group.id, :followed_item_type => 'Group' }).should_not be_nil
    end
  end

  context 'unfollowing' do
    before do
      user_model
      @communities = GroupCategory.communities_for(Account.default)
      group_model(:name => "Algebra Teachers", :group_category => @communities, :join_level => "parent_context_request")
    end

    it "should auto-unfollow the group when leaving the group" do
      @membership = @group.add_user(@user, 'accepted')
      @membership.workflow_state = 'deleted'
      @membership.save!
      @user.reload.user_follows.find(:first, :conditions => { :followed_item_id => @group.id, :followed_item_type => 'Group' }).should be_nil
    end

    it "should auto-unfollow the group when the membership is destroyed" do
      @membership = @group.add_user(@user, 'accepted')
      @membership.destroy
      @user.reload.user_follows.find(:first, :conditions => { :followed_item_id => @group.id, :followed_item_type => 'Group' }).should be_nil
    end
  end
end
