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

describe Pseudonym do

  it "should create a new instance given valid attributes" do
    user_model
    factory_with_protected_attributes(Pseudonym, valid_pseudonym_attributes)
  end

  it "should allow single character usernames" do
    user_model
    pseudonym_model
    @pseudonym.unique_id = 'c'
    @pseudonym.save!
  end

  it "should validate the presence of user and account ids" do
    p = Pseudonym.new(:unique_id => 'cody@instructure.com')
    p.save.should be_false

    p.account_id = 1
    p.save.should be_false

    p.user_id = 1
    p.account_id = nil
    p.save.should be_false

    p.account_id = 1
    p.save.should be_true

    # make sure a password was generated
    p.password.should_not be_nil
    p.password.should_not match /tmp-pw/
  end

  it "should not allow active duplicates" do
    u = User.create!
    p1 = Pseudonym.create!(:unique_id => 'cody@instructure.com', :user => u)
    p2 = Pseudonym.create(:unique_id => 'cody@instructure.com', :user => u)
    # Failed; p1 is still active
    p2.should be_new_record
    p2.workflow_state = 'deleted'
    p2.save!
    # Duplicates okay in the deleted state
    p1.workflow_state = 'deleted'
    p1.save!
    # Should allow creating a new active one if the others are deleted
    Pseudonym.create!(:unique_id => 'cody@instructure.com', :user => u)
  end
  
  it "should find the correct pseudonym for logins" do
    user = User.create!
    p1 = Pseudonym.create!(:unique_id => 'Cody@instructure.com', :user => user)
    p2 = Pseudonym.create!(:unique_id => 'codY@instructure.com', :user => user) { |p| p.workflow_state = 'deleted' }
    Pseudonym.custom_find_by_unique_id('cody@instructure.com').should == p1
    account = Account.create!
    p3 = Pseudonym.create!(:unique_id => 'cOdy@instructure.com', :account => account, :user => user)
    Pseudonym.custom_find_by_unique_id('cody@instructure.com', :all).sort.should == [p1, p3]
  end

  it "should associate to another user" do
    user_model
    pseudonym_model
    @pseudonym.user.should eql(@user)
  end
  
  it "should order by position" do
    user_model
    p1 = pseudonym_model(:user_id => @user.id)
    p2 = pseudonym_model(:user_id => @user.id)
    p3 = pseudonym_model(:user_id => @user.id)
    p1.move_to_bottom
    p3.move_to_top
    Pseudonym.all.sort.map(&:id).should eql([p3.id, p2.id, p1.id])
  end
  
  it "should update user account associations on CRUD" do
    account_model
    user_model
    account1 = account_model
    account2 = account_model
    @user.user_account_associations.length.should eql(0)
    
    pseudonym_model(:user => @user, :account => account1)
    @user.reload
    @user.user_account_associations.length.should eql(1)
    @user.user_account_associations.first.account.should eql(account1)
    
    account2 = account_model
    @pseudonym.account = account2
    @pseudonym.save
    @user.reload
    @user.user_account_associations.length.should eql(1)
    @user.user_account_associations.first.account.should eql(account2)

    @pseudonym.destroy
    @user.reload
    @user.user_account_associations.should == []
  end
  
  it "should allow deleting pseudonyms" do
    user_with_pseudonym(:active_all => true)
    @pseudonym.destroy(true).should eql(true)
    @pseudonym.should be_deleted
  end
  
  it "should not allow deleting system-generated pseudonyms by default" do
    user_with_pseudonym(:active_all => true)
    @pseudonym.sis_user_id = 'something_cool'
    @pseudonym.save!
    @pseudonym.account.account_authorization_configs.create!(:auth_type => 'ldap')
    lambda{ @pseudonym.destroy}.should raise_error("Cannot delete system-generated pseudonyms")
    @pseudonym.should_not be_deleted
  end
  
  it "should not allow deleting system-generated pseudonyms by default" do
    user_with_pseudonym(:active_all => true)
    @pseudonym.sis_user_id = 'something_cool'
    @pseudonym.save!
    @pseudonym.destroy(true).should eql(true)
    @pseudonym.should be_deleted
  end

  it "should change a blank sis_user_id to nil" do
    user
    pseudonym = Pseudonym.new(:user => @user, :unique_id => 'test@example.com', :password => 'pwd123')
    pseudonym.password_confirmation = 'pwd123'
    pseudonym.sis_user_id = ''
    pseudonym.should be_valid
    pseudonym.sis_user_id.should be_nil
  end

  context "LDAP errors" do
    before do
      require 'net/ldap'
      user_with_pseudonym(:active_all => true)
      @aac = @pseudonym.account.account_authorization_configs.create!(
        :auth_type      => 'ldap',
        :auth_base      => "ou=people,dc=example,dc=com",
        :auth_host      => "ldap.example.com",
        :auth_username  => "cn=query,dc=example,dc=com",
        :auth_port      => 636,
        :auth_filter    => "(uid={{login}})",
        :auth_over_tls  => true
      )
    end

    it "should gracefully handle unreachable LDAP servers" do
      Net::LDAP.any_instance.expects(:bind_as).raises(Net::LDAP::LdapError, "no connection to server")
      lambda{ @pseudonym.ldap_bind_result('blech') }.should_not raise_error
      ErrorReport.last.message.should eql("no connection to server")
      Net::LDAP.any_instance.expects(:bind_as).returns(true)
      @pseudonym.ldap_bind_result('yay!').should be_true
    end

    it "should set last_timeout_failure on LDAP servers that timeout" do
      Net::LDAP.any_instance.expects(:bind_as).once.raises(Timeout::Error, "timed out")
      @pseudonym.ldap_bind_result('test').should be_false
      ErrorReport.last.message.should match /Timeout::Error|timed out/ # 1.8/1.9 compat
      @aac.reload.last_timeout_failure.should > 1.minute.ago
    end

    it "should not attempt to bind if last_timeout_failure is set recently" do
      # calling again should not attempt to bind
      @aac.update_attribute(:last_timeout_failure, 5.seconds.ago)
      Net::LDAP.any_instance.expects(:bind_as).never
      @pseudonym.ldap_bind_result('test').should be_false

      # updating the config should reset :last_timeout_failure
      @aac.reload.update_attributes(:auth_port => 637)
      @aac.last_timeout_failure.should be_nil
      Net::LDAP.any_instance.expects(:bind_as).returns(true)
      @pseudonym.ldap_bind_result('test').should be_true
    end

    it "should allow another attempt once last_timeout_failure is sufficiently in the past" do
      @aac.update_attribute(:last_timeout_failure, 5.seconds.ago)
      Setting.set('ldap_failure_wait_time', 2.seconds)
      Net::LDAP.any_instance.expects(:bind_as).returns(true)
      @pseudonym.ldap_bind_result('test').should be_true
    end
  end

  it "should not error on malformed SSHA password" do
    pseudonym_model
    @pseudonym.sis_ssha = '{SSHA}garbage'
    @pseudonym.valid_ssha?('garbage').should be_false
  end
  
  context "Needs a pseudonym with an active user" do
    before do
      user_model
      pseudonym_model
    end
    
    it "should offer login as the unique id" do
      @pseudonym.login.should eql(@pseudonym.unique_id)
    end

    it "should be able to set the login" do
      @pseudonym.login = 'another'
      @pseudonym.login.should eql('another')
      @pseudonym.unique_id.should eql('another')
    end

    it "should know if the login changed" do
      @pseudonym.login = 'another'
      @pseudonym.login_changed?.should be_true
    end

    it "should offer the user code as the user's uuid" do
      @pseudonym.user.should eql(@user)
      @pseudonym.user_code.should eql(@user.uuid)
    end

    it "should be able to change the user email" do
      @pseudonym.email = 'admin@example.com'
      @pseudonym.reload
      @pseudonym.user.email_channel.path.should eql('admin@example.com')
    end
    
    it "should offer the user sms if there is one" do
      communication_channel_model(:path_type => 'sms', :user_id => @user.id)
      @user.communication_channels << @cc
      @user.save!
      @user.sms.should eql(@cc.path)
      @pseudonym.sms.should eql(@user.sms)
    end

    it "should be able to change the user sms" do
      communication_channel_model(:path_type => 'sms', :user_id => @user.id, :path => 'admin@example.com')
      @pseudonym.sms = @cc
      @pseudonym.sms.should eql('admin@example.com')
      @pseudonym.user.sms.should eql('admin@example.com')
    end
  end
  
  it "should determine if the password is managed" do
    u = User.create!
    p = Pseudonym.create!(:unique_id => 'jt@instructure.com', :user => u)
    p.sis_user_id = 'jt'
    p.should_not be_managed_password
    p.account.account_authorization_configs.create!(:auth_type => 'ldap')
    p.should be_managed_password
    p.sis_user_id = nil
    p.should_not be_managed_password
  end

  context "login assertions" do
    it "should create a CC if LDAP gave an e-mail we don't have" do
      account = Account.create!
      account.account_authorization_configs.create!(:auth_type => 'ldap')
      u = User.create!
      u.register
      p = u.pseudonyms.create!(:unique_id => 'jt', :account => account) { |p| p.sis_user_id = 'jt' }
      p.instance_variable_set(:@ldap_result, {:mail => ['jt@instructure.com']})

      p.add_ldap_channel
      u.reload
      u.communication_channels.length.should == 1
      u.email_channel.path.should == 'jt@instructure.com'
      u.email_channel.should be_active
      u.email_channel.destroy

      p.add_ldap_channel
      u.reload
      u.communication_channels.length.should == 1
      u.email_channel.path.should == 'jt@instructure.com'
      u.email_channel.should be_active
      u.email_channel.update_attribute(:workflow_state, 'unconfirmed')

      p.add_ldap_channel
      u.reload
      u.communication_channels.length.should == 1
      u.email_channel.path.should == 'jt@instructure.com'
      u.email_channel.should be_active
    end
  end
end

