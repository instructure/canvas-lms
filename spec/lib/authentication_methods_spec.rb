require File.expand_path('../spec_helper', File.dirname(__FILE__))


describe AuthenticationMethods do

  describe '#initiate_delegated_login' do;
    let(:request) { stub(:host_with_port => '', :host => '' ) }
    let(:controller) { RSpec::MockController.new(domain_root_account, request) }

    describe 'when auth is not delegated' do
      let(:domain_root_account) { stub(:delegated_authentication? => false) }

      it 'returns false' do
        controller.initiate_delegated_login.should be_false
      end

      it 'does not redirect anywhere' do
        controller.initiate_delegated_login
        controller.redirects.should == []
      end
    end

    describe 'when auth is CAS' do
      let(:domain_root_account) do
        stub(
          :delegated_authentication? => true,
          :cas_authentication? => true,
          :saml_authentication? => false,
          :account_authorization_config => stub(:auth_base => 'base_url')
        )
      end

      it 'returns true' do
        controller.initiate_delegated_login.should be_true
      end

      it 'redirects to CAS client url' do
        client = stub(:add_service_to_login_url => 'cas_login_url')
        CASClient::Client.stubs(:new => client)
        controller.initiate_delegated_login
        controller.redirects.should == ['cas_login_url']
      end

      it 'can be overriden by passing the canvas_login parameter' do
        controller = RSpec::MockController.new(domain_root_account, request, :canvas_login => true)
        controller.initiate_delegated_login.should be_false
        controller.redirects.should == []
      end


      context "cas_client" do
        let(:controller) { RSpec::MockController.new(domain_root_account, request, :canvas_login => true) }
        let(:cas_client) { controller.cas_client }
        let(:cas_base_url) { domain_root_account.account_authorization_config.auth_base }

        it "accepts an account parameter" do
          account_url = "account_url"
          account = domain_root_account
          account.account_authorization_config.stubs(:auth_base).returns(account_url)
          controller.instance_variable_set('@cas_client', nil)
          controller.cas_client(account).cas_base_url.should == account_url
        end

        it 'sets the cas_clients config values' do
          config = {
            cas_base_url: cas_base_url,
            encode_extra_attributes_as: :raw
          }
          cas_client.instance_variable_get('@conf_options').should == config
        end
      end
    end

    describe 'when auth is SAML' do
      let(:domain_root_account) do
        stub(
          :delegated_authentication? => true,
          :cas_authentication? => false,
          :saml_authentication? => true,
          :account_authorization_config => stub(:saml_settings => {}, :debugging? => false),
          :auth_discovery_url => nil
        )
      end

      let(:saml_request) { stub(:generate_request => 'saml_login_url') }

      before do
        pending('requires SAML extension') unless AccountAuthorizationConfig.saml_enabled
        Onelogin::Saml::AuthRequest.stubs(:new => saml_request)
      end

      it 'returns true' do
        controller.initiate_delegated_login.should be_true
      end

      it 'redirects to SAML auth request url' do
        controller.initiate_delegated_login
        controller.redirects.should == ['saml_login_url']
      end

      it 'redirects to the discovery url if there is one' do
        domain_root_account.stubs(:auth_discovery_url => 'discovery_url')
        controller.initiate_delegated_login
        controller.redirects.should == ['discovery_url']
      end

      it 'can be overriden by passing the canvas_login parameter' do
        controller = RSpec::MockController.new(domain_root_account, request, :canvas_login => true)
        controller.initiate_delegated_login.should be_false
        controller.redirects.should == []
      end
    end
  end

  describe "#load_user" do
    before do
      @request = stub(:env => {'encrypted_cookie_store.session_refreshed_at' => 5.minutes.ago})
      @controller = RSpec::MockController.new(nil, @request)
      @controller.stubs(:load_pseudonym_from_access_token)
      @controller.stubs(:api_request?).returns(false)
    end

    context "with active session" do
      before do
        user_with_pseudonym
        @pseudonym_session = stub(:record => @pseudonym)
        PseudonymSession.stubs(:find).returns(@pseudonym_session)
      end

      it "should set the user and pseudonym" do
        @controller.send(:load_user).should == @user
        @controller.instance_variable_get(:@current_user).should == @user
        @controller.instance_variable_get(:@current_pseudonym).should == @pseudonym
      end

      it "should destroy session if user was explicitly logged out" do
        @user.stamp_logout_time!
        @pseudonym.reload
        @controller.expects(:destroy_session).once
        @controller.send(:load_user).should be_nil
        @controller.instance_variable_get(:@current_user).should be_nil
        @controller.instance_variable_get(:@current_pseudonym).should be_nil
      end

      it "should not destroy session if user was logged out in the future" do
        Timecop.freeze(5.minutes.from_now) do
          @user.stamp_logout_time!
        end
        @pseudonym.reload
        @controller.send(:load_user).should == @user
        @controller.instance_variable_get(:@current_user).should == @user
        @controller.instance_variable_get(:@current_pseudonym).should == @pseudonym
      end
    end
  end
end

class RSpec::MockController
  include AuthenticationMethods

  attr_reader :redirects, :params, :session, :request

  def initialize(root_account, req, params_hash = {})
    @domain_root_account = root_account
    @request = req
    @redirects = []
    @params = params_hash
    reset_session
  end

  def reset_session
    @session = {}
  end

  def redirect_to(url)
    @redirects << url
  end

  def cas_login_url; ''; end

  def zendesk_delegated_auth_pass_through_url(options)
    options[:target]
  end

  def cookies; {}; end
end

