#
# Copyright (C) 2011 - present Instructure, Inc.
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

require_relative '../spec_helper'
require_relative '../lti_1_3_spec_helper'

RSpec.describe ApplicationController do
  before :each do
    request_double = double(
      host_with_port: "www.example.com",
      host: "www.example.com",
      headers: {},
      format: double(:html? => true),
      user_agent: nil,
      remote_ip: '0.0.0.0',
      base_url: 'https://canvas.test'
    )
    allow(controller).to receive(:request).and_return(request_double)
  end

  describe "#google_drive_connection" do
    before :each do
      settings_mock = double()
      allow(settings_mock).to receive(:settings).and_return({})
      allow(Canvas::Plugin).to receive(:find).and_return(settings_mock)
    end

    it "uses @real_current_user first" do
      mock_real_current_user = double()
      mock_current_user = double()
      controller.instance_variable_set(:@real_current_user, mock_real_current_user)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      expect(Rails.cache).to receive(:fetch).with(['google_drive_tokens', mock_real_current_user].cache_key).and_return(["real_current_user_token", "real_current_user_secret"])

      expect(GoogleDrive::Connection).to receive(:new).with("real_current_user_token", "real_current_user_secret", 30)

      Setting.skip_cache do
        controller.send(:google_drive_connection)
      end
    end

    it "uses @current_user second" do
      mock_current_user = double()
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      expect(Rails.cache).to receive(:fetch).with(['google_drive_tokens', mock_current_user].cache_key).and_return(["current_user_token", "current_user_secret"])

      expect(GoogleDrive::Connection).to receive(:new).with("current_user_token", "current_user_secret", 30)
      Setting.skip_cache do
        controller.send(:google_drive_connection)
      end
    end

    it "queries user services if token isn't in the cache" do
      mock_current_user = double()
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, mock_current_user)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      mock_user_services = double("mock_user_services")
      expect(mock_current_user).to receive(:user_services).and_return(mock_user_services)
      expect(mock_user_services).to receive(:where).with(service: "google_drive").and_return(double(first: double(token: "user_service_token", secret: "user_service_secret")))

      expect(GoogleDrive::Connection).to receive(:new).with("user_service_token", "user_service_secret", 30)
      Setting.skip_cache do
        controller.send(:google_drive_connection)
      end
    end

    it "uses the session values if no users are set" do
      controller.instance_variable_set(:@real_current_user, nil)
      controller.instance_variable_set(:@current_user, nil)
      session[:oauth_gdrive_refresh_token] = "session_token"
      session[:oauth_gdrive_access_token] = "sesion_secret"

      expect(GoogleDrive::Connection).to receive(:new).with("session_token", "sesion_secret", 30)

      controller.send(:google_drive_connection)
    end
  end

  describe "js_env" do
    before do
      allow(controller).to receive(:api_request?).and_return(false)
    end

    it "should set items" do
      expect(HostUrl).to receive(:file_host).with(Account.default, "www.example.com").and_return("files.example.com")
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
      controller.instance_variable_set(:@context, double(time_zone: Time.zone, asset_string: "", class_name: nil))
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
      expect { controller.js_env(:REAL_SLIM_SHADY => 'poser') }.to raise_error("js_env key REAL_SLIM_SHADY is already taken")
    end

    it "should overwrite a key if told explicitly to do so" do
      controller.js_env :REAL_SLIM_SHADY => 'please stand up'
      controller.js_env({:REAL_SLIM_SHADY => 'poser'}, true)
      expect(controller.js_env[:REAL_SLIM_SHADY]).to eq 'poser'
    end

    it 'gets appropriate settings from the root account' do
      root_account = double(global_id: 1, feature_enabled?: false, open_registration?: true, settings: {})
      allow(HostUrl).to receive_messages(file_host: 'files.example.com')
      controller.instance_variable_set(:@domain_root_account, root_account)
      expect(controller.js_env[:SETTINGS][:open_registration]).to be_truthy
    end

    it 'sets LTI_LAUNCH_FRAME_ALLOWANCES' do
      expect(@controller.js_env[:LTI_LAUNCH_FRAME_ALLOWANCES]).to match_array [
        "geolocation *",
        "microphone *",
        "camera *",
        "midi *",
        "encrypted-media *"
      ]
    end

    it 'sets DEEP_LINKING_POST_MESSAGE_ORIGIN' do
      expect(@controller.js_env[:DEEP_LINKING_POST_MESSAGE_ORIGIN]).to eq @controller.request.base_url
    end

    context "sharding" do
      require_relative '../sharding_spec_helper'
      specs_require_sharding

      it "should set the global id for the domain_root_account" do
        controller.instance_variable_set(:@domain_root_account, Account.default)
        expect(controller.js_env[:DOMAIN_ROOT_ACCOUNT_ID]).to eq Account.default.global_id
      end
    end

    it 'matches against weird http_accept headers' do
      # sometimes we get browser requests for an endpoint that just pass */* as
      # the accept header. I don't think we can simulate this in a test, so
      # this test just verifies the condition in js_env works across updates
      expect(Mime::Type.new("*/*") == "*/*").to be_truthy
    end
  end

  describe "clean_return_to" do
    before do
      req = double('request obj', :protocol => 'https://', :host_with_port => 'canvas.example.com')
      allow(controller).to receive(:request).and_return(req)
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
      allow(controller).to receive(:request).and_return(double("request", :protocol => '', :host_with_port => ''))

      @common_params = { :only_path => true }
    end

    it "should include inline=1 in url by default" do
      expect(controller).to receive(:file_download_url).
        with(@attachment, @common_params.merge(:inline => 1)).
        and_return('')
      expect(HostUrl).to receive(:file_host_with_shard).with(42, '').and_return(['myfiles', Shard.default])
      controller.instance_variable_set(:@domain_root_account, 42)
      url = controller.send(:safe_domain_file_url, @attachment)
      expect(url).to match /myfiles/
    end

    it "should include :download=>1 in inline urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      allow(controller).to receive(:named_context_url).and_return('')
      url = controller.send(:safe_domain_file_url, @attachment)
      expect(url).to match(/[\?&]download=1(&|$)/)
    end

    it "should not include :download=>1 in download urls for relative contexts" do
      controller.instance_variable_set(:@context, @attachment.context)
      allow(controller).to receive(:named_context_url).and_return('')
      url = controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
      expect(url).not_to match(/[\?&]download=1(&|$)/)
    end

    it "should include download_frd=1 and not include inline=1 in url when specified as for download" do
      expect(controller).to receive(:file_download_url).
        with(@attachment, @common_params.merge(:download_frd => 1)).
        and_return('')
      controller.send(:safe_domain_file_url, @attachment, nil, nil, true)
    end

    it "prepends a unique file subdomain if configured" do
      override_dynamic_settings(private: { canvas: { attachment_specific_file_domain: true } }) do
        expect(controller).to receive(:file_download_url).
          with(@attachment, @common_params.merge(:inline => 1)).
          and_return("/files/#{@attachment.id}")
        expect(controller.send(:safe_domain_file_url, @attachment, ['canvasfiles.com', Shard.default], nil, false)).to eq "a#{@attachment.shard.id}-#{@attachment.id}.canvasfiles.com/files/#{@attachment.id}"
      end
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
      allow(controller).to receive(:named_context_url).with(@user, :context_url).and_return('')
      allow(controller).to receive(:params).and_return({:user_id => 'sis_user_id:test1'})
      allow(controller).to receive(:api_request?).and_return(true)
      controller.send(:get_context)
      expect(controller.instance_variable_get(:@context)).to eq @user
    end

    it "should find course section with api_find for api requests" do
      course_model
      @section = @course.course_sections.first
      @section.update_attribute(:sis_source_id, 'test1')
      controller.instance_variable_set(:@domain_root_account, Account.default)
      allow(controller).to receive(:named_context_url).with(@section, :context_url).and_return('')
      allow(controller).to receive(:params).and_return({:course_section_id => 'sis_section_id:test1'})
      allow(controller).to receive(:api_request?).and_return(true)
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
      controller.send(:assign_localizer)
      I18n.set_locale_with_localizer # this is what t() triggers
      expect(I18n.locale.to_s).to eq "es"
      course_model(:locale => "ru")
      allow(controller).to receive(:named_context_url).with(@course, :context_url).and_return('')
      allow(controller).to receive(:params).and_return({:course_id => @course.id})
      allow(controller).to receive(:api_request?).and_return(false)
      allow(controller).to receive(:session).and_return({})
      allow(controller).to receive(:js_env).and_return({})
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
      expect{controller.send(:require_account_context)}.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "properly requires course context" do
      course_model
      controller.instance_variable_set(:@context, @course)
      expect(controller.send(:require_course_context)).to be_truthy
      controller.instance_variable_set(:@context, Account.default)
      expect{controller.send(:require_course_context)}.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'log_participation' do
    before :once do
      course_model
      student_in_course
      attachment_model(context: @course)
    end

    it "should find file's context instead of user" do
      controller.instance_variable_set(:@domain_root_account, Account.default)
      controller.instance_variable_set(:@context, @student)
      controller.instance_variable_set(:@accessed_asset, {level: 'participate', code: @attachment.asset_string, category: 'files'})
      allow(controller).to receive(:named_context_url).with(@attachment, :context_url).and_return("/files/#{@attachment.id}")
      allow(controller).to receive(:params).and_return({file_id: @attachment.id, id: @attachment.id})
      allow(controller.request).to receive(:path).and_return("/files/#{@attachment.id}")
      controller.send(:log_participation, @student)
      expect(AssetUserAccess.where(user: @student, asset_code: @attachment.asset_string).take.context).to eq @course
    end

    it 'should not error on non-standard context for file' do
      controller.instance_variable_set(:@domain_root_account, Account.default)
      controller.instance_variable_set(:@context, @student)
      controller.instance_variable_set(:@accessed_asset, {level: 'participate', code: @attachment.asset_string, category: 'files'})
      allow(controller).to receive(:named_context_url).with(@attachment, :context_url).and_return("/files/#{@attachment.id}")
      allow(controller).to receive(:params).and_return({file_id: @attachment.id, id: @attachment.id})
      allow(controller.request).to receive(:path).and_return("/files/#{@attachment.id}")
      assignment_model(course: @course)
      @attachment.context = @assignment
      @attachment.save!
      expect {controller.send(:log_participation, @student)}.not_to raise_error
    end
  end

  describe 'rescue_action_in_public' do
    context 'sharding' do
      require_relative '../sharding_spec_helper'
      specs_require_sharding

      before do
        @shard2.activate do
          @account = account_model
        end
      end

      it 'should log error reports to the domain_root_accounts shard' do
        report = ErrorReport.new
        allow(ErrorReport).to receive(:log_exception).and_return(report)
        allow(ErrorReport).to receive(:find).and_return(report)
        allow(Canvas::Errors::Info).to receive(:useful_http_env_stuff_from_request).and_return({})

        req = double()
        allow(req).to receive(:url).and_return('url')
        allow(req).to receive(:headers).and_return({})
        allow(req).to receive(:authorization).and_return(nil)
        allow(req).to receive(:request_method_symbol).and_return(:get)
        allow(req).to receive(:format).and_return('format')

        allow(controller).to receive(:request).and_return(req)
        allow(controller).to receive(:api_request?).and_return(false)
        allow(controller).to receive(:render_rescue_action)

        controller.instance_variable_set(:@domain_root_account, @account)

        expect(@shard2).to receive(:activate)

        controller.send(:rescue_action_in_public, Exception.new)
      end
    end
  end

  describe 'content_tag_redirect' do

    it 'redirects for lti_message_handler' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Lti::MessageHandler')
      expect(controller).to receive(:named_context_url).with(Account.default, :context_basic_lti_launch_request_url, 44, {:module_item_id => 42, resource_link_fragment: 'ContentTag:42'}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for an assignment' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Assignment')
      expect(controller).to receive(:named_context_url).with(Account.default, :context_assignment_url, 44, {:module_item_id => 42}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a quiz' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: true, content_type: 'Quizzes::Quiz')
      expect(controller).to receive(:named_context_url).with(Account.default, :context_quiz_url, 44, {:module_item_id => 42}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a discussion topic' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'DiscussionTopic')
      expect(controller).to receive(:named_context_url).with(Account.default, :context_discussion_topic_url, 44, {:module_item_id => 42}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a wikipage' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'WikiPage', content: {})
      expect(controller).to receive(:polymorphic_url).with([Account.default, tag.content], {:module_item_id => 42}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a rubric' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Rubric')
      expect(controller).to receive(:named_context_url).with(Account.default, :context_rubric_url, 44, {:module_item_id => 42}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for a question bank' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'AssessmentQuestionBank')
      expect(controller).to receive(:named_context_url).with(Account.default, :context_question_bank_url, 44, {:module_item_id => 42}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    it 'redirects for an attachment' do
      tag = double()
      allow(tag).to receive_messages(id: 42, content_id: 44, content_type_quiz?: false, content_type: 'Attachment')
      expect(controller).to receive(:named_context_url).with(Account.default, :context_file_url, 44, {:module_item_id => 42}).and_return('nil')
      allow(controller).to receive(:redirect_to)
      controller.send(:content_tag_redirect, Account.default, tag, nil)
    end

    context 'ContextExternalTool' do

      let(:course){ course_model }
      let_once(:dev_key) { DeveloperKey.create! }

      let(:tool) do
        tool = course.context_external_tools.new(
          name: "bob",
          consumer_key: "bob",
          shared_secret: "bob",
          tool_id: 'some_tool',
          privacy_level: 'public',
          developer_key: dev_key
        )
        tool.url = "http://www.example.com/basic_lti"
        tool.resource_selection = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :selection_width => 400,
          :selection_height => 400}
        tool.settings[:selection_width] = 500
        tool.settings[:selection_height] = 300
        tool.settings[:custom_fields] = {"test_token"=>"$com.instructure.PostMessageToken"}
        tool.save!
        tool
      end

      let(:content_tag) { ContentTag.create(content: tool, url: tool.url)}

      context 'display type' do
        before do
          allow(controller).to receive(:named_context_url).and_return('wrong_url')
          allow(controller).to receive(:render)
          allow(controller).to receive_messages(js_env:[])
          controller.instance_variable_set(:"@context", course)
          allow(content_tag).to receive(:id).and_return(42)
          allow(controller).to receive(:require_user) { user_model }
          allow(controller).to receive(:lti_launch_params) {{}}
          content_tag.update_attributes!(context: assignment_model)
        end

        context 'display_type == "full_width' do
          before do
            tool.settings[:assignment_selection] = { "display_type" => "full_width" }
            tool.save!
          end

          it 'uses the tool setting display type if the "display" parameter is absent' do
            expect(Lti::AppUtil).to receive(:display_template).with('full_width')
            controller.send(:content_tag_redirect, course, content_tag, nil)
          end

          it 'does not use the assignment lti header' do
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:prepend_template]).to be_blank
          end

          it 'does not display the assignment edit sidebar' do
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:append_template]).to_not be_present
          end
        end

        it 'gives priority to the "display" parameter' do
          expect(Lti::AppUtil).to receive(:display_template).with('borderless')
          controller.params['display'] = 'borderless'
          controller.send(:content_tag_redirect, course, content_tag, nil)
        end

        it 'does not raise an error if the display type of the placement is not set' do
          tool.settings[:assignment_selection] = {}
          tool.save!
          expect do
            controller.send(:content_tag_redirect, course, content_tag, nil)
          end.not_to raise_exception
        end

        it 'does display the assignment lti header if the display type is not "full_width"' do
          controller.send(:content_tag_redirect, course, content_tag, nil)
          expect(assigns[:prepend_template]).to be_present
        end

        it 'does display the assignment edit sidebar if display type is not "full_width"' do
          controller.send(:content_tag_redirect, course, content_tag, nil)
          expect(assigns[:append_template]).to be_present
        end
      end

      context 'lti version' do
        let_once(:user) { user_model }

        before do
          allow(controller).to receive(:named_context_url).and_return('wrong_url')
          allow(controller).to receive(:lti_grade_passback_api_url).and_return('wrong_url')
          allow(controller).to receive(:blti_legacy_grade_passback_api_url).and_return('wrong_url')
          allow(controller).to receive(:lti_turnitin_outcomes_placement_url).and_return('wrong_url')

          allow(controller).to receive(:render)
          allow(controller).to receive_messages(js_env:[])
          controller.instance_variable_set(:"@context", course)
          allow(content_tag).to receive(:id).and_return(42)
          allow(controller).to receive(:require_user) { user_model }
          controller.instance_variable_set(:@current_user, user)
          controller.instance_variable_set(:@domain_root_account, course.account)
          content_tag.update_attributes!(context: assignment_model)
        end

        describe 'LTI 1.3' do
          let_once(:developer_key) do
            d = DeveloperKey.create!
            enable_developer_key_account_binding! d
            d
          end
          let_once(:account) { Account.default }

          include_context 'lti_1_3_spec_helper'

          before do
            tool.developer_key = developer_key
            tool.use_1_3 = true
            tool.save!

            assignment = assignment_model(submission_types: 'external_tool', external_tool_tag: content_tag)
            content_tag.update_attributes!(context: assignment)
          end

          shared_examples_for 'a placement that caches the launch' do
            let(:verifier) { "e5e774d015f42370dcca2893025467b414d39009dfe9a55250279cca16f5f3c2704f9c56fef4cea32825a8f72282fa139298cf846e0110238900567923f9d057" }
            let(:redis_key) { "#{course.class.name}:#{Lti::RedisMessageClient::LTI_1_3_PREFIX}#{verifier}" }
            let(:cached_launch) { JSON.parse(Canvas.redis.get(redis_key)) }

            before do
              allow(SecureRandom).to receive(:hex).and_return(verifier)
              controller.send(:content_tag_redirect, course, content_tag, nil)
            end

            it 'caches the LTI 1.3 launch' do
              expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiResourceLinkRequest"
            end

            it 'creates a login message' do
              expect(assigns[:lti_launch].params.keys).to match_array [
                "iss",
                "login_hint",
                "target_link_uri",
                "lti_message_hint"
              ]
            end

            it 'sets the "login_hint" to the current user lti id' do
              expect(assigns[:lti_launch].params['login_hint']).to eq Lti::Asset.opaque_identifier_for(user)
            end
          end

          context 'assignments' do
            it_behaves_like 'a placement that caches the launch'
          end

          context 'module items' do
            before { content_tag.update!(context: course.account) }

            it_behaves_like 'a placement that caches the launch'
          end
          # rubocop:enable RSpec/NestedGroups
        end

        it 'creates a basic lti launch request when tool is not configured to use LTI 1.3' do
          controller.send(:content_tag_redirect, course, content_tag, nil)
          expect(assigns[:lti_launch].params["lti_message_type"]).to eq "basic-lti-launch-request"
        end
      end

      it 'returns the full path for the redirect url' do
        expect(controller).to receive(:named_context_url).with(course, :context_url, {:include_host => true})
        expect(controller).to receive(:named_context_url).with(course, :context_external_content_success_url, 'external_tool_redirect', {:include_host => true}).and_return('wrong_url')
        allow(controller).to receive(:render)
        allow(controller).to receive_messages(js_env:[])
        controller.instance_variable_set(:"@context", course)
        controller.send(:content_tag_redirect, course, content_tag, nil)
      end

      it 'sets the resource_link_id correctly' do
        allow(controller).to receive(:named_context_url).and_return('wrong_url')
        allow(controller).to receive(:render)
        allow(controller).to receive_messages(js_env:[])
        controller.instance_variable_set(:"@context", course)
        allow(content_tag).to receive(:id).and_return(42)
        controller.send(:content_tag_redirect, course, content_tag, nil)
        expect(assigns[:lti_launch].params["resource_link_id"]).to eq 'e62d81a8a1587cdf9d3bbc3de0ef303d6bc70d78'
      end

      it 'sets the post message token' do
        allow(controller).to receive(:named_context_url).and_return('wrong_url')
        allow(controller).to receive(:render)
        allow(controller).to receive_messages(js_env:[])
        controller.instance_variable_set(:"@context", course)
        allow(content_tag).to receive(:id).and_return(42)
        controller.send(:content_tag_redirect, course, content_tag, nil)
        expect(assigns[:lti_launch].params["custom_test_token"]).to be_present
      end

      it 'uses selection_width and selection_height if provided' do
        allow(controller).to receive(:named_context_url).and_return(tool.url)
        allow(controller).to receive(:render)
        allow(controller).to receive_messages(js_env:[])
        controller.instance_variable_set(:"@context", course)
        allow(content_tag).to receive(:id).and_return(42)
        controller.send(:content_tag_redirect, course, content_tag, nil)

        expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq '500px'
        expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq '300px'
      end

      it 'appends px to tool dimensions only when needed' do
        tool.settings = {}
        tool.save!
        content_tag = ContentTag.create(content: tool, url: tool.url)

        allow(controller).to receive(:named_context_url).and_return(tool.url)
        allow(controller).to receive(:render)
        allow(controller).to receive_messages(js_env:[])
        controller.instance_variable_set(:"@context", course)
        allow(content_tag).to receive(:id).and_return(42)
        controller.send(:content_tag_redirect, course, content_tag, nil)

        expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq '100%'
        expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq '100%'
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

      allow(controller).to receive(:polymorphic_url).and_return("http://example.com")
      external_tools = controller.external_tools_display_hashes(:account_navigation, @group)

      expect(external_tools).to eq([])
    end

    it 'returns array of tools if context is not group' do
      @course = course_model
      tool = @course.context_external_tools.new(:name => "bob", :consumer_key => "test", :shared_secret => "secret", :url => "http://example.com")
      tool.account_navigation = {:url => "http://example.com", :icon_url => "http://example.com", :enabled => true, :canvas_icon_class => 'icon-commons'}
      tool.save!

      allow(controller).to receive(:polymorphic_url).and_return("http://example.com")
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
      allow(controller).to receive(:request).and_return(ActionDispatch::TestRequest.create)
      controller.instance_variable_set(:@context, @course)
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

    it "doesn't return an invalid icon_url" do
      totallyavalidurl = %{');\"></i>nothing to see here</button><img src=x onerror="alert(document.cookie);alert(document.domain);" />}
      @tool.settings[:editor_button][:icon_url] = totallyavalidurl
      @tool.save!
      hash = controller.external_tool_display_hash(@tool, :editor_button)
      expect(hash[:icon_url]).to be_nil
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
      allow(controller.request).to receive(:cookie_jar).and_return(cookies)
      allow(controller.request).to receive(:get?).and_return(false)
      allow(controller.request).to receive(:head?).and_return(false)
      allow(controller.request).to receive(:path).and_return('/non-api/endpoint')
      controller.instance_variable_set(:@current_user, User.new)
      controller.instance_variable_set(:@pseudonym_session, "session-authenticated")
      controller.params[controller.request_forgery_protection_token] = "bogus"
      controller.request.headers['X-CSRF-Token'] = "bogus"
    end

    it "should raise InvalidAuthenticityToken with invalid tokens" do
      allow(controller).to receive(:valid_request_origin?).and_return(true)
      expect{ controller.send(:verify_authenticity_token) }.to raise_exception(ActionController::InvalidAuthenticityToken)
    end

    it "should not raise with valid token" do
      controller.request.headers['X-CSRF-Token'] = controller.form_authenticity_token
      expect{ controller.send(:verify_authenticity_token) }.not_to raise_exception
    end

    it "should still raise on session-authenticated api request with invalid tokens" do
      allow(controller.request).to receive(:path).and_return('/api/endpoint')
      allow(controller).to receive(:valid_request_origin?).and_return(true)
      expect{ controller.send(:verify_authenticity_token) }.to raise_exception(ActionController::InvalidAuthenticityToken)
    end

    it "should not raise on token-authenticated api request despite invalid tokens" do
      allow(controller.request).to receive(:path).and_return('/api/endpoint')
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
    it "doesn't show unpublished courses to students" do
      student = user_factory(active_all: true)
      c1 = course_factory
      e = c1.enroll_student(student)
      e.update_attribute(:workflow_state, 'active')
      c2 = course_factory(active_all: true)
      c2.enroll_student(student).accept!

      controller.instance_variable_set(:@context, student)
      controller.send(:get_all_pertinent_contexts)
      expect(controller.instance_variable_get(:@contexts).select{|c| c.is_a?(Course)}).to eq [c2]
    end


    it "doesn't touch the database if there are no valid courses" do
      user_factory
      controller.instance_variable_set(:@context, @user)

      expect(Course).to receive(:where).never
      controller.send(:get_all_pertinent_contexts, only_contexts: 'Group_1')
    end

    it "doesn't touch the database if there are no valid groups" do
      user_factory
      controller.instance_variable_set(:@context, @user)

      expect(@user).to receive(:current_groups).never
      controller.send(:get_all_pertinent_contexts, include_groups: true, only_contexts: 'Course_1')
    end

    context "sharding" do
      require_relative '../sharding_spec_helper'
      specs_require_sharding

      it "should not asplode with cross-shard groups" do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        @shard1.activate do
          account = Account.create!
          teacher_in_course(:user => @user, :active_all => true, :account => account)
          @other_group = group_model(:context => @course)
          group_model(:context => @course)
          @group.add_user(@user)
        end
        controller.send(:get_all_pertinent_contexts, include_groups: true, only_contexts: "group_#{@other_group.id},group_#{@group.id}")
        expect(controller.instance_variable_get(:@contexts).select{|c| c.is_a?(Group)}).to eq [@group]
      end

      it "should not include groups in courses the user doesn't have the ability to view yet" do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        course_factory
        student_in_course(:user => @user, :course => @course)
        expect(@course).to_not be_available
        expect(@user.cached_current_enrollments).to be_empty
        @other_group = group_model(:context => @course)
        group_model(:context => @course)
        @group.add_user(@user)

        controller.send(:get_all_pertinent_contexts, include_groups: true)
        expect(controller.instance_variable_get(:@contexts).select{|c| c.is_a?(Group)}).to be_empty
      end

      it 'must select all cross-shard courses the user belongs to' do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        account = Account.create!
        enrollment1 = course_with_teacher(user: @user, active_all: true, account: account)
        course1 = enrollment1.course

        enrollment2 = @shard1.activate do
          account = Account.create!
          course_with_teacher(user: @user, active_all: true, account: account)
        end
        course2 = enrollment2.course

        controller.send(:get_all_pertinent_contexts, cross_shard: true)
        contexts = controller.instance_variable_get(:@contexts)
        expect(contexts).to include course1, course2
      end

      it 'must select only the specified cross-shard courses when only_contexts is included' do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        account = Account.create!
        enrollment1 = course_with_teacher(user: @user, active_all: true, account: account)
        course1 = enrollment1.course

        enrollment2 = @shard1.activate do
          account = Account.create!
          course_with_teacher(user: @user, active_all: true, account: account)
        end
        course2 = enrollment2.course

        controller.send(:get_all_pertinent_contexts, {
          cross_shard: true,
          only_contexts: "Course_#{course2.id}",
        })
        contexts = controller.instance_variable_get(:@contexts)
        expect(contexts).to_not include course1
        expect(contexts).to include course2
      end
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
      allow(controller.request).to receive_messages(xhr?: true)

      expect(discard).to be_empty, 'precondition'
      controller.send(:discard_flash_if_xhr)
      expect(discard).to all(match(/^notice$/))
    end

    it 'sets flash discard if request format is text/plain' do
      allow(controller.request).to receive_messages(xhr?: false, format: 'text/plain')

      expect(discard).to be_empty, 'precondition'
      controller.send(:discard_flash_if_xhr)
      expect(discard).to all(match(/^notice$/))
    end

    it 'leaves flash as is if conditions are not met' do
      allow(controller.request).to receive_messages(xhr?: false, format: 'text/html')

      expect(discard).to be_empty, 'precondition'
      controller.send(:discard_flash_if_xhr)
      expect(discard).to be_empty
    end
  end

  describe '#setup_live_events_context' do
    let(:non_conditional_values) do
      {
        hostname: 'test.host',
        user_agent: 'Rails Testing',
        client_ip: '0.0.0.0',
        producer: 'canvas'
      }
    end

    before(:each) do
      Thread.current[:context] = nil
    end

    it 'stringifies the non-strings in the context attributes' do
      current_user_attributes = { global_id: 12345 }

      current_user = double(current_user_attributes)
      controller.instance_variable_set(:@current_user, current_user)
      controller.send(:setup_live_events_context)
      expect(LiveEvents.get_context).to eq({user_id: '12345'}.merge(non_conditional_values))
    end

    context 'when a domain_root_account exists' do
      let(:root_account_attributes) do
        {
          uuid: 'account_uuid1',
          global_id: 'account_global1',
          lti_guid: 'lti1'
        }
      end

      let(:expected_context_attributes) do
        {
          root_account_uuid: 'account_uuid1',
          root_account_id: 'account_global1',
          root_account_lti_guid: 'lti1'
        }.merge(non_conditional_values)
      end

      it 'adds root account values to the LiveEvent context' do
        root_account = double(root_account_attributes)
        controller.instance_variable_set(:@domain_root_account, root_account)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context 'when a current_user exists' do
      let(:current_user_attributes) do
        {
          global_id: 'user_global_id'
        }
      end

      let(:expected_context_attributes) do
        {
          user_id: 'user_global_id'
        }.merge(non_conditional_values)
      end

      it 'sets the correct attributes on the LiveEvent context' do
        current_user = double(current_user_attributes)
        controller.instance_variable_set(:@current_user, current_user)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context 'when a real current_user exists' do
      let(:real_current_user_attributes) do
        {
          global_id: 'real_user_global_id'
        }
      end

      let(:expected_context_attributes) do
        {
          real_user_id: 'real_user_global_id'
        }.merge(non_conditional_values)
      end

      it 'sets the correct attributes on the LiveEvent context' do
        real_current_user = double(real_current_user_attributes)
        controller.instance_variable_set(:@real_current_user, real_current_user)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context 'when a real current_pseudonym exists' do
      let(:current_pseudonym_attributes) do
        {
          unique_id: 'unique_id',
          global_account_id: 'global_account_id',
          sis_user_id: 'sis_user_id'
        }
      end

      let(:expected_context_attributes) do
        {
          user_login: 'unique_id',
          user_account_id: 'global_account_id',
          user_sis_id: 'sis_user_id'
        }.merge(non_conditional_values)
      end

      it 'sets the correct attributes on the LiveEvent context' do
        current_pseudonym = double(current_pseudonym_attributes)
        controller.instance_variable_set(:@current_pseudonym, current_pseudonym)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context 'when a canvas context exists' do
      let(:canvas_context_attributes) do
        {
          class: Class,
          global_id: 'context_global_id'
        }
      end

      let(:expected_context_attributes) do
        {
          context_type: 'Class',
          context_id: 'context_global_id'
        }.merge(non_conditional_values)
      end

      it 'sets the correct attributes on the LiveEvent context' do
        canvas_context = double(canvas_context_attributes)
        controller.instance_variable_set(:@context, canvas_context)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context 'when a context_membership exists' do
      context 'when the context has a role' do
        it 'sets the correct attributes on the LiveEvent context' do
          stubbed_role = double({ name: 'name' })
          context_membership = double({role: stubbed_role})

          controller.instance_variable_set(:@context_membership, context_membership)
          controller.send(:setup_live_events_context)
          expect(LiveEvents.get_context).to eq({ context_role: 'name' }.merge(non_conditional_values))
        end
      end

      context 'when the context has a type' do
        it 'sets the correct attributes on the LiveEvent context' do
          context_membership = double({ type: 'type' })

          controller.instance_variable_set(:@context_membership, context_membership)
          controller.send(:setup_live_events_context)
          expect(LiveEvents.get_context).to eq({ context_role: 'type' }.merge(non_conditional_values))
        end
      end

      context 'when the context has neither a role or type' do
        it 'sets the correct attributes on the LiveEvent context' do
          context_membership = double({ class: Class })

          controller.instance_variable_set(:@context_membership, context_membership)
          controller.send(:setup_live_events_context)
          expect(LiveEvents.get_context).to eq({ context_role: 'Class' }.merge(non_conditional_values))
        end
      end
    end

    context 'when the current thread has a context key' do
      let(:thread_attributes) do
        {
          request_id: 'request_id',
          session_id: 'session_id'
        }
      end

      let(:expected_context_attributes) do
        {
          request_id: 'request_id',
          session_id: 'session_id'
        }.merge(non_conditional_values)
      end

      it 'sets the correct attributes on the LiveEvent context' do
        Thread.current[:context] = thread_attributes
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end
  end
end

describe WikiPagesController do
  describe "set_js_rights" do
    it "should populate js_env with policy rights" do
      allow(controller).to receive(:default_url_options).and_return({})

      course_with_teacher_logged_in :active_all => true
      controller.instance_variable_set(:@context, @course)

      get 'index', params: {:course_id => @course.id}

      expect(controller.js_env).to include(:WIKI_RIGHTS)
      expect(controller.js_env[:WIKI_RIGHTS].symbolize_keys).to eq Hash[@course.wiki.check_policy(@teacher).map { |right| [right, true] }]
    end
  end
end

describe CoursesController do
  describe "set_js_wiki_data" do
    before :each do
      course_with_teacher_logged_in :active_all => true
      @course.wiki_pages.create!(:title => 'blah').set_as_front_page!
      @course.reload
      @course.default_view = "wiki"
      @course.show_announcements_on_home_page = true
      @course.home_page_announcement_limit = 5
      @course.save!
    end

    it "should populate js_env with course_home setting" do
      controller.instance_variable_set(:@context, @course)
      get 'show', params: {id: @course.id}
      expect(controller.js_env).to include(:COURSE_HOME)
    end

    it "should populate js_env with setting for show_announcements flag" do
      controller.instance_variable_set(:@context, @course)
      get 'show', params: {id: @course.id}
      expect(controller.js_env).to include(:SHOW_ANNOUNCEMENTS, :ANNOUNCEMENT_LIMIT)
      expect(controller.js_env[:SHOW_ANNOUNCEMENTS]).to be_truthy
      expect(controller.js_env[:ANNOUNCEMENT_LIMIT]).to eq(5)
    end
  end

  describe "set_master_course_js_env_data" do
    before :each do
      controller.instance_variable_set(:@domain_root_account, Account.default)
      account_admin_user(:active_all => true)
      controller.instance_variable_set(:@current_user, @user)

      @master_course = course_factory
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      @master_page = @course.wiki_pages.create!(:title => "blah", :body => "bloo")
      @tag = @template.content_tag_for(@master_page)

      @child_course = course_factory
      @template.add_child_course!(@child_course)

      @child_page = @child_course.wiki_pages.create!(:title => "bloo", :body => "bloo", :migration_id => @tag.migration_id)
    end

    it "should populate master-side data (unrestricted)" do
      controller.set_master_course_js_env_data(@master_page, @master_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data['is_master_course_master_content']).to be_truthy
      expect(data['restricted_by_master_course']).to be_falsey
    end

    it "should populate master-side data (restricted)" do
      @tag.update_attribute(:restrictions, {:content => true})

      controller.set_master_course_js_env_data(@master_page, @master_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data['is_master_course_master_content']).to be_truthy
      expect(data['restricted_by_master_course']).to be_truthy
      expect(data['master_course_restrictions']).to eq({:content => true})
    end

    it "should populate child-side data (unrestricted)" do
      controller.set_master_course_js_env_data(@child_page, @child_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data['is_master_course_child_content']).to be_truthy
      expect(data['restricted_by_master_course']).to be_falsey
    end

    it "should populate child-side data (restricted)" do
      @tag.update_attribute(:restrictions, {:content => true})

      controller.set_master_course_js_env_data(@child_page, @child_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data['is_master_course_child_content']).to be_truthy
      expect(data['restricted_by_master_course']).to be_truthy
      expect(data['master_course_restrictions']).to eq({:content => true})
    end
  end

  context 'validate_scopes' do
    let(:account) { double() }

    before do
      controller.instance_variable_set(:@domain_root_account, account)
    end

    it 'does not affect session based api requests' do
      allow(controller).to receive(:request).and_return(double({
        params: {}
      }))
      expect(controller.send(:validate_scopes)).to be_nil
    end

    it 'does not affect api requests that use an access token with an unscoped developer key' do
      user = user_model
      developer_key = DeveloperKey.create!
      token = AccessToken.create!(user: user, developer_key: developer_key)
      controller.instance_variable_set(:@access_token, token)
      allow(controller).to receive(:request).and_return(double({
        params: {},
        method: 'GET'
      }))
      expect(controller.send(:validate_scopes)).to be_nil
    end

    it 'raises AccessTokenScopeError if scopes do not match' do
      user = user_model
      developer_key = DeveloperKey.create!(require_scopes: true)
      token = AccessToken.create!(user: user, developer_key: developer_key)
      controller.instance_variable_set(:@access_token, token)
      allow(controller).to receive(:request).and_return(double({
        params: {},
        method: 'GET'
      }))
      expect { controller.send(:validate_scopes) }.to raise_error(AuthenticationMethods::AccessTokenScopeError)
    end

    context 'with valid scopes on dev key' do
      let(:developer_key) { DeveloperKey.create!(require_scopes: true, scopes: ['url:GET|/api/v1/accounts']) }

      it 'allows adequately scoped requests through' do
        user = user_model
        token = AccessToken.create!(user: user, developer_key: developer_key, scopes: ['url:GET|/api/v1/accounts'])
        controller.instance_variable_set(:@access_token, token)
        allow(controller).to receive(:request).and_return(double({
          params: {},
          method: 'GET',
          path: '/api/v1/accounts'
        }))
        expect(controller.send(:validate_scopes)).to be_nil
      end

      it 'allows HEAD requests' do
        user = user_model
        token = AccessToken.create!(user: user, developer_key: developer_key, scopes: ['url:GET|/api/v1/accounts'])
        controller.instance_variable_set(:@access_token, token)
        allow(controller).to receive(:request).and_return(double({
          params: {},
          method: 'HEAD',
          path: '/api/v1/accounts'
        }))
        expect(controller.send(:validate_scopes)).to be_nil
      end

      it 'strips includes for adequately scoped requests' do
        user = user_model
        token = AccessToken.create!(user: user, developer_key: developer_key, scopes: ['url:GET|/api/v1/accounts'])
        controller.instance_variable_set(:@access_token, token)
        allow(controller).to receive(:request).and_return(double({
          method: 'GET',
          path: '/api/v1/accounts'
        }))
        params = double()
        expect(params).to receive(:delete).with(:include)
        expect(params).to receive(:delete).with(:includes)
        allow(controller).to receive(:params).and_return(params)
        controller.send(:validate_scopes)
      end
    end
  end
end

RSpec.describe ApplicationController, '#render_unauthorized_action' do
  controller do
    def index
      render_unauthorized_action
    end
  end

  before :once do
    @teacher = course_with_teacher(active_all: true).user
  end

  before do
    user_session(@teacher)
    get :index, format: format
  end

  describe 'pdf format' do
    let(:format) { :pdf }

    specify { expect(response.headers.fetch('Content-Type')).to match(/\Atext\/html/) }
    specify { expect(response).to have_http_status :unauthorized }
    specify { expect(response).to render_template('shared/unauthorized') }
  end

  describe 'html format' do
    let(:format) { :html }

    specify { expect(response.headers.fetch('Content-Type')).to match(/\Atext\/html/) }
    specify { expect(response).to have_http_status :unauthorized }
    specify { expect(response).to render_template('shared/unauthorized') }
  end

  describe 'json format' do
    let(:format) { :json }

    specify { expect(response.headers['Content-Type']).to match(/\Aapplication\/json/) }
    specify { expect(response).to have_http_status :unauthorized }
    specify { expect(json_parse.fetch('status')).to eq 'unauthorized' }
  end
end

RSpec.describe ApplicationController, '#redirect_to_login' do
  controller do
    def index
      redirect_to_login
    end
  end

  before do
    get :index, format: format
  end

  context 'given an unauthenticated json request' do
    let(:format) { :json }

    specify { expect(response).to have_http_status :unauthorized }
    specify { expect(json_parse.fetch('status')).to eq 'unauthenticated' }
  end

  shared_examples 'redirectable to html login page' do
    specify { expect(flash[:warning]).to eq 'You must be logged in to access this page' }
    specify { expect(session[:return_to]).to eq controller.clean_return_to(request.fullpath) }
    specify { expect(response).to redirect_to login_url }
    specify { expect(response).to have_http_status :found }
    specify { expect(response.location).to eq login_url }
  end

  context 'given an unauthenticated html request' do
    it_behaves_like 'redirectable to html login page' do
      let(:format) { :html }
    end
  end

  context 'given an unauthenticated pdf request' do
    it_behaves_like 'redirectable to html login page' do
      let(:format) { :pdf }
    end
  end
end
