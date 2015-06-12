require File.expand_path('../spec_helper', File.dirname(__FILE__))


describe AuthenticationMethods do
  describe "#load_user" do
    before do
      @request = stub(:env => {'encrypted_cookie_store.session_refreshed_at' => 5.minutes.ago},
                      :format => stub(:json? => false),
                      :host_with_port => "")
      @controller = RSpec::MockController.new(nil, @request)
      @controller.stubs(:load_pseudonym_from_access_token)
      @controller.stubs(:api_request?).returns(false)
      @controller.stubs(:logger).returns(stub(info: nil))
    end

    context "with active session" do
      before do
        user_with_pseudonym
        @pseudonym_session = stub(:record => @pseudonym)
        PseudonymSession.stubs(:find).returns(@pseudonym_session)
      end

      it "should set the user and pseudonym" do
        expect(@controller.send(:load_user)).to eq @user
        expect(@controller.instance_variable_get(:@current_user)).to eq @user
        expect(@controller.instance_variable_get(:@current_pseudonym)).to eq @pseudonym
      end

      it "should destroy session if user was explicitly logged out" do
        @user.stamp_logout_time!
        @pseudonym.reload
        @controller.expects(:destroy_session).once
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
  end

  describe "#masked_authenticity_token" do
    before do
      @request = stub(host_with_port: "")
      @controller = RSpec::MockController.new(nil, @request)
      @session_options = {}
      CanvasRails::Application.config.expects(:session_options).at_least_once.returns(@session_options)
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
      HostUrl.expects(:is_file_host?).once.with(@request.host_with_port).returns(true)
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

  def cookies
    @cookies ||= {}
  end
end

