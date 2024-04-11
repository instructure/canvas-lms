# frozen_string_literal: true

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

require_relative "../spec_helper"
require_relative "../lti_1_3_spec_helper"

RSpec.describe ApplicationController do
  context "group 1" do
    before do
      request_double = double(
        cookies_same_site_protection: proc { false },
        host_with_port: "www.example.com",
        host: "www.example.com",
        url: "http://www.example.com",
        method: "GET",
        headers: {},
        format: double(html?: true),
        user_agent: nil,
        remote_ip: "0.0.0.0",
        base_url: "https://canvas.test",
        referer: nil
      )
      allow(controller).to receive(:request).and_return(request_double)
    end

    describe "#google_drive_connection" do
      before do
        settings_mock = double
        allow(settings_mock).to receive(:settings).and_return({})
        allow(Canvas::Plugin).to receive(:find).and_return(settings_mock)
      end

      it "uses @real_current_user first" do
        mock_real_current_user = double
        mock_current_user = double
        controller.instance_variable_set(:@real_current_user, mock_real_current_user)
        controller.instance_variable_set(:@current_user, mock_current_user)
        session[:oauth_gdrive_refresh_token] = "session_token"
        session[:oauth_gdrive_access_token] = "sesion_secret"

        expect(Rails.cache).to receive(:fetch).with(["google_drive_tokens", mock_real_current_user].cache_key).and_return(["real_current_user_token", "real_current_user_secret"])

        expect(GoogleDrive::Connection).to receive(:new).with("real_current_user_token", "real_current_user_secret", 30)

        controller.send(:google_drive_connection)
      end

      it "uses @current_user second" do
        mock_current_user = double
        controller.instance_variable_set(:@real_current_user, nil)
        controller.instance_variable_set(:@current_user, mock_current_user)
        session[:oauth_gdrive_refresh_token] = "session_token"
        session[:oauth_gdrive_access_token] = "sesion_secret"

        expect(Rails.cache).to receive(:fetch).with(["google_drive_tokens", mock_current_user].cache_key).and_return(["current_user_token", "current_user_secret"])

        expect(GoogleDrive::Connection).to receive(:new).with("current_user_token", "current_user_secret", 30)
        controller.send(:google_drive_connection)
      end

      it "queries user services if token isn't in the cache" do
        mock_current_user = double
        controller.instance_variable_set(:@real_current_user, nil)
        controller.instance_variable_set(:@current_user, mock_current_user)
        session[:oauth_gdrive_refresh_token] = "session_token"
        session[:oauth_gdrive_access_token] = "sesion_secret"

        mock_user_services = double("mock_user_services")
        expect(mock_current_user).to receive(:user_services).and_return(mock_user_services)
        expect(mock_user_services).to receive(:where).with(service: "google_drive").and_return(double(first: double(token: "user_service_token", secret: "user_service_secret")))

        expect(GoogleDrive::Connection).to receive(:new).with("user_service_token", "user_service_secret", 30)
        controller.send(:google_drive_connection)
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

      it "sets items" do
        expect(HostUrl).to receive(:file_host).with(Account.default, "www.example.com").and_return("files.example.com")
        controller.js_env FOO: "bar"
        expect(controller.js_env[:FOO]).to eq "bar"
        expect(controller.js_env[:files_domain]).to eq "files.example.com"
      end

      it "auto-sets timezone and locales" do
        I18n.with_locale(:fr) do
          Time.use_zone("Alaska") do
            expect(@controller.js_env[:LOCALES]).to eq ["fr", "en"] # 'en' is always the last fallback
            expect(@controller.js_env[:BIGEASY_LOCALE]).to eq "fr_FR"
            expect(@controller.js_env[:FULLCALENDAR_LOCALE]).to eq "fr"
            expect(@controller.js_env[:MOMENT_LOCALE]).to eq "fr"
            expect(@controller.js_env[:TIMEZONE]).to eq "America/Juneau"
          end
        end
      end

      describe "user flags" do
        before do
          user_factory
          controller.instance_variable_set(:@domain_root_account, Account.default)
          controller.instance_variable_set(:@current_user, @user)
          allow(controller).to receive(:user_display_json).and_return({})
        end

        context "eventAlertTimeout" do
          it "is not set if the feature flag is off" do
            expect(controller.js_env[:flashAlertTimeout]).to be_nil
          end

          it "is 86400000 (1 day in milliseconds) if the feature flag is on" do
            @user.enable_feature!(:disable_alert_timeouts)
            expect(controller.js_env[:flashAlertTimeout]).to eq(1.day.in_milliseconds)
          end
        end

        context "group_information" do
          before do
            course_with_user("TeacherEnrollment", user: @user, active_all: true)
            @group_category = @course.group_categories.create!(name: "Group Category")
            @group_1 = @course.groups.create!(group_category: @group_category, name: "group 1")
            @group_2 = @course.groups.create!(group_category: @group_category, name: "group 2")
            @group_10 = @course.groups.create!(group_category: @group_category, name: "group 10")
            @group_zed = @course.groups.create!(group_category: @group_category, name: "group zed")
          end

          it "contains active group names sorted by name" do
            @group_zed.workflow_state = "deleted"
            @group_zed.save!
            controller.instance_variable_set(:@context, @group_1)
            group_names = controller.js_env[:group_information].pluck(:label)
            expect(group_names).to eq ["group 1", "group 10", "group 2"]
          end
        end

        context "current_user_is_student" do
          before do
            course_with_user("TeacherEnrollment", user: @user, active_all: true)
            @course_with_user_as_teacher = @course

            course_with_user("StudentEnrollment", user: @user, active_all: true)
            @course_with_user_as_student = @course

            allow(controller).to receive("api_v1_course_ping_url").and_return({})
          end

          it "for the course where user is enrolled as teacher" do
            controller.instance_variable_set(:@context, @course_with_user_as_teacher)
            expect(controller.js_env[:current_user_is_student]).to be_falsey
          end

          it "for the course where user is enrolled as student" do
            controller.instance_variable_set(:@context, @course_with_user_as_student)
            expect(controller.js_env[:current_user_is_student]).to be_truthy
          end
        end

        context "current_user_is_admin" do
          before do
            @sub_account = Account.create(name: "sub account from default account", parent_account: Account.default)
            @teacher_sub_account_admin = user_with_pseudonym(username: "nobody@example.com")
            @root_account_course = Course.create!(name: "course in root account", account: Account.default)
            @root_account_course.enroll_user(@teacher_sub_account_admin, "TeacherEnrollment", enrollment_state: "active")
            @sub_account_course = Course.create!(name: "course in sub account", account: @sub_account)
            @sub_account.account_users.create!(user: @teacher_sub_account_admin)
            @admin = user_with_pseudonym(username: "nobody2@example.com")
            Account.default.account_users.create!(user: @admin)
            allow(controller).to receive("api_v1_course_ping_url").and_return({})
          end

          it "is set to false when the user is an account admin of a different account that is not the parent account of the course" do
            controller.instance_variable_set(:@current_user, @teacher_sub_account_admin)
            controller.instance_variable_set(:@context, @root_account_course)
            expect(controller.js_env[:current_user_is_admin]).to be_falsey
          end

          it "is set to true when the user is an account admin of the account that is the parent account of the course" do
            controller.instance_variable_set(:@current_user, @teacher_sub_account_admin)
            controller.instance_variable_set(:@context, @sub_account_course)
            expect(controller.js_env[:current_user_is_admin]).to be_truthy
          end

          it "is set to true when the user is an account admin of the root account" do
            controller.instance_variable_set(:@current_user, @admin)
            controller.instance_variable_set(:@context, @root_account_course)
            expect(controller.js_env[:current_user_is_admin]).to be_truthy
          end
        end
      end

      describe "ENV.DIRECT_SHARE_ENABLED" do
        before do
          allow(controller).to receive(:user_display_json)
          allow(controller).to receive("api_v1_course_ping_url").and_return({})
          controller.instance_variable_set(:@domain_root_account, Account.default)
        end

        it "sets the env var to true when the user can use it" do
          course_with_teacher(active_all: true)
          controller.instance_variable_set(:@current_user, @teacher)
          controller.instance_variable_set(:@context, @course)
          expect(controller.js_env[:DIRECT_SHARE_ENABLED]).to be_truthy
        end

        it "sets the env var to false when the user can't use it" do
          course_with_student(active_all: true)
          controller.instance_variable_set(:@current_user, @student)
          controller.instance_variable_set(:@context, @course)
          expect(controller.js_env[:DIRECT_SHARE_ENABLED]).to be_falsey
        end

        it "sets the env var to false when the context is a group" do
          course_with_teacher(active_all: true)
          controller.instance_variable_set(:@current_user, @teacher)
          controller.instance_variable_set(:@context, group_model)
          expect(controller.js_env[:DIRECT_SHARE_ENABLED]).to be_falsey
        end

        describe "with manage_course_content_add permission disabled" do
          before do
            course_with_teacher(active_all: true, user: @teacher)
            RoleOverride.create!(context: @course.account, permission: "manage_course_content_add", role: teacher_role, enabled: false)
          end

          it "sets the env var to false if the course is active" do
            controller.instance_variable_set(:@current_user, @teacher)
            controller.instance_variable_set(:@context, @course)
            expect(controller.js_env[:DIRECT_SHARE_ENABLED]).to be_falsey
          end

          describe "when the course is concluded" do
            before do
              @course.complete!
            end

            it "sets the env var to true when the user can use it" do
              controller.instance_variable_set(:@current_user, @teacher)
              controller.instance_variable_set(:@context, @course)
              expect(controller.js_env[:DIRECT_SHARE_ENABLED]).to be_truthy
            end

            it "sets the env var to false when the user can't use it" do
              controller.instance_variable_set(:@current_user, @student)
              controller.instance_variable_set(:@context, @course)
              expect(controller.js_env[:DIRECT_SHARE_ENABLED]).to be_falsey
            end
          end
        end
      end

      it "sets the contextual timezone from the context" do
        Time.use_zone("Mountain Time (US & Canada)") do
          controller.instance_variable_set(:@context, double(time_zone: Time.zone, asset_string: "", class_name: nil))
          controller.js_env({})
          expect(controller.js_env[:CONTEXT_TIMEZONE]).to eq "America/Denver"
        end
      end

      context "session_timezone url param is given" do
        before do
          allow(controller).to receive(:params).and_return({ session_timezone: "America/New_York" })
        end

        it "sets the timezone from the url" do
          Time.use_zone("Mountain Time (US & Canada)") do
            controller.instance_variable_set(:@context, double(time_zone: Time.zone, asset_string: "", class_name: nil))
            controller.js_env({})
            expect(controller.js_env[:TIMEZONE]).to eq "America/New_York"
          end
        end

        it "sets the contextual timezone from the url" do
          Time.use_zone("Mountain Time (US & Canada)") do
            controller.instance_variable_set(:@context, double(time_zone: Time.zone, asset_string: "", class_name: nil))
            controller.js_env({})
            expect(controller.js_env[:CONTEXT_TIMEZONE]).to eq "America/New_York"
          end
        end

        context "session_timezone is not valid" do
          before do
            allow(controller).to receive(:params).and_return({ session_timezone: "ChawnZone" })
          end

          it "sets the contextual timezone from the context" do
            Time.use_zone("Mountain Time (US & Canada)") do
              controller.instance_variable_set(:@context, double(time_zone: Time.zone, asset_string: "", class_name: nil))
              controller.js_env({})
              expect(controller.js_env[:CONTEXT_TIMEZONE]).to eq "America/Denver"
            end
          end

          it "sets the timezone from the context" do
            Time.use_zone("Mountain Time (US & Canada)") do
              controller.instance_variable_set(:@context, double(time_zone: Time.zone, asset_string: "", class_name: nil))
              controller.js_env({})
              expect(controller.js_env[:TIMEZONE]).to eq "America/Denver"
            end
          end
        end
      end

      it "allows multiple items" do
        controller.js_env A: "a", B: "b"
        expect(controller.js_env[:A]).to eq "a"
        expect(controller.js_env[:B]).to eq "b"
      end

      it "does not allow overwriting a key" do
        controller.js_env REAL_SLIM_SHADY: "please stand up"
        expect { controller.js_env(REAL_SLIM_SHADY: "poser") }.to raise_error("js_env key REAL_SLIM_SHADY is already taken")
      end

      it "overwrites a key if told explicitly to do so" do
        controller.js_env REAL_SLIM_SHADY: "please stand up"
        controller.js_env({ REAL_SLIM_SHADY: "poser" }, true)
        expect(controller.js_env[:REAL_SLIM_SHADY]).to eq "poser"
      end

      it "gets appropriate settings from the root account" do
        root_account = double(global_id: 1, id: 1, feature_enabled?: false, open_registration?: true, settings: {}, cache_key: "key", uuid: "bleh", salesforce_id: "blah")
        allow(root_account).to receive(:kill_joy?).and_return(false)
        allow(HostUrl).to receive_messages(file_host: "files.example.com")
        controller.instance_variable_set(:@domain_root_account, root_account)
        expect(controller.js_env[:SETTINGS][:open_registration]).to be_truthy
        expect(controller.js_env[:KILL_JOY]).to be_falsey
      end

      it "disables fun when set" do
        root_account = double(global_id: 1, id: 1, feature_enabled?: false, open_registration?: true, settings: {}, cache_key: "key", uuid: "blah", salesforce_id: "bleh")
        allow(root_account).to receive(:kill_joy?).and_return(true)
        allow(HostUrl).to receive_messages(file_host: "files.example.com")
        controller.instance_variable_set(:@domain_root_account, root_account)
        expect(controller.js_env[:KILL_JOY]).to be_truthy
      end

      context "feature/release flags" do
        context "canvas_k6_theme" do
          before do
            controller.instance_variable_set(:@context, @course)
          end

          it "populates js_env with elementary theme setting" do
            expect(controller.js_env[:FEATURES]).to include(:canvas_k6_theme)
          end
        end

        context "usage_rights_discussion_topics" do
          before do
            controller.instance_variable_set(:@domain_root_account, Account.default)
          end

          it "is false if the feature flag is off" do
            Account.default.disable_feature!(:usage_rights_discussion_topics)
            expect(controller.js_env[:FEATURES][:usage_rights_discussion_topics]).to be_falsey
          end

          it "is true if the feature flag is on" do
            Account.default.enable_feature!(:usage_rights_discussion_topics)
            expect(controller.js_env[:FEATURES][:usage_rights_discussion_topics]).to be_truthy
          end
        end
      end

      it "sets LTI_LAUNCH_FRAME_ALLOWANCES" do
        expect(@controller.js_env[:LTI_LAUNCH_FRAME_ALLOWANCES]).to match_array [
          "geolocation *",
          "microphone *",
          "camera *",
          "midi *",
          "encrypted-media *",
          "autoplay *",
          "clipboard-write *",
          "display-capture *"
        ]
      end

      it "sets DEEP_LINKING_POST_MESSAGE_ORIGIN" do
        expect(@controller.js_env[:DEEP_LINKING_POST_MESSAGE_ORIGIN]).to eq @controller.request.base_url
      end

      context "sharding" do
        specs_require_sharding

        it "sets the global id for the domain_root_account" do
          controller.instance_variable_set(:@domain_root_account, Account.default)
          expect(controller.js_env[:DOMAIN_ROOT_ACCOUNT_ID]).to eq Account.default.global_id
        end
      end

      it "matches against weird http_accept headers" do
        # sometimes we get browser requests for an endpoint that just pass */* as
        # the accept header. I don't think we can simulate this in a test, so
        # this test just verifies the condition in js_env works across updates
        expect(Mime::Type.new("*/*") == "*/*").to be_truthy
      end

      context "disable_keyboard_shortcuts" do
        it "is false by default" do
          expect(@controller.js_env[:disable_keyboard_shortcuts]).to be_falsey
        end

        it "is true if user disables keyboard shortcuts" do
          user = user_model
          user.enable_feature!(:disable_keyboard_shortcuts)
          expect(user.prefers_no_keyboard_shortcuts?).to be_truthy
        end
      end

      context "comment_library_suggestions_enabled" do
        before do
          user_factory
          controller.instance_variable_set(:@domain_root_account, Account.default)
          controller.instance_variable_set(:@current_user, @user)
          allow(controller).to receive(:user_display_json).and_return({})
        end

        it "is false by default" do
          expect(@controller.js_env[:comment_library_suggestions_enabled]).to be false
        end

        it "is true if user enables suggestions" do
          @user.preferences[:comment_library_suggestions_enabled] = true
          @user.save!
          expect(@controller.js_env[:comment_library_suggestions_enabled]).to be true
        end
      end

      context "canvas for elementary" do
        let(:course) { create_course }

        before do
          controller.instance_variable_set(:@context, course)
          allow(controller).to receive("api_v1_course_ping_url").and_return({})
        end

        describe "K5_HOMEROOM_COURSE" do
          describe "with canvas_for_elementary account setting on" do
            it "is true if the course is a homeroom course and in a K-5 account" do
              course.account.settings[:enable_as_k5_account] = { value: true }
              course.homeroom_course = true
              expect(@controller.js_env[:K5_HOMEROOM_COURSE]).to be_truthy
            end

            it "is false if the course is a homeroom course and not in a K-5 account" do
              course.homeroom_course = true
              expect(@controller.js_env[:K5_HOMEROOM_COURSE]).to be_falsy
            end

            it "is false if the course is not a homeroom course and in a K-5 account" do
              course.account.settings[:enable_as_k5_account] = { value: true }
              expect(@controller.js_env[:K5_HOMEROOM_COURSE]).to be_falsy
            end
          end

          it "is false with the canvas_for_elementary account setting off" do
            expect(@controller.js_env[:K5_HOMEROOM_COURSE]).to be_falsy

            course.homeroom_course = true
            expect(@controller.js_env[:K5_HOMEROOM_COURSE]).to be_falsy

            course.homeroom_course = false
            course.account.settings[:enable_as_k5_account] = { value: true }
            expect(@controller.js_env[:K5_HOMEROOM_COURSE]).to be_falsy
          end
        end
      end

      context "ACCOUNT_ID" do
        before :once do
          @subaccount = Account.default.sub_accounts.create!
        end

        it "is the account id in account context" do
          controller.instance_variable_set :@context, @subaccount
          expect(controller.js_env[:ACCOUNT_ID]).to eq @subaccount.id
        end

        it "is the course's subaccount id in course context" do
          course_factory(account: @subaccount)
          controller.instance_variable_set :@context, @course
          allow(controller).to receive(:polymorphic_url).and_return("/dummy")
          expect(controller.js_env[:ACCOUNT_ID]).to eq @subaccount.id
        end

        it "is the group's account id in account group context" do
          group = @subaccount.groups.create!
          controller.instance_variable_set :@context, group
          expect(controller.js_env[:ACCOUNT_ID]).to eq @subaccount.id
        end

        it "is the group's course's subaccount id in course group context" do
          course_factory(account: @subaccount)
          group = @course.groups.create!
          controller.instance_variable_set :@context, group
          expect(controller.js_env[:ACCOUNT_ID]).to eq @subaccount.id
        end

        it "is the domain root account id in user context" do
          user_factory
          controller.instance_variable_set :@context, @user
          controller.instance_variable_set :@domain_root_account, Account.default
          expect(controller.js_env[:ACCOUNT_ID]).to eq Account.default.id
        end
      end
    end

    describe "clean_return_to" do
      before do
        req = double("request obj", protocol: "https://", host_with_port: "canvas.example.com")
        allow(controller).to receive(:request).and_return(req)
      end

      it "builds from a simple path" do
        expect(controller.send(:clean_return_to, "/calendar")).to eq "https://canvas.example.com/calendar"
      end

      it "builds from a full url" do
        # ... but always use the request host/protocol, not the given
        expect(controller.send(:clean_return_to, "http://example.org/a/b?a=1&b=2#test")).to eq "https://canvas.example.com/a/b?a=1&b=2#test"
      end

      it "rejects disallowed paths" do
        expect(controller.send(:clean_return_to, "ftp://example.com/javascript:hai")).to be_nil
      end

      it "removes /download from the end of a file path" do
        expect(controller.send(:clean_return_to, "/courses/1/files/1/download?wrap=1")).to eq "https://canvas.example.com/courses/1/files/1"
        expect(controller.send(:clean_return_to, "/courses/1~1/files/1~1/download?wrap=1")).to eq "https://canvas.example.com/courses/1~1/files/1~1"
        expect(controller.send(:clean_return_to, "/courses/1/pages/download?wrap=1")).to eq "https://canvas.example.com/courses/1/pages/download?wrap=1"
      end
    end

    describe "response_code_for_rescue" do
      it "maps certain exceptions declared outside core canvas to known codes" do
        e = CanvasHttp::CircuitBreakerError.new
        expect(controller.send(:response_code_for_rescue, e)).to eq(502)
      end
    end

    describe "#reject!" do
      it "sets the message and status in the error json" do
        expect { controller.reject!("test message", :not_found) }.to(raise_error(RequestError) do |e|
          expect(e.message).to eq "test message"
          expect(e.error_json[:message]).to eq "test message"
          expect(e.error_json[:status]).to eq "not_found"
          expect(e.response_status).to eq 404
        end)
      end

      it "defaults status to 'bad_request'" do
        expect { controller.reject!("test message") }.to(raise_error(RequestError) do |e|
          expect(e.error_json[:status]).to eq "bad_request"
          expect(e.response_status).to eq 400
        end)
      end

      it "accepts numeric status codes" do
        expect { controller.reject!("test message", 403) }.to(raise_error(RequestError) do |e|
          expect(e.error_json[:status]).to eq "forbidden"
          expect(e.response_status).to eq 403
        end)
      end

      it "accepts symbolic status codes" do
        expect { controller.reject!("test message", :service_unavailable) }.to(raise_error(RequestError) do |e|
          expect(e.error_json[:status]).to eq "service_unavailable"
          expect(e.response_status).to eq 503
        end)
      end
    end

    describe "safe_domain_file_user" do
      before :once do
        @user = User.create!
        @attachment = @user.attachments.new(filename: "foo.png")
        @attachment.content_type = "image/png"
        @attachment.save!
      end

      before do
        # safe_domain_file_url wants to use request.protocol
        allow(controller).to receive(:request).and_return(double("request", protocol: "", host_with_port: "", url: ""))

        @common_params = { only_path: true }
      end

      it "includes inline=1 in url by default" do
        expect(controller).to receive(:file_download_url)
          .with(@attachment, @common_params.merge(inline: 1))
          .and_return("")
        expect(HostUrl).to receive(:file_host_with_shard).with(42, "").and_return(["myfiles", Shard.default])
        controller.instance_variable_set(:@domain_root_account, 42)
        url = controller.send(:safe_domain_file_url, @attachment)
        expect(url).to match(/myfiles/)
      end

      it "includes :download=>1 in inline urls for relative contexts" do
        controller.instance_variable_set(:@context, @attachment.context)
        allow(controller).to receive(:named_context_url).and_return("")
        url = controller.send(:safe_domain_file_url, @attachment)
        expect(url).to match(/[?&]download=1(&|$)/)
      end

      it "does not include :download=>1 in download urls for relative contexts" do
        controller.instance_variable_set(:@context, @attachment.context)
        allow(controller).to receive(:named_context_url).and_return("")
        url = controller.send(:safe_domain_file_url, @attachment, download: true)
        expect(url).not_to match(/[?&]download=1(&|$)/)
      end

      it "includes download_frd=1 and not include inline=1 in url when specified as for download" do
        expect(controller).to receive(:file_download_url)
          .with(@attachment, @common_params.merge(download_frd: 1))
          .and_return("")
        controller.send(:safe_domain_file_url, @attachment, download: true)
      end

      it "prepends a unique file subdomain if configured" do
        override_dynamic_settings(private: { canvas: { attachment_specific_file_domain: true } }) do
          expect(controller).to receive(:file_download_url)
            .with(@attachment, @common_params.merge(inline: 1))
            .and_return("/files/#{@attachment.id}")
          expect(controller.send(:safe_domain_file_url, @attachment, host_and_shard: ["canvasfiles.com", Shard.default])).to eq "a#{@attachment.shard.id}-#{@attachment.id}.canvasfiles.com/files/#{@attachment.id}"
        end
      end
    end

    describe "get_context" do
      after do
        I18n.localizer = nil
      end

      it "finds user with api_find for api requests" do
        user_with_pseudonym
        @pseudonym.update_attribute(:sis_user_id, "test1")
        controller.instance_variable_set(:@domain_root_account, Account.default)
        allow(controller).to receive(:named_context_url).with(@user, :context_url).and_return("")
        allow(controller).to receive_messages(params: { user_id: "sis_user_id:test1" }, api_request?: true)
        controller.send(:get_context)
        expect(controller.instance_variable_get(:@context)).to eq @user
      end

      it "finds course section with api_find for api requests" do
        course_model
        @section = @course.course_sections.first
        @section.update_attribute(:sis_source_id, "test1")
        controller.instance_variable_set(:@domain_root_account, Account.default)
        allow(controller).to receive(:named_context_url).with(@section, :context_url).and_return("")
        allow(controller).to receive_messages(params: { course_section_id: "sis_section_id:test1" }, api_request?: true)
        controller.send(:get_context)
        expect(controller.instance_variable_get(:@context)).to eq @section
      end

      # this test is supposed to represent calling I18n.t before a context is set
      # and still having later localizations that depend on the locale of the
      # context work.
      it "resets the localizer" do
        # emulate all the locale related work done before/around a request
        acct = Account.default
        acct.default_locale = "es"
        acct.save!
        controller.instance_variable_set(:@domain_root_account, acct)
        controller.send(:assign_localizer)
        I18n.set_locale_with_localizer # this is what t() triggers
        expect(I18n.locale.to_s).to eq "es"
        course_model(locale: "ru")
        allow(controller).to receive(:named_context_url).with(@course, :context_url).and_return("")
        allow(controller).to receive_messages(params: { course_id: @course.id }, api_request?: false, session: {}, js_env: {})
        controller.send(:get_context)
        expect(controller.instance_variable_get(:@context)).to eq @course
        I18n.set_locale_with_localizer # this is what t() triggers
        expect(I18n.locale.to_s).to eq "ru"
      end

      it "doesn't fail if localizer exists in a contextless state" do
        # establish an instance with no request/session
        ctrl = ApplicationController.new
        ctrl.send(:assign_localizer)
        locale = nil
        expect { locale = I18n.localizer.call }.to_not raise_error
        expect(locale).to eq("en") # default locale
      end
    end

    context "require_context" do
      it "properly requires account context" do
        controller.instance_variable_set(:@context, Account.default)
        expect(controller.send(:require_account_context)).to be_truthy
        course_model
        controller.instance_variable_set(:@context, @course)
        expect { controller.send(:require_account_context) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "properly requires course context" do
        course_model
        controller.instance_variable_set(:@context, @course)
        expect(controller.send(:require_course_context)).to be_truthy
        controller.instance_variable_set(:@context, Account.default)
        expect { controller.send(:require_course_context) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "#log_asset_access" do
      before :once do
        course_model
        user_model
      end

      before do
        controller.instance_variable_set(:@current_user, @user)
        controller.instance_variable_set(:@context, @user)
      end

      it "sets @accessed_asset[asset_for_root_account_id] when asset is an array" do
        controller.send(:log_asset_access, ["assignments", @course], "assignments", "other")
        accessed_asset = controller.instance_variable_get(:@accessed_asset)
        expect(accessed_asset[:asset_for_root_account_id]).to eq(@course)
      end

      it "sets @accessed_asset[asset_for_root_account_id] when asset is not an array" do
        controller.send(:log_asset_access, @course, "assignments", "other")
        accessed_asset = controller.instance_variable_get(:@accessed_asset)
        expect(accessed_asset[:asset_for_root_account_id]).to eq(@course)
      end
    end

    describe "log_participation" do
      before :once do
        course_model
        student_in_course
        attachment_model(context: @course)
      end

      it "finds file's context instead of user" do
        controller.instance_variable_set(:@domain_root_account, Account.default)
        controller.instance_variable_set(:@context, @student)
        controller.instance_variable_set(:@accessed_asset, { level: "participate", code: @attachment.asset_string, category: "files" })
        allow(controller).to receive(:named_context_url).with(@attachment, :context_url).and_return("/files/#{@attachment.id}")
        allow(controller).to receive(:params).and_return({ file_id: @attachment.id, id: @attachment.id })
        allow(controller.request).to receive(:path).and_return("/files/#{@attachment.id}")
        controller.send(:log_participation, @student)
        expect(AssetUserAccess.where(user: @student, asset_code: @attachment.asset_string).take.context).to eq @course
      end

      it "does not error on non-standard context for file" do
        controller.instance_variable_set(:@domain_root_account, Account.default)
        controller.instance_variable_set(:@context, @student)
        controller.instance_variable_set(:@accessed_asset, { level: "participate", code: @attachment.asset_string, category: "files" })
        allow(controller).to receive(:named_context_url).with(@attachment, :context_url).and_return("/files/#{@attachment.id}")
        allow(controller).to receive(:params).and_return({ file_id: @attachment.id, id: @attachment.id })
        allow(controller.request).to receive(:path).and_return("/files/#{@attachment.id}")
        assignment_model(course: @course)
        @attachment.context = @assignment
        @attachment.save!
        expect { controller.send(:log_participation, @student) }.not_to raise_error
      end
    end

    describe "#add_interaction_seconds" do
      let(:params) do
        {
          interaction_seconds: "62",
          authenticity_token: "auth token",
          page_view_token: "page view token",
          id: "379b0dbc-f01c-4dc4-ae05-15f23588cefb"
        }
      end
      let(:page_view_info) do
        {
          request_id: "379b0dbc-f01c-4dc4-ae05-15f23588cefb",
          user_id: 10_000_000_000_004,
          created_at: "2020-06-12T17:02:44.14Z"
        }
      end
      let(:page_view) do
        {
          request_id: "379b0dbc-f01c-4dc4-ae05-15f23588cefb",
          session_id: "fc85ce4458c27360893cb7fa01632d85",
          interaction_seconds: 5.0
        }
      end

      before :once do
        student_in_course
      end

      it "updates for HTTP PUT requests that are not generated by hand" do
        allow(controller.request).to receive_messages(xhr?: 0, put?: true)
        allow(RequestContextGenerator).to receive(:store_interaction_seconds_update).and_return(true)
        allow(CanvasSecurity::PageViewJwt).to receive(:decode).and_return(page_view_info)
        allow(PageView).to receive(:find_for_update).and_return(page_view)
        expect { controller.send(:add_interaction_seconds) }.not_to raise_error
      end
    end

    describe "rescue_action_in_public" do
      context "sharding" do
        specs_require_sharding

        before do
          @shard2.activate do
            @account = account_model
          end
        end

        it "logs error reports to the domain_root_accounts shard" do
          allow(Canvas::Errors::Info).to receive(:useful_http_env_stuff_from_request).and_return({})

          req = double
          allow(req).to receive_messages(url: "url",
                                         headers: {},
                                         authorization: nil,
                                         request_method_symbol: :get,
                                         format: "format")

          allow(controller).to receive_messages(request: req, api_request?: false)
          allow(controller).to receive(:render_rescue_action)

          controller.instance_variable_set(:@domain_root_account, @account)

          controller.send(:rescue_action_in_public, Exception.new)

          expect(ErrorReport.count).to eq 0
          @shard2.activate do
            expect(ErrorReport.count).to eq 1
          end
        end
      end
    end

    describe "content_tag_redirect" do
      def create_tag(overrides)
        ContentTag.create!(
          {
            id: 42,
            content_id: 44,
            tag_type: "context_module",
            context_type: "Account",
            context_id: 1,
            root_account_id: Account.default
          }.merge(overrides)
        )
      end

      it "redirects for lti_message_handler" do
        tag = create_tag(content_type: "Lti::MessageHandler")
        expect(controller).to receive(:named_context_url).with(Account.default, :context_basic_lti_launch_request_url, 44, { module_item_id: 42, resource_link_fragment: "ContentTag:42" }).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      context "when manage enabled" do
        let(:course) { course_model }

        before do
          controller.instance_variable_set(:@context, course)
          allow(course).to receive(:grants_any_right?).and_return true
        end

        it "redirects for an assignment" do
          tag = create_tag(content_type: "Assignment")
          expect(controller).to receive(:named_context_url).with(Account.default, :context_assignment_url, 44, { module_item_id: 42 }).and_return("nil")
          allow(controller).to receive(:redirect_to)
          controller.send(:content_tag_redirect, Account.default, tag, nil)
        end

        it "redirects to edit for a quiz_lti assignment" do
          tag = create_tag(content_type: "Assignment")
          allow(tag).to receive(:quiz_lti).and_return true
          expect(controller).to receive(:named_context_url).with(Account.default, :edit_context_assignment_url, 44, { module_item_id: 42, quiz_lti: true }).and_return("nil")
          allow(controller).to receive(:redirect_to)
          controller.send(:content_tag_redirect, Account.default, tag, nil)
        end

        context "when the build param is passed" do
          it "redirects to build for a quiz_lti assignment" do
            tag = create_tag(content_type: "Assignment")
            allow(tag).to receive(:quiz_lti).and_return true
            expect(controller).to receive(:named_context_url).with(
              Account.default, :context_assignment_url, 44, { module_item_id: 42 }
            ).and_return("nil")
            allow(controller).to receive(:redirect_to)
            controller.params[:build] = true
            controller.send(:content_tag_redirect, Account.default, tag, nil)
          end
        end
      end

      it "redirects for a quiz" do
        tag = create_tag(content_type: "Quizzes::Quiz")
        expect(controller).to receive(:named_context_url).with(Account.default, :context_quiz_url, 44, { module_item_id: 42 }).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      it "redirects for a discussion topic" do
        tag = create_tag(content_type: "DiscussionTopic")
        expect(controller).to receive(:named_context_url).with(Account.default, :context_discussion_topic_url, 44, { module_item_id: 42 }).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      it "redirects for a wikipage" do
        tag = create_tag(content_type: "WikiPage")
        expect(controller).to receive(:polymorphic_url).with([Account.default, tag.content], { module_item_id: 42 }).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      it "redirects for a rubric" do
        tag = create_tag(content_type: "Rubric")
        expect(controller).to receive(:named_context_url).with(Account.default, :context_rubric_url, 44, { module_item_id: 42 }).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      it "redirects for a question bank" do
        tag = create_tag(content_type: "AssessmentQuestionBank")
        expect(controller).to receive(:named_context_url).with(Account.default, :context_question_bank_url, 44, { module_item_id: 42 }).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      it "redirects for an attachment" do
        tag = create_tag(content_type: "Attachment")
        expect(controller).to receive(:named_context_url).with(Account.default, :context_file_url, 44, { module_item_id: 42 }).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      it "redirects for an alignment" do
        course = course_model
        controller.instance_variable_set(:@context, course)
        allow(course).to receive(:grants_right?).and_return true
        tag = create_tag(content_type: "Assignment", tag_type: "learning_outcome")
        expect(controller).to receive(:named_context_url).with(Account.default, :context_assignment_url, 44, {}).and_return("nil")
        allow(controller).to receive(:redirect_to)
        controller.send(:content_tag_redirect, Account.default, tag, nil)
      end

      context "ContextExternalTool" do
        let_once(:dev_key) { DeveloperKey.create! }

        let(:course) { course_model }
        let(:user) { user_model }
        let(:tool) do
          tool = course.context_external_tools.new(
            name: "bob",
            consumer_key: "bob",
            shared_secret: "bob",
            tool_id: "some_tool",
            privacy_level: "public",
            developer_key: dev_key
          )
          tool.url = "http://www.example.com/basic_lti"
          tool.resource_selection = {
            url: "http://#{HostUrl.default_host}/selection_test",
            selection_width: 400,
            selection_height: 400
          }
          tool.settings[:selection_width] = 500
          tool.settings[:selection_height] = 300
          tool.settings[:custom_fields] = { "test_token" => "$com.instructure.PostMessageToken" }
          tool.save!
          tool
        end

        let(:content_tag) { ContentTag.create(id: 42, content: tool, url: tool.url) }

        before do
          allow(controller).to receive(:named_context_url).and_return("wrong_url")
          allow(controller).to receive(:render)
          allow(controller).to receive_messages(js_env: [])
          allow(controller).to receive(:require_user) { user_model }

          controller.instance_variable_set(:@current_user, user)
          controller.instance_variable_set(:@context, course)
          controller.instance_variable_set(:@domain_root_account, course.account)
        end

        context "display type" do
          before do
            allow(controller).to receive(:lti_launch_params) { {} }
            content_tag.update!(context: assignment_model)
          end

          context 'display_type == "full_width' do
            before do
              tool.settings[:assignment_selection] = { "display_type" => "full_width" }
              tool.save!
            end

            it 'uses the tool setting display type if the "display" parameter is absent' do
              expect(Lti::AppUtil).to receive(:display_template).with("full_width")
              controller.send(:content_tag_redirect, course, content_tag, nil)
            end

            it "does not use the assignment lti header" do
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:prepend_template]).to be_blank
            end

            it "does not display the assignment edit sidebar" do
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:append_template]).to_not be_present
            end

            context "ENV.LTI_TOOL_FORM_ID" do
              it "sets a random id" do
                expect(controller).to receive(:random_lti_tool_form_id).and_return("1")
                expect(controller).to receive(:js_env).with(LTI_TOOL_FORM_ID: "1")
                controller.send(:content_tag_redirect, course, content_tag, nil)
              end
            end
          end

          context 'display_type == "in_nav_context"' do
            before do
              tool.settings[:assignment_selection] = { "display_type" => "in_nav_context" }
              tool.save!
            end

            it "does not display the assignment lti header" do
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:prepend_template]).to be_blank
            end

            it "does display the assignment edit sidebar" do
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:append_template]).to be_present
            end
          end

          it 'gives priority to the "display" parameter' do
            expect(Lti::AppUtil).to receive(:display_template).with("borderless")
            controller.params["display"] = "borderless"
            controller.send(:content_tag_redirect, course, content_tag, nil)
          end

          it "overrides the configured display_type for the quiz_lti in module context" do
            allow(content_tag.context).to receive(:quiz_lti?).and_return(true)
            module1 = course.context_modules.create!(name: "Module 1")
            content_tag.context.context_module_tags.create!(context_module: module1, context: course, tag_type: "context_module")

            expect(Lti::AppUtil).to receive(:display_template).with("in_nav_context")
            controller.send(:content_tag_redirect, course, content_tag, nil)
          end

          it "does not raise an error if the display type of the placement is not set" do
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

        context "lti version" do
          before do
            allow(controller).to receive_messages(lti_grade_passback_api_url: "wrong_url",
                                                  blti_legacy_grade_passback_api_url: "wrong_url",
                                                  lti_turnitin_outcomes_placement_url: "wrong_url")
            content_tag.update!(context: assignment_model)
          end

          describe "LTI 1.3" do
            let_once(:developer_key) do
              d = DeveloperKey.create!
              enable_developer_key_account_binding! d
              d
            end
            let_once(:account) { Account.default }

            include_context "lti_1_3_spec_helper"

            before do
              tool.developer_key = developer_key
              tool.use_1_3 = true
              tool.save!

              assignment = assignment_model(submission_types: "external_tool", external_tool_tag: content_tag)
              content_tag.update!(context: assignment)
            end

            shared_examples_for "a placement that caches the launch" do
              let(:verifier) { "e5e774d015f42370dcca2893025467b414d39009dfe9a55250279cca16f5f3c2704f9c56fef4cea32825a8f72282fa139298cf846e0110238900567923f9d057" }
              let(:redis_key) { "#{course.class.name}:#{Lti::RedisMessageClient::LTI_1_3_PREFIX}#{verifier}" }
              let(:cached_launch) { JSON.parse(Canvas.redis.get(redis_key)) }

              before do
                allow(SecureRandom).to receive(:hex).and_return(verifier)
                controller.send(:content_tag_redirect, course, content_tag, nil)
              end

              it "caches the LTI 1.3 launch" do
                expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiResourceLinkRequest"
              end

              it "creates a login message" do
                expect(assigns[:lti_launch].params.keys).to match_array %w[
                  iss
                  login_hint
                  target_link_uri
                  lti_message_hint
                  canvas_region
                  canvas_environment
                  client_id
                  deployment_id
                  lti_storage_target
                ]
              end

              it 'sets the "login_hint" to the current user lti id' do
                expect(assigns[:lti_launch].params["login_hint"]).to eq Lti::Asset.opaque_identifier_for(user)
              end

              it "does not use the oidc_initiation_url as the resource_url" do
                expect(assigns[:lti_launch].resource_url).to eq tool.url
              end

              it 'sets the "canvas_domain" to the request domain' do
                message_hint = JSON::JWT.decode(assigns[:lti_launch].params["lti_message_hint"], :skip_verification)
                expect(message_hint["canvas_domain"]).to eq "localhost"
              end

              context "when the developer key has an oidc_initiation_url" do
                before do
                  tool.developer_key.update!(oidc_initiation_url:)
                  controller.send(:content_tag_redirect, course, content_tag, nil)
                end

                let(:oidc_initiation_url) { "https://www.test.com/oidc/login" }

                it "does use the oidc_initiation_url as the resource_url" do
                  expect(assigns[:lti_launch].resource_url).to eq oidc_initiation_url
                end
              end

              context "when the content tag has a custom url" do
                let(:custom_url) { "http://www.example.com/basic_lti?deep_linking=true" }

                before do
                  content_tag.update!(url: custom_url)
                  controller.send(:content_tag_redirect, course, content_tag, nil)
                end

                it "uses the custom url as the target_link_uri" do
                  expect(assigns[:lti_launch].params["target_link_uri"]).to eq custom_url
                end
              end
            end

            context "assignments" do
              it_behaves_like "a placement that caches the launch"

              context "when a 1.3 tool replaces an LTI 1.1 tool" do
                let(:assignment) { content_tag.context }

                before do
                  # assignments configured with LTI 1.1 will not have
                  # LineItem or ResouceLink records prior to the LTI 1.3
                  # launch.
                  assignment.line_items.destroy_all

                  Lti::ResourceLink.where(
                    resource_link_uuid: assignment.lti_context_id
                  ).destroy_all

                  assignment.update!(lti_context_id: SecureRandom.uuid)

                  controller.send(:content_tag_redirect, course, content_tag, nil)
                end

                it "creates the default line item" do
                  expect(assignment.line_items).to be_present
                end

                it "creates the LTI resource link" do
                  expect(
                    Lti::ResourceLink.where(resource_link_uuid: assignment.lti_context_id)
                  ).to be_present
                end
              end
            end

            context "module items" do
              before do
                content_tag.update!(
                  context: course,
                  associated_asset: Lti::ResourceLink.create_with(course, tool, { abc: "def" }, "http://www.example.com/launch")
                )
              end

              it_behaves_like "a placement that caches the launch" do
                it "sets link-level custom parameters" do
                  expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/custom"]).to include("abc" => "def")
                end
              end
            end
          end

          it "creates a basic lti launch request when tool is not configured to use LTI 1.3" do
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:lti_launch].params["lti_message_type"]).to eq "basic-lti-launch-request"
          end

          it "does not use the oidc_initiation_url as the resource_url" do
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:resource_url]).to eq tool.url
          end
        end

        context "return_url" do
          before do
            content_tag.update!(context: assignment_model)
            allow(content_tag.context).to receive(:quiz_lti?).and_return(true)
            allow(controller).to receive(:lti_launch_params)
            allow(controller).to receive_messages(require_user: true,
                                                  named_context_url: "named_context_url",
                                                  polymorphic_url: "host/quizzes")
          end

          context "is set to homepage page when launched from homepage" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1")
              expect(controller).to receive(:polymorphic_url).with([course]).and_return("host")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100")
              expect(controller).to receive(:polymorphic_url).with([course]).and_return("host")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host"
            end
          end

          context "is set to gradebook page when launched from gradebook page" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1/gradebook")
              expect(controller).to receive(:polymorphic_url).with([course, :gradebook]).and_return("host/gradebook")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/gradebook"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100/gradebook")
              expect(controller).to receive(:polymorphic_url).with([course, :gradebook]).and_return("host/gradebook")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/gradebook"
            end
          end

          context "is set to modules page when launched from modules page" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1/modules")
              expect(controller).to receive(:polymorphic_url).with([course, :context_modules]).and_return("host/modules")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/modules"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100/modules")
              expect(controller).to receive(:polymorphic_url).with([course, :context_modules]).and_return("host/modules")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/modules"
            end
          end

          context "is set to assignments page when launched from assignments page" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1/assignments")
              expect(controller).to receive(:polymorphic_url).with([course, :assignments]).and_return("host/assignments")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/assignments"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100/assignments")
              expect(controller).to receive(:polymorphic_url).with([course, :assignments]).and_return("host/assignments")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/assignments"
            end
          end

          context "is set to quizzes page when launched from quizzes page" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1/quizzes")
              controller.context.root_account.enable_feature! :newquizzes_on_quiz_page
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/quizzes"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100/quizzes")
              controller.context.root_account.enable_feature! :newquizzes_on_quiz_page
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/quizzes"
            end
          end

          context "is set to modules page when launched from edit page accessed from modules" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1/assignments/100/edit?module_item_id=42")
              expect(controller).to receive(:polymorphic_url).with([course, :context_modules]).and_return("host/modules")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/modules"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100/assignments/1/edit?module_item_id=42")
              expect(controller).to receive(:polymorphic_url).with([course, :context_modules]).and_return("host/modules")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/modules"
            end
          end

          context "is set to assignments page when launched from edit page accessed from assignments" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1/assignments/1/edit")
              expect(controller).to receive(:polymorphic_url).with([course, :assignments]).and_return("host/assignments")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/assignments"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100/assignments/100/edit")
              expect(controller).to receive(:polymorphic_url).with([course, :assignments]).and_return("host/assignments")
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/assignments"
            end
          end

          context "is set to quizzes page when launched from edit page accessed from quizzes" do
            it "for small id" do
              allow(controller.request).to receive(:referer).and_return("courses/1/assignments/1/edit?quiz_lti")
              controller.context.root_account.enable_feature! :newquizzes_on_quiz_page
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/quizzes"
            end

            it "for large id" do
              allow(controller.request).to receive(:referer).and_return("courses/100/assignments/100/edit?quiz_lti")
              controller.context.root_account.enable_feature! :newquizzes_on_quiz_page
              controller.send(:content_tag_redirect, course, content_tag, nil)
              expect(assigns[:return_url]).to eq "host/quizzes"
            end
          end

          it "is set to quizzes page when launched from assignments/new" do
            allow(controller.request).to receive(:referer).and_return("assignments/new")
            controller.context.root_account.enable_feature! :newquizzes_on_quiz_page
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:return_url]).to eq "host/quizzes"
          end

          it "is not set to quizzes page when flag is disabled" do
            allow(controller.request).to receive(:referer).and_return("assignments/new")
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:return_url]).to eq "named_context_url"
          end

          it "is not set to quizzes page when there is no referer" do
            allow(controller.request).to receive(:referer).and_return(nil)
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:return_url]).to eq "named_context_url"
          end

          it "is set using named_context_url when not launched from quizzes page" do
            allow(controller.request).to receive(:referer).and_return("assignments")
            controller.context.root_account.enable_feature! :newquizzes_on_quiz_page
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:return_url]).to eq "named_context_url"
          end

          it 'is set using named_context_url when not launched from quizzes page and referrer includes "quiz"' do
            allow(controller.request).to receive(:referer).and_return("somequizzessub.com/assignments")
            controller.context.root_account.enable_feature! :newquizzes_on_quiz_page
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:return_url]).to eq "named_context_url"
          end
        end

        context "with environment-specific overrides" do
          let(:override_url) { "http://www.example-beta.com/basic_lti" }

          before do
            allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")

            tool.settings[:environments] = {
              launch_url: override_url
            }
            tool.save!
          end

          it "uses override for launch_url" do
            controller.send(:content_tag_redirect, course, content_tag, nil)
            expect(assigns[:lti_launch].resource_url).to eq override_url
          end
        end

        it "logs the launch" do
          allow(Lti::LogService).to receive(:new) do
            double("Lti::LogService").tap { |s| allow(s).to receive(:call) }
          end

          controller.send(:content_tag_redirect, course, content_tag, nil)

          expect(Lti::LogService).to have_received(:new).with(
            tool:,
            context: course,
            user:,
            placement: nil,
            launch_type: :content_item
          )
        end

        it "returns the full path for the redirect url" do
          expect(controller).to receive(:named_context_url).with(course, :context_url, { include_host: true })
          expect(controller).to receive(:named_context_url).with(
            course,
            :context_external_content_success_url,
            "external_tool_redirect",
            { include_host: true }
          ).and_return("wrong_url")
          controller.send(:content_tag_redirect, course, content_tag, nil)
        end

        it "sets the resource_link_id correctly" do
          controller.send(:content_tag_redirect, course, content_tag, nil)
          expect(assigns[:lti_launch].params["resource_link_id"]).to eq "e62d81a8a1587cdf9d3bbc3de0ef303d6bc70d78"
        end

        it "sets the post message token" do
          controller.send(:content_tag_redirect, course, content_tag, nil)
          expect(assigns[:lti_launch].params["custom_test_token"]).to be_present
        end

        context "tool dimensions" do
          context "when ContentTag provides selection_width or selection_height" do
            before do
              content_tag.update(link_settings: { selection_width: 543, selection_height: 321 })
            end

            it "uses selection_width and selection_height from the ContentTag if provided" do
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "543px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "321px"
            end

            it "uses selection_width from tool.settings[\"selection_width\"] if the ContentTag's is nil" do
              content_tag.update(link_settings: { selection_width: nil, selection_height: 321 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "500px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "321px"
            end

            it "uses selection_width from tool.settings[\"selection_width\"] if the ContentTag's is \"\"" do
              content_tag.update(link_settings: { selection_width: "", selection_height: 321 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "500px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "321px"
            end

            it "uses selection_height from tool.settings[\"selection_height\"] if the ContentTag`s is nil" do
              content_tag.update(link_settings: { selection_width: 543, selection_height: nil })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "543px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "300px"
            end

            it "uses selection_height from tool.settings[\"selection_height\"] if the ContentTag`s is \"\"" do
              content_tag.update(link_settings: { selection_width: 543, selection_height: "" })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "543px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "300px"
            end
          end

          context "when ContentTag doesn't have link_settings and tool.settings provides selection_width or selection_height" do
            # ContextExternalTool#normalize_sizes! converts settings[:selection_width] and settings[:selection_height] to integer

            it "uses selection_width and selection_height from the tool.settings if provided" do
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "500px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "300px"
            end

            it "uses 100% for selection_width when is not provided by tool.settings" do
              tool.update(settings: { selection_height: 300 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "100%"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "300px"
            end

            it "uses 100% for selection_width when tool.settings[\"selection_width\"] is nil" do
              tool.update(settings: { selection_width: nil, selection_height: 300 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "100%"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "300px"
            end

            it "uses 100% for selection_width when tool.settings[\"selection_width\"] is 0" do
              tool.update(settings: { selection_width: 0, selection_height: 300 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "100%"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "300px"
            end

            it "uses 100% for selection_width when tool.settings[\"selection_width\"] is \"\"" do
              tool.update(settings: { selection_width: "", selection_height: 300 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "100%"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "300px"
            end

            it "uses 100% for selection_height when is not provided" do
              tool.update(settings: { selection_width: 500 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "500px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "100%"
            end

            it "uses 100% for selection_height when tool.settings[\"selection_height\"] is nil" do
              tool.update(settings: { selection_width: 500, selection_height: nil })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "500px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "100%"
            end

            it "uses 100% for selection_height when tool.settings[\"selection_height\"] is 0" do
              tool.update(settings: { selection_width: 500, selection_height: 0 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "500px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "100%"
            end

            it "uses 100% for selection_height when tool.settings[\"selection_height\"] is \"\"" do
              tool.update(settings: { selection_width: 500, selection_height: "" })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "500px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "100%"
            end
          end

          context "misc" do
            it "appends px to tool dimensions when receives numeric values" do
              tool.update(settings: { selection_width: 50, selection_height: 90 })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "50px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "90px"
            end

            it "does not appends px to tool dimensions when dimensions already have px or %" do
              content_tag.update(link_settings: { selection_width: "543px", selection_height: "90%" })
              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "543px"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "90%"
            end

            it "does not appends px to tool dimensions when ContentTag and tool.settings don't provide the dimensions" do
              # in this case, it will use the default values: { selection_width: "100%", selection_height: "100%" }
              # see ApplicationController#tool_dimensions
              tool.settings = {}
              tool.save!
              content_tag = ContentTag.create(content: tool, url: tool.url)

              controller.send(:content_tag_redirect, course, content_tag, nil)

              expect(assigns[:lti_launch].tool_dimensions[:selection_width]).to eq "100%"
              expect(assigns[:lti_launch].tool_dimensions[:selection_height]).to eq "100%"
            end
          end
        end
      end
    end

    describe "external_tools_display_hashes" do
      it "returns empty array if context is group" do
        @course = course_model
        @group = @course.groups.create!(name: "some group")
        tool = @course.context_external_tools.new(name: "bob", consumer_key: "test", shared_secret: "secret", url: "http://example.com")
        tool.account_navigation = { url: "http://example.com", icon_url: "http://example.com", enabled: true }
        tool.save!

        allow(controller).to receive(:polymorphic_url).and_return("http://example.com")
        external_tools = controller.external_tools_display_hashes(:account_navigation, @group)

        expect(external_tools).to eq([])
      end

      it "returns array of tools if context is not group" do
        @course = course_model
        tool = @course.context_external_tools.new(name: "bob", consumer_key: "test", shared_secret: "secret", url: "http://example.com")
        tool.account_navigation = { url: "http://example.com", icon_url: "http://example.com", enabled: true, canvas_icon_class: "icon-commons" }
        tool.save!

        allow(controller).to receive(:polymorphic_url).and_return("http://example.com")
        external_tools = controller.external_tools_display_hashes(:account_navigation, @course)

        expect(external_tools).to eq([{ id: tool.id, title: "bob", base_url: "http://example.com", icon_url: "http://example.com", canvas_icon_class: "icon-commons" }])
      end

      it "doesn't return tools that are mapped to disabled feature flags -- course navigation" do
        @course = course_model
        tool = analytics_2_tool_factory(context: @course)

        allow(controller).to receive(:polymorphic_url).and_return("http://example.com")
        external_tools = controller.external_tools_display_hashes(:course_navigation, @course)
        expect(external_tools).not_to include({ title: "Analytics 2", base_url: "http://example.com", icon_url: nil, canvas_icon_class: "icon-analytics", tool_id: ContextExternalTool::ANALYTICS_2 })

        @course.enable_feature!(:analytics_2)
        external_tools = controller.external_tools_display_hashes(:course_navigation, @course)
        expect(external_tools).to include({ id: tool.id, title: "Analytics 2", base_url: "http://example.com", icon_url: nil, canvas_icon_class: "icon-analytics", tool_id: ContextExternalTool::ANALYTICS_2 })
      end

      it "doesn't return tools that are mapped to disabled feature flags -- account navigation" do
        @account = account_model
        tool = admin_analytics_tool_factory(context: @account)

        allow(controller).to receive(:polymorphic_url).and_return("http://admin_analytics.example.com/")
        external_tools = controller.external_tools_display_hashes(:account_navigation, @account)
        expect(external_tools).not_to include({ title: "Admin Analytics", base_url: "http://admin_analytics.example.com/", icon_url: nil, canvas_icon_class: "icon-analytics", tool_id: ContextExternalTool::ADMIN_ANALYTICS })

        @account.enable_feature!(:admin_analytics)
        external_tools = controller.external_tools_display_hashes(:account_navigation, @account)
        expect(external_tools).to include({ id: tool.id, title: "Admin Analytics", base_url: "http://admin_analytics.example.com/", icon_url: nil, canvas_icon_class: "icon-analytics", tool_id: ContextExternalTool::ADMIN_ANALYTICS })
      end

      context "LTI tool has a submission_type_selection placement" do
        let(:developer_key) { DeveloperKey.create! }
        let(:domain) { "http://example.com" }
        let(:tool1) { external_tool_1_3_model(developer_key:, opts: { domain:, settings: { submission_type_selection: {} } }) }
        let(:tool2) { external_tool_1_3_model(developer_key:, opts: { domain:, settings: { submission_type_selection: {} } }) }

        def setup_tools
          allow(Lti::ContextToolFinder).to receive(:all_tools_for).and_return([tool1, tool2])
          allow(controller).to receive(:polymorphic_url).and_return(domain)
        end

        context "lti_placement_restrictions FF on" do
          before do
            expect(Account.site_admin).to receive(:feature_enabled?).with(:lti_placement_restrictions).and_return(true)
          end

          it "is filtering out not allowed placements" do
            setup_tools
            expect(tool1).to receive(:placement_allowed?).and_return(true)
            expect(tool2).to receive(:placement_allowed?).and_return(false)
            external_tools = controller.send(:external_tools_display_hashes, :submission_type_selection)
            expect(external_tools).to include({ id: tool1.id, title: "a", base_url: domain, icon_url: nil, canvas_icon_class: nil })
            expect(external_tools).to_not include({ id: tool2.id, title: "a", base_url: domain, icon_url: nil, canvas_icon_class: nil })
          end
        end

        context "lti_placement_restrictions FF off" do
          before do
            expect(Account.site_admin).to receive(:feature_enabled?).with(:lti_placement_restrictions).and_return(false)
          end

          it "is not filtering out not allowed placements" do
            setup_tools
            external_tools = controller.send(:external_tools_display_hashes, :submission_type_selection)
            expect(external_tools).to include({ id: tool1.id, title: "a", base_url: domain, icon_url: nil, canvas_icon_class: nil })
            expect(external_tools).to include({ id: tool2.id, title: "a", base_url: domain, icon_url: nil, canvas_icon_class: nil })
          end
        end
      end
    end

    describe "external_tool_display_hash" do
      def tool_settings(setting, include_class = false)
        settings_hash = {
          url: "http://example.com/?#{setting}",
          icon_url: "http://example.com/icon.png?#{setting}",
          enabled: true
        }

        settings_hash[:canvas_icon_class] = "icon-#{setting}" if include_class
        settings_hash
      end

      before :once do
        @course = course_model
        @group = @course.groups.create!(name: "some group")
        @tool = @course.context_external_tools.new(name: "bob", consumer_key: "test", shared_secret: "secret", url: "http://example.com")

        @tool_settings = %i[
          user_navigation
          course_navigation
          account_navigation
          resource_selection
          editor_button
          homework_submission
          migration_selection
          course_home_sub_navigation
          course_settings_sub_navigation
          global_navigation
          assignment_menu
          file_menu
          discussion_topic_menu
          module_menu
          quiz_menu
          wiki_page_menu
          tool_configuration
          link_selection
          assignment_selection
          post_grades
        ]

        @tool_settings.each do |setting|
          @tool.send(:"#{setting}=", tool_settings(setting))
        end
        @tool.save!
      end

      before do
        allow(controller).to receive(:request).and_return(ActionDispatch::TestRequest.create)
        controller.instance_variable_set(:@context, @course)
      end

      it "returns a hash" do
        hash = controller.external_tool_display_hash(@tool, :account_navigation)
        left_over_keys = hash.keys - %i[id base_url title icon_url canvas_icon_class]
        expect(left_over_keys).to eq []
      end

      it "all settings are correct" do
        @tool_settings.each do |setting|
          hash = controller.external_tool_display_hash(@tool, setting)
          expect(hash[:base_url]).to eq "http://test.host/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=#{setting}"
          expect(hash[:icon_url]).to eq "http://example.com/icon.png?#{setting}"
          expect(hash[:canvas_icon_class]).to be_nil
        end
      end

      it "doesn't return an invalid icon_url" do
        totallyavalidurl = %{');"></i>nothing to see here</button><img src=x onerror="alert(document.cookie);alert(document.domain);" />}
        @tool.settings[:editor_button][:icon_url] = totallyavalidurl
        @tool.save!
        hash = controller.external_tool_display_hash(@tool, :editor_button)
        expect(hash[:icon_url]).to be_nil
      end

      it "all settings return canvas_icon_class if set" do
        @tool_settings.each do |setting|
          @tool.send(:"#{setting}=", tool_settings(setting, true))
          @tool.save!

          hash = controller.external_tool_display_hash(@tool, setting)
          expect(hash[:base_url]).to eq "http://test.host/courses/#{@course.id}/external_tools/#{@tool.id}?launch_type=#{setting}"
          expect(hash[:icon_url]).to eq "http://example.com/icon.png?#{setting}"
          expect(hash[:canvas_icon_class]).to eq "icon-#{setting}"
        end
      end
    end

    describe "verify_authenticity_token" do
      before do
        # default setup is a protected non-GET non-API session-authenticated request with bogus tokens
        cookies = ActionDispatch::Cookies::CookieJar.new(controller.request)
        controller.allow_forgery_protection = true
        allow(controller.request).to receive_messages(cookie_jar: cookies, get?: false, head?: false, path: "/non-api/endpoint")
        controller.instance_variable_set(:@current_user, User.new)
        controller.instance_variable_set(:@pseudonym_session, "session-authenticated")
        controller.params[controller.request_forgery_protection_token] = "bogus"
        controller.request.headers["X-CSRF-Token"] = "bogus"
      end

      it "raises InvalidAuthenticityToken with invalid tokens" do
        allow(controller).to receive(:valid_request_origin?).and_return(true)
        expect { controller.send(:verify_authenticity_token) }.to raise_exception(ActionController::InvalidAuthenticityToken)
      end

      it "does not raise with valid token" do
        controller.request.headers["X-CSRF-Token"] = controller.form_authenticity_token
        expect { controller.send(:verify_authenticity_token) }.not_to raise_exception
      end

      it "still raises on session-authenticated api request with invalid tokens" do
        allow(controller.request).to receive(:path).and_return("/api/endpoint")
        allow(controller).to receive(:valid_request_origin?).and_return(true)
        expect { controller.send(:verify_authenticity_token) }.to raise_exception(ActionController::InvalidAuthenticityToken)
      end

      it "does not raise on token-authenticated api request despite invalid tokens" do
        allow(controller.request).to receive(:path).and_return("/api/endpoint")
        controller.instance_variable_set(:@pseudonym_session, nil)
        expect { controller.send(:verify_authenticity_token) }.not_to raise_exception
      end
    end
  end

  describe "flash_notices" do
    it "returns notice text for each type" do
      %i[error warning info notice].each do |type|
        flash[type] = type.to_s
      end
      expect(controller.send(:flash_notices)).to match_array([
                                                               { type: "error", content: "error", icon: "warning" },
                                                               { type: "warning", content: "warning", icon: "warning" },
                                                               { type: "info", content: "info", icon: "info" },
                                                               { type: "success", content: "notice", icon: "check" }
                                                             ])
    end

    it "wraps html notification text in an object" do
      flash[:html_notice] = "<p>hello</p>"
      expect(controller.send(:flash_notices)).to match_array([
                                                               { type: "success", content: { html: "<p>hello</p>" }, icon: "check" }
                                                             ])
    end
  end

  describe "#ms_office?" do
    it "detects Word 2011 for mac" do
      controller.request.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X) Word/14.57.0"
      expect(controller.send(:ms_office?)).to be true
    end
  end

  describe "#get_all_pertinent_contexts" do
    it "doesn't show unpublished courses to students" do
      student = user_factory(active_all: true)
      c1 = course_factory
      e = c1.enroll_student(student)
      e.update_attribute(:workflow_state, "active")
      c2 = course_factory(active_all: true)
      c2.enroll_student(student).accept!

      controller.instance_variable_set(:@context, student)
      controller.send(:get_all_pertinent_contexts)
      expect(controller.instance_variable_get(:@contexts).select { |c| c.is_a?(Course) }).to eq [c2]
    end

    it "doesn't touch the database if there are no valid courses" do
      user_factory
      controller.instance_variable_set(:@context, @user)

      expect(Course).not_to receive(:where)
      controller.send(:get_all_pertinent_contexts, only_contexts: "Group_1")
    end

    it "doesn't touch the database if there are no valid groups" do
      user_factory
      controller.instance_variable_set(:@context, @user)

      expect(@user).not_to receive(:current_groups)
      controller.send(:get_all_pertinent_contexts, include_groups: true, only_contexts: "Course_1")
    end

    context "sharding" do
      specs_require_sharding

      it "does not asplode with cross-shard groups" do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        @shard1.activate do
          account = Account.create!
          teacher_in_course(user: @user, active_all: true, account:)
          @other_group = group_model(context: @course)
          group_model(context: @course)
          @group.add_user(@user)
        end
        controller.send(:get_all_pertinent_contexts, include_groups: true, only_contexts: "group_#{@other_group.id},group_#{@group.id}")
        expect(controller.instance_variable_get(:@contexts).select { |c| c.is_a?(Group) }).to eq [@group]
      end

      it "does not include groups in courses the user doesn't have the ability to view yet" do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        course_factory
        student_in_course(user: @user, course: @course)
        expect(@course).to_not be_available
        expect(@user.cached_currentish_enrollments).to be_empty
        @other_group = group_model(context: @course)
        group_model(context: @course)
        @group.add_user(@user)

        controller.send(:get_all_pertinent_contexts, include_groups: true)
        expect(controller.instance_variable_get(:@contexts).select { |c| c.is_a?(Group) }).to be_empty
      end

      it "must select all cross-shard courses the user belongs to" do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        account = Account.create!
        enrollment1 = course_with_teacher(user: @user, active_all: true, account:)
        course1 = enrollment1.course

        enrollment2 = @shard1.activate do
          account = Account.create!
          course_with_teacher(user: @user, active_all: true, account:)
        end
        course2 = enrollment2.course

        controller.send(:get_all_pertinent_contexts, cross_shard: true)
        contexts = controller.instance_variable_get(:@contexts)
        expect(contexts).to include course1, course2
      end

      it "must select only the specified cross-shard courses when only_contexts is included" do
        user_factory(active_all: true)
        controller.instance_variable_set(:@context, @user)

        account = Account.create!
        enrollment1 = course_with_teacher(user: @user, active_all: true, account:)
        course1 = enrollment1.course

        enrollment2 = @shard1.activate do
          account = Account.create!
          course_with_teacher(user: @user, active_all: true, account:)
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

  describe "#discard_flash_if_xhr" do
    subject(:discard) do
      flash.instance_variable_get(:@discard)
    end

    before do
      flash[:notice] = "A flash notice"
    end

    it "sets flash discard if request is xhr" do
      allow(controller.request).to receive_messages(xhr?: true)

      expect(discard).to be_empty, "precondition"
      controller.send(:discard_flash_if_xhr)
      expect(discard).to all(match(/^notice$/))
    end

    it "sets flash discard if request format is text/plain" do
      allow(controller.request).to receive_messages(xhr?: false, format: "text/plain")

      expect(discard).to be_empty, "precondition"
      controller.send(:discard_flash_if_xhr)
      expect(discard).to all(match(/^notice$/))
    end

    it "leaves flash as is if conditions are not met" do
      allow(controller.request).to receive_messages(xhr?: false, format: "text/html")

      expect(discard).to be_empty, "precondition"
      controller.send(:discard_flash_if_xhr)
      expect(discard).to be_empty
    end
  end

  describe "#setup_live_events_context" do
    let(:non_conditional_values) do
      {
        hostname: "test.host",
        user_agent: "Rails Testing",
        client_ip: "0.0.0.0",
        producer: "canvas",
        url: "http://test.host",
        http_method: "GET",
        referrer: nil
      }
    end

    before do
      Thread.current[:context] = nil
    end

    it "stringifies the non-strings in the context attributes" do
      current_user_attributes = { global_id: 12_345, time_zone: "asdf" }

      current_user = double(current_user_attributes)
      controller.instance_variable_set(:@current_user, current_user)
      controller.send(:setup_live_events_context)
      expect(LiveEvents.get_context).to eq({ user_id: "12345", time_zone: "asdf" }.merge(non_conditional_values))
    end

    it 'sets the "context_sis_source_id"' do
      controller.instance_variable_set(:@context, course_model(sis_source_id: "banana"))
      controller.send(:setup_live_events_context)
      expect(LiveEvents.get_context[:context_sis_source_id]).to eq "banana"
    end

    context "when there is a HTTP referrer" do
      it "includes the referer in 'referrer' (two 'r's)" do
        url = "http://example.com/some-referer-url"
        controller.request.headers["HTTP_REFERER"] = url
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(non_conditional_values.merge(referrer: url))
      end
    end

    context "when a domain_root_account exists" do
      let(:root_account_attributes) do
        {
          uuid: "account_uuid1",
          global_id: "account_global1",
          lti_guid: "lti1",
          feature_enabled?: false
        }
      end

      let(:expected_context_attributes) do
        {
          root_account_uuid: "account_uuid1",
          root_account_id: "account_global1",
          root_account_lti_guid: "lti1"
        }.merge(non_conditional_values)
      end

      it "adds root account values to the LiveEvent context" do
        root_account = double(root_account_attributes)
        controller.instance_variable_set(:@domain_root_account, root_account)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context "when a current_user exists" do
      let(:current_user_attributes) do
        {
          global_id: "user_global_id",
          time_zone: "America/Denver"
        }
      end

      let(:expected_context_attributes) do
        {
          user_id: "user_global_id",
          time_zone: "America/Denver"
        }.merge(non_conditional_values)
      end

      it "sets the correct attributes on the LiveEvent context" do
        current_user = double(current_user_attributes)
        controller.instance_variable_set(:@current_user, current_user)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context "when a real current_user exists" do
      let(:real_current_user_attributes) do
        {
          global_id: "real_user_global_id"
        }
      end

      let(:expected_context_attributes) do
        {
          real_user_id: "real_user_global_id"
        }.merge(non_conditional_values)
      end

      it "sets the correct attributes on the LiveEvent context" do
        real_current_user = double(real_current_user_attributes)
        controller.instance_variable_set(:@real_current_user, real_current_user)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context "when an access_token exists" do
      let(:real_access_token_attributes) do
        {
          developer_key: double(global_id: "1111")
        }
      end

      let(:expected_context_attributes) do
        {
          developer_key_id: "1111"
        }.merge(non_conditional_values)
      end

      it "sets the correct attributes on the LiveEvent context" do
        real_access_token = double(real_access_token_attributes)
        controller.instance_variable_set(:@access_token, real_access_token)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context "when a real current_pseudonym exists" do
      let(:current_pseudonym_attributes) do
        {
          unique_id: "unique_id",
          global_account_id: "global_account_id",
          sis_user_id: "sis_user_id"
        }
      end

      let(:expected_context_attributes) do
        {
          user_login: "unique_id",
          user_account_id: "global_account_id",
          user_sis_id: "sis_user_id"
        }.merge(non_conditional_values)
      end

      it "sets the correct attributes on the LiveEvent context" do
        current_pseudonym = double(current_pseudonym_attributes)
        controller.instance_variable_set(:@current_pseudonym, current_pseudonym)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end

    context "when a canvas context exists" do
      let(:canvas_context_attributes) do
        {
          class: Class,
          global_id: "context_global_id"
        }
      end

      let(:expected_context_attributes) do
        {
          context_type: "Class",
          context_id: "context_global_id",
          context_account_id: nil
        }.merge(non_conditional_values)
      end

      it "sets the correct attributes on the LiveEvent context" do
        canvas_context = double(canvas_context_attributes)
        controller.instance_variable_set(:@context, canvas_context)
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end

      context "when a course" do
        let(:course) { course_model }
        let(:expected_context_attributes) do
          {
            context_type: "Course",
            context_id: course.global_id.to_s,
            context_account_id: course.account.global_id.to_s,
            context_sis_source_id: nil
          }.merge(non_conditional_values)
        end

        it "sets the correct attributes on the LiveEvent context" do
          controller.instance_variable_set(:@context, course)
          controller.send(:setup_live_events_context)
          expect(LiveEvents.get_context).to eq(expected_context_attributes)
        end
      end
    end

    context "when a context_membership exists" do
      context "when the context has a role" do
        it "sets the correct attributes on the LiveEvent context" do
          stubbed_role = double({ name: "name" })
          context_membership = double({ role: stubbed_role })

          controller.instance_variable_set(:@context_membership, context_membership)
          controller.send(:setup_live_events_context)
          expect(LiveEvents.get_context).to eq({ context_role: "name" }.merge(non_conditional_values))
        end
      end

      context "when the context has a type" do
        it "sets the correct attributes on the LiveEvent context" do
          context_membership = double({ type: "type" })

          controller.instance_variable_set(:@context_membership, context_membership)
          controller.send(:setup_live_events_context)
          expect(LiveEvents.get_context).to eq({ context_role: "type" }.merge(non_conditional_values))
        end
      end

      context "when the context has neither a role or type" do
        it "sets the correct attributes on the LiveEvent context" do
          context_membership = double({ class: Class })

          controller.instance_variable_set(:@context_membership, context_membership)
          controller.send(:setup_live_events_context)
          expect(LiveEvents.get_context).to eq({ context_role: "Class" }.merge(non_conditional_values))
        end
      end
    end

    context "when the current thread has a context key" do
      let(:thread_attributes) do
        {
          request_id: "request_id",
          session_id: "session_id"
        }
      end

      let(:expected_context_attributes) do
        {
          request_id: "request_id",
          session_id: "session_id"
        }.merge(non_conditional_values)
      end

      it "sets the correct attributes on the LiveEvent context" do
        Thread.current[:context] = thread_attributes
        controller.send(:setup_live_events_context)
        expect(LiveEvents.get_context).to eq(expected_context_attributes)
      end
    end
  end

  describe "show_student_view_button? helper" do
    context "for teachers" do
      before :once do
        course_with_teacher active_all: true
      end

      before do
        user_session @teacher
        controller.instance_variable_set(:@context, @course)
        controller.instance_variable_set(:@current_user, @user)
      end

      it "returns true on course home page" do
        controller.params[:controller] = "courses"
        controller.params[:action] = "show"
        expect(controller.send(:show_student_view_button?)).to be_truthy
      end

      it "returns true on modules page" do
        controller.params[:controller] = "context_modules"
        controller.params[:action] = "index"
        expect(controller.send(:show_student_view_button?)).to be_truthy
      end

      it "returns false if context is not set" do
        controller.instance_variable_set(:@context, nil)
        controller.params[:controller] = "courses"
        controller.params[:action] = "show"
        expect(controller.send(:show_student_view_button?)).to be_falsey
      end

      it "returns false for pages index if pages tab is disabled" do
        @course.update_attribute(:tab_configuration, [{ "id" => Course::TAB_PAGES, "hidden" => true }])
        controller.instance_variable_set(:@context, @course)
        controller.params[:controller] = "wiki_pages"
        controller.params[:action] = "index"
        expect(controller.send(:show_student_view_button?)).to be_falsey
      end

      it "returns true for pages page even if pages tab is disabled" do
        @course.update_attribute(:tab_configuration, [{ "id" => Course::TAB_PAGES, "hidden" => true }])
        controller.instance_variable_set(:@context, @course)
        controller.params[:controller] = "wiki_pages"
        controller.params[:action] = "show"
        expect(controller.send(:show_student_view_button?)).to be_truthy
      end
    end

    context "for students" do
      before :once do
        course_with_student active_all: true
      end

      before do
        user_session @student
        controller.instance_variable_set(:@context, @course)
        controller.instance_variable_set(:@current_user, @user)
      end

      it "returns false regardless of page" do
        controller.params[:controller] = "courses"
        controller.params[:action] = "show"
        expect(controller.send(:show_student_view_button?)).to be_falsey

        controller.params[:controller] = "wiki_pages"
        controller.params[:action] = "show"
        expect(controller.send(:show_student_view_button?)).to be_falsey

        controller.params[:controller] = "assignments"
        controller.params[:action] = "syllabus"
        expect(controller.send(:show_student_view_button?)).to be_falsey
      end
    end
  end

  describe "show_immersive_reader? helper" do
    before(:once) do
      course_with_student(active_all: true)
    end

    before do
      user_session(@student)
      controller.instance_variable_set(:@context, @course)
      controller.instance_variable_set(:@current_user, @student)
    end

    shared_examples_for "pages with an immersive reader flag enabled" do
      it "is true for wiki_pages#show" do
        controller.params[:controller] = "wiki_pages"
        controller.params[:action] = "show"
        expect(controller.send(:show_immersive_reader?)).to be true
      end

      it "is false when there is no logged in user" do
        controller.instance_variable_set(:@current_user, nil)
        controller.params[:controller] = "wiki_pages"
        controller.params[:action] = "show"
        expect(controller.send(:show_immersive_reader?)).to be false
      end

      it "is false on pages where immersive reader is not supported" do
        controller.params[:controller] = "discussion_topics"
        controller.params[:action] = "index"
        expect(controller.send(:show_immersive_reader?)).to be false
      end

      it "is true for the assignments show page" do
        controller.params[:controller] = "assignments"
        controller.params[:action] = "show"
        expect(controller.send(:show_immersive_reader?)).to be true
      end

      it "is true for the course page" do
        controller.params[:controller] = "courses"
        controller.params[:action] = "show"
        expect(controller.send(:show_immersive_reader?)).to be true
      end

      it "is true for the syllabus page" do
        controller.params[:controller] = "assignments"
        controller.params[:action] = "syllabus"
        expect(controller.send(:show_immersive_reader?)).to be true
      end

      it "is true for a wiki front page" do
        controller.params[:controller] = "wiki_pages"
        controller.params[:action] = "front_page"
        expect(controller.send(:show_immersive_reader?)).to be true
      end
    end

    it "is false when no immersive reader flags are enabled, even on supported pages" do
      controller.params[:controller] = "wiki_pages"
      controller.params[:action] = "show"
      expect(controller.send(:show_immersive_reader?)).to be false
    end

    context "when root account has immersive reader flag enabled" do
      before(:once) do
        @course.root_account.enable_feature!(:immersive_reader_wiki_pages)
      end

      it_behaves_like "pages with an immersive reader flag enabled"
    end

    context "when user has immersive reader flag enabled" do
      before do
        @student.enable_feature!(:user_immersive_reader_wiki_pages)
      end

      it_behaves_like "pages with an immersive reader flag enabled"
    end
  end

  describe "new math equation handling feature" do
    let(:root_account) { Account.default }

    before do
      controller.instance_variable_set(:@domain_root_account, root_account)
    end

    it "sets new_math_equation_handling to true" do
      expect(@controller.use_new_math_equation_handling?).to be_truthy
      expect(@controller.js_env[:FEATURES][:new_math_equation_handling]).to be_truthy
    end

    context "with the quizzes#edit action" do
      before do
        allow(controller).to receive(:params).and_return(
          {
            controller: "quizzes/quizzes",
            action: "edit"
          }
        )
      end

      it "sets new_math_equation_handling to false" do
        expect(@controller.use_new_math_equation_handling?).to be_falsey
        expect(@controller.js_env[:FEATURES][:new_math_equation_handling]).to be_falsey
      end
    end

    context "with the question_banks controller" do
      before do
        allow(controller).to receive(:params).and_return(
          {
            controller: "question_banks"
          }
        )
      end

      it "sets new_math_equation_handling to false" do
        expect(@controller.use_new_math_equation_handling?).to be_falsey
        expect(@controller.js_env[:FEATURES][:new_math_equation_handling]).to be_falsey
      end
    end

    context "with the eportfolio_entries controller" do
      before do
        allow(controller).to receive(:params).and_return(
          {
            controller: "eportfolio_entries"
          }
        )
      end

      it "sets new_math_equation_handling to false" do
        expect(@controller.use_new_math_equation_handling?).to be_falsey
        expect(@controller.js_env[:FEATURES][:new_math_equation_handling]).to be_falsey
      end
    end
  end

  describe "k5 helpers" do
    before do
      controller.instance_variable_set(:@current_user, @user)
      controller.instance_variable_set(:@domain_root_account, @account)
    end

    it "k5_user? calls K5::UserService with correct arguments" do
      expect(K5::UserService).to receive(:new).with(@user, @account, nil).and_call_original
      expect_any_instance_of(K5::UserService).to receive(:k5_user?).once
      @controller.send(:k5_user?)
    end

    it "k5_disabled? calls K5::UserService with correct arguments" do
      expect(K5::UserService).to receive(:new).with(@user, @account, nil).and_call_original
      expect_any_instance_of(K5::UserService).to receive(:k5_disabled?).once
      @controller.send(:k5_disabled?)
    end

    it "use_classic_font? calls K5::UserService with correct arguments" do
      expect(K5::UserService).to receive(:new).with(@user, @account, nil).and_call_original
      expect_any_instance_of(K5::UserService).to receive(:use_classic_font?).once
      @controller.send(:use_classic_font?)
    end
  end

  describe "should_show_migration_limitation_message helper" do
    context "for teachers" do
      before :once do
        course_with_teacher active_all: true
      end

      before do
        user_session @teacher
        controller.instance_variable_set(:@context, @course)
        controller.instance_variable_set(:@current_user, @user)
      end

      context "when the teacher has a quiz migration alert" do
        before do
          @quiz_migration_alert =
            QuizMigrationAlert.create!(user_id: @teacher.id, course_id: @course.id, migration_id: "10000000000040")
        end

        it "returns true if the path is allowed" do
          [
            "/courses/1",
            "/courses/1/assignments",
            "/courses/1/quizzes",
            "/courses/1/modules",
          ].each do |path|
            allow(controller).to receive(:request).and_return(double({ path: }))
            expect(controller.send(:should_show_migration_limitation_message)).to be(true)
          end
        end

        it "returns false if he path is not allowed" do
          [
            "/courses/1/gradebook/speed_grader",
            "/courses/1/assignments/1"
          ].each do |path|
            allow(controller).to receive(:request).and_return(double({ path: }))
            expect(controller.send(:should_show_migration_limitation_message)).to be(false)
          end
        end
      end

      context "when the teacher doesn't have a quiz migration alert" do
        it "returns false in any path" do
          [
            "/courses/1",
            "/courses/1/assignments",
            "/courses/1/quizzes",
            "/courses/1/modules",
            "/courses/1/gradebook/speed_grader",
            "/courses/1/assignments/1"
          ].each do |path|
            allow(controller).to receive(:request).and_return(double({ path: }))
            expect(controller.send(:should_show_migration_limitation_message)).to be(false)
          end
        end
      end
    end

    context "for students" do
      before :once do
        course_with_student active_all: true
      end

      before do
        user_session @student
        controller.instance_variable_set(:@context, @course)
        controller.instance_variable_set(:@current_user, @user)
        @quiz_migration_alert =
          QuizMigrationAlert.create!(user_id: @student.id, course_id: @course.id, migration_id: "10000000000040")
      end

      it "returns false even in any path" do
        [
          "/courses/1",
          "/courses/1/assignments",
          "/courses/1/quizzes",
          "/courses/1/modules",
          "/courses/1/some_path",
          "/courses/1/assignments/1"
        ].each do |path|
          allow(controller).to receive(:request).and_return(double({ path: }))
          expect(controller.send(:should_show_migration_limitation_message)).to be(false)
        end
      end
    end
  end
end

describe WikiPagesController do
  describe "set_js_rights" do
    it "populates js_env with policy rights" do
      allow(controller).to receive(:default_url_options).and_return({})

      course_with_teacher_logged_in active_all: true
      controller.instance_variable_set(:@context, @course)

      get "index", params: { course_id: @course.id }

      expect(controller.js_env).to include(:WIKI_RIGHTS)
      expect(controller.js_env[:WIKI_RIGHTS].symbolize_keys).to eq(@course.wiki.check_policy(@teacher).index_with { true })
    end
  end
end

describe CoursesController do
  describe "set_js_wiki_data" do
    before do
      course_with_teacher_logged_in active_all: true
      @course.wiki_pages.create!(title: "blah").set_as_front_page!
      @course.reload
      @course.default_view = "wiki"
      @course.show_announcements_on_home_page = true
      @course.home_page_announcement_limit = 5
      @course.save!
    end

    it "populates js_env with course_home setting" do
      controller.instance_variable_set(:@context, @course)
      get "show", params: { id: @course.id }
      expect(controller.js_env).to include(:COURSE_HOME)
    end

    it "populates js_env with setting for show_announcements flag" do
      controller.instance_variable_set(:@context, @course)
      get "show", params: { id: @course.id }
      expect(controller.js_env).to include(:SHOW_ANNOUNCEMENTS, :ANNOUNCEMENT_LIMIT)
      expect(controller.js_env[:SHOW_ANNOUNCEMENTS]).to be_truthy
      expect(controller.js_env[:ANNOUNCEMENT_LIMIT]).to eq(5)
    end
  end

  describe "set_master_course_js_env_data" do
    before do
      controller.instance_variable_set(:@domain_root_account, Account.default)
      account_admin_user(active_all: true)
      controller.instance_variable_set(:@current_user, @user)

      @master_course = course_factory
      @template = MasterCourses::MasterTemplate.set_as_master_course(@course)
      @master_page = @course.wiki_pages.create!(title: "blah", body: "bloo")
      @tag = @template.content_tag_for(@master_page)

      @child_course = course_factory
      @template.add_child_course!(@child_course)

      @child_page = @child_course.wiki_pages.create!(title: "bloo", body: "bloo", migration_id: @tag.migration_id)
    end

    it "populates master-side data (unrestricted)" do
      controller.set_master_course_js_env_data(@master_page, @master_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data["is_master_course_master_content"]).to be_truthy
      expect(data["restricted_by_master_course"]).to be_falsey
    end

    it "populates master-side data (restricted)" do
      @tag.update_attribute(:restrictions, { content: true })

      controller.set_master_course_js_env_data(@master_page, @master_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data["is_master_course_master_content"]).to be_truthy
      expect(data["restricted_by_master_course"]).to be_truthy
      expect(data["master_course_restrictions"]).to eq({ content: true })
    end

    it "populates child-side data (unrestricted)" do
      controller.set_master_course_js_env_data(@child_page, @child_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data["is_master_course_child_content"]).to be_truthy
      expect(data["restricted_by_master_course"]).to be_falsey
    end

    it "populates child-side data (restricted)" do
      @tag.update_attribute(:restrictions, { content: true })

      controller.set_master_course_js_env_data(@child_page, @child_course)
      data = controller.js_env[:MASTER_COURSE_DATA]
      expect(data["is_master_course_child_content"]).to be_truthy
      expect(data["restricted_by_master_course"]).to be_truthy
      expect(data["master_course_restrictions"]).to eq({ content: true })
    end
  end

  describe "annotate_sentry" do
    it "sets the db_cluster tag correctly" do
      expect(Sentry).to receive(:set_tags).with({ db_cluster: Account.default.shard.database_server.id })
      get "index"
    end
  end

  describe "set_normalized_route" do
    it "does nothing by default" do
      get "index"
      expect(controller.instance_variable_get(:@normalized_route)).to be_nil
    end

    context "when Sentry is enabled on the frontend" do
      before do
        ConfigFile.stub("sentry", { dsn: "dummy-dsn", frontend_dsn: "dummy-frontend-dsn" })
      end

      after do
        ConfigFile.unstub
        SentryExtensions::Settings.reset_settings
      end

      context "given a standard route" do
        it "correctly sets the value" do
          get "index"
          expect(controller.js_env[:SENTRY_FRONTEND][:normalized_route]).to eq("/courses")
        end
      end

      context "given a route with a single path parameter" do
        it "correctly sets the value" do
          get "show", params: { id: 1 }
          expect(controller.js_env[:SENTRY_FRONTEND][:normalized_route]).to eq("/courses/{id}")
        end
      end

      context "given a route with multiple path parameters" do
        it "correctly sets the value" do
          get "settings", params: { course_id: 1 }
          expect(controller.js_env[:SENTRY_FRONTEND][:normalized_route]).to eq("/courses/{course_id}/settings/{full_path}")
        end
      end
    end
  end

  context "validate_scopes" do
    let(:account) { double }

    before do
      controller.instance_variable_set(:@domain_root_account, account)
    end

    it "does not affect session based api requests" do
      allow(controller).to receive(:request).and_return(double({
                                                                 params: {}
                                                               }))
      expect(controller.send(:validate_scopes)).to be_nil
    end

    it "does not affect api requests that use an access token with an unscoped developer key" do
      user = user_model
      developer_key = DeveloperKey.create!
      token = AccessToken.create!(user:, developer_key:)
      controller.instance_variable_set(:@access_token, token)
      allow(controller).to receive(:request).and_return(double({
                                                                 params: {},
                                                                 method: "GET"
                                                               }))
      expect(controller.send(:validate_scopes)).to be_nil
    end

    it "raises AccessTokenScopeError if scopes do not match" do
      user = user_model
      developer_key = DeveloperKey.create!(require_scopes: true)
      token = AccessToken.create!(user:, developer_key:)
      controller.instance_variable_set(:@access_token, token)
      allow(controller).to receive(:request).and_return(double({
                                                                 params: {},
                                                                 method: "GET",
                                                                 path: "/not_allowed_path"
                                                               }))
      expect { controller.send(:validate_scopes) }.to raise_error(AuthenticationMethods::AccessTokenScopeError)
    end

    context "with valid scopes on dev key" do
      let(:developer_key) { DeveloperKey.create!(require_scopes: true, scopes: ["url:GET|/api/v1/accounts"]) }

      it "allows adequately scoped requests through" do
        user = user_model
        token = AccessToken.create!(user:, developer_key:, scopes: ["url:GET|/api/v1/accounts"])
        controller.instance_variable_set(:@access_token, token)
        allow(controller).to receive(:request).and_return(double({
                                                                   params: {},
                                                                   method: "GET",
                                                                   path: "/api/v1/accounts"
                                                                 }))
        expect(controller.send(:validate_scopes)).to be_nil
      end

      it "allows HEAD requests" do
        user = user_model
        token = AccessToken.create!(user:, developer_key:, scopes: ["url:GET|/api/v1/accounts"])
        controller.instance_variable_set(:@access_token, token)
        allow(controller).to receive(:request).and_return(double({
                                                                   params: {},
                                                                   method: "HEAD",
                                                                   path: "/api/v1/accounts"
                                                                 }))
        expect(controller.send(:validate_scopes)).to be_nil
      end

      it "strips includes for adequately scoped requests" do
        user = user_model
        token = AccessToken.create!(user:, developer_key:, scopes: ["url:GET|/api/v1/accounts"])
        controller.instance_variable_set(:@access_token, token)
        params = { include: ["a"], includes: ["uuid", "b"] }
        allow(controller).to receive_messages(request: double({
                                                                method: "GET",
                                                                path: "/api/v1/accounts"
                                                              }),
                                              params:)
        controller.send(:validate_scopes)
        expect(params).to eq(include: [], includes: ["uuid"])
      end
    end

    context "with valid scopes and allow includes on dev key" do
      let(:developer_key) { DeveloperKey.create!(require_scopes: true, allow_includes: true, scopes: ["url:GET|/api/v1/accounts"]) }

      it "keeps includes for adequately scoped requests" do
        user = user_model
        token = AccessToken.create!(user:, developer_key:, scopes: ["url:GET|/api/v1/accounts"])
        controller.instance_variable_set(:@access_token, token)
        params = { include: ["a"], includes: ["uuid", "b"] }
        allow(controller).to receive_messages(request: double({
                                                                method: "GET",
                                                                path: "/api/v1/accounts"
                                                              }),
                                              params:)
        controller.send(:validate_scopes)
        expect(params).to eq(include: ["a"], includes: ["uuid", "b"])
      end
    end
  end
end

RSpec.describe ApplicationController, "#render_unauthorized_action" do
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
    get :index, format:
  end

  describe "pdf format" do
    let(:format) { :pdf }

    specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Atext/html}) }
    specify { expect(response).to have_http_status :unauthorized }
    specify { expect(response).to render_template("shared/unauthorized") }
  end

  describe "html format" do
    let(:format) { :html }

    specify { expect(response.headers.fetch("Content-Type")).to match(%r{\Atext/html}) }
    specify { expect(response).to have_http_status :unauthorized }
    specify { expect(response).to render_template("shared/unauthorized") }
  end

  describe "json format" do
    let(:format) { :json }

    specify { expect(response.headers["Content-Type"]).to match(%r{\Aapplication/json}) }
    specify { expect(response).to have_http_status :unauthorized }
    specify { expect(json_parse.fetch("status")).to eq "unauthorized" }
  end
end

RSpec.describe ApplicationController, "#redirect_to_login" do
  controller do
    def index
      redirect_to_login
    end
  end

  describe "format specified" do
    before do
      get :index, format:
    end

    context "given an unauthenticated json request" do
      let(:format) { :json }

      specify { expect(response).to have_http_status :unauthorized }
      specify { expect(json_parse.fetch("status")).to eq "unauthenticated" }
    end

    shared_examples "redirectable to html login page" do
      specify { expect(flash[:warning]).to eq "You must be logged in to access this page" }
      specify { expect(session[:return_to]).to eq controller.clean_return_to(request.fullpath) }
      specify { expect(response).to redirect_to login_url }
      specify { expect(response).to have_http_status :found }
      specify { expect(response.location).to eq login_url }
    end

    context "given an unauthenticated html request" do
      it_behaves_like "redirectable to html login page" do
        let(:format) { :html }
      end
    end

    context "given an unauthenticated pdf request" do
      it_behaves_like "redirectable to html login page" do
        let(:format) { :pdf }
      end
    end
  end

  describe "format unspecified" do
    before do
      request.headers["HTTP_ACCEPT"] = "*/*"
      get :index
    end

    context "given an unauthenticated request" do
      specify { expect(session[:return_to]).to eq controller.clean_return_to(request.fullpath) }
      specify { expect(response).to redirect_to login_url }
      specify { expect(response).to have_http_status :found }
      specify { expect(response.location).to eq login_url }
    end
  end
end

RSpec.describe ApplicationController, "#respect_account_privacy" do
  controller do
    before_action :require_user, only: :index

    def index
      render json: [{}]
    end

    def login
      render json: [{}]
    end

    def public
      render json: "anyone can see this"
    end
  end

  context "when the account it set to require requests be authenticated" do
    let(:account) { Account.default }

    before do
      controller.instance_variable_set(:@domain_root_account, account)
      account.settings[:require_user] = true
      account.save
    end

    after do
      account.settings.delete(:require_user)
      account.save
    end

    it "allows unauthenticated users to login" do
      routes.draw { get "login" => "anonymous#login" }
      params = { controller: "login/test_controller" }
      allow(controller).to receive(:params).and_return(params)
      response = get "login"
      expect(response.code).not_to eq("302")
    end

    it "redirects requests to login for unauthenticated users" do
      routes.draw { get "public" => "anonymous#public" }
      response = get "public"
      expect(response.code).to eq("302")
    end

    context "with an authenticated user" do
      before do
        user_factory
        user_session(@user)
      end

      it "allows requests" do
        response = get "index"
        expect(response.code).not_to eq("302")
      end
    end
  end
end

RSpec.describe ApplicationController, "#manage_live_events_context" do
  controller do
    def index
      render json: [{}]
    end
  end

  it "sets the context to nil after request" do
    Thread.current[:live_events_ctx] = {}

    get :index, format: :html

    expect(Thread.current[:live_events_ctx]).to be_nil
  end
end

RSpec.describe ApplicationController, "#compute_http_cost" do
  include WebMock::API

  controller do
    def index
      if params[:do_http].to_i > 0
        CanvasHttp.get("http://www.example.com/test")
      end
      if params[:do_error].to_i > 0
        raise StandardError, "Test Error Handling"
      end

      render json: [{}]
    end
  end

  it "has no cost for non http actions" do
    get :index, params: { do_http: 0, do_error: 0 }
    expect(response).to have_http_status :success
    expect(CanvasHttp.cost).to eq(0)
    expect(controller.request.env["extra-request-cost"]).to be_nil
  end

  it "has some cost for http actions (in seconds)" do
    stub_request(:get, "http://www.example.com/test")
      .to_return(status: 200, body: "", headers: {})
    start_time = Time.now
    get :index, params: { do_http: 1, do_error: 0 }
    expect(response).to have_http_status :success
    end_time = Time.now
    expect(CanvasHttp.cost > 0).to be_truthy
    expect(CanvasHttp.cost <= (end_time - start_time)).to be_truthy
    expect(controller.request.env["extra-request-cost"]).to eq(CanvasHttp.cost)
  end

  it "tracks costs through errors" do
    stub_request(:get, "http://www.example.com/test")
      .to_return(status: 200, body: "", headers: {})
    get :index, params: { do_http: 1, do_error: 1 }
    expect(response).to have_http_status :internal_server_error
    expect(CanvasHttp.cost > 0).to be_truthy
    expect(controller.request.env["extra-request-cost"]).to eq(CanvasHttp.cost)
  end
end
