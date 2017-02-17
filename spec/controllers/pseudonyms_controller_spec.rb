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
        expect(response).to be_success
        expect(assigns[:pseudonym]).to eql(@pseudonym)
        @pseudonym.reload
        expect(@pseudonym.crypted_password).not_to eql(pword)
        expect(@pseudonym.user).to be_registered
        @cc.reload
        expect(@cc.confirmation_code).not_to eql(code)
        expect(@cc).to be_active
      end
    end

    context "active communication channel" do
      it "should change the password if authorized" do
        @cc.confirm
        @cc.reload
        expect(@cc).to be_active
        pword = @pseudonym.crypted_password
        code = @cc.confirmation_code
        post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code, :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
        expect(response).to be_success
        expect(assigns[:pseudonym]).to eql(@pseudonym)
        @pseudonym.reload
        expect(@pseudonym.crypted_password).not_to eql(pword)
        expect(@pseudonym.user).to be_registered
        @cc.reload
        expect(@cc.confirmation_code).not_to eql(code)
        expect(@cc).to be_active
      end
    end

    it "should not change the password if unauthorized" do
      pword = @pseudonym.crypted_password
      code = @cc.confirmation_code
      post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code + 'a', :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
      assert_status(400)
      expect(assigns[:pseudonym]).to eql(@pseudonym)
      expect(assigns[:pseudonym].crypted_password).to eql(pword)
      expect(assigns[:pseudonym].user).not_to be_registered
      @cc.reload
      expect(@cc.confirmation_code).to eql(code)
      expect(@cc).not_to be_active
    end

    describe "forgot password" do
      before :once do
        Notification.create(:name => 'Forgot Password')
        user_factory
      end

      it "should send password-change email for a registered user" do
        pseudonym(@user)
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => @pseudonym.unique_id}
        expect(response).to be_redirect
        expect(assigns[:ccs]).to include(@cc)
        expect(assigns[:ccs].detect{|cc| cc == @cc}.messages_sent).not_to be_nil
        expect(assigns[:ccs].detect{|cc| cc == @cc}.messages_sent).not_to be_empty
      end

      it "should use case insensitive match for CommunicationChannel email" do
        # Setup user with communication channel that has mixed case email
        pseudonym(@user)
        @cc = communication_channel_model(:workflow_state => 'active', :path => 'Victoria.Silvstedt@example.com')
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => 'victoria.silvstedt@example.com'}
        expect(response).to be_redirect
        expect(assigns[:ccs]).to include(@cc)
        expect(assigns[:ccs].detect{|cc| cc == @cc}.messages_sent).not_to be_nil
        expect(assigns[:ccs].detect{|cc| cc == @cc}.messages_sent).not_to be_empty
      end
      it "should send password-change email case insensitively" do
        pseudonym(@user, :username => 'user1@example.com')
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => 'USER1@EXAMPLE.COM'}
        expect(response).to be_redirect
        expect(assigns[:ccs]).to include(@cc)
        expect(assigns[:ccs].detect{|cc| cc == @cc}.messages_sent).not_to be_nil
        expect(assigns[:ccs].detect{|cc| cc == @cc}.messages_sent).not_to be_empty
      end

      it "should not send password-change email for users with pseudonyms in a different account" do
        pseudonym(@user, :account => Account.site_admin)
        get 'forgot_password', :pseudonym_session => {:unique_id_forgot => @pseudonym.unique_id}
        expect(response).to be_redirect
        expect(assigns[:ccs]).not_to include(@cc)
      end
    end

    it "should render confirm change password view for registered user's email" do
      @user.register
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      expect(response).to be_success
    end

    it "should not render confirm change password view for non-email channels" do
      @user.register
      @cc.update_attributes(:path_type => 'sms')
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      expect(response).to be_redirect
    end

    it "should render confirm change password view for unregistered user" do
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      expect(response).to be_success
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
      expect(@other_pseudonym).to be_active
      expect(@pseudonym).to be_active

      delete 'destroy', :user_id => @other_user.id, :id => @pseudonym.id
      assert_status(404)
      expect(@other_pseudonym).to be_active
      expect(@pseudonym).to be_active
    end

    it "should not destroy if it's the last active pseudonym" do
      account_admin_user(user: @user)
      delete 'destroy', :user_id => @user.id, :id => @pseudonym.id
      assert_status(400)
      expect(@pseudonym).to be_active
    end

    it "should not destroy if it's SIS and the user doesn't have permission" do
      account_admin_user_with_role_changes(user: @user, role_changes: {manage_sis: false})
      @pseudonym.sis_user_id = 'bob'
      @pseudonym.save!
      delete 'destroy', :user_id => @user.id, :id => @pseudonym.id
      assert_unauthorized
      expect(@pseudonym).to be_active
    end

    it "should destroy if for the current user with more than one pseudonym" do
      account_admin_user(user: @user)
      @p2 = @user.pseudonyms.create!(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(200)
      expect(@pseudonym).to be_active
      expect(@p2.reload).to be_deleted
    end

    it "should destroy if authorized to delete pseudonyms" do
      Account.site_admin.account_users.create!(user: @user)
      @p2 = @user.pseudonyms.build(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      @p2.sis_user_id = 'another_one@test.com'
      @p2.save!
      @p2.account.authentication_providers.create!(:auth_type => 'ldap')
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(200)
      expect(@pseudonym).to be_active
      expect(@p2).to be_active
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
        expect(response).to be_success
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
        expect(response).to be_redirect
        expect(@user.reload.pseudonyms.map(&:unique_id)).to include('a_new_unique_name')
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
        expect(response).to be_success
        expect(@user.pseudonyms.size).to eq 2
        expect((@user.pseudonyms - [@pseudonym]).last.account).to eq @account
      end

      it "should allow explicit account id in params as long as they have permission" do
        @account2 = Account.create!
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :account_id => @account.id, :unique_id => 'unique1' }
        expect(response).to be_success
        expect(@user.pseudonyms.size).to eq 2
        expect((@user.pseudonyms - [@pseudonym]).last.account).to eq @account
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
      expect(response).to be_redirect
      @test_user.pseudonym.reload
      expect(@test_user.pseudonym.valid_password?('new_password')).to be_truthy
    end

    it "should not change a password if not authorized" do
      account1 = Account.new
      account1.settings[:admins_can_change_passwords] = true
      account1.save!
      user_with_pseudonym(:active_all => 1, :username => 'user@example.com', :password => 'qwertyuiop', :account => account1)
      @user1 = @user
      @pseudonym1 = @pseudonym
      # need to get the user associated with the default account as well
      @user.pseudonyms.create!(:unique_id => 'user1@example.com', :account => Account.default)

      user_with_pseudonym(:active_all => 1, :username => 'user2@example.com', :password => 'qwertyuiop')
      Account.default.account_users.create!(user: @user)
      user_session(@user, @pseudonym)
      # not logged in!

      post 'update', :format => 'json', :id => @pseudonym1.id, :user_id => @user1.id, :pseudonym => { :password => 'bobbobbob', :password_confirmation => 'bobbobbob' }
      expect(response).not_to be_success
      @pseudonym1.reload
      expect(@pseudonym1.valid_password?('qwertyuiop')).to be_truthy
      expect(@pseudonym1.valid_password?('bobbobbob')).to be_falsey
    end

    it "should be able to change SIS with only :manage_sis permissions" do
      account1 = Account.new
      account1.settings[:admins_can_change_passwords] = false
      account1.save!
      user_with_pseudonym(:active_all => 1, :username => 'user@example.com', :password => 'qwertyuiop', :account => account1)
      @user1 = @user
      @pseudonym1 = @pseudonym

      role = custom_account_role('sis_only', :account => account1)
      user_with_pseudonym(:active_all => 1, :username => 'user2@example.com', :password => 'qwertyuiop')
      account_admin_user_with_role_changes(user: @user, account: account1, role: role, role_changes: { manage_sis: true, manage_user_logins: true })
      user_session(@user, @pseudonym)

      post 'update', :format => 'json', :id => @pseudonym1.id, :user_id => @user1.id, :pseudonym => { :sis_user_id => 'sis1' }
      expect(response).to be_success
      expect(@pseudonym1.reload.sis_user_id).to eq 'sis1'

      post 'update', :format => 'json', :id => @pseudonym1.id, :user_id => @user1.id, :pseudonym => { :integration_id => 'sis2' }
      expect(response).to be_success
      expect(@pseudonym1.reload.integration_id).to eq 'sis2'
    end

    it "should be able to change unique_id with permission" do
      bob = user_with_pseudonym(username: 'old_username')
      sally = account_admin_user
      user_session(sally)
      put 'update',
        id: bob.pseudonym.id,
        user_id: bob.id,
        pseudonym: { unique_id: 'new_username' }
      expect(response).to be_redirect
      expect(bob.pseudonym.reload.unique_id).to eq 'new_username'
    end

    it "should not be able to change unique_id without permission" do
      bob = user_with_pseudonym(username: 'old_username')
      user_session(bob)
      put 'update',
        id: bob.pseudonym.id,
        user_id: bob.id,
        pseudonym: { unique_id: 'new_username' }
      expect(response).not_to be_success
      expect(bob.pseudonym.reload.unique_id).to eq 'old_username'
    end

    it "should fail partial update when permission isn't given to make username change" do
      bob = user_with_pseudonym(username: 'old_username', password: 'old_password')
      user_session(bob)
      put 'update',
          id: bob.pseudonym.id,
          user_id: bob.id,
          pseudonym: {
              password: 'new_password',
              password_confirmation: 'new_password',
              unique_id: 'new_username'
          }
      expect(response).not_to be_success
      bob.pseudonym.reload
      expect(bob.pseudonym.unique_id).to eq 'old_username'
      expect(bob.pseudonym).to be_valid_password('old_password')
    end

    it "should allow password change for current user" do
      bob = user_with_pseudonym(username: 'old_username', password: 'old_password')
      user_session(bob)
      put 'update',
          id: bob.pseudonym.id,
          user_id: bob.id,
          pseudonym: {
              password: 'new_password',
              password_confirmation: 'new_password',
          }
      expect(response).to be_redirect
      bob.pseudonym.reload
      expect(bob.pseudonym.unique_id).to eq 'old_username'
      expect(bob.pseudonym).to be_valid_password('new_password')
    end

    it "should return an error message when trying to duplicate a sis id" do
      user_with_pseudonym(:active_all => 1, :username => 'user@example.com', :password => 'qwertyuiop')
      @user1 = @user
      @pseudonym1 = @pseudonym
      @pseudonym1.update_attribute(:sis_user_id, "sis_user")

      user_with_pseudonym(:active_all => 1, :username => 'user2@example.com', :password => 'qwertyuiop')
      @user2 = @user
      @pseudonym2 = @pseudonym

      user_with_pseudonym(:active_all => 1, :username => 'admin@example.com', :password => 'qwertyuiop')
      account_admin_user(user: @user)
      user_session(@user, @pseudonym)

      post 'update', :format => 'json', :id => @pseudonym2.id, :user_id => @user2.id, :pseudonym => { :sis_user_id => 'sis_user' }
      expect(response).to be_bad_request
      res = JSON.parse(response.body)
      expect(res["errors"]["sis_user_id"][0]["type"]).to eq "taken"
      expect(res["errors"]["sis_user_id"][0]["message"]).to match(/is already in use/)
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
        expect(response).to be_success
        expect(assigns['pseudonyms']).to match_array [@p1, @p2]
      end
    end

    describe 'create' do
      it "should create a new pseudonym for a user in a different shard (cross-shard)" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :password => 'bobobobo', :password_confirmation => 'bobobobo', :account_id => Account.default.id, :unique_id => 'bobob' }
        expect(response).to be_success

        @user.reload
        expect(@user.all_pseudonyms.length).to eq 2
        expect(@user.all_pseudonyms.map(&:shard)).to eq [@shard1, Shard.default]
      end

      it "should create a new pseudonym for a user in a different shard (same-shard)" do
        post 'create', :format => 'json', :user_id => @user.id, :pseudonym => { :password => 'bobobobo', :password_confirmation => 'bobobobo', :account_id => @account.id, :unique_id => 'bobob' }
        expect(response).to be_success

        expect(@user.all_pseudonyms.length).to eq 2
        expect(@user.all_pseudonyms.map(&:shard)).to eq [@shard1, @shard1]
      end
    end

    describe 'update' do
      it "should update a pseudonym on another shard" do
        post 'update', :format => 'json', :user_id => @user.id, :id => @pseudonym.id, :pseudonym => { :unique_id => 'yoyoyo' }
        expect(response).to be_success

        expect(@pseudonym.reload.unique_id).to eq 'yoyoyo'
      end

      it "should update a pseudonym on the requesting shard for a user from another shard" do
        @pseudonym = Account.default.pseudonyms.create!(:user => @user, :unique_id => 'bobob')
        post 'update', :format => 'json', :user_id => @user.id, :id => @pseudonym.id, :pseudonym => { :unique_id => 'yoyoyo' }
        expect(response).to be_success

        expect(@pseudonym.reload.unique_id).to eq 'yoyoyo'
      end
    end

    describe 'destroy' do
      it "should destroy a pseudonym on another shard" do
        @pseudonym = @account.pseudonyms.create!(:user => @user, :unique_id => 'bobob')
        post 'destroy', :format => 'json', :user_id => @user.id, :id => @pseudonym.id
        expect(response).to be_success

        expect(@pseudonym.reload).to be_deleted
      end

      it "should destroy a pseudonym on the requesting shard for a user from another shard" do
        @pseudonym = Account.default.pseudonyms.create!(:user => @user, :unique_id => 'bobob')
        post 'destroy', :format => 'json', :user_id => @user.id, :id => @pseudonym.id
        expect(response).to be_success

        expect(@pseudonym.reload).to be_deleted
      end
    end
  end
end
