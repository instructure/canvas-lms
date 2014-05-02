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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

def gen_ssha_password(password)
  salt = SecureRandom.random_bytes(10)
  "{SSHA}" + Base64.encode64(Digest::SHA1.digest(password+salt).unpack('H*').first+salt).gsub(/\s/, '')
end

describe SIS::CSV::UserImporter do

  before { account_model }

  it "should create new users and update names" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Uno")
    user.short_name.should eql("User Uno")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user1')

    user.communication_channels.count.should eql(1)
    cc = user.communication_channels.first
    cc.path.should eql("user@example.com")

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno 2,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Uno 2")
    user.short_name.should eql("User Uno 2")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user1')

    user.communication_channels.count.should eql(1)

    user.name = "My Awesome Name"
    user.save

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno 2,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.account.should eql(@account)
    user.name.should eql("My Awesome Name")
    user.short_name.should eql("My Awesome Name")
  end

  it "should create new users with display name" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Uno")
    user.short_name.should eql("The Uno")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user1')

    user.communication_channels.count.should eql(1)
    cc = user.communication_channels.first
    cc.path.should eql("user@example.com")

    # Field order shouldn't matter
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status,short_name",
        "user_2,user2,User,Dos,user2@example.com,active,The Dos"
    )
    user = CommunicationChannel.find_by_path('user2@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Dos")
    user.short_name.should eql("The Dos")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user2')

    user.communication_channels.count.should eql(1)
    cc = user.communication_channels.first
    cc.path.should eql("user2@example.com")
  end

  it "should create new users with full name" do
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Uno")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user1')

    user.communication_channels.count.should eql(1)
    cc = user.communication_channels.first
    cc.path.should eql("user@example.com")

    # Field order shouldn't matter
    process_csv_data_cleanly(
        "user_id,login_id,email,status,full_name",
        "user_2,user2,user2@example.com,active,User Dos"
    )
    user = CommunicationChannel.find_by_path('user2@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Dos")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user2')

    user.communication_channels.count.should eql(1)
    cc = user.communication_channels.first
    cc.path.should eql("user2@example.com")
  end

  it "should create new users with sortable name" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"One, User\",user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Uno")
    user.sortable_name.should eql("One, User")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user1')

    user.communication_channels.count.should eql(1)
    cc = user.communication_channels.first
    cc.path.should eql("user@example.com")

    # Field order shouldn't matter
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status,sortable_name",
        "user_2,user2,User,Dos,user2@example.com,active,\"Two, User\""
    )
    user = CommunicationChannel.find_by_path('user2@example.com').user
    user.account.should eql(@account)
    user.name.should eql("User Dos")
    user.sortable_name.should eql("Two, User")

    user.pseudonyms.count.should eql(1)
    pseudonym = user.pseudonyms.first
    pseudonym.unique_id.should eql('user2')

    user.communication_channels.count.should eql(1)
    cc = user.communication_channels.first
    cc.path.should eql("user2@example.com")
  end

  it "should preserve first name/last name split" do
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,badpassword,John,St. Clair,user@example.com,active,"
    )
    user = Pseudonym.find_by_unique_id('user1').user
    user.name.should == 'John St. Clair'
    user.sortable_name.should == 'St. Clair, John'
    user.first_name.should == 'John'
    user.last_name.should == 'St. Clair'
  end

  it "should tolerate blank first and last names" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,,,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.name.should eql(" ")

    process_csv_data_cleanly(
        "user_id,login_id,email,status",
        "user_2,user2,user2@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user2@example.com').user
    user.name.should eql(" ")
  end

  it "should ignore first and last names if full name is provided" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,full_name,email,status",
        "user_1,user1,,,User One,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.name.should eql("User One")
    user.sortable_name.should eql("One, User")

    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,full_name,email,status",
        "user_2,user2,User,Dos,User Two,user2@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user2@example.com').user
    user.name.should eql("User Two")
    user.sortable_name.should eql("Two, User")
  end

  it "should set passwords and not overwrite current passwords" do
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,badpassword,User,Uno 2,user@example.com,active,",
      "user_2,user2,,User,Uno 2,user2@example.com,active,#{gen_ssha_password("password")}"
    )
    user1 = CommunicationChannel.find_by_path('user@example.com').user
    p = user1.pseudonyms.first
    p.valid_arbitrary_credentials?('badpassword').should be_true

    p.password = 'lessbadpassword'
    p.password_confirmation = 'lessbadpassword'
    p.save

    user2 = CommunicationChannel.find_by_path('user2@example.com').user
    p = user2.pseudonyms.first
    p.valid_arbitrary_credentials?('password').should be_true

    p.password = 'newpassword'
    p.password_confirmation = 'newpassword'
    p.save

    p.valid_arbitrary_credentials?('password').should be_false
    p.valid_arbitrary_credentials?('newpassword').should be_true

    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,badpassword2,User,Uno 2,user@example.com,active",
      "user_2,user2,,User,Uno 2,user2@example.com,active,#{gen_ssha_password("changedpassword")}"
    )

    user1.reload
    p = user1.pseudonyms.first
    p.valid_arbitrary_credentials?('badpassword').should be_false
    p.valid_arbitrary_credentials?('badpassword2').should be_false
    p.valid_arbitrary_credentials?('lessbadpassword').should be_true

    user2.reload
    p = user2.pseudonyms.first
    p.valid_arbitrary_credentials?('password').should be_false
    p.valid_arbitrary_credentials?('changedpassword').should be_false
    p.valid_arbitrary_credentials?('newpassword').should be_true
    p.valid_ssha?('changedpassword').should be_true
  end

  it "should allow setting and resetting of passwords" do
    CommunicationChannel.find_by_path("user1@example.com").should be_nil
    CommunicationChannel.find_by_path("user2@example.com").should be_nil

    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,password1,User,Uno,user1@example.com,active,",
      "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass1")}"
    )

    user1_persistence_token = nil
    user2_persistence_token = nil
    CommunicationChannel.find_by_path('user1@example.com').user.pseudonyms.first.tap do |p|
      user1_persistence_token = p.persistence_token
      p.valid_arbitrary_credentials?('password1').should be_true
      p.valid_arbitrary_credentials?('password2').should be_false
      p.valid_arbitrary_credentials?('password3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_false
    end

    user2_sis_ssha = nil
    CommunicationChannel.find_by_path('user2@example.com').user.pseudonyms.first.tap do |p|
      user2_persistence_token = p.persistence_token
      user2_sis_ssha = p.sis_ssha
      p.valid_arbitrary_credentials?('encpass1').should be_true
      p.valid_arbitrary_credentials?('encpass2').should be_false
      p.valid_arbitrary_credentials?('encpass3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_false
    end

    # passwords haven't changed, neither should persistence tokens
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,password1,User,Uno,user1@example.com,active,",
      "user_2,user2,,User,Dos,user2@example.com,active,#{user2_sis_ssha}"
    )

    CommunicationChannel.find_by_path('user1@example.com').user.pseudonyms.first.tap do |p|
      user1_persistence_token.should == p.persistence_token
      p.valid_arbitrary_credentials?('password1').should be_true
      p.valid_arbitrary_credentials?('password2').should be_false
      p.valid_arbitrary_credentials?('password3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_false
    end

    CommunicationChannel.find_by_path('user2@example.com').user.pseudonyms.first.tap do |p|
      user2_persistence_token.should == p.persistence_token
      p.valid_arbitrary_credentials?('encpass1').should be_true
      p.valid_arbitrary_credentials?('encpass2').should be_false
      p.valid_arbitrary_credentials?('encpass3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_false
    end

    # passwords change, persistence token should change
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,password2,User,Uno,user1@example.com,active,",
      "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass2")}"
    )

    CommunicationChannel.find_by_path('user1@example.com').user.pseudonyms.first.tap do |p|
      user1_persistence_token.should_not == p.persistence_token
      p.valid_arbitrary_credentials?('password1').should be_false
      p.valid_arbitrary_credentials?('password2').should be_true
      p.valid_arbitrary_credentials?('password3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_false

      p.password_confirmation = p.password = 'password4'
      p.save
      user1_persistence_token = p.persistence_token
    end

    CommunicationChannel.find_by_path('user2@example.com').user.pseudonyms.first.tap do |p|
      user2_persistence_token.should_not == p.persistence_token
      p.valid_arbitrary_credentials?('encpass1').should be_false
      p.valid_arbitrary_credentials?('encpass2').should be_true
      p.valid_arbitrary_credentials?('encpass3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_false

      p.password_confirmation = p.password = 'password4'
      p.save
      user2_persistence_token = p.persistence_token
    end

    # user set password, persistence token should not change
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,password3,User,Uno,user1@example.com,active,",
      "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass3")}"
    )

    CommunicationChannel.find_by_path('user1@example.com').user.pseudonyms.first.tap do |p|
      user1_persistence_token.should == p.persistence_token
      p.valid_arbitrary_credentials?('password1').should be_false
      p.valid_arbitrary_credentials?('password2').should be_false
      p.valid_arbitrary_credentials?('password3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_true
    end

    CommunicationChannel.find_by_path('user2@example.com').user.pseudonyms.first.tap do |p|
      user2_persistence_token.should == p.persistence_token
      p.valid_arbitrary_credentials?('encpass1').should be_false
      p.valid_arbitrary_credentials?('encpass2').should be_false
      p.valid_arbitrary_credentials?('encpass3').should be_false
      p.valid_arbitrary_credentials?('password4').should be_true
    end

  end

  it "should catch active-record-level errors, like invalid unique_id" do
    before_user_count = User.count
    before_pseudo_count = Pseudonym.count
    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status",
      "U1,@,User,Uno,user@example.com,active"
    )
    CommunicationChannel.find_by_path('user@example.com').should be_nil

    importer.errors.map(&:last).should == []
    importer.warnings.map(&:last).should == ["Failed saving user. Internal error: unique_id is invalid"]
    [User.count, Pseudonym.count].should == [before_user_count, before_pseudo_count]
  end

  it "should not allow a secondary user account with the same login id." do
    p_count = Pseudonym.count
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.pseudonyms.count.should == 1
    user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'

    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user1,User,Uno,user@example.com,active"
    )
    importer.errors.should == []
    importer.warnings.map{|r|r.last}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.pseudonyms.count.should == 1
    user.pseudonyms.find_by_unique_id('user1').sis_user_id.should == 'user_1'
    Pseudonym.count.should == (p_count + 1)
  end

  it "should not allow a secondary user account to change its login id to some other registered login id" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )

    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user1,User,Dos,user2@example.com,active",
      "user_1,user3,User,Uno,user1@example.com,active"
    )
    importer.warnings.map{|r|r.last}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
    importer.errors.should == []
    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").unique_id.should == "user3"
    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_2").unique_id.should == "user2"
  end

  it "should allow a secondary user account to change its login id to some other registered login id if the other changes it first" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user3,User,Uno,user1@example.com,active",
      "user_2,user1,User,Dos,user2@example.com,active"
    )
    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").unique_id.should == "user3"
    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_2").unique_id.should == "user1"
  end

  it "should allow a user to update information" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user2,User,Uno-Dos,user1@example.com,active"
    )

    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.last_name.should == "Uno-Dos"
  end

  it "should allow a user to update display name specifically" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno,user1@example.com,active"
    )

    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno-Dos,user1@example.com,active"
    )

    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.short_name.should == "The Uno-Dos"
  end

  it "should allow a user to update full name name specifically" do
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,user1@example.com,active"
    )

    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Dos,user1@example.com,active"
    )

    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.name.should == "User Dos"
  end

  it "should allow a user to update sortable name specifically" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"One, User\",user1@example.com,active"
    )

    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"Two, User\",user1@example.com,active"
    )

    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.sortable_name.should == "Two, User"
  end

  it "should allow a user to update emails specifically" do
    enable_cache do
      now = Time.now
      Time.stubs(:now).returns(now - 2)
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )

      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.email.should == "user1@example.com"

      Time.stubs(:now).returns(now)
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user2@example.com,active"
      )

      Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.email.should == "user2@example.com"
    end
  end

  it "should update sortable name properly when full name is updated" do
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,user1@example.com,active"
    )

    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.sortable_name.should == "Uno, User"

    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Dos,user1@example.com,active"
    )

    Pseudonym.find_by_account_id_and_sis_user_id(@account.id, "user_1").user.sortable_name.should == "Dos, User"
  end

  it "should add two users with different user_ids, login_ids, but the same email" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    user1 = User.create!(:name => 'User Uno')
    user1.pseudonyms.create!(:unique_id => 'user1', :account => @account)
    user1.communication_channels.create!(:path => 'user@example.com') { |cc| cc.workflow_state = 'active' }

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user2,User,Dos,user@example.com,active"
    )
    user2 = Pseudonym.find_by_unique_id('user2').user
    user1.should_not == user2
    user2.last_name.should == "Dos"
    user2.pseudonyms.count.should == 1
    user2.pseudonyms.first.communication_channel_id.should_not be_nil

    Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first.should_not be_nil
  end

  it "should not notify about a merge opportunity to an SIS user in the same account" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active",
      "user_2,user2,User,Dos,user@example.com,active"
    )
    user1 = Pseudonym.find_by_unique_id('user1').user
    user2 = Pseudonym.find_by_unique_id('user2').user
    user1.should_not == user2
    user1.last_name.should == "Uno"
    user2.last_name.should == "Dos"
    user1.pseudonyms.count.should == 1
    user2.pseudonyms.count.should == 1
    user1.pseudonyms.first.communication_channel_id.should_not be_nil
    user2.pseudonyms.first.communication_channel_id.should_not be_nil

    Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first.should be_nil
  end

  it "should not notify about merge opportunities for users that have no means of logging in" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,deleted",
      "user_2,user2,User,Dos,user@example.com,active"
    )
    user1 = Pseudonym.find_by_unique_id('user1').user
    user2 = Pseudonym.find_by_unique_id('user2').user
    user1.should_not == user2
    user1.last_name.should == "Uno"
    user2.last_name.should == "Dos"
    user1.pseudonyms.count.should == 1
    user2.pseudonyms.count.should == 1
    user1.pseudonyms.first.communication_channel_id.should_not be_nil
    user2.pseudonyms.first.communication_channel_id.should_not be_nil

    Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first.should be_nil
  end

  it "should not have problems updating a user to a conflicting email" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    user1 = Pseudonym.find_by_unique_id('user1').user
    user2 = Pseudonym.find_by_unique_id('user2').user
    user1.should_not == user2
    user1.last_name.should == "Uno"
    user2.last_name.should == "Dos"
    user1.pseudonyms.count.should == 1
    user2.pseudonyms.count.should == 1
    user1.pseudonyms.first.communication_channel_id.should_not be_nil
    user2.pseudonyms.first.communication_channel_id.should_not be_nil

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user2,User,Dos,user1@example.com,active"
    )
    user2.reload
    user2.communication_channels.length.should == 1
    user2.email_channel.should be_active
    user2.email.should == 'user1@example.com'

    Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first.should be_nil
  end

  it "should not have a problem adding an existing e-mail that differs in case" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user1 = Pseudonym.find_by_unique_id('user1').user
    user1.communication_channels.create!(:path => 'JT@instructure.com')

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,jt@instructure.com,active"
    )
    user1.reload
    user1.communication_channels.count.should == 2
    user1.communication_channels.active.count.should == 1
    user1.email_channel.should be_active
    user1.email.should == 'jt@instructure.com'
  end

  it "should re-activate retired e-mails" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user1 = Pseudonym.find_by_unique_id('user1').user
    user1.email_channel.destroy
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user1.reload
    user1.email_channel.should be_active
    user1.communication_channels.length.should == 1
  end

  it "should send merge opportunity notifications when reactivating an email" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    user1 = User.create!(:name => 'User Uno')
    user1.pseudonyms.create!(:unique_id => 'user1', :account => @account)
    user1.communication_channels.create!(:path => 'user1@example.com') { |cc| cc.workflow_state = 'active' }

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user2,User,Dos,user1@example.com,deleted"
    )
    user2 = Pseudonym.find_by_unique_id('user2').user
    user1.should_not == user2
    user1.last_name.should == "Uno"
    user2.last_name.should == "Dos"
    user1.pseudonyms.count.should == 1
    user2.pseudonyms.count.should == 1
    user2.pseudonyms.first.communication_channel_id.should_not be_nil
    user1.email_channel.should_not == user2.email_channel
    Message.count.should == 0

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user2,User,Dos,user1@example.com,active"
    )
    user2.reload

    Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first.should_not be_nil
  end

  it "should not send merge opportunity notifications if the conflicting cc is retired or unconfirmed" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    u1 = User.create! { |u| u.workflow_state = 'registered' }
    cc1 = u1.communication_channels.create!(:path => 'user1@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'retired' }
    u2 = User.create! { |u| u.workflow_state = 'registered'}
    cc2 = u2.communication_channels.create!(:path => 'user1@example.com', :path_type => 'email')
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user1 = Pseudonym.find_by_unique_id('user1').user
    [u1, u2].should_not be_include(user1)
    user1.communication_channels.length.should == 1
    user1.email.should == 'user1@example.com'
    [cc1, cc2].should_not be_include(user1.email_channel)
    Message.where(:communication_channel_id => user1.email_channel, :notification_id => notification).first.should be_nil
  end

  it "should create everything in the deleted state when deleted initially" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,deleted"
    )
    p = Pseudonym.find_by_unique_id('user1')
    p.should be_deleted
    u = p.user
    u.communication_channels.length.should == 1
    u.communication_channels.first.should be_retired
  end

  it "should not add a user with the same login id as another user" do
    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user1,User,Dos,user2@example.com,active"
    )
    importer.errors.should == []
    importer.warnings.map{|x| x[1]}.should == ["user user_1 has already claimed user_2's requested login information, skipping"]
    Pseudonym.find_by_unique_id('user1').should_not be_nil
    Pseudonym.find_by_unique_id('user2').should be_nil
  end

  it "should not present an error for the same login_id with different case for same user" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_1,USer1,User,Uno,user1@example.com,active"
    )
    Pseudonym.find_by_sis_user_id('user_1').unique_id.should == 'USer1'
  end

  it "should use an existing pseudonym if it wasn't imported from sis and has the same login id" do
    u = User.create!
    u.register!
    p_count = Pseudonym.count
    p = u.pseudonyms.create!(:unique_id => "user2", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
    Pseudonym.find_by_unique_id('user1').should be_nil
    Pseudonym.find_by_unique_id('user2').should_not be_nil
    p.sis_user_id.should be_nil
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    p.reload
    Pseudonym.find_by_unique_id('user1').should_not be_nil
    Pseudonym.find_by_unique_id('user2').should_not be_nil
    Pseudonym.count.should == (p_count + 2)
    p.sis_user_id.should == "user_2"
  end

  it "should use an existing pseudonym if it wasn't imported from sis and has the same email address" do
    u = User.create!
    u.register!
    p_count = Pseudonym.count
    p = u.pseudonyms.create!(:unique_id => "user2@example.com", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
    Pseudonym.find_by_unique_id('user1').should be_nil
    Pseudonym.find_by_unique_id('user2').should be_nil
    Pseudonym.find_by_unique_id('user2@example.com').should_not be_nil
    p.sis_user_id.should be_nil
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    p.reload
    Pseudonym.find_by_unique_id('user1').should_not be_nil
    Pseudonym.find_by_unique_id('user2').should_not be_nil
    Pseudonym.find_by_unique_id('user2@example.com').should be_nil
    Pseudonym.count.should == (p_count + 2)
    p.sis_user_id.should == "user_2"
  end

  it "should strip white space on fields" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,short_name,sortable_name,email,status",
      "user_1  ,user1   ,User   ,Uno   ,The Uno   ,\"Uno, User   \",user@example.com   ,active  ",
      "   user_2,   user2,   User,   Dos,   The Dos,\"   Dos, User\",   user2@example.com,  active"
    )
    user = CommunicationChannel.find_by_path('user@example.com').user
    user.should_not be_nil
    user.name.should == "User Uno"
    user.sortable_name.should == "Uno, User"
    user.short_name.should == "The Uno"
    p = user.pseudonyms.first
    p.unique_id.should == "user1"
    user = CommunicationChannel.find_by_path('user2@example.com').user
    user.should_not be_nil
    user.name.should == "User Dos"
    user.sortable_name.should == "Dos, User"
    user.short_name.should == "The Dos"
    p = user.pseudonyms.first
    p.unique_id.should == "user2"
  end

  it "should use an existing communication channel" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    p = Pseudonym.find_by_unique_id('user1')
    user1 = p.user
    user1.last_name.should == "Uno"
    user1.pseudonyms.count.should == 1
    p.communication_channel_id.should_not be_nil
    user1.communication_channels.count.should == 1
    user1.communication_channels.first.path.should == 'user1@example.com'
    p.sis_communication_channel_id.should == p.communication_channel_id
    user1.communication_channels.create!(:path => 'user2@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }

    # change to user2@example.com; because user1@example.com was sis created, it should disappear
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user2@example.com,active"
    )
    p.reload
    user1.reload
    user1.pseudonyms.count.should == 1
    user1.communication_channels.count.should == 2
    user1.communication_channels.unretired.count.should == 1
    p.communication_channel_id.should_not be_nil
    user1.communication_channels.unretired.first.path.should == 'user2@example.com'
    p.sis_communication_channel_id.should == p.communication_channel_id
    p.communication_channel_id.should == user1.communication_channels.unretired.first.id
  end

  it "should use an existing active communication channel, even if a retired one exists" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,,active"
    )
    p = Pseudonym.find_by_unique_id('user1')
    u = p.user
    u.communication_channels.create!(:path => 'user1@example.com') { |ccc| ccc.workflow_state = 'retired' }
    cc = u.communication_channels.create!(:path => 'user1@example.com') { |ccc| ccc.workflow_state = 'active' }
    u.communication_channels.create!(:path => 'user1@example.com') { |ccc| ccc.workflow_state = 'retired' }
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,User1@example.com,active"
    )
    cc.reload
    cc.path.should == 'User1@example.com'
  end

  it "should work when a communication channel already exists, but there's no sis_communication_channel" do
    importer = process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,,active"
    )
    p = Pseudonym.find_by_unique_id('user1')
    user1 = p.user
    user1.last_name.should == "Uno"
    user1.pseudonyms.count.should == 1
    p.communication_channel_id.should be_nil
    user1.communication_channels.count.should == 0
    p.sis_communication_channel_id.should be_nil
    user1.communication_channels.create!(:path => 'user2@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }

    importer = process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user2@example.com,active"
    )
    p.reload
    user1.reload
    user1.pseudonyms.count.should == 1
    user1.communication_channels.count.should == 1
    user1.communication_channels.unretired.count.should == 1
    p.communication_channel_id.should_not be_nil
    user1.communication_channels.unretired.first.path.should == 'user2@example.com'
    p.sis_communication_channel_id.should == p.communication_channel_id
    p.communication_channel_id.should == user1.communication_channels.unretired.first.id
  end

  it "should handle stickiness" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,,active"
    )
    p = Pseudonym.find_by_unique_id('user1')
    p.unique_id = 'user5'
    p.save!
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user3,User,Uno,,active"
    )
    p.reload
    p.unique_id.should == 'user5'
    Pseudonym.find_by_unique_id('user1').should be_nil
    Pseudonym.find_by_unique_id('user3').should be_nil
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user3,User,Uno,,active",
      {:override_sis_stickiness => true}
    )
    p.reload
    p.unique_id.should == 'user3'
    Pseudonym.find_by_unique_id('user1').should be_nil
    Pseudonym.find_by_unique_id('user5').should be_nil
  end

  it "should handle display name stickiness" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno,,active"
    )
    user = Pseudonym.find_by_unique_id('user1').user
    user.short_name = 'The Amazing Uno'
    user.save!
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno-Dos,,active"
    )
    user.reload
    user.short_name.should == 'The Amazing Uno'
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno-Dos,,active",
        {:override_sis_stickiness => true}
    )
    user.reload
    user.short_name.should == 'The Uno-Dos'
  end

  it "should handle full name stickiness" do
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,,active"
    )
    user = Pseudonym.find_by_unique_id('user1').user
    user.name = 'The Amazing Uno'
    user.save!
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,,active"
    )
    user.reload
    user.name.should == 'The Amazing Uno'
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,,active",
        {:override_sis_stickiness => true}
    )
    user.reload
    user.name.should == 'User Uno'
  end

  it "should handle sortable name stickiness" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"One, User\",,active"
    )
    user = Pseudonym.find_by_unique_id('user1').user
    user.sortable_name = 'Uno, The Amazing'
    user.save!
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"Two, User\",,active"
    )
    user.reload
    user.sortable_name.should == 'Uno, The Amazing'
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"Two, User\",,active",
        {:override_sis_stickiness => true}
    )
    user.reload
    user.sortable_name.should == 'Two, User'
  end

  it 'should leave users around always' do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,deleted"
    )
    user1 = @account.pseudonyms.find_by_sis_user_id('user_1')
    user2 = @account.pseudonyms.find_by_sis_user_id('user_2')
    user1.workflow_state.should == 'active'
    user2.workflow_state.should == 'deleted'
    user1.user.workflow_state.should == 'registered'
    user2.user.workflow_state.should == 'registered'
  end

  it 'should remove enrollments when a user is deleted' do
    process_csv_data_cleanly(
      "course_id,short_name,long_name,account_id,term_id,status",
      "test_1,TC 101,Test Course 101,,,active",
      "test_2,TC 102,Test Course 102,,,active"
    )
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    process_csv_data_cleanly(
      "section_id,course_id,name,status,start_date,end_date",
      "S001,test_1,Sec1,active,,",
      "S002,test_2,Sec1,active,,"
    )
    # the enrollments
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
      "test_1,user_1,teacher,,active,,,",
      ",user_1,student,S002,active,,,"
    )
    @account.courses.find_by_sis_source_id("test_1").teachers.map(&:name).include?("User Uno").should be_true
    @account.courses.find_by_sis_source_id("test_2").students.map(&:name).include?("User Uno").should be_true
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    @account.courses.find_by_sis_source_id("test_1").teachers.map(&:name).include?("User Uno").should be_true
    @account.courses.find_by_sis_source_id("test_2").students.map(&:name).include?("User Uno").should be_true
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,deleted"
    )
    @account.courses.find_by_sis_source_id("test_1").teachers.map(&:name).include?("User Uno").should be_false
    @account.courses.find_by_sis_source_id("test_2").students.map(&:name).include?("User Uno").should be_false
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    @account.courses.find_by_sis_source_id("test_1").teachers.map(&:name).include?("User Uno").should be_false
    @account.courses.find_by_sis_source_id("test_2").students.map(&:name).include?("User Uno").should be_false
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
      "test_1,user_1,teacher,,active,,,",
      ",user_1,student,S002,active,,,"
    )
    @account.courses.find_by_sis_source_id("test_1").teachers.map(&:name).include?("User Uno").should be_true
    @account.courses.find_by_sis_source_id("test_2").students.map(&:name).include?("User Uno").should be_true
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    @account.courses.find_by_sis_source_id("test_1").teachers.map(&:name).include?("User Uno").should be_true
    @account.courses.find_by_sis_source_id("test_2").students.map(&:name).include?("User Uno").should be_true
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,deleted"
    )
    @account.courses.find_by_sis_source_id("test_1").teachers.map(&:name).include?("User Uno").should be_false
    @account.courses.find_by_sis_source_id("test_2").students.map(&:name).include?("User Uno").should be_false
  end

  context 'account associations' do
    before(:each) do
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,Humanities,active",
        "A002,A001,English,active",
        "A003,A002,English Literature,active",
        "A004,,Awesomeness,active"
      )
    end

    it "should work with users created as both active and deleted" do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_2,user2,User,Dos,user2@example.com,deleted"
      )
      user1 = @account.pseudonyms.find_by_sis_user_id('user_1')
      user2 = @account.pseudonyms.find_by_sis_user_id('user_2')
      user1.user.user_account_associations.map { |uaa| [uaa.account_id, uaa.depth] }.should == [[@account.id, 0]]
      user2.user.user_account_associations.should be_empty

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted"
      )
      user1.reload
      user1.user.user_account_associations.should be_empty
    end

    it 'should work when a user gets undeleted' do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )
      user = @account.pseudonyms.find_by_sis_user_id('user_1')
      user.user.user_account_associations.map { |uaa| [uaa.account_id, uaa.depth] }.should == [[@account.id, 0]]

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted"
      )
      user = @account.pseudonyms.find_by_sis_user_id('user_1')
      user.user.user_account_associations.should be_empty

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )
      user = @account.pseudonyms.find_by_sis_user_id('user_1')
      user.user.user_account_associations.map { |uaa| [uaa.account_id, uaa.depth] }.should == [[@account.id, 0]]
    end

    it 'should delete user enrollments for the current account when deleted, and update appropriate account associations' do
      @account1 = @account
      @account2 = account_model
      @account = @account1
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active")
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A001,,TestAccount1,active",
        "A002,A001,TestAccount1A,active")
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "C001,TC 101,Test Course 1,A002,,active,,")
      process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "S001,C001,Test Course 1,active,,")
      @account.pseudonyms.find_by_sis_user_id('user_1').user.user_account_associations.map { |uaa| uaa.account_id }.should == [@account.id]
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
        "C001,user_1,teacher,,active,,,"
      )
      @pseudo1 = @account.pseudonyms.find_by_sis_user_id('user_1')
      @pseudo1.user.user_account_associations.map { |uaa| uaa.account_id }.sort.should == [@account.id, Account.find_by_sis_source_id('A002').id, Account.find_by_sis_source_id('A001').id].sort

      @account = @account2
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active")
      process_csv_data_cleanly(
        "account_id,parent_account_id,name,status",
        "A101,,TestAccount1,active",
        "A102,A101,TestAccount1A,active")
      process_csv_data_cleanly(
        "course_id,short_name,long_name,account_id,term_id,status,start_date,end_date",
        "C001,TC 101,Test Course 1,A102,,active,,")
      process_csv_data_cleanly(
        "section_id,course_id,name,status,start_date,end_date",
        "S001,C001,Test Course 1,active,,")
      @account.pseudonyms.find_by_sis_user_id('user_1').user.user_account_associations.map { |uaa| uaa.account_id }.should == [@account.id]
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
        "C001,user_1,teacher,,active,,,"
      )
      @pseudo2 = @account.pseudonyms.find_by_sis_user_id('user_1')
      @pseudo2.user.user_account_associations.map { |uaa| uaa.account_id }.sort.should == [@account.id, Account.find_by_sis_source_id('A102').id, Account.find_by_sis_source_id('A101').id].sort

      UserMerge.from(@pseudo1.user).into(@pseudo2.user)
      @user = @account1.pseudonyms.find_by_sis_user_id('user_1').user
      @account2.pseudonyms.find_by_sis_user_id('user_1').user.should == @user

      @user.user_account_associations.map { |uaa| uaa.account_id }.sort.should == [@account1.id, @account2.id, Account.find_by_sis_source_id('A002').id, Account.find_by_sis_source_id('A001').id, Account.find_by_sis_source_id('A102').id, Account.find_by_sis_source_id('A101').id].sort

      @account = @account1
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted")
      @account1.pseudonyms.find_by_sis_user_id('user_1').tap do |pseudo|
        pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort.should == [@account2.id, Account.find_by_sis_source_id('A102').id, Account.find_by_sis_source_id('A101').id].sort
        pseudo.workflow_state.should == 'deleted'
        pseudo.user.workflow_state.should == 'registered'
      end
      @account2.pseudonyms.find_by_sis_user_id('user_1').tap do |pseudo|
        pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort.should == [@account2.id, Account.find_by_sis_source_id('A102').id, Account.find_by_sis_source_id('A101').id].sort
        pseudo.workflow_state.should == 'active'
        pseudo.user.workflow_state.should == 'registered'
      end
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active")
      @account1.pseudonyms.find_by_sis_user_id('user_1').tap do |pseudo|
        pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort.should == [@account2.id, Account.find_by_sis_source_id('A102').id, Account.find_by_sis_source_id('A101').id, @account1.id].sort
        pseudo.workflow_state.should == 'active'
        pseudo.user.workflow_state.should == 'registered'
      end
      @account2.pseudonyms.find_by_sis_user_id('user_1').tap do |pseudo|
        pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort.should == [@account2.id, Account.find_by_sis_source_id('A102').id, Account.find_by_sis_source_id('A101').id, @account1.id].sort
        pseudo.workflow_state.should == 'active'
        pseudo.user.workflow_state.should == 'registered'
      end
    end
  end

  it "should not steal the communication channel of the previous user" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user_1 = Pseudonym.find_by_unique_id('user1').user
    user_1.email.should == 'user1@example.com'
    user_1.pseudonym.sis_communication_channel.should == user_1.email_channel
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    user_1 = Pseudonym.find_by_unique_id('user1').user
    user_2 = Pseudonym.find_by_unique_id('user2').user
    user_1.email.should == 'user1@example.com'
    user_2.email.should == 'user2@example.com'
    user_1.pseudonym.sis_communication_channel.should == user_1.email_channel
    user_2.pseudonym.sis_communication_channel.should == user_2.email_channel
  end

  it "should not resurrect a non SIS user" do
    @non_sis_user = user_with_pseudonym(:active_all => 1)
    @non_sis_user.remove_from_root_account(Account.default)
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,#{@pseudonym.unique_id},User,Uno,#{@pseudonym.unique_id},active"
    )
    user_1 = Pseudonym.find_by_sis_user_id('user_1').user
    user_1.should_not == @non_sis_user
    user_1.pseudonym.should_not == @pseudonym
  end

  it "should not resurrect a non SIS pseudonym" do
    @non_sis_user = user_with_pseudonym(:active_all => 1)
    @pseudonym = @user.pseudonyms.create!(:unique_id => 'user1', :account => Account.default)
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user_1 = Pseudonym.find_by_sis_user_id('user_1').user
    user_1.should_not == @non_sis_user
    user_1.pseudonym.should_not == @pseudonym
  end

  it "should error nicely when resurrecting an SIS user that conflicts with an active user" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted"
    )
    @non_sis_user = user_with_pseudonym(:active_all => 1)
    @pseudonym = @non_sis_user.pseudonyms.create!(:unique_id => 'user1', :account => @account)
    importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
    )
    importer.errors.should == []
    importer.warnings.length.should == 1
    importer.warnings.last.last.should == "user #{@non_sis_user.id} has already claimed user_1's requested login information, skipping"
  end
end
