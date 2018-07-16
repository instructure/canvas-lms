#
# Copyright (C) 2015 - present Instructure, Inc.
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

require_relative '../../spec_helper'
require 'rotp'

describe Login::OtpController do
  describe '#new' do
    before :once do
      user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')
    end

    before do
      user_session(@user, @pseudonym)
    end

    context "verification" do
      before do
        session[:pending_otp] = true
      end

      it "should show enrollment for unenrolled, required user" do
        Account.default.settings[:mfa_settings] = :required
        Account.default.save!

        get :new
        expect(response).to be_successful
        expect(session[:pending_otp_secret_key]).not_to be_nil
      end

      it "should ask for verification of enrolled, optional user" do
        Account.default.settings[:mfa_settings] = :optional
        Account.default.save!

        @user.otp_secret_key = ROTP::Base32.random_base32
        @user.save!

        get :new
        expect(response).to be_successful
        expect(session[:pending_otp_secret_key]).to be_nil
      end

      it "should send otp to sms channel" do
        Account.default.settings[:mfa_settings] = :required
        Account.default.save!

        @user.otp_secret_key = ROTP::Base32.random_base32
        cc = @user.otp_communication_channel = @user.communication_channels.sms.create!(:path => 'bob')
        expect_any_instantiation_of(cc).to receive(:send_otp!)
        @user.save!

        get :new
        expect(response).to be_successful
        expect(session[:pending_otp_secret_key]).to be_nil
      end
    end

    context "enrollment" do
      it "should generate a secret key" do
        get :new
        expect(session[:pending_otp_secret_key]).not_to be_nil
        expect(@user.reload.otp_secret_key).to be_nil
      end

      it "should generate a new secret key for re-enrollment" do
        @user.otp_secret_key = ROTP::Base32.random_base32
        @user.save!

        get :new
        expect(session[:pending_otp_secret_key]).not_to be_nil
        expect(session[:pending_otp_secret_key]).not_to eq @user.reload.otp_secret_key
      end
    end
  end

  describe "#create" do
    context "enrollment" do
      before :once do
        user_with_pseudonym
      end

      before do
        user_session(@user, @pseudonym)
        @secret_key = session[:pending_otp_secret_key] = ROTP::Base32.random_base32
      end

      it "should save the pending key" do
        @user.one_time_passwords.create!
        @user.otp_communication_channel_id = @user.communication_channels.sms.create!(:path => 'bob')

        post :create, params: {:otp_login => { :verification_code => ROTP::TOTP.new(@secret_key).now }}
        expect(response).to redirect_to settings_profile_url
        expect(@user.reload.otp_secret_key).to eq @secret_key
        expect(@user.otp_communication_channel).to be_nil
        expect(@user.one_time_passwords).not_to be_exists

        expect(session[:pending_otp_secret_key]).to be_nil
      end

      it "should continue to the dashboard if part of the login flow" do
        session[:pending_otp] = true
        post :create, params: {:otp_login => { :verification_code => ROTP::TOTP.new(@secret_key).now }}
        expect(response).to redirect_to dashboard_url(:login_success => 1)
        expect(session[:pending_otp]).to be_nil
      end

      it "should save a pending sms" do
        @cc = @user.communication_channels.sms.create!(:path => 'bob')
        session[:pending_otp_communication_channel_id] = @cc.id
        code = ROTP::TOTP.new(@secret_key).now
        # make sure we get 5 minutes of drift
        expect_any_instance_of(ROTP::TOTP).to receive(:verify_with_drift).with(code.to_s, 300).once.and_return(true)
        post :create, params: {:otp_login => { :verification_code => code.to_s }}
        expect(response).to redirect_to settings_profile_url
        expect(@user.reload.otp_secret_key).to eq @secret_key
        expect(@user.otp_communication_channel).to eq @cc
        expect(@cc.reload).to be_active
        expect(session[:pending_otp_secret_key]).to be_nil
        expect(session[:pending_otp_communication_channel_id]).to be_nil
      end

      it "shouldn't fail if the sms is already active" do
        @cc = @user.communication_channels.sms.create!(:path => 'bob')
        @cc.confirm!
        session[:pending_otp_communication_channel_id] = @cc.id
        post :create, params: {:otp_login => { :verification_code => ROTP::TOTP.new(@secret_key).now }}
        expect(response).to redirect_to settings_profile_url
        expect(@user.reload.otp_secret_key).to eq @secret_key
        expect(@user.otp_communication_channel).to eq @cc
        expect(@cc.reload).to be_active
        expect(session[:pending_otp_secret_key]).to be_nil
        expect(session[:pending_otp_communication_channel_id]).to be_nil
      end
    end

    context "verification" do
      before :once do
        Account.default.settings[:mfa_settings] = :required
        Account.default.save!

        user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')
      end

      before do
        @user.otp_secret_key = ROTP::Base32.random_base32
        @user.save!
        expect_any_instance_of(CommunicationChannel).to receive(:send_otp!).never
        user_session(@user, @pseudonym)
        session[:pending_otp] = true
      end

      it "should verify a code" do
        code = ROTP::TOTP.new(@user.otp_secret_key).now
        post :create, params: {:otp_login => { :verification_code => code }}
        expect(response).to redirect_to dashboard_url(:login_success => 1)
        expect(cookies['canvas_otp_remember_me']).to be_nil
        expect(Canvas.redis.get("otp_used:#{@user.global_id}:#{code}")).to eq '1' if Canvas.redis_enabled?
      end

      it "should verify a backup code" do
        code = @user.one_time_passwords.create!.code
        post :create, params: {:otp_login => { :verification_code => code }}
        expect(response).to redirect_to dashboard_url(:login_success => 1)
        expect(cookies['canvas_otp_remember_me']).to be_nil
        expect(Canvas.redis.get("otp_used:#{@user.global_id}:#{code}")).to eq '1' if Canvas.redis_enabled?
      end

      it "should set a cookie" do
        post :create, params: {otp_login: { verification_code: ROTP::TOTP.new(@user.otp_secret_key).now, remember_me: '1' }}
        expect(response).to redirect_to dashboard_url(:login_success => 1)
        expect(cookies['canvas_otp_remember_me']).not_to be_nil
      end

      it "should add the current ip to existing ips" do
        cookies['canvas_otp_remember_me'] = @user.otp_secret_key_remember_me_cookie(Time.now.utc, nil, 'ip1')
        allow_any_instance_of(ActionDispatch::Request).to receive(:ip).and_return('ip2')
        post :create, params: {otp_login: { verification_code: ROTP::TOTP.new(@user.otp_secret_key).now, remember_me: '1' }}
        expect(response).to redirect_to dashboard_url(:login_success => 1)
        expect(cookies['canvas_otp_remember_me']).not_to be_nil
        _, ips, _ = @user.parse_otp_remember_me_cookie(cookies['canvas_otp_remember_me'])
        expect(ips.sort).to eq ['ip1', 'ip2']
      end

      it "should fail for an incorrect token" do
        post :create, params: {:otp_login => { :verification_code => '123456' }}
        expect(response).to redirect_to(otp_login_url)
      end

      it "should allow 30 seconds of drift by default" do
        expect_any_instance_of(ROTP::TOTP).to receive(:verify_with_drift).with('123456', 30).once.and_return(false)
        post :create, params: {:otp_login => { :verification_code => '123456' }}
        expect(response).to redirect_to(otp_login_url)
      end

      it "should allow 5 minutes of drift for SMS" do
        @user.otp_communication_channel = @user.communication_channels.sms.create!(:path => 'bob')
        @user.save!

        expect_any_instance_of(ROTP::TOTP).to receive(:verify_with_drift).with('123456', 300).once.and_return(false)
        post :create, params: {:otp_login => { :verification_code => '123456' }}
        expect(response).to redirect_to(otp_login_url)
      end

      it "should not allow the same code to be used multiple times" do
        skip "needs redis" unless Canvas.redis_enabled?

        Canvas.redis.set("otp_used:#{@user.global_id}:123456", '1')
        expect_any_instance_of(ROTP::TOTP).to receive(:verify_with_drift).never
        post :create, params: {:otp_login => { :verification_code => '123456' }}
        expect(response).to redirect_to(otp_login_url)
      end
    end
  end

  describe '#destroy' do
    before :once do
      Account.default.settings[:mfa_settings] = :optional
      Account.default.save!

      user_with_pseudonym(:active_all => 1, :password => 'qwertyuiop')
      @user.otp_secret_key = ROTP::Base32.random_base32
      @user.otp_communication_channel = @user.communication_channels.sms.create!(:path => 'bob')
      @user.generate_one_time_passwords
      @user.save!
    end

    before :each do
      user_session(@user)
    end

    it "should delete self" do
      delete :destroy, params: {:user_id => 'self'}
      expect(response).to be_successful
      expect(@user.reload.otp_secret_key).to be_nil
      expect(@user.otp_communication_channel).to be_nil
      expect(@user.one_time_passwords).not_to be_exists
    end

    it "should delete self as id" do
      delete :destroy, params: {:user_id => @user.id}
      expect(response).to be_successful
      expect(@user.reload.otp_secret_key).to be_nil
      expect(@user.otp_communication_channel).to be_nil
    end

    it "should not be able to delete self if required" do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!
      delete :destroy, params: {:user_id => 'self'}
      expect(response).not_to be_successful
      expect(@user.reload.otp_secret_key).not_to be_nil
      expect(@user.otp_communication_channel).not_to be_nil
    end

    it "should not be able to delete self as id if required" do
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!
      delete :destroy, params: {:user_id => @user.id}
      expect(response).not_to be_successful
      expect(@user.reload.otp_secret_key).not_to be_nil
      expect(@user.otp_communication_channel).not_to be_nil
    end

    it "should not be able to delete another user" do
      @other_user = @user
      @admin = user_with_pseudonym(:active_all => 1, :unique_id => 'user2')
      user_session(@admin)
      delete :destroy, params: {:user_id => @other_user.id}
      expect(response).not_to be_successful
      expect(@other_user.reload.otp_secret_key).not_to be_nil
      expect(@other_user.otp_communication_channel).not_to be_nil
    end

    it "should be able to delete another user with permission" do
      @other_user = @user
      @admin = user_with_pseudonym(active_all: 1, unique_id: 'user2')
      mfa_role = custom_account_role('mfa_role', account: Account.default)

      Account.default.role_overrides.create!(role: mfa_role, permission: 'reset_any_mfa', enabled: true)
      Account.default.account_users.create!(user: @admin, role: mfa_role)

      user_session(@admin)
      delete :destroy, params: {user_id: @other_user.id}
      expect(response).to be_successful
      expect(@other_user.reload.otp_secret_key).to be_nil
      expect(@other_user.otp_communication_channel).to be_nil
    end

    it "should be able to delete another user with site_admin" do
      @other_user = @user
      @admin = user_with_pseudonym(active_all: 1, unique_id: 'user2', account: Account.site_admin)
      mfa_role = custom_account_role('mfa_role', account: Account.site_admin)

      Account.site_admin.role_overrides.create!(role: mfa_role, permission: 'reset_any_mfa', enabled: true)
      Account.site_admin.account_users.create!(user: @admin, role: mfa_role)

      user_session(@admin)
      delete :destroy, params: {user_id: @other_user.id}
      expect(response).to be_successful
      expect(@other_user.reload.otp_secret_key).to be_nil
      expect(@other_user.otp_communication_channel).to be_nil
    end

    it "should not be able to delete another user from different account" do
      @other_user = @user
      account1 = Account.create!
      @admin = user_with_pseudonym(active_all: 1, unique_id: 'user2', account: account1)
      mfa_role = custom_account_role('mfa_role', account: account1)

      account1.role_overrides.create!(role: mfa_role, permission: 'reset_any_mfa', enabled: true)
      account1.account_users.create!(user: @admin, role: mfa_role)
      user_session(@admin)

      delete :destroy, params: {user_id: @other_user.id}
      expect(response).not_to be_successful
      expect(@other_user.reload.otp_secret_key).not_to be_nil
      expect(@other_user.otp_communication_channel).not_to be_nil
    end

    it "should be able to delete another user as admin" do
      # even if required
      Account.default.settings[:mfa_settings] = :required
      Account.default.save!

      @other_user = @user
      @admin = user_with_pseudonym(:active_all => 1, :unique_id => 'user2')
      Account.default.account_users.create!(user: @admin)
      user_session(@admin)
      delete :destroy, params: {:user_id => @other_user.id}
      expect(response).to be_successful
      expect(@other_user.reload.otp_secret_key).to be_nil
      expect(@other_user.otp_communication_channel).to be_nil
    end
  end
end
