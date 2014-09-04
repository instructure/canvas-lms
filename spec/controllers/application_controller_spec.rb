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

describe ApplicationController do

  before :each do
    controller.stubs(:form_authenticity_token).returns('asdf')
    controller.stubs(:request).returns(stub(:host_with_port => "www.example.com"))
  end

  describe "#twitter_connection" do
    it "uses current user if available" do
      mock_current_user = mock()
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdocs_access_token_token] = "session_token"
      session[:oauth_gdocs_access_token_secret] = "sesion_secret"

      mock_user_services = mock("mock_user_services")
      mock_current_user.expects(:user_services).returns(mock_user_services)
      mock_user_services.expects(:find_by_service).with("twitter").returns(mock(token: "current_user_token", secret: "current_user_secret"))

      Twitter::Connection.expects(:new).with("current_user_token", "current_user_secret")

      controller.send(:twitter_connection)
    end
    it "uses session if no current user" do
      controller.instance_variable_set(:@current_user, nil)
      session[:oauth_twitter_access_token_token] = "session_token"
      session[:oauth_twitter_access_token_secret] = "sesion_secret"

      Twitter::Connection.expects(:new).with("session_token", "sesion_secret")

      controller.send(:twitter_connection)
    end
  end

  describe "#google_docs_connection" do
    it "uses @real_current_user first" do
      mock_real_current_user = mock()
      mock_current_user = mock()
      controller.instance_variable_set(:@real_current_user, mock_real_current_user)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdocs_access_token_token] = "session_token"
      session[:oauth_gdocs_access_token_secret] = "sesion_secret"

      Rails.cache.expects(:fetch).with(['google_docs_tokens', mock_real_current_user].cache_key).returns(["real_current_user_token", "real_current_user_secret"])

      GoogleDocs::Connection.expects(:new).with("real_current_user_token", "real_current_user_secret")

      controller.send(:google_docs_connection)
    end

    it "uses @current_user second" do
      mock_current_user = mock()
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdocs_access_token_token] = "session_token"
      session[:oauth_gdocs_access_token_secret] = "sesion_secret"

      Rails.cache.expects(:fetch).with(['google_docs_tokens', mock_current_user].cache_key).returns(["current_user_token", "current_user_secret"])

      GoogleDocs::Connection.expects(:new).with("current_user_token", "current_user_secret")

      controller.send(:google_docs_connection)
    end

    it "queries user services if token isn't in the cache" do
      mock_current_user = mock()
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdocs_access_token_token] = "session_token"
      session[:oauth_gdocs_access_token_secret] = "sesion_secret"

      mock_user_services = mock("mock_user_services")
      mock_current_user.expects(:user_services).returns(mock_user_services)
      mock_user_services.expects(:find_by_service).with("google_docs").returns(mock(token: "user_service_token", secret: "user_service_secret"))

      GoogleDocs::Connection.expects(:new).with("user_service_token", "user_service_secret")

      controller.send(:google_docs_connection)
    end

    it "uses the session values if no users are set" do
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, nil)
      session[:oauth_gdocs_access_token_token] = "session_token"
      session[:oauth_gdocs_access_token_secret] = "sesion_secret"

      GoogleDocs::Connection.expects(:new).with("session_token", "sesion_secret")

      controller.send(:google_docs_connection)
    end

    it "raises a NoTokenError when the user exists but does not have a user service" do
      mock_current_user = mock()
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdocs_access_token_token] = "session_token"
      session[:oauth_gdocs_access_token_secret] = "sesion_secret"

      mock_user_services = mock("mock_user_services")
      mock_current_user.expects(:user_services).returns(mock_user_services)
      mock_user_services.expects(:find_by_service).with("google_docs").returns(nil)

      expect {
        controller.send(:google_docs_connection)
      }.to raise_error(GoogleDocs::NoTokenError)
    end
  end

  describe "js_env" do
    it "should set items" do
      HostUrl.expects(:file_host).with(Account.default, "www.example.com").returns("files.example.com")
      controller.js_env :FOO => 'bar'
      controller.js_env[:FOO].should == 'bar'
      controller.js_env[:AUTHENTICITY_TOKEN].should == 'asdf'
      controller.js_env[:files_domain].should == 'files.example.com'
    end

    it "should auto-set timezone and locale" do
      I18n.locale = :fr
      Time.zone = 'Alaska'
      @controller.js_env[:LOCALE].should == 'fr-FR'
      @controller.js_env[:TIMEZONE].should == 'America/Juneau'
    end

    it "sets the contextual timezone from the context" do
      Time.zone = "Mountain Time (US & Canada)"
      controller.instance_variable_set(:@context, stub(time_zone: Time.zone, asset_string: ""))
      controller.js_env({})
      controller.js_env[:CONTEXT_TIMEZONE].should == 'America/Denver'
    end

    it "should allow multiple items" do
      controller.js_env :A => 'a', :B => 'b'
      controller.js_env[:A].should == 'a'
      controller.js_env[:B].should == 'b'
    end

    it "should not allow overwriting a key" do
      controller.js_env :REAL_SLIM_SHADY => 'please stand up'
      expect { controller.js_env(:REAL_SLIM_SHADY => 'poser') }.to raise_error
    end

    it 'gets appropriate settings from the root account' do
      root_account = stub(global_id: 1, open_registration?: true)
      HostUrl.stubs(file_host: 'files.example.com')
      controller.instance_variable_set(:@domain_root_account, root_account)
      controller.js_env[:SETTINGS][:open_registration].should be_truthy
    end

    context "sharding" do
      specs_require_sharding

      it "should set the global id for the domain_root_account" do
        controller.instance_variable_set(:@domain_root_account, Account.default)
        controller.js_env[:DOMAIN_ROOT_ACCOUNT_ID].should == Account.default.global_id
      end
    end
  end

  describe "clean_return_to" do
    before do
      req = stub('request obj', :protocol => 'https://', :host_with_port => 'canvas.example.com')
      controller.stubs(:request).returns(req)
    end

    it "should build from a simple path" do
      controller.send(:clean_return_to, "/calendar").should == "https://canvas.example.com/calendar"
    end

    it "should build from a full url" do
      # ... but always use the request host/protocol, not the given
      controller.send(:clean_return_to, "http://example.org/a/b?a=1&b=2#test").should == "https://canvas.example.com/a/b?a=1&b=2#test"
    end

    it "should reject disallowed paths" do
      controller.send(:clean_return_to, "ftp://example.com/javascript:hai").should be_nil
    end
  end

  describe "#reject!" do
    it "sets the message and status in the error json" do
      expect { controller.reject!('test message', :not_found) }.to(raise_error(RequestError) do |e|
        e.message.should == 'test message'
        e.error_json[:message].should == 'test message'
        e.error_json[:status].should == 'not_found'
        e.response_status.should == 404
      end)
    end

    it "defaults status to 'bad_request'" do
      expect { controller.reject!('test message') }.to(raise_error(RequestError) do |e|
        e.error_json[:status].should == 'bad_request'
        e.response_status.should == 400
      end)
    end

    it "accepts numeric status codes" do
      expect { controller.reject!('test message', 403) }.to(raise_error(RequestError) do |e|
        e.error_json[:status].should == 'forbidden'
        e.response_status.should == 403
      end)
    end

    it "accepts symbolic status codes" do
      expect { controller.reject!('test message', :service_unavailable) }.to(raise_error(RequestError) do |e|
        e.error_json[:status].should == 'service_unavailable'
        e.response_status.should == 503
      end)
    end
  end

  describe "safe_domain_file_user" do
    before :once do
      @user = User.create!
      @attachment = @user.attachments.new(:filename => 'foo.png')
      @attachment.content_type = 'image/png'
      @attachment.save!
    end

    before :each do
      # safe_domain_file_url wants to use request.protocol
      controller.stubs(:request).returns(mock(:protocol => '', :host_with_port => ''))

      @common_params = {
        :user_id => nil,
        :ts => nil,
        :sf_verifier => nil,
        :only_path => true
      }
    end

    it "should include inline=1 in url by default" do
      controller.expects(:file_download_url).
        with(@attachment, @common_params.merge(:inline => 1)).
        returns('')
      HostUrl.expects(:file_host_with_shard).with(42, '').returns(['myfiles', Shard.default])
      controller.instance_variable_set(:@domain_root_account, 42)
      url = controller.send(:safe_domain_file_url, @attachment)
      url.should match /myfiles/
    end

    it "should include :download=>1 in inline urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      controller.stubs(:named_context_url).returns('')
      url = controller.send(:safe_domain_file_url, @attachment)
      url.should match(/[\?&]download=1(&|$)/)
    end

    it "should not include :download=>1 in download urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      controller.stubs(:named_context_url).returns('')
      url = controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
      url.should_not match(/[\?&]download=1(&|$)/)
    end

    it "should include download_frd=1 and not include inline=1 in url when specified as for download" do
      controller.expects(:file_download_url).
        with(@attachment, @common_params.merge(:download_frd => 1)).
        returns('')
      controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
    end
  end

  describe "get_context" do
    after do
      I18n.localizer = nil
    end

    it "should find user with api_find for api requests" do
      user_with_pseudonym
      @pseudonym.update_attribute(:sis_user_id, 'test1')
      controller.instance_variable_set(:@domain_root_account, Account.default)
      controller.stubs(:named_context_url).with(@user, :context_url).returns('')
      controller.stubs(:params).returns({:user_id => 'sis_user_id:test1'})
      controller.stubs(:api_request?).returns(true)
      controller.send(:get_context)
      controller.instance_variable_get(:@context).should == @user
    end

    it "should find course section with api_find for api requests" do
      course_model
      @section = @course.course_sections.first
      @section.update_attribute(:sis_source_id, 'test1')
      controller.instance_variable_set(:@domain_root_account, Account.default)
      controller.stubs(:named_context_url).with(@section, :context_url).returns('')
      controller.stubs(:params).returns({:course_section_id => 'sis_section_id:test1'})
      controller.stubs(:api_request?).returns(true)
      controller.send(:get_context)
      controller.instance_variable_get(:@context).should == @section
    end

    # this test is supposed to represent calling I18n.t before a context is set
    # and still having later localizations that depend on the locale of the
    # context work.
    it "should reset the localizer" do
      # emulate all the locale related work done before/around a request
      acct = Account.default
      acct.default_locale = "es"
      acct.save!
      controller.instance_variable_set(:@domain_root_account, acct)
      req = mock()
      req.stubs(:headers).returns({})
      controller.stubs(:request).returns(req)
      controller.send(:assign_localizer)
      I18n.set_locale_with_localizer # this is what t() triggers
      I18n.locale.to_s.should == "es"
      course_model(:locale => "ru")
      controller.stubs(:named_context_url).with(@course, :context_url).returns('')
      controller.stubs(:params).returns({:course_id => @course.id})
      controller.stubs(:api_request?).returns(false)
      controller.stubs(:session).returns({})
      controller.stubs(:js_env).returns({})
      controller.send(:get_context)
      controller.instance_variable_get(:@context).should == @course
      I18n.set_locale_with_localizer # this is what t() triggers
      I18n.locale.to_s.should == "ru"
    end
  end

  describe 'rescue_action_in_public' do
    context 'sharding' do
      specs_require_sharding

      before do
        @shard2.activate do
          @account = account_model
        end
      end

      it 'should log error reports to the domain_root_accounts shard' do
        ErrorReport.stubs(:log_exception).returns(ErrorReport.new)
        ErrorReport.stubs(:useful_http_env_stuff_from_request).returns({})

        req = mock()
        req.stubs(:url).returns('url')
        req.stubs(:headers).returns({})
        req.stubs(:request_method_symbol).returns(:get)
        req.stubs(:format).returns('format')

        controller.stubs(:request).returns(req)
        controller.stubs(:api_request?).returns(false)
        controller.stubs(:render_rescue_action)

        controller.instance_variable_set(:@domain_root_account, @account)

        @shard2.expects(:activate).twice

        controller.send(:rescue_action_in_public, Exception.new)
      end
    end
  end
end

describe WikiPagesController do
  describe "set_js_rights" do
    it "should populate js_env with policy rights" do
      controller.stubs(:default_url_options).returns({})

      course_with_teacher_logged_in :active_all => true
      controller.instance_variable_set(:@context, @course)

      get 'pages_index', :course_id => @course.id

      controller.js_env.should include(:WIKI_RIGHTS)
      controller.js_env[:WIKI_RIGHTS].should == Hash[@course.wiki.check_policy(@teacher).map { |right| [right, true] }]
    end
  end
end
