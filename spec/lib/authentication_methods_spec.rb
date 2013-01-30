require File.expand_path('../spec_helper', File.dirname(__FILE__))


describe AuthenticationMethods do

  describe '#initiate_delegated_login' do
    let(:request) { stub(:host_with_port => '' ) }
    let(:controller) { Spec::MockController.new(domain_root_account, request) }

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
        controller = Spec::MockController.new(domain_root_account, request, :canvas_login => true)
        controller.initiate_delegated_login.should be_false
        controller.redirects.should == []
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
        controller = Spec::MockController.new(domain_root_account, request, :canvas_login => true)
        controller.initiate_delegated_login.should be_false
        controller.redirects.should == []
      end
    end
  end
end

class Spec::MockController
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

end

