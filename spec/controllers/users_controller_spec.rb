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

require "feedjira"
require_relative "../lti_1_3_spec_helper"
require_relative "../helpers/k5_common"

describe UsersController do
  include K5Common

  let(:group_helper) { Factories::GradingPeriodGroupHelper.new }

  describe "external_tool" do
    let(:account) { Account.default }

    let :tool do
      tool = account.context_external_tools.new({
                                                  name: "bob",
                                                  consumer_key: "bob",
                                                  shared_secret: "bob",
                                                  tool_id: "some_tool",
                                                  privacy_level: "public"
                                                })
      tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
      tool.resource_selection = {
        url: "http://#{HostUrl.default_host}/selection_test",
        selection_width: 400,
        selection_height: 400
      }
      user_navigation = {
        text: "example",
        labels: {
          "en" => "English Label",
          "sp" => "Spanish Label"
        }
      }
      tool.settings[:user_navigation] = user_navigation
      tool.save!
      tool
    end

    let_once(:user) { user_factory(active_all: true) }
    before do
      account.account_users.create!(user:)
      user_session(user)
    end

    context "ENV.LTI_TOOL_FORM_ID" do
      it "sets a random id" do
        expect(controller).to receive(:random_lti_tool_form_id).and_return("1")
        allow(controller).to receive(:js_env).with(anything).and_call_original
        expect(controller).to receive(:js_env).with(LTI_TOOL_FORM_ID: "1")
        get :external_tool, params: { id: tool.id, user_id: user.id }
      end
    end

    it "removes query string when post_only = true" do
      tool.user_navigation = { text: "example" }
      tool.settings["post_only"] = "true"
      tool.save!

      get :external_tool, params: { id: tool.id, user_id: user.id }
      expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basic_lti"
    end

    it "does not remove query string from url" do
      tool.user_navigation = { text: "example" }
      tool.save!

      get :external_tool, params: { id: tool.id, user_id: user.id }
      expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basic_lti?first=john&last=smith"
    end

    it "uses localized labels" do
      get :external_tool, params: { id: tool.id, user_id: user.id }
      expect(tool.label_for(:user_navigation, :en)).to eq "English Label"
    end

    it "includes the correct context_asset_string" do
      get :external_tool, params: { id: tool.id, user_id: user.id }
      expect(controller.js_env[:context_asset_string]).to eq "user_#{user.id}"
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

      it "uses override for launch_url and includes original query parameters" do
        get :external_tool, params: { id: tool.id, user_id: user.id }
        expect(assigns[:lti_launch].resource_url).to eq override_url + "?first=john&last=smith"
      end
    end

    context "using LTI 1.3 when specified" do
      include_context "lti_1_3_spec_helper"

      let(:verifier) { "e5e774d015f42370dcca2893025467b414d39009dfe9a55250279cca16f5f3c2704f9c56fef4cea32825a8f72282fa139298cf846e0110238900567923f9d057" }
      let(:redis_key) { "#{assigns[:domain_root_account].class_name}:#{Lti::RedisMessageClient::LTI_1_3_PREFIX}#{verifier}" }
      let(:cached_launch) { JSON.parse(Canvas.redis.get(redis_key)) }
      let(:developer_key) { DeveloperKey.create! }

      before do
        allow(SecureRandom).to receive(:hex).and_return(verifier)
        tool.use_1_3 = true
        tool.developer_key = developer_key
        tool.save!
        get :external_tool, params: { id: tool.id, user_id: user.id }
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

      it "caches the LTI 1.3 launch" do
        expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiResourceLinkRequest"
      end

      it "does not use the oidc_initiation_url as the resource_url" do
        expect(assigns[:lti_launch].resource_url).to eq tool.url
      end

      it 'sets the "canvas_domain" to the request domain' do
        message_hint = JSON::JWT.decode(assigns[:lti_launch].params["lti_message_hint"], :skip_verification)
        expect(message_hint["canvas_domain"]).to eq "localhost"
      end

      context "when the developer key has an oidc_initiation_url" do
        let(:developer_key) { DeveloperKey.create!(oidc_initiation_url:) }
        let(:oidc_initiation_url) { "https://www.test.com/oidc/login" }

        it "uses the oidc_initiation_url as the resource_url" do
          expect(assigns[:lti_launch].resource_url).to eq oidc_initiation_url
        end
      end
    end
  end

  describe "GET oauth" do
    it "sets up oauth for google_drive" do
      state = nil
      settings_mock = double
      allow(settings_mock).to receive_messages(settings: {}, enabled?: true)

      user_factory(active_all: true)
      user_session(@user)

      allow(Canvas::Plugin).to receive(:find).and_return(settings_mock)
      allow(SecureRandom).to receive(:hex).and_return("abc123")
      expect(GoogleDrive::Client).to receive(:auth_uri) { |_c, s|
                                       state = s
                                       "http://example.com/redirect"
                                     }

      get :oauth, params: { service: "google_drive", return_to: "http://example.com" }

      expect(response).to redirect_to "http://example.com/redirect"
      json = Canvas::Security.decode_jwt(state)
      expect(session[:oauth_gdrive_nonce]).to eq "abc123"
      expect(json["redirect_uri"]).to eq oauth_success_url(service: "google_drive")
      expect(json["return_to_url"]).to eq "http://example.com"
      expect(json["nonce"]).to eq session[:oauth_gdrive_nonce]
    end
  end

  describe "GET oauth_success" do
    it "handles google_drive oauth_success for a logged_in_user" do
      settings_mock = double
      allow(settings_mock).to receive(:settings).and_return({})
      authorization_mock = instance_double("Google::Auth::UserRefreshCredentials",
                                           :code= => nil,
                                           :fetch_access_token! => nil,
                                           :refresh_token => "refresh_token",
                                           :access_token => "access_token")
      about_mock = instance_double("Google::Apis::DriveV3::About",
                                   user: instance_double("Google::Apis::DriveV3::User",
                                                         email_address: "blah@blah.com",
                                                         permission_id: "permission_id"))
      client_mock = instance_double("Google::Apis::DriveV3::DriveService",
                                    get_about: about_mock,
                                    authorization: authorization_mock)
      allow(GoogleDrive::Client).to receive(:create).and_return(client_mock)

      session[:oauth_gdrive_nonce] = "abc123"
      state = Canvas::Security.create_jwt({ "return_to_url" => "http://localhost.com/return",
                                            "nonce" => "abc123" })
      course_with_student_logged_in

      get :oauth_success, params: { state:, service: "google_drive", code: "some_code" }

      service = UserService.where(user_id: @user,
                                  service: "google_drive",
                                  service_domain: "drive.google.com").first
      expect(service.service_user_id).to eq "permission_id"
      expect(service.service_user_name).to eq "blah@blah.com"
      expect(service.token).to eq "refresh_token"
      expect(service.secret).to eq "access_token"
      expect(session[:oauth_gdrive_nonce]).to be_nil
    end

    it "handles google_drive oauth_success for a non logged in user" do
      settings_mock = double
      allow(settings_mock).to receive(:settings).and_return({})
      authorization_mock = instance_double("Google::Auth::UserRefreshCredentials",
                                           :code= => nil,
                                           :fetch_access_token! => nil,
                                           :refresh_token => "refresh_token",
                                           :access_token => "access_token")
      client_mock = instance_double("Google::Apis::DriveV3::DriveService",
                                    get_about: nil,
                                    authorization: authorization_mock)
      allow(GoogleDrive::Client).to receive(:create).and_return(client_mock)

      session[:oauth_gdrive_nonce] = "abc123"
      state = Canvas::Security.create_jwt({ "return_to_url" => "http://localhost.com/return",
                                            "nonce" => "abc123" })

      get :oauth_success, params: { state:, service: "google_drive", code: "some_code" }

      expect(session[:oauth_gdrive_access_token]).to eq "access_token"
      expect(session[:oauth_gdrive_refresh_token]).to eq "refresh_token"
      expect(session[:oauth_gdrive_nonce]).to be_nil
    end

    it "rejects invalid state" do
      settings_mock = double
      allow(settings_mock).to receive(:settings).and_return({})
      authorization_mock = instance_double("Google::Auth::UserRefreshCredentials")
      allow(authorization_mock).to receive_messages(:code= => nil,
                                                    :fetch_access_token! => nil,
                                                    :refresh_token => "refresh_token",
                                                    :access_token => "access_token")
      client_mock = instance_double("Google::Apis::DriveV3::DriveService",
                                    get_about: nil,
                                    authorization: authorization_mock)
      allow(GoogleDrive::Client).to receive(:create).and_return(client_mock)

      state = Canvas::Security.create_jwt({ "return_to_url" => "http://localhost.com/return",
                                            "nonce" => "abc123" })
      get :oauth_success, params: { state:, service: "google_drive", code: "some_code" }

      assert_unauthorized
      expect(session[:oauth_gdrive_access_token]).to be_nil
      expect(session[:oauth_gdrive_refresh_token]).to be_nil
    end

    it "handles auth failure gracefully" do
      authorization_mock = instance_double("Google::Auth::UserRefreshCredentials", :code= => nil)
      allow(authorization_mock).to receive(:fetch_access_token!) do
        raise Signet::AuthorizationError, "{\"error\": \"invalid_grant\", \"error_description\": \"Bad Request\"}"
      end
      client_mock = instance_double("Google::Apis::DriveV3::DriveService", authorization: authorization_mock)
      allow(GoogleDrive::Client).to receive(:create).and_return(client_mock)
      state = Canvas::Security.create_jwt({ "return_to_url" => "http://localhost.com/return",
                                            "nonce" => "abc123" })
      get :oauth_success, params: { state:, service: "google_drive", code: "some_code" }
      expect(response).to be_redirect
      expect(flash[:error]).to eq "Google Drive failed authorization for current user!"
    end
  end

  context "manageable_courses" do
    it "does not include deleted courses in manageable courses" do
      course_with_teacher_logged_in(course_name: "MyCourse1", active_all: 1)
      course1 = @course
      course1.destroy
      course_with_teacher(course_name: "MyCourse2", user: @teacher, active_all: 1)
      course2 = @course

      get "manageable_courses", params: { user_id: @teacher.id, term: "MyCourse" }
      expect(response).to be_successful

      courses = json_parse
      expect(courses.pluck("id")).to eq [course2.id]
    end

    it "does not include future teacher term courses in manageable courses" do
      course_with_teacher_logged_in(course_name: "MyCourse1", active_all: 1)
      term = @course.enrollment_term
      term.enrollment_dates_overrides.create!(
        enrollment_type: "TeacherEnrollment", start_at: 1.week.from_now, end_at: 2.weeks.from_now, context: term.root_account
      )

      get "manageable_courses", params: { user_id: @teacher.id, term: "MyCourse" }
      expect(response).to be_successful

      courses = json_parse
      expect(courses).to be_empty
    end

    it "sorts the results of manageable_courses by name" do
      course_with_teacher_logged_in(course_name: "B", active_all: 1)
      %w[c d a].each do |name|
        course_with_teacher(course_name: name, user: @teacher, active_all: 1)
      end

      get "manageable_courses", params: { user_id: @teacher.id }
      expect(response).to be_successful

      courses = json_parse
      expect(courses.pluck("label")).to eq %w[a B c d]
    end

    it "sorts the results of manageable_courses by term with default term first then alphabetically" do
      # Default term
      course_with_teacher_logged_in(course_name: "E", active_all: 1)
      future_term = EnrollmentTerm.create(start_at: 1.day.from_now, root_account: @teacher.account)
      past_term = EnrollmentTerm.create(start_at: 1.day.ago, root_account: @teacher.account)
      # Future terms
      %w[b a].each do |name|
        course_with_teacher(course_name: name, user: @teacher, active_all: 1, enrollment_term_id: future_term.id)
      end
      # Past terms
      %w[d c].each do |name|
        course_with_teacher(course_name: name, user: @teacher, active_all: 1, enrollment_term_id: past_term.id)
      end

      get "manageable_courses", params: { user_id: @teacher.id }
      expect(response).to be_successful

      courses = json_parse
      expect(courses.pluck("label")).to eq %w[E c d a b]
    end

    it "does not include courses for which the user doesnt have the appropriate rights" do
      @role1 = custom_account_role("subadmin", account: Account.default)
      account_admin_user_with_role_changes(role: @role1, role_changes: { manage_content: false, read_course_content: false })
      course_with_user("TeacherEnrollment", course_name: "A", active_all: true, user: @admin)
      course_with_user("StudentEnrollment", course_name: "B", active_all: true, user: @admin)

      user_session(@admin)

      get "manageable_courses", params: { user_id: @admin.id }
      expect(response).to be_successful
      expect(json_parse.pluck("label")).to eq %w[A B]

      get "manageable_courses", params: { user_id: @admin.id, enforce_manage_grant_requirement: true }
      expect(response).to be_successful
      expect(json_parse.pluck("label")).to eq %w[A]
    end

    it "includes blueprint" do
      course_with_teacher_logged_in(course_name: "Blueprint!", active_all: 1)
      @course1 = @course
      @course2 = course_with_teacher(course_name: "NotBlueprint", user: @teacher, active_all: 1).course
      MasterCourses::MasterTemplate.set_as_master_course(@course1)

      get "manageable_courses", params: { user_id: @teacher.id }
      expect(response).to be_successful
      courses = json_parse
      expect(courses.find { |c| c["id"] == @course1.id }["blueprint"]).to be true
      expect(courses.find { |c| c["id"] == @course2.id }["blueprint"]).to be false
    end

    context "query matching" do
      before do
        course_with_teacher_logged_in(course_name: "Extra course", active_all: 1)
      end

      it "matches query to course id" do
        course_with_teacher(course_name: "Biology", user: @teacher, active_all: 1)
        get "manageable_courses", params: { user_id: @teacher.id, term: @course.id }
        expect(response).to be_successful
        courses = json_parse
        expect(courses.pluck("id")).to eq [@course.id]
      end

      it "matches query to course code" do
        course_code = "BIO 12239"
        course_with_teacher(course_name: "Biology", user: @teacher, active_all: 1)
        @course.course_code = course_code
        @course.save
        get "manageable_courses", params: { user_id: @teacher.id, term: course_code }
        expect(response).to be_successful
        courses = json_parse
        expect(courses.pluck("course_code")).to eq [course_code]
      end
    end

    context "concluded courses" do
      before do
        course_with_teacher_logged_in(course_name: "MyCourse1", active_all: 1)
        course1 = @course
        course1.workflow_state = "completed"
        course1.save!

        past_term = EnrollmentTerm.create(start_at: 14.days.ago, end_at: 7.days.ago, root_account: @teacher.account)
        course_with_teacher(course_name: "MyCourse2", user: @teacher, active_all: 1, enrollment_term_id: past_term.id)

        course_with_teacher(course_name: "MyOldCourse", user: @teacher, active_all: 1, enrollment_term_id: past_term.id)

        course_with_teacher(course_name: "MyCourse3", user: @teacher, active_all: 1)
      end

      it "does not include soft or hard concluded courses for teachers" do
        get "manageable_courses", params: { user_id: @teacher.id, term: "MyCourse" }
        expect(response).to be_successful
        courses = json_parse
        expect(courses.pluck("id")).to eq [@course.id]
      end

      it "does not include soft or hard concluded courses for admins" do
        account_admin_user
        user_session(@admin)

        get "manageable_courses", params: { user_id: @admin.id, term: "MyCourse" }
        expect(response).to be_successful
        courses = json_parse
        expect(courses.pluck("id")).to eq [@course.id]
      end

      it "includes concluded courses for teachers when passing include = 'concluded'" do
        get "manageable_courses", params: { user_id: @teacher.id, include: "concluded" }
        expect(response).to be_successful
        courses = json_parse

        expect(courses.pluck("course_code").sort).to eq %w[MyCourse1 MyCourse2 MyCourse3 MyOldCourse].sort
      end

      it "includes concluded courses for admins when passing include = 'concluded'" do
        account_admin_user
        user_session(@admin)

        get "manageable_courses", params: { user_id: @admin.id, include: "concluded" }
        expect(response).to be_successful
        courses = json_parse

        expect(courses.pluck("course_code").sort).to eq %w[MyCourse1 MyCourse2 MyCourse3 MyOldCourse].sort
      end

      it "includes courses with overridden dates as not concluded for teachers if the course period is active" do
        my_old_course = Course.find_by(course_code: "MyOldCourse")
        my_old_course.restrict_enrollments_to_course_dates = true
        my_old_course.start_at = 2.weeks.ago
        my_old_course.conclude_at = 2.weeks.from_now
        my_old_course.save!

        get "manageable_courses", params: { user_id: @teacher.id }
        expect(response).to be_successful
        courses = json_parse
        expect(courses.pluck("course_code")).to include("MyOldCourse")
      end

      it "includes courses with overridden dates as not concluded for admins if the course period is active" do
        my_old_course = Course.find_by(course_code: "MyOldCourse")
        my_old_course.restrict_enrollments_to_course_dates = true
        my_old_course.start_at = 2.weeks.ago
        my_old_course.conclude_at = 2.weeks.from_now
        my_old_course.save!

        account_admin_user
        user_session(@admin)

        get "manageable_courses", params: { user_id: @admin.id }
        expect(response).to be_successful
        courses = json_parse
        expect(courses.pluck("course_code")).to include("MyOldCourse")
      end
    end

    context "sharding" do
      specs_require_sharding

      it "is able to find courses on other shards" do
        course_with_teacher_logged_in(course_name: "Blah", active_all: 1)
        @shard1.activate do
          @other_account = Account.create
          @cs_course = @other_account.courses.create!(name: "A cross shard course", workflow_state: "available")
          @cs_course.enroll_user(@teacher, "TeacherEnrollment", enrollment_state: "active")
        end

        get "manageable_courses", params: { user_id: @teacher.id }
        # should sort the cross-shard course before the current shard one
        expect(json_parse.pluck("label")).to eq [@cs_course.name, @course.name]
      end
    end
  end

  describe "POST 'create'" do
    it "does not allow creating when self_registration is disabled and you're not an admin'" do
      post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal" } }
      expect(response).not_to be_successful
    end

    context "self registration" do
      before do
        Account.default.canvas_authentication_provider.update_attribute(:self_registration, true)
      end

      context "self registration for observers only" do
        before do
          Account.default.canvas_authentication_provider.update_attribute(:self_registration, "observer")
        end

        it "does not allow teachers to self register" do
          post "create", params: { pseudonym: { unique_id: "jane@example.com" }, user: { name: "Jane Teacher", terms_of_use: "1", initial_enrollment_type: "teacher" } }, format: "json"
          assert_status(403)
        end

        it "does not allow students to self register" do
          course_factory(active_all: true)
          @course.update_attribute(:self_enrollment, true)

          post "create", params: { pseudonym: { unique_id: "jane@example.com", password: "lolwut12", password_confirmation: "lolwut12" }, user: { name: "Jane Student", terms_of_use: "1", self_enrollment_code: @course.self_enrollment_code, initial_enrollment_type: "student" }, pseudonym_type: "username", self_enrollment: "1" }, format: "json"
          assert_status(403)
        end

        it "allows observers to self register" do
          user_with_pseudonym(active_all: true, password: "lolwut12")
          course_with_student(user: @user, active_all: true)
          pairing_code = @student.generate_observer_pairing_code

          post "create", params: { pseudonym: { unique_id: "jane@example.com" }, pairing_code: { code: pairing_code.code }, user: { name: "Jane Observer", terms_of_use: "1", initial_enrollment_type: "observer" } }, format: "json"
          expect(response).to be_successful
          new_pseudo = Pseudonym.where(unique_id: "jane@example.com").first
          new_user = new_pseudo.user
          expect(new_user.linked_students).to eq [@user]
          oe = new_user.observer_enrollments.first
          expect(oe.course).to eq @course
          expect(oe.associated_user).to eq @user
        end

        it "does not 500 when paring code is not in request" do
          post "create", params: { pseudonym: { unique_id: "jane@example.com" }, user: { name: "Jane Observer", terms_of_use: "1", initial_enrollment_type: "observer" } }, format: "json"
          assert_status(400)
        end

        it "allows observers to self register with a pairing code" do
          course_with_student
          @domain_root_account = @course.account
          pairing_code = @student.generate_observer_pairing_code

          post "create",
               params: {
                 pseudonym: {
                   unique_id: "jon@example.com",
                   password: "password",
                   password_confirmation: "password"
                 },
                 user: {
                   name: "Jon",
                   terms_of_use: "1",
                   initial_enrollment_type: "observer",
                   skip_registration: "1"
                 },
                 pairing_code: {
                   code: pairing_code.code
                 }
               },
               format: "json"

          expect(response).to be_successful
          new_pseudo = Pseudonym.where(unique_id: "jon@example.com").first
          new_user = new_pseudo.user
          expect(new_pseudo.crypted_password).not_to be_nil
          expect(new_user.linked_students).to eq [@student]
          oe = new_user.observer_enrollments.first
          expect(oe.course).to eq @course
          expect(oe.associated_user).to eq @student
        end

        it "does not send a confirmation email when using a pairing_code and skip_confirmation" do
          course_with_student
          @domain_root_account = @course.account
          pairing_code = @student.generate_observer_pairing_code

          post "create",
               params: {
                 pseudonym: {
                   unique_id: "jon@example.com",
                   password: "password",
                   password_confirmation: "password"
                 },
                 user: {
                   name: "Jon",
                   terms_of_use: "1",
                   initial_enrollment_type: "observer",
                   skip_registration: "1"
                 },
                 communication_channel: {
                   skip_confirmation: true
                 },
                 pairing_code: {
                   code: pairing_code.code
                 }
               },
               format: "json"

          expect(response).to be_successful
          new_pseudo = Pseudonym.where(unique_id: "jon@example.com").first
          new_user = new_pseudo.user
          message = Message.where(user_id: new_user.id)
          expect(message.count).to eq 0
        end

        it "redirects users to the oauth confirmation when registering through oauth" do
          redis = double("Redis")
          allow(redis).to receive(:setex)
          allow(redis).to receive(:hmget)
          allow(redis).to receive(:del)
          allow(Canvas).to receive_messages(redis:)
          key = DeveloperKey.create! redirect_uri: "https://example.com"
          provider = Canvas::OAuth::Provider.new(key.id, key.redirect_uri, [], nil)

          course_with_student
          @domain_root_account = @course.account
          pairing_code = @student.generate_observer_pairing_code

          post "create",
               params: {
                 pseudonym: {
                   unique_id: "jon@example.com",
                   password: "password",
                   password_confirmation: "password"
                 },
                 user: {
                   name: "Jon",
                   terms_of_use: "1",
                   initial_enrollment_type: "observer",
                   skip_registration: "1"
                 },
                 pairing_code: {
                   code: pairing_code.code
                 }
               },
               format: "json",
               session: { oauth2: provider.session_hash }

          expect(response).to be_successful
          json = json_parse
          expect(json["destination"]).to eq "http://test.host/login/oauth2/confirm"
        end

        it "redirects 'new' action to root_url" do
          get "new"
          expect(response).to redirect_to root_url
        end
      end

      it "creates a pre_registered user" do
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal", terms_of_use: "1" } }
        expect(response).to be_successful

        p = Pseudonym.where(unique_id: "jacob@instructure.com").first
        expect(p).to be_active
        expect(p.user).to be_pre_registered
        expect(p.user.name).to eq "Jacob Fugal"
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq "jacob@instructure.com"
        expect(p.user.associated_accounts).to eq [Account.default]
        expect(p.user.preferences[:accepted_terms]).to be_truthy
      end

      it "marks user as having accepted the terms of use if specified" do
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal", terms_of_use: "1" } }
        json = response.parsed_body
        accepted_terms = json["user"]["user"]["preferences"]["accepted_terms"]
        expect(response).to be_successful
        expect(accepted_terms).to be_present
        expect(Time.parse(accepted_terms)).to be_within(1.minute.to_i).of(Time.now.utc)
      end

      it "stores a confirmation_redirect url if it's trusted" do
        allow(CommunicationChannel).to receive(:trusted_confirmation_redirect?)
          .with(Account.default, "https://benevolent.place")
          .and_return(true)

        post "create", params: {
          pseudonym: { unique_id: "jacob@instructure.com" },
          user: { name: "Jacob Fugal", terms_of_use: "1" },
          communication_channel: { confirmation_redirect: "https://benevolent.place" }
        }
        expect(response).to be_successful
        expect(CommunicationChannel.last.confirmation_redirect).to eq("https://benevolent.place")
      end

      it "does not store a confirmation_redirect url if it's not trusted" do
        allow(CommunicationChannel).to receive(:trusted_confirmation_redirect?)
          .with(Account.default, "https://nasty.place")
          .and_return(false)

        post "create", params: {
          pseudonym: { unique_id: "jacob@instructure.com" },
          user: { name: "Jacob Fugal", terms_of_use: "1" },
          communication_channel: { confirmation_redirect: "https://nasty.place" }
        }
        expect(response).to be_successful
        expect(CommunicationChannel.last.confirmation_redirect).to be_nil
      end

      it "creates a registered user if the skip_registration flag is passed in" do
        post("create", params: {
               pseudonym: { unique_id: "jacob@instructure.com" },
               user: { name: "Jacob Fugal", terms_of_use: "1", skip_registration: "1" }
             })
        expect(response).to be_successful

        p = Pseudonym.where(unique_id: "jacob@instructure.com").first
        expect(p).to be_active
        expect(p.user).to be_registered
        expect(p.user.name).to eq "Jacob Fugal"
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq "jacob@instructure.com"
        expect(p.user.associated_accounts).to eq [Account.default]
      end

      it "complains about conflicting unique_ids" do
        u = User.create! { |user| user.workflow_state = "registered" }
        p = u.pseudonyms.create!(unique_id: "jacob@instructure.com")
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal", terms_of_use: "1" } }
        assert_status(400)
        json = response.parsed_body
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
        expect(Pseudonym.by_unique_id("jacob@instructure.com")).to eq [p]
      end

      it "does not complain about conflicting ccs, in any state" do
        user1, user2, user3 = User.create!, User.create!, User.create!
        cc1 = communication_channel(user1, { username: "jacob@instructure.com" })
        cc2 = communication_channel(user2, { username: "jacob@instructure.com", cc_state: "confirmed" })
        cc3 = communication_channel(user3, { username: "jacob@instructure.com", cc_state: "retired" })

        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal", terms_of_use: "1" } }
        expect(response).to be_successful

        p = Pseudonym.where(unique_id: "jacob@instructure.com").first
        expect(p).to be_active
        expect(p.user).to be_pre_registered
        expect(p.user.name).to eq "Jacob Fugal"
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq "jacob@instructure.com"
        expect([cc1, cc2, cc3]).not_to include(p.user.communication_channels.first)
      end

      it "re-uses 'conflicting' unique_ids if it hasn't been fully registered yet" do
        u = User.create!(workflow_state: "creation_pending")
        p = Pseudonym.create!(unique_id: "jacob@instructure.com", user: u)
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal", terms_of_use: "1" } }
        expect(response).to be_successful

        expect(Pseudonym.by_unique_id("jacob@instructure.com")).to eq [p]
        p.reload
        expect(p).to be_active
        expect(p.user).to be_pre_registered
        expect(p.user.name).to eq "Jacob Fugal"
        expect(p.user.communication_channels.length).to eq 1
        expect(p.user.communication_channels.first).to be_unconfirmed
        expect(p.user.communication_channels.first.path).to eq "jacob@instructure.com"

        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal", terms_of_use: "1" } }
        expect(response).not_to be_successful
      end

      it "validates acceptance of the terms" do
        Account.default.create_terms_of_service!(terms_type: "default", passive: false)
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal" } }
        assert_status(400)
        json = response.parsed_body
        expect(json["errors"]["user"]["terms_of_use"]).to be_present
      end

      it "does not validate acceptance of the terms if terms are passive" do
        Account.default.create_terms_of_service!(terms_type: "default")
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal" } }
        expect(response).to be_successful
      end

      it "does not validate acceptance of the terms if not required by account" do
        default_account = Account.default
        Account.default.create_terms_of_service!(terms_type: "default")
        default_account.save!

        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal" } }
        expect(response).to be_successful
      end

      it "requires email pseudonyms by default" do
        post "create", params: { pseudonym: { unique_id: "jacob" }, user: { name: "Jacob Fugal", terms_of_use: "1" } }
        assert_status(400)
        json = response.parsed_body
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
      end

      it "requires email pseudonyms if not self enrolling" do
        post "create", params: { pseudonym: { unique_id: "jacob" }, user: { name: "Jacob Fugal", terms_of_use: "1" }, pseudonym_type: "username" }
        assert_status(400)
        json = response.parsed_body
        expect(json["errors"]["pseudonym"]["unique_id"]).to be_present
      end

      it "validates the self enrollment code" do
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com", password: "asdfasdf", password_confirmation: "asdfasdf" }, user: { name: "Jacob Fugal", terms_of_use: "1", self_enrollment_code: "omg ... not valid", initial_enrollment_type: "student" }, self_enrollment: "1" }
        assert_status(400)
        json = response.parsed_body
        expect(json["errors"]["user"]["self_enrollment_code"]).to be_present
      end

      it "ignores the password if not self enrolling" do
        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com", password: "asdfasdf", password_confirmation: "asdfasdf" }, user: { name: "Jacob Fugal", terms_of_use: "1", initial_enrollment_type: "student" } }
        expect(response).to be_successful
        u = User.where(name: "Jacob Fugal").first
        expect(u).to be_pre_registered
        expect(u.pseudonym).to be_password_auto_generated
      end

      context "self enrollment" do
        before(:once) do
          Account.default.allow_self_enrollment!
          course_factory(active_all: true)
          @course.update_attribute(:self_enrollment, true)
        end

        it "strips the self enrollment code before validation" do
          post "create", params: { pseudonym: { unique_id: "jacob@instructure.com", password: "asdfasdf", password_confirmation: "asdfasdf" }, user: { name: "Jacob Fugal", terms_of_use: "1", self_enrollment_code: @course.self_enrollment_code + " ", initial_enrollment_type: "student" }, self_enrollment: "1" }
          expect(response).to be_successful
        end

        it "sets root_account_ids" do
          post "create", params: { pseudonym: { unique_id: "jacob@instructure.com", password: "asdfasdf", password_confirmation: "asdfasdf" },
                                   user: { name: "happy gilmore", terms_of_use: "1", self_enrollment_code: @course.self_enrollment_code + " ", initial_enrollment_type: "student" },
                                   self_enrollment: "1" }
          expect(response).to be_successful
          u = User.where(name: "happy gilmore").take
          expect(u.root_account_ids).to eq [Account.default.id]
        end

        it "ignores the password if self enrolling with an email pseudonym" do
          post "create", params: { pseudonym: { unique_id: "jacob@instructure.com", password: "asdfasdf", password_confirmation: "asdfasdf" }, user: { name: "Jacob Fugal", terms_of_use: "1", self_enrollment_code: @course.self_enrollment_code, initial_enrollment_type: "student" }, pseudonym_type: "email", self_enrollment: "1" }
          expect(response).to be_successful
          u = User.where(name: "Jacob Fugal").first
          expect(u).to be_pre_registered
          expect(u.pseudonym).to be_password_auto_generated
        end

        it "requires a password if self enrolling with a non-email pseudonym" do
          post "create", params: { pseudonym: { unique_id: "jacob" }, user: { name: "Jacob Fugal", terms_of_use: "1", self_enrollment_code: @course.self_enrollment_code, initial_enrollment_type: "student" }, pseudonym_type: "username", self_enrollment: "1" }
          assert_status(400)
          json = response.parsed_body
          expect(json["errors"]["pseudonym"]["password"]).to be_present
          expect(json["errors"]["pseudonym"]["password_confirmation"]).to be_present
        end

        it "auto-registers the user if self enrolling" do
          post "create", params: { pseudonym: { unique_id: "jacob", password: "asdfasdf", password_confirmation: "asdfasdf" }, user: { name: "Jacob Fugal", terms_of_use: "1", self_enrollment_code: @course.self_enrollment_code, initial_enrollment_type: "student" }, pseudonym_type: "username", self_enrollment: "1" }
          expect(response).to be_successful
          u = User.where(name: "Jacob Fugal").first
          expect(@course.students).to include(u)
          expect(u).to be_registered
          expect(u.pseudonym).not_to be_password_auto_generated
        end
      end

      it "links the user to the observee" do
        user = user_with_pseudonym(active_all: true, password: "lolwut12")
        pairing_code = user.generate_observer_pairing_code

        post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, pairing_code: { code: pairing_code.code }, user: { name: "Jacob Fugal", terms_of_use: "1", initial_enrollment_type: "observer" } }
        expect(response).to be_successful
        u = User.where(name: "Jacob Fugal").first
        expect(u).to be_pre_registered
        expect(response).to be_successful
        expect(u.linked_students).to include(@user)
      end
    end

    context "account admin creating users" do
      describe "successfully" do
        let!(:account) { Account.create! }

        before do
          user_with_pseudonym(account:)
          account.account_users.create!(user: @user)
          user_session(@user, @pseudonym)
        end

        it "creates a pre_registered user (in the correct account)" do
          post "create", params: { account_id: account.id, pseudonym: { unique_id: "jacob@instructure.com", sis_user_id: "testsisid" }, user: { name: "Jacob Fugal" } }, format: "json"
          expect(response).to be_successful
          p = Pseudonym.where(unique_id: "jacob@instructure.com").first
          expect(p.account_id).to eq account.id
          expect(p).to be_active
          expect(p.sis_user_id).to eq "testsisid"
          expect(p.user).to be_pre_registered
        end

        it "creates users with non-email pseudonyms" do
          post "create", params: { account_id: account.id, pseudonym: { unique_id: "jacob", sis_user_id: "testsisid", integration_id: "abc", path: "" }, user: { name: "Jacob Fugal" } }, format: "json"
          expect(response).to be_successful
          p = Pseudonym.where(unique_id: "jacob").first
          expect(p.account_id).to eq account.id
          expect(p).to be_active
          expect(p.sis_user_id).to eq "testsisid"
          expect(p.integration_id).to eq "abc"
          expect(p.user).to be_pre_registered
        end

        it "reassigns null values when passing empty strings for pseudonym[integration_id]" do
          post "create",
               params: { account_id: account.id,
                         pseudonym: { unique_id: "jacob", sis_user_id: "testsisid", integration_id: "", path: "" },
                         user: { name: "Jacob Fugal" } },
               format: "json"
          expect(response).to be_successful
          p = Pseudonym.where(unique_id: "jacob").first
          expect(p.account_id).to eq account.id
          expect(p).to be_active
          expect(p.sis_user_id).to eq "testsisid"
          expect(p.integration_id).to be_nil
          expect(p.user).to be_pre_registered
        end

        it "creates users with non-email pseudonyms and an email" do
          post "create", params: { account_id: account.id, pseudonym: { unique_id: "testid", path: "testemail@example.com" }, user: { name: "test" } }, format: "json"
          expect(response).to be_successful
          p = Pseudonym.where(unique_id: "testid").first
          expect(p.user.email).to eq "testemail@example.com"
        end

        it "does not require acceptance of the terms" do
          post "create", params: { account_id: account.id, pseudonym: { unique_id: "jacob@instructure.com" }, user: { name: "Jacob Fugal" } }
          expect(response).to be_successful
        end

        it "allows setting a password" do
          post "create", params: { account_id: account.id, pseudonym: { unique_id: "jacob@instructure.com", password: "asdfasdf", password_confirmation: "asdfasdf" }, user: { name: "Jacob Fugal" } }
          u = User.where(name: "Jacob Fugal").first
          expect(u).to be_present
          expect(u.pseudonym).not_to be_password_auto_generated
        end

        it "allows admins to force the self-registration workflow for a given user" do
          expect_any_instance_of(Pseudonym).to receive(:send_confirmation!)
          post "create", params: { account_id: account.id,
                                   pseudonym: {
                                     unique_id: "jacob@instructure.com",
                                     password: "asdfasdf",
                                     password_confirmation: "asdfasdf",
                                     force_self_registration: "1",
                                   },
                                   user: { name: "Jacob Fugal" } }
          expect(response).to be_successful
          u = User.where(name: "Jacob Fugal").first
          expect(u).to be_present
          expect(u.pseudonym).not_to be_password_auto_generated
        end

        it "does not throw a 500 error without user params'" do
          post "create", params: { pseudonym: { unique_id: "jacob@instructure.com" }, account_id: account.id }
          expect(response).to be_successful
        end

        it "does not throw a 500 error without pseudonym params'" do
          post "create", params: { user: { name: "Jacob Fugal" }, account_id: account.id }
          assert_status(400)
          expect(response).not_to be_successful
        end

        it "strips whitespace from the unique_id" do
          post "create", params: { account_id: account.id, pseudonym: { unique_id: "spaceman@example.com " }, user: { name: "Spaceman" } }, format: "json"
          expect(response).to be_successful
          json = response.parsed_body
          p = Pseudonym.find(json["pseudonym"]["pseudonym"]["id"])
          expect(p.unique_id).to eq "spaceman@example.com"
          expect(p.user.email).to eq "spaceman@example.com"
        end
      end

      it "does not allow an admin to set the sis id when creating a user if they don't have privileges to manage sis" do
        account = Account.create!
        admin = account_admin_user_with_role_changes(account:, role_changes: { "manage_sis" => false })
        user_session(admin)
        post "create", params: { account_id: account.id, pseudonym: { unique_id: "jacob@instructure.com", sis_user_id: "testsisid" }, user: { name: "Jacob Fugal" } }, format: "json"
        expect(response).to be_successful
        p = Pseudonym.where(unique_id: "jacob@instructure.com").first
        expect(p.account_id).to eq account.id
        expect(p).to be_active
        expect(p.sis_user_id).to be_nil
        expect(p.user).to be_pre_registered
      end

      context "merge opportunity notifications" do
        before do
          @notification = Notification.create(name: "Merge Email Communication Channel", category: "Registration")
          @account = Account.create!
          user_with_pseudonym(account: @account)
          @account.account_users.create!(user: @user)
          user_session(@user, @pseudonym)
          @admin = @user

          @u = User.create! { |user| user.workflow_state = "registered" }
          communication_channel(@u, { username: "jacob@instructure.com", active_cc: true })
        end

        it "notifies the user if a merge opportunity arises" do
          @u.pseudonyms.create!(unique_id: "jon@instructure.com")

          post "create",
               params: {
                 account_id: @account.id,
                 pseudonym: {
                   unique_id: "jacob@instructure.com",
                   send_confirmation: "0"
                 },
                 user: {
                   name: "Jacob Fugal"
                 }
               },
               format: "json"
          expect(response).to be_successful
          p = Pseudonym.where(unique_id: "jacob@instructure.com").first
          expect(Message.where(communication_channel_id: p.user.email_channel, notification_id: @notification).first).to be_present
        end

        it "does not notify user of opportunity when suppress_notifications = true" do
          initial_message_count = Message.count
          @u.pseudonyms.create!(unique_id: "jon@instructure.com")
          @account.settings[:suppress_notifications] = true
          @account.save!

          post "create",
               params: {
                 account_id: @account.id,
                 pseudonym: {
                   unique_id: "jacob@instructure.com",
                   send_confirmation: "0"
                 },
                 user: {
                   name: "Jacob Fugal"
                 }
               },
               format: "json"
          expect(response).to be_successful
          expect(Message.count).to eq initial_message_count
        end

        it "does not notify the user if the merge opportunity can't log in'" do
          post "create",
               params: {
                 account_id: @account.id,
                 pseudonym: {
                   unique_id: "jacob@instructure.com",
                   send_confirmation: "0"
                 },
                 user: {
                   name: "Jacob Fugal"
                 }
               },
               format: "json"
          expect(response).to be_successful
          p = Pseudonym.where(unique_id: "jacob@instructure.com").first
          expect(Message.where(communication_channel_id: p.user.email_channel, notification_id: @notification).first).to be_nil
        end
      end
    end
  end

  describe "#validate_recaptcha" do
    # Let's make sure we never actually hit recaptcha in specs
    before do
      WebMock.disable_net_connect!
      Account.default.canvas_authentication_provider.enable_captcha = true
      subject.instance_variable_set(:@domain_root_account, Account.default)

      subject.request = ActionController::TestRequest.create(subject.class)
      subject.request.host = "canvas.docker"

      WebMock.stub_request(:post, "https://www.google.com/recaptcha/api/siteverify")
             .with(
               body: { "secret" => "test-token", "response" => "valid-submit-key" }
             )
             .to_return(status: 200, body: { success: true, challenge_ts: Time.zone.now.to_s, hostname: "canvas.docker" }.to_json)

      WebMock.stub_request(:post, "https://www.google.com/recaptcha/api/siteverify")
             .with(
               body: { "secret" => "test-token", "response" => "invalid-submit-key" }
             )
             .to_return(status: 200, body: {
               :success => false,
               :challenge_ts => Time.zone.now.to_s,
               :hostname => "canvas.docker",
               "error-codes" => ["invalid-input-response"]
             }.to_json)

      WebMock.stub_request(:post, "https://www.google.com/recaptcha/api/siteverify")
             .with(
               body: { "secret" => "test-token", "response" => nil }
             )
             .to_return(status: 200, body: {
               :success => false,
               :challenge_ts => Time.zone.now.to_s,
               :hostname => "canvas.docker",
               "error-codes" => ["missing-input-response"]
             }.to_json)
      # Fallback for any dynamicsettings call that isn't mocked below
      allow(DynamicSettings).to receive(:find).with(any_args).and_call_original
    end

    after do
      WebMock.enable_net_connect!
    end

    it "returns nil if there is no token" do
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(DynamicSettings::FallbackProxy.new({ "recaptcha_server_key" => nil }))
      expect(subject.send(:validate_recaptcha, nil)).to be_nil
    end

    it "returns nil for valid recaptcha submissions" do
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(DynamicSettings::FallbackProxy.new({ "recaptcha_server_key" => "test-token" }))
      expect(subject.send(:validate_recaptcha, "valid-submit-key")).to be_nil
    end

    it "returns an error for missing recaptcha submissions" do
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(DynamicSettings::FallbackProxy.new({ "recaptcha_server_key" => "test-token" }))
      expect(subject.send(:validate_recaptcha, nil)).not_to be_nil
    end

    it "returns an error for invalid recaptcha submissions" do
      allow(DynamicSettings).to receive(:find).with(tree: :private).and_return(DynamicSettings::FallbackProxy.new({ "recaptcha_server_key" => "test-token" }))
      expect(subject.send(:validate_recaptcha, "invalid-submit-key")).not_to be_nil
    end
  end

  describe "GET 'grades_for_student'" do
    let_once(:all_grading_periods_id) { 0 }
    let_once(:course) { course_factory(active_all: true) }
    let_once(:student) { user_factory(active_all: true) }
    let_once(:student_enrollment) do
      course_with_user("StudentEnrollment", course:, user: student, active_all: true)
    end
    let_once(:grading_period_group) { group_helper.legacy_create_for_course(course) }
    let_once(:grading_period) do
      grading_period_group.grading_periods.create!(
        end_date: 2.months.from_now,
        start_date: 3.months.ago,
        title: "Some Semester"
      )
    end
    let(:json) { json_parse(response.body) }
    let(:grade) { json.fetch("grade") }
    let(:restrict_quantitative_data) { json.fetch("restrict_quantitative_data") }
    let(:grading_scheme) { json.fetch("grading_scheme") }

    before(:once) do
      assignment_1 = assignment_model(course:, due_at: Time.zone.now, points_possible: 10)
      assignment_1.grade_student(student, grade: "40%", grader: @teacher)
      assignment_2 = assignment_model(course:, due_at: 3.months.from_now, points_possible: 100)
      assignment_2.grade_student(student, grade: "100%", grader: @teacher)
    end

    def get_grades!(grading_period_id)
      get("grades_for_student", params: { grading_period_id:, enrollment_id: student_enrollment.id })
    end

    context "as a student" do
      before do
        user_session(student)
      end

      context "when requesting the course grade" do
        before(:once) do
          student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!(all_grading_periods_id)
          expect(response).to be_ok
          expect(restrict_quantitative_data).to be false
          expect(grading_scheme).to eq course.grading_standard_or_default.data
        end

        it "returns restrict_quantitative_data as true when student is restricted for the course context" do
          # truthy feature flag
          Account.default.enable_feature! :restrict_quantitative_data

          # truthy setting
          Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
          Account.default.save!
          @course.restrict_quantitative_data = true
          @course.save!

          get_grades!(all_grading_periods_id)
          expect(restrict_quantitative_data).to be true
          expect(grading_scheme).to eq course.grading_standard_or_default.data
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course.enable_feature!(:final_grades_override)
            course.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the course override score when one exists" do
            get_grades!(all_grading_periods_id)
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed course score when no course override score exists" do
            student_enrollment.scores.find_by!(course_score: true).update!(override_score: nil)
            get_grades!(all_grading_periods_id)
            expect(grade).to be 94.55
          end
        end

        it "sets the grade to the computed course score when Final Grade Override is not allowed" do
          course.enable_feature!(:final_grades_override)
          course.update!(allow_final_grade_override: false)
          get_grades!(all_grading_periods_id)
          expect(grade).to be 94.55
        end

        it "sets the grade to the computed course score when Final Grade Override is not enabled" do
          get_grades!(all_grading_periods_id)
          expect(grade).to be 94.55
        end
      end

      context "when requesting a specific grading period grade" do
        before(:once) do
          student_enrollment.scores.find_by!(grading_period:).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!(grading_period.id)
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course.enable_feature!(:final_grades_override)
            course.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the grading period override score when one exists" do
            get_grades!(grading_period.id)
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed grading period score when no grading period override score exists" do
            student_enrollment.scores.find_by!(grading_period:).update!(override_score: nil)
            get_grades!(grading_period.id)
            expect(grade).to be 40.0
          end
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not allowed" do
          course.enable_feature!(:final_grades_override)
          course.update!(allow_final_grade_override: false)
          get_grades!(grading_period.id)
          expect(grade).to be 40.0
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not enabled" do
          course.disable_feature!(:final_grades_override)
          get_grades!(grading_period.id)
          expect(grade).to be 40.0
        end
      end
    end

    context "as a teacher" do
      let(:teacher) { course_with_user("TeacherEnrollment", course:, active_all: true).user }

      it "shows the computed score, even if override scores exist and feature is enabled" do
        course.enable_feature!(:final_grades_override)
        course.update!(allow_final_grade_override: true)
        user_session(teacher)
        student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.2)
        get_grades!(grading_period.id)
        expect(grade).to eq 40.0
      end

      it "shows restrict_quantitative_data as falsey by default" do
        user_session(teacher)
        get_grades!(grading_period.id)
        expect(restrict_quantitative_data).to be false
        expect(grading_scheme).to eq course.grading_standard_or_default.data
      end

      it "shows restrict_quantitative_data as true when teacher is restricted" do
        # truthy feature flag
        Account.default.enable_feature! :restrict_quantitative_data

        # truthy setting
        Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
        Account.default.save!
        @course.restrict_quantitative_data = true
        @course.save!

        user_session(teacher)
        get_grades!(grading_period.id)
        expect(restrict_quantitative_data).to be true
        expect(grading_scheme).to eq course.grading_standard_or_default.data
      end
    end

    context "with unposted assignments" do
      before do
        unposted_assignment = assignment_model(
          course:,
          due_at: Time.zone.now,
          points_possible: 90
        )
        unposted_assignment.ensure_post_policy(post_manually: true)
        unposted_assignment.grade_student(student, grade: "100%", grader: @teacher)

        user_session(@teacher)
      end

      let(:response) do
        get("grades_for_student", params: { enrollment_id: student_enrollment.id })
      end

      context "when the requester can manage grades" do
        before do
          course.root_account.role_overrides.create!(
            permission: "view_all_grades", role: teacher_role, enabled: false
          )
        end

        it "allows access" do
          expect(response).to be_ok
        end

        it "returns the grade" do
          expect(json["grade"]).to eq 94.55
        end

        it "returns the unposted_grade" do
          expect(json["unposted_grade"]).to eq 97
        end
      end

      context "when the requester can view all grades" do
        before do
          course.root_account.role_overrides.create!(
            permission: "view_all_grades", role: teacher_role, enabled: true
          )
          course.root_account.role_overrides.create!(
            permission: "manage_grades", role: teacher_role, enabled: false
          )
        end

        it "allows access" do
          expect(response).to be_ok
        end

        it "returns the grade" do
          expect(json["grade"]).to eq 94.55
        end

        it "returns the unposted_grade" do
          expect(json["unposted_grade"]).to eq 97
        end
      end

      context "when the requester does not have permissions to see unposted grades" do
        before do
          course.root_account.role_overrides.create!(
            permission: "view_all_grades", role: teacher_role, enabled: false
          )
          course.root_account.role_overrides.create!(
            permission: "manage_grades", role: teacher_role, enabled: false
          )
        end

        it "returns unauthorized" do
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    context "as an observer" do
      let!(:observer) { user_with_pseudonym(active_all: true) }

      before do
        add_linked_observer(student, observer)
        user_session(observer)
      end

      context "when requesting the course grade" do
        before(:once) do
          student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!(all_grading_periods_id)
          expect(response).to be_ok
        end

        it "shows restrict_quantitative_data as falsey by default" do
          get_grades!(grading_period.id)
          expect(restrict_quantitative_data).to be false
          expect(grading_scheme).to eq course.grading_standard_or_default.data
        end

        it "shows restrict_quantitative_data as true when teacher is restricted" do
          # truthy feature flag
          Account.default.enable_feature! :restrict_quantitative_data

          # truthy setting
          Account.default.settings[:restrict_quantitative_data] = { value: true, locked: true }
          Account.default.save!
          @course.restrict_quantitative_data = true
          @course.save!

          get_grades!(grading_period.id)
          expect(restrict_quantitative_data).to be true
          expect(grading_scheme).to eq course.grading_standard_or_default.data
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course.enable_feature!(:final_grades_override)
            course.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the course override score when one exists" do
            get_grades!(all_grading_periods_id)
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed course score when no course override score exists" do
            student_enrollment.scores.find_by!(course_score: true).update!(override_score: nil)
            get_grades!(all_grading_periods_id)
            expect(grade).to be 94.55
          end
        end

        it "sets the grade to the computed course score when Final Grade Override is not allowed" do
          course.enable_feature!(:final_grades_override)
          get_grades!(all_grading_periods_id)
          expect(grade).to be 94.55
        end

        it "sets the grade to the computed course score when Final Grade Override is not enabled" do
          get_grades!(all_grading_periods_id)
          expect(grade).to be 94.55
        end
      end

      context "when requesting a specific grading period grade" do
        before(:once) do
          student_enrollment.scores.find_by!(grading_period:).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!(grading_period.id)
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course.enable_feature!(:final_grades_override)
            course.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the grading period override score when one exists" do
            get_grades!(grading_period.id)
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed grading period score when no grading period override score exists" do
            student_enrollment.scores.find_by!(grading_period:).update!(override_score: nil)
            get_grades!(grading_period.id)
            expect(grade).to be 40.0
          end
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not allowed" do
          course.enable_feature!(:final_grades_override)
          course.update!(allow_final_grade_override: false)
          get_grades!(grading_period.id)
          expect(grade).to be 40.0
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not enabled" do
          course.disable_feature!(:final_grades_override)
          get_grades!(grading_period.id)
          expect(grade).to be 40.0
        end
      end
    end

    context "as an unrelated observer" do
      it "returns unauthorized" do
        observer = user_with_pseudonym(active_all: true)
        user_session(observer)
        get_grades!(all_grading_periods_id)
        assert_unauthorized
      end
    end

    context "as a student other than the requested student" do
      it "returns unauthorized when the user is not observing the requested student" do
        snooping_student = user_factory(active_all: true)
        course.enroll_student(snooping_student, active_all: true)
        user_session(snooping_student)
        get_grades!(grading_period.id)
        expect(response).to_not be_ok
      end
    end
  end

  describe "GET 'grades'" do
    let_once(:all_grading_periods_id) { 0 }
    let_once(:course_1) { course_factory(active_all: true) }
    let_once(:teacher) { course_with_teacher(course: course_1, active_all: true).user }
    let_once(:student) { user_factory(active_all: true) }
    let_once(:student_enrollment) do
      course_with_user("StudentEnrollment", course: course_1, user: student, active_all: true)
    end
    let_once(:grading_period_group) { group_helper.legacy_create_for_course(course_1) }
    let_once(:grading_period) do
      grading_period_group.grading_periods.create!(
        end_date: 2.months.from_now,
        start_date: 3.months.ago,
        title: "Some Semester"
      )
    end
    let(:selected_period_id) { assigns[:grading_periods][course_1.id][:selected_period_id] }

    before(:once) do
      # Student must be enrolled in multiple courses for access to this page.
      course_2 = course_factory(active_all: true)
      course_with_user("StudentEnrollment", course: course_2, user: student, active_all: true)

      assignment_1 = assignment_model(course: course_1, due_at: Time.zone.now, points_possible: 10)
      assignment_1.grade_student(student, grade: "40%", grader: teacher)
      assignment_2 = assignment_model(course: course_1, due_at: 3.months.from_now, points_possible: 100)
      assignment_2.grade_student(student, grade: "100%", grader: teacher)
    end

    def get_grades!(grading_period_id: nil)
      params = {}
      params[:course_id] = course_1.id if grading_period_id.present?
      params[:grading_period_id] = grading_period_id if grading_period_id.present?
      get("grades", params:)
    end

    context "as a student" do
      let(:grade) { assigns[:grades][:student_enrollments][course_1.id] }

      before do
        user_session(student)
      end

      it "includes the grading periods when the course is using grading periods" do
        get_grades!
        response_periods = assigns[:grading_periods][course_1.id][:periods]
        expect(response_periods).to include grading_period
      end

      context "when requesting a specific grading period grade" do
        before(:once) do
          student_enrollment.scores.find_by!(grading_period:).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!(grading_period_id: grading_period.id)
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course_1.enable_feature!(:final_grades_override)
            course_1.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the grading period override score when one exists" do
            get_grades!(grading_period_id: grading_period.id)
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed grading period score when no grading period override score exists" do
            student_enrollment.scores.find_by!(grading_period:).update!(override_score: nil)
            get_grades!(grading_period_id: grading_period.id)
            expect(grade).to be 40.0
          end
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not allowed" do
          course_1.enable_feature!(:final_grades_override)
          course_1.update!(allow_final_grade_override: false)
          get_grades!(grading_period_id: grading_period.id)
          expect(grade).to be 40.0
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not enabled" do
          course_1.disable_feature!(:final_grades_override)
          get_grades!(grading_period_id: grading_period.id)
          expect(grade).to be 40.0
        end

        it "sets the selected period id to the id of the requested grading period" do
          get_grades!(grading_period_id: grading_period.id)
          expect(selected_period_id).to be grading_period.id
        end
      end

      context "when not requesting a specific grading period and a grading period is current" do
        before(:once) do
          student_enrollment.scores.find_by!(grading_period:).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course_1.enable_feature!(:final_grades_override)
            course_1.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the grading period override score when one exists" do
            get_grades!
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed grading period score when no grading period override score exists" do
            student_enrollment.scores.find_by!(grading_period:).update!(override_score: nil)
            get_grades!
            expect(grade).to be 40.0
          end
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not allowed" do
          course_1.enable_feature!(:final_grades_override)
          course_1.update!(allow_final_grade_override: false)
          get_grades!
          expect(grade).to be 40.0
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not enabled" do
          course_1.disable_feature!(:final_grades_override)
          get_grades!
          expect(grade).to be 40.0
        end

        it "sets the selected period id to the id of the current grading period" do
          get_grades!(grading_period_id: grading_period.id)
          expect(selected_period_id).to be grading_period.id
        end
      end

      context "when not requesting a specific grading period and no grading period is current" do
        before(:once) do
          student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.2)
          grading_period.update!(start_date: 1.month.from_now)
        end

        it "returns okay" do
          get_grades!
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course_1.enable_feature!(:final_grades_override)
            course_1.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the course override score when one exists" do
            get_grades!
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed course score when no course override score exists" do
            student_enrollment.scores.find_by!(course_score: true).update!(override_score: nil)
            get_grades!
            expect(grade).to be 94.55
          end
        end

        it "sets the grade to the computed course score when Final Grade Override is not allowed" do
          course_1.enable_feature!(:final_grades_override)
          course_1.update!(allow_final_grade_override: false)
          get_grades!
          expect(grade).to be 94.55
        end

        it "sets the grade to the computed course score when Final Grade Override is not enabled" do
          get_grades!
          expect(grade).to be 94.55
        end

        it "sets the selected grading period to '0' (All Grading Periods)" do
          get_grades!
          expect(selected_period_id).to be 0
        end
      end
    end

    context "as an observer requesting an observed student's grades" do
      let_once(:observer) { user_with_pseudonym(active_all: true) }
      let(:observed_grades) { assigns[:grades][:observed_enrollments] }
      let(:grade) { observed_grades[course_1.id][student.id] }

      before(:once) do
        add_linked_observer(student, observer)
      end

      before do
        user_session(observer)
      end

      it "includes the grading periods when the course is using grading periods" do
        get_grades!
        response_periods = assigns[:grading_periods][course_1.id][:periods]
        expect(response_periods).to include grading_period
      end

      context "when requesting a specific grading period grade" do
        before(:once) do
          student_enrollment.scores.find_by!(grading_period:).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!(grading_period_id: grading_period.id)
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course_1.enable_feature!(:final_grades_override)
            course_1.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the grading period override score when one exists" do
            get_grades!(grading_period_id: grading_period.id)
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed grading period score when no grading period override score exists" do
            student_enrollment.scores.find_by!(grading_period:).update!(override_score: nil)
            get_grades!(grading_period_id: grading_period.id)
            expect(grade).to be 40.0
          end
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not allowed" do
          course_1.enable_feature!(:final_grades_override)
          course_1.update!(allow_final_grade_override: false)
          get_grades!(grading_period_id: grading_period.id)
          expect(grade).to be 40.0
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not enabled" do
          course_1.disable_feature!(:final_grades_override)
          get_grades!(grading_period_id: grading_period.id)
          expect(grade).to be 40.0
        end

        it "sets the selected period id to the id of the requested grading period" do
          get_grades!(grading_period_id: grading_period.id)
          expect(selected_period_id).to be grading_period.id
        end
      end

      context "when not requesting a specific grading period and a grading period is current" do
        before(:once) do
          student_enrollment.scores.find_by!(grading_period:).update!(override_score: 89.2)
        end

        it "returns okay" do
          get_grades!
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course_1.enable_feature!(:final_grades_override)
            course_1.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the grading period override score when one exists" do
            get_grades!
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed grading period score when no grading period override score exists" do
            student_enrollment.scores.find_by!(grading_period:).update!(override_score: nil)
            get_grades!
            expect(grade).to be 40.0
          end
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not allowed" do
          course_1.enable_feature!(:final_grades_override)
          course_1.update!(allow_final_grade_override: false)
          get_grades!
          expect(grade).to be 40.0
        end

        it "sets the grade to the computed grading period score when Final Grade Override is not enabled" do
          course_1.disable_feature!(:final_grades_override)
          get_grades!
          expect(grade).to be 40.0
        end

        it "sets the selected period id to the id of the current grading period" do
          get_grades!(grading_period_id: grading_period.id)
          expect(selected_period_id).to be grading_period.id
        end
      end

      context "when not requesting a specific grading period and no grading period is current" do
        before(:once) do
          student_enrollment.scores.find_by!(course_score: true).update!(override_score: 89.2)
          grading_period.update!(start_date: 1.month.from_now)
        end

        it "returns okay" do
          get_grades!
          expect(response).to be_ok
        end

        context "when Final Grade Override is enabled and allowed" do
          before(:once) do
            course_1.enable_feature!(:final_grades_override)
            course_1.update!(allow_final_grade_override: true)
          end

          it "sets the grade to the course override score when one exists" do
            get_grades!
            expect(grade).to be 89.2
          end

          it "sets the grade to the computed course score when no course override score exists" do
            student_enrollment.scores.find_by!(course_score: true).update!(override_score: nil)
            get_grades!
            expect(grade).to be 94.55
          end
        end

        it "sets the grade to the computed course score when Final Grade Override is not allowed" do
          course_1.enable_feature!(:final_grades_override)
          course_1.update!(allow_final_grade_override: false)
          get_grades!
          expect(grade).to be 94.55
        end

        it "sets the grade to the computed course score when Final Grade Override is not enabled" do
          get_grades!
          expect(grade).to be 94.55
        end

        it "sets the selected grading period to '0' (All Grading Periods)" do
          get_grades!
          expect(selected_period_id).to be 0
        end
      end

      context "with cross-shard enrollments" do
        specs_require_sharding

        it "returns grades for enrollments in other shards" do
          @shard1.activate do
            other_account = Account.create
            @cs_course = course_factory(active_all: true, account: other_account)
            course_with_user("TeacherEnrollment", course: @cs_course, user: teacher, active_all: true)
            course_with_user("StudentEnrollment", course: @cs_course, user: student, active_all: true)
            cs_observer = course_with_observer(course: @cs_course, user: observer, active_all: true)
            cs_observer.update!(associated_user: student)
            assignment = @cs_course.assignments.create!(title: "Homework", points_possible: 10)
            assignment.grade_student(student, grade: 8, grader: teacher)
          end

          get_grades!
          cross_course_grade = observed_grades.dig(@cs_course.id, student.id)
          expect(cross_course_grade).to eq 80.0
        end
      end
    end

    context "with cross-shard grading periods" do
      specs_require_sharding

      let(:test_course) { course_factory(active_all: true) }
      let(:student1) { user_factory(active_all: true) }
      let(:student2) { user_factory(active_all: true) }
      let(:grading_period_group) { group_helper.legacy_create_for_course(test_course) }
      let!(:grading_period) do
        grading_period_group.grading_periods.create!(
          title: "Some Semester",
          start_date: 3.months.ago,
          end_date: 2.months.from_now
        )
      end
      let(:assignment_due_in_grading_period) do
        test_course.assignments.create!(
          due_at: 10.days.from_now(grading_period.start_date),
          points_possible: 10
        )
      end
      let(:another_test_course) { course_factory(active_all: true) }
      let(:test_student) do
        student = user_factory(active_all: true)
        course_with_user("StudentEnrollment", course: test_course, user: student, active_all: true)
        course_with_user("StudentEnrollment", course: another_test_course, user: student, active_all: true)
        student
      end

      it "uses global ids for grading periods" do
        course_with_user("StudentEnrollment", course: test_course, user: student1, active_all: true)
        @shard1.activate do
          account = Account.create!
          @course2 = course_factory(active_all: true, account:)
          course_with_user("StudentEnrollment", course: @course2, user: student1, active_all: true)
          grading_period_group2 = group_helper.legacy_create_for_course(@course2)
          @grading_period2 = grading_period_group2.grading_periods.create!(
            title: "Some Semester",
            start_date: 3.months.ago,
            end_date: 2.months.from_now
          )
        end

        user_session(student1)

        get "grades"
        expect(response).to be_successful
        selected_period_id = assigns[:grading_periods][@course2.id][:selected_period_id]
        expect(selected_period_id).to eq @grading_period2.id
      end
    end

    it "does not include designers in the teacher enrollments" do
      # teacher needs to be in two courses to get to the point where teacher
      # enrollments are queried
      @course1 = course_factory(active_all: true)
      @course2 = course_factory(active_all: true)
      @teacher = user_factory(active_all: true)
      @designer = user_factory(active_all: true)
      @course1.enroll_teacher(@teacher).accept!
      @course2.enroll_teacher(@teacher).accept!
      @course2.enroll_designer(@designer).accept!

      user_session(@teacher)
      get "grades", params: { course_id: @course.id }
      expect(response).to be_successful

      teacher_enrollments = assigns[:presenter].teacher_enrollments
      expect(teacher_enrollments).not_to be_nil
      teachers = teacher_enrollments.map(&:user)
      expect(teachers).to include(@teacher)
      expect(teachers).not_to include(@designer)
    end

    it "does not redirect to an observer enrollment with no observee" do
      @course1 = course_factory(active_all: true)
      @course2 = course_factory(active_all: true)
      @user = user_factory(active_all: true)
      @course1.enroll_user(@user, "ObserverEnrollment")
      @course2.enroll_student(@user).accept!

      user_session(@user)
      get "grades"
      expect(response).to redirect_to course_grades_url(@course2)
    end

    it "does not include student view students in the grade average calculation" do
      course_with_teacher_logged_in(active_all: true)
      course_with_teacher(active_all: true, user: @teacher)
      @s1 = student_in_course(active_user: true).user
      @s2 = student_in_course(active_user: true).user
      @test_student = @course.student_view_student
      @assignment = assignment_model(course: @course, points_possible: 5)
      @assignment.grade_student(@s1, grade: 3, grader: @teacher)
      @assignment.grade_student(@s2, grade: 4, grader: @teacher)
      @assignment.grade_student(@test_student, grade: 5, grader: @teacher)

      get "grades"
      expect(assigns[:presenter].course_grade_summaries[@course.id]).to eq({ score: 70, students: 2 })
    end

    context "across shards" do
      specs_require_sharding

      it "loads courses from all shards" do
        course_with_teacher_logged_in active_all: true
        @shard1.activate do
          account = Account.create!
          course = account.courses.create!
          @e2 = course.enroll_teacher(@teacher)
          @e2.update_attribute(:workflow_state, "active")
        end

        get "grades"
        expect(response).to be_successful
        enrollments = assigns[:presenter].teacher_enrollments
        expect(enrollments).to include(@e2)
      end
    end
  end

  describe "GET 'avatar_image'" do
    it "redirects to no-pic if avatars are disabled" do
      course_with_student_logged_in(active_all: true)
      get "avatar_image", params: { user_id: @user.id }
      expect(response).to redirect_to User.default_avatar_fallback
    end

    it "redirects to avatar silhouette if no avatar is set and avatars are enabled" do
      course_with_student_logged_in(active_all: true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.settings[:avatars] = "enabled_pending"
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get "avatar_image", params: { user_id: @user.id }
      expect(response).to redirect_to User.default_avatar_fallback
    end

    it "passes along the default fallback to placeholder image" do
      course_with_student_logged_in(active_all: true)
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get "avatar_image", params: { user_id: @user.id }
      expect(response).to redirect_to "http://test.host/images/messages/avatar-50.png"
    end

    it "takes an invalid id and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get "avatar_image", params: { user_id: "a" }
      expect(response).to redirect_to "http://test.host/images/messages/avatar-50.png"
    end

    it "takes an invalid id with a hyphen and return silhouette" do
      @account = Account.default
      @account.enable_service(:avatars)
      @account.save!
      expect(@account.service_enabled?(:avatars)).to be_truthy
      get "avatar_image", params: { user_id: "a-1" }
      expect(response).to redirect_to "http://test.host/images/messages/avatar-50.png"
    end
  end

  describe "GET 'public_feed.atom'" do
    before do
      course_with_student(active_all: true)
      @as = assignment_model(course: @course)
      @dt = @course.discussion_topics.create!(title: "hi", message: "blah", user: @student)
      @wp = wiki_page_model(course: @course)
    end

    it "requires authorization" do
      get "public_feed", params: { feed_code: @user.feed_code + "x" }, format: "atom"
      expect(assigns[:problem]).to match(/The verification code is invalid/)
    end

    it "includes absolute path for rel='self' link" do
      get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.feed_url).to match(%r{http://})
    end

    it "includes an author for each entry" do
      get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed).not_to be_nil
      expect(feed.entries).not_to be_empty
      expect(feed.entries.all? { |e| e.author.present? }).to be_truthy
    end

    it "excludes unpublished things" do
      get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed.entries.size).to eq 3

      @as.unpublish
      @wp.unpublish
      @dt.unpublish! # yes, you really have to shout to unpublish a discussion topic :(

      get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed.entries.size).to eq 0
    end

    it "respects overrides" do
      @other_section = @course.course_sections.create! name: "other section"
      @as2 = assignment_model(title: "not for you", course: @course, only_visible_to_overrides: true)
      create_section_override_for_assignment(@as2, { course_section: @other_section })
      graded_discussion_topic(context: @course)
      create_section_override_for_assignment(@topic.assignment, { course_section: @other_section })
      @topic.assignment.update_attribute :only_visible_to_overrides, true

      get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed.entries.map(&:id).join(" ")).not_to include @as2.asset_string
      expect(feed.entries.map(&:id).join(" ")).not_to include @topic.asset_string

      @course.enroll_student(@student, section: @other_section, enrollment_state: "active", allow_multiple_enrollments: true)
      get "public_feed", params: { feed_code: @user.feed_code }, format: "atom"
      feed = Feedjira.parse(response.body)
      expect(feed.entries.map(&:id).join(" ")).to include @as2.asset_string
      expect(feed.entries.map(&:id).join(" ")).to include @topic.asset_string
    end
  end

  describe "GET 'admin_merge'" do
    let(:account) { Account.create! }

    before do
      account_admin_user
      user_session(@admin)
    end

    describe "as site admin" do
      before { Account.site_admin.account_users.create!(user: @admin) }

      it "warns about merging a user with itself" do
        user = User.create!
        pseudonym(user)
        get "admin_merge", params: { user_id: user.id, pending_user_id: user.id }
        expect(flash[:error]).to eq "You can't merge an account with itself."
      end

      it "does not issue warning if the users are different" do
        user = User.create!
        other_user = User.create!
        get "admin_merge", params: { user_id: user.id, pending_user_id: other_user.id }
        expect(flash[:error]).to be_nil
      end
    end

    it "does not allow you to view any user by id" do
      pseudonym(@admin)
      user_with_pseudonym(account:)
      get "admin_merge", params: { user_id: @admin.id, pending_user_id: @user.id }
      expect(response).to be_successful
      expect(assigns[:pending_other_user]).to be_nil
    end
  end

  describe "GET 'admin_split'" do
    before :once do
      account_admin_user
    end

    it "sets the env" do
      user1 = user_with_pseudonym
      user2 = user_with_pseudonym
      UserMerge.from(user2).into user1
      user_session(@admin)
      get "admin_split", params: { user_id: user1.id }
      expect(assigns[:js_env][:ADMIN_SPLIT_URL]).to include "/api/v1/users/#{user1.id}/split"
      expect(assigns[:js_env][:ADMIN_SPLIT_USER][:id]).to eq user1.id
      expect(assigns[:js_env][:ADMIN_SPLIT_USERS].pluck(:id)).to eq([user2.id])
    end
  end

  describe "GET 'show'" do
    context "sharding" do
      specs_require_sharding

      it "includes enrollments from all shards for the actual user" do
        course_with_teacher(active_all: 1)
        @shard1.activate do
          account = Account.create!
          course = account.courses.create!
          @e2 = course.enroll_teacher(@teacher)
        end
        account_admin_user(user: @teacher)
        user_session(@teacher)

        get "show", params: { id: @teacher.id }
        expect(response).to be_successful
        expect(assigns[:enrollments].sort_by(&:id)).to eq [@enrollment, @e2]
      end
    end

    context "rendering page views" do
      before do
        allow(PageView).to receive(:page_views_enabled?).and_return(true)
        course_with_teacher(active_all: 1)
      end

      context "when view_statistics right is granted" do
        before do
          account_admin_user_with_role_changes(
            role_changes: { view_statistics: true }
          )
          user_session(@user)
        end

        it "is viewable" do
          get "show", params: { id: @teacher.id }
          expect(assigns[:show_page_views]).to be true
        end
      end

      context "when view_statistics right is not granted" do
        before do
          account_admin_user_with_role_changes(
            role_changes: { view_statistics: false }
          )
          user_session(@user)
        end

        it "is not viewable" do
          get "show", params: { id: @teacher.id }
          expect(assigns[:show_page_views]).to be false
        end
      end
    end

    it "does not let admins see enrollments from other accounts" do
      @enrollment1 = course_with_teacher(active_all: 1)
      @enrollment2 = course_with_teacher(active_all: 1, user: @user)

      other_root_account = Account.create!(name: "other")
      @enrollment3 = course_with_teacher(active_all: 1, user: @user, account: other_root_account)

      account_admin_user
      user_session(@admin)

      get "show", params: { id: @teacher.id }
      expect(response).to be_successful
      expect(assigns[:enrollments].sort_by(&:id)).to eq [@enrollment1, @enrollment2]
    end

    it "401s on a deleted user" do
      course_with_teacher(active_all: 1)

      account_admin_user
      user_session(@admin)
      @teacher.destroy

      get "show", params: { id: @teacher.id }
      expect(response).to have_http_status :unauthorized
      expect(response).not_to render_template("users/show")
    end

    it "404s, but still shows, on a deleted user for site admins" do
      course_with_teacher(active_all: 1, user: user_with_pseudonym)

      account_admin_user(account: Account.site_admin)
      user_session(@admin)
      @teacher.destroy

      get "show", params: { id: @teacher.id }
      expect(response).to have_http_status :not_found
      expect(response).to render_template("users/show")
    end

    it "404s, but still shows, on a deleted user for admins" do
      course_with_teacher(active_all: 1, user: user_with_pseudonym)

      account_admin_user
      user_session(@admin)
      @teacher.destroy

      get "show", params: { id: @teacher.id }
      expect(response).to have_http_status :not_found
      expect(response).to render_template("users/show")
    end

    it "responds to JSON request" do
      account = Account.create!
      course_with_student(active_all: true, account:)
      account_admin_user(account:)
      user_with_pseudonym(user: @admin, account:)
      user_session(@admin)
      get "show", params: { id: @student.id }, format: "json"
      expect(response).to be_successful
      user = json_parse
      expect(user["name"]).to eq @student.name
    end

    it "redirects to login when not logged in, even if the user doesn't exist" do
      get "show", params: { id: 50 }
      expect(response).to redirect_to("/login")
    end

    it "401s if the user doesn't exist when you are logged in" do
      defunct_user = User.create!.destroy_permanently!
      user_factory(active_all: true)
      user_session(@user)
      get "show", params: { id: defunct_user.id }
      expect(response).to have_http_status :unauthorized
    end

    it "401s if the user exists but you don't have permission" do
      user2 = user_factory(active_all: true)
      user_factory(active_all: true)
      user_session(@user)
      get "show", params: { id: user2.id }
      expect(response).to have_http_status :unauthorized
    end

    it "renders for an admin" do
      account_admin_user(active_all: true)
      user_session(@user)
      get "show", params: { id: @user.id }
      expect(response).to have_http_status :ok
    end

    it "shows a deleted user from the account context if they have a deleted pseudonym for that account" do
      course_with_teacher(active_all: 1, user: user_with_pseudonym)
      account_admin_user(active_all: true)
      user_session(@admin)
      @teacher.remove_from_root_account(Account.default)

      get "show", params: { account_id: Account.default.id, id: @teacher.id }
      expect(response).to have_http_status :ok
    end

    context "cross-shard deleted users" do
      specs_require_sharding

      before do
        @shard1.activate do
          course_with_teacher(active_all: 1, user: user_with_pseudonym)
        end
        Account.default.pseudonyms.create!(user: @teacher, unique_id: "teacher-shard1")
        user_with_pseudonym
        account_admin_user(user: @user, active_all: true)
        user_session(@admin)
        @teacher.remove_from_root_account(Account.default)
      end

      it "shows a deleted user from the account context if they have a deleted pseudonym for that account" do
        get "show", params: { account_id: Account.default.id, id: @teacher.id }

        expect(response).to have_http_status :ok
      end

      it "does not give login ID for another account in json format" do
        get "show", params: { account_id: Account.default.id, id: @teacher.id, format: :json }

        expect(response).to have_http_status :ok
        expect(response.parsed_body["login_id"]).to be_nil
      end
    end

    it "does not show a deleted user from an account the user doesn't have access to" do
      course_with_teacher(active_all: 1, user: user_with_pseudonym)
      account_admin_user(active_all: true, account: account_model)
      user_session(@admin)
      @teacher.remove_from_root_account(@course.root_account)

      get "show", params: { account_id: @course.root_account.id, id: @teacher.id }
      expect(response).to have_http_status :unauthorized
    end
  end

  describe "PUT 'update'" do
    it "does not leak information about arbitrary users" do
      other_user = User.create! name: "secret"
      user_with_pseudonym
      user_session(@user)
      put "update", params: { id: other_user.id }, format: "json"
      expect(response.body).not_to include "secret"
      expect(response).to have_http_status :unauthorized
    end

    it "overwrites stuck sis fields" do
      user_with_pseudonym
      user_session(@user)
      put "update", params: { id: @user.id, "user[sortable_name]": "overwritten@example.com" }, format: "json"
      expect(response.body).to include "overwritten@example.com"
      expect(response).to have_http_status :ok
    end

    it "doesn't overwrite stuck sis fields" do
      user_with_pseudonym
      user_session(@user)
      put "update", params: { id: @user.id, "user[sortable_name]": "overwritten@example.com", override_sis_stickiness: false }, format: "json"
      expect(response.body).not_to include "overwritten@example.com"
      expect(response).to have_http_status :ok
    end
  end

  describe "POST 'masquerade'" do
    specs_require_sharding

    it "associates the user with target user's shard" do
      allow(PageView).to receive(:page_view_method).and_return(:db)
      user_with_pseudonym
      admin = @user
      Account.site_admin.account_users.create!(user: admin)
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account:)
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
        post "masquerade", params: { user_id: user2.id }
        expect(response).to be_redirect

        expect(admin.associated_shards(:shadow)).to include(@shard1)
      end
    end

    it "does not associate the user with target user's shard if masquerading failed" do
      allow(PageView).to receive(:page_view_method).and_return(:db)
      user_with_pseudonym
      admin = @user
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account:)
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
        post "masquerade", params: { user_id: user2.id }
        expect(response).not_to be_redirect

        expect(admin.associated_shards(:shadow)).not_to include(@shard1)
      end
    end

    it "does not associate the user with target user's shard for non-db page views" do
      user_with_pseudonym
      admin = @user
      Account.site_admin.account_users.create!(user: admin)
      user_session(admin)
      @shard1.activate do
        account = Account.create!
        user2 = user_with_pseudonym(account:)
        allow(LoadAccount).to receive(:default_domain_root_account).and_return(account)
        post "masquerade", params: { user_id: user2.id }
        expect(response).to be_redirect

        expect(admin.associated_shards(:shadow)).not_to include(@shard1)
      end
    end
  end

  describe "GET masquerade" do
    let(:user2) do
      user2 = user_with_pseudonym(name: "user2", short_name: "u2")
      user2.pseudonym.sis_user_id = "user2_sisid1"
      user2.pseudonym.integration_id = "user2_intid1"
      user2.pseudonym.unique_id = "user2_login1@foo.com"
      user2.pseudonym.save!
      user2
    end

    before do
      user_session(site_admin_user)
    end

    it "sets the js_env properly with act as user data" do
      get "masquerade", params: { user_id: user2.id }
      assert_response(:success)
      act_as_user_data = controller.js_env[:act_as_user_data][:user]
      expect(act_as_user_data).to include({
                                            name: user2.name,
                                            short_name: user2.short_name,
                                            id: user2.id,
                                            avatar_image_url: user2.avatar_image_url,
                                            sortable_name: user2.sortable_name,
                                            email: user2.email,
                                            pseudonyms: [
                                              { login_id: user2.pseudonym.unique_id,
                                                sis_id: user2.pseudonym.sis_user_id,
                                                integration_id: user2.pseudonym.integration_id }
                                            ]
                                          })
    end
  end

  describe "GET media_download" do
    let(:kaltura_client) do
      kaltura_client = instance_double(CanvasKaltura::ClientV3)
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(kaltura_client)
      kaltura_client
    end

    let(:media_source_fetcher) do
      media_source_fetcher = instance_double(MediaSourceFetcher)
      expect(MediaSourceFetcher).to receive(:new).with(kaltura_client).and_return(media_source_fetcher)
      media_source_fetcher
    end

    before do
      account = Account.create!
      course_with_student(active_all: true, account:)
      user_session(@student)
    end

    it "passes type and media_type params down to the media fetcher" do
      expect(media_source_fetcher).to receive(:fetch_preferred_source_url)
        .with(media_id: "someMediaId", file_extension: "mp4", media_type: "video")
        .and_return("http://example.com/media.mp4")

      get "media_download", params: { user_id: @student.id, entryId: "someMediaId", type: "mp4", media_type: "video" }
    end

    context "when redirect is set to 1" do
      it "redirects to the url" do
        allow(media_source_fetcher).to receive(:fetch_preferred_source_url)
          .and_return("http://example.com/media.mp4")

        get "media_download", params: { user_id: @student.id, entryId: "someMediaId", type: "mp4", redirect: "1" }

        expect(response).to redirect_to "http://example.com/media.mp4"
      end
    end

    context "when redirect does not equal 1" do
      it "renders the url in json" do
        allow(media_source_fetcher).to receive(:fetch_preferred_source_url)
          .and_return("http://example.com/media.mp4")

        get "media_download", params: { user_id: @student.id, entryId: "someMediaId", type: "mp4" }

        expect(json_parse["url"]).to eq "http://example.com/media.mp4"
      end
    end

    context "when asset is not found" do
      it "renders a 404 and error message" do
        allow(media_source_fetcher).to receive(:fetch_preferred_source_url)
          .and_return(nil)

        get "media_download", params: { user_id: @student.id, entryId: "someMediaId", type: "mp4" }

        expect(response).to have_http_status :not_found
        expect(response.body).to eq "Could not find download URL"
      end
    end
  end

  describe "login hooks" do
    before do
      Account.default.canvas_authentication_provider.update_attribute(:self_registration, true)
    end

    it "hooks on new" do
      expect(controller).to receive(:run_login_hooks).once
      get "new"
    end

    it "hooks on failed create" do
      expect(controller).to receive(:run_login_hooks).once
      post "create"
    end
  end

  describe "teacher_activity" do
    it "finds submission comment interaction" do
      course_with_student_submissions
      sub = @course.assignments.first.submissions
                   .where(user_id: @student).first
      sub.add_comment(comment: "hi", author: @teacher)

      get "teacher_activity", params: { user_id: @teacher.id, course_id: @course.id }

      expect(assigns[:courses][@course][0][:last_interaction]).not_to be_nil
    end

    it "finds ungraded submissions but not if the assignment is deleted" do
      course_with_teacher_logged_in(active_all: true)
      student_in_course(active_all: true)

      a1 = @course.assignments.create!(title: "a1", submission_types: "online_text_entry")
      s1 = a1.submit_homework(@student, body: "blah1")
      a2 = @course.assignments.create!(title: "a2", submission_types: "online_text_entry")
      a2.submit_homework(@student, body: "blah2")
      a2.destroy!

      get "teacher_activity", params: { user_id: @teacher.id, course_id: @course.id }

      expect(assigns[:courses][@course][0][:ungraded]).to eq [s1]
    end
  end

  describe "#toggle_hide_dashcard_color_overlays" do
    it "updates user preference based on value provided" do
      course_factory
      user_factory(active_all: true)
      user_session(@user)

      expect(@user.preferences[:hide_dashcard_color_overlays]).to be_falsy

      post :toggle_hide_dashcard_color_overlays

      expect(@user.reload.preferences[:hide_dashcard_color_overlays]).to be_truthy
      expect(response).to be_successful
      expect(response.parsed_body).to be_empty
    end
  end

  describe "#dashboard_view" do
    before do
      course_factory
      user_factory(active_all: true)
      user_session(@user)
    end

    it "sets the proper user preference on PUT requests" do
      put :dashboard_view, params: { dashboard_view: "cards" }
      expect(@user.dashboard_view).to eql("cards")
    end

    it "does not allow arbitrary values to be set" do
      put :dashboard_view, params: { dashboard_view: "a non-whitelisted value" }
      assert_status(400)
    end
  end

  describe "#invite_users" do
    it "does not work without ability to manage students or admins on course" do
      Account.default.tap do |a|
        a.settings[:open_registration] = true
        a.save!
      end
      course_with_student_logged_in(active_all: true)

      post "invite_users", params: { course_id: @course.id }

      assert_unauthorized
    end

    it "does not work without open registration or manage_user_logins rights" do
      course_with_teacher_logged_in(active_all: true)

      post "invite_users", params: { course_id: @course.id }

      assert_unauthorized
    end

    it "works with an admin with manage_login_rights" do
      course_factory
      account_admin_user(active_all: true)
      user_session(@user)

      post "invite_users", params: { course_id: @course.id }
      expect(response).to be_successful # yes, even though we didn't do anything
    end

    it "works with a teacher with open_registration" do
      allow_any_instantiation_of(Account.default).to receive(:open_registration?).and_return(true)
      course_with_teacher_logged_in(active_all: true)

      post "invite_users", params: { course_id: @course.id }
      expect(response).to be_successful
    end

    it "invites a bunch of users" do
      allow_any_instantiation_of(Account.default).to receive(:open_registration?).and_return(true)
      course_with_teacher_logged_in(active_all: true)

      user_list = [{ "email" => "example1@example.com" }, { "email" => "example2@example.com", "name" => "Hurp Durp" }]

      post "invite_users", params: { course_id: @course.id, users: user_list }
      expect(response).to be_successful
      json = response.parsed_body
      expect(json["invited_users"].count).to eq 2

      new_user1 = User.where(name: "example1@example.com").first
      new_user2 = User.where(name: "Hurp Durp").first
      expect([new_user1, new_user2].map(&:root_account_ids)).to match_array([[@course.root_account_id], [@course.root_account_id]])
      expect(json["invited_users"].pluck("id")).to match_array([new_user1.id, new_user2.id])
      expect(json["invited_users"].pluck("user_token")).to match_array([new_user1.token, new_user2.token])
    end

    it "checks for pre-existing users" do
      existing_user = user_with_pseudonym(active_all: true, username: "example1@example.com")

      allow_any_instantiation_of(Account.default).to receive(:open_registration?).and_return(true)
      course_with_teacher_logged_in(active_all: true)

      user_list = [{ "email" => "example1@example.com" }]

      post "invite_users", params: { course_id: @course.id, users: user_list }
      expect(response).to be_successful

      json = response.parsed_body
      expect(json["invited_users"]).to be_empty
      expect(json["errored_users"].count).to eq 1
      expect(json["errored_users"].first["existing_users"].first["user_id"]).to eq existing_user.id
      expect(json["errored_users"].first["existing_users"].first["user_token"]).to eq existing_user.token
    end

    it "checks for pre-existing users with unconfirmed communication channels" do
      user = user_with_pseudonym(active_all: true, username: "example1@example.com")
      user.communication_channels.first.update!(workflow_state: "unconfirmed")
      unconfirmed_email_message =
        "The email address provided conflicts with an existing user's email that is awaiting verification."

      allow_any_instantiation_of(Account.default).to receive(:open_registration?).and_return(true)
      course_with_teacher_logged_in(active_all: true)

      user_list = [{ "email" => "example1@example.com" }]

      post "invite_users", params: { course_id: @course.id, users: user_list }
      expect(response).to be_successful

      json = response.parsed_body
      expect(json["invited_users"]).to be_empty
      expect(json["errored_users"].count).to eq 1
      expect(json["errored_users"].first["errors"].first["message"]).to include(unconfirmed_email_message)
    end
  end

  describe "#user_dashboard" do
    context "with student planner feature enabled" do
      before(:once) do
        @account = Account.default
      end

      it "sets ENV.STUDENT_PLANNER_ENABLED to false when user has no student enrollments" do
        user_factory(active_all: true)
        user_session(@user)
        @current_user = @user
        get "user_dashboard"
        expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be_falsey
      end

      it "sets ENV.STUDENT_PLANNER_ENABLED to true when user has a student enrollment" do
        course_with_student_logged_in(active_all: true)
        @current_user = @user
        get "user_dashboard"
        expect(assigns[:js_env][:STUDENT_PLANNER_ENABLED]).to be_truthy
      end

      it "sets ENV.STUDENT_PLANNER_COURSES" do
        course_with_student_logged_in(active_all: true)
        @current_user = @user
        get "user_dashboard"
        courses = assigns[:js_env][:STUDENT_PLANNER_COURSES]
        expect(courses.pluck(:id)).to eq [@course.id]
      end

      it "sets ENV.STUDENT_PLANNER_GROUPS" do
        course_with_student_logged_in(active_all: true)
        @current_user = @user
        group = @account.groups.create! name: "Account group"
        group.add_user(@current_user, "accepted", true)
        get "user_dashboard"
        groups = assigns[:js_env][:STUDENT_PLANNER_GROUPS]
        expect(groups.pluck(:id)).to eq [group.id]
      end
    end

    context "data preloading" do
      before do
        course_with_student_logged_in(active_all: true)
        @course1 = @course
        @course2 = course_with_student(active_all: true, user: @user).course
        @current_user = @user
      end

      it "loads favorites" do
        @user.favorites.where(context_type: "Course", context_id: @course1).first_or_create!
        get "user_dashboard"
        course_data = assigns[:js_env][:STUDENT_PLANNER_COURSES]
        expect(course_data.detect { |h| h[:id] == @course1.id }[:isFavorited]).to be true
        expect(course_data.detect { |h| h[:id] == @course2.id }[:isFavorited]).to be false
      end

      it "loads nicknames" do
        @user.set_preference(:course_nicknames, @course1.id, "some nickname or whatever")
        expect_any_instance_of(User).to_not receive(:course_nickname)
        get "user_dashboard"
        course_data = assigns[:js_env][:STUDENT_PLANNER_COURSES]
        expect(course_data.detect { |h| h[:id] == @course1.id }[:shortName]).to eq "some nickname or whatever"
        expect(course_data.detect { |h| h[:id] == @course2.id }[:shortName]).to eq @course2.name
      end

      context "sharding" do
        specs_require_sharding

        it "loads nicknames for a cross-shard user" do
          @shard1.activate do
            xs_user = user_factory(active_all: true)
            @course1.enroll_student(xs_user, enrollment_state: "active")
            xs_user.set_preference(:course_nicknames, @course1.id, "worst class")
            user_session(xs_user)
          end
          get "user_dashboard"
          course_data = assigns[:js_env][:STUDENT_PLANNER_COURSES]
          expect(course_data.detect { |h| h[:id] == @course1.id }[:shortName]).to eq "worst class"
        end
      end
    end

    context "with canvas for elementary account setting" do
      before(:once) do
        @account = Account.default
      end

      before do
        course_with_student_logged_in(active_all: true)
      end

      shared_examples_for "observer list" do
        it "sets ENV.OBSERVED_USERS_LIST with self and observed users" do
          get "user_dashboard"

          observers = assigns[:js_env][:OBSERVED_USERS_LIST]
          expect(observers.length).to be(1)
          expect(observers[0][:name]).to eq(@student.name)
          expect(observers[0][:id]).to eq(@student.id)
        end
      end

      context "disabled" do
        before(:once) do
          toggle_k5_setting(@account, false)
        end

        it_behaves_like "observer list"

        it "only returns classic dashboard bundles" do
          get "user_dashboard"
          expect(assigns[:js_bundles].flatten).to include :dashboard
          expect(assigns[:js_bundles].flatten).not_to include :k5_dashboard
          expect(assigns[:css_bundles].flatten).to include :dashboard
          expect(assigns[:css_bundles].flatten).not_to include :k5_common
          expect(assigns[:css_bundles].flatten).not_to include :k5_dashboard
          expect(assigns[:css_bundles].flatten).not_to include :k5_font
          expect(assigns[:js_env][:K5_USER]).to be_falsy
        end
      end

      context "enabled" do
        before(:once) do
          toggle_k5_setting(@account, true)
        end

        it_behaves_like "observer list"

        it "returns K-5 dashboard bundles" do
          @current_user = @user
          get "user_dashboard"
          expect(assigns[:js_bundles].flatten).to include :k5_dashboard
          expect(assigns[:js_bundles].flatten).not_to include :dashboard
          expect(assigns[:css_bundles].flatten).to include :k5_common
          expect(assigns[:css_bundles].flatten).to include :k5_dashboard
          expect(assigns[:css_bundles].flatten).to include :k5_font
          expect(assigns[:css_bundles].flatten).not_to include :dashboard
          expect(assigns[:js_env][:K5_USER]).to be_truthy
        end

        it "does not include k5_font css bundle if use_classic_font? is true" do
          allow(controller).to receive(:use_classic_font?).and_return(true)
          @current_user = @user
          get "user_dashboard"
          expect(assigns[:css_bundles].flatten).to include :k5_dashboard
          expect(assigns[:css_bundles].flatten).not_to include :k5_font
        end

        context "ENV.INITIAL_NUM_K5_CARDS" do
          before :once do
            course_with_student
          end

          before do
            user_session @student
          end

          it "is set to cached count" do
            enable_cache do
              Rails.cache.write(["last_known_k5_cards_count", @student.global_id].cache_key, 3)
              get "user_dashboard"
              expect(assigns[:js_env][:INITIAL_NUM_K5_CARDS]).to eq 3
              Rails.cache.delete(["last_known_k5_cards_count", @student.global_id].cache_key)
            end
          end

          it "is set to 5 if not cached" do
            enable_cache do
              get "user_dashboard"
              expect(assigns[:js_env][:INITIAL_NUM_K5_CARDS]).to eq 5
            end
          end
        end

        context "@cards_prefetch_observed_param" do
          before :once do
            @user1 = user_factory(active_all: true, account: @account)
            @course = course_factory(active_all: true, account: @account)
          end

          before do
            user_session(@user1)
          end

          it "is set to id of selected observed user when user is an observer" do
            student = user_factory(active_all: true, account: @account)
            @course.enroll_student(student)
            @course.enroll_user(@user1, "ObserverEnrollment", { associated_user_id: student.id })
            get "user_dashboard"
            expect(controller.instance_variable_get(:@cards_prefetch_observed_param)).to eq student.id
          end

          it "is undefined when user is not an observer" do
            @course.enroll_student(@user1)
            get "user_dashboard"
            expect(controller.instance_variable_get(:@cards_prefetch_observed_param)).to be_nil
          end
        end

        context "ENV.SELECTED_CONTEXT_CODES" do
          it "is set to an array with the user's selected context codes" do
            contexts = %w[course_1 course_2]
            @user.set_preference(:selected_calendar_contexts, contexts)
            get "user_dashboard"
            expect(assigns[:js_env][:SELECTED_CONTEXT_CODES]).to eq(contexts)
          end

          it "is set to an empty array if the user has unselected all of their calendars" do
            @user.set_preference(:selected_calendar_contexts, "[]")
            get "user_dashboard"
            expect(assigns[:js_env][:SELECTED_CONTEXT_CODES]).to eq([])
          end
        end

        context "ENV.ACCOUNT_CALENDAR_CONTEXTS" do
          before :once do
            @account1 = Account.create!(name: "test 1")
            @account2 = Account.create!(name: "test 2")
            toggle_k5_setting(@account1)
            toggle_k5_setting(@account2)
          end

          before do
            allow_any_instance_of(User).to receive(:enabled_account_calendars).and_return([@account1, @account2])
          end

          it "includes a list of account calendars' asset_string and name" do
            get "user_dashboard"
            account_contexts = assigns[:js_env][:ACCOUNT_CALENDAR_CONTEXTS]
            expect(account_contexts.length).to be 2
            expect(account_contexts[0][:name]).to eq "test 1"
            expect(account_contexts[0][:asset_string]).to eq "account_#{@account1.id}"
            expect(account_contexts[1][:name]).to eq "test 2"
            expect(account_contexts[1][:asset_string]).to eq "account_#{@account2.id}"
          end

          it "does not include classic accounts in the list" do
            toggle_k5_setting(@account2, false)
            get "user_dashboard"
            account_contexts = assigns[:js_env][:ACCOUNT_CALENDAR_CONTEXTS]
            expect(account_contexts.length).to be 1
            expect(account_contexts[0][:name]).to eq "test 1"
          end
        end
      end
    end

    it "sets ENV.CREATE_COURSES_PERMISSIONS correctly if user is a teacher and can create courses" do
      Account.default.settings[:teachers_can_create_courses] = true
      Account.default.save!
      course_with_teacher_logged_in(active_all: true)

      get "user_dashboard"
      expect(assigns[:js_env][:CREATE_COURSES_PERMISSIONS][:PERMISSION]).to be(:teacher)
      expect(assigns[:js_env][:CREATE_COURSES_PERMISSIONS][:RESTRICT_TO_MCC_ACCOUNT]).to be_falsey
    end
  end

  describe "#dashboard_stream_items" do
    before :once do
      @course1 = course_factory(active_all: true)
      @user1 = user_factory(active_all: true)
    end

    before do
      user_session(@user1)
    end

    it "does not pass contexts to cached_recent_stream_items for students" do
      @course1.enroll_student(@user1)
      expect(@user1).to receive(:cached_recent_stream_items).with({ contexts: nil })

      get "dashboard_stream_items"
      expect(assigns[:user].id).to be(@user1.id)
      expect(assigns[:is_observing_student]).to be(false)
    end

    context "with observers" do
      before :once do
        @course2 = course_factory(active_all: true)
        @student = user_factory(active_all: true)
        @course1.enroll_student(@student)
        @course1.enroll_user(@user1, "ObserverEnrollment", associated_user_id: @student.id)
      end

      it "passes context to cached_recent_stream_items for observers" do
        expect_any_instance_of(User).to receive(:cached_recent_stream_items).with({ contexts: [@course1] })

        get "dashboard_stream_items", params: { observed_user_id: @student.id }
        expect(assigns[:user].id).to be(@student.id)
        expect(assigns[:is_observing_student]).to be(true)
      end

      it "returns unauthorized if user passes observed_user_id of user whom they are not observing" do
        @another_student = user_factory(active_all: true)
        @course1.enroll_student(@another_student)

        get "dashboard_stream_items", params: { observed_user_id: @another_student.id }
        expect(response).to be_unauthorized
      end
    end
  end

  describe "#dashboard_sidebar" do
    before :once do
      @course1 = course_factory(active_all: true)
      @user1 = user_factory(active_all: true)
    end

    before do
      user_session(@user1)
      allow(controller).to receive(:prepare_current_user_dashboard_items)
    end

    it "sets appropriate variables for students" do
      @course1.enroll_student(@user1)

      get "dashboard_sidebar"
      expect(assigns[:user].id).to be(@user1.id)
      expect(assigns[:is_observing_student]).to be(false)
      expect(assigns[:show_recent_feedback]).to be(true)
      expect(controller).not_to have_received(:prepare_current_user_dashboard_items)
    end

    it "sets appropriate variables for teachers" do
      @course1.enroll_teacher(@user1)

      get "dashboard_sidebar"
      expect(assigns[:user].id).to be(@user1.id)
      expect(assigns[:is_observing_student]).to be(false)
      expect(assigns[:show_recent_feedback]).to be(false)
      expect(controller).to have_received(:prepare_current_user_dashboard_items)
    end

    it "sets appropriate variables for users with teacher and student enrollments" do
      @course1.enroll_teacher(@user1)
      @course1.enroll_student(@user1)

      get "dashboard_sidebar"
      expect(assigns[:user].id).to be(@user1.id)
      expect(assigns[:is_observing_student]).to be(false)
      expect(assigns[:show_recent_feedback]).to be(true)
      expect(controller).to have_received(:prepare_current_user_dashboard_items)
    end

    context "with observers" do
      before :once do
        @course2 = course_factory(active_all: true)
        @student = user_factory(active_all: true)
        @course1.enroll_student(@student)
        @course1.enroll_user(@user1, "ObserverEnrollment", associated_user_id: @student.id)
        @course2.enroll_teacher(@user1)
      end

      it "sets variables for observer" do
        get "dashboard_sidebar"
        expect(assigns[:user].id).to be(@user1.id)
        expect(assigns[:is_observing_student]).to be(false)
        expect(assigns[:show_recent_feedback]).to be(false)
        expect(controller).to have_received(:prepare_current_user_dashboard_items)
      end

      it "sets variables for observer observing themself" do
        get "dashboard_sidebar", params: { observed_user_id: @user1.id }
        expect(assigns[:user].id).to be(@user1.id)
        expect(assigns[:is_observing_student]).to be(false)
        expect(assigns[:show_recent_feedback]).to be(false)
        expect(controller).to have_received(:prepare_current_user_dashboard_items)
      end

      it "sets variables for observer observing a student" do
        get "dashboard_sidebar", params: { observed_user_id: @student.id }
        expect(assigns[:user].id).to be(@student.id)
        expect(assigns[:is_observing_student]).to be(true)
        expect(assigns[:show_recent_feedback]).to be(true)
        expect(controller).not_to have_received(:prepare_current_user_dashboard_items)
      end

      it "returns unauthorized if user passes observed_user_id of user who they are not observing" do
        @another_student = user_factory(active_all: true)
        @course1.enroll_student(@another_student)

        get "dashboard_sidebar", params: { observed_user_id: @another_student.id }
        expect(response).to be_unauthorized
      end
    end
  end

  describe "#pandata_events_token" do
    subject do
      @request.env["HTTP_AUTHORIZATION"] = "Bearer #{access_token.full_token}"
      get "pandata_events_token", params: { app_key: }
    end

    let(:user) do
      user_with_pseudonym(active_user: true, username: "test1@example.com", password: "test1234")
      @user
    end
    let(:developer_key) { DeveloperKey.create! }
    let(:access_token) { user.access_tokens.create!(developer_key:) }
    let(:endpoint) { "https://example.com" }
    let(:app_key) { "VALID" }
    let(:credentials) do
      {
        valid_key: "VALID",
        valid_secret: "secret",
        valid_secret_alg: :HS256,
        invalid_key: "INVALID",
        invalid_secret: "secret"
      }.with_indifferent_access
    end

    before do
      enable_developer_key_account_binding!(developer_key)
      allow(Setting).to receive(:get).and_call_original
      allow(Setting).to receive(:get).with("pandata_events_token_allowed_developer_key_ids", "").and_return(developer_key.global_id.to_s)
      allow(Setting).to receive(:get).with("pandata_events_token_prefixes", "ios,android").and_return("valid")
      allow(PandataEvents).to receive_messages(credentials:, endpoint:)
    end

    context "with logged-in user but no access token" do
      subject { get "pandata_events_token" }

      before do
        user_session(user)
      end

      it "returns bad_request" do
        subject
        assert_status(400)
        json = response.parsed_body
        expect(json["message"]).to eq "Access token required"
      end
    end

    context "with wrong developer key" do
      before do
        allow(Setting).to receive(:get).with("pandata_events_token_allowed_developer_key_ids", "").and_return("")
      end

      it "returns forbidden" do
        subject
        assert_status(403)
        json = response.parsed_body
        expect(json["message"]).to eq "Developer key not authorized"
      end
    end

    context "with invalid app key" do
      let(:app_key) { "INVALID" }

      it "returns bad request" do
        subject
        assert_status(400)
        json = response.parsed_body
        expect(json["message"]).to eq "Invalid app key"
      end
    end

    it "succeeds" do
      subject
      assert_status(200)
    end

    it "returns the PandataEvents endpoint" do
      subject
      expect(response.parsed_body["url"]).to eq endpoint
    end

    context "auth token" do
      let(:token) { CanvasSecurity.decode_jwt(response.parsed_body["auth_token"], ["secret"]) }

      it "contains the app key as iss" do
        subject
        expect(token["iss"]).to eq app_key
      end

      it "contains the user id as sub" do
        subject
        expect(token["sub"]).to eq user.global_id
      end

      it "has exp that matches expires_at" do
        subject
        exp = DateTime.strptime(token["exp"].to_s, "%s")
        expires_at = DateTime.strptime(response.parsed_body["expires_at"].to_s, "%Q")
        expect(exp.to_s).to eq expires_at.to_s
      end
    end

    context "props token" do
      let(:token) { CanvasSecurity.decode_jwt(response.parsed_body["props_token"], ["secret"]) }

      it "contains the user id" do
        subject
        expect(token["user_id"]).to eq user.global_id
      end

      it "contains the shard id" do
        subject
        expect(token["shard"]).to eq Shard.current.id
      end

      it "contains the root account id" do
        subject
        expect(token["root_account_id"]).to eq Account.default.id
      end

      it "contains the root account uuid" do
        subject
        expect(token["root_account_uuid"]).to eq Account.default.uuid
      end
    end

    context "expires_at" do
      it "is an epoch timestamp in ms" do
        subject
        expires_at = response.parsed_body["expires_at"]
        expect(expires_at).to be_a Float
        expires_at_date = DateTime.strptime(expires_at.to_s, "%Q")
        expect(expires_at_date).to be_a DateTime
      end

      it "is ~1 day from now" do
        subject
        expires_at = response.parsed_body["expires_at"]
        expect(DateTime.strptime(expires_at.to_s, "%Q").utc).to be_within(1.minute).of(1.day.from_now)
      end
    end

    context "after multiple requests" do
      specs_require_cache(:redis_cache_store)

      it "still has exp that matches expires_at" do
        expires_at = nil
        Timecop.travel(5.minutes.ago) do
          @request.env["HTTP_AUTHORIZATION"] = "Bearer #{access_token.full_token}"
          get "pandata_events_token", params: { app_key: }

          token = CanvasSecurity.decode_jwt(response.parsed_body["auth_token"], ["secret"])
          exp = DateTime.strptime(token["exp"].to_s, "%s").to_s
          expires_at = DateTime.strptime(response.parsed_body["expires_at"].to_s, "%Q").to_s

          expect(exp).to eq expires_at
        end

        @request.env["HTTP_AUTHORIZATION"] = "Bearer #{access_token.full_token}"
        get "pandata_events_token", params: { app_key: }

        token = CanvasSecurity.decode_jwt(response.parsed_body["auth_token"], ["secret"])
        exp2 = DateTime.strptime(token["exp"].to_s, "%s").to_s
        expires_at2 = DateTime.strptime(response.parsed_body["expires_at"].to_s, "%Q").to_s

        expect(expires_at).not_to eq expires_at2
        expect(exp2).to eq expires_at2
      end
    end
  end

  describe "DELETE 'users'" do
    let(:user) { user_with_pseudonym(active_all: true)  }
    let(:admin) { account_admin_user(active_all: true)  }
    let(:siteadmin) { site_admin_user(active_all: true) }

    it "rejects unauthenticated users" do
      delete "destroy", params: { id: user.id }, format: :json
      expect(response).to have_http_status :unauthorized
    end

    it "rejects non siteadmin users" do
      user_session(admin)

      delete "destroy", params: { id: user.id }, format: :json
      expect(response).to have_http_status :unauthorized
    end

    it "allows siteadmin users" do
      user_session(siteadmin)

      delete "destroy", params: { id: user.id }, format: :json
      expect(response).to have_http_status :ok

      expect(user.reload.workflow_state).to eq "deleted"
    end
  end

  describe "DELETE 'sessions'" do
    let(:user) { user_with_pseudonym(active_all: true)  }
    let(:user2) { user_with_pseudonym(active_all: true) }
    let(:admin) { account_admin_user(active_all: true)  }

    before do
      user.access_tokens.create!

      @sns_client = double
      allow(DeveloperKey).to receive(:sns).and_return(@sns_client)
      expect(@sns_client).to receive(:create_platform_endpoint).and_return(endpoint_arn: "arn")
      user.access_tokens.each_with_index { |ac, i| ac.notification_endpoints.create!(token: "token #{i}") }
    end

    it "rejects unauthenticated users" do
      delete "terminate_sessions", params: { id: user.id }, format: :json
      expect(response).to have_http_status :unauthorized
    end

    it "rejects one person from terminating someone else" do
      user_session(user2)

      delete "terminate_sessions", params: { id: user.id }, format: :json
      expect(response).to have_http_status :unauthorized
    end

    it "allows admin to terminate sessions" do
      user_session(admin)

      delete "terminate_sessions", params: { id: user.id }, format: :json
      expect(response).to have_http_status :ok

      expect(user.reload.last_logged_out).not_to be_nil
      expect(user.access_tokens.take.permanent_expires_at).to be <= Time.zone.now
    end

    it "allows admin to expire mobile sessions" do
      user_session(admin)
      starting_notification_endpoints_count = user.notification_endpoints.count
      expect(starting_notification_endpoints_count).to be > 0
      delete "expire_mobile_sessions", format: :json

      expect(response).to have_http_status :ok
      expect(user.reload.access_tokens.take.permanent_expires_at).to be <= Time.zone.now
      expect(user.reload.notification_endpoints.count).to be < starting_notification_endpoints_count
    end

    it "only expires access tokens associated to mobile app developer keys" do
      dev_key = DeveloperKey.create!
      user2.access_tokens.create!(developer_key: dev_key)

      user_session(admin)
      delete "expire_mobile_sessions", format: :json

      expect(response).to have_http_status :ok
      expect(user.reload.access_tokens.take.permanent_expires_at).to be <= Time.zone.now
      expect(user2.reload.access_tokens.take.permanent_expires_at).to be_nil
    end
  end

  describe "PUT 'settings'" do
    before :once do
      user_factory(active_all: true)
    end

    before do
      user_session(@user)
    end

    it "does not allow another user to update their preferences" do
      @user1 = @user
      @user2 = user_factory(active_all: true)
      put "settings", params: { id: @user2.id, collapse_course_nav: true }, format: "json"
      assert_unauthorized
    end

    it "updates collapse_course_nav preference to true" do
      put "settings", params: { id: @user.id, collapse_course_nav: true }, format: "json"
      @user.reload
      expect(@user.collapse_course_nav?).to be_truthy
    end

    it "updates collapse_course_nav preference to false" do
      @user.preferences[:collapse_course_nav] = true
      @user.save!
      put "settings", params: { id: @user.id, collapse_course_nav: false }, format: "json"
      @user.reload
      expect(@user.collapse_course_nav?).to be_falsey
    end

    it "does not update preferences not included in the params" do
      @user.preferences[:collapse_global_nav] = true
      @user.preferences[:collapse_course_nav] = true
      @user.preferences[:elementary_dashboard_disabled] = true
      @user.save!
      put "settings", params: { id: @user.id, collapse_course_nav: false }, format: "json"
      @user.reload
      expect(@user.preferences[:collapse_global_nav]).to be_truthy
      expect(@user.preferences[:collapse_course_nav]).to be_falsey
      expect(@user.preferences[:elementary_dashboard_disabled]).to be_truthy
    end
  end

  describe "#show_k5_dashboard" do
    before :once do
      user_factory
    end

    it "returns unauthorized if unauthenticated" do
      get "show_k5_dashboard", format: "json"
      assert_unauthorized
    end

    it "returns value of k5_user?" do
      user_session(@user)
      allow(controller).to receive(:k5_user?).and_return(true)
      get "show_k5_dashboard", format: "json"
      expect(json_parse["show_k5_dashboard"]).to be_truthy
    end

    it "returns value of use_classic_font?" do
      user_session(@user)
      allow(controller).to receive(:use_classic_font?).and_return(false)
      get "show_k5_dashboard", format: "json"
      expect(json_parse["use_classic_font"]).to be_falsey
    end
  end
end
