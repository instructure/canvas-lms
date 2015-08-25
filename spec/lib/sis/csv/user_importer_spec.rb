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
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Uno")
    expect(user.short_name).to eql("User Uno")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user1')

    expect(user.communication_channels.count).to eql(1)
    cc = user.communication_channels.first
    expect(cc.path).to eql("user@example.com")

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno 2,user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Uno 2")
    expect(user.short_name).to eql("User Uno 2")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user1')

    expect(user.communication_channels.count).to eql(1)

    user.name = "My Awesome Name"
    user.save

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno 2,user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("My Awesome Name")
    expect(user.short_name).to eql("My Awesome Name")
  end

  it "should create new users with display name" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno,user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Uno")
    expect(user.short_name).to eql("The Uno")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user1')

    expect(user.communication_channels.count).to eql(1)
    cc = user.communication_channels.first
    expect(cc.path).to eql("user@example.com")

    # Field order shouldn't matter
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status,short_name",
        "user_2,user2,User,Dos,user2@example.com,active,The Dos"
    )
    user = CommunicationChannel.by_path('user2@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Dos")
    expect(user.short_name).to eql("The Dos")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user2')

    expect(user.communication_channels.count).to eql(1)
    cc = user.communication_channels.first
    expect(cc.path).to eql("user2@example.com")
  end

  it "should create new users with full name" do
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Uno")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user1')

    expect(user.communication_channels.count).to eql(1)
    cc = user.communication_channels.first
    expect(cc.path).to eql("user@example.com")

    # Field order shouldn't matter
    process_csv_data_cleanly(
        "user_id,login_id,email,status,full_name",
        "user_2,user2,user2@example.com,active,User Dos"
    )
    user = CommunicationChannel.by_path('user2@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Dos")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user2')

    expect(user.communication_channels.count).to eql(1)
    cc = user.communication_channels.first
    expect(cc.path).to eql("user2@example.com")
  end

  it "should create new users with sortable name" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"One, User\",user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Uno")
    expect(user.sortable_name).to eql("One, User")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user1')

    expect(user.communication_channels.count).to eql(1)
    cc = user.communication_channels.first
    expect(cc.path).to eql("user@example.com")

    # Field order shouldn't matter
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status,sortable_name",
        "user_2,user2,User,Dos,user2@example.com,active,\"Two, User\""
    )
    user = CommunicationChannel.by_path('user2@example.com').first.user
    expect(user.account).to eql(@account)
    expect(user.name).to eql("User Dos")
    expect(user.sortable_name).to eql("Two, User")

    expect(user.pseudonyms.count).to eql(1)
    pseudonym = user.pseudonyms.first
    expect(pseudonym.unique_id).to eql('user2')

    expect(user.communication_channels.count).to eql(1)
    cc = user.communication_channels.first
    expect(cc.path).to eql("user2@example.com")
  end

  it "should preserve first name/last name split" do
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,badpassword,John,St. Clair,user@example.com,active,"
    )
    user = Pseudonym.by_unique_id('user1').first.user
    expect(user.name).to eq 'John St. Clair'
    expect(user.sortable_name).to eq 'St. Clair, John'
    expect(user.first_name).to eq 'John'
    expect(user.last_name).to eq 'St. Clair'
  end

  it "should tolerate blank first and last names" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,,,user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.name).to eql(" ")

    process_csv_data_cleanly(
        "user_id,login_id,email,status",
        "user_2,user2,user2@example.com,active"
    )
    user = CommunicationChannel.by_path('user2@example.com').first.user
    expect(user.name).to eql(" ")
  end

  it "should ignore first and last names if full name is provided" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,full_name,email,status",
        "user_1,user1,,,User One,user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.name).to eql("User One")
    expect(user.sortable_name).to eql("One, User")

    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,full_name,email,status",
        "user_2,user2,User,Dos,User Two,user2@example.com,active"
    )
    user = CommunicationChannel.by_path('user2@example.com').first.user
    expect(user.name).to eql("User Two")
    expect(user.sortable_name).to eql("Two, User")
  end

  it "should set passwords and not overwrite current passwords" do
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,badpassword,User,Uno 2,user@example.com,active,",
      "user_2,user2,,User,Uno 2,user2@example.com,active,#{gen_ssha_password("password")}"
    )
    user1 = CommunicationChannel.by_path('user@example.com').first.user
    p = user1.pseudonyms.first
    expect(p.valid_arbitrary_credentials?('badpassword')).to be_truthy

    p.password = 'lessbadpassword'
    p.password_confirmation = 'lessbadpassword'
    p.save

    user2 = CommunicationChannel.by_path('user2@example.com').first.user
    p = user2.pseudonyms.first
    expect(p.valid_arbitrary_credentials?('password')).to be_truthy

    p.password = 'newpassword'
    p.password_confirmation = 'newpassword'
    p.save

    expect(p.valid_arbitrary_credentials?('password')).to be_falsey
    expect(p.valid_arbitrary_credentials?('newpassword')).to be_truthy

    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,badpassword2,User,Uno 2,user@example.com,active",
      "user_2,user2,,User,Uno 2,user2@example.com,active,#{gen_ssha_password("changedpassword")}"
    )

    user1.reload
    p = user1.pseudonyms.first
    expect(p.valid_arbitrary_credentials?('badpassword')).to be_falsey
    expect(p.valid_arbitrary_credentials?('badpassword2')).to be_falsey
    expect(p.valid_arbitrary_credentials?('lessbadpassword')).to be_truthy

    user2.reload
    p = user2.pseudonyms.first
    expect(p.valid_arbitrary_credentials?('password')).to be_falsey
    expect(p.valid_arbitrary_credentials?('changedpassword')).to be_falsey
    expect(p.valid_arbitrary_credentials?('newpassword')).to be_truthy
    expect(p.valid_ssha?('changedpassword')).to be_truthy
  end

  it "should recognize integration_id and work" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status,ssha_password,integration_id",
        "user_2,user2,User,Dos,user@example.com,active,#{gen_ssha_password("password")}, 9000"
    )
    user2 = Pseudonym.by_unique_id('user2').first.user
    expect(user2.pseudonym.integration_id).to eq "9000"
  end

  it "should recognize there's no integration_id and still work" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status,ssha_password",
        "user_2,user2,User,Dos,user@example.com,active,#{gen_ssha_password("password")}"
    )
    user2 = Pseudonym.by_unique_id('user2').first.user
    expect(user2.pseudonym.integration_id).to be_nil
  end

  it "should allow setting and resetting of passwords" do
    expect(CommunicationChannel.by_path("user1@example.com").first).to be_nil
    expect(CommunicationChannel.by_path("user2@example.com").first).to be_nil

    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,password1,User,Uno,user1@example.com,active,",
      "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass1")}"
    )

    user1_persistence_token = nil
    user2_persistence_token = nil
    CommunicationChannel.by_path('user1@example.com').first.user.pseudonyms.first.tap do |p|
      user1_persistence_token = p.persistence_token
      expect(p.valid_arbitrary_credentials?('password1')).to be_truthy
      expect(p.valid_arbitrary_credentials?('password2')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_falsey
    end

    user2_sis_ssha = nil
    CommunicationChannel.by_path('user2@example.com').first.user.pseudonyms.first.tap do |p|
      user2_persistence_token = p.persistence_token
      user2_sis_ssha = p.sis_ssha
      expect(p.valid_arbitrary_credentials?('encpass1')).to be_truthy
      expect(p.valid_arbitrary_credentials?('encpass2')).to be_falsey
      expect(p.valid_arbitrary_credentials?('encpass3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_falsey
    end

    # passwords haven't changed, neither should persistence tokens
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,password1,User,Uno,user1@example.com,active,",
      "user_2,user2,,User,Dos,user2@example.com,active,#{user2_sis_ssha}"
    )

    CommunicationChannel.by_path('user1@example.com').first.user.pseudonyms.first.tap do |p|
      expect(user1_persistence_token).to eq p.persistence_token
      expect(p.valid_arbitrary_credentials?('password1')).to be_truthy
      expect(p.valid_arbitrary_credentials?('password2')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_falsey
    end

    CommunicationChannel.by_path('user2@example.com').first.user.pseudonyms.first.tap do |p|
      expect(user2_persistence_token).to eq p.persistence_token
      expect(p.valid_arbitrary_credentials?('encpass1')).to be_truthy
      expect(p.valid_arbitrary_credentials?('encpass2')).to be_falsey
      expect(p.valid_arbitrary_credentials?('encpass3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_falsey
    end

    # passwords change, persistence token should change
    process_csv_data_cleanly(
      "user_id,login_id,password,first_name,last_name,email,status,ssha_password",
      "user_1,user1,password2,User,Uno,user1@example.com,active,",
      "user_2,user2,,User,Dos,user2@example.com,active,#{gen_ssha_password("encpass2")}"
    )

    CommunicationChannel.by_path('user1@example.com').first.user.pseudonyms.first.tap do |p|
      expect(user1_persistence_token).not_to eq p.persistence_token
      expect(p.valid_arbitrary_credentials?('password1')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password2')).to be_truthy
      expect(p.valid_arbitrary_credentials?('password3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_falsey

      p.password_confirmation = p.password = 'password4'
      p.save
      user1_persistence_token = p.persistence_token
    end

    CommunicationChannel.by_path('user2@example.com').first.user.pseudonyms.first.tap do |p|
      expect(user2_persistence_token).not_to eq p.persistence_token
      expect(p.valid_arbitrary_credentials?('encpass1')).to be_falsey
      expect(p.valid_arbitrary_credentials?('encpass2')).to be_truthy
      expect(p.valid_arbitrary_credentials?('encpass3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_falsey

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

    CommunicationChannel.by_path('user1@example.com').first.user.pseudonyms.first.tap do |p|
      expect(user1_persistence_token).to eq p.persistence_token
      expect(p.valid_arbitrary_credentials?('password1')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password2')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_truthy
    end

    CommunicationChannel.by_path('user2@example.com').first.user.pseudonyms.first.tap do |p|
      expect(user2_persistence_token).to eq p.persistence_token
      expect(p.valid_arbitrary_credentials?('encpass1')).to be_falsey
      expect(p.valid_arbitrary_credentials?('encpass2')).to be_falsey
      expect(p.valid_arbitrary_credentials?('encpass3')).to be_falsey
      expect(p.valid_arbitrary_credentials?('password4')).to be_truthy
    end

  end

  it "should catch active-record-level errors, like invalid unique_id" do
    before_user_count = User.count
    before_pseudo_count = Pseudonym.count
    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status",
      "U1,@,User,Uno,user@example.com,active"
    )
    expect(CommunicationChannel.by_path('user@example.com').first).to be_nil

    expect(importer.errors.map(&:last)).to eq []
    expect(importer.warnings.map(&:last)).to eq ["Failed saving user. Internal error: unique_id is invalid"]
    expect([User.count, Pseudonym.count]).to eq [before_user_count, before_pseudo_count]
  end

  it "should not allow a secondary user account with the same login id." do
    p_count = Pseudonym.count
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.pseudonyms.count).to eq 1
    expect(user.pseudonyms.by_unique_id('user1').first.sis_user_id).to eq 'user_1'

    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user1,User,Uno,user@example.com,active"
    )
    expect(importer.errors).to eq []
    expect(importer.warnings.map{|r|r.last}).to eq ["user user_1 has already claimed user_2's requested login information, skipping"]
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user.pseudonyms.count).to eq 1
    expect(user.pseudonyms.by_unique_id('user1').first.sis_user_id).to eq 'user_1'
    expect(Pseudonym.count).to eq(p_count + 1)
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
    expect(importer.warnings.map{|r|r.last}).to eq ["user user_1 has already claimed user_2's requested login information, skipping"]
    expect(importer.errors).to eq []
    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.unique_id).to eq "user3"
    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_2").first.unique_id).to eq "user2"
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
    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.unique_id).to eq "user3"
    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_2").first.unique_id).to eq "user1"
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

    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.user.last_name).to eq "Uno-Dos"
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

    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.user.short_name).to eq "The Uno-Dos"
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

    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.user.name).to eq "User Dos"
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

    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.user.sortable_name).to eq "Two, User"
  end

  it "should allow a user to update emails specifically" do
    enable_cache do
      now = Time.now
      Time.stubs(:now).returns(now - 2)
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )

      expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.user.email).to eq "user1@example.com"

      Time.stubs(:now).returns(now)
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user2@example.com,active"
      )

      expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.user.email).to eq "user2@example.com"
    end
  end

  it "should update sortable name properly when full name is updated" do
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,user1@example.com,active"
    )

    expect(Pseudonym.where(account_id: @account, sis_user_id: "user_1").first.user.sortable_name).to eq "Uno, User"

    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Dos,user1@example.com,active"
    )

    expect(Pseudonym.where(account_id:@account, sis_user_id: "user_1").first.user.sortable_name).to eq "Dos, User"
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
    user2 = Pseudonym.by_unique_id('user2').first.user
    expect(user1).not_to eq user2
    expect(user2.last_name).to eq "Dos"
    expect(user2.pseudonyms.count).to eq 1
    expect(user2.pseudonyms.first.communication_channel_id).not_to be_nil

    expect(Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first).not_to be_nil
  end

  it "should not notify about a merge opportunity to an SIS user in the same account" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active",
      "user_2,user2,User,Dos,user@example.com,active"
    )
    user1 = Pseudonym.by_unique_id('user1').first.user
    user2 = Pseudonym.by_unique_id('user2').first.user
    expect(user1).not_to eq user2
    expect(user1.last_name).to eq "Uno"
    expect(user2.last_name).to eq "Dos"
    expect(user1.pseudonyms.count).to eq 1
    expect(user2.pseudonyms.count).to eq 1
    expect(user1.pseudonyms.first.communication_channel_id).not_to be_nil
    expect(user2.pseudonyms.first.communication_channel_id).not_to be_nil

    expect(Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first).to be_nil
  end

  it "should not notify about merge opportunities for users that have no means of logging in" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,deleted",
      "user_2,user2,User,Dos,user@example.com,active"
    )
    user1 = Pseudonym.by_unique_id('user1').first.user
    user2 = Pseudonym.by_unique_id('user2').first.user
    expect(user1).not_to eq user2
    expect(user1.last_name).to eq "Uno"
    expect(user2.last_name).to eq "Dos"
    expect(user1.pseudonyms.count).to eq 1
    expect(user2.pseudonyms.count).to eq 1
    expect(user1.pseudonyms.first.communication_channel_id).not_to be_nil
    expect(user2.pseudonyms.first.communication_channel_id).not_to be_nil

    expect(Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first).to be_nil
  end

  it "should not have problems updating a user to a conflicting email" do
    notification = Notification.create(:name => 'Merge Email Communication Channel', :category => 'Registration')
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    user1 = Pseudonym.by_unique_id('user1').first.user
    user2 = Pseudonym.by_unique_id('user2').first.user
    expect(user1).not_to eq user2
    expect(user1.last_name).to eq "Uno"
    expect(user2.last_name).to eq "Dos"
    expect(user1.pseudonyms.count).to eq 1
    expect(user2.pseudonyms.count).to eq 1
    expect(user1.pseudonyms.first.communication_channel_id).not_to be_nil
    expect(user2.pseudonyms.first.communication_channel_id).not_to be_nil

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user2,User,Dos,user1@example.com,active"
    )
    user2.reload
    expect(user2.communication_channels.length).to eq 1
    expect(user2.email_channel).to be_active
    expect(user2.email).to eq 'user1@example.com'

    expect(Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first).to be_nil
  end

  it "should not have a problem adding an existing e-mail that differs in case" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user1 = Pseudonym.by_unique_id('user1').first.user
    user1.communication_channels.create!(:path => 'JT@instructure.com')

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,jt@instructure.com,active"
    )
    user1.reload
    expect(user1.communication_channels.count).to eq 2
    expect(user1.communication_channels.active.count).to eq 1
    expect(user1.email_channel).to be_active
    expect(user1.email).to eq 'jt@instructure.com'
  end

  it "should re-activate retired e-mails" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user1 = Pseudonym.by_unique_id('user1').first.user
    user1.email_channel.destroy
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user1.reload
    expect(user1.email_channel).to be_active
    expect(user1.communication_channels.length).to eq 1
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
    user2 = Pseudonym.by_unique_id('user2').first.user
    expect(user1).not_to eq user2
    expect(user1.last_name).to eq "Uno"
    expect(user2.last_name).to eq "Dos"
    expect(user1.pseudonyms.count).to eq 1
    expect(user2.pseudonyms.count).to eq 1
    expect(user2.pseudonyms.first.communication_channel_id).not_to be_nil
    expect(user1.email_channel).not_to eq user2.email_channel
    expect(Message.count).to eq 0

    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_2,user2,User,Dos,user1@example.com,active"
    )
    user2.reload

    expect(Message.where(:communication_channel_id => user2.email_channel, :notification_id => notification).first).not_to be_nil
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
    user1 = Pseudonym.by_unique_id('user1').first.user
    expect([u1, u2]).not_to be_include(user1)
    expect(user1.communication_channels.length).to eq 1
    expect(user1.email).to eq 'user1@example.com'
    expect([cc1, cc2]).not_to be_include(user1.email_channel)
    expect(Message.where(:communication_channel_id => user1.email_channel, :notification_id => notification).first).to be_nil
  end

  it "should create everything in the deleted state when deleted initially" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,deleted"
    )
    p = Pseudonym.by_unique_id('user1').first
    expect(p).to be_deleted
    u = p.user
    expect(u.communication_channels.length).to eq 1
    expect(u.communication_channels.first).to be_retired
  end

  it "should not add a user with the same login id as another user" do
    importer = process_csv_data(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user1,User,Dos,user2@example.com,active"
    )
    expect(importer.errors).to eq []
    expect(importer.warnings.map{|x| x[1]}).to eq ["user user_1 has already claimed user_2's requested login information, skipping"]
    expect(Pseudonym.by_unique_id('user1').first).not_to be_nil
    expect(Pseudonym.by_unique_id('user2').first).to be_nil
  end

  it "should not present an error for the same login_id with different case for same user" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active",
        "user_1,USer1,User,Uno,user1@example.com,active"
    )
    expect(Pseudonym.where(sis_user_id: 'user_1').first.unique_id).to eq 'USer1'
  end

  it "should use an existing pseudonym if it wasn't imported from sis and has the same login id" do
    u = User.create!
    u.register!
    p_count = Pseudonym.count
    p = u.pseudonyms.create!(:unique_id => "user2", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
    expect(Pseudonym.by_unique_id('user1').first).to be_nil
    expect(Pseudonym.by_unique_id('user2').first).not_to be_nil
    expect(p.sis_user_id).to be_nil
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    p.reload
    expect(Pseudonym.by_unique_id('user1').first).not_to be_nil
    expect(Pseudonym.by_unique_id('user2').first).not_to be_nil
    expect(Pseudonym.count).to eq(p_count + 2)
    expect(p.sis_user_id).to eq "user_2"
  end

  it "should use an existing pseudonym if it wasn't imported from sis and has the same email address" do
    u = User.create!
    u.register!
    p_count = Pseudonym.count
    p = u.pseudonyms.create!(:unique_id => "user2@example.com", :password => "validpassword", :password_confirmation => "validpassword", :account => @account)
    expect(Pseudonym.by_unique_id('user1').first).to be_nil
    expect(Pseudonym.by_unique_id('user2').first).to be_nil
    expect(Pseudonym.by_unique_id('user2@example.com').first).not_to be_nil
    expect(p.sis_user_id).to be_nil
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    p.reload
    expect(Pseudonym.by_unique_id('user1').first).not_to be_nil
    expect(Pseudonym.by_unique_id('user2').first).not_to be_nil
    expect(Pseudonym.by_unique_id('user2@example.com').first).to be_nil
    expect(Pseudonym.count).to eq(p_count + 2)
    expect(p.sis_user_id).to eq "user_2"
  end

  it "should strip white space on fields" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,short_name,sortable_name,email,status",
      "user_1  ,user1   ,User   ,Uno   ,The Uno   ,\"Uno, User   \",user@example.com   ,active  ",
      "   user_2,   user2,   User,   Dos,   The Dos,\"   Dos, User\",   user2@example.com,  active"
    )
    user = CommunicationChannel.by_path('user@example.com').first.user
    expect(user).not_to be_nil
    expect(user.name).to eq "User Uno"
    expect(user.sortable_name).to eq "Uno, User"
    expect(user.short_name).to eq "The Uno"
    p = user.pseudonyms.first
    expect(p.unique_id).to eq "user1"
    user = CommunicationChannel.by_path('user2@example.com').first.user
    expect(user).not_to be_nil
    expect(user.name).to eq "User Dos"
    expect(user.sortable_name).to eq "Dos, User"
    expect(user.short_name).to eq "The Dos"
    p = user.pseudonyms.first
    expect(p.unique_id).to eq "user2"
  end

  it "should use an existing communication channel" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    p = Pseudonym.by_unique_id('user1').first
    user1 = p.user
    expect(user1.last_name).to eq "Uno"
    expect(user1.pseudonyms.count).to eq 1
    expect(p.communication_channel_id).not_to be_nil
    expect(user1.communication_channels.count).to eq 1
    expect(user1.communication_channels.first.path).to eq 'user1@example.com'
    expect(p.sis_communication_channel_id).to eq p.communication_channel_id
    user1.communication_channels.create!(:path => 'user2@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }

    # change to user2@example.com; because user1@example.com was sis created, it should disappear
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user2@example.com,active"
    )
    p.reload
    user1.reload
    expect(user1.pseudonyms.count).to eq 1
    expect(user1.communication_channels.count).to eq 2
    expect(user1.communication_channels.unretired.count).to eq 1
    expect(p.communication_channel_id).not_to be_nil
    expect(user1.communication_channels.unretired.first.path).to eq 'user2@example.com'
    expect(p.sis_communication_channel_id).to eq p.communication_channel_id
    expect(p.communication_channel_id).to eq user1.communication_channels.unretired.first.id
  end

  it "should work when a communication channel already exists, but there's no sis_communication_channel" do
    importer = process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,,active"
    )
    p = Pseudonym.by_unique_id('user1').first
    user1 = p.user
    expect(user1.last_name).to eq "Uno"
    expect(user1.pseudonyms.count).to eq 1
    expect(p.communication_channel_id).to be_nil
    expect(user1.communication_channels.count).to eq 0
    expect(p.sis_communication_channel_id).to be_nil
    user1.communication_channels.create!(:path => 'user2@example.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }

    importer = process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user2@example.com,active"
    )
    p.reload
    user1.reload
    expect(user1.pseudonyms.count).to eq 1
    expect(user1.communication_channels.count).to eq 1
    expect(user1.communication_channels.unretired.count).to eq 1
    expect(p.communication_channel_id).not_to be_nil
    expect(user1.communication_channels.unretired.first.path).to eq 'user2@example.com'
    expect(p.sis_communication_channel_id).to eq p.communication_channel_id
    expect(p.communication_channel_id).to eq user1.communication_channels.unretired.first.id
  end

  it "should handle stickiness" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,,active"
    )
    p = Pseudonym.by_unique_id('user1').first
    p.unique_id = 'user5'
    p.save!
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user3,User,Uno,,active"
    )
    p.reload
    expect(p.unique_id).to eq 'user5'
    expect(Pseudonym.by_unique_id('user1').first).to be_nil
    expect(Pseudonym.by_unique_id('user3').first).to be_nil
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user3,User,Uno,,active",
      {:override_sis_stickiness => true}
    )
    p.reload
    expect(p.unique_id).to eq 'user3'
    expect(Pseudonym.by_unique_id('user1').first).to be_nil
    expect(Pseudonym.by_unique_id('user5').first).to be_nil
  end

  it "should handle display name stickiness" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno,,active"
    )
    user = Pseudonym.by_unique_id('user1').first.user
    user.short_name = 'The Amazing Uno'
    user.save!
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno-Dos,,active"
    )
    user.reload
    expect(user.short_name).to eq 'The Amazing Uno'
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,short_name,email,status",
        "user_1,user1,User,Uno,The Uno-Dos,,active",
        {:override_sis_stickiness => true}
    )
    user.reload
    expect(user.short_name).to eq 'The Uno-Dos'
  end

  it "should handle full name stickiness" do
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,,active"
    )
    user = Pseudonym.by_unique_id('user1').first.user
    user.name = 'The Amazing Uno'
    user.save!
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,,active"
    )
    user.reload
    expect(user.name).to eq 'The Amazing Uno'
    process_csv_data_cleanly(
        "user_id,login_id,full_name,email,status",
        "user_1,user1,User Uno,,active",
        {:override_sis_stickiness => true}
    )
    user.reload
    expect(user.name).to eq 'User Uno'
  end

  it "should handle sortable name stickiness" do
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"One, User\",,active"
    )
    user = Pseudonym.by_unique_id('user1').first.user
    user.sortable_name = 'Uno, The Amazing'
    user.save!
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"Two, User\",,active"
    )
    user.reload
    expect(user.sortable_name).to eq 'Uno, The Amazing'
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,sortable_name,email,status",
        "user_1,user1,User,Uno,\"Two, User\",,active",
        {:override_sis_stickiness => true}
    )
    user.reload
    expect(user.sortable_name).to eq 'Two, User'
  end

  it 'should leave users around always' do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,deleted"
    )
    user1 = @account.pseudonyms.where(sis_user_id: 'user_1').first
    user2 = @account.pseudonyms.where(sis_user_id: 'user_2').first
    expect(user1.workflow_state).to eq 'active'
    expect(user2.workflow_state).to eq 'deleted'
    expect(user1.user.workflow_state).to eq 'registered'
    expect(user2.user.workflow_state).to eq 'registered'
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
    expect(@account.courses.where(sis_source_id: "test_1").first.teachers.map(&:name).include?("User Uno")).to be_truthy
    expect(@account.courses.where(sis_source_id: "test_2").first.students.map(&:name).include?("User Uno")).to be_truthy
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    expect(@account.courses.where(sis_source_id: "test_1").first.teachers.map(&:name).include?("User Uno")).to be_truthy
    expect(@account.courses.where(sis_source_id: "test_2").first.students.map(&:name).include?("User Uno")).to be_truthy
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,deleted"
    )
    expect(@account.courses.where(sis_source_id: "test_1").first.teachers.map(&:name).include?("User Uno")).to be_falsey
    expect(@account.courses.where(sis_source_id: "test_2").first.students.map(&:name).include?("User Uno")).to be_falsey
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    expect(@account.courses.where(sis_source_id: "test_1").first.teachers.map(&:name).include?("User Uno")).to be_falsey
    expect(@account.courses.where(sis_source_id: "test_2").first.students.map(&:name).include?("User Uno")).to be_falsey
    process_csv_data_cleanly(
      "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
      "test_1,user_1,teacher,,active,,,",
      ",user_1,student,S002,active,,,"
    )
    expect(@account.courses.where(sis_source_id: "test_1").first.teachers.map(&:name).include?("User Uno")).to be_truthy
    expect(@account.courses.where(sis_source_id: "test_2").first.students.map(&:name).include?("User Uno")).to be_truthy
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,active"
    )
    expect(@account.courses.where(sis_source_id: "test_1").first.teachers.map(&:name).include?("User Uno")).to be_truthy
    expect(@account.courses.where(sis_source_id: "test_2").first.students.map(&:name).include?("User Uno")).to be_truthy
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user@example.com,deleted"
    )
    expect(@account.courses.where(sis_source_id: "test_1").first.teachers.map(&:name).include?("User Uno")).to be_falsey
    expect(@account.courses.where(sis_source_id: "test_2").first.students.map(&:name).include?("User Uno")).to be_falsey
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
      user1 = @account.pseudonyms.where(sis_user_id: 'user_1').first
      user2 = @account.pseudonyms.where(sis_user_id: 'user_2').first
      expect(user1.user.user_account_associations.map { |uaa| [uaa.account_id, uaa.depth] }).to eq [[@account.id, 0]]
      expect(user2.user.user_account_associations).to be_empty

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted"
      )
      user1.reload
      expect(user1.user.user_account_associations).to be_empty
    end

    it 'should work when a user gets undeleted' do
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )
      user = @account.pseudonyms.where(sis_user_id: 'user_1').first
      expect(user.user.user_account_associations.map { |uaa| [uaa.account_id, uaa.depth] }).to eq [[@account.id, 0]]

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted"
      )
      user = @account.pseudonyms.where(sis_user_id: 'user_1').first
      expect(user.user.user_account_associations).to be_empty

      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active"
      )
      user = @account.pseudonyms.where(sis_user_id: 'user_1').first
      expect(user.user.user_account_associations.map { |uaa| [uaa.account_id, uaa.depth] }).to eq [[@account.id, 0]]
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
      expect(@account.pseudonyms.where(sis_user_id: 'user_1').first.user.user_account_associations.map { |uaa| uaa.account_id }).to eq [@account.id]
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
        "C001,user_1,teacher,,active,,,"
      )
      @pseudo1 = @account.pseudonyms.where(sis_user_id: 'user_1').first
      expect(@pseudo1.user.user_account_associations.map { |uaa| uaa.account_id }.sort).to eq [@account.id, Account.where(sis_source_id: 'A002').first.id, Account.where(sis_source_id: 'A001').first.id].sort

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
      expect(@account.pseudonyms.where(sis_user_id: 'user_1').first.user.user_account_associations.map { |uaa| uaa.account_id }).to eq [@account.id]
      process_csv_data_cleanly(
        "course_id,user_id,role,section_id,status,associated_user_id,start_date,end_date",
        "C001,user_1,teacher,,active,,,"
      )
      @pseudo2 = @account.pseudonyms.where(sis_user_id: 'user_1').first
      expect(@pseudo2.user.user_account_associations.map { |uaa| uaa.account_id }.sort).to eq [@account.id, Account.where(sis_source_id: 'A102').first.id, Account.where(sis_source_id: 'A101').first.id].sort

      UserMerge.from(@pseudo1.user).into(@pseudo2.user)
      @user = @account1.pseudonyms.where(sis_user_id: 'user_1').first.user
      expect(@account2.pseudonyms.where(sis_user_id: 'user_1').first.user).to eq @user

      expect(@user.user_account_associations.map { |uaa| uaa.account_id }.sort).to eq [@account1.id, @account2.id, Account.where(sis_source_id: 'A002').first.id, Account.where(sis_source_id: 'A001').first.id, Account.where(sis_source_id: 'A102').first.id, Account.where(sis_source_id: 'A101').first.id].sort

      @account = @account1
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,deleted")
      @account1.pseudonyms.where(sis_user_id: 'user_1').first.tap do |pseudo|
        expect(pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort).to eq [@account2.id, Account.where(sis_source_id: 'A102').first.id, Account.where(sis_source_id: 'A101').first.id].sort
        expect(pseudo.workflow_state).to eq 'deleted'
        expect(pseudo.user.workflow_state).to eq 'registered'
      end
      @account2.pseudonyms.where(sis_user_id: 'user_1').first.tap do |pseudo|
        expect(pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort).to eq [@account2.id, Account.where(sis_source_id: 'A102').first.id, Account.where(sis_source_id: 'A101').first.id].sort
        expect(pseudo.workflow_state).to eq 'active'
        expect(pseudo.user.workflow_state).to eq 'registered'
      end
      process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status",
        "user_1,user1,User,Uno,user1@example.com,active")
      @account1.pseudonyms.where(sis_user_id: 'user_1').first.tap do |pseudo|
        expect(pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort).to eq [@account2.id, Account.where(sis_source_id: 'A102').first.id, Account.where(sis_source_id: 'A101').first.id, @account1.id].sort
        expect(pseudo.workflow_state).to eq 'active'
        expect(pseudo.user.workflow_state).to eq 'registered'
      end
      @account2.pseudonyms.where(sis_user_id: 'user_1').first.tap do |pseudo|
        expect(pseudo.user.user_account_associations.map { |uaa| uaa.account_id }.sort).to eq [@account2.id, Account.where(sis_source_id: 'A102').first.id, Account.where(sis_source_id: 'A101').first.id, @account1.id].sort
        expect(pseudo.workflow_state).to eq 'active'
        expect(pseudo.user.workflow_state).to eq 'registered'
      end
    end
  end

  it "should not steal the communication channel of the previous user" do
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user_1 = Pseudonym.by_unique_id('user1').first.user
    expect(user_1.email).to eq 'user1@example.com'
    expect(user_1.pseudonym.sis_communication_channel).to eq user_1.email_channel
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active",
      "user_2,user2,User,Dos,user2@example.com,active"
    )
    user_1 = Pseudonym.by_unique_id('user1').first.user
    user_2 = Pseudonym.by_unique_id('user2').first.user
    expect(user_1.email).to eq 'user1@example.com'
    expect(user_2.email).to eq 'user2@example.com'
    expect(user_1.pseudonym.sis_communication_channel).to eq user_1.email_channel
    expect(user_2.pseudonym.sis_communication_channel).to eq user_2.email_channel
  end

  it "should not resurrect a non SIS user" do
    @non_sis_user = user_with_pseudonym(:active_all => 1)
    @non_sis_user.remove_from_root_account(Account.default)
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,#{@pseudonym.unique_id},User,Uno,#{@pseudonym.unique_id},active"
    )
    user_1 = Pseudonym.where(sis_user_id: 'user_1').first.user
    expect(user_1).not_to eq @non_sis_user
    expect(user_1.pseudonym).not_to eq @pseudonym
  end

  it "should not resurrect a non SIS pseudonym" do
    @non_sis_user = user_with_pseudonym(:active_all => 1)
    @pseudonym = @user.pseudonyms.create!(:unique_id => 'user1', :account => Account.default)
    process_csv_data_cleanly(
      "user_id,login_id,first_name,last_name,email,status",
      "user_1,user1,User,Uno,user1@example.com,active"
    )
    user_1 = Pseudonym.where(sis_user_id: 'user_1').first.user
    expect(user_1).not_to eq @non_sis_user
    expect(user_1.pseudonym).not_to eq @pseudonym
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
    expect(importer.errors).to eq []
    expect(importer.warnings.length).to eq 1
    expect(importer.warnings.last.last).to eq "user #{@non_sis_user.id} has already claimed user_1's requested login information, skipping"
  end

  it "sets authentication providers" do
    ap = @account.authentication_providers.create!(auth_type: 'google')
    process_csv_data_cleanly(
        "user_id,login_id,first_name,last_name,email,status,authentication_provider_id",
        "user_1,user1,User,Uno,user1@example.com,active,google"
    )
    p = @account.pseudonyms.active.where(sis_user_id: 'user_1').first
    expect(p.authentication_provider).to eq ap
  end

  it "warns on invalid authentication providers" do
    importer = process_csv_data(
        "user_id,login_id,first_name,last_name,email,status,authentication_provider_id",
        "user_1,user1,User,Uno,user1@example.com,active,google"
    )
    expect(importer.errors).to eq []
    expect(importer.warnings.length).to eq 1
    expect(importer.warnings.last.last).to eq "unrecognized authentication provider google for user_1, skipping"
    expect(@account.pseudonyms.active.where(sis_user_id: 'user_1').first).to eq nil
  end
end
