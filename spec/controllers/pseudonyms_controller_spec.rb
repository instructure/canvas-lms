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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe PseudonymsController do

  describe "password changing" do
    before :once do
      user_with_pseudonym
    end

    context "unconfirmed communication channel" do
      it "should change the password if authorized" do
        pword = @pseudonym.crypted_password
        code = @cc.confirmation_code
        post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code, :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
        response.should be_success
        assigns[:pseudonym].should eql(@pseudonym)
        @pseudonym.reload
        @pseudonym.crypted_password.should_not eql(pword)
        @pseudonym.user.should be_registered
        @cc.reload
        @cc.confirmation_code.should_not eql(code)
        @cc.should be_active
      end
    end

    context "active communication channel" do
      it "should change the password if authorized" do
        @cc.confirm
        @cc.reload
        @cc.should be_active
        pword = @pseudonym.crypted_password
        code = @cc.confirmation_code
        post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code, :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
        response.should be_success
        assigns[:pseudonym].should eql(@pseudonym)
        @pseudonym.reload
        @pseudonym.crypted_password.should_not eql(pword)
        @pseudonym.user.should be_registered
        @cc.reload
        @cc.confirmation_code.should_not eql(code)
        @cc.should be_active
      end
    end

    it "should not change the password if unauthorized" do
      pword = @pseudonym.crypted_password
      code = @cc.confirmation_code
      post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code + 'a', :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
      assert_status(400)
      assigns[:pseudonym].should eql(@pseudonym)
      assigns[:pseudonym].crypted_password.should eql(pword)
      assigns[:pseudonym].user.should_not be_registered
      @cc.reload
      @cc.confirmation_code.should eql(code)
      @cc.should_not be_active
    end

    describe "forgot password" do
      before :once do
        Notification.create(:name => 'Forgot Password')
        user
      end

      it "should send password-change email for a registered user" do
        pseudonym(@user)
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => @pseudonym.unique_id}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end

      it "should use case insensitive match for CommunicationChannel email" do
        # Setup user with communication channel that has mixed case email
        pseudonym(@user)
        @cc = communication_channel_model(:workflow_state => 'active', :path => 'Victoria.Silvstedt@example.com')
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => 'victoria.silvstedt@example.com'}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end
      it "should send password-change email case insensitively" do
        pseudonym(@user, :username => 'user1@example.com')
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => 'USER1@EXAMPLE.COM'}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end

      it "should send password-change email for users with pseudonyms in a different account" do
        pseudonym(@user, :account => Account.site_admin)
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => @pseudonym.unique_id}
        response.should be_redirect
        assigns[:ccs].should include(@cc)
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
        assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_empty
      end
    end

    it "should render confirm change password view for registered user's email" do
      @user.register
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_success
    end

    it "should not render confirm change password view for non-email channels" do
      @user.register
      @cc.update_attributes(:path_type => 'sms')
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_redirect
    end

    it "should render confirm change password view for unregistered user" do
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_success
    end
  end

  describe "destroy" do
    before :once do
      user_with_pseudonym(:active_all => true)
    end

    before :each do
      user_session(@user, @pseudonym)
    end

    it "should not destroy if for the wrong user" do
      @main_user = @user
      user_model
      @other_user = @user
      @other_pseudonym = @user.pseudonyms.create!(:unique_id => "test@test.com", :password => "password", :password_confirmation => "password")
      delete 'destroy', :user_id => @main_user.id, :id => @other_pseudonym.id
      assert_status(404)
      @other_pseudonym.should be_active
      @pseudonym.should be_active

      delete 'destroy', :user_id => @other_user.id, :id => @pseudonym.id
      assert_unauthorized
      @other_pseudonym.should be_active
      @pseudonym.should be_active
    end

    it "should not destroy if it's the last active pseudonym" do
      delete 'destroy', :user_id => @user.id, :id => @pseudonym.id
      assert_status(400)
      @pseudonym.should be_active
    end

    it "should not destroy if it's SIS and the user doesn't have permission" do
      @pseudonym.sis_user_id = 'bob'
      @pseudonym.save!
      delete 'destroy', :user_id => @user.id, :id => @pseudonym.id
      assert_status(400)
      @pseudonym.should be_active
    end

    it "should destroy if for the current user with more than one pseudonym" do
      @p2 = @user.pseudonyms.create!(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(200)
      @pseudonym.should be_active
      @p2.reload.should be_deleted
    end

    it "should not destroy if for the current user and it's a system-generated pseudonym" do
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
      Account.site_admin.account_users.create!(user: @user)
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
        Account.site_admin.account_users.create!(user: @user)
        user_session(@user, @pseudonym)
      end

      it "should use the account id from params" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :account_id => Account.site_admin.id, :unique_id => 'unique1' }
        response.should be_success
      end
    end

    context 'with default admin permissions' do
      before :once do
        user_with_pseudonym(:active_all => true)
        Account.default.account_users.create!(user: @user)
      end

      before :each do
        user_session(@user, @pseudonym)
      end

      it 'lets user create pseudonym for self' do
        post 'create', :user_id => @user.id, :pseudonym => { :account_id => Account.default.id, :unique_id => 'a_new_unique_name' }
        response.should be_redirect
        @user.reload.pseudonyms.map(&:unique_id).should include('a_new_unique_name')
      end

      it 'will not allow default admin to create pseudonym for site admin' do
        siteadmin = User.create!(:name => 'siteadmin')
        Account.site_admin.account_users.create!(user: siteadmin)
        Account.default.account_users.create!(user: siteadmin)
        post 'create', :user_id => siteadmin.id, :pseudonym => { :account_id => Account.site_admin.id, :unique_id => 'a_new_unique_name' }
        assert_unauthorized
      end

      it 'will not allow default admin to create pseudonym in another account' do
        user2 = User.create!
        Account.default.pseudonyms.create!(unique_id: 'user', user: user2)
        account2 = Account.create!

        LoadAccount.stubs(:default_domain_root_account).returns(account2)
        post 'create', user_id: user2.id, pseudonym: { unique_id: 'user' }
        assert_unauthorized
      end

      it 'will not allow default admin to create pseudonym in site admin' do
        user2 = User.create!
        Account.default.pseudonyms.create!(unique_id: 'user', user: user2)
        Account.site_admin.account_users.create!(user: user2)

        LoadAccount.stubs(:default_domain_root_account).returns(Account.site_admin)
        post 'create', user_id: user2.id, pseudonym: { unique_id: 'user' }
        assert_unauthorized
      end

      it 'will not allow admin to add pseudonyms to unrelated users' do
        user2 = User.create!
        post 'create', user_id: user2.id, pseudonym: { unique_id: 'user' }
        assert_unauthorized
      end
    end

    context "without site admin permissions" do
      before :once do
        @account = Account.create!
        user_with_pseudonym(:active_all => true, :account => @account)
        @account.account_users.create!(user: @user)
      end

      before :each do
        LoadAccount.stubs(:default_domain_root_account).returns(@account)
        user_session(@user, @pseudonym)
      end

      it "should use the domain_root_account" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :unique_id => 'unique1' }
        response.should be_success
        @user.pseudonyms.size.should == 2
        (@user.pseudonyms - [@pseudonym]).last.account.should == @account
      end

      it "should allow explicit account id in params as long as they have permission" do
        @account2 = Account.create!
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :account_id => @account.id, :unique_id => 'unique1' }
        response.should be_success
        @user.pseudonyms.size.should == 2
        (@user.pseudonyms - [@pseudonym]).last.account.should == @account
      end

      it "should raise permission error if no permission on explict account id in params" do
        @account2 = Account.create!
        post 'create', :user_id => @user.id, :pseudonym => { :account_id => @account2.id, :unique_id => 'unique1' }
        assert_unauthorized
      end
    end

    it "should not allow user to add their own pseudonym to an arbitrary account" do
      user_with_pseudonym(active_all: true)
      account2 = Account.create!
      user_session(@user, @pseudonym)
      post 'create', user_id: @user.id, pseudonym: { account_id: account2.id, unique_id: 'user' }
      assert_unauthorized
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
      Account.site_admin.account_users.create!(user: @user)
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
      Account.default.account_users.create!(user: @user)
      user_session(@user, @pseudonym)
      # not logged in!

      post 'update', :format => 'json', :id => @pseudonym1.id, :user_id => @user1.id, :pseudonym => { :password => 'bobbob', :password_confirmation => 'bobbob' }
      response.should_not be_success
      @pseudonym1.reload
      @pseudonym1.valid_password?('qwerty1').should be_true
      @pseudonym1.valid_password?('bobob').should be_false
    end
  end

  context "sharding" do
    specs_require_sharding

    before :once do
      user_with_pseudonym(:active_all => 1)
      @admin = @user
      @admin_pseudonym = @pseudonym
      Account.site_admin.account_users.create!(user: @admin)

      @shard1.activate do
        @account = Account.create!
        user_with_pseudonym(:active_all => 1, :account => @account)
      end
    end

    before :each do
      user_session(@admin, @admin_pseudonym)
    end

    describe 'index' do
      it "should list pseudonyms from all shards" do
        @p1 = @pseudonym
        @p2 = Account.default.pseudonyms.create!(:user => @user, :unique_id => @p1.unique_id)

        get 'index', :format => 'json', :user_id => @user.id
        response.should be_success
        assigns['pseudonyms'].should == [@p1, @p2]
      end
    end

    describe 'create' do
      it "should create a new pseudonym for a user in a different shard (cross-shard)" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :password => 'bobobob', :password_confirmation => 'bobobob', :account_id => Account.default.id, :unique_id => 'bobob' }
        response.should be_success

        @user.reload
        @user.all_pseudonyms.length.should == 2
        @user.all_pseudonyms.map(&:shard).should == [@shard1, Shard.default]
      end

      it "should create a new pseudonym for a user in a different shard (same-shard)" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :password => 'bobobob', :password_confirmation => 'bobobob', :account_id => @account.id, :unique_id => 'bobob' }
        response.should be_success

        @user.all_pseudonyms.length.should == 2
        @user.all_pseudonyms.map(&:shard).should == [@shard1, @shard1]
      end
    end

    describe 'update' do
      it "should update a pseudonym on another shard" do
        post 'update', :format => 'json', :user_id => @user.id, :id => @pseudonym.id, :pseudonym => { :unique_id => 'yoyoyo' }
        response.should be_success

        @pseudonym.reload.unique_id.should == 'yoyoyo'
      end

      it "should update a pseudonym on the requesting shard for a user from another shard" do
        @pseudonym = Account.default.pseudonyms.create!(:user => @user, :unique_id => 'bobob')
        post 'update', :format => 'json', :user_id => @user.id, :id => @pseudonym.id, :pseudonym => { :unique_id => 'yoyoyo' }
        response.should be_success

        @pseudonym.reload.unique_id.should == 'yoyoyo'
      end
    end

    describe 'destroy' do
      it "should destroy a pseudonym on another shard" do
        @pseudonym = @account.pseudonyms.create!(:user => @user, :unique_id => 'bobob')
        post 'destroy', :format => 'json', :user_id => @user.id, :id => @pseudonym.id
        response.should be_success

        @pseudonym.reload.should be_deleted
      end

      it "should destroy a pseudonym on the requesting shard for a user from another shard" do
        @pseudonym = Account.default.pseudonyms.create!(:user => @user, :unique_id => 'bobob')
        post 'destroy', :format => 'json', :user_id => @user.id, :id => @pseudonym.id
        response.should be_success

        @pseudonym.reload.should be_deleted
      end
    end
  end
end
