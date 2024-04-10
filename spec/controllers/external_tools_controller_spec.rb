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

require "lti_1_3_spec_helper"
require_relative "lti/concerns/parent_frame_shared_examples"
require_relative "../support/request_helper"

describe ExternalToolsController do
  include ExternalToolsSpecHelper
  include Lti::RedisMessageClient
  include RequestHelper

  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
  end

  around do |example|
    consider_all_requests_local(false, &example)
  end

  describe "GET 'jwt_token'" do
    before do
      @iat = Time.zone.now
      allow_any_instance_of(Time.zone.class).to receive(:now).and_return(@iat)
      @tool = new_valid_tool(@course)
      @tool.course_navigation = { message_type: "ContentItemSelectionResponse" }
      @tool.save!
      @course.name = "Course Name"
      @course.save!
    end

    it "returns the correct JWT token when given using the tool_id param" do
      user_session(@teacher)
      get :jwt_token, params: { course_id: @course.id, tool_id: @tool.id }
      jwt = response.parsed_body["jwt_token"]
      decoded_token = Canvas::Security.decode_jwt(jwt, [:skip_verification])

      expect(decoded_token["custom_canvas_user_id"]).to eq @teacher.id.to_s
      expect(decoded_token["custom_canvas_course_id"]).to eq @course.id.to_s
      expect(decoded_token["consumer_key"]).to eq @tool.consumer_key
      expect(decoded_token["iat"]).to eq @iat.to_i
    end

    it "does not return a JWT token for another context" do
      teacher_course = @course
      other_course = course_factory

      @tool.context_id = other_course.id
      @tool.save!

      user_session(@teacher)
      get :jwt_token, params: { course_id: teacher_course.id, tool_id: @tool.id }

      expect(response).to have_http_status :not_found
    end

    it "returns the correct JWT token when given using the tool_launch_url param" do
      user_session(@teacher)
      get :jwt_token, params: { course_id: @course.id, tool_launch_url: @tool.url }
      decoded_token = Canvas::Security.decode_jwt(response.parsed_body["jwt_token"], [:skip_verification])

      expect(decoded_token["custom_canvas_user_id"]).to eq @teacher.id.to_s
      expect(decoded_token["custom_canvas_course_id"]).to eq @course.id.to_s
      expect(decoded_token["consumer_key"]).to eq @tool.consumer_key
      expect(decoded_token["iat"]).to eq @iat.to_i
    end

    it "sets status code to 404 if the requested tool id does not exist" do
      user_session(@teacher)
      get :jwt_token, params: { course_id: @course.id, tool_id: 999_999 }
      expect(response).to have_http_status :not_found
    end

    it "sets status code to 404 if no query params are provided" do
      user_session(@teacher)
      get :jwt_token, params: { course_id: @course.id }
      expect(response).to have_http_status :not_found
    end

    it "sets status code to 404 if the requested tool_launch_url does not exist" do
      user_session(@teacher)
      get :jwt_token, params: { course_id: @course.id, tool_launch_url: "http://www.nothere.com/doesnt_exist" }
      expect(response).to have_http_status :not_found
    end
  end

  describe "GET 'show'" do
    context "resource link request" do
      include_context "lti_1_3_spec_helper"

      let(:tool) do
        tool = @course.context_external_tools.new(
          name: "bob",
          consumer_key: "bob",
          shared_secret: "bob"
        )
        tool.url = "http://www.example.com/basic_lti"
        tool.course_navigation = { enabled: true }
        tool.use_1_3 = true
        tool.developer_key = DeveloperKey.create!
        tool.save!
        tool
      end

      let(:verifier) { "e5e774d015f42370dcca2893025467b414d39009dfe9a55250279cca16f5f3c2704f9c56fef4cea32825a8f72282fa139298cf846e0110238900567923f9d057" }
      let(:redis_key) { "#{@course.class.name}:#{Lti::RedisMessageClient::LTI_1_3_PREFIX}#{verifier}" }
      let(:cached_launch) { JSON.parse(Canvas.redis.get(redis_key)) }

      before { allow(SecureRandom).to receive(:hex).and_return(verifier) }

      context "when the current user is nil" do
        context "and the context is a public course" do
          subject do
            get :show, params: { course_id: @course.id, id: tool.id }
            response
          end

          before { @course.update!(is_public: true) }

          it { is_expected.to be_successful }

          it "uses the public user ID as the ISS" do
            subject
            expect(cached_launch["sub"]).to be_nil
          end
        end
      end

      context "when current user is a teacher" do
        subject { get :show, params: { course_id: @course.id, id: tool.id } }

        before do
          user_session(@teacher)
        end

        it "creates a login message" do
          subject
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
          subject
          expect(assigns[:lti_launch].params["login_hint"]).to eq Lti::Asset.opaque_identifier_for(@teacher)
        end

        it "caches the the LTI 1.3 launch" do
          subject
          expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiResourceLinkRequest"
        end

        it 'sets the "canvas_domain" to the request domain' do
          subject
          message_hint = JSON::JWT.decode(assigns[:lti_launch].params["lti_message_hint"], :skip_verification)
          expect(message_hint["canvas_domain"]).to eq "localhost"
        end

        it "defaults placement to context navigation" do
          subject
          expect(cached_launch["https://www.instructure.com/placement"]).to eq "course_navigation"
        end

        context "in the student_context_card placement" do
          subject { get :show, params: { course_id: @course.id, id: tool.id, placement: "student_context_card", student_id: }.compact }

          let(:student_id) { raise "override" }

          before do
            tool.student_context_card = { enabled: true }
            tool.save!
          end

          context "without student_id param" do
            let(:student_id) { nil }

            it "does not include lti_student_id in launch" do
              subject
              expect(cached_launch).not_to have_key("https://www.instructure.com/lti_student_id")
            end
          end

          context "with non-existent student_id param" do
            let(:student_id) { "wrong" }

            it "returns a JSON error" do
              subject
              expect(response).to be_not_found
            end
          end

          context "with non-student student_id param" do
            let(:student_id) { @teacher.id.to_s }

            it "returns a JSON error" do
              subject
              expect(response).to be_unauthorized
            end
          end

          context "with valid student_id param" do
            let(:student) { student_in_course(course: @course, active_all: true).user }
            let(:student_id) { student.id }

            it "includes lti_student_id in launch" do
              subject
              expect(cached_launch["https://www.instructure.com/lti_student_id"]).to eq(student.global_id.to_s)
            end
          end
        end
      end

      context "with a bad launch url" do
        it "fails gracefully" do
          user_session(@teacher)
          allow(controller).to receive(:basic_lti_launch_request).and_raise(Lti::Errors::InvalidLaunchUrlError)
          get :show, params: { course_id: @course.id, id: tool.id }
          expect(response).to be_redirect
        end
      end

      context "current user is a student view user" do
        before do
          user_session(@course.student_view_student)
          get :show, params: { course_id: @course.id, id: tool.id }
        end

        it "returns the TestUser claim when viewing as a student" do
          get :show, params: { course_id: @course.id, id: tool.id }
          expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/roles"]).to include("http://purl.imsglobal.org/vocab/lti/system/person#TestUser")
        end
      end

      context "with deep links" do
        before do
          user_session(@teacher)
        end

        it "get passed in target_link_uri" do
          get :show, params: { course_id: @course.id, id: tool.id, launch_url: "http://www.example.com/deep_link" }
          expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]).to eq "http://www.example.com/deep_link"
        end

        it "does not pass in target_link_uri if it doesn't match the tool domain" do
          get :show, params: { course_id: @course.id, id: tool.id, launch_url: "http://www.hi.com/deep_link" }
          expect(cached_launch["https://purl.imsglobal.org/spec/lti/claim/target_link_uri"]).to eq "http://www.example.com/basic_lti"
        end
      end
    end

    context "basic-lti-launch-request" do
      let(:tool) do
        @course.account.context_external_tools.new(
          name: "bob",
          consumer_key: "bob",
          shared_secret: "bob",
          url: "http://www.example.com/basic_lti"
        )
      end

      before { user_session(@teacher) }

      context "launching account tools for non-admins" do
        before do
          tool.account_navigation = { enabled: true }
          tool.save!

          get :show, params: { account_id: @course.account.id, id: tool.id }
        end

        it "launches successfully" do
          expect(response).to be_successful
        end

        it "sets a crumb with the tool name" do
          expect(assigns[:_crumbs].last).to eq(["bob", nil, {}])
        end
      end

      context "when required_permissions set" do
        it "does not launch account tool for non-admins" do
          tool.account_navigation = { enabled: true, required_permissions: "manage_data_services" }
          tool.save!

          get :show, params: { account_id: @course.account.id, id: tool.id }

          expect(response).not_to be_successful
        end
      end

      it "generates the resource_link_id correctly for a course navigation launch" do
        tool.course_navigation = { enabled: true }
        tool.save!

        get :show, params: { course_id: @course.id, id: tool.id }
        expect(assigns[:lti_launch].params["resource_link_id"]).to eq opaque_id(@course)
      end

      it "generates the correct resource_link_id for a homework submission" do
        assignment = @course.assignments.create!(name: "an assignment")
        assignment.save!
        tool.course_navigation = { enabled: true }
        tool.homework_submission = { enabled: true }
        tool.save!

        get :show, params: { course_id: @course.id, id: tool.id, launch_type: "homework_submission", assignment_id: assignment.id }
        expect(response).to be_successful

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params["resource_link_id"]).to eq opaque_id(@course)
      end

      it "returns flash error if the tool is not found" do
        get :show, params: { account_id: @course.account.id, id: 0 }
        expect(response).to be_redirect
        expect(flash[:error]).to match(/find valid settings/)
      end

      context "with environment-specific overrides" do
        let(:override_url) { "http://www.example-beta.com/basic_lti" }
        let(:domain) { "www.example-beta.com" }

        before do
          allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")

          tool.course_navigation = { enabled: true }
          tool.settings[:environments] = {
            domain:
          }
          tool.save!
        end

        it "uses override for resource_url" do
          get :show, params: { course_id: @course.id, id: tool.id }

          expect(assigns[:lti_launch].resource_url).to eq override_url
        end

        context "when launch_url is passed in params" do
          let(:launch_url) { "https://www.example.com/other_lti_launch" }
          let(:override_launch_url) { "https://www.example-beta.com/other_lti_launch" }

          it "uses overridden launch_url for resource_url" do
            get :show, params: { course_id: @course.id, id: tool.id, launch_url: }

            expect(assigns[:lti_launch].resource_url).to eq override_launch_url
          end
        end
      end

      context "in the student_context_card placement" do
        before do
          tool.student_context_card = { enabled: true }
          tool.save!
        end

        let(:student) { student_in_course(course: @course, active_all: true).user }
        let(:student_id) { student.id }

        it "includes ext_lti_student_id in the launch" do
          get :show, params: { course_id: @course.id, id: tool.id, student_id:, placement: :student_context_card }
          expect(assigns[:lti_launch].params["ext_lti_student_id"]).to eq(student.global_id.to_s)
        end
      end
    end

    context "ContentItemSelectionResponse" do
      before :once do
        @tool = new_valid_tool(@course)
        @tool.course_navigation = { message_type: "ContentItemSelectionResponse" }
        @tool.save!

        @course.name = "a course"
        @course.save!
      end

      it "generates the resource_link_id correctly" do
        user_session(@teacher)
        tool = @tool
        tool.settings["post_only"] = "true"
        tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
        tool.save!
        get :show, params: { course_id: @course.id, id: tool.id }
        expect(assigns[:lti_launch].params["resource_link_id"]).to eq opaque_id(@course)
      end

      it "removes query params when post_only is set" do
        user_session(@teacher)
        tool = @tool
        tool.settings["post_only"] = "true"
        tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
        tool.save!
        get :show, params: { course_id: @course.id, id: tool.id }
        expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basic_lti"
      end

      it "does not remove query params when post_only is not set" do
        user_session(@teacher)
        tool = @tool
        tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
        tool.save!
        get :show, params: { course_id: @course.id, id: tool.id }
        expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basic_lti?first=john&last=smith"
      end

      it "generates launch params for a ContentItemSelectionResponse message" do
        user_session(@teacher)
        allow(HostUrl).to receive(:outgoing_email_address).and_return("some_address")

        @course.root_account.lti_guid = "root-account-guid"
        @course.root_account.name = "root account"
        @course.root_account.save!

        get :show, params: { course_id: @course.id, id: @tool.id }

        expect(response).to be_successful
        lti_launch = assigns[:lti_launch]
        expect(lti_launch.link_text).to eq "bob"
        expect(lti_launch.resource_url).to eq "http://www.example.com/basic_lti"
        expect(lti_launch.launch_type).to be_nil
        expect(lti_launch.params["lti_message_type"]).to eq "ContentItemSelectionResponse"
        expect(lti_launch.params["lti_version"]).to eq "LTI-1p0"
        expect(lti_launch.params["context_id"]).to eq opaque_id(@course)
        expect(lti_launch.params["resource_link_id"]).to eq opaque_id(@course)
        expect(lti_launch.params["context_title"]).to eq "a course"
        expect(lti_launch.params["roles"]).to eq "Instructor"
        expect(lti_launch.params["tool_consumer_instance_guid"]).to eq "root-account-guid"
        expect(lti_launch.params["tool_consumer_instance_name"]).to eq "root account"
        expect(lti_launch.params["tool_consumer_instance_contact_email"]).to eq "some_address"
        expect(lti_launch.params["launch_presentation_return_url"]).to start_with "http"
        expect(lti_launch.params["launch_presentation_locale"]).to eq "en"
        expect(lti_launch.params["launch_presentation_document_target"]).to eq "iframe"
      end

      it "sends content item json for a course" do
        user_session(@teacher)
        get :show, params: { course_id: @course.id, id: @tool.id }
        content_item = JSON.parse(assigns[:lti_launch].params["content_items"])
        placement = content_item["@graph"].first

        expect(content_item["@context"]).to eq "http://purl.imsglobal.org/ctx/lti/v1/ContentItemPlacement"
        expect(content_item["@graph"].size).to eq 1
        expect(placement["@type"]).to eq "ContentItemPlacement"
        expect(placement["placementOf"]["@type"]).to eq "FileItem"
        expect(placement["placementOf"]["@id"]).to eq "#{api_v1_course_content_exports_url(@course)}?export_type=common_cartridge"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.course"
        expect(placement["placementOf"]["title"]).to eq "a course"
      end

      it "sends content item json for an assignment" do
        user_session(@teacher)
        assignment = @course.assignments.create!(name: "an assignment")
        get :show, params: { course_id: @course.id, id: @tool.id, assignments: [assignment.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        migration_url = placement["placementOf"]["@id"]
        params = migration_url.split("?").last.split("&")

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bassignments%5D%5B%5D=#{assignment.id}"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.assignment"
        expect(placement["placementOf"]["title"]).to eq "an assignment"
      end

      it "sends content item json for a discussion topic" do
        user_session(@teacher)
        topic = @course.discussion_topics.create!(title: "blah")
        get :show, params: { course_id: @course.id, id: @tool.id, discussion_topics: [topic.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        migration_url = placement["placementOf"]["@id"]
        params = migration_url.split("?").last.split("&")

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bdiscussion_topics%5D%5B%5D=#{topic.id}"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.discussion_topic"
        expect(placement["placementOf"]["title"]).to eq "blah"
      end

      it "sends content item json for a file" do
        user_session(@teacher)
        attachment_model
        get :show, params: { course_id: @course.id, id: @tool.id, files: [@attachment.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        download_url = placement["placementOf"]["@id"]

        expect(download_url).to include(@attachment.uuid)
        expect(placement["placementOf"]["mediaType"]).to eq @attachment.content_type
        expect(placement["placementOf"]["title"]).to eq @attachment.display_name
      end

      it "sends content item json for a quiz" do
        user_session(@teacher)
        quiz = @course.quizzes.create!(title: "a quiz")
        get :show, params: { course_id: @course.id, id: @tool.id, quizzes: [quiz.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        migration_url = placement["placementOf"]["@id"]
        params = migration_url.split("?").last.split("&")

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bquizzes%5D%5B%5D=#{quiz.id}"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.quiz"
        expect(placement["placementOf"]["title"]).to eq "a quiz"
      end

      it "sends content item json for a module" do
        user_session(@teacher)
        context_module = @course.context_modules.create!(name: "a module")
        get :show, params: { course_id: @course.id, id: @tool.id, modules: [context_module.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        migration_url = placement["placementOf"]["@id"]
        params = migration_url.split("?").last.split("&")

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bmodules%5D%5B%5D=#{context_module.id}"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.module"
        expect(placement["placementOf"]["title"]).to eq "a module"
      end

      it "sends content item json for a module item" do
        user_session(@teacher)
        context_module = @course.context_modules.create!(name: "a module")
        quiz = @course.quizzes.create!(title: "a quiz")
        tag = context_module.add_item(id: quiz.id, type: "quiz")

        get :show, params: { course_id: @course.id, id: @tool.id, module_items: [tag.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        migration_url = placement["placementOf"]["@id"]
        params = migration_url.split("?").last.split("&")

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bmodule_items%5D%5B%5D=#{tag.id}"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.quiz"
        expect(placement["placementOf"]["title"]).to eq "a quiz"
      end

      it "sends content item json for a page" do
        user_session(@teacher)
        page = @course.wiki_pages.create!(title: "a page")
        get :show, params: { course_id: @course.id, id: @tool.id, pages: [page.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        migration_url = placement["placementOf"]["@id"]
        params = migration_url.split("?").last.split("&")

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "select%5Bpages%5D%5B%5D=#{page.id}"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.page"
        expect(placement["placementOf"]["title"]).to eq "a page"
      end

      it "sends content item json for selected content" do
        user_session(@teacher)
        page = @course.wiki_pages.create!(title: "a page")
        assignment = @course.assignments.create!(name: "an assignment")
        get :show, params: { course_id: @course.id, id: @tool.id, pages: [page.id], assignments: [assignment.id] }
        placement = JSON.parse(assigns[:lti_launch].params["content_items"])["@graph"].first
        migration_url = placement["placementOf"]["@id"]
        params = migration_url.split("?").last.split("&")

        expect(migration_url).to start_with api_v1_course_content_exports_url(@course)
        expect(params).to include "export_type=common_cartridge"
        expect(params).to include "select%5Bpages%5D%5B%5D=#{page.id}"
        expect(params).to include "select%5Bassignments%5D%5B%5D=#{assignment.id}"
        expect(placement["placementOf"]["mediaType"]).to eq "application/vnd.instructure.api.content-exports.course"
        expect(placement["placementOf"]["title"]).to eq "a course"
      end

      it "returns flash error if invalid id params are passed in" do
        user_session(@teacher)
        get :show, params: { course_id: @course.id, id: @tool.id, pages: [0] }
        expect(response).to be_redirect
        expect(flash[:error]).to match(/error generating the tool launch/)
      end

      context "when launch_url is passed in params" do
        let(:launch_url) { "https://www.example.com/other_lti_launch" }

        it "uses provided launch_url" do
          user_session(@teacher)
          get :show, params: { course_id: @course.id, id: @tool.id, launch_url: }

          expect(assigns[:lti_launch].resource_url).to eq launch_url
        end
      end

      context "with environment-specific overrides" do
        let(:override_url) { "http://www.example-beta.com/basic_lti" }
        let(:domain) { "www.example-beta.com" }

        before do
          allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")

          @tool.settings[:environments] = {
            domain:
          }
          @tool.save!
        end

        it "uses override for resource_url" do
          user_session(@teacher)
          get :show, params: { course_id: @course.id, id: @tool.id }

          expect(assigns[:lti_launch].resource_url).to eq override_url
        end

        context "when launch_url is passed in params" do
          let(:launch_url) { "https://www.example.com/other_lti_launch" }
          let(:override_launch_url) { "https://www.example-beta.com/other_lti_launch" }

          it "uses overridden launch_url for resource_url" do
            user_session(@teacher)
            get :show, params: { course_id: @course.id, id: @tool.id, launch_url: }

            expect(assigns[:lti_launch].resource_url).to eq override_launch_url
          end
        end
      end
    end

    context "ContentItemSelectionRequest" do
      before :once do
        @tool = new_valid_tool(@course)
        @tool.migration_selection = { message_type: "ContentItemSelectionRequest" }
        @tool.resource_selection = { message_type: "ContentItemSelectionRequest" }
        @tool.homework_submission = { message_type: "ContentItemSelectionRequest" }
        @tool.editor_button = { message_type: "ContentItemSelectionRequest", icon_url: "http://example.com/icon.png" }
        @tool.save!

        @course.name = "a course"
        @course.course_code = "CS 124"
        @course.save!
      end

      it "generates launch params for a ContentItemSelectionRequest message" do
        user_session(@teacher)
        get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "migration_selection" }
        expect(response).to be_successful

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params["lti_message_type"]).to eq "ContentItemSelectionRequest"
        expect(lti_launch.params["content_item_return_url"]).to eq "http://test.host/courses/#{@course.id}/external_content/success/external_tool_dialog"
        expect(lti_launch.params["accept_multiple"]).to eq "false"
        expect(lti_launch.params["context_label"]).to eq @course.course_code
      end

      it "sets proper return data for migration_selection" do
        user_session(@teacher)
        get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "migration_selection" }
        expect(response).to be_successful

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params["accept_copy_advice"]).to eq "true"
        expect(lti_launch.params["accept_presentation_document_targets"]).to eq "download"
        expect(lti_launch.params["accept_media_types"]).to eq "application/vnd.ims.imsccv1p1,application/vnd.ims.imsccv1p2,application/vnd.ims.imsccv1p3,application/zip,application/xml"
      end

      it "sets proper return data for resource_selection" do
        user_session(@teacher)
        get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "resource_selection" }
        expect(response).to be_successful

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params["accept_copy_advice"]).to be_nil
        expect(lti_launch.params["accept_presentation_document_targets"]).to eq "frame,window"
        expect(lti_launch.params["accept_media_types"]).to eq "application/vnd.ims.lti.v1.ltilink"
      end

      it "sets proper return data for collaboration" do
        user_session(@teacher)
        @tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        @tool.save!
        get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "collaboration" }
        expect(response).to be_successful

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params["accept_copy_advice"]).to be_nil
        expect(lti_launch.params["accept_presentation_document_targets"]).to eq "window"
        expect(lti_launch.params["accept_media_types"]).to eq "application/vnd.ims.lti.v1.ltilink"
      end

      context "homework submission" do
        it "sets accept_copy_advice to true if submission_type includes online_upload" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.allowed_extensions += ["pdf", "jpeg"]
          assignment.submission_types = "online_upload"
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          expect(response).to be_successful

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["accept_copy_advice"]).to eq "true"
        end

        it "sets accept_copy_advice to false if submission_type does not include online_upload" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.allowed_extensions += ["pdf", "jpeg"]
          assignment.submission_types = "online_text_entry"
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["accept_copy_advice"]).to eq "false"
        end

        it "sets proper accept_media_types for homework_submission with extension restrictions" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.allowed_extensions += ["pdf", "jpeg"]
          assignment.submission_types = "online_upload"
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          expect(response).to be_successful

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["accept_media_types"]).to eq "application/pdf,image/jpeg"
        end

        it "sends the ext_content_file_extensions paramter for restriced file types" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.allowed_extensions += ["pdf", "jpeg"]
          assignment.submission_types = "online_upload"
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["ext_content_file_extensions"]).to eq "pdf,jpeg"
        end

        it "doesn't set the ext_content_file_extensions parameter if online_upload isn't accepted" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.submission_types = "online_text_entry"
          assignment.allowed_extensions += ["pdf", "jpeg"]
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params).not_to have_key("ext_content_file_extensions")
        end

        it "sets the accept_media_types parameter to '*.*'' if online_upload isn't accepted" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.allowed_extensions += ["pdf", "jpeg"]
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          expect(response).to be_successful

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["accept_media_types"]).to eq "*/*"
        end

        it "sets the accept_presentation_document_target to window if online_url is a submission type" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.submission_types = "online_url"
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["accept_presentation_document_targets"]).to include "window"
        end

        it "doesn't add none to accept_presentation_document_target if online_upload isn't a submission_type" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.submission_types = "online_url"
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["accept_presentation_document_targets"]).not_to include "none"
        end

        it "sets the mime type to */* if there is a online_url submission type" do
          user_session(@teacher)
          assignment = @course.assignments.new(name: "an assignment")
          assignment.allowed_extensions += ["pdf", "jpeg"]
          assignment.submission_types = "online_upload,online_url"
          assignment.save!
          get :show, params: { course_id: @course.id,
                               id: @tool.id,
                               launch_type: "homework_submission",
                               assignment_id: assignment.id }
          expect(response).to be_successful

          lti_launch = assigns[:lti_launch]
          expect(lti_launch.params["accept_media_types"]).to eq "*/*"
        end
      end

      it "sets proper return data for editor_button" do
        user_session(@teacher)
        get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "editor_button" }
        expect(response).to be_successful

        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params["accept_copy_advice"]).to be_nil
        expect(lti_launch.params["accept_presentation_document_targets"]).to eq "embed,frame,iframe,window"
        expect(lti_launch.params["accept_media_types"]).to eq "image/*,text/html,application/vnd.ims.lti.v1.ltilink,*/*"
      end

      it "does not copy query params to POST if disable_lti_post_only feature flag is set" do
        user_session(@teacher)
        @course.root_account.enable_feature!(:disable_lti_post_only)
        @tool.url = "http://www.instructure.com/test?first=rory&last=williams"
        @tool.save!

        get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "migration_selection" }
        expect(assigns[:lti_launch].params["first"]).to be_nil
      end

      it "does not copy query params to POST if oauth_compliant tool setting is enabled" do
        user_session(@teacher)
        @course.root_account.disable_feature!(:disable_lti_post_only)
        @tool.url = "http://www.instructure.com/test?first=rory&last=williams"
        @tool.settings[:oauth_compliant] = true
        @tool.save!

        get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "migration_selection" }
        expect(assigns[:lti_launch].params["first"]).to be_nil
      end

      context "with environment-specific overrides" do
        let(:override_url) { "http://www.example-beta.com/basic_lti" }
        let(:domain) { "www.example-beta.com" }

        before do
          allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")

          @tool.settings[:environments] = {
            domain:
          }
          @tool.save!
        end

        it "uses override for resource_url" do
          user_session(@teacher)
          get :show, params: { course_id: @course.id, id: @tool.id, launch_type: "migration_selection" }

          expect(assigns[:lti_launch].resource_url).to eq override_url
        end

        context "when launch_url is passed in params" do
          let(:launch_url) { "https://www.example.com/other_lti_launch" }
          let(:override_launch_url) { "https://www.example-beta.com/other_lti_launch" }

          it "uses overridden launch_url for resource_url" do
            user_session(@teacher)
            get :show, params: { course_id: @course.id, id: @tool.id, launch_url:, launch_type: "migration_selection" }

            expect(assigns[:lti_launch].resource_url).to eq override_launch_url
          end
        end
      end
    end
  end

  describe "GET 'retrieve'" do
    let :account do
      Account.default
    end

    let :tool do
      tool = account.context_external_tools.new(
        name: "bob",
        consumer_key: "bob",
        shared_secret: "bob",
        tool_id: "some_tool",
        privacy_level: "public"
      )
      tool.url = "http://www.example.com/basic_lti?first=john&last=smith"
      tool.resource_selection = {
        url: "http://#{HostUrl.default_host}/selection_test",
        selection_width: 400,
        selection_height: 400
      }
      tool.save!
      tool
    end

    context "LTI 1.3" do
      let(:developer_key) do
        key = DeveloperKey.create!(account: @course.account)
        key.generate_rsa_keypair!
        key.developer_key_account_bindings.first.update!(
          workflow_state: "on"
        )
        key.save!
        key
      end

      let(:lti_1_3_tool) do
        tool = @course.context_external_tools.new(name: "test",
                                                  consumer_key: "key",
                                                  shared_secret: "secret")
        tool.url = "http://www.example.com/launch"
        tool.use_1_3 = true
        tool.developer_key = developer_key
        tool.save!
        tool
      end

      let(:decoded_jwt) do
        lti_launch = assigns[:lti_launch]
        Canvas::Security.decode_jwt(lti_launch.params["lti_message_hint"])
      end

      let(:launch_hash) do
        cached_launch = fetch_and_delete_launch(@course, decoded_jwt["verifier"])
        JSON.parse(cached_launch)
      end

      before do
        lti_1_3_tool
        user_session(@teacher)
      end

      it "assigns @lti_launch.resource_url" do
        get "retrieve", params: { course_id: @course.id, url: "http://www.example.com/launch" }
        expect(assigns[:lti_launch].resource_url).to eq lti_1_3_tool.url
      end

      context "ENV.LTI_TOOL_FORM_ID" do
        it "sets a random id" do
          expect(controller).to receive(:random_lti_tool_form_id).and_return("1")
          expect(controller).to receive(:js_env).with(LTI_TOOL_FORM_ID: "1")
          get "retrieve", params: { course_id: @course.id, url: "http://www.example.com/launch" }
        end
      end

      context "when resource_link_lookup_uuid is passed" do
        include Lti::RedisMessageClient
        let(:launch_params) do
          JSON.parse(
            fetch_and_delete_launch(
              @course,
              JSON::JWT.decode(assigns[:lti_launch].params["lti_message_hint"], :skip_verification)["verifier"]
            )
          )
        end

        let(:rl) do
          Lti::ResourceLink.create!(
            context_external_tool: lti_1_3_tool,
            context: @course,
            custom: { abc: "def", expans: "$Canvas.user.id" },
            url: "http://www.example.com/launch"
          )
        end

        let(:get_page_params) do
          {
            course_id: @course.id,
            url: "http://www.example.com/launch",
            resource_link_lookup_uuid: rl.lookup_uuid
          }
        end

        let(:get_page) { get "retrieve", params: get_page_params }

        context "when launch_type is not provided" do
          it "does not include placement in launch" do
            get_page
            expect(launch_hash["https://www.instructure.com/placement"]).to be_nil
          end
        end

        context "when launch_type is provided" do
          let(:launch_type) { "homework_submission" }
          let(:get_page_params) { super().merge(launch_type:) }

          before do
            lti_1_3_tool.homework_submission = { enabled: true }
            lti_1_3_tool.save!
          end

          it "includes placement in launch" do
            get_page
            expect(launch_hash["https://www.instructure.com/placement"]).to eq launch_type
          end
        end

        it "sets the custom parameters in the launch hash" do
          get_page
          expect(launch_hash["https://purl.imsglobal.org/spec/lti/claim/custom"]).to include(
            "abc" => "def",
            "expans" => @teacher.id.to_s
          )
        end

        it "sets the custom parameters in the launch hash when is the old parameter name `resource_link_lookup_id`" do
          get "retrieve", params: {
            course_id: @course.id,
            url: "http://www.example.com/launch",
            resource_link_lookup_id: rl.lookup_uuid
          }

          expect(launch_hash["https://purl.imsglobal.org/spec/lti/claim/custom"]).to include(
            "abc" => "def",
            "expans" => @teacher.id.to_s
          )
        end

        it "errors if the resource_link_lookup_uuid cannot be found" do
          get "retrieve", params: {
            course_id: @course.id,
            url: "http://www.example.com/launch",
            resource_link_lookup_uuid: "wrong_do_it_again"
          }
          expect(response).to be_redirect
          expect(flash[:error]).to eq "Couldn't find valid settings for this link: Resource link not found"
        end

        it "errors if the resource_link_lookup_uuid is for the wrong context" do
          rl.update(context: Course.create(course_valid_attributes))
          get_page
          expect(response).to be_redirect
          expect(flash[:error]).to eq "Couldn't find valid settings for this link: Resource link not found"
        end

        it "errors if the resource_link_id cannot be found" do
          get "retrieve", params: {
            course_id: @course.id,
            url: "http://www.example.com/launch",
            resource_link_id: "wrong_do_it_again"
          }
          expect(response).to be_redirect
          expect(flash[:error]).to eq "Couldn't find valid settings for this link: Resource link not found"
        end

        it "errors if the resource_link_id is for the wrong context" do
          rl.update(context: Course.create(course_valid_attributes))
          get "retrieve", params: {
            course_id: @course.id,
            url: "http://www.example.com/launch",
            resource_link_id: rl.resource_link_uuid
          }
          expect(response).to be_redirect
          expect(flash[:error]).to eq "Couldn't find valid settings for this link: Resource link not found"
        end

        it "errors if the resource_link is inactive" do
          rl.update(workflow_state: "deleted")
          get_page
          expect(response).to be_redirect
          expect(flash[:error]).to eq "Couldn't find valid settings for this link: Resource link not found"
        end

        it "does not include custom params if the resource_link is for the wrong tool" do
          tool2 = @course.context_external_tools.create!(
            name: "test",
            consumer_key: "key",
            shared_secret: "secret",
            url: "http://www.example2.com/launch",
            use_1_3: true,
            developer_key: DeveloperKey.create!
          )
          rl.update(context_external_tool: tool2)
          get_page
          expect(launch_params["https://purl.imsglobal.org/spec/lti/claim/custom"]).to be_blank
        end

        it "succeeds if the resource_link is for a tool with the same host" do
          tool2 = @course.account.context_external_tools.create!(
            name: "test",
            consumer_key: "key",
            shared_secret: "secret",
            url: "http://www.example.com/launch",
            use_1_3: true,
            developer_key: lti_1_3_tool.developer_key
          )
          rl.update(context_external_tool: tool2)
          get_page
          expect(
            launch_params["https://purl.imsglobal.org/spec/lti/claim/custom"]
          ).to eq({ "abc" => "def", "expans" => @teacher.id.to_s })
        end

        it "if parent_frame_context is not given it does not include it in lti_message_hint" do
          get_page
          expect(decoded_jwt).to_not include("parent_frame_context")
        end

        context "when the parent parent_frame_context is passed" do
          let(:get_page_params) { super().merge(parent_frame_context: 123) }

          it "sets parent_frame_context in the lti_message_hint" do
            get_page
            expect(decoded_jwt["parent_frame_context"]).to eq("123")
          end
        end
      end

      context "tool is used for assignment_selection" do
        it "uses secure params to pass along lti_assignment_id for 1.3" do
          lti_1_3_tool.assignment_selection = { enable: true }
          lti_1_3_tool.custom_fields = { assignment_id: "$com.instructure.Assignment.lti.id" }
          lti_1_3_tool.save!

          lti_assignment_id = SecureRandom.uuid
          jwt = Canvas::Security.create_jwt({ lti_assignment_id: })
          get :show, params: { course_id: @course.id, id: lti_1_3_tool.id, secure_params: jwt, launch_type: "assignment_selection" }
          expect(launch_hash["https://purl.imsglobal.org/spec/lti/claim/custom"]["assignment_id"]).to eq(lti_assignment_id)
        end
      end

      context "tool is used to edit an existing collaboration" do
        let(:collab) do
          ExternalToolCollaboration.create!(
            title: "my collab",
            user: @teacher,
            url: "http://www.example.com/launch",
            context: @course,
            data: {
              "updateUrl" => "http://www.example.com/launch?abc=def"
            }
          )
        end

        let(:launch_params) do
          JSON.parse(fetch_and_delete_launch(@course, decoded_jwt["verifier"]))
        end

        # it "it passes collaboration into the expander" do
        #   get :retrieve, params: { course_id: @course.id, url: collab.update_url, launch_type: "collaboration", content_item_id: collab.id }
        #   expect(launch_hash["https://purl.imsglobal.org/spec/lti/claim/custom"]["assignment_id"]).to eq(lti_assignment_id)
        # end

        let(:jwt) do
          deep_link_return_url = launch_params["https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings"]["deep_link_return_url"]
          return_jwt = deep_link_return_url.match(/data=([^&]*)/)[1]
          JSON::JWT.decode(return_jwt, :skip_verification)
        end

        before do
          lti_1_3_tool.collaboration = {
            "enabled" => true,
            "message_type" => "LtiDeepLinkingRequest",
            "placement" => "collaboration",
            "text" => "tool",
          }
          lti_1_3_tool.save!
        end

        it "adds content_item_id to the data JWT" do
          get :retrieve, params: { course_id: @course.id, url: collab.update_url, launch_type: "collaboration", content_item_id: collab.id }
          expect(jwt[:content_item_id]).to eq(collab.id)
        end

        context "when the update_url in the collaboration given by content_item_id does not match up with the given launch URL" do
          it "does not add content_item_id to the data JWT" do
            get :retrieve, params: {
              course_id: @course.id,
              url: collab.update_url + "&mismatch",
              launch_type: "collaboration",
              content_item_id: collab.id
            }
            expect(jwt[:content_item_id]).to be_nil
          end
        end
      end

      context "tool is used for student_context_card" do
        # If and when we add the functionality, we can also test here that the
        # student_id appears in the launch.
        it "launches and does not crash" do
          lti_1_3_tool.student_context_card = { enable: true }
          lti_1_3_tool.save!

          get "retrieve", params: {
            course_id: @course.id,
            url: "http://www.example.com/launch",
            placement: "student_context_card",
            student_id: @student.id,
          }
          expect(response).to have_http_status(:ok)
          expect(assigns[:lti_launch].resource_url).to eq lti_1_3_tool.url
        end
      end
    end

    it "requires authentication" do
      user_model
      user_session(@user)
      get "retrieve", params: { course_id: @course.id }
      assert_unauthorized
    end

    context "logging" do
      before do
        allow(Lti::LogService).to receive(:new) do
          double("Lti::LogService").tap { |s| allow(s).to receive(:call) }
        end
        user_session(@teacher)
      end

      context "when placement is provided" do
        let(:placement) { "assignment_selection" }

        it "logs launch with placement and indirect_link launch_type" do
          expect(Lti::LogService).to receive(:new).with(
            tool:,
            context: @course,
            user: @teacher,
            placement:,
            launch_type: :indirect_link
          )

          get "retrieve", params: { course_id: @course.id, url: tool.url, placement: }
        end
      end

      context "when placement isn't provided (like rich content)" do
        it "logs launch with no placement and content_item launch_type" do
          expect(Lti::LogService).to receive(:new).with(
            tool:,
            context: @course,
            user: @teacher,
            placement: nil,
            launch_type: :content_item
          )

          get "retrieve", params: { course_id: @course.id, url: tool.url }
        end
      end
    end

    it "passes prefer_1_1=false to find_external_tool by default when looking up by URL" do
      user_session(@teacher)
      expect(ContextExternalTool).to receive(:find_external_tool).with(
        anything, anything, anything, anything, anything, prefer_1_1: false
      )
      get "retrieve", params: { course_id: @course.id, url: "http://www.example.com/basic_lti" }
    end

    it "passes prefer_1_1=false to find_external_tool only when the prefer_1_1 param is set" do
      user_session(@teacher)
      expect(ContextExternalTool).to receive(:find_external_tool).with(
        anything, anything, anything, anything, anything, prefer_1_1: true
      )
      get "retrieve", params: { course_id: @course.id, url: "http://www.example.com/basic_lti", prefer_1_1: true }
    end

    it "finds tools matching by exact url" do
      user_session(@teacher)
      tool = new_valid_tool(@course) # this tool has a url and no domain
      get "retrieve", params: { course_id: @course.id, url: "http://www.example.com/basic_lti" }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params).not_to be_nil
    end

    it "finds tools matching by resource_link_lookup_uuid" do
      user_session(@teacher)

      tool = new_valid_tool(@course) # this tool has a url and no domain
      resource_link = Lti::ResourceLink.create_with(@course, tool, nil, "http://www.example.com/basiclti/url_from_resource_link")

      # provide no url parameter
      get "retrieve", params: { course_id: @course.id, resource_link_lookup_uuid: resource_link.lookup_uuid }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool

      expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basiclti/url_from_resource_link"
    end

    it "finds tools matching by resource_link_id" do
      user_session(@teacher)

      tool = new_valid_tool(@course) # this tool has a url and no domain
      resource_link = Lti::ResourceLink.create_with(@course, tool, nil, "http://www.example.com/basiclti/url_from_resource_link")

      # provide no url parameter
      get "retrieve", params: { course_id: @course.id, resource_link_id: resource_link.resource_link_uuid }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool

      expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basiclti/url_from_resource_link"
    end

    it "finds tools matching by resource_link_lookup_uuid, ignoring the url parameter" do
      user_session(@teacher)
      new_valid_tool(@course, {
                       url: "http://tool1.com"
                     })
      tool2 = new_valid_tool(@course, {
                               url: "http://tool2.com"
                             })
      resource_link = Lti::ResourceLink.create_with(@course, tool2, nil, "http://tool2.com/testing")

      # supply a different url to the endpoint
      get "retrieve", params: { course_id: @course.id, resource_link_lookup_uuid: resource_link.lookup_uuid, url: "http://tool1.com" }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool2
      expect(assigns[:lti_launch].resource_url).to eq "http://tool2.com/testing"
    end

    it "sets a breadcrumb with the tool name" do
      user_session(@teacher)
      new_valid_tool(@course)
      get "retrieve", params: { course_id: @course.id, url: "http://www.example.com/basic_lti" }
      expect(assigns[:_crumbs].last).to eq(["bob", nil, {}])
    end

    it "redirects if no matching tools are found" do
      user_session(@teacher)
      get "retrieve", params: { course_id: @course.id, url: "http://www.example.com" }
      expect(response).to be_redirect
      expect(flash[:error]).to eq "Couldn't find valid settings for this link"
    end

    it "returns a variable expansion for a collaboration" do
      user_session(@teacher)
      collab = ExternalToolCollaboration.new(
        title: "my collab",
        user: @teacher,
        url: "http://www.example.com"
      )
      collab.context = @course
      collab.save!
      tool = new_valid_tool(@course)
      tool.collaboration = { message_type: "ContentItemSelectionRequest" }
      tool.settings[:custom_fields] = { "collaboration_url" => "$Canvas.api.collaborationMembers.url" }
      tool.save!
      get "retrieve", params: { course_id: @course.id, url: tool.url, content_item_id: collab.id, placement: "collaboration" }
      expect(assigns[:lti_launch].params["custom_collaboration_url"]).to eq api_v1_collaboration_members_url(collab)
    end

    it "messages appropriately when there is a launch error because of missing permissions" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      tool.settings[:course_navigation] = { "required_permissions" => "not-real-permissions,nor-this-one" }
      tool.save!
      get "retrieve", params: { course_id: @course.id, url: "http://www.example.com/basic_lti", placement: :course_navigation }
      expect(response).to be_unauthorized
    end

    it "removes query params when post_only is set" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)

      tool.settings["post_only"] = "true"
      tool.save!
      get :retrieve, params: { url: tool.url, account_id: account.id }
      expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basic_lti"
    end

    it "does not remove query params when post_only is not set" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)

      tool.save!
      get :retrieve, params: { url: tool.url, account_id: account.id }
      expect(assigns[:lti_launch].resource_url).to eq "http://www.example.com/basic_lti?first=john&last=smith"
    end

    it "adds params from secure_params" do
      u = user_factory(active_all: true)
      account.account_users.create!(user: u)
      user_session(@user)
      tool.save!
      lti_assignment_id = SecureRandom.uuid
      jwt = Canvas::Security.create_jwt({ lti_assignment_id: })
      get :retrieve, params: { url: tool.url, account_id: account.id, secure_params: jwt }
      expect(assigns[:lti_launch].params["ext_lti_assignment_id"]).to eq lti_assignment_id
    end

    it_behaves_like "an endpoint which uses parent_frame_context to set the CSP header" do
      subject do
        get :retrieve, params: {
          url: tool.url,
          course_id: @course.id,
          parent_frame_context: pfc_tool.id
        }
      end

      before { user_session(@student) }

      let(:pfc_tool_context) { @course }
    end

    context "with display type 'in_rce'" do
      render_views

      subject do
        get :retrieve, params: {
          url: tool.url,
          course_id: @course.id,
          display: "in_rce"
        }
      end

      before do
        user_session(@student)
        Account.site_admin.enable_feature!(:lti_rce_postmessage_support)
      end

      it "renders the sibling forwarder frame once" do
        subject
        expect(response.body.scan('id="post_message_forwarding').count).to eq 1
      end

      it "renders the tool launch iframe" do
        subject
        expect(response.body).to include("id=\"tool_content_")
      end

      it "includes post_message_forwarding JS for main frame" do
        subject
        expect(response.body).to match %r{<script src="/dist/javascripts/lti_post_message_forwarding-[0-9a-z]+\.js">}
      end

      it "includes IN_RCE and IGNORE_LTI_POST_MESSAGES in the JS ENV" do
        subject
        env = js_env_from_response(response)
        expect(env["IN_RCE"]).to be(true)
        expect(env["IGNORE_LTI_POST_MESSAGES"]).to be(true)
      end
    end

    context "for Quizzes Next launch" do
      let(:assignment) do
        a = assignment_model(course: @course, title: "A Quizzes.Next Assignment")
        a.submission_types = "external_tool"
        a.external_tool_tag_attributes = { url: tool.url }
        a.save!
        a
      end
      let(:tool) do
        account.context_external_tools.create!({
                                                 name: "Quizzes.Next",
                                                 url: "http://example.com/launch",
                                                 domain: "example.com",
                                                 consumer_key: "test_key",
                                                 shared_secret: "test_secret",
                                                 privacy_level: "public",
                                                 tool_id: "Quizzes 2"
                                               })
      end

      let(:retrieve_params) do
        {
          course_id: @course.id,
          assignment_id: assignment.id,
          url: "http://example.com/launch"
        }
      end

      before do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session(@user)
      end

      it "sets resource_link_id to that of the assignment's launch" do
        get :retrieve, params: retrieve_params

        expect(assigns[:lti_launch].params["resource_link_id"]).to eq assignment.lti_resource_link_id
        expect(assigns[:lti_launch].params["context_id"]).to eq opaque_id(@course)
      end

      it "sets resource_link_title to that of the title" do
        get :retrieve, params: retrieve_params

        expect(assigns[:lti_launch].params["resource_link_title"]).to eq assignment.title
      end

      it "includes extra assignment info during relaunch" do
        get :retrieve, params: retrieve_params.merge(placement: :assignment_selection)

        # this is a sampling of that extra assignment info, which is fully tested in
        # `lti_integration_spec.rb`. This is just enough to know that it exists.
        expect(assigns[:lti_launch].params["custom_canvas_assignment_title"]).to eq assignment.title
        expect(assigns[:lti_launch].params["ext_outcome_result_total_score_accepted"]).to eq "true"
        expect(assigns[:lti_launch].params["lis_outcome_service_url"]).to eq lti_grade_passback_api_url(tool)
      end
    end

    context "collaborations" do
      let(:collab) do
        collab = ExternalToolCollaboration.new(
          title: "my collab",
          user: @teacher,
          url: "http://www.example.com"
        )
        collab.context = @course
        collab.save!
        collab
      end

      it "lets you specify the selection_type" do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session u
        tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        tool.save!
        get :retrieve, params: { url: tool.url, account_id: account.id, placement: "collaboration" }
        expect(assigns[:lti_launch].params["lti_message_type"]).to eq "ContentItemSelectionRequest"
      end

      it "creates a content-item return url with an id" do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session u
        tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        tool.save!
        get :retrieve, params: { url: tool.url, course_id: @course.id, placement: "collaboration", content_item_id: collab.id }
        return_url = assigns[:lti_launch].params["content_item_return_url"]
        expect(return_url).to eq "http://test.host/courses/#{@course.id}/external_content/success/external_tool_dialog/#{collab.id}"
      end

      it "sets the auto_create param to true" do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session u
        tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        tool.save!
        get :retrieve, params: { url: tool.url, course_id: @course.id, placement: "collaboration", content_item_id: collab.id }
        expect(assigns[:lti_launch].params["auto_create"]).to eq "true"
      end

      it "sets the accept_unsigned param to false" do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session u
        tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        tool.save!
        get :retrieve, params: { url: tool.url, course_id: @course.id, placement: "collaboration", content_item_id: collab.id }
        expect(assigns[:lti_launch].params["accept_unsigned"]).to eq "false"
      end

      it "adds a data element with a jwt that contains the id if a content_item_id param is present" do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session u
        tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        tool.save!
        get :retrieve, params: { url: tool.url, course_id: @course.id, placement: "collaboration", content_item_id: collab.id }
        data = assigns[:lti_launch].params["data"]
        json_data = Canvas::Security.decode_jwt(data)
        expect(json_data[:content_item_id]).to eq collab.id.to_s
      end

      it "adds a data element with a jwt that contains the consumer_key if a content_item_id param is present" do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session u
        tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        tool.save!
        get :retrieve, params: { url: tool.url, course_id: @course.id, placement: "collaboration", content_item_id: collab.id }
        data = assigns[:lti_launch].params["data"]
        json_data = Canvas::Security.decode_jwt(data)
        expect(json_data[:oauth_consumer_key]).to eq tool.consumer_key
      end

      it "adds to the data element the default launch url" do
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        user_session u
        tool.collaboration = { message_type: "ContentItemSelectionRequest" }
        tool.save!
        get :retrieve, params: { url: tool.url, course_id: @course.id, placement: "collaboration", content_item_id: collab.id }
        data = assigns[:lti_launch].params["data"]
        json_data = Canvas::Security.decode_jwt(data)
        expect(json_data[:default_launch_url]).to eq tool.url
      end
    end

    context "for assignment launches with overrides" do
      let(:assignment) do
        a = assignment_model(course: @course, due_at:)
        a.submission_types = "external_tool"
        a.external_tool_tag_attributes = { url: tool.url }
        a.due_at = due_at
        a.save!
        a
      end

      let(:tool) do
        account.context_external_tools.create!({
                                                 name: "Some awesome LTI tool",
                                                 url: "http://example.com/launch",
                                                 domain: "example.com",
                                                 consumer_key: "test_key",
                                                 shared_secret: "test_secret",
                                                 privacy_level: "public",
                                                 settings: {
                                                   custom_fields: { "canvas_assignment_due_at" => "$Canvas.assignment.dueAt.iso8601" }
                                                 }
                                               })
      end

      let(:due_at) { "2021-07-29 08:26:56.000000000 +0000".to_datetime }
      let(:due_at_diff) { "2021-07-30 08:26:56.000000000 +0000".to_datetime }

      let(:retrieve_params) do
        {
          course_id: @course.id,
          assignment_id: assignment.id,
          url: "http://example.com/launch",
          placement: :assignment_selection
        }
      end

      let(:launch_resource_link_id) { assigns[:lti_launch].params["resource_link_id"] }
      let(:launch_resource_link_title) { assigns[:lti_launch].params["resource_link_title"] }

      before do
        student_in_course
        u = user_factory(active_all: true)
        account.account_users.create!(user: u)
        adhoc_override = assignment_override_model(assignment:)
        override_student = adhoc_override.assignment_override_students.build
        override_student.user = @student
        override_student.save!
        adhoc_override.override_due_at(due_at_diff)
        adhoc_override.save!
      end

      it "generates a student launch with overriden params" do
        expect(assignment.due_at).to eq due_at

        user_session(@student)
        get :retrieve, params: retrieve_params

        expect(
          assigns[:lti_launch].params["custom_canvas_assignment_due_at"].to_datetime
        ).to eq due_at_diff
      end

      it "generates an admin/teacher launch with overriden params" do
        expect(assignment.due_at).to eq due_at

        user_session(@user)
        get :retrieve, params: retrieve_params

        expect(
          assigns[:lti_launch].params["custom_canvas_assignment_due_at"].to_datetime
        ).to eq due_at_diff
      end

      context "with the lti_resource_link_id_speedgrader_launches_reference_assignment feature flag off" do
        before { account.disable_feature!(:lti_resource_link_id_speedgrader_launches_reference_assignment) }

        it "uses the resource_link_id of the course and title of the tool" do
          user_session(@user)
          get :retrieve, params: retrieve_params
          expect(launch_resource_link_id).to eq opaque_id(@course)
          expect(launch_resource_link_title).to eq tool.name
        end
      end

      context "with the lti_resource_link_id_speedgrader_launches_reference_assignment feature flag on" do
        before { account.enable_feature!(:lti_resource_link_id_speedgrader_launches_reference_assignment) }

        it "uses the resource_link_id and resource_link_title of the assignment" do
          user_session(@student)
          get :retrieve, params: retrieve_params
          expect(launch_resource_link_id).to eq assignment.lti_resource_link_id
          expect(launch_resource_link_title).to eq assignment.title
        end

        context "when launching as a student" do
          it "uses the resource_link_id and resource_link_title of the assignment" do
            user_session(@student)
            get :retrieve, params: retrieve_params
            expect(launch_resource_link_id).to eq assignment.lti_resource_link_id
            expect(launch_resource_link_title).to eq assignment.title
          end
        end
      end

      context "when launching as a student but the assigment is unpublished" do
        it "returns a 401" do
          user_session(@student)
          assignment.update! workflow_state: "unpublished"
          get :retrieve, params: retrieve_params
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end

  describe "GET 'resource_selection'" do
    it "requires authentication" do
      user_model
      user_session(@user)
      get "resource_selection", params: { course_id: @course.id, external_tool_id: 0 }
      assert_unauthorized
    end

    it "logs the launch" do
      allow(Lti::LogService).to receive(:new) do
        double("Lti::LogService").tap { |s| allow(s).to receive(:call) }
      end

      user_session(@teacher)
      tool = new_valid_tool(@course)

      expect(Lti::LogService).to receive(:new).with(
        tool:,
        context: @course,
        user: @teacher,
        placement: "resource_selection",
        launch_type: :resource_selection
      )

      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id }
    end

    it "is accessible by students" do
      user_session(@student)
      tool = new_valid_tool(@course)
      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id }
      expect(response).to be_successful
    end

    it "redirects if no matching tools are found" do
      user_session(@teacher)
      tool = @course.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob")
      tool.url = "http://www.example.com/basic_lti"
      # this tool exists, but isn't properly configured
      tool.save!
      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id }
      expect(response).to be_redirect
      expect(flash[:error]).to eq "Couldn't find valid settings for this tool"
    end

    it "finds a valid tool if one exists" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params["custom_canvas_enrollment_state"]).to eq "active"
    end

    it "sets html selection if specified" do
      user_session(@teacher)
      tool = new_valid_tool(@course)
      html = "<img src='/blank.png'/>"
      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id, editor_button: "1", selection: html }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params["text"]).to eq CGI.escape(html)
    end

    it "finds account-level tools" do
      @user = account_admin_user
      user_session(@user)

      tool = new_valid_tool(Account.default)
      get "resource_selection", params: { account_id: Account.default.id, external_tool_id: tool.id }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool
    end

    it "is accessible even after course is soft-concluded" do
      user_session(@student)
      @course.start_at = 2.days.ago
      @course.conclude_at = 1.day.ago
      @course.restrict_enrollments_to_course_dates = true
      @course.save!

      tool = new_valid_tool(@course)
      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params["custom_canvas_enrollment_state"]).to eq "inactive"
    end

    it "is accessible even after course is hard-concluded" do
      user_session(@student)
      @course.complete

      tool = new_valid_tool(@course)
      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params["custom_canvas_enrollment_state"]).to eq "inactive"
    end

    it "is accessible even after enrollment is concluded and include a parameter indicating inactive state" do
      user_session(@student)
      e = @student.enrollments.first
      e.conclude
      e.reload
      expect(e.workflow_state).to eq "completed"

      tool = new_valid_tool(@course)
      get "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id }
      expect(response).to be_successful
      expect(assigns[:tool]).to eq tool
      expect(assigns[:lti_launch].params["custom_canvas_enrollment_state"]).to eq "inactive"
    end

    it_behaves_like "an endpoint which uses parent_frame_context to set the CSP header" do
      subject do
        get "resource_selection", params: {
          course_id: @course.id,
          external_tool_id: new_valid_tool(@course).id,
          parent_frame_context: pfc_tool.id
        }
      end

      before { user_session(@student) }

      let(:pfc_tool_context) { @course }
    end

    context "with RCE parameters" do
      subject do
        user_session(@student)
        get "resource_selection", params: {
          course_id: @course.id,
          external_tool_id: tool.id,
          editor: "1",
          selection:,
          editor_contents: contents
        }
      end

      let(:message_type) { raise "override in examples" }
      let(:contents) { "hello world!" }
      let(:selection) { "world!" }
      let(:tool) do
        t = new_valid_tool(@course)
        t.editor_button = { message_type:, icon_url: "http://example.com/icon" }
        t.custom_fields = { contents: "$com.instructure.Editor.contents", selection: "$com.instructure.Editor.selection" }
        t.save
        t
      end

      shared_examples_for "includes editor variables" do
        let(:selection_launch_param) { raise "override" }
        let(:contents_launch_param) { raise "override" }

        it "includes editor selection" do
          subject
          expect(selection_launch_param).to eq selection
        end

        it "includes editor contents" do
          subject
          expect(contents_launch_param).to eq contents
        end
      end

      context "when tool is 1.1" do
        context "during a basic launch" do
          let(:message_type) { "basic-lti-launch-request" }

          it_behaves_like "includes editor variables" do
            let(:selection_launch_param) { assigns[:lti_launch].params["custom_selection"] }
            let(:contents_launch_param) { assigns[:lti_launch].params["custom_contents"] }
          end
        end

        context "during a content item launch" do
          let(:message_type) { "ContentItemSelectionRequest" }

          it_behaves_like "includes editor variables" do
            let(:selection_launch_param) { assigns[:lti_launch].params["custom_selection"] }
            let(:contents_launch_param) { assigns[:lti_launch].params["custom_contents"] }
          end

          it "forwards parent_frame_context to the content item return url" do
            user_session(@teacher)
            tool.resource_selection = { message_type: "ContentItemSelectionRequest" }
            tool.save!
            post "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id, parent_frame_context: tool.id }
            expect(response).to be_successful
            expect(assigns[:lti_launch].params["content_item_return_url"]).to include("parent_frame_context=#{tool.id}")
          end
        end
      end

      context "when tool is 1.3" do
        let(:tool) do
          t = super()
          t.use_1_3 = true
          t.developer_key = DeveloperKey.create!
          t.save
          t
        end

        let(:decoded_jwt) do
          JSON::JWT.decode(assigns[:lti_launch].params["lti_message_hint"], :skip_verification)
        end

        let(:launch_params) do
          JSON.parse(fetch_and_delete_launch(@course, decoded_jwt["verifier"]))
        end

        context "during a basic launch" do
          let(:message_type) { "LtiResourceLinkRequest" }

          it_behaves_like "includes editor variables" do
            let(:selection_launch_param) { launch_params.dig("https://purl.imsglobal.org/spec/lti/claim/custom", "selection") }
            let(:contents_launch_param) { launch_params.dig("https://purl.imsglobal.org/spec/lti/claim/custom", "contents") }
          end
        end

        context "during a deep linking launch" do
          let(:message_type) { "LtiDeepLinkingRequest" }

          it_behaves_like "includes editor variables" do
            let(:selection_launch_param) { launch_params.dig("https://purl.imsglobal.org/spec/lti/claim/custom", "selection") }
            let(:contents_launch_param) { launch_params.dig("https://purl.imsglobal.org/spec/lti/claim/custom", "contents") }
          end

          context "when the parent_frame_context param is sent" do
            before do
              tool.resource_selection = { message_type: "LtiDeepLinkingRequest" }
              tool.save!
              user_session(@teacher)
              post "resource_selection", params: { course_id: @course.id, external_tool_id: tool.id, parent_frame_context: tool.id, editor: true }
            end

            it "forwards parent_frame_context to the deep link return url" do
              deep_link_return_url = launch_params["https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings"]["deep_link_return_url"]
              return_jwt = deep_link_return_url.match(/data=([^&]*)/)[1]
              jwt = JSON::JWT.decode(return_jwt, :skip_verification)
              expect(jwt[:parent_frame_context]).to eq tool.id.to_s
              expect(response).to be_successful
            end

            it "includes parent_frame_context in the lti_message_hint" do
              expect(decoded_jwt["parent_frame_context"]).to eq(tool.id.to_s)
            end
          end
        end
      end
    end
  end

  describe "POST 'create'" do
    let(:launch_url) { "https://www.tool.com/launch" }
    let(:consumer_key) { "key" }
    let(:shared_secret) { "seekret" }
    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
          <blti:title>Example Tool Provider</blti:title>
          <blti:description>This is a Sample Tool Provider.</blti:description>
          <blti:launch_url>https://www.tool.com/launch</blti:launch_url>
          <blti:extensions platform="canvas.instructure.com">
          </blti:extensions>
        </cartridge_basiclti_link>
      XML
    end
    let(:xml_response) { OpenStruct.new({ body: xml }) }

    context "with client id" do
      subject do
        post "create", params:, format: "json"
        ContextExternalTool.find_by(id: tool_id)
      end

      include_context "lti_1_3_spec_helper"

      let(:tool_id) { (response.status == 200) ? response.parsed_body["id"] : -1 }
      let(:tool_configuration) { Lti::ToolConfiguration.create! settings:, developer_key: }
      let(:developer_key) { DeveloperKey.create!(account:) }
      let_once(:user) { account_admin_user(account:) }
      let_once(:account) { account_model }
      let(:params) do
        {
          client_id: developer_key.id,
          account_id: account
        }
      end

      before do
        user_session(user)
        tool_configuration
        enable_developer_key_account_binding!(developer_key)
      end

      it { is_expected.to_not be_nil }

      context "with invalid client id" do
        let(:params) { super().merge(client_id: "bad client id") }

        it "return 404" do
          subject
          expect(response).to have_http_status :not_found
        end
      end

      context "with inactive developer key" do
        let(:developer_key) do
          dev_key = super()
          dev_key.deactivate!
          dev_key
        end

        it "return 422" do
          subject
          expect(response).to have_http_status :unprocessable_entity
        end
      end

      context "with no account binding" do
        before do
          developer_key.developer_key_account_bindings.destroy_all
        end

        it "return 422" do
          subject
          expect(response).to have_http_status :unprocessable_entity
        end
      end
    end

    context "tool duplication" do
      shared_examples_for "detects duplication in context" do
        let(:params) { raise "Override in specs" }

        before do
          allow(CanvasHttp).to receive(:get).and_return(xml_response)
          ContextExternalTool.create!(
            context: @course,
            name: "first tool",
            url: launch_url,
            consumer_key:,
            shared_secret:
          )
        end

        it 'responds with bad request if tool is a duplicate and "verify_uniqueness" is true' do
          user_session(@teacher)
          post "create", params:, format: "json"
          expect(response).to be_bad_request
        end

        it 'gives error message in response if duplicate tool and "verify_uniqueness" is true' do
          user_session(@teacher)
          post "create", params:, format: "json"
          error_message = response.parsed_body.dig("errors", "tool_currently_installed").first["message"]
          expect(error_message).to eq "The tool is already installed in this context."
        end
      end

      context "create manually" do
        it_behaves_like "detects duplication in context" do
          let(:params) do
            {
              course_id: @course.id,
              external_tool: {
                name: "tool name",
                url: launch_url,
                consumer_key:,
                shared_secret:,
                verify_uniqueness: "true"
              }
            }
          end
        end
      end

      context "create via XML" do
        it_behaves_like "detects duplication in context" do
          let(:params) do
            {
              course_id: @course.id,
              external_tool: {
                name: "tool name",
                consumer_key:,
                shared_secret:,
                verify_uniqueness: "true",
                config_type: "by_xml",
                config_xml: xml
              }
            }
          end
        end
      end

      context "create via URL" do
        it_behaves_like "detects duplication in context" do
          let(:params) do
            {
              course_id: @course.id,
              external_tool: {
                name: "tool name",
                consumer_key:,
                shared_secret:,
                verify_uniqueness: "true",
                config_type: "by_url",
                config_url: "http://config.example.com"
              }
            }
          end
        end
      end

      context "create via client id" do
        include_context "lti_1_3_spec_helper"
        let(:tool_configuration) { Lti::ToolConfiguration.create! settings:, developer_key: }
        let(:developer_key) { DeveloperKey.create!(account: @course.account) }

        before do
          tool = tool_configuration.new_external_tool(@course)
          tool.save!
          enable_developer_key_account_binding!(developer_key)
        end

        it_behaves_like "detects duplication in context" do
          let(:params) do
            {
              client_id: developer_key.id,
              course_id: @course.id,
              external_tool: {
                verify_uniqueness: "true"
              }
            }
          end
        end
      end
    end

    it "requires authentication" do
      post "create", params: { course_id: @course.id }, format: "json"
      assert_status(401)
    end

    it "does not create tool if user lacks create_tool_manually" do
      user_session(@student)
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret" } }, format: "json"
      assert_status(401)
    end

    it "creates tool if user is granted create_tool_manually" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret" } }, format: "json"
      assert_status(200)
    end

    it "accepts basic configurations" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret" } }, format: "json"
      expect(response).to be_successful
      expect(assigns[:tool]).not_to be_nil
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].url).to eq "http://example.com"
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
    end

    it "accepts is_rce_favorite parameter" do
      user_session(account_admin_user)
      post "create",
           params: {
             account_id: @course.account.id,
             external_tool: {
               name: "tool name",
               url: "http://example.com",
               consumer_key: "key",
               shared_secret: "secret",
               editor_button: { url: "http://example.com", enabled: true },
               is_rce_favorite: true
             }
           },
           format: "json"
      expect(response).to be_successful
      expect(assigns[:tool].is_rce_favorite).to be true
    end

    it "sets the oauth_compliant setting" do
      user_session(@teacher)
      external_tool_settings = { name: "tool name",
                                 url: "http://example.com",
                                 consumer_key: "key",
                                 shared_secret: "secret",
                                 oauth_compliant: true }
      post "create", params: { course_id: @course.id, external_tool: external_tool_settings }, format: "json"
      expect(assigns[:tool].settings[:oauth_compliant]).to equal true
    end

    it "fails on basic xml with no url or domain set" do
      user_session(@teacher)
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
            xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
            xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
            xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
            xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
            http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
            <blti:title>Other Name</blti:title>
            <blti:description>Description</blti:description>
            <blti:extensions platform="canvas.instructure.com">
              <lticm:property name="privacy_level">public</lticm:property>
            </blti:extensions>
            <cartridge_bundle identifierref="BLTI001_Bundle"/>
            <cartridge_icon identifierref="BLTI001_Icon"/>
        </cartridge_basiclti_link>
      XML
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", consumer_key: "key", shared_secret: "secret", config_type: "by_xml", config_xml: xml } }, format: "json"
      expect(response).not_to be_successful
    end

    it "handles advanced xml configurations" do
      user_session(@teacher)
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
            xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
            xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
            xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
            xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
            http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
            <blti:title>Other Name</blti:title>
            <blti:description>Description</blti:description>
            <blti:launch_url>http://example.com/other_url</blti:launch_url>
            <blti:extensions platform="canvas.instructure.com">
              <lticm:property name="privacy_level">public</lticm:property>
              <lticm:property name="not_selectable">true</lticm:property>
              <lticm:options name="editor_button">
                <lticm:property name="url">http://example.com/editor</lticm:property>
                <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
                <lticm:property name="text">Editor Button</lticm:property>
                <lticm:property name="selection_width">500</lticm:property>
                <lticm:property name="selection_height">300</lticm:property>
              </lticm:options>
              <lticm:property name="oauth_compliant">
               true
              </lticm:property>
            </blti:extensions>
            <cartridge_bundle identifierref="BLTI001_Bundle"/>
            <cartridge_icon identifierref="BLTI001_Icon"/>
        </cartridge_basiclti_link>
      XML
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret", config_type: "by_xml", config_xml: xml } }, format: "json"
      expect(response).to be_successful
      expect(assigns[:tool]).not_to be_nil
      # User-entered name overrides name provided in xml
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].description).to eq "Description"
      expect(assigns[:tool].url).to eq "http://example.com/other_url"
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
      expect(assigns[:tool].not_selectable).to be_truthy
      expect(assigns[:tool].has_placement?(:editor_button)).to be_truthy
      expect(assigns[:tool].settings[:oauth_compliant]).to be_truthy
    end

    it "handles advanced xml configurations with no url or domain set" do
      user_session(@teacher)
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
            xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
            xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
            xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
            xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
            http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
            <blti:title>Other Name</blti:title>
            <blti:description>Description</blti:description>
            <blti:extensions platform="canvas.instructure.com">
              <lticm:property name="privacy_level">public</lticm:property>
              <lticm:options name="editor_button">
                <lticm:property name="url">http://example.com/editor</lticm:property>
                <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
                <lticm:property name="text">Editor Button</lticm:property>
                <lticm:property name="selection_width">500</lticm:property>
                <lticm:property name="selection_height">300</lticm:property>
              </lticm:options>
            </blti:extensions>
            <cartridge_bundle identifierref="BLTI001_Bundle"/>
            <cartridge_icon identifierref="BLTI001_Icon"/>
        </cartridge_basiclti_link>
      XML
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", consumer_key: "key", shared_secret: "secret", config_type: "by_xml", config_xml: xml } }, format: "json"
      expect(response).to be_successful
      expect(assigns[:tool]).not_to be_nil
      # User-entered name overrides name provided in xml
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].description).to eq "Description"
      expect(assigns[:tool].url).to be_nil
      expect(assigns[:tool].domain).to be_nil
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
      expect(assigns[:tool].has_placement?(:editor_button)).to be_truthy
    end

    it "handles advanced xml configurations by URL retrieval" do
      user_session(@teacher)
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0"
            xmlns:blti = "http://www.imsglobal.org/xsd/imsbasiclti_v1p0"
            xmlns:lticm ="http://www.imsglobal.org/xsd/imslticm_v1p0"
            xmlns:lticp ="http://www.imsglobal.org/xsd/imslticp_v1p0"
            xmlns:xsi = "http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation = "http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd
            http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd
            http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
            <blti:title>Other Name</blti:title>
            <blti:description>Description</blti:description>
            <blti:launch_url>http://example.com/other_url</blti:launch_url>
            <blti:extensions platform="canvas.instructure.com">
              <lticm:property name="privacy_level">public</lticm:property>
              <lticm:options name="editor_button">
                <lticm:property name="url">http://example.com/editor</lticm:property>
                <lticm:property name="icon_url">http://example.com/icon.png</lticm:property>
                <lticm:property name="text">Editor Button</lticm:property>
                <lticm:property name="selection_width">500</lticm:property>
                <lticm:property name="selection_height">300</lticm:property>
              </lticm:options>
            </blti:extensions>
            <cartridge_bundle identifierref="BLTI001_Bundle"/>
            <cartridge_icon identifierref="BLTI001_Icon"/>
        </cartridge_basiclti_link>
      XML
      obj = OpenStruct.new({ body: xml })
      allow(CanvasHttp).to receive(:get).and_return(obj)
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret", config_type: "by_url", config_url: "http://config.example.com" } }, format: "json"

      expect(response).to be_successful
      expect(assigns[:tool]).not_to be_nil
      # User-entered name overrides name provided in xml
      expect(assigns[:tool].name).to eq "tool name"
      expect(assigns[:tool].description).to eq "Description"
      expect(assigns[:tool].url).to eq "http://example.com/other_url"
      expect(assigns[:tool].consumer_key).to eq "key"
      expect(assigns[:tool].shared_secret).to eq "secret"
      expect(assigns[:tool].has_placement?(:editor_button)).to be_truthy
    end

    it "fails gracefully on invalid URL retrieval or timeouts" do
      allow(CanvasHttp).to receive(:get).and_raise(Timeout::Error)
      user_session(@teacher)
      post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret", config_type: "by_url", config_url: "http://config.example.com" } }, format: "json"
      expect(response).not_to be_successful
      expect(assigns[:tool]).to be_new_record
      json = json_parse(response.body)
      expect(json["errors"]["config_url"][0]["message"]).to eq I18n.t(:retrieve_timeout, "could not retrieve configuration, the server response timed out")
    end

    it "fails gracefully trying to retrieve from localhost" do
      expect(CanvasHttp).to receive(:insecure_host?).with("localhost").and_return(true)
      user_session(@teacher)
      post "create",
           params: { course_id: @course.id,
                     external_tool: { name: "tool name",
                                      url: "http://example.com",
                                      consumer_key: "key",
                                      shared_secret: "secret",
                                      config_type: "by_url",
                                      config_url: "http://localhost:9001" } },
           format: "json"
      expect(response).not_to be_successful
      expect(assigns[:tool]).to be_new_record
      json = json_parse(response.body)
      expect(json["errors"]["config_url"][0]["message"]).to eq "Invalid URL"
    end

    it "stores placement config using string key" do
      expect(CanvasHttp).to receive(:insecure_host?).with("localhost").and_return(true)
      user_session(@teacher)

      post "create",
           params: { course_id: @course.id,
                     external_tool: { name: "tool name",
                                      url: "http://example.com",
                                      consumer_key: "key",
                                      shared_secret: "secret",
                                      config_type: "by_url",
                                      config_url: "http://localhost:9001",
                                      course_navigation: { enabled: true } } },
           format: "json"
      expect(assigns[:tool].settings).to have_key "course_navigation"
    end

    context "navigation tabs caching" do
      it "does not clear the navigation tabs cache for non navigtaion tools" do
        enable_cache do
          user_session(@teacher)
          nav_cache = Lti::NavigationCache.new(@course.root_account)
          cache_key = nav_cache.cache_key
          xml = <<~XML
            <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
              <blti:title>Redirect Tool</blti:title>
              <blti:description>
                Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
              </blti:description>
              <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
              <blti:custom>
                <lticm:property name="url">https://</lticm:property>
              </blti:custom>
              <blti:extensions platform="canvas.instructure.com">
                <lticm:property name="icon_url">
                  https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
                </lticm:property>
                <lticm:property name="link_text"/>
                <lticm:property name="privacy_level">anonymous</lticm:property>
                <lticm:property name="tool_id">redirect</lticm:property>
              </blti:extensions>
            </cartridge_basiclti_link>
          XML
          post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret", config_type: "by_xml", config_xml: xml } }, format: "json"
          expect(response).to be_successful
          expect(nav_cache.cache_key).to eq cache_key
        end
      end

      it "clears the navigation tabs cache for course nav" do
        enable_cache do
          user_session(@teacher)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<~XML
            <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
              <blti:title>Redirect Tool</blti:title>
              <blti:description>
                Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
              </blti:description>
              <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
              <blti:custom>
                <lticm:property name="url">https://</lticm:property>
              </blti:custom>
              <blti:extensions platform="canvas.instructure.com">
                <lticm:options name="course_navigation">
                  <lticm:property name="enabled">true</lticm:property>
                  <lticm:property name="visibility">public</lticm:property>
                </lticm:options>
                <lticm:property name="icon_url">
                  https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
                </lticm:property>
                <lticm:property name="link_text"/>
                <lticm:property name="privacy_level">anonymous</lticm:property>
                <lticm:property name="tool_id">redirect</lticm:property>
              </blti:extensions>
            </cartridge_basiclti_link>
          XML
          post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret", config_type: "by_xml", config_xml: xml } }, format: "json"
          expect(response).to be_successful
          expect(Lti::NavigationCache.new(@course.root_account).cache_key).not_to eq cache_key
        end
      end

      it "clears the navigation tabs cache for account nav" do
        enable_cache do
          user_session(@teacher)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<~XML
            <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
              <blti:title>Redirect Tool</blti:title>
              <blti:description>
                Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
              </blti:description>
              <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
              <blti:custom>
                <lticm:property name="url">https://</lticm:property>
              </blti:custom>
              <blti:extensions platform="canvas.instructure.com">
                <lticm:options name="account_navigation">
                  <lticm:property name="enabled">true</lticm:property>
                  <lticm:property name="visibility">public</lticm:property>
                </lticm:options>
                <lticm:property name="icon_url">
                  https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
                </lticm:property>
                <lticm:property name="link_text"/>
                <lticm:property name="privacy_level">anonymous</lticm:property>
                <lticm:property name="tool_id">redirect</lticm:property>
              </blti:extensions>
            </cartridge_basiclti_link>
          XML
          post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret", config_type: "by_xml", config_xml: xml } }, format: "json"
          expect(response).to be_successful
          expect(Lti::NavigationCache.new(@course.root_account).cache_key).not_to eq cache_key
        end
      end

      it "clears the navigation tabs cache for user nav" do
        enable_cache do
          user_session(@teacher)
          cache_key = Lti::NavigationCache.new(@course.root_account).cache_key
          xml = <<~XML
            <cartridge_basiclti_link xmlns="http://www.imsglobal.org/xsd/imslticc_v1p0" xmlns:blti="http://www.imsglobal.org/xsd/imsbasiclti_v1p0" xmlns:lticm="http://www.imsglobal.org/xsd/imslticm_v1p0" xmlns:lticp="http://www.imsglobal.org/xsd/imslticp_v1p0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.imsglobal.org/xsd/imslticc_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticc_v1p0.xsd http://www.imsglobal.org/xsd/imsbasiclti_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imsbasiclti_v1p0p1.xsd http://www.imsglobal.org/xsd/imslticm_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticm_v1p0.xsd http://www.imsglobal.org/xsd/imslticp_v1p0 http://www.imsglobal.org/xsd/lti/ltiv1p0/imslticp_v1p0.xsd">
              <blti:title>Redirect Tool</blti:title>
              <blti:description>
                Add links to external web resources that show up as navigation items in course, user or account navigation. Whatever URL you specify is loaded within the content pane when users click the link.
              </blti:description>
              <blti:launch_url>https://www.edu-apps.org/redirect</blti:launch_url>
              <blti:custom>
                <lticm:property name="url">https://</lticm:property>
              </blti:custom>
              <blti:extensions platform="canvas.instructure.com">
                <lticm:options name="user_navigation">
                  <lticm:property name="enabled">true</lticm:property>
                  <lticm:property name="visibility">public</lticm:property>
                </lticm:options>
                <lticm:property name="icon_url">
                  https://www.edu-apps.org/assets/lti_redirect_engine/redirect_icon.png
                </lticm:property>
                <lticm:property name="link_text"/>
                <lticm:property name="privacy_level">anonymous</lticm:property>
                <lticm:property name="tool_id">redirect</lticm:property>
              </blti:extensions>
            </cartridge_basiclti_link>
          XML
          post "create", params: { course_id: @course.id, external_tool: { name: "tool name", url: "http://example.com", consumer_key: "key", shared_secret: "secret", config_type: "by_xml", config_xml: xml } }, format: "json"
          expect(response).to be_successful
          expect(Lti::NavigationCache.new(@course.root_account).cache_key).not_to eq cache_key
        end
      end
    end
  end

  describe "PUT 'update'" do
    it "updates tool with tool_configuration[prefer_sis_email] param" do
      @tool = new_valid_tool(@course)
      user_session(@teacher)

      put :update, params: { course_id: @course.id, external_tool_id: @tool.id, external_tool: { tool_configuration: { prefer_sis_email: "true" } } }, format: "json"

      expect(response).to be_successful

      json = json_parse(response.body)

      expect(json["tool_configuration"]).to be_truthy
      expect(json["tool_configuration"]["prefer_sis_email"]).to eq "true"
    end

    it "updates allow_membership_service_access if the feature flag is set" do
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:membership_service_for_lti_tools).and_return(true)
      @tool = new_valid_tool(@course)
      user_session(@teacher)

      put :update, params: { course_id: @course.id, external_tool_id: @tool.id, external_tool: { allow_membership_service_access: true } }, format: "json"

      expect(response).to be_successful
      expect(@tool.reload.allow_membership_service_access).to be true
    end

    it "does not update allow_membership_service_access if the feature flag is not set" do
      @tool = new_valid_tool(@course)
      user_session(@teacher)

      put :update, params: { course_id: @course.id, external_tool_id: @tool.id, external_tool: { allow_membership_service_access: true } }, format: "json"

      expect(response).to be_successful
      expect(@tool.reload.allow_membership_service_access).to be_falsey
    end

    it "accepts is_rce_favorite parameter" do
      user_session(account_admin_user)
      @tool = new_valid_tool(@course.root_account)
      @tool.editor_button = { url: "http://example.com", icon_url: "http://example.com", enabled: true }
      @tool.save!
      put :update, params: { account_id: @course.root_account.id, external_tool_id: @tool.id, external_tool: { is_rce_favorite: true } }, format: "json"
      expect(response).to be_successful
      expect(assigns[:tool].is_rce_favorite).to be true
    end

    it "updates placement properties if the enabled key is set to false" do
      user_session(account_admin_user)
      @tool = new_valid_tool(@course.root_account)
      @tool.editor_button = { url: "https://example.com", icon_url: "https://example.com", enabled: false }
      @tool.save!

      put :update,
          params: {
            account_id: @course.root_account.id,
            external_tool_id: @tool.id,
            external_tool: { editor_button: { url: "https://new-example.com" } }
          },
          format: "json"
      tool_updated = ContextExternalTool.find(@tool.id)
      inactive_placements = tool_updated[:settings][:inactive_placements]
      editor_button = tool_updated[:settings][:editor_button]

      expect(response).to be_successful
      expect(inactive_placements).to include(:editor_button)
      expect(inactive_placements[:editor_button][:url]).to eq "https://new-example.com"
      expect(editor_button).to be_nil
    end

    it "allows to remove the app placement entirely" do
      user_session(account_admin_user)
      @tool = new_valid_tool(@course.root_account)
      @tool.editor_button = { url: "https://example.com", icon_url: "https://example.com", enabled: false }
      @tool.save!

      put :update,
          params: {
            account_id: @course.root_account.id,
            external_tool_id: @tool.id,
            external_tool: { editor_button: "null" }
          },
          format: "json"
      expect(response).to be_successful
      expect(@tool.reload.editor_button).to be_nil
    end
  end

  describe "'GET 'generate_sessionless_launch'" do
    let(:login_pseudonym) { pseudonym(@user) }
    let(:tool) { new_valid_tool(@course) }
    let(:url) { URI.parse(response.parsed_body["url"]) }
    let(:query_params) { CGI.parse(url.query) }
    let(:verifier) { query_params["verifier"].first }
    let(:session_token) { SessionToken.parse(query_params["session_token"].first) }
    let(:launch_settings) do
      redis_key = "#{@course.class.name}:#{Lti::RedisMessageClient::SESSIONLESS_LAUNCH_PREFIX}#{verifier}"
      JSON.parse(Canvas.redis.get(redis_key))
    end
    let(:tool_settings) { launch_settings["tool_settings"] }

    before do
      allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
      allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
      user_session(@user, login_pseudonym)
    end

    it "generates a sessionless launch" do
      get :generate_sessionless_launch, params: { course_id: @course.id, id: tool.id }

      expect(response).to be_successful

      expect(launch_settings["launch_url"]).to eq "http://www.example.com/basic_lti"
      expect(launch_settings.dig("metadata", "launch_type")).to eq "direct_link"
      expect(launch_settings["tool_name"]).to eq "bob"
      expect(launch_settings["analytics_id"]).to eq "some_tool"
      expect(tool_settings["custom_canvas_course_id"]).to eq @course.id.to_s
      expect(tool_settings["custom_canvas_user_id"]).to eq @user.id.to_s
    end

    context "when using an API token" do
      let(:access_token) { login_pseudonym.user.access_tokens.create(purpose: "test") }

      before { controller.instance_variable_set :@access_token, access_token }

      it "adds a session_token to log the user in" do
        get :generate_sessionless_launch, params: { course_id: @course.id, id: tool.id }

        expect(response).to be_successful

        expect(session_token.pseudonym_id).to eq(login_pseudonym.global_id)
      end
    end

    context "when the launch url has query params" do
      let(:tool) { new_valid_tool(@course, { url: "http://www.example.com/basic_lti?tripping", post_only: true }) }

      it "strips query param from launch_url before signing, attaches to post body, and removes query params in url for launch" do
        get :generate_sessionless_launch, params: { course_id: @course.id, id: tool.id }

        expect(response).to be_successful

        expect(launch_settings["launch_url"]).to eq "http://www.example.com/basic_lti"
        expect(launch_settings["tool_settings"]).to have_key "tripping"
      end
    end

    context 'with "launch_type" set to "assessment' do
      let(:due_at) { Time.zone.now }
      let(:course) { @course }
      let(:assignment) do
        a = assignment_model(
          course: @course,
          name: "tool assignment",
          submission_types: "external_tool",
          points_possible: 20,
          grading_type: "points",
          due_at:
        )

        tag = @assignment.build_external_tool_tag(url: tool.url)
        tag.update!(content_type: "ContextExternalTool")

        a
      end

      before do
        tool.settings["custom_fields"] ||= {}
        tool.settings["custom_fields"]["assignment_due_at"] = "$Canvas.assignment.dueAt.iso8601"
        tool.save!
      end

      it "generates a sessionless launch for an external tool assignment" do
        get :generate_sessionless_launch, params: { course_id: course.id, launch_type: "assessment", assignment_id: assignment.id }
        expect(response).to be_successful

        expect(launch_settings["launch_url"]).to eq "http://www.example.com/basic_lti"
        expect(launch_settings.dig("metadata", "launch_type")).to eq "content_item"
        expect(launch_settings["tool_name"]).to eq "bob"
        expect(launch_settings["analytics_id"]).to eq "some_tool"
        expect(tool_settings["custom_canvas_course_id"]).to eq @course.id.to_s
        expect(tool_settings["custom_canvas_user_id"]).to eq @user.id.to_s
        expect(tool_settings["resource_link_id"]).to eq opaque_id(@assignment.external_tool_tag)
        expect(tool_settings["resource_link_title"]).to eq "tool assignment"

        expect(Time.parse(tool_settings["custom_assignment_due_at"])).to be_within(5.seconds).of due_at
      end

      context "and the assignment has due date overrides" do
        let!(:assignment_override) do
          override = assignment.assignment_overrides.create!(
            title: "1 student",
            set_type: "ADHOC",
            due_at_overridden: true,
            due_at: due_at + 1.day
          )

          override.assignment_override_students.create!(user: @user)

          override
        end

        it "sends the overridden due_at value in the launch parameters" do
          get :generate_sessionless_launch, params: { course_id: course.id, launch_type: "assessment", assignment_id: assignment.id }

          expect(Time.parse(tool_settings["custom_assignment_due_at"])).to be_within(5.seconds).of(assignment_override.due_at)
        end
      end
    end

    context "when url is provided in params" do
      let(:provided_url) { "https://www.example.com/sessionless_launch" }

      it "uses it for launch_url" do
        get :generate_sessionless_launch, params: { course_id: @course.id, id: tool.id, url: provided_url }
        expect(response).to be_successful
        expect(launch_settings["launch_url"]).to eq provided_url
      end
    end

    context "with only launch url" do
      it "is successful" do
        get :generate_sessionless_launch, params: { course_id: @course.id, url: tool.url }
        expect(response).to be_successful
        expect(launch_settings.dig("metadata", "launch_type")).to eq "indirect_link"
      end
    end

    context "with environment-specific overrides" do
      let(:override_url) { "http://www.example-beta.com/basic_lti" }
      let(:domain) { "www.example-beta.com" }

      before do
        allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")
        user_session(account_admin_user)

        tool.settings[:environments] = {
          domain:
        }
        tool.save!
      end

      it "uses override for resource_url" do
        get :generate_sessionless_launch, params: { course_id: @course.id, id: tool.id }
        expect(response).to be_successful
        expect(launch_settings["launch_url"]).to eq override_url
      end

      context "when launch_url is passed in params" do
        let(:launch_url) { "https://www.example.com/other_lti_launch" }
        let(:override_launch_url) { "https://www.example-beta.com/other_lti_launch" }

        it "uses overridden launch_url for resource_url" do
          get :generate_sessionless_launch, params: { course_id: @course.id, id: tool.id, url: launch_url }
          expect(response).to be_successful
          expect(launch_settings["launch_url"]).to eq override_launch_url
        end
      end
    end

    it "passes whitelisted `platform` query param to lti launch body" do
      assignment_model(course: @course,
                       name: "tool assignment",
                       submission_types: "external_tool",
                       points_possible: 20,
                       grading_type: "points")
      tag = @assignment.build_external_tool_tag(url: tool.url)
      tag.content_type = "ContextExternalTool"
      tag.save!

      get :generate_sessionless_launch, params: {
        course_id: @course.id,
        launch_type: "assessment",
        assignment_id: @assignment.id,
        platform: "mobile"
      }
      expect(response).to be_successful

      expect(tool_settings["ext_platform"]).to eq "mobile"
    end

    it "requires context_module_id for module_item launch type" do
      @cm = ContextModule.create(context: @course)
      @tg = ContentTag.create(context: @course,
                              context_module: @cm,
                              content_type: "ContextExternalTool",
                              content: tool)

      get :generate_sessionless_launch,
          params: { course_id: @course.id,
                    launch_type: "module_item",
                    content_type: "ContextExternalTool" }

      expect(response).not_to be_successful
      expect(response.body).to include "A module item id must be provided for module item LTI launch"
    end

    it "Sets the correct resource_link_id for module items when module_item_id is provided" do
      @cm = ContextModule.create(context: @course)
      @tg = ContentTag.create(context: @course,
                              context_module: @cm,
                              content_type: "ContextExternalTool",
                              content: @tool,
                              url: tool.url,
                              title: "my module item title")
      @cm.content_tags << @tg
      @cm.save!
      @course.save!

      get :generate_sessionless_launch,
          params: { course_id: @course.id,
                    launch_type: "module_item",
                    module_item_id: @tg.id,
                    content_type: "ContextExternalTool" }

      expect(response).to be_successful

      expect(launch_settings["tool_settings"]["resource_link_id"]).to eq opaque_id(@tg)
      expect(launch_settings["tool_settings"]["resource_link_title"]).to eq "my module item title"
      expect(launch_settings.dig("metadata", "launch_type")).to eq "content_item"
    end

    it "makes the module item available for variable expansions" do
      tool.settings[:custom_fields] = { "standard" => "$Canvas.moduleItem.id" }
      tool.save!
      @cm = ContextModule.create(context: @course)
      @tg = ContentTag.create(context: @course,
                              context_module: @cm,
                              content_type: "ContextExternalTool",
                              content: tool,
                              url: tool.url)
      @cm.content_tags << @tg
      @cm.save!
      @course.save!

      get :generate_sessionless_launch,
          params: { course_id: @course.id,
                    launch_type: "module_item",
                    module_item_id: @tg.id,
                    content_type: "ContextExternalTool" }

      expect(launch_settings.dig("tool_settings", "custom_standard")).to eq @tg.id.to_s
    end

    it "redirects if there is no matching tool for the launch_url, and tool id" do
      params = { course_id: @course.id, url: "http://my_non_esisting_tool_domain.com", id: -1 }
      expect(get(:generate_sessionless_launch, params:)).to redirect_to course_url(@course)
    end

    it "redirects if there is no matching tool for the and tool id" do
      params = { course_id: @course.id, id: -1 }
      expect(get(:generate_sessionless_launch, params:)).to redirect_to course_url(@course)
    end

    it "redirects if there is no launch url associated with the tool" do
      tool.update!(url: nil)
      params = { course_id: @course.id, id: tool.id }
      expect(get(:generate_sessionless_launch, params:)).to redirect_to course_url(@course)
    end

    context "with 1.3 tool" do
      include_context "lti_1_3_spec_helper"

      let(:tool) do
        t = tool_configuration.new_external_tool(@course)
        t.save!
        t
      end
      let(:rl) do
        Lti::ResourceLink.create!(
          context_external_tool: tool,
          context: @course,
          custom: { abc: "def", expans: "$Canvas.user.id" },
          url: "http://www.example.com/launch"
        )
      end
      let(:params) { { course_id: @course.id, id: tool.id } }
      let(:account) { @course.account }
      let(:access_token) { login_pseudonym.user.access_tokens.create(purpose: "test") }

      before { controller.instance_variable_set :@access_token, access_token }

      it "returns the lti 1.3 launch url with a session token when not given url or lookup_id" do
        get(:generate_sessionless_launch, params:)
        expect(response).to be_successful

        expect(url.path).to eq("#{course_external_tools_path(@course)}/#{tool.id}")
        expect(url.query).to match(/session_token=[0-9a-zA-Z_-]+/)
        expect(session_token.pseudonym_id).to eq(login_pseudonym.global_id)
      end

      it "returns the lti 1.3 launch url with a session token when given a url and tool id" do
        get :generate_sessionless_launch, params: params.merge(url: "http://lti13testtool.docker/deep_link")
        expect(response).to be_successful

        expect(url.path).to eq("#{course_external_tools_path(@course)}/#{tool.id}")
        expect(query_params).to have_key("display")
        expect(query_params).to have_key("launch_url")
        expect(query_params).to have_key("session_token")
        expect(session_token.pseudonym_id).to eq(login_pseudonym.global_id)
      end

      it "returns the specified launch url for a deep link" do
        get :generate_sessionless_launch, params: params.merge(id: tool.id, url: "http://lti13testtool.docker/deep_link")
        expect(response).to be_successful
        expect(query_params["launch_url"]).to eq ["http://lti13testtool.docker/deep_link"]
      end

      context "when not passing tool_id" do
        let(:params) { { course_id: @course.id } }

        it "returns the lti 1.3 resource link lookup uuid with a session token when given a lookup_uuid" do
          get :generate_sessionless_launch, params: params.merge(resource_link_lookup_uuid: rl.lookup_uuid)
          expect(response).to be_successful

          expect(url.path).to eq("#{course_external_tools_path(@course)}/retrieve")
          expect(query_params).to have_key("display")
          expect(query_params).to have_key("resource_link_lookup_uuid")
          expect(query_params).to have_key("session_token")
          expect(session_token.pseudonym_id).to eq(login_pseudonym.global_id)
        end

        it "returns the lti 1.3 launch url with a session token when given a url and a lookup_id" do
          get :generate_sessionless_launch, params: params.merge(url: "http://lti13testtool.docker/deep_link", resource_link_lookup_uuid: rl.lookup_uuid)
          expect(response).to be_successful

          expect(url.path).to eq("#{course_external_tools_path(@course)}/retrieve")
          expect(query_params).to have_key("display")
          expect(query_params).to have_key("resource_link_lookup_uuid")
          expect(query_params).to have_key("session_token")
          expect(session_token.pseudonym_id).to eq(login_pseudonym.global_id)
        end
      end

      context "when there is no access to token (non-API access)" do
        let(:access_token) { nil }

        it "returns a 401" do
          get(:generate_sessionless_launch, params:)
          expect(response).to_not be_successful
          expect(response.code.to_i).to eq(401)
        end
      end

      context "when the developer key requires scopes" do
        before do
          access_token.developer_key.update!(require_scopes: true)
        end

        it 'responds with "unauthorized" if developer key requires scopes' do
          get(:generate_sessionless_launch, params:)
          expect(response).to be_unauthorized
        end
      end

      context "with a cross-shard launch" do
        specs_require_sharding

        let!(:tool) do
          t = tool_configuration.new_external_tool(course)
          t.save!
          t
        end

        let(:course) do
          course = course_model(account:)
          course.enroll_user(user, "StudentEnrollment", { enrollment_state: "active" })
          course.offer!
          course
        end

        let(:user) { @shard2.activate { user_model(name: "cross-shard user") } }
        let(:developer_key) { DeveloperKey.create!(account:) }
        let(:account) { Account.default }
        let(:tool_root_account) { account_model }
        let(:access_token) { pseudonym(user).user.access_tokens.create(purpose: "test") }
        let(:account_host) { "canvas-test.instructure.com" }
        let(:tool_host) { "canvas-test-2.instructure.com" }
        let(:params) { { course_id: course.global_id, id: tool.global_id } }

        before do
          tool.update_attribute(:root_account_id, tool_root_account.id)
          tool_root_account.account_domains.create!(host: tool_host)
          account.account_domains.create!(host: account_host)
          user_session(user)
          request.host = account_host
        end

        it "returns the lti 1.3 launch url with a session token" do
          expect(HTTParty).to receive(:get) do |url, options|
            expect(url).to eq "http://#{tool_host}/api/v1/courses/#{course.shard.id}~#{course.local_id}/external_tools/sessionless_launch?course_id=#{course.id}&id=#{tool.id}&redirect=true"
            expect(options[:headers].keys).to include "Authorization"
          end

          @shard2.activate { get :generate_sessionless_launch, params: }
        end

        context 'with a "redirect" flag' do
          let(:params) { { course_id: course.global_id, id: tool.global_id, redirect: true } }

          it "uses the request host" do
            @shard2.activate { get :generate_sessionless_launch, params: }
            expect(URI(json_parse["url"]).host).to eq account_host
          end
        end

        context "when the context is not a course" do
          let!(:tool) do
            t = tool_configuration.new_external_tool(course.account)
            t.save!
            t
          end

          let(:params) { { account_id: course.account.global_id, id: tool.global_id, redirect: true } }

          it "uses the request host" do
            @shard2.activate { get :generate_sessionless_launch, params: }
            expect(URI(json_parse["url"]).host).to eq account_host
          end
        end

        context "when an API token is not used" do
          let(:access_token) { nil }

          it "does not return a sessionless launch URI" do
            @shard2.activate { get :generate_sessionless_launch, params: }
            expect(response).to be_unauthorized
          end
        end

        context "when the cross-account request fails" do
          before { allow(HTTParty).to receive(:get).and_return(double("success?" => false)) }

          it "uses the request host" do
            @shard2.activate { get :generate_sessionless_launch, params: }
            expect(URI(json_parse["url"]).host).to eq account_host
          end
        end
      end

      context "with an assignment launch" do
        before do
          assignment.update!(
            external_tool_tag: content_tag,
            submission_types: "external_tool"
          )
        end

        let(:assignment) { assignment_model(course: @course) }
        let(:launch_url) { tool.url }
        let(:params) { { course_id: @course.id, launch_type: :assessment, assignment_id: assignment.id } }
        let(:content_tag) { ContentTag.create!(context: assignment, content: tool, url: launch_url) }

        it "returns an assignment launch URL" do
          get(:generate_sessionless_launch, params:)
          expect(json_parse["url"]).to include "http://test.host/courses/#{@course.id}/assignments/#{assignment.id}?display=borderless&session_token="
        end

        context "and the assignment is missing AGS records" do
          before do
            assignment.line_items.destroy_all

            Lti::ResourceLink.where(
              resource_link_uuid: assignment.lti_context_id
            ).destroy_all

            get :generate_sessionless_launch, params:
          end

          it "creates the missing line item" do
            expect(assignment.reload.line_items).to be_present
          end

          it "creates the missing resource link" do
            expect(Lti::ResourceLink.where(resource_link_uuid: assignment.lti_context_id)).to be_present
          end
        end
      end

      context "with a module item launch" do
        subject do
          get(:generate_sessionless_launch, params:)
          json_parse["url"]
        end

        let(:launch_url) { tool.url }
        let(:params) { { course_id: @course.id, launch_type: :module_item, module_item_id: module_item.id } }
        let(:context_module) do
          ContextModule.create!(
            context: @course,
            name: "External Tools"
          )
        end
        let(:module_item) do
          ContentTag.create!(
            context: @course,
            context_module:,
            content: tool,
            url: launch_url
          )
        end

        it { is_expected.to include "http://test.host/courses/#{@course.id}/modules/items/#{module_item.id}" }

        it { is_expected.to include "display=borderless" }

        it { is_expected.to match(/session_token=\w+/) }
      end

      context "when there is a URL but no launch_type or ID" do
        before do
          get :generate_sessionless_launch, params: { course_id: @course.id, url: tool.url }
        end

        it "generates a retrieve URL with the url" do
          expect(json_parse["url"]).to start_with("http://test.host/courses/#{@course.id}/external_tools/retrieve?")
          expect(json_parse["url"]).to include("display=borderless")
          expect(json_parse["url"]).to include("url=#{CGI.escape tool.url}")
        end

        it "finds the tool" do
          expect(json_parse["id"]).to eq(tool.id)
        end
      end
    end
  end

  describe "#sessionless_launch" do
    let(:tool) do
      new_valid_tool(@course).tap do |t|
        t.course_navigation = { enabled: true }
        t.save!
      end
    end
    let(:verifier) do
      get :generate_sessionless_launch, params: { course_id: @course.id, id: tool.id, launch_type: :course_navigation }
      json = response.parsed_body
      CGI.parse(URI.parse(json["url"]).query)["verifier"].first
    end

    before do
      allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
      allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
      user_session(@user)
    end

    it "generates a sessionless launch" do
      expect(controller).to receive(:log_asset_access).once
      get :sessionless_launch, params: { course_id: @course.id, verifier: }
    end

    it "logs the launch" do
      allow(Lti::LogService).to receive(:new) do
        double("Lti::LogService").tap { |s| allow(s).to receive(:call) }
      end

      get :sessionless_launch, params: { course_id: @course.id, verifier: }

      expect(Lti::LogService).to have_received(:new).with(
        tool:,
        context: @course,
        user: @user,
        placement: "course_navigation",
        launch_type: :direct_link
      )
    end
  end

  def opaque_id(asset)
    if asset.respond_to?(:lti_context_id)
      Lti::Asset.global_context_id_for(asset)
    else
      Lti::Asset.context_id_for(asset)
    end
  end

  describe "GET 'visible_course_nav_tools'" do
    def add_tool(name, course)
      tool = course.context_external_tools.new(
        name:,
        consumer_key: "key1",
        shared_secret: "secret1"
      )
      tool.url = "http://www.example.com/basic_lti"
      tool.use_1_3 = true
      tool.developer_key = DeveloperKey.create!
      tool.save!
      tool
    end

    before :once do
      student_in_course(active_all: true)
      @course1 = @course
      course_with_teacher(active_all: true, user: @teacher)
      student_in_course(active_all: true, user: @student)
      @course2 = @course

      @tool1 = add_tool("Course nav tool 1", @course1)
      @tool1.course_navigation = { enabled: true }
      @tool1.save!
      @tool2 = add_tool("Course nav tool 2", @course1)
      @tool2.course_navigation = { enabled: true }
      @tool2.save!
      @tool3 = add_tool("Course nav tool 3", @course2)
      @tool3.course_navigation = { enabled: true }
      @tool3.save!
    end

    it "returns a 400 response if no context_codes are provided for the batch endpoint" do
      user_session(@teacher)
      get :all_visible_nav_tools, params: { course_id: @course1.id }

      message = json_parse(response.body)["message"]
      expect(response).to have_http_status :bad_request
      expect(message).to eq "Missing context_codes"
    end

    it "returns a 404 response if no context could be found for the single-context endpoint" do
      user_session(@teacher)
      get :visible_course_nav_tools, params: { course_id: "definitely_not_a_course" }

      expect(response).to have_http_status :not_found
    end

    it "returns a 400 response if any context_codes besides courses are provided" do
      user_session(@teacher)
      get :all_visible_nav_tools, params: { context_codes: ["account_#{@course.account.id}"] }

      message = json_parse(response.body)["message"]
      expect(response).to have_http_status :bad_request
      expect(message).to eq "Invalid context_codes; only `course` codes are supported"
    end

    it "returns an empty array if no courses are found or the courses found have no associated tools" do
      course_with_teacher(active_all: true)
      user_session(@teacher)

      get :all_visible_nav_tools, params: { context_codes: ["course_fake"] }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to be 0

      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course.id}"] }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to be 0
    end

    it "returns unauthorized if the user lacks read access to any of the supplied courses for the batch endpoint" do
      @course2.claim!
      user_session(@student)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"] }
      assert_unauthorized
    end

    it "returns unauthorized if the user lacks read access the context for the single-context endpoint" do
      @course2.claim!
      user_session(@student)
      get :visible_course_nav_tools, params: { course_id: @course2.id }
      assert_unauthorized
    end

    it "shows course nav tools to teacher" do
      user_session(@teacher)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"] }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to be 3
      expect(tools.pluck("name")).to eq ["Course nav tool 1", "Course nav tool 2", "Course nav tool 3"]
    end

    it "shows course nav tools for the single-context endpoint" do
      user_session(@teacher)
      get :visible_course_nav_tools, params: { course_id: @course1.id }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to be 2
      expect(tools.pluck("name")).to eq ["Course nav tool 1", "Course nav tool 2"]
    end

    it "shows course nav tools to student" do
      user_session(@student)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course1.id}", "course_#{@course2.id}"] }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to be 3
      expect(tools.pluck("name")).to eq ["Course nav tool 1", "Course nav tool 2", "Course nav tool 3"]
    end

    it "only returns tools with a course navigation placement" do
      @tool2.course_navigation = { enabled: false }
      @tool2.save!
      user_session(@teacher)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course1.id}"] }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to eq 1
      expect(tools.none? { |t| t["name"] == "Course nav tool 2" }).to be_truthy
    end

    it "doesn't return tools to student marked with admins visibility" do
      @tool3.course_navigation = { enabled: true, visibility: "admins" }
      @tool3.save!
      user_session(@teacher)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course2.id}"] }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to eq 1
      expect(tools.first["name"]).to eq "Course nav tool 3"

      user_session(@student)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course2.id}"] }
      expect(response).to be_successful
      tools = json_parse(response.body)
      expect(tools.count).to eq 0
    end

    it "returns tools in the order they are configured in the navigation settings" do
      saved_tabs = [
        { id: "context_external_tool_#{@tool2.id}" },
        { id: "context_external_tool_#{@tool1.id}" }
      ]
      @course1.tab_configuration = saved_tabs
      @course1.save!
      user_session(@teacher)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course1.id}"] }

      tools = json_parse(response.body)
      expect(tools.count).to eq 2
      expect(tools[0]["name"]).to eq "Course nav tool 2"
      expect(tools[1]["name"]).to eq "Course nav tool 1"
    end

    it "excludes hidden tools from response for students" do
      saved_tabs = [{ id: "context_external_tool_#{@tool3.id}", hidden: true }]
      @course2.tab_configuration = saved_tabs
      @course2.save!
      user_session(@student)
      get :all_visible_nav_tools, params: { context_codes: ["course_#{@course2.id}"] }

      tools = json_parse(response.body)
      expect(tools.count).to eq 0
    end
  end
end
