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

describe ApplicationController do

  before :each do
    controller.stubs(:request).returns(stub(:host_with_port => "www.example.com",
                                            :host => "www.example.com",
                                            :headers => {}, :format => stub(:html? => true)))
  end

  describe "#twitter_connection" do
    it "uses current user if available" do
      mock_current_user = mock()
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdocs_access_token_token] = "session_token"
      session[:oauth_gdocs_access_token_secret] = "sesion_secret"

      mock_user_services = mock("mock_user_services")
      mock_current_user.expects(:user_services).returns(mock_user_services)
      mock_user_services.expects(:where).with(service: "twitter").returns(stub(first: mock(token: "current_user_token", secret: "current_user_secret")))

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

  describe "#google_drive_connection" do
    before :each do
      settings_mock = mock()
      settings_mock.stubs(:settings).returns({})
      Canvas::Plugin.stubs(:find).returns(settings_mock)
    end

    it "uses @real_current_user first" do
      mock_real_current_user = mock()
      mock_current_user = mock()
      controller.instance_variable_set(:@real_current_user, mock_real_current_user)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      Rails.cache.expects(:fetch).with(['google_drive_tokens', mock_real_current_user].cache_key).returns(["real_current_user_token", "real_current_user_secret"])

      GoogleDrive::Connection.expects(:new).with("real_current_user_token", "real_current_user_secret", 30)

      controller.send(:google_drive_connection)
    end

    it "uses @current_user second" do
      mock_current_user = mock()
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      Rails.cache.expects(:fetch).with(['google_drive_tokens', mock_current_user].cache_key).returns(["current_user_token", "current_user_secret"])

      GoogleDrive::Connection.expects(:new).with("current_user_token", "current_user_secret", 30)
      controller.send(:google_drive_connection)
    end

    it "queries user services if token isn't in the cache" do
      mock_current_user = mock()
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      mock_user_services = mock("mock_user_services")
      mock_current_user.expects(:user_services).returns(mock_user_services)
      mock_user_services.expects(:where).with(service: "google_drive").returns(stub(first: mock(token: "user_service_token", secret: "user_service_secret")))

      GoogleDrive::Connection.expects(:new).with("user_service_token", "user_service_secret", 30)
      controller.send(:google_drive_connection)
    end

    it "uses the session values if no users are set" do
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, nil)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      GoogleDrive::Connection.expects(:new).with("session_token", "sesion_secret", 30)

      controller.send(:google_drive_connection)
    end
  end

  describe "js_env" do
    before do
      controller.stubs(:api_request?).returns(false)
    end

    it "should set items" do
      HostUrl.expects(:file_host).with(Account.default, "www.example.com").returns("files.example.com")
      controller.js_env :FOO => 'bar'
      expect(controller.js_env[:FOO]).to eq 'bar'
      expect(controller.js_env[:files_domain]).to eq 'files.example.com'
    end

    it "should auto-set timezone and locale" do
      I18n.locale = :fr
      Time.zone = 'Alaska'
      expect(@controller.js_env[:LOCALE]).to eq 'fr'
      expect(@controller.js_env[:BIGEASY_LOCALE]).to eq 'fr_FR'
      expect(@controller.js_env[:FULLCALENDAR_LOCALE]).to eq 'fr'
      expect(@controller.js_env[:MOMENT_LOCALE]).to eq 'fr'
      expect(@controller.js_env[:TIMEZONE]).to eq 'America/Juneau'
    end

    it "sets the contextual timezone from the context" do
      Time.zone = "Mountain Time (US & Canada)"
      controller.instance_variable_set(:@context, stub(time_zone: Time.zone, asset_string: "", class_name: nil))
      controller.js_env({})
      expect(controller.js_env[:CONTEXT_TIMEZONE]).to eq 'America/Denver'
    end

    it "should allow multiple items" do
      controller.js_env :A => 'a', :B => 'b'
      expect(controller.js_env[:A]).to eq 'a'
      expect(controller.js_env[:B]).to eq 'b'
    end

    it "should not allow overwriting a key" do
      controller.js_env :REAL_SLIM_SHADY => 'please stand up'
      expect { controller.js_env(:REAL_SLIM_SHADY => 'poser') }.to raise_error
    end

    it 'gets appropriate settings from the root account' do
      root_account = stub(global_id: 1, feature_enabled?: false, open_registration?: true, settings: {})
      HostUrl.stubs(file_host: 'files.example.com')
      controller.instance_variable_set(:@domain_root_account, root_account)
      expect(controller.js_env[:SETTINGS][:open_registration]).to be_truthy
    end

    context "sharding" do
      specs_require_sharding

      it "should set the global id for the domain_root_account" do
        controller.instance_variable_set(:@domain_root_account, Account.default)
        expect(controller.js_env[:DOMAIN_ROOT_ACCOUNT_ID]).to eq Account.default.global_id
      end
    end
  end

  describe "clean_return_to" do
    before do
      req = stub('request obj', :protocol => 'https://', :host_with_port => 'canvas.example.com')
      controller.stubs(:request).returns(req)
    end

    it "should build from a simple path" do
      expect(controller.send(:clean_return_to, "/calendar")).to eq "https://canvas.example.com/calendar"
    end

    it "should build from a full url" do
      # ... but always use the request host/protocol, not the given
      expect(controller.send(:clean_return_to, "http://example.org/a/b?a=1&b=2#test")).to eq "https://canvas.example.com/a/b?a=1&b=2#test"
    end

    it "should reject disallowed paths" do
      expect(controller.send(:clean_return_to, "ftp://example.com/javascript:hai")).to be_nil
    end
  end

  describe "#reject!" do
    it "sets the message and status in the error json" do
      expect { controller.reject!('test message', :not_found) }.to(raise_error(RequestError) do |e|
        expect(e.message).to eq 'test message'
        expect(e.error_json[:message]).to eq 'test message'
        expect(e.error_json[:status]).to eq 'not_found'
        expect(e.response_status).to eq 404
      end)
    end

    it "defaults status to 'bad_request'" do
      expect { controller.reject!('test message') }.to(raise_error(RequestError) do |e|
        expect(e.error_json[:status]).to eq 'bad_request'
        expect(e.response_status).to eq 400
      end)
    end

    it "accepts numeric status codes" do
      expect { controller.reject!('test message', 403) }.to(raise_error(RequestError) do |e|
        expect(e.error_json[:status]).to eq 'forbidden'
        expect(e.response_status).to eq 403
      end)
    end

    it "accepts symbolic status codes" do
      expect { controller.reject!('test message', :service_unavailable) }.to(raise_error(RequestError) do |e|
        expect(e.error_json[:status]).to eq 'service_unavailable'
        expect(e.response_status).to eq 503
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
      expect(url).to match /myfiles/
    end

    it "should include :download=>1 in inline urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      controller.stubs(:named_context_url).returns('')
      url = controller.send(:safe_domain_file_url, @attachment)
      expect(url).to match(/[\?&]download=1(&|$)/)
    end

    it "should not include :download=>1 in download urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      controller.stubs(:named_context_url).returns('')
      url = controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
      expect(url).not_to match(/[\?&]download=1(&|$)/)
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
      expect(controller.instance_variable_get(:@context)).to eq @user
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
      expect(controller.instance_variable_get(:@context)).to eq @section
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

      req.stubs(:host).returns('www.example.com')
      req.stubs(:headers).returns({})
      req.stubs(:format).returns(stub(:html? => true))
      controller.stubs(:request).returns(req)
      controller.send(:assign_localizer)
      I18n.set_locale_with_localizer # this is what t() triggers
      expect(I18n.locale.to_s).to eq "es"
      course_model(:locale => "ru")
      controller.stubs(:named_context_url).with(@course, :context_url).returns('')
      controller.stubs(:params).returns({:course_id => @course.id})
      controller.stubs(:api_request?).returns(false)
      controller.stubs(:session).returns({})
      controller.stubs(:js_env).returns({})
      controller.send(:get_context)
      expect(controller.instance_variable_get(:@context)).to eq @course
      I18n.set_locale_with_localizer # this is what t() triggers
      expect(I18n.locale.to_s).to eq "ru"
    end
  end

  context 'require_context' do
    it "properly requires account context" do
      controller.instance_variable_set(:@context, Account.default)
      expect(controller.send(:require_account_context)).to be_truthy
      course_model
      controller.instance_variable_set(:@context, @course)
      expect{controller.send(:require_account_context)}.to raise_error
    end

    it "properly requires course context" do
      course_model
      controller.instance_variable_set(:@context, @course)
      expect(controller.send(:require_course_context)).to be_truthy
      controller.instance_variable_set(:@context, Account.default)
      expect{controller.send(:require_course_context)}.to raise_error
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
        report = ErrorReport.new
        ErrorReport.stubs(:log_exception).returns(report)
        ErrorReport.stubs(:find).returns(report)
        Canvas::Errors::Info.stubs(:useful_http_env_stuff_from_request).returns({})

        req = mock()
        req.stubs(:url).returns('url')
        req.stubs(:headers).returns({})
        req.stubs(:authorization).returns(nil)
        req.stubs(:request_method_symbol).returns(:get)
        req.stubs(:format).returns('format')

        controller.stubs(:request).returns(req)
        controller.stubs(:api_request?).returns(false)
        controller.stubs(:render_rescue_action)

        controller.instance_variable_set(:@domain_root_account, @account)

        @shard2.expects(:activate)

        controller.send(:rescue_action_in_public, Exception.new)
      end
    end
  end

  describe 'content_tag_redirect' do

    it 'redirects for lti_message_handler' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Lti::MessageHandler')
      controller.expects(:named_context_url).with(Account.default, :context_basic_lti_launch_request_url, 44, {:module_item_id => 42, resource_link_fragment: 'ContentTag:42'}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for an assignment' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Assignment')
      controller.expects(:named_context_url).with(Account.default, :context_assignment_url, 44, {:module_item_id => 42}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a quiz' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: true, content_type: 'Quizzes::Quiz')
      controller.expects(:named_context_url).with(Account.default, :context_quiz_url, 44, {:module_item_id => 42}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a discussion topic' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'DiscussionTopic')
      controller.expects(:named_context_url).with(Account.default, :context_discussion_topic_url, 44, {:module_item_id => 42}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a wikipage' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'WikiPage', content: {})
      controller.expects(:polymorphic_url).with([Account.default, tag.content], {:module_item_id => 42}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a rubric' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Rubric')
      controller.expects(:named_context_url).with(Account.default, :context_rubric_url, 44, {:module_item_id => 42}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a question bank' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'AssessmentQuestionBank')
      controller.expects(:named_context_url).with(Account.default, :context_question_bank_url, 44, {:module_item_id => 42}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for an attachment' do
      tag = mock()
      tag.stubs(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Attachment')
      controller.expects(:named_context_url).with(Account.default, :context_file_url, 44, {:module_item_id => 42}).returns('nil')
      controller.stubs(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    context 'ContextExternalTool' do

      let(:course){ course_model }

      let(:tool) do
        tool = course.context_external_tools.new(
          name: "bob",
          consumer_key: "bob",
          shared_secret: "bob",
          tool_id: 'some_tool',
          privacy_level: 'public'
        )
        tool.url = "http://www.example.com/basic_lti"
        tool.resource_selection = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :selection_width => 400,
          :selection_height => 400}
        tool.save!
        tool
      end

      let(:content_tag) { ContentTag.create(content: tool, url: tool.url)}

      it 'returns the full path for the redirect url' do
        controller.expects(:named_context_url).with(course, :context_url, {:include_host => true})
        controller.expects(:named_context_url).with(course, :context_external_content_success_url, 'external_tool_redirect', {:include_host => true}).returns('wrong_url')
        controller.stubs(:render)
        controller.stubs(js_env:[])
        controller.instance_variable_set(:"@context", course)
        controller.send(:content_tag_redirect, course, content_tag, nil)
      end

      it 'sets the resource_link_id correctly' do
        controller.stubs(:named_context_url).returns('wrong_url')
        controller.stubs(:render)
        controller.stubs(js_env:[])
        controller.instance_variable_set(:"@context", course)
        content_tag.stubs(:id).returns(42)
        controller.send(:content_tag_redirect, course, content_tag, nil)
        expect(assigns[:lti_launch].params["resource_link_id"]).to eq 'e62d81a8a1587cdf9d3bbc3de0ef303d6bc70d78'
      end

    end

  end

  describe 'external_tools_display_hashes' do
    it 'returns empty array if context is group' do
      @course = course_model
      @group = @course.groups.create!(:name => "some group")
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret", :url => "http://example.com")
      tool.account_navigation = {:url => "http://example.com", :icon_url => "http://example.com", :enabled => true}
      tool.save!

      controller.stubs(:polymorphic_url).returns("http://example.com")
      external_tools = controller.external_tools_display_hashes(:account_navigation, @group)

      expect(external_tools).to eq([])
    end

    it 'returns array of tools if context is not group' do
      @course = course_model
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret", :url => "http://example.com")
      tool.account_navigation = {:url => "http://example.com", :icon_url => "http://example.com", :enabled => true, :canvas_icon_class => 'icon-commons'}
      tool.save!

      controller.stubs(:polymorphic_url).returns("http://example.com")
      external_tools = controller.external_tools_display_hashes(:account_navigation, @course)

      expect(external_tools).to eq([{:title=>"bob", :base_url=>"http://example.com", :icon_url=>"http://example.com", :canvas_icon_class => 'icon-commons'}])
    end
  end

  describe 'external_tool_display_hash' do
    def tool_settings(setting, include_class=false)
      settings_hash = {
        url: "http://example.com/?#{setting.to_s}",
        icon_url: "http://example.com/icon.png?#{setting.to_s}",
        enabled: true
      }

      settings_hash[:canvas_icon_class] = "icon-#{setting.to_s}" if include_class
      settings_hash
    end

    before :once do
      @course = course_model
      @group = @course.groups.create!(:name => "some group")
      @tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret", :url => "http://example.com")

      @tool_settings = [
        :user_navigation, :course_navigation, :account_navigation, :resource_selection,
        :editor_button, :homework_submission, :migration_selection, :course_home_sub_navigation,
        :course_settings_sub_navigation, :global_navigation,
        :assignment_menu, :file_menu, :discussion_topic_menu, :module_menu, :quiz_menu, :wiki_page_menu,
        :tool_configuration, :link_selection, :assignment_selection, :post_grades
      ]

      @tool_settings.each do |setting|
        @tool.send("#{setting}=", tool_settings(setting))
      end
      @tool.save!
    end

    before :each do
      controller.stubs(:request).returns(ActionDispatch::TestRequest.new)
      controller.instance_variable_set(:@context, @course)
    end

    it 'returns a hash' do
      hash = controller.external_tool_display_hash(@tool, :account_navigation)
      left_over_keys = hash.keys - [:base_url, :title, :icon_url, :canvas_icon_class]
      expect(left_over_keys).to eq []
    end

    it 'returns a hash' do
      hash = controller.external_tool_display_hash(@tool, :account_navigation)
      left_over_keys = hash.keys - [:base_url, :title, :icon_url, :canvas_icon_class]
      expect(left_over_keys).to eq []
    end

    it 'all settings are correct' do
      @tool_settings.each do |setting|
        hash = controller.external_tool_display_hash(@tool, setting)
        expect(hash[:base_url]).to eq "http://test.host/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=#{setting.to_s}"
        expect(hash[:icon_url]).to eq "http://example.com/icon.png?#{setting.to_s}"
        expect(hash[:canvas_icon_class]).to be nil
      end
    end

    it 'all settings return canvas_icon_class if set' do
      @tool_settings.each do |setting|
        @tool.send("#{setting}=", tool_settings(setting, true))
        @tool.save!

        hash = controller.external_tool_display_hash(@tool, setting)
        expect(hash[:base_url]).to eq "http://test.host/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=#{setting.to_s}"
        expect(hash[:icon_url]).to eq "http://example.com/icon.png?#{setting.to_s}"
        expect(hash[:canvas_icon_class]).to eq "icon-#{setting.to_s}"
      end
    end
  end

  describe 'verify_authenticity_token' do
    before :each do
      # default setup is a protected non-GET non-API session-authenticated request with bogus tokens
      cookies = ActionDispatch::Cookies::CookieJar.new(nil)
      controller.allow_forgery_protection = true
      controller.request.stubs(:cookie_jar).returns(cookies)
      controller.request.stubs(:get?).returns(false)
      controller.request.stubs(:head?).returns(false)
      controller.request.stubs(:path).returns('/non-api/endpoint')
      controller.instance_variable_set(:@pseudonym_session, "session-authenticated")
      controller.params[controller.request_forgery_protection_token] = "bogus"
      controller.request.headers['X-CSRF-Token'] = "bogus"
    end

    it "should raise InvalidAuthenticityToken with invalid tokens" do
      expect{ controller.send(:verify_authenticity_token) }.to raise_exception(ActionController::InvalidAuthenticityToken)
    end

    it "should not raise with valid token" do
      controller.request.headers['X-CSRF-Token'] = controller.form_authenticity_token
      expect{ controller.send(:verify_authenticity_token) }.not_to raise_exception
    end

    it "should still raise on session-authenticated api request with invalid tokens" do
      controller.request.stubs(:path).returns('/api/endpoint')
      expect{ controller.send(:verify_authenticity_token) }.to raise_exception(ActionController::InvalidAuthenticityToken)
    end

    it "should not raise on token-authenticated api request despite invalid tokens" do
      controller.request.stubs(:path).returns('/api/endpoint')
      controller.instance_variable_set(:@pseudonym_session, nil)
      expect{ controller.send(:verify_authenticity_token) }.not_to raise_exception
    end
  end
end

describe ApplicationController do
  describe "flash_notices" do
    it 'should return notice text for each type' do
      [:error, :warning, :info, :notice].each do |type|
        flash[type] = type.to_s
      end
      expect(controller.send(:flash_notices)).to match_array([
         {type: 'error', content: 'error', icon: 'warning'},
         {type: 'warning', content: 'warning', icon: 'warning'},
         {type: 'info', content: 'info', icon: 'info'},
         {type: 'success', content: 'notice', icon: 'check'}
     ])
    end

    it 'should wrap html notification text in an object' do
      flash[:html_notice] = '<p>hello</p>'
      expect(controller.send(:flash_notices)).to match_array([
        {type: 'success', content: {html: '<p>hello</p>'}, icon: 'check'}
      ])
    end
  end

  describe "#ms_office?" do
    it "detects Word 2011 for mac" do
      controller.request.user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X) Word/14.57.0'
      expect(controller.send(:ms_office?)).to eq true
    end
  end

  describe "#get_all_pertinent_contexts" do
    it "doesn't touch the database if there are no valid courses" do
      user
      controller.instance_variable_set(:@context, @user)

      course_scope = stub('current_enrollments')
      course_scope.stubs(:current).returns(course_scope)
      course_scope.stubs(:shard).returns(course_scope)
      course_scope.stubs(:preload).returns(course_scope)
      course_scope.expects(:none).returns(Enrollment.none)
      @user.stubs(:enrollments).returns(course_scope)
      controller.send(:get_all_pertinent_contexts, only_contexts: 'Group_1')
    end

    it "doesn't touch the database if there are no valid groups" do
      user
      controller.instance_variable_set(:@context, @user)

      group_scope = stub('current_groups')
      group_scope.expects(:none).returns(Group.none)
      @user.stubs(:current_groups).returns(group_scope)
      controller.send(:get_all_pertinent_contexts, include_groups: true, only_contexts: 'Course_1')
    end
  end

  describe '#discard_flash_if_xhr' do
    before do
      flash[:notice] = 'A flash notice'
    end
    subject(:discard) do
      flash.instance_variable_get('@discard')
    end

    it 'sets flash discard if request is xhr' do
      controller.request.stubs(xhr?: true)

      expect(discard).to be_empty, 'precondition'
      controller.send(:discard_flash_if_xhr)
      expect(discard).to all(match(/^notice$/))
    end

    it 'sets flash discard if request format is text/plain' do
      controller.request.stubs(xhr?: false, format: 'text/plain')

      expect(discard).to be_empty, 'precondition'
      controller.send(:discard_flash_if_xhr)
      expect(discard).to all(match(/^notice$/))
    end

    it 'leaves flash as is if conditions are not met' do
      controller.request.stubs(xhr?: false, format: 'text/html')

      expect(discard).to be_empty, 'precondition'
      controller.send(:discard_flash_if_xhr)
      expect(discard).to be_empty
    end
  end
end

describe WikiPagesController do
  describe "set_js_rights" do
    it "should populate js_env with policy rights" do
      controller.stubs(:default_url_options).returns({})

      course_with_teacher_logged_in :active_all => true
      controller.instance_variable_set(:@context, @course)

      get 'index', :course_id => @course.id

      expect(controller.js_env).to include(:WIKI_RIGHTS)
      expect(controller.js_env[:WIKI_RIGHTS].symbolize_keys).to eq Hash[@course.wiki.check_policy(@teacher).map { |right| [right, true] }]
    end
  end
end
