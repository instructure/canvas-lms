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
    @user.name.should eql('User')
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
  
  it "should update account associations when a course account moves in the hierachy" do
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
    account2 = account_model
    user = user_with_pseudonym

    pseudonym = user.pseudonyms.first
    pseudonym.account = account1
    pseudonym.save
    
    user.reload
    user.associated_accounts.length.should eql(1)
    user.associated_accounts.first.should eql(account1)

    # Make sure that multiple sequential updates also work
    pseudonym.account = account2
    pseudonym.save
    pseudonym.account = account1
    pseudonym.save
    user.reload
    user.associated_accounts.length.should eql(1)
    user.associated_accounts.first.should eql(account1)

    account1.parent_account = account2
    account1.save!
    
    user.reload
    user.associated_accounts.length.should eql(2)
    user.associated_accounts[0].should eql(account1)
    user.associated_accounts[1].should eql(account2)
  end

  it "should update account associations when a user is associated to an account just by account_users" do
    account = account_model
    @user = User.create
    account.add_user(@user)

    @user.reload
    @user.associated_accounts.length.should eql(1)
    @user.associated_accounts.first.should eql(account)
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
  
  it "should be able to remove itself from a root account" do
    account1 = Account.create
    account2 = Account.create
    user = User.create
    user.register!
    p1 = user.pseudonyms.create(:unique_id => "user1")
    p2 = user.pseudonyms.create(:unique_id => "user2")
    p1.account = account1
    p2.account = account2
    p1.save!
    p2.save!
    account1.add_user(user)
    account2.add_user(user)
    course1 = account1.courses.create
    course2 = account2.courses.create
    course1.offer!
    course2.offer!
    enrollment1 = course1.enroll_student(user)
    enrollment2 = course2.enroll_student(user)
    enrollment1.workflow_state = 'active'
    enrollment2.workflow_state = 'active'
    enrollment1.save!
    enrollment2.save!
    user.associated_account_ids.include?(account1.id).should be_true
    user.associated_account_ids.include?(account2.id).should be_true
    user.remove_from_root_account(account2)
    user.reload
    user.associated_account_ids.include?(account1.id).should be_true
    user.associated_account_ids.include?(account2.id).should be_false
  end

  it "should search by multiple fields" do
    @account = Account.create!
    user1 = User.create! :name => "longname1", :short_name => "shortname1"
    user1.register!
    user2 = User.create! :name => "longname2", :short_name => "shortname2"
    user2.register!

    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == []
    User.name_like("uniqueid2").map(&:id).should == []

    p1 = user1.pseudonyms.new :unique_id => "uniqueid1", :account => @account
    p1.sis_user_id = "sisid1"
    p1.save!
    p2 = user2.pseudonyms.new :unique_id => "uniqueid2", :account => @account
    p2.sis_user_id = "sisid2"
    p2.save!

    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]

    p3 = user1.pseudonyms.new :unique_id => "uniqueid3", :account => @account
    p3.sis_user_id = "sisid3"
    p3.save!
    
    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]
    User.name_like("uniqueid3").map(&:id).should == [user1.id]

    p4 = user1.pseudonyms.new :unique_id => "uniqueid4", :account => @account
    p4.sis_user_id = "sisid3 2"
    p4.save!

    User.name_like("longname1").map(&:id).should == [user1.id]
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]
    User.name_like("uniqueid3").map(&:id).should == [user1.id]
    User.name_like("sisid3").map(&:id).should == [user1.id]

    user3 = User.create! :name => "longname1", :short_name => "shortname3"
    user3.register!
    
    User.name_like("longname1").map(&:id).sort.should == [user1.id, user3.id].sort
    User.name_like("shortname2").map(&:id).should == [user2.id]
    User.name_like("sisid1").map(&:id).should == [user1.id]
    User.name_like("uniqueid2").map(&:id).should == [user2.id]
    User.name_like("uniqueid3").map(&:id).should == [user1.id]
    User.name_like("sisid3").map(&:id).should == [user1.id]

    User.name_like("sisid3").map(&:id).should == [user1.id]
    User.name_like("uniqueid4").map(&:id).should == [user1.id]
    p4.destroy
    User.name_like("sisid3").map(&:id).should == [user1.id]
    User.name_like("uniqueid4").map(&:id).should == []

  end

  it "should be able to be removed from a root account with non-Canvas auth" do
    account1 = account_with_cas
    account2 = Account.create!
    user = User.create!
    user.register!
    p1 = user.pseudonyms.new :unique_id => "id1", :account => account1
    p1.sis_source_id = 'sis_id1'
    p1.save!
    user.pseudonyms.create! :unique_id => "id2", :account => account2
    lambda { p1.destroy }.should raise_error /Cannot delete system-generated pseudonyms/
    user.remove_from_root_account account1
    user.associated_root_accounts.should eql [account2]
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

  context "permissions" do
    it "should grant become_user to self" do
      @user = user_with_pseudonym(:username => 'nobody1@example.com')
      @user.grants_right?(@user, nil, :become_user).should be_true
    end

    it "should not grant become_user to other users" do
      @user1 = user_with_pseudonym(:username => 'nobody1@example.com')
      @user2 = user_with_pseudonym(:username => 'nobody2@example.com')
      @user1.grants_right?(@user2, nil, :become_user).should be_false
      @user2.grants_right?(@user1, nil, :become_user).should be_false
    end

    it "should grant become_user to site and account admins" do
      user = user_with_pseudonym(:username => 'nobody1@example.com')
      @admin = user_with_pseudonym(:username => 'nobody2@example.com')
      @site_admin = user_with_pseudonym(:username => 'nobody3@example.com')
      Account.site_admin.add_user(@site_admin)
      Account.default.add_user(@admin)
      user.grants_right?(@site_admin, nil, :become_user).should be_true
      @admin.grants_right?(@site_admin, nil, :become_user).should be_true
      user.grants_right?(@admin, nil, :become_user).should be_true
      @admin.grants_right?(@admin, nil, :become_user).should be_true
      @admin.grants_right?(user, nil, :become_user).should be_false
      @site_admin.grants_right?(@site_admin, nil, :become_user).should be_true
      @site_admin.grants_right?(user, nil, :become_user).should be_false
      @site_admin.grants_right?(@admin, nil, :become_user).should be_false
    end

    it "should not grant become_user to other site admins" do
      @site_admin1 = user_with_pseudonym(:username => 'nobody1@example.com')
      @site_admin2 = user_with_pseudonym(:username => 'nobody2@example.com')
      Account.site_admin.add_user(@site_admin1)
      Account.site_admin.add_user(@site_admin2)
      @site_admin1.grants_right?(@site_admin2, nil, :become_user).should be_false
      @site_admin2.grants_right?(@site_admin1, nil, :become_user).should be_false
    end

    it "should not grant become_user to other account admins" do
      @admin1 = user_with_pseudonym(:username => 'nobody1@example.com')
      @admin2 = user_with_pseudonym(:username => 'nobody2@example.com')
      Account.default.add_user(@admin1)
      Account.default.add_user(@admin2)
      @admin1.grants_right?(@admin2, nil, :become_user).should be_false
      @admin2.grants_right?(@admin1, nil, :become_user).should be_false
    end

    it "should grant become_user for users in multiple accounts to site admins but not account admins" do
      user = user_with_pseudonym(:username => 'nobody1@example.com')
      @account2 = Account.create!
      user.pseudonyms.create!(:unique_id => 'nobodyelse@example.com', :account => @account2)
      @admin = user_with_pseudonym(:username => 'nobody2@example.com')
      @site_admin = user_with_pseudonym(:username => 'nobody3@example.com')
      Account.default.add_user(@admin)
      Account.site_admin.add_user(@site_admin)
      user.grants_right?(@admin, nil, :become_user).should be_false
      user.grants_right?(@site_admin, nil, :become_user).should be_true
      @account2.add_user(@admin)
      user.grants_right?(@admin, nil, :become_user).should be_true
    end

    it "should not grant become_user for dis-associated users" do
      @user1 = user_model
      @user2 = user_model
      @user1.grants_right?(@user2, nil, :become_user).should be_false
      @user2.grants_right?(@user1, nil, :become_user).should be_false
    end

    it "should grant become_user for dis-associated users to site admins" do
      user = user_model
      @site_admin = user_model
      Account.site_admin.add_user(@site_admin)
      user.grants_right?(@site_admin, nil, :become_user).should be_true
      @site_admin.grants_right?(user, nil, :become_user).should be_false
    end
  end

  context "messageable_users" do
    before(:each) do
      @admin = user_model
      @student = user_model
      tie_user_to_account(@admin, :membership_type => 'AccountAdmin')
      tie_user_to_account(@student, :membership_type => 'Student')
    end

    it "should include users with no shared contexts iff admin" do
      @admin.messageable_users(:ids => [@user.id]).should_not be_empty
      @user.messageable_users(:ids => [@admin.id]).should be_empty
    end

    it "should not do admin catch-all if specific contexts requested" do
      course1 = course_model
      course2 = course_model
      course2.offer!

      enrollment = course2.enroll_teacher(@admin)
      enrollment.workflow_state = 'active'
      enrollment.save
      @admin.reload

      enrollment = course2.enroll_student(@student)
      enrollment.workflow_state = 'active'
      enrollment.save

      @admin.messageable_users(:context => ["course_#{course1.id}"], :ids => [@student.id]).should be_empty
      @admin.messageable_users(:context => ["course_#{course2.id}"], :ids => [@student.id]).should_not be_empty
      @student.messageable_users(:context => ["course_#{course2.id}"], :ids => [@admin.id]).should_not be_empty
    end
  end
end
