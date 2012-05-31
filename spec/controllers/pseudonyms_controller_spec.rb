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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe PseudonymsController do

  describe "password changing" do
    it "should change the password if authorized" do
      user_with_pseudonym
      pword = @pseudonym.crypted_password
      code = @cc.confirmation_code
      post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code, :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
      response.should be_redirect
      assigns[:pseudonym].should eql(@pseudonym)
      assigns[:pseudonym].crypted_password.should_not eql(pword)
      assigns[:pseudonym].user.should be_registered
      assigns[:cc].confirmation_code.should_not eql(code)
      assigns[:cc].should be_active
    end

    it "should not change the password if unauthorized" do
      user_with_pseudonym
      pword = @pseudonym.crypted_password
      code = @cc.confirmation_code
      post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code + 'a', :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
      response.should be_redirect
      assigns[:pseudonym].should eql(@pseudonym)
      assigns[:pseudonym].crypted_password.should eql(pword)
      assigns[:pseudonym].user.should_not be_registered
      @cc.reload
      @cc.confirmation_code.should eql(code)
      @cc.should_not be_active
    end

    describe "forgot password" do
      before :each do
        Notification.create(:name => 'Forgot Password')
      end

      it "should send password-change email for a registered user" do
        user_with_pseudonym
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => @pseudonym.unique_id}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end

      it "should use case insensitive match for CommunicationChannel email" do
        # Setup user with communication channel that has mixed case email
        user_with_pseudonym
        @cc = communication_channel_model(:user_id => @user.id, :workflow_state => 'active', :path => 'Victoria.Silvstedt@example.com')
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => 'victoria.silvstedt@example.com'}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end
      it "should send password-change email case insensitively" do
        user_with_pseudonym(:username => 'user1@example.com')
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => 'USER1@EXAMPLE.COM'}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end

      it "should send password-change email for users with pseudonyms in a different account" do
        user_with_pseudonym(:account => Account.site_admin)
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => @pseudonym.unique_id}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end
    end

    it "should render confirm change password view for registered user's email" do
      user_with_pseudonym(:active_user => true)
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_success
    end

    it "should not render confirm change password view for non-email channels" do
      user_with_pseudonym(:active_user => true)
      @cc.update_attributes(:path_type => 'sms')
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_redirect
    end

    it "should render confirm change password view for unregistered user" do
      user_with_pseudonym
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_success
    end
  end

  describe "destroy" do
    it "should not destroy if for the wrong user" do
      rescue_action_in_public!
      user_model
      @other_user = @user
      @other_pseudonym = @user.pseudonyms.create!(:unique_id => "test@test.com", :password => "password", :password_confirmation => "password")
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      delete 'destroy', :user_id => @user.id, :id => @other_pseudonym.id
      assert_status(404)
      @other_pseudonym.should be_active
      @pseudonym.should be_active

      delete 'destroy', :user_id => @other_user.id, :id => @pseudonym.id
      assert_unauthorized
      @other_pseudonym.should be_active
      @pseudonym.should be_active
    end
    
    it "should not destroy if it's the last active pseudonym" do
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      delete 'destroy', :user_id => @user.id, :id => @pseudonym.id
      assert_status(400)
      @pseudonym.should be_active
    end

    it "should not destroy if it's SIS and the user doesn't have permission" do
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      @pseudonym.sis_user_id = 'bob'
      @pseudonym.save!
      delete 'destroy', :user_id => @user.id, :id => @pseudonym.id
      assert_status(400)
      @pseudonym.should be_active
    end
    
    it "should destroy if for the current user with more than one pseudonym" do
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      @p2 = @user.pseudonyms.create!(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(200)
      @pseudonym.should be_active
      @p2.reload.should be_deleted
    end
    
    it "should not destroy if for the current user and it's a system-generated pseudonym" do
      rescue_action_in_public!
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      @p2 = @user.pseudonyms.create!(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      @p2.sis_user_id = 'another_one@test.com'
      @p2.save!
      @p2.account.account_authorization_configs.create!(:auth_type => 'ldap')
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(401)
      @pseudonym.should be_active
      @p2.should be_active
    end
    
    it "should destroy if authorized to delete pseudonyms" do
      rescue_action_in_public!
      user_with_pseudonym(:active_all => true)
      Account.site_admin.add_user(@user)
      user_session(@user, @pseudonym)
      @p2 = @user.pseudonyms.build(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      @p2.sis_user_id = 'another_one@test.com'
      @p2.save!
      @p2.account.account_authorization_configs.create!(:auth_type => 'ldap')
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(200)
      @pseudonym.should be_active
      @p2.should be_active
    end
  end

  describe "create" do
    # these specs only test the non-api version of the calls
    context "with site admin permissions" do
      before :each do
        user_with_pseudonym(:active_all => true)
        Account.site_admin.add_user(@user)
        user_session(@user, @pseudonym)
      end

      it "should use the account id from params" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :account_id => Account.site_admin.id, :unique_id => 'unique1' }
        response.should be_success
      end
    end

    context "without site admin permissions" do
      before :each do
        @account = Account.create!
        user_with_pseudonym(:active_all => true, :account => @account)
        LoadAccount.stubs(:default_domain_root_account).returns(@account)
        @account.add_user(@user)
        user_session(@user, @pseudonym)
      end

      it "should ignore use the domain_root_account" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :unique_id => 'unique1' }
        response.should be_success
        @user.pseudonyms.size.should == 2
        (@user.pseudonyms - [@pseudonym]).last.account.should == @account
      end

      it "should ignore account id in params and use the domain_root_account" do
        @account2 = Account.create!
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :account_id => @account2.id, :unique_id => 'unique1' }
        response.should be_success
        @user.pseudonyms.size.should == 2
        (@user.pseudonyms - [@pseudonym]).last.account.should == @account
      end
    end
  end

  describe "update" do
    it "should change a password if authorized" do
      account = Account.default
      user_with_pseudonym(
        :username => 'test2@example.com',
        :password => 'old_password',
        :account  => account)
      @test_user = @user
      user_with_pseudonym(
        :username => 'admin@example.com',
        :password => 'admin-password',
        :account  => account)
      account.settings[:admins_can_change_passwords] = true
      account.save!
      Account.site_admin.add_user(@user)
      user_session(@user, @pseudonym)
      put 'update', {
        :id        => @test_user.pseudonym.id,
        :user_id   => @test_user.id,
        :pseudonym => {
          :password              => 'new_password',
          :password_confirmation => 'new_password'
        }}
      response.should be_redirect
      @test_user.pseudonym.reload
      @test_user.pseudonym.valid_password?('new_password').should be_true
    end

    it "should not change a password if not authorized" do
      account1 = Account.new
      account1.settings[:admins_can_change_passwords] = true
      account1.save!
      user_with_pseudonym(:active_all => 1, :username => 'user@example.com', :password => 'qwerty1', :account => account1)
      @user1 = @user
      @pseudonym1 = @pseudonym
      # need to get the user associated with the default account as well
      @user.pseudonyms.create!(:unique_id => 'user1@example.com', :account => Account.default)

      user_with_pseudonym(:active_all => 1, :username => 'user2@example.com', :password => 'qwerty2')
      Account.default.add_user(@user)
      user_session(@user, @pseudonym)
      # not logged in!

      post 'update', :format => 'json', :id => @pseudonym1.id, :user_id => @user1.id, :pseudonym => { :password => 'bobbob', :password_confirmation => 'bobbob' }
      response.should be_success
      @pseudonym1.reload
      @pseudonym1.valid_password?('qwerty1').should be_true
      @pseudonym1.valid_password?('bobob').should be_false
    end
  end
end
