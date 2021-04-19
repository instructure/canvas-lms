# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../spec_helper'

# FIXME: these tests should all exist in a controller test,
# since that's the context required to run any of them
describe AuthenticationMethods do
  class MockController
    include Canvas::RequestForgeryProtection
    include AuthenticationMethods

    attr_accessor :redirects, :params, :session, :request, :render_hash

    def initialize(request:, root_account: Account.default, params: {})
      @request = request
      @domain_root_account = root_account
      @params = params
      @redirects = []
      @render_hash = nil
      reset_session
    end

    def reset_session
      @session = {}
    end

    def redirect_to(url)
      @redirects << url
    end

    def render(render_hash)
      @render_hash = render_hash
    end

    def api_find(klass, id)
      klass.find(id)
    end

    def cas_login_url; ''; end

    def zendesk_delegated_auth_pass_through_url(options)
      options[:target]
    end

    def cookies
      @cookies ||= {}
    end

    class MockLogger
      def info(*); end
      def warn(*); end
    end

    def logger
      MockLogger.new
    end
  end

  describe "#load_user" do
    context "with active session" do
      before do
        @request = double(:env => {'encrypted_cookie_store.session_refreshed_at' => 5.minutes.ago},
                        :format => double(:json? => false),
                        :host_with_port => "")
        @controller = MockController.new(request: @request)
        allow(@controller).to receive(:load_pseudonym_from_access_token)
        allow(@controller).to receive(:api_request?).and_return(false)
        user_with_pseudonym
        @pseudonym_session = double(record: @pseudonym)
        allow(PseudonymSession).to receive(:find_with_validation).and_return(@pseudonym_session)
      end

      it "should set the user and pseudonym" do
        expect(@controller.send(:load_user)).to eq @user
        expect(@controller.instance_variable_get(:@current_user)).to eq @user
        expect(@controller.instance_variable_get(:@current_pseudonym)).to eq @pseudonym
      end

      it "should destroy session if user was explicitly logged out" do
        @user.stamp_logout_time!
        @pseudonym.reload
        expect(@controller).to receive(:destroy_session).once
        expect(@controller.send(:load_user)).to be_nil
        expect(@controller.instance_variable_get(:@current_user)).to be_nil
        expect(@controller.instance_variable_get(:@current_pseudonym)).to be_nil
      end

      it "should not destroy session if user was logged out in the future" do
        Timecop.freeze(5.minutes.from_now) do
          @user.stamp_logout_time!
        end
        @pseudonym.reload
        expect(@controller.send(:load_user)).to eq @user
        expect(@controller.instance_variable_get(:@current_user)).to eq @user
        expect(@controller.instance_variable_get(:@current_pseudonym)).to eq @pseudonym
      end

      it "should set the CSRF cookie" do
        @controller.send(:load_user)
        expect(@controller.cookies['_csrf_token']).not_to be nil
      end
    end

    context "with a JSON web token" do
      include_context "JWT setup"

      before do
        enable_default_developer_key!
        user_with_pseudonym # masquerading user
        @real_user = @user
        Account.site_admin.account_users.create!(user: @real_user)
        user_with_pseudonym # masqueradee
      end

      def build_encoded_token(user_id, real_user_id: nil)
        payload = { sub: user_id }
        payload[:masq_sub] = real_user_id if real_user_id
        crypted_token = Canvas::Security::ServicesJwt.generate(payload, false)
        payload = {
          iss: "some other service",
          user_token: crypted_token
        }
        wrapper_token = Canvas::Security.create_jwt(payload, nil, fake_signing_secret)
        Canvas::Security.base64_encode(wrapper_token)
      end

      def setup_with_jwt(token)
        request = double(authorization: "Bearer #{token}",
                         format: double(:json? => true),
                         host_with_port: "",
                         url: "",
                         method: "GET")
        controller = MockController.new(request: request)
        allow(controller).to receive(:api_request?).and_return(true)
        controller
      end

      it "finds a user by JWT" do
        base64_encoded_token = build_encoded_token(@user.id)
        controller = setup_with_jwt(base64_encoded_token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_user)).to eq @user
      end

      it "sets real current_user if masquerading user id present" do
        base64_encoded_token = build_encoded_token(@user.id, real_user_id: @real_user.id)
        controller = setup_with_jwt(base64_encoded_token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_user)).to eq @user
        expect(controller.instance_variable_get(:@real_current_user)).to eq @real_user
      end

      it "sets current_pseudonym" do
        base64_encoded_token = build_encoded_token(@user.id)
        controller = setup_with_jwt(base64_encoded_token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_pseudonym)).to eq @user.pseudonym
        expect(controller.instance_variable_get(:@real_current_pseudonym)).to be_nil
      end

      it "sets real current_pseudonym if masquerading user id present" do
        base64_encoded_token = build_encoded_token(@user.id, real_user_id: @real_user.id)
        controller = setup_with_jwt(base64_encoded_token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_pseudonym)).to eq @user.pseudonym
        expect(controller.instance_variable_get(:@real_current_pseudonym)).to eq @real_user.pseudonym
      end
    end

    context "with an access token" do
      before do
        enable_default_developer_key!
        user_with_pseudonym # masquerading user
        @real_user = @user
        Account.site_admin.account_users.create!(user: @real_user)
        user_with_pseudonym # masqueradee
      end

      def setup_with_token(token)
        request = double(authorization: "Bearer #{token.full_token}",
                         format: double(:json? => true),
                         host_with_port: "",
                         url: "",
                         method: "GET")
        controller = MockController.new(request: request)
        allow(controller).to receive(:api_request?).and_return(true)
        controller
      end

      it "finds a user by access token" do
        token = AccessToken.create!(user: @user)
        controller = setup_with_token(token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_user)).to eq @user
      end

      it "sets {real_,}current_user from token" do
        token = AccessToken.create!(user: @user, real_user: @real_user)
        controller = setup_with_token(token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_user)).to eq @user
        expect(controller.instance_variable_get(:@real_current_user)).to eq @real_user
      end

      it "sets current_pseudonym" do
        token = AccessToken.create!(user: @user)
        controller = setup_with_token(token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_pseudonym)).to eq @user.pseudonym
        expect(controller.instance_variable_get(:@real_current_pseudonym)).to be_nil
      end

      it "sets real current_pseudonym" do
        token = AccessToken.create!(user: @user, real_user: @real_user)
        controller = setup_with_token(token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_pseudonym)).to eq @user.pseudonym
        expect(controller.instance_variable_get(:@real_current_pseudonym)).to eq @real_user.pseudonym
      end

      it "marks the access token as used" do
        token = AccessToken.create!(user: @user)
        controller = setup_with_token(token)

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@access_token).last_used_at).to be_truthy
      end

      it "raises AccessTokenError if current_user and current_pseudonym are not set" do
        allow(SisPseudonym).to receive(:for).and_return(nil)
        token = AccessToken.create!(user: @user)
        controller = setup_with_token(token)

        expect{controller.send(:load_user)}.to raise_error(AuthenticationMethods::AccessTokenError)
      end

      it "accepts as_user_id on a masquerading token if masquerade matches" do
        token = AccessToken.create!(user: @user, real_user: @real_user)
        controller = setup_with_token(token)
        controller.params[:as_user_id] = @user.id

        expect(controller.send(:load_user)).to eq @user
        expect(controller.instance_variable_get(:@current_user)).to eq @user
        expect(controller.instance_variable_get(:@real_current_user)).to eq @real_user
      end

      it "rejects as_user_id on a masquerading token if masquerade does not match" do
        @other_user = @user
        user_with_pseudonym
        token = AccessToken.create!(user: @user, real_user: @real_user)
        controller = setup_with_token(token)
        controller.params[:as_user_id] = @other_user.id

        expect(controller.send(:load_user)).to eq false
        expect(controller.render_hash[:json][:errors]).to eq "Cannot change masquerade"
      end
    end
  end

  describe "#masked_authenticity_token" do
    before do
      @request = double(host_with_port: "")
      @controller = MockController.new(request: @request)
      @session_options = {}
      expect(CanvasRails::Application.config).to receive(:session_options).at_least(:once).and_return(@session_options)
    end

    it "should not set SSL-only explicitly if session_options doesn't specify" do
      @controller.send(:masked_authenticity_token)
      expect(@controller.cookies['_csrf_token']).not_to be_has_key(:secure)
    end

    it "should set SSL-only if session_options specifies" do
      @session_options[:secure] = true
      @controller.send(:masked_authenticity_token)
      expect(@controller.cookies['_csrf_token'][:secure]).to be true
    end

    it "should set httponly explicitly false on a non-files host" do
      @controller.send(:masked_authenticity_token)
      expect(@controller.cookies['_csrf_token'][:httponly]).to be false
    end

    it "should set httponly explicitly true on a files host" do
      expect(HostUrl).to receive(:is_file_host?).once.with(@request.host_with_port).and_return(true)
      @controller.send(:masked_authenticity_token)
      expect(@controller.cookies['_csrf_token'][:httponly]).to be true
    end

    it "should not set a cookie domain explicitly if session_options doesn't specify" do
      @controller.send(:masked_authenticity_token)
      expect(@controller.cookies['_csrf_token']).not_to be_has_key(:domain)
    end

    it "should set a cookie domain explicitly if session_options specifies" do
      @session_options[:domain] = "cookie domain"
      @controller.send(:masked_authenticity_token)
      expect(@controller.cookies['_csrf_token'][:domain]).to eq @session_options[:domain]
    end
  end

  describe "#access_token_account" do
    let(:account) {Account.create!}
    let(:dev_key) {DeveloperKey.create!(account: account)}
    let(:access_token) {AccessToken.create!(developer_key: dev_key)}
    let(:request) {double(format: double(:json? => false), host_with_port:"")}
    let(:controller) {MockController.new(request: request, root_account: account)}

    it "doesn't call '#get_context' if the Dev key is owned by the domain root account" do
      expect(controller).not_to receive(:get_context)
      controller.access_token_account(account, access_token)
    end

    it "doesn't call '#get_context' if the Dev key has no account_id" do
      dev_key.account_id = nil
      dev_key.save!
      expect(controller).not_to receive(:get_context)
      controller.access_token_account(account, access_token)
    end

    it "returns the domain_root_account if there is no account_id" do
      dev_key.account_id = nil
      dev_key.save!
      expect(controller.access_token_account(account, access_token)).to be(account)
    end

    it "returns the domain_root_account if the Dev key is owned by the domain root account" do
      expect(controller.access_token_account(account, access_token)).to be(account)
    end

    it "returns the contexts account for a sub account dev_key" do
      sub_account = Account.create!(parent_account: account)
      dev_key.account = sub_account
      dev_key.save!
      allow(controller).to receive(:get_context)
      controller.instance_variable_set(:@context, sub_account)
      expect(controller.access_token_account(account, access_token)).to be(sub_account)
    end

    it "returns the domain_root_account if the context can't be resolved" do
      sub_account = Account.create!(parent_account: account)
      dev_key.account = sub_account
      dev_key.save!
      allow(controller).to receive(:get_context)
      expect(controller.access_token_account(account, access_token)).to be(account)
    end
  end
end
