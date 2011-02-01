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

describe User do
  
  context "validation" do
    it "should create a new instance given valid attributes" do
      user_model
    end
  end
  
  it "should get the first email from communication_channel" do
    @user = User.create
    @cc1 = mock_model(CommunicationChannel)
    @cc1.stub!(:path).and_return('cc1')
    @cc2 = mock_model(CommunicationChannel)
    @cc2.stub!(:path).and_return('cc2')
    @user.stub!(:communication_channels).and_return([@cc1, @cc2])
    @user.stub!(:communication_channel).and_return(@cc1)
    @user.communication_channel.should eql(@cc1)
  end
  
  it "should be able to assert a name" do
    @user = User.create
    @user.assert_name(nil)
    @user.name.should eql('User') #be_nil
    @user.assert_name('david')
    @user.name.should eql('david')
    @user.assert_name('bill')
    @user.name.should eql('bill')
    @user.assert_name(nil)
    @user.name.should eql('bill')
    @user = User.find(@user)
    @user.name.should eql('bill')
  end
  
  it "should update account associations when a course account changes" do
    account1 = account_model
    account2 = account_model
    course_with_student
    @user.associated_accounts.length.should eql(0)
    
    @course.account = account1
    @course.save!
    @course.reload
    @user.reload
    
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account1)
    
    @course.account = account2
    @course.save!
    @user.reload
    
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account2)
  end
  
  it "should update account associations when a course account moves in the heirachy" do
    account1 = account_model
    
    @enrollment = course_with_student(:account => account1)
    @course.account = account1
    @course.save!
    @course.reload
    @user.reload
    
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account1)
    
    account2 = account_model
    account1.parent_account = account2
    account1.save!
    @course.reload
    @user.reload
    
    @user.associated_accounts.length.should eql(2)
    @user.associated_accounts[0].should eql(account1)
    @user.associated_accounts[1].should eql(account2)
  end
  
  it "should update account associations when a user is associated to an account just by pseudonym" do
    account1 = account_model
    user = user_with_pseudonym
    pseudonym = user.pseudonyms.first
    pseudonym.account = account1
    pseudonym.save
    
    user.reload
    user.associated_accounts.length.should eql(1)
    user.associated_accounts.first.should eql(account1)
    
    account2 = account_model
    account1.parent_account = account2
    account1.save!
    
    user.reload
    user.associated_accounts.length.should eql(2)
    user.associated_accounts[0].should eql(account1)
    user.associated_accounts[1].should eql(account2)
  end
  
  it "should populate dashboard_messages" do
    Notification.create(:name => "Assignment Created")
    course_with_teacher(:active_all => true)
    StreamItem.for_user(@user).should be_empty
    @a = @course.assignments.new(:title => "some assignment")
    @a.workflow_state = "available"
    @a.save
    StreamItem.for_user(@user).should_not be_empty
  end
  
  context "move_to_user" do
    it "should delete the old user" do
      @user1 = user_model
      @user2 = user_model
      @user2.move_to_user(@user1)
      @user1.reload
      @user2.reload
      @user1.should_not be_deleted
      @user2.should be_deleted
    end
    
    it "should move pseudonyms to the new user" do
      @user1 = user_model
      @user2 = user_model
      @user2.pseudonyms.create!(:unique_id => 'sam@yahoo.com')
      @user2.move_to_user(@user1)
      @user2.reload
      @user2.pseudonyms.should be_empty
      @user1.reload
      @user1.pseudonyms.map(&:unique_id).should be_include('sam@yahoo.com')
    end
    
    it "should move submissions to the new user (but only if they don't already exist)" do
      @user1 = user_model
      @user2 = user_model
      @a1 = assignment_model
      s1 = @a1.find_or_create_submission(@user1)
      s2 = @a1.find_or_create_submission(@user2)
      @a2 = assignment_model
      s3 = @a2.find_or_create_submission(@user2)
      @user2.submissions.length.should eql(2)
      @user1.submissions.length.should eql(1)
      @user2.move_to_user(@user1)
      @user2.reload
      @user1.reload
      @user2.submissions.length.should eql(1)
      @user2.submissions.first.id.should eql(s2.id)
      @user1.submissions.length.should eql(2)
      @user1.submissions.map(&:id).should be_include(s1.id)
      @user1.submissions.map(&:id).should be_include(s3.id)
    end
  end
end
