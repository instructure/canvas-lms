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

describe UserList do
  
  before(:each) do
    @account = Account.default
    @account.settings = { :open_registration => true }
    @account.save!
  end

  it "should complain about invalid addresses" do
    ul = UserList.new '@instructure'
    ul.errors.should == [{:address => '@instructure', :details => :unparseable}]
  end

  it "should find by SMS number" do
    user_with_pseudonym(:name => "JT", :active_all => 1)
    cc = @user.communication_channels.create!(:path => '8015555555@txt.att.net', :path_type => 'sms')
    cc.confirm!
    ul = UserList.new '(801) 555-5555'
    ul.addresses.should == [{:address => '(801) 555-5555', :type => :sms, :user_id => @user.id, :name => 'JT'}]
    ul.errors.should == []
    ul.duplicate_addresses.should == []

    ul = UserList.new '8015555555'
    ul.addresses.should == [{:address => '(801) 555-5555', :type => :sms, :user_id => @user.id, :name => 'JT'}]
    ul.errors.should == []
    ul.duplicate_addresses.should == []
  end

  it "should process a list of emails" do
    ul = UserList.new(regular)
    ul.addresses.map{|x| [x[:name], x[:address]]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com"],
        ["Last, First", "lastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
  end
  
  it "should process a list of only emails, without brackets" do
    ul = UserList.new without_brackets
    ul.addresses.map{|x| [x[:name], x[:address]]}.should eql([
        [nil, "ryankshaw@gmail.com"],
        [nil, "lastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
  end
  
  it "should work with a mixed entry list" do
    ul = UserList.new regular + "," + %{otherryankshaw@gmail.com, otherlastfirst@gmail.com}
    ul.addresses.map{|x| [x[:name], x[:address]]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com"],
        ["Last, First", "lastfirst@gmail.com"],
        [nil, "otherryankshaw@gmail.com"],
        [nil, "otherlastfirst@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
  end
  
  it "should work well with a single address" do
    ul = UserList.new('ryankshaw@gmail.com')
    ul.addresses.map{|x| [x[:name], x[:address]]}.should eql([
        [nil, "ryankshaw@gmail.com"]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
  end
  
  it "should remove duplicates" do
    user = User.create!(:name => 'A 123451')
    user.pseudonyms.create!(:unique_id => "A123451", :account => @account)
    user = User.create!(:name => 'user 3')
    user.pseudonyms.create!(:unique_id => "user3", :account => @account)
    ul = UserList.new regular + "," + without_brackets + ", A123451, user3, A123451, user3", @account
    ul.addresses.map{|x| [x[:name], x[:address], x[:type]]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com", :email],
        ["Last, First", "lastfirst@gmail.com", :email],
        ['A 123451', "A123451", :pseudonym],
        ['user 3', "user3", :pseudonym]])
    ul.errors.should == []
    ul.duplicate_addresses.map{|x| [x[:name], x[:address], x[:type]]}.should eql([
        [nil, "ryankshaw@gmail.com", :email],
        [nil, "lastfirst@gmail.com", :email],
        ['A 123451', "A123451", :pseudonym],
        ['user 3', "user3", :pseudonym]])

    ul = UserList.new regular + ",A123451 ,user3 ," + without_brackets + ", A123451, user3", @account
    ul.addresses.map{|x| [x[:name], x[:address], x[:type]]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com", :email],
        ["Last, First", "lastfirst@gmail.com", :email],
        ['A 123451', "A123451", :pseudonym],
        ['user 3', "user3", :pseudonym]])
    ul.errors.should == []
    ul.duplicate_addresses.map{|x| [x[:name], x[:address], x[:type]]}.should eql([
        [nil, "ryankshaw@gmail.com", :email],
        [nil, "lastfirst@gmail.com", :email],
        ['A 123451', "A123451", :pseudonym],
        ['user 3', "user3", :pseudonym]])
  end

  it "should be case insensitive when finding existing users" do
    @account.settings = { :open_registration => false }
    @account.save!

    user = User.create!(:name => 'user 3')
    user.pseudonyms.create!(:unique_id => "user3", :account => @account)
    user = User.create!(:name => 'user 4')
    user.pseudonyms.create!(:unique_id => "user4", :account => @account)
    user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }

    ul = UserList.new 'JT@INSTRUCTURE.COM, USER3', @account
    ul.addresses.map{|x| [x[:name], x[:address], x[:type]]}.should eql([
        ['user 4', 'jt@instructure.com', :email],
        ['user 3', 'user3', :pseudonym]])
    ul.errors.should == []
  end

  it "should be case insensitive when finding duplicates" do
    ul = UserList.new 'jt@instructure.com, JT@INSTRUCTURE.COM'
    ul.addresses.length.should == 1
    ul.duplicate_addresses.length.should == 1
  end
  
  it "should process login ids and email addresses" do
    user = User.create!(:name => 'A 112351243')
    user.pseudonyms.create!(:unique_id => "A112351243", :account => @account)
    user = User.create!(:name => 'user 1')
    user.pseudonyms.create!(:unique_id => "user1", :account => @account)
    ul = UserList.new regular + "," + %{user1,test@example.com,A112351243,"thomas walsh" <test2@example.com>, "walsh, thomas" <test3@example.com>}, @account
    ul.addresses.map{|x| [x[:name], x[:address], x[:type]]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com", :email],
        ["Last, First", "lastfirst@gmail.com", :email],
        ["user 1", "user1", :pseudonym],
        [nil, "test@example.com", :email],
        ["A 112351243", "A112351243", :pseudonym],
        ["thomas walsh", "test2@example.com", :email],
        ["walsh, thomas", "test3@example.com", :email]])
    ul.errors.should == []
    ul.duplicate_addresses.should == []
  end
  
  it "should not process login ids if they don't exist" do
    user = User.create!(:name => 'A 112351243')
    user.pseudonyms.create!(:unique_id => "A112351243", :account => @account)
    user = User.create!(:name => 'user 1')
    user.pseudonyms.create!(:unique_id => "user1", :account => @account)
    ul = UserList.new regular + "," + %{user1,test@example.com,A112351243,"thomas walsh" <test2@example.com>, "walsh, thomas" <test3@example.com>,A4513454}, @account
    ul.addresses.map{|x| [x[:name], x[:address], x[:type]]}.should eql([
        ["Shaw, Ryan", "ryankshaw@gmail.com", :email],
        ["Last, First", "lastfirst@gmail.com", :email],
        ['user 1', "user1", :pseudonym],
        [nil, "test@example.com", :email],
        ['A 112351243', "A112351243", :pseudonym],
        ["thomas walsh", "test2@example.com", :email],
        ["walsh, thomas", "test3@example.com", :email]])
    ul.errors.should == [{:address => "A4513454", :type => :pseudonym, :details => :not_found}]
    ul.duplicate_addresses.should == []
  end

  it "pseudonyms should take precedence over emails" do
    @user1 = user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => 1)
    @user2 = user_with_pseudonym(:name => 'Bob', :username => 'jt2@instructure.com', :active_all => 1)
    @user2.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
    ul = UserList.new 'jt@instructure.com'
    ul.addresses.should == [{:type => :pseudonym, :address => 'jt@instructure.com', :user_id => @user1.id, :name => 'JT'}]
    ul.duplicate_addresses.should == []
  end

  it "pseudonyms should take precedence over phone numbers" do
    @user1 = user_with_pseudonym(:name => 'JT', :username => '8015555555', :active_all => 1)
    @user2 = user_with_pseudonym(:name => 'Bob', :username => 'jt2@instructure.com', :active_all => 1)
    @user2.communication_channels.create!(:path => '8015555555@tmomail.net', :path_type => 'sms') { |cc| cc.workflow_state = 'active' }
    ul = UserList.new '8015555555'
    ul.addresses.should == [{:type => :pseudonym, :address => '8015555555', :user_id => @user1.id, :name => 'JT'}]
    ul.duplicate_addresses.should == []
  end

  it "should work with a list of paths" do
    ul = UserList.new(['leonard@example.com', 'sheldon@example.com'], @account, :preferred)
    ul.addresses.count.should == 2
    expect { ul.users }.to change(User, :count).by(2)
  end

  context "closed registration" do
    before(:each) do
      @account.settings = { :open_registration => false }
      @account.save!
    end

    it "should not return non-existing users if open registration is disabled" do
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == []
      ul.errors.length.should == 1
      ul.errors.first[:details].should == :not_found
    end

    it "should pick the pseudonym, even if someone else has the CC" do
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => 1)
      @user1 = @user
      user_with_pseudonym(:name => 'JT 1', :username => 'jt+1@instructure.com', :active_all => 1)
      @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :pseudonym, :user_id => @user1.id, :name => 'JT'}]
      ul.errors.should == []
      ul.duplicate_addresses.should == []
    end

    it "should complain if multiple people have the CC" do
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => true)
      @user.communication_channels.create!(:path => 'jt+2@instructure.com') { |cc| cc.workflow_state = 'active' }
      user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => true)
      @user.communication_channels.create!(:path => 'jt+2@instructure.com') { |cc| cc.workflow_state = 'active' }
      ul = UserList.new 'jt+2@instructure.com'
      ul.addresses.should == []
      ul.errors.should == [{:address => 'jt+2@instructure.com', :type => :email, :details => :non_unique }]
      ul.duplicate_addresses.should == []
    end

    it "should not think that multiple pseudonyms for the same user is multiple users" do
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
      @user.pseudonyms.create!(:unique_id => 'jt+2@instructure.com')
      @user.communication_channels.create!(:path => 'jt+3@instructure.com') { |cc| cc.workflow_state = 'active' }
      ul = UserList.new 'jt+3@instructure.com'
      ul.addresses.should == [{:address => 'jt+3@instructure.com', :type => :email, :user_id => @user.id, :name => 'JT'}]
      ul.errors.should == []
      ul.duplicate_addresses.should == []
    end

    it "should detect duplicates, even from different CCs" do
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => 1)
      cc = @user.communication_channels.create!(:path => '8015555555@txt.att.net', :path_type => 'sms')
      cc.confirm
      ul = UserList.new 'jt@instructure.com, (801) 555-5555'
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :pseudonym, :user_id => @user.id, :name => 'JT'}]
      ul.errors.should == []
      ul.duplicate_addresses.should == [{:address => '(801) 555-5555', :type => :sms, :user_id => @user.id, :name => 'JT'}]
    end

    it "should choose the active CC if there is 1 active and n unconfirmed" do
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
      @user.communication_channels.create!(:path => 'jt+2@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user1 = @user
      user_with_pseudonym(:name => 'JT 1', :username => 'jt+1@instructure.com', :active_all => true)
      @user.communication_channels.create!(:path => 'jt+2@instructure.com')
      ul = UserList.new 'jt+2@instructure.com'
      ul.addresses.should == [{:address => 'jt+2@instructure.com', :type => :email, :user_id => @user1.id, :name => 'JT' }]
      ul.errors.should == []
      ul.duplicate_addresses.should == []
    end

    # create the CCs in reverse order to check the logic when we see them in a different order
    it "should choose the active CC if there is 1 active and n unconfirmed, try 2" do
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
      @user.communication_channels.create!(:path => 'jt+2@instructure.com')
      @user1 = @user
      user_with_pseudonym(:name => 'JT 1', :username => 'jt+1@instructure.com', :active_all => true)
      @user.communication_channels.create!(:path => 'jt+2@instructure.com') { |cc| cc.workflow_state = 'active' }
      ul = UserList.new 'jt+2@instructure.com'
      ul.addresses.should == [{:address => 'jt+2@instructure.com', :type => :email, :user_id => @user.id, :name => 'JT 1' }]
      ul.errors.should == []
      ul.duplicate_addresses.should == []
    end

    it "should not find users from untrusted accounts" do
      Pseudonym.stubs(:trusted_by_including_self).with(Account.default).returns(Pseudonym.scoped({:conditions => {:account_id => Account.default.id}}))
      account = Account.create!
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account)
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == []
      ul.errors.should == [{:address => 'jt@instructure.com', :type => :email, :details => :not_found}]
    end

    it "should find users from trusted accounts" do
      Pseudonym.stubs(:trusted_by_including_self).with(Account.default).returns(Pseudonym.scoped({}))
      account = Account.create!
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account)
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :pseudonym, :user_id => @user.id, :name => 'JT'}]
      ul.errors.should == []
    end

    it "should prefer a user from the current account instead of a trusted account" do
      Pseudonym.stubs(:trusted_by_including_self).with(Account.default).returns(Pseudonym.scoped({}))
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
      @user1 = @user
      account = Account.create!
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account)
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :pseudonym, :user_id => @user1.id, :name => 'JT'}]
      ul.errors.should == []
    end

    it "should prefer a user from the current account instead of a trusted account (reverse order)" do
      Pseudonym.stubs(:trusted_by_including_self).with(Account.default).returns(Pseudonym.scoped({}))
      account = Account.create!
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account)
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true)
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :pseudonym, :user_id => @user.id, :name => 'JT'}]
      ul.errors.should == []
    end

    it "should not find a user if there is a conflict of unique_ids from not-this-account" do
      Pseudonym.stubs(:trusted_by_including_self).with(Account.default).returns(Pseudonym.scoped({}))
      account1 = Account.create!
      account2 = Account.create!
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account1)
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account2)
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == []
      ul.errors.should == [{:address => 'jt@instructure.com', :type => :pseudonym, :details => :non_unique}]
    end

    it "should find a user with multiple not-this-account pseudonyms" do
      Pseudonym.stubs(:trusted_by_including_self).with(Account.default).returns(Pseudonym.scoped({}))
      account1 = Account.create!
      account2 = Account.create!
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => true, :account => account1)
      @user.pseudonyms.create!(:unique_id => 'jt@instructure.com', :account => account2)
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :pseudonym, :user_id => @user.id, :name => 'JT'}]
      ul.errors.should == []
    end

    it "should not find a user from a different account by SMS" do
      Pseudonym.stubs(:trusted_by_including_self).with(Account.default).returns(Pseudonym.scoped({:conditions => {:account_id => Account.default.id}}))
      account = Account.create!
      user_with_pseudonym(:name => "JT", :active_all => 1, :account => account)
      cc = @user.communication_channels.create!(:path => '8015555555@txt.att.net', :path_type => 'sms')
      cc.confirm!
      ul = UserList.new '(801) 555-5555'
      ul.addresses.should == []
      ul.errors.should == [{:address => '(801) 555-5555', :type => :sms, :details => :not_found}]
      ul.duplicate_addresses.should == []
    end
  end

  context "preferred selection" do
    it "should find an existing user if there is only one" do
      user_with_pseudonym(:name => 'JT', :username => 'jt@instructure.com', :active_all => 1)
      @user.communication_channels.create!(:path => 'jt+2@instructure.com') { |cc| cc.workflow_state = 'active' }
      ul = UserList.new 'jt+2@instructure.com', nil, :preferred
      ul.addresses.should == [{:address => 'jt+2@instructure.com', :type => :email, :user_id => @user.id, :name => 'JT'}]
      ul.errors.should == []
      ul.duplicate_addresses.should == []
      ul.users.should == [@user]
    end

    it "should create a new user if none exists" do
      ul = UserList.new 'jt@instructure.com', nil, :preferred
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :email, :name => nil}]
      ul.errors.should == []
      ul.duplicate_addresses.should == []
    end

    it "should create a new user if multiple matching users are found" do
      @user1 = user_with_pseudonym(:name => 'JT', :username => 'jt+1@instructure.com')
      @user2 = user_with_pseudonym(:name => 'JT', :username => 'jt+2@instructure.com')
      @user1.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
      @user2.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
      ul = UserList.new 'jt@instructure.com', nil, :preferred
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :email, :details => :non_unique}]
      ul.errors.should == []
      ul.duplicate_addresses.should == []
      users = ul.users
      users.length.should == 1
      users.first.should_not == @user1
      users.first.should_not == @user2
    end

    it "should not create a new user for non-matching non-email" do
      ul = UserList.new 'jt', nil, :preferred
      ul.addresses.should == []
      ul.errors.should == [{:address => 'jt', :type => :pseudonym, :details => :not_found}]
      ul.duplicate_addresses.should == []
    end
  end

  context "user creation" do
    it "should create new users in creation_pending state" do
      ul = UserList.new 'jt@instructure.com'
      ul.addresses.length.should == 1
      ul.addresses.first[:user_id].should be_nil
      users = ul.users
      users.length.should == 1
      user = users.first
      user.should be_creation_pending
      user.pseudonyms.should be_empty
      user.communication_channels.length.should == 1
      cc = user.communication_channels.first
      cc.path_type.should == 'email'
      cc.should be_unconfirmed
      cc.path.should == 'jt@instructure.com'
    end

    it "should create new users even if a user already exists" do
      user_with_pseudonym(:name => 'JT', :username => 'jt+1@instructure.com', :active_all => 1)
      @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
      ul = UserList.new 'Bob <jt@instructure.com>'
      ul.addresses.should == [{:address => 'jt@instructure.com', :type => :email, :name => 'Bob'}]
      users = ul.users
      users.length.should == 1
      user = users.first
      user.should_not == @user
      user.should be_creation_pending
      user.pseudonyms.should be_empty
      user.communication_channels.length.should == 1
      cc = user.communication_channels.first
      cc.path_type.should == 'email'
      cc.should be_unconfirmed
      cc.path.should == 'jt@instructure.com'
      cc.should_not == @cc
    end

    it "should not create new users for users found by email" do
      user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
      @pseudonym.update_attribute(:unique_id, 'jt')
      ul = UserList.new 'jt@instructure.com', Account.default, :closed
      ul.addresses.length.should == 1
      ul.addresses.first[:user_id].should == @user.id
      ul.addresses.first[:type].should == :email
      ul.users.should == [@user]
    end
  end
end

def regular
  %{"Shaw, Ryan" <ryankshaw@gmail.com>, "Last, First" <lastfirst@gmail.com>}
end

def without_brackets
  %{ryankshaw@gmail.com, lastfirst@gmail.com}
end
