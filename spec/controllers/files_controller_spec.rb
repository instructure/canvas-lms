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

require_relative "../helpers/k5_common"
require "webmock/rspec"

def new_valid_tool(course)
  tool = course.context_external_tools.new(
    name: "bob",
    consumer_key: "bob",
    shared_secret: "bob",
    tool_id: "some_tool",
    privacy_level: "public"
  )
  tool.url = "http://www.example.com/basic_lti"
  tool.resource_selection = {
    url: "http://#{HostUrl.default_host}/selection_test",
    selection_width: 400,
    selection_height: 400
  }
  tool.save!
  tool
end

describe FilesController do
  include K5Common

  def course_folder
    @folder = @course.folders.create!(name: "a folder", workflow_state: "visible")
  end

  def io
    fixture_file_upload("docs/doc.doc", "application/msword", true)
  end

  def course_file
    @file = @course.attachments.create!(uploaded_data: io)
  end

  def user_file
    @file = @user.attachments.create!(uploaded_data: io)
  end

  def user_html_file
    @file = @user.attachments.create!(uploaded_data: fixture_file_upload("test.html", "text/html", false))
  end

  def account_js_file
    @file = @account.attachments.create!(uploaded_data: fixture_file_upload("test.js", "text/javascript", false))
  end

  def folder_file
    @file = @folder.active_file_attachments.build(uploaded_data: io)
    @file.context = @course
    @file.save!
    @file
  end

  def file_in_a_module
    @module = @course.context_modules.create!(name: "module")
    @tag = @module.add_item({ type: "attachment", id: @file.id })
    @module.reload
    hash = {}
    hash[@tag.id.to_s] = { type: "must_view" }
    @module.completion_requirements = hash
    @module.save!
  end

  def file_with_path(path)
    components = path.split("/")
    folder = nil
    while components.size > 1
      component = components.shift
      folder = @course.folders.where(name: component).first
      folder ||= @course.folders.create!(name: component, workflow_state: "visible", parent_folder: folder)
    end
    filename = components.shift
    @file = folder.active_file_attachments.build(filename:, uploaded_data: io)
    @file.context = @course
    @file.save!
    @file
  end

  before :once do
    @other_user = user_factory(active_all: true)
    course_with_teacher active_all: true
    student_in_course active_all: true
  end

  describe "GET 'quota'" do
    it "requires authorization" do
      get "quota", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "assigns variables for course quota" do
      user_session(@teacher)
      get "quota", params: { course_id: @course.id }
      expect(assigns[:quota]).not_to be_nil
      expect(response).to be_successful
    end

    it "assigns variables for user quota" do
      user_session(@student)
      get "quota", params: { user_id: @student.id }
      expect(assigns[:quota]).not_to be_nil
      expect(response).to be_successful
    end

    it "assigns variables for group quota" do
      user_session(@teacher)
      group_model(context: @course)
      get "quota", params: { group_id: @group.id }
      expect(assigns[:quota]).not_to be_nil
      expect(response).to be_successful
    end

    it "allows changing group quota" do
      user_session(@teacher)
      group_model(context: @course, storage_quota: 500.megabytes)
      get "quota", params: { group_id: @group.id }
      expect(assigns[:quota]).to eq 500.megabytes
      expect(response).to be_successful
    end
  end

  describe "GET 'index'" do
    def enable_limited_access_for_students
      @course.account.root_account.enable_feature!(:allow_limited_access_for_students)
      @course.account.settings[:enable_limited_access_for_students] = true
      @course.account.save!
    end

    it "requires authorization" do
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 11, "hidden" => true }])
      get "index", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "assigns variables" do
      user_session(@teacher)
      get "index", params: { course_id: @course.id }
      expect(response).to be_successful
      expect(assigns[:contexts]).not_to be_nil
      expect(assigns[:contexts][0]).to eql(@course)
    end

    it "works for a user context, too" do
      user_session(@student)
      get "index", params: { user_id: @student.id }
      expect(response).to be_successful
    end

    it "works for a group context, too" do
      group_with_user_logged_in(group_context: Account.default)
      get "index", params: { group_id: @group.id }
      expect(response).to be_successful
    end

    it "refuses for a non-html format" do
      group_with_user_logged_in(group_context: Account.default)
      get "index", params: { group_id: @group.id }, format: :js
      expect(response.body).to include("endpoint does not support js")
      expect(response.code.to_i).to eq(400)
    end

    it "does not show external tools in a group context" do
      group_with_user_logged_in(group_context: Account.default)
      new_valid_tool(@course)
      user_file
      @file.context = @group
      get "index", params: { group_id: @group.id }
      expect(assigns[:js_env][:FILES_CONTEXTS][0][:file_menu_tools]).to eq []
    end

    it "redirects to course homepage if context is course in limited access for students account" do
      enable_limited_access_for_students

      user_session(@student)
      get "index", params: { course_id: @course.id }
      expect(response).to redirect_to(course_path(@course))
    end

    it "renders unauthorized if context is a User enrolled as student in a limited access for students account" do
      enable_limited_access_for_students

      user_session(@student)
      get "index", params: { user_id: @student.id }
      expect(response.code.to_i).to be 401
    end

    it "renders unauthorized if context is a Group and user is student in a limited access for students account" do
      enable_limited_access_for_students

      category = group_category
      @group = category.groups.create(context: @course)

      user_session(@student)
      get "index", params: { group_id: @group.id }
      expect(response.code.to_i).to be 401
    end

    context "file menu tool visibility" do
      before do
        course_factory(active_all: true)
        @tool = @course.context_external_tools.create!(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
        @tool.file_menu = {
          visibility: "admins"
        }
        @tool.save!
      end

      before do
        user_factory(active_all: true)
        user_session(@user)
      end

      it "shows restricted external tools to teachers" do
        @course.enroll_teacher(@user).accept!

        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:FILES_CONTEXTS][0][:file_menu_tools].count).to eq 1
      end

      it "does not show restricted external tools to students" do
        course_file
        @course.enroll_student(@user).accept!

        get "index", params: { course_id: @course.id }
        expect(assigns[:js_env][:FILES_CONTEXTS][0][:file_menu_tools]).to eq []
      end
    end

    describe "across shards" do
      specs_require_sharding

      before :once do
        @shard2.activate do
          user_factory(active_all: true)
        end
      end

      before do
        user_session(@user)
      end

      it "authorizes users on a remote shard" do
        get "index", params: { user_id: @user.global_id }
        expect(response).to be_successful
      end
    end
  end

  describe "GET 'show'" do
    def enable_limited_access_for_students
      @course.account.root_account.enable_feature!(:allow_limited_access_for_students)
      @course.account.settings[:enable_limited_access_for_students] = true
      @course.account.save!
    end

    before :once do
      course_file
    end

    it "requires authorization" do
      get "show", params: { course_id: @course.id, id: @file.id }
      assert_unauthorized
    end

    it "respects user context" do
      skip("investigate cause for failures beginning 05/05/21 FOO-1950")
      user_session(@teacher)
      assert_page_not_found do
        get "show", params: { user_id: @user.id, id: @file.id }, format: "html"
      end
    end

    it "doesn't allow an assignment_id to bypass other auth checks" do
      assignment1 = @course.assignments.create!(name: "an assignment")

      attachment_model(context: @teacher, uploaded_data: stub_file_data("test.m4v", "asdf", "video/mp4"))

      user_session(@student)

      get "show", params: { id: @attachment.id }, format: :json
      expect(response).not_to be_ok

      get "show", params: { assignment_id: assignment1.id, id: @attachment.id }, format: :json
      expect(response).not_to be_ok
    end

    it "renders files with limited access flag" do
      enable_limited_access_for_students

      user_session(@student)
      get "show", params: { course_id: @course.id, id: @file.id }
      expect(response).to be_successful
    end

    describe "with verifiers" do
      it "allows public access with legacy verifier" do
        allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return "stubby"
        get "show", params: { course_id: @course.id, id: @file.id, verifier: @file.uuid }, format: "json"
        expect(response).to be_successful
        expect(json_parse["attachment"]).to_not be_nil
        expect(json_parse["attachment"]["canvadoc_session_url"]).to eq "stubby"
        expect(json_parse["attachment"]["md5"]).to be_nil
      end

      it "allows public access with new verifier" do
        verifier = Attachments::Verification.new(@file).verifier_for_user(nil)
        get "show", params: { course_id: @course.id, id: @file.id, verifier: }, format: "json"
        expect(response).to be_successful
        expect(json_parse["attachment"]).to_not be_nil
        expect(json_parse["attachment"]["md5"]).to be_nil
      end

      it "does not redirect to terms-acceptance page" do
        user_session(@teacher)
        session[:require_terms] = true
        verifier = Attachments::Verification.new(@file).verifier_for_user(@teacher)
        get "show", params: { course_id: @course.id, id: @file.id, verifier: }, format: "json"
        expect(response).to be_successful
      end

      it "emits an asset_accessed live event" do
        allow_any_instance_of(Attachment).to receive(:canvadoc_url).and_return "stubby"
        expect(Canvas::LiveEvents).to receive(:asset_access).with(@file, "files", nil, nil)
        get "show", params: { course_id: @course.id, id: @file.id, verifier: @file.uuid, download: 1 }, format: "json"
      end
    end

    describe "with an OAuth access token" do
      before do
        user_with_pseudonym
        pseudonym(@teacher)
        @access_token = AccessToken.create!(user: @teacher)
        @invalid_token = AccessToken.create!(user: @teacher, permanent_expires_at: 1.day.ago)
        @unauthorized_token = AccessToken.create!(user: @user)
      end

      context "with enable_file_access_with_api_tokens disabled" do
        before do
          Account.site_admin.disable_feature!(:enable_file_access_with_api_tokens)
        end

        it "does not allow access with a valid token" do
          request.headers["Authorization"] = "Bearer #{@access_token.full_token}"
          get "show", params: { course_id: @course.id, id: @file.id }
          expect(response).not_to be_successful
        end
      end

      it "allows access with a valid token" do
        request.headers["Authorization"] = "Bearer #{@access_token.full_token}"
        get "show", params: { course_id: @course.id, id: @file.id }, format: "json"
        expect(response).to be_successful
      end

      it "allows download with a valid token" do
        request.headers["Authorization"] = "Bearer #{@access_token.full_token}"
        get "show", params: { course_id: @course.id, id: @file.id, download: "1" }
        expect(response).to be_redirect
        expect(response.location).to include "/courses/#{@course.id}/files/#{@file.id}/course%20files"
      end

      it "denies access with an invalid token" do
        request.headers["Authorization"] = "Bearer #{@invalid_token.full_token}"
        get "show", params: { course_id: @course.id, id: @file.id }
        expect(response.status.to_i).to be > 399
      end

      it "denies access with a valid token for a user who does not have access" do
        request.headers["Authorization"] = "Bearer #{@unauthorized_token.full_token}"
        get "show", params: { course_id: @course.id, id: @file.id }
        expect(response.status.to_i).to be > 399
      end
    end

    describe "with JWT access token" do
      include_context "InstAccess setup"

      before do
        @file.update!(file_state: "hidden")
        user_with_pseudonym
        jwt_payload = {
          resource: "/courses/#{@course.id}/files/#{@file.id}?instfs_id=stuff",
          aud: [@course.root_account.uuid],
          sub: @user.uuid,
          tenant_auth: { location: "location" },
          iss: "instructure:inst_access",
          exp: 1.hour.from_now.to_i,
          iat: Time.now.to_i
        }
        @token_string = InstAccess::Token.send(:new, jwt_payload).to_unencrypted_token_string
        allow(Canvadocs).to receive(:enabled?).and_return(true)
        allow(InstFS).to receive_messages(enabled?: true, app_host: "http://instfs.test")
        stub_request(:get, "http://instfs.test/files/stuff/metadata").to_return(status: 200, body: { url: "http://instfs.test/stuff" }.to_json)
      end

      it "allows access" do
        get "show", params: { course_id: @course.id, id: @file.id, access_token: @token_string, instfs_id: "stuff" }, format: "json"
        expect(response).to be_successful
        expect(json_parse["attachment"]["canvadoc_session_url"]).to match %r{/api/v1/canvadoc_session.+?access_token=#{@token_string}}
      end

      it "allows access to files in deleted contexts" do
        @course.delete

        get "show", params: { course_id: @course.id, id: @file.id, access_token: @token_string, instfs_id: "stuff" }, format: "json"
        expect(response).to be_successful
        expect(json_parse["attachment"]["canvadoc_session_url"]).to match %r{/api/v1/canvadoc_session.+?access_token=#{@token_string}}
      end

      it "allows access to deleted files" do
        @file.destroy

        get "show", params: { course_id: @course.id, id: @file.id, access_token: @token_string, instfs_id: "stuff" }, format: "json"
        expect(response).to be_successful
        expect(json_parse["attachment"]["canvadoc_session_url"]).to match %r{/api/v1/canvadoc_session.+?access_token=#{@token_string}}
      end

      it "does not allow access if the resource in the token does not match the resource being accessed" do
        file2 = user_file

        get "show", params: { course_id: @course.id, id: file2.id, access_token: @token_string, instfs_id: "stuff" }, format: "json"
        expect(response).to be_not_found
      end

      it "does not allow access if InstFS doesn't return metadata for the tenant auth" do
        stub_request(:get, "http://instfs.test/files/stuff/metadata").to_return(status: 404, body: { error: "weird" }.to_json)

        get "show", params: { course_id: @course.id, id: @file.id, access_token: @token_string, instfs_id: "stuff" }, format: "json"
        expect(response).to be_forbidden
      end

      it "allows download" do
        get "show", params: { course_id: @course.id, id: @file.id, access_token: @token_string, instfs_id: "stuff", download: "1" }
        expect(response).to be_redirect
        expect(response.location).to include "/courses/#{@course.id}/files/#{@file.id}/course%20files"
        expect(response.location).to include "sf_verifier"

        sf_verifier = Addressable::URI.parse(response.location).query_values["sf_verifier"]
        claims = Canvas::Security.decode_jwt(sf_verifier)
        expect(claims["attachment_id"]).to eq @file.global_id.to_s
        expect(claims["permission"]).to eq "download"
      end
    end

    describe "access via location parameter" do
      def valid_download_response(response)
        expect(response.status).to equal(302)
        expect(response.headers["location"]).to include("download_frd")
      end

      def valid_denied_access_response(response)
        expect(response).to have_http_status(:forbidden).or have_http_status(:unauthorized)
      end

      context "for a deleted file" do
        before do
          @course.is_public = false
          @course.public_syllabus = true
          @course.save!

          course_file
          html = <<~HTML
            <p><a href="/courses/#{@course.id}/files/#{@file.id}/download">file 2</a></p>
          HTML
          @course.associate_attachments_to_rce_object(html, @teacher, context_concern: "syllabus_body")

          @file.destroy
        end

        let(:params_with_location) { { course_id: @course.id, id: @file.id, download: 1, location: "course_syllabus_#{@course.id}" } }

        context "with disable_file_verifiers_in_public_syllabus enabled" do
          before do
            @course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
          end

          it "denies access even with location" do
            user_session(@other_user)
            get "show", params: params_with_location, format: "json"
            valid_denied_access_response(response)
          end
        end
      end

      context "for a private user file attached to a public course syllabus" do
        before do
          @course.is_public = false
          @course.public_syllabus = true
          @course.save!

          user_session(@student)
          user_file

          html = <<~HTML
            <p><a href="/users/#{@student.id}/files/#{@file.id}/download">file 2</a></p>
          HTML
          @course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
          @course.associate_attachments_to_rce_object(html, @student, context_concern: "syllabus_body")
        end

        let(:params_with_location) { { user_id: @student.id, id: @file.id, download: 1, location: "course_syllabus_#{@course.id}" } }

        context "with disable_file_verifiers_in_public_syllabus enabled" do
          before do
            @course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
          end

          it "allows access for student/file owner" do
            user_session(@student)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "allows access for teacher/course owner" do
            user_session(@teacher)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "allows access for unassociated user" do
            user_session(@other_user)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "allows access for anonymous user" do
            remove_user_session
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end
        end

        context "with disable_file_verifiers_in_public_syllabus disabled" do
          before do
            @course.root_account.disable_feature!(:disable_file_verifiers_in_public_syllabus)
          end

          it "allows access for student/file owner" do
            user_session(@student)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "denies access for teacher/course owner" do
            user_session(@teacher)
            get "show", params: params_with_location, format: "json"
            valid_denied_access_response(response)
          end

          it "denies access for unassociated user" do
            user_session(@other_user)
            get "show", params: params_with_location, format: "json"
            valid_denied_access_response(response)
          end

          it "denies access for anonymous user" do
            remove_user_session
            get "show", params: params_with_location, format: "json"
            valid_denied_access_response(response)
          end
        end
      end

      context "for a course file attached to a public course syllabus" do
        before do
          @course.is_public = false
          @course.public_syllabus = true
          @course.save!

          course_file
          html = <<~HTML
            <p><a href="/courses/#{@course.id}/files/#{@file.id}/download">file 2</a></p>
          HTML

          @course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
          @course.associate_attachments_to_rce_object(html, @teacher, context_concern: "syllabus_body")
        end

        let(:params_with_location) { { course_id: @course.id, id: @file.id, download: 1, location: "course_syllabus_#{@course.id}" } }

        context "with disable_file_verifiers_in_public_syllabus enabled" do
          before do
            @course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
          end

          it "allows access for student/file owner" do
            user_session(@student)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "allows access for teacher/course owner" do
            user_session(@teacher)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "allows access for unassociated user" do
            user_session(@other_user)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "allows access for anonymous user" do
            remove_user_session
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          context "with sharding" do
            specs_require_sharding

            before do
              @shard1.activate do
                user_factory(active_all: true)
                @course.enroll_teacher(@user)
                attachment_model(context: @user, filename: "shard1.txt")
                html = <<~HTML
                  <p><a href="/courses/#{@course.id}/files/#{@attachment.id}/download">file 1</a>
                HTML
                @course.root_account.enable_feature!(:disable_file_verifiers_in_public_syllabus)
                @course.associate_attachments_to_rce_object(html, @user, context_concern: "syllabus_body")
              end
            end

            it "allows access to the file" do
              user_session(@student)
              get "show", params: { user_id: @user.global_id, id: @attachment.global_id, download: 1, location: "course_syllabus_#{@course.id}" }, format: "json"
              expect(response.headers["location"]).to include("download_frd")

              @shard1.activate do
                get "show", params: { user_id: @user.id, id: @attachment.id, download: 1, location: "course_syllabus_#{@course.global_id}" }, format: "json"
                expect(response.headers["location"]).to include("download_frd")
              end
            end
          end
        end

        context "with disable_file_verifiers_in_public_syllabus disabled" do
          before do
            @course.root_account.disable_feature!(:disable_file_verifiers_in_public_syllabus)
          end

          it "allows access for student/file owner" do
            user_session(@student)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "allows access for teacher/course owner" do
            user_session(@teacher)
            get "show", params: params_with_location, format: "json"
            valid_download_response(response)
          end

          it "denies access for unassociated user" do
            user_session(@other_user)
            get "show", params: params_with_location, format: "json"
            valid_denied_access_response(response)
          end

          it "denies access for anonymous user" do
            remove_user_session
            get "show", params: params_with_location, format: "json"
            valid_denied_access_response(response)
          end
        end
      end
    end

    describe "sets the X-Robots-Tag" do
      it "sets the X-Robots-Tag header to noindex, nofollow" do
        verifier = Attachments::Verification.new(@file).verifier_for_user(nil)
        get "show", params: { course_id: @course.id, id: @file.id, verifier: }, format: "json"
        expect(response).to be_successful
        expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
      end

      it "does not set the X-Robots-Tag header if the account allows indexing" do
        @course.root_account.settings[:enable_search_indexing] = true
        @course.root_account.save!
        verifier = Attachments::Verification.new(@file).verifier_for_user(nil)
        get "show", params: { course_id: @course.id, id: @file.id, verifier: }, format: "json"
        expect(response).to be_successful
        expect(response.headers["X-Robots-Tag"]).to be_nil
      end
    end

    it "assigns variables" do
      user_session(@teacher)
      get "show", params: { course_id: @course.id, id: @file.id }
      expect(response).to be_successful
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment]).to eql(@file)
    end

    it "redirects for download" do
      user_session(@teacher)
      # k5_mode hooks don't run because we never render
      expect(allow_any_instantiation_of(@course)).not_to receive(:elementary_subject_course?)
      get "show", params: { course_id: @course.id, id: @file.id, download: 1 }
      expect(response).to be_redirect
    end

    it "forces download when download_frd is set" do
      user_session(@teacher)
      # this call should happen inside of FilesController#send_attachment
      expect_any_instance_of(FilesController).to receive(:send_stored_file).with(@file, false)
      get "show", params: { course_id: @course.id, id: @file.id, download: 1, verifier: @file.uuid, download_frd: 1 }
    end

    it "remembers most recent valid sf_verifier in session" do
      user1 = user_factory(active_all: true)
      file1 = user_file
      verifier1 = Users::AccessVerifier.generate(user: user1)

      user2 = user_factory(active_all: true)
      file2 = user_file
      verifier2 = Users::AccessVerifier.generate(user: user2)

      # first verifier
      user_session(user1)
      get "show", params: verifier1.merge(id: file1.id)
      expect(response).to be_successful

      expect(session[:file_access_user_id]).to eq user1.global_id
      expect(session[:file_access_expiration]).not_to be_nil
      expect(session[:permissions_key]).not_to be_nil
      permissions_key = session[:permissions_key]

      # second verifier, should update session
      get "show", params: verifier2.merge(id: file2.id)
      expect(response).to be_successful

      expect(session[:file_access_user_id]).to eq user2.global_id
      expect(session[:file_access_expiration]).not_to be_nil
      expect(session[:permissions_key]).not_to eq permissions_key
      permissions_key = session[:permissions_key]

      # repeat access, even without verifier, should extend expiration (though
      # we can't assert that, because milliseconds) and thus change
      # permissions_key
      get "show", params: { id: file2.id }
      expect(response).to be_successful

      expect(session[:permissions_key]).not_to eq permissions_key
    end

    it "redirects without sf_verifier for inline_content files" do
      user = user_factory(active_all: true)
      file = user_html_file
      verifier = Users::AccessVerifier.generate(user:)

      get "show", params: verifier.merge(id: file.id)
      expect(response).to be_redirect

      expect(response.headers["Location"]).not_to include "sf_verifier=#{verifier}"
    end

    it "ignores invalid sf_verifiers" do
      user = user_factory(active_all: true)
      file = user_file
      verifier = Users::AccessVerifier.generate(user:)

      # first use to establish session
      get "show", params: verifier.merge(id: file.id)
      expect(response).to be_successful
      permissions_key = session[:permissions_key]

      # second use after verifier expiration but before session expiration.
      # expired verifier should be ignored but session should still be extended
      Timecop.freeze((Users::AccessVerifier::TTL_MINUTES + 1).minutes.from_now) do
        get "show", params: verifier.merge(id: file.id)
      end
      expect(response).to be_successful
      expect(session[:permissions_key]).not_to eq permissions_key
    end

    it "sets cache headers for non text files" do
      get "show", params: { course_id: @course.id, id: @file.id, download: 1, verifier: @file.uuid, download_frd: 1 }
      expect(response.header["Cache-Control"]).to include "private"
      expect(response.header["Cache-Control"]).to include "max-age=#{1.day.seconds}"
      expect(response.header["Cache-Control"]).not_to include "no-cache"
      expect(response.header["Cache-Control"]).not_to include "no-store"
      expect(response.header["Cache-Control"]).not_to include "must-revalidate"
      expect(response.header).to include("Expires")
      expect(response.header).not_to include("Pragma")
    end

    it "does not set cache headers for text files" do
      @file.content_type = "text/html"
      @file.save
      get "show", params: { course_id: @course.id, id: @file.id, download: 1, verifier: @file.uuid, download_frd: 1 }
      # rails will include private directive by default unless no-cache is provided
      expect(response.header["Cache-Control"]).to include "no-store"
      expect(response.header).not_to include("Expires")
      expect(response.header).to include("Pragma")
    end

    it "allows concluded teachers to read and download files" do
      user_session(@teacher)
      @enrollment.conclude
      get "show", params: { course_id: @course.id, id: @file.id }
      expect(response).to be_successful
      get "show", params: { course_id: @course.id, id: @file.id, download: 1 }
      expect(response).to be_redirect
    end

    context "when the attachment has been overwritten" do
      subject do
        get("show", params:)
        response
      end

      let(:old_file) do
        old = @course.attachments.build(display_name: "old file")
        old.file_state = "deleted"
        old.replacement_attachment = file
        old.save!
        old
      end

      let(:file) { @file }
      let(:params) { { course_id: @course.id, id: old_file.id, preview: 1 } }

      before { user_session(@teacher) }

      it "finds overwritten files" do
        expect(subject).to be_redirect
        expect(subject.location).to match(%r{/courses/#{@course.id}/files/#{file.id}})
      end

      context "and no context is given" do
        let(:params) { { id: old_file.id, preview: 1 } }

        it "does not find the file" do
          expect(subject).to be_not_found
        end

        context "but a replacement_chain_context is given" do
          let(:params) do
            {
              id: old_file.id,
              preview: 1,
              replacement_chain_context_type: "course",
              replacement_chain_context_id: @course.id
            }
          end

          it "find the new file" do
            expect(subject).to be_redirect

            location = URI.parse(subject.location)
            query = CGI.parse(location.query)

            expect(location.path).to eq "/files/#{file.id}/download"
            expect(query["download_frd"]).to eq ["1"]
            expect(query["sf_verifier"]).to be_present
          end
        end
      end
    end

    context "after user merge" do
      before :once do
        @merge_user_1 = student_in_course(name: "Merge User 1", active_all: true).user
        @merge_user_2 = student_in_course(name: "Merge User 2", active_all: true).user

        @user_1_file = attachment_model(context: @merge_user_1, md5: "hi")
      end

      before do
        user_session(@teacher)
      end

      it "finds file in merged-to user's context" do
        UserMerge.from(@merge_user_1).into(@merge_user_2)
        UserMerge.from(@merge_user_2).into(@student)
        run_jobs

        get "show", params: { user_id: @merge_user_1.id, id: @user_1_file.id, verifier: @user_1_file.uuid }
        expect(response).to be_successful
        expect(@user_1_file.reload.context_type).to eq "User"
        expect(@user_1_file.context_id).to eq @student.id
      end

      it "finds file in merged-from user's context when merged-to user already had the file" do
        @user_2_file = attachment_model(context: @merge_user_2, md5: "hi")

        UserMerge.from(@merge_user_1).into(@merge_user_2)
        UserMerge.from(@merge_user_2).into(@student)
        run_jobs

        get "show", params: { user_id: @merge_user_1.id, id: @user_1_file.id, verifier: @user_1_file.uuid }
        expect(response).to be_successful
        expect(@user_1_file.reload.context_type).to eq "User"
        expect(@user_1_file.context_id).to eq @merge_user_1.id
      end

      context "with sharding" do
        specs_require_sharding

        it "finds file in intermediate user's context if merge has happened cross-shard" do
          @shard1.activate do
            account = Account.create!
            course_with_student(account:)
          end
          UserMerge.from(@merge_user_1).into(@merge_user_2)
          UserMerge.from(@merge_user_2).into(@student)
          run_jobs

          get "show", params: { user_id: @merge_user_1.id, id: @user_1_file.id, verifier: @user_1_file.uuid }
          expect(response).to be_successful
          expect(@user_1_file.reload.context_type).to eq "User"
          expect(@user_1_file.context_id).to eq @merge_user_2.id
        end

        it "finds files correctly when given a non-native user ID" do
          @shard1.activate do
            account = Account.create!
            course_with_student(account:)
          end
          UserMerge.from(@merge_user_1).into(@merge_user_2)
          UserMerge.from(@merge_user_2).into(@student)
          run_jobs

          @shard1.activate do
            get "show", params: { user_id: @merge_user_1.id, id: @user_1_file.id, verifier: @user_1_file.uuid }
            expect(response).to be_successful
            expect(@user_1_file.reload.context_type).to eq "User"
            expect(@user_1_file.context_id).to eq @merge_user_2.id
          end
        end
      end
    end

    describe "as a student" do
      before do
        user_session(@student)
      end

      describe "with a module item ID" do
        let(:params) do
          {
            course_id: @course.id,
            id: @file.id,
            module_item_id: 1
          }
        end

        it "logs asset access for the attachment" do
          expect(controller).to receive(:log_asset_access).with(
            @file,
            "files",
            "files"
          )
          get "show", params:
        end
      end

      it "allows concluded students to read and download files" do
        @enrollment.conclude
        get "show", params: { course_id: @course.id, id: @file.id }
        expect(response).to be_successful
        get "show", params: { course_id: @course.id, id: @file.id, download: 1 }
        expect(response).to be_redirect
      end

      it "marks files as viewed for module progressions if the file is previewed inline" do
        file_in_a_module
        get "show", params: { course_id: @course.id, id: @file.id, inline: 1 }
        expect(json_parse).to eq({ "ok" => true })
        @module.reload
        expect(@module.evaluate_for(@student).state).to be(:completed)
      end

      it "marks files as viewed for module progressions if the file is downloaded" do
        file_in_a_module
        get "show", params: { course_id: @course.id, id: @file.id, download: 1 }
        @module.reload
        expect(@module.evaluate_for(@student).state).to be(:completed)
      end

      it "marks files as viewed for module progressions if the file data is requested and is canvadocable" do
        file_in_a_module
        allow_any_instance_of(Attachment).to receive(:canvadocable?).and_return true
        get "show", params: { course_id: @course.id, id: @file.id }, format: :json
        @module.reload
        expect(@module.evaluate_for(@student).state).to be(:completed)
      end

      it "marks media files viewed when rendering html with file_preview" do
        @file = attachment_model(context: @course, uploaded_data: stub_file_data("test.m4v", "asdf", "video/mp4"))
        file_in_a_module
        get "show", params: { course_id: @course.id, id: @file.id }, format: :html
        @module.reload
        expect(@module.evaluate_for(@student).state).to be(:completed)
      end

      it "marks previewable files as viewed when rendering html with file_preview" do
        odp = attachment_model(context: @course, uploaded_data: stub_file_data("test.odp", "asdf", "application/vnd.oasis.opendocument.presentation"))
        odt = attachment_model(context: @course, uploaded_data: stub_file_data("test.odt", "asdf", "application/vnd.oasis.opendocument.text"))
        docx = attachment_model(context: @course, uploaded_data: stub_file_data("test.docx", "asdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
        pptx = attachment_model(context: @course, uploaded_data: stub_file_data("test.pptx", "asdf", "application/vnd.openxmlformats-officedocument.presentationml.presentation"))
        pdf = attachment_model(context: @course, uploaded_data: stub_file_data("test.pdf", "asdf", "application/pdf"))
        rft = attachment_model(context: @course, uploaded_data: stub_file_data("test.rft", "asdf", "application/rtf"))
        [odp, odt, docx, pptx, pdf, rft].each do |file|
          @file = file
          file_in_a_module
          get "show", params: { course_id: @course.id, id: @file.id }, format: :html
          @module.reload
          expect(@module.evaluate_for(@student).state).to be(:completed)
        end
      end

      it "does not mark as viewed not previewable files" do
        @file = attachment_model(context: @course, uploaded_data: stub_file_data("test", "asdf", "application/unknown"))
        file_in_a_module
        get "show", params: { course_id: @course.id, id: @file.id }, format: :html
        @module.reload
        expect(@module.evaluate_for(@student).state).to be(:unlocked)
      end

      it "redirects to the user's files URL when browsing to an attachment with the same path as a deleted attachment" do
        owned_file = course_file
        owned_file.display_name = "holla"
        owned_file.user_id = @student.id
        owned_file.save
        owned_file.destroy
        get "show", params: { course_id: @course.id, id: owned_file.id }
        expect(response).to be_redirect
        expect(flash[:notice]).to match(/has been deleted/)
        expect(URI.parse(response["Location"]).path).to eq "/courses/#{@course.id}/files"
      end

      it "displays a new file without incident" do
        new_file = course_file
        new_file.display_name = "holla"
        new_file.save

        get "show", params: { course_id: @course.id, id: new_file.id }
        expect(response).to be_successful
        expect(assigns(:attachment)).to eq new_file
      end

      it "does not leak the name of unowned deleted files" do
        unowned_file = @file
        unowned_file.display_name = "holla"
        unowned_file.save
        unowned_file.destroy

        get "show", params: { course_id: @course.id, id: unowned_file.id }
        expect(response).to have_http_status(:not_found)
        expect(assigns(:not_found_message)).to eq("This file has been deleted")
      end

      it "does not blow up for logged out users" do
        unowned_file = @file
        unowned_file.display_name = "holla"
        unowned_file.save
        unowned_file.destroy

        remove_user_session
        get "show", params: { course_id: @course.id, id: unowned_file.id }
        expect(response).to have_http_status(:not_found)
        expect(assigns(:not_found_message)).to eq("This file has been deleted")
      end

      it "views file when student's submission was deleted" do
        @assignment = @course.assignments.create!(title: "upload_assignment", submission_types: "online_upload")
        attachment_model context: @student
        @assignment.submit_homework @student, attachments: [@attachment]
        # create an orphaned attachment_association
        @assignment.all_submissions.delete_all
        get "show", params: { user_id: @student.id, id: @attachment.id, download_frd: 1 }
        expect(response).to be_successful
      end

      it "hides the left side if in K5 mode" do
        toggle_k5_setting(@course.account)
        expect(controller).to receive(:set_k5_mode).and_call_original
        get "show", params: { course_id: @course.id, id: @file.id }
        expect(response).to be_successful
        expect(assigns[:show_left_side]).to be false
      end
    end

    describe "as a teacher" do
      before do
        user_session @teacher
      end

      it "works for quiz_statistics" do
        quiz_model
        file = @quiz.statistics_csv("student_analysis").csv_attachment
        get "show", params: { quiz_statistics_id: file.reload.context.id,
                              file_id: file.id,
                              download: "1",
                              verifier: file.uuid }
        expect(response).to be_redirect
      end

      it "records the inline view when a teacher previews a student's submission" do
        @assignment = @course.assignments.create!(title: "upload_assignment", submission_types: "online_upload")
        attachment_model context: @student
        @assignment.submit_homework @student, attachments: [@attachment]
        get "show", params: { user_id: @student.id, id: @attachment.id, inline: 1 }
        expect(response).to be_successful
      end

      it "is successful when viewing as an admin even if locked" do
        @file.locked = true
        @file.save!
        get "show", params: { course_id: @course.id, id: @file.id }
        expect(response).to be_successful
      end

      describe "with a module item ID" do
        let(:params) do
          {
            course_id: @course.id,
            id: @file.id,
            module_item_id: 1
          }
        end

        it "logs asset access for the attachment" do
          expect(controller).to receive(:log_asset_access).with(
            @file,
            "files",
            "files"
          )
          get "show", params:
        end
      end
    end

    describe "canvadoc_session_url" do
      before do
        user_session(@student)
        allow(Canvadocs).to receive(:enabled?).and_return true
        @file = canvadocable_attachment_model
      end

      it "is included if :download is allowed" do
        get "show", params: { course_id: @course.id, id: @file.id }, format: "json"
        expect(json_parse["attachment"]["canvadoc_session_url"]).to be_present
      end

      it "is not included if locked" do
        @file.lock_at = 1.month.ago
        @file.save!
        get "show", params: { course_id: @course.id, id: @file.id }, format: "json"
        expect(json_parse["attachment"]["canvadoc_session_url"]).to be_nil
      end

      it "is included in newly uploaded files" do
        user_session(@teacher)

        attachment = Attachment.create!(context: @course, file_state: "deleted", filename: "doc.doc")
        attachment.uploaded_data = io
        attachment.save!

        get "api_create_success", params: { id: attachment.id, uuid: attachment.uuid }, format: "json"
        expect(json_parse["canvadoc_session_url"]).to be_present
      end
    end
  end

  describe "GET 'api_create_success'" do
    before do
      category = group_category
      @group = category.groups.create(context: @course)
      @group.add_user(@student)
      user_session(@student)
    end

    it "treats attachments that live in the special 'submissions' folder as quota exempt" do
      attachment = Attachment.create!(
        context: @group,
        uploaded_data: StringIO.new("my file"),
        folder: @group.submissions_folder,
        filename: "my-great-file.txt",
        file_state: "deleted"
      )
      attachment.update_attribute(:size, 51.megabytes)
      get "api_create_success", params: { id: attachment.id, uuid: attachment.uuid }, format: "json"
      expect(response).to be_successful
    end

    it "does not give quota exemption to files not in the special 'submissions' folder" do
      attachment = Attachment.create!(
        context: @group,
        uploaded_data: StringIO.new("my file"),
        filename: "my-great-file.txt",
        file_state: "deleted"
      )
      attachment.update_attribute(:size, 51.megabytes)
      get "api_create_success", params: { id: attachment.id, uuid: attachment.uuid }, format: "json"
      expect(json_parse.fetch("message")).to eq "file size exceeds quota limits"
    end
  end

  describe "GET 'show_relative'" do
    before(:once) do
      course_file
      file_in_a_module
    end

    context "as student" do
      before do
        user_session(@student)
      end

      it "finds files by relative path" do
        get "show_relative", params: { course_id: @course.id, file_path: @file.full_display_path }
        expect(response).to be_redirect
        get "show_relative", params: { course_id: @course.id, file_path: @file.full_path }
        expect(response).to be_redirect

        def test_path(path)
          file_with_path(path)
          get "show_relative", params: { course_id: @course.id, file_path: @file.full_display_path }
          expect(response).to be_redirect
          get "show_relative", params: { course_id: @course.id, file_path: @file.full_path }
          expect(response).to be_redirect
        end

        test_path("course files/unfiled/test1.txt")
        test_path("course files/blah")
        test_path("course files/a/b/c%20dude/d/e/f.gif")
      end

      it "renders unauthorized access page if the file path doesn't match" do
        get "show_relative", params: { course_id: @course.id, file_path: @file.full_display_path + "blah" }
        expect(response).to render_template("shared/errors/file_not_found")
        get "show_relative", params: { file_id: @file.id, course_id: @course.id, file_path: @file.full_display_path + "blah" }
        expect(response).to render_template("shared/errors/file_not_found")
      end

      it "renders file_not_found even if the format is non-html" do
        get "show_relative", params: { file_id: @file.id, course_id: @course.id, file_path: @file.full_display_path + ".css" }, format: "css"
        expect(response).to render_template("shared/errors/file_not_found")
      end

      it "ignores bad file_ids" do
        get "show_relative", params: { file_id: @file.id + 1, course_id: @course.id, file_path: @file.full_display_path }
        expect(response).to be_redirect
        get "show_relative", params: { file_id: "blah", course_id: @course.id, file_path: @file.full_display_path }
        expect(response).to be_redirect
      end

      it "renders inline for html files" do
        s3_storage!
        allow(HostUrl).to receive(:file_host).and_return("files.test")
        request.host = "files.test"
        @file.update_attribute(:content_type, "text/html")
        handle = double(read: "hello")
        allow_any_instantiation_of(@file).to receive(:open).and_return(handle)
        get "show_relative", params: { file_id: @file.id, course_id: @course.id, file_path: @file.full_display_path, inline: 1, download: 1 }
        expect(response).to be_successful
        expect(response.body).to eq "hello"
        expect(response.media_type).to eq "text/html"
      end

      it "redirects for large html files" do
        s3_storage!
        allow(HostUrl).to receive(:file_host).and_return("files.test")
        request.host = "files.test"
        @file.update_attribute(:content_type, "text/html")
        @file.update_attribute(:size, 1024 * 1024)
        allow_any_instance_of(FileAuthenticator).to receive(:inline_url).and_return("https://s3/myfile")
        get "show_relative", params: { file_id: @file.id, course_id: @course.id, file_path: @file.full_display_path, inline: 1, download: 1 }
        expect(response).to redirect_to("https://s3/myfile")
      end

      it "redirects for image files" do
        s3_storage!
        allow(HostUrl).to receive(:file_host).and_return("files.test")
        request.host = "files.test"
        @file.update_attribute(:content_type, "image/jpeg")
        allow_any_instance_of(FileAuthenticator).to receive(:inline_url).and_return("https://s3/myfile")
        get "show_relative", params: { file_id: @file.id, course_id: @course.id, file_path: @file.full_display_path, inline: 1, download: 1 }
        expect(response).to redirect_to("https://s3/myfile")
      end

      it "redirects for non-html files" do
        s3_storage!
        allow(HostUrl).to receive(:file_host).and_return("files.test")
        request.host = "files.test"
        # it's a .doc file
        allow_any_instance_of(FileAuthenticator).to receive(:download_url).and_return("https://s3/myfile")
        get "show_relative", params: { file_id: @file.id, course_id: @course.id, file_path: @file.full_display_path, inline: 1, download: 1 }
        expect(response).to redirect_to("https://s3/myfile")
      end

      it "prioritizes matches on display name vs. filename" do
        display_name = "file.txt"
        # make a file with an original filename matching the other file's display_name
        Attachment.create!(context: @course,
                           uploaded_data: StringIO.new("blah1"),
                           folder: Folder.root_folders(@course).first,
                           filename: display_name,
                           display_name: "something_else.txt")
        file2 = Attachment.create!(context: @course,
                                   uploaded_data: StringIO.new("blah2"),
                                   folder: Folder.root_folders(@course).first,
                                   filename: "still_something_else.txt",
                                   display_name:)
        other_file = Attachment.create!(context: @course,
                                        uploaded_data: StringIO.new("blah3"),
                                        folder: Folder.root_folders(@course).first,
                                        filename: "totallydifferent.html")

        get "show_relative", params: { file_id: other_file.id, course_id: @course.id, file_path: file2.full_display_path }
        expect(assigns[:attachment]).to eq file2
      end
    end

    context "unauthenticated user" do
      it "renders unauthorized if the file exists" do
        get "show_relative", params: { course_id: @course.id, file_path: @file.full_display_path }
        assert_unauthorized
      end

      it "renders unauthorized if the file doesn't exist" do
        get "show_relative", params: { course_id: @course.id, file_path: "course files/nope" }
        assert_unauthorized
      end
    end

    context "after user merge" do
      before :once do
        @merge_user_1 = student_in_course(name: "Merge User 1", active_all: true).user
        @user_1_file = attachment_model(context: @merge_user_1, md5: "hi")
      end

      before do
        user_session(@teacher)
      end

      context "with sharding" do
        specs_require_sharding

        it "allows access to files from a user who was merged into another user (happens with cross-shard merge)" do
          @shard1.activate do
            account = Account.create!
            course_with_student(account:)
          end
          UserMerge.from(@merge_user_1).into(@student)
          run_jobs

          get "show_relative", params: { user_id: @merge_user_1.id, file_id: @user_1_file.id, file_path: @user_1_file.full_path, verifier: @user_1_file.uuid }
          expect(response).to be_redirect
        end
      end
    end

    context "account-context files" do
      before :once do
        @account = account_model
      end

      before do
        allow(HostUrl).to receive(:file_host).and_return("files.test")
        request.host = "files.test"
        user_session(@teacher)
      end

      it "skips verification for an account-context file" do
        account_js_file
        file_verifier = Attachments::Verification.new(@file).verifier_for_user(nil)
        user_verifier = Users::AccessVerifier.generate(user: @teacher)
        other_params = { download: 1, inline: 1, verifier: file_verifier, account_id: @account.id, file_id: @file.id, file_path: @file.full_path }
        get "show_relative", params: user_verifier.merge(other_params)
        expect(response).to be_redirect
        get "show_relative", params: other_params
        expect(response).to be_successful
      end

      it "enforces verification for contexts other than account" do
        course_file
        file_verifier = Attachments::Verification.new(@file).verifier_for_user(nil)
        user_verifier = Users::AccessVerifier.generate(user: @teacher)
        other_params = { download: 1, inline: 1, verifier: file_verifier, account_id: @account.id, file_id: @file.id, file_path: @file.full_path }
        get "show_relative", params: user_verifier.merge(other_params)
        assert_unauthorized
      end
    end

    describe "with the sf_verifier" do
      before do
        @file.update!(file_state: "hidden", instfs_uuid: "stuff")
        user_with_pseudonym
        allow(InstFS).to receive(:enabled?).and_return(true)
        allow_any_instance_of(FilesController).to receive(:safer_domain_available?).and_return(false)
      end

      it "does not allow access if the user can't see the file" do
        sf_verifier = Users::AccessVerifier.generate(
          user: @user,
          real_user: @user,
          root_account: Account.last,
          return_url: nil,
          fallback_url: "http://test.host/fallback"
        )

        get "show_relative", params: { course_id: @course.id, file_id: @file.id, file_path: @file.full_display_path, **sf_verifier }
        expect(response).to be_unauthorized
      end

      it "allows access if the sf_verifier includes the file authorization information" do
        sf_verifier = Users::AccessVerifier.generate(
          authorization: { attachment: @file, permission: "download" },
          user: @user,
          real_user: @user,
          root_account: Account.last,
          return_url: nil,
          fallback_url: "http://test.host/fallback"
        )

        get "show_relative", params: { course_id: @course.id, file_id: @file.id, file_path: @file.full_display_path, **sf_verifier }
        expect(response).to be_redirect
        expect(response.location).to include "/files/stuff/doc.doc?download=1&token="
      end
    end
  end

  describe "PUT 'update'" do
    before :once do
      course_file
    end

    it "requires authorization" do
      put "update", params: { course_id: @course.id, id: @file.id }
      assert_unauthorized
    end

    it "updates file" do
      user_session(@teacher)
      put "update", params: { course_id: @course.id, id: @file.id, attachment: { display_name: "new name", uploaded_data: nil } }
      expect(response).to be_redirect
      expect(assigns[:attachment]).to eql(@file)
      expect(assigns[:attachment].display_name).to eql("new name")
      expect(assigns[:attachment].user_id).to be_nil
    end

    it "moves file into a folder" do
      user_session(@teacher)
      course_folder

      put "update", params: { course_id: @course.id, id: @file.id, attachment: { folder_id: @folder.id } }, format: "json"
      expect(response).to be_successful

      @file.reload
      expect(@file.folder).to eql(@folder)
    end

    context "submissions folder" do
      before(:once) do
        @student = user_model
        @root_folder = Folder.root_folders(@student).first
        @file = attachment_model(context: @user, uploaded_data: default_uploaded_data, folder: @root_folder)
        @sub_folder = @student.submissions_folder
        @sub_file = attachment_model(context: @user, uploaded_data: default_uploaded_data, folder: @sub_folder)
      end

      it "does not move a file into a submissions folder" do
        user_session(@student)
        put "update", params: { user_id: @student.id, id: @file.id, attachment: { folder_id: @sub_folder.id } }, format: "json"
        expect(response).to have_http_status :forbidden
      end

      it "does not move a file out of a submissions folder" do
        user_session(@student)
        put "update", params: { user_id: @student.id, id: @sub_file.id, attachment: { folder_id: @root_folder.id } }, format: "json"
        expect(response).to have_http_status :forbidden
      end
    end

    it "replaces content and update user_id" do
      course_with_teacher_logged_in(active_all: true)
      course_file
      new_content = default_uploaded_data
      put "update", params: { course_id: @course.id, id: @file.id, attachment: { uploaded_data: new_content } }
      expect(response).to be_redirect
      expect(assigns[:attachment]).to eql(@file)
      @file.reload
      expect(@file.size).to eql new_content.size
      expect(@file.user).to eql @teacher
    end

    context "usage_rights_required" do
      before do
        @course.usage_rights_required = true
        @course.save!
        user_session(@teacher)
        @file.update_attribute(:locked, true)
      end

      it "does not publish if usage_rights unset" do
        put "update", params: { course_id: @course.id, id: @file.id, attachment: { locked: "false" } }
        expect(@file.reload).to be_locked
      end

      it "publishes if usage_rights set" do
        @file.usage_rights = @course.usage_rights.create! use_justification: "public_domain"
        @file.save!
        put "update", params: { course_id: @course.id, id: @file.id, attachment: { locked: "false" } }
        expect(@file.reload).not_to be_locked
      end
    end
  end

  describe "DELETE 'destroy'" do
    context "authorization" do
      before :once do
        course_file
      end

      it "requires authorization" do
        delete "destroy", params: { course_id: @course.id, id: @file.id }
        expect(response.body).to eql("{\"message\":\"Unauthorized to delete this file\"}")
        expect(assigns[:attachment].file_state).to eq "available"
      end

      it "deletes file" do
        user_session(@teacher)
        delete "destroy", params: { course_id: @course.id, id: @file.id }
        expect(response).to be_redirect
        expect(assigns[:attachment]).to eql(@file)
        expect(assigns[:attachment].file_state).to eq "deleted"
      end
    end

    it "refuses to delete a file in a submissions folder" do
      file = @student.attachments.create! display_name: "blah", uploaded_data: default_uploaded_data, folder: @student.submissions_folder
      delete "destroy", params: { user_id: @student.id, id: file.id }
      expect(response).to have_http_status :unauthorized
    end

    context "file that has been submitted" do
      def submit_file
        assignment = @course.assignments.create!(title: "some assignment", submission_types: "online_upload")
        @file = attachment_model(context: @user, uploaded_data: stub_file_data("test.txt", "asdf", "text/plain"))
        assignment.submit_homework(@student, attachments: [@file])
      end

      before do
        submit_file
        user_session(@student)
      end

      it "does not delete" do
        delete "destroy", params: { id: @file.id }
        expect(response.body).to eql("{\"message\":\"Cannot delete a file that has been submitted as part of an assignment\"}")
        expect(assigns[:attachment].file_state).to eq "available"
      end
    end
  end

  describe "POST 'create_pending'" do
    it "requires authorization" do
      user_session(@other_user)
      post "create_pending", params: { attachment: { context_code: @course.asset_string } }
      assert_unauthorized
    end

    it "requires a pseudonym" do
      post "create_pending", params: { attachment: { context_code: @course.asset_string } }
      expect(response).to redirect_to login_url
    end

    it "creates file placeholder (in local mode)" do
      local_storage!
      user_session(@teacher)
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        filename: "bob.txt"
      } }
      expect(response).to be_successful
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].id).not_to be_nil
      expect(assigns[:attachment][:user_id]).not_to be_nil
      json = json_parse
      expect(json).not_to be_nil
      expect(json["upload_url"]).not_to be_nil
      expect(json["upload_params"]).not_to be_nil
      expect(json["upload_params"]).not_to be_empty
    end

    it "creates file placeholder (in s3 mode)" do
      s3_storage!
      user_session(@teacher)
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        filename: "bob.txt"
      } }
      expect(response).to be_successful
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].id).not_to be_nil
      expect(assigns[:attachment][:user_id]).not_to be_nil
      json = json_parse
      expect(json).not_to be_nil
      expect(json["upload_url"]).not_to be_nil
      expect(json["upload_params"]).to be_present
      expect(json["upload_params"]["x-amz-credential"]).to start_with("stub_id")
    end

    it "allows specifying a content_type" do
      # the API does, and the files page sends it based on the browser's detection
      s3_storage!
      user_session(@teacher)
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        filename: "something.rb",
        content_type: "text/magical-incantation"
      } }
      expect(response).to be_successful
      expect(assigns[:attachment].content_type).to eq "text/magical-incantation"
    end

    it "does not allow going over quota for file uploads" do
      s3_storage!
      user_session(@student)
      Setting.set("user_default_quota", -1)
      post "create_pending", params: { attachment: {
        context_code: @student.asset_string,
        filename: "bob.txt",
        size: 1
      } }
      expect(response).to be_bad_request
      expect(assigns[:quota_used]).to be > assigns[:quota]
    end

    it "allows going over quota for homework submissions" do
      s3_storage!
      user_session(@student)
      @assignment = @course.assignments.create!(title: "upload_assignment", submission_types: "online_upload")
      Setting.set("user_default_quota", -1)
      post "create_pending", params: { attachment: {
                                         context_code: @assignment.context_code,
                                         asset_string: @assignment.asset_string,
                                         intent: "submit",
                                         filename: "bob.txt"
                                       },
                                       format: :json }
      expect(response).to be_successful
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].id).not_to be_nil
      json = json_parse
      expect(json).not_to be_nil
      expect(json["upload_url"]).not_to be_nil
      expect(json["upload_params"]).to be_present
      expect(json["upload_params"]["x-amz-credential"]).to start_with("stub_id")
    end

    # This test verifies that an attachment on a graded discussion will not affect the files quota
    it "allows going over quota for graded discussions submissions" do
      s3_storage!
      user_session(@student)
      @assignment = @course.assignments.create!(title: "discussion assignment", submission_types: "discussion_topic")
      Setting.set("user_default_quota", -1)
      post "create_pending", params: { attachment: {
                                         context_code: @assignment.context_code,
                                         asset_string: @assignment.asset_string,
                                         intent: "submit",
                                         filename: "bob.txt"
                                       },
                                       format: :json }
      expect(response).to be_successful
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].id).not_to be_nil
      json = json_parse
      expect(json).not_to be_nil
      expect(json["upload_url"]).not_to be_nil
      expect(json["upload_params"]).to be_present
      expect(json["upload_params"]["x-amz-credential"]).to start_with("stub_id")
    end

    it "associates assignment submission for a group assignment with the group" do
      user_session(@student)
      category = group_category
      assignment = @course.assignments.create(group_category: category, submission_types: "online_upload")
      group = category.groups.create(context: @course)
      group.add_user(@student)
      user_session(@student)

      # assignment.grants_right?(@student, :submit).should be_true
      # assignment.grants_right?(@student, :nothing).should be_true

      s3_storage!
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        asset_string: assignment.asset_string,
        intent: "submit",
        filename: "bob.txt"
      } }
      expect(response).to be_successful

      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].context).to eq group
    end

    it "creates the file in unlocked state if :usage_rights_required is disabled" do
      @course.usage_rights_required = false
      @course.save!
      user_session(@teacher)
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        filename: "bob.txt"
      } }
      expect(response).to be_successful
      expect(assigns[:attachment].locked).to be_falsy
    end

    it "creates the file in locked state if :usage_rights_required is enabled" do
      @course.usage_rights_required = true
      @course.save!
      user_session(@teacher)
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        filename: "bob.txt"
      } }
      expect(response).to be_successful
      expect(assigns[:attachment].locked).to be_truthy
    end

    it "refuses to create a file in a submissions folder" do
      user_session(@student)
      post "create_pending", params: { attachment: {
        context_code: @student.asset_string,
        filename: "test.txt",
        folder_id: @student.submissions_folder.id
      } }
      expect(response).to have_http_status :unauthorized
    end

    it "creates a file in the submissions folder if intent=='submit'" do
      user_session(@student)
      assignment = @course.assignments.create!(submission_types: "online_upload")
      post "create_pending", params: { attachment: {
        context_code: assignment.context_code,
        asset_string: assignment.asset_string,
        filename: "test.txt",
        intent: "submit"
      } }
      f = assigns[:attachment].folder
      expect(f.submission_context_code).to eq @course.asset_string
    end

    it "uses a submissions folder for group assignments" do
      user_session(@student)
      category = group_category
      assignment = @course.assignments.create(group_category: category, submission_types: "online_upload")
      group = category.groups.create(context: @course)
      group.add_user(@student)
      user_session(@student)
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        asset_string: assignment.asset_string,
        intent: "submit",
        filename: "bob.txt"
      } }
      expect(response).to be_successful
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment].context).to eq group
      expect(assigns[:attachment].folder).to be_for_submissions
    end

    it "does not require usage rights for group submissions to be visible to students" do
      @course.usage_rights_required = true
      @course.save!
      user_session(@student)
      category = group_category
      assignment = @course.assignments.create(group_category: category, submission_types: "online_upload")
      group = category.groups.create(context: @course)
      group.add_user(@student)
      user_session(@student)
      post "create_pending", params: { attachment: {
        context_code: @course.asset_string,
        asset_string: assignment.asset_string,
        intent: "submit",
        filename: "bob.txt"
      } }
      expect(response).to be_successful
      expect(assigns[:attachment]).not_to be_nil
      expect(assigns[:attachment]).not_to be_locked
    end

    context "sharding" do
      specs_require_sharding

      it "creates the attachment on the context's shard" do
        local_storage!
        @shard1.activate do
          account = Account.create!
          course_with_teacher_logged_in(active_all: true, account:)
        end
        post "create_pending", params: { attachment: {
          context_code: @course.asset_string,
          filename: "bob.txt"
        } }
        expect(response).to be_successful
        expect(assigns[:attachment]).not_to be_nil
        expect(assigns[:attachment].id).not_to be_nil
        expect(assigns[:attachment].shard).to eq @shard1
        json = json_parse
        expect(json).not_to be_nil
        expect(json["upload_url"]).not_to be_nil
        expect(json["upload_params"]).not_to be_nil
        expect(json["upload_params"]).not_to be_empty
      end

      it "creates the attachment on the user's shard when submitting" do
        local_storage!
        account = Account.create!
        @shard1.activate do
          @student = user_factory(active_user: true)
        end
        course_factory(active_all: true, account:)
        @course.enroll_user(@student, "StudentEnrollment").accept!
        @assignment = @course.assignments.create!(title: "upload_assignment", submission_types: "online_upload")

        user_session(@student)
        post "create_pending", params: { attachment: {
          context_code: @course.asset_string,
          asset_string: @assignment.asset_string,
          intent: "submit",
          filename: "bob.txt"
        } }
        expect(response).to be_successful
        expect(assigns[:attachment]).not_to be_nil
        expect(assigns[:attachment].id).not_to be_nil
        expect(assigns[:attachment].shard).to eq @shard1
        json = json_parse
        expect(json).not_to be_nil
        expect(json["upload_url"]).not_to be_nil
        expect(json["upload_params"]).not_to be_nil
        expect(json["upload_params"]).not_to be_empty
      end
    end
  end

  describe "POST 'api_create'" do
    before :once do
      # this endpoint does not need a logged-in user or api token auth, it's
      # based completely on the policy signature
      pseudonym(@teacher)
      @attachment = Attachment.create!(context: @course,
                                       file_state: "deleted",
                                       workflow_state: "unattached",
                                       filename: "test.txt",
                                       content_type: "text")
    end

    before do
      @content = Rack::Test::UploadedFile.new(file_fixture("a_file.txt"), "")
      request.env["CONTENT_TYPE"] = "multipart/form-data"
      enable_forgery_protection
    end

    it "accepts the upload data if the policy and attachment are acceptable" do
      local_storage!
      params = @attachment.ajax_upload_params("", "")
      post "api_create", params: params[:upload_params].merge(file: @content)
      expect(response).to be_redirect
      @attachment.reload
      # the file is not available until the third api call is completed
      expect(@attachment.file_state).to eq "deleted"
      expect(@attachment.open.read).to eq file_fixture("a_file.txt").read
    end

    it "opens up cors headers" do
      params = @attachment.ajax_upload_params("", "")
      request.headers["Origin"] = "http://canvas.docker"
      post "api_create", params: params[:upload_params].merge(file: @content)
      expect(response.header["Access-Control-Allow-Origin"]).to eq "http://canvas.docker"
    end

    it "has a preflight point for options requests (mostly safari)" do
      process :api_create_success_cors, method: "OPTIONS", params: { id: "" }
      expect(response.header["Access-Control-Allow-Headers"]).to eq("Origin, X-Requested-With, Content-Type, Accept, Authorization, Accept-Encoding")
    end

    it "rejects a blank policy" do
      post "api_create", params: { file: @content }
      assert_status(400)
    end

    it "rejects an empty file" do
      empty_file = Rack::Test::UploadedFile.new(file_fixture("empty_file.txt"), "")
      params = @attachment.ajax_upload_params("", "")
      post "api_create", params: params[:upload_params].merge(file: empty_file)
      assert_status(400)
    end

    it "rejects an expired policy" do
      params = @attachment.ajax_upload_params("", "", expiration: -60.seconds)
      post "api_create", params: params[:upload_params].merge({ file: @content })
      assert_status(400)
    end

    it "rejects a modified policy" do
      params = @attachment.ajax_upload_params("", "")
      params[:upload_params]["Policy"] << "a"
      post "api_create", params: params[:upload_params].merge({ file: @content })
      assert_status(400)
    end

    it "rejects a good policy if the attachment data is already uploaded" do
      params = @attachment.ajax_upload_params("", "")
      @attachment.uploaded_data = @content
      @attachment.save!
      post "api_create", params: params[:upload_params].merge(file: @content)
      assert_status(400)
    end

    it "forwards params[:success_include] to the api_create_success redirect as params[:include] if present" do
      local_storage!
      params = @attachment.ajax_upload_params("", "")
      post "api_create", params: params[:upload_params].merge(file: @content, success_include: "foo")
      expect(response).to be_redirect
      expect(response.location).to include("include%5B%5D=foo") # include[]=foo, url encoded
    end

    it "adds 'include=avatar' to the api_create_success redirect for profile pictures" do
      profile_pic = Attachment.create!(user: @teacher,
                                       context: @teacher,
                                       folder: @teacher.profile_pics_folder,
                                       file_state: "deleted",
                                       workflow_state: "unattached",
                                       filename: "profile.png",
                                       content_type: "image/png")

      local_storage!
      params = profile_pic.ajax_upload_params("", "")
      post "api_create", params: params[:upload_params].merge(file: @content)
      expect(response).to be_redirect
      expect(response.location).to include("include%5B%5D=avatar") # include[]=avatar, url encoded
    end
  end

  describe "POST api_capture" do
    before do
      allow(InstFS).to receive_messages(enabled?: true, jwt_secrets: ["jwt signing key"])
      @token = Canvas::Security.create_jwt({}, nil, InstFS.jwt_secret)
    end

    it "rejects if InstFS integration is disabled" do
      allow(InstFS).to receive(:enabled?).and_return(false)
      post "api_capture", params: { id: 1 }
      assert_status(404)
    end

    it "rejects if JWT is excluded or improperly formed" do
      wrong_token = Canvas::Security.create_jwt({}, nil, "the wrong key")
      post "api_capture", params: { id: 1, token: wrong_token }
      assert_forbidden
    end

    it "rejects if required params aren't included" do
      post "api_capture", params: { id: 1, user_id: 1, context_type: "Course", token: @token }
      # `context_id` is excluded
      assert_status(400)
    end

    context "with a course" do
      let(:course) { Course.create }
      let(:user) { User.create!(name: "me") }
      let(:folder) { Folder.create!(name: "test", context: course) }
      let(:params) do
        {
          id: 1,
          user_id: user.id,
          context_type: "Course",
          context_id: course.id,
          token: @token,
          name: "test.txt",
          size: 42,
          content_type: "text/plain",
          instfs_uuid: 1,
          folder_id: folder.id,
        }
      end

      it "creates a new attachment" do
        post("api_capture", params:)
        assert_status(201)
        attachment = folder.attachments.first
        expect(attachment).not_to be_nil
        expect(attachment.workflow_state).to eq "processed"
      end

      it "populates the md5 column with the instfs sha512" do
        post "api_capture", params: params.merge(sha512: "deadbeef")
        assert_status(201)
        expect(folder.attachments.first.md5).to eq "deadbeef"
      end

      it "includes the attachment json in the response" do
        post("api_capture", params:)
        assert_status(201)
        attachment = folder.attachments.first
        data = json_parse
        expect(data["id"]).to eql attachment.id
        expect(data["filename"]).to eql "test.txt"
        expect(data["url"]).not_to be_nil
      end

      it "works with a ContentMigration as the context" do
        migration = course.content_migrations.create!
        request_params = params.merge(
          context_id: migration.id,
          context_type: "ContentMigration"
        )

        post "api_capture", params: request_params
        assert_status(201)
      end

      it "works with a Quizzes::QuizSubmission as the context" do
        quiz = course.quizzes.create!
        submission = quiz.quiz_submissions.create!(user:)

        request_params = params.merge(
          context_type: "Quizzes::QuizSubmission",
          context_id: submission.id
        )

        post "api_capture", params: request_params
        assert_status(201)
      end

      context "with Submission, Assignment, and Progress" do
        let(:assignment) { course.assignments.create! }
        let(:submission) { assignment.submissions.create!(user: @student) }
        let(:assignment_params) do
          params.merge(
            context_type: "Assignment",
            context_id: assignment.id
          )
        end
        let(:attachment) do
          Attachment.create!(
            context: assignment,
            user: @student,
            filename: "cats.jpg",
            uploaded_data: StringIO.new("meow?")
          )
        end
        let(:progress) do
          Progress
            .new(context: assignment, user:, tag: :test)
            .tap(&:start)
            .tap(&:save!)
        end
        let!(:homework_service) { Services::SubmitHomeworkService.new(attachment, progress) }

        before do
          allow(Mailer).to receive(:deliver)
          allow(Services::SubmitHomeworkService).to(receive(:new)).and_return(homework_service)
        end

        it "works with an Assignment as the context" do
          post "api_capture", params: assignment_params
          assert_status(201)
        end

        context "with progress_id param" do
          let(:progress_params) do
            assignment_params.merge(
              progress_id: progress.id
            )
          end
          let(:request) do
            post "api_capture", params: progress_params
            progress.reload
          end

          it "completes the Progress object" do
            request
            expect(progress).to be_completed
          end

          it "sets the attachment id in the Progress#results" do
            request
            expect(progress.results["id"]).not_to be_nil
          end

          it "returns a 201 http status" do
            request
            assert_status(201)
          end

          it "does not submit the attachment" do
            expect(homework_service).not_to receive(:submit)
            request
          end
        end

        context "with Progress tagged as :upload_via_url" do
          let(:progress) do
            Progress
              .new(context: assignment, user:, tag: :upload_via_url)
              .tap(&:start)
              .tap(&:save!)
          end

          let(:progress_params) do
            assignment_params.merge(
              progress_id: progress.id,
              comment:,
              eula_agreement_timestamp:
            )
          end
          let(:eula_agreement_timestamp) { "1522419910" }
          let(:comment) { "my assignment comment" }
          let(:request) { post "api_capture", params: progress_params }

          before do
            allow(homework_service).to receive(:queue_email)
          end

          it "submits the attachment if the submit_assignment flag is not provided" do
            expect(homework_service).to receive(:submit).with(eula_agreement_timestamp, comment)
            request
          end

          it "submits the attachment if the submit_assignment param is set to true" do
            expect(homework_service).to receive(:submit).with(eula_agreement_timestamp, comment)
            post "api_capture", params: progress_params.merge(submit_assignment: true)
          end

          it "does not submit the attachment if the submit_assignment param is set to false" do
            expect(homework_service).not_to receive(:submit)
            post "api_capture", params: progress_params.merge(submit_assignment: false)
          end

          it "saves the eula_agreement_timestamp" do
            request
            submission = Submission.where(assignment_id: assignment.id)
            expect(submission.first.turnitin_data[:eula_agreement_timestamp]).to eq(eula_agreement_timestamp)
          end

          it "saves the comment" do
            request
            submission = Submission.where(assignment_id: assignment.id)
            expect(submission.first.submission_comments.first.comment).to eq(comment)
          end

          it "returns a 201 http status" do
            request
            assert_status(201)
          end

          it "marks the progress as completed" do
            request
            expect(progress.reload.workflow_state).to eq "completed"
          end

          it "sends a failure email" do
            expect(homework_service).to receive(:submit).and_raise("error")
            expect(homework_service).to receive(:failure_email)
            request

            expect(progress.reload.workflow_state).to eq "failed"
          end
        end
      end

      context "with precreated attachment" do
        let(:attachment) do
          folder.attachments.create!(
            context: course,
            user:,
            file_state: "deleted",
            workflow_state: "unattached",
            filename: "test.txt",
            content_type: "text"
          )
        end

        let(:params) do
          super().merge(
            precreated_attachment_id: attachment.id
          )
        end

        it "marks attachment available" do
          post("api_capture", params:)
          expect(attachment.reload.file_state).to eq "available"
        end

        context "when id is wrong" do
          let(:params) do
            super().merge(
              precreated_attachment_id: attachment.id + 42
            )
          end

          it "returns an error" do
            post("api_capture", params:)
            assert_status(422)
          end
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      it "creates the attachment on the context's shard" do
        user = @shard1.activate { User.create!(name: "me") }
        post "api_capture", params: {
          user_id: user.global_id,
          context_type: "User",
          context_id: user.global_id,
          token: @token,
          name: "test.txt",
          size: 42,
          content_type: "text/plain",
          instfs_uuid: 1,
          folder_id: user.profile_pics_folder.global_id,
        }
        assert_status(201)
        attachment = assigns[:attachment]
        expect(attachment).not_to be_nil
        expect(attachment.shard).to eq @shard1
      end

      it "stores the correct root_account_id on the attachment for a cross-shard account when the context is on the birth shard" do
        account = @shard1.activate { Account.create! }
        user = User.create!(name: "me")
        Attachment.current_root_account = account
        post "api_capture", params: {
          user_id: user.global_id,
          context_type: "User",
          context_id: user.global_id,
          token: @token,
          name: "test.txt",
          size: 42,
          content_type: "text/plain",
          instfs_uuid: 1,
          folder_id: user.profile_pics_folder.global_id,
        }
        assert_status(201)
        attachment = assigns[:attachment]
        expect(attachment.root_account_id).to eq account.global_id
      end
    end
  end

  describe "public_url" do
    before :once do
      assignment_model course: @course, submission_types: %w[online_upload]
      attachment_model context: @student
      @submission = @assignment.submit_homework @student, attachments: [@attachment]
    end

    context "with direct rights" do
      before do
        user_session @student
      end

      it "gives a download url" do
        get "public_url", params: { id: @attachment.id }
        expect(response).to be_successful
        data = json_parse
        expect(data).to eq({ "public_url" => @attachment.public_url(secure: false) })
      end
    end

    context "without direct rights" do
      before do
        user_session @teacher
      end

      it "fails if no submission_id is given" do
        get "public_url", params: { id: @attachment.id }
        assert_unauthorized
      end

      it "allows a teacher to download a student's submission" do
        get "public_url", params: { id: @attachment.id, submission_id: @submission.id }
        expect(response).to be_successful
        data = json_parse
        expect(data).to eq({ "public_url" => @attachment.public_url(secure: false) })
      end

      it "verifies that the requested file belongs to the submission" do
        otherfile = attachment_model
        get "public_url", params: { id: otherfile, submission_id: @submission.id }
        assert_unauthorized
      end

      it "allows downloading an attachment to a previous version" do
        old_file = @attachment
        new_file = attachment_model(context: @student)
        @assignment.submit_homework @student, attachments: [new_file]
        get "public_url", params: { id: old_file.id, submission_id: @submission.id }
        expect(response).to be_successful
        data = json_parse
        expect(data).to eq({ "public_url" => old_file.public_url(secure: false) })
      end
    end
  end

  describe "GET 'image_thumbnail'" do
    let(:image) { @teacher.attachments.create!(uploaded_data: stub_png_data, instfs_uuid: "1234") }

    it "returns default 'no_pic' thumbnail if attachment not found" do
      user_session @teacher
      get "image_thumbnail", params: { uuid: "bad uuid", id: "bad id" }
      expect(response).to be_redirect
    end

    it "returns the same jwt if requested twice" do
      enable_cache do
        user_session @teacher
        locations = Array.new(2) do
          get("image_thumbnail", params: { uuid: image.uuid, id: image.id }).location
        end
        expect(locations[0]).to eq(locations[1])
      end
    end

    it "returns the different jwts if no_cache is passed" do
      enable_cache do
        user_session @teacher
        locations = Array.new(2) do
          get("image_thumbnail", params: { uuid: image.uuid, id: image.id, no_cache: true }).location
        end
        expect(locations[0]).not_to eq(locations[1])
      end
    end
  end

  describe "GET 'image_thumbnail_plain'" do
    before :once do
      @course.root_account.enable_feature!(:file_association_access)
    end

    context "without InstFS" do
      let(:image) do
        local_storage!
        @teacher.attachments.create!(uploaded_data: stub_png_data)
      end

      it "returns a non-token url for local storage" do
        local_storage!
        user_session @teacher
        location = get("image_thumbnail_plain", params: { id: image.id, no_cache: true }).location
        expect(location).to match(%r{/images/thumbnails/show/#{image.thumbnail.id}$})
      end
    end

    context "with InstFS enabled" do
      let(:image) { @teacher.attachments.create!(uploaded_data: stub_png_data, instfs_uuid: "1234") }

      it "returns default 'no_pic' thumbnail if attachment not found" do
        user_session @teacher
        get "image_thumbnail_plain", params: { id: image.id + 1 }
        expect(response).to redirect_to("/images/no_pic.gif")
      end

      it "returns the same jwt if requested twice" do
        enable_cache do
          user_session @teacher
          locations = Array.new(2) do
            get("image_thumbnail_plain", params: { id: image.id }).location
          end
          expect(locations[0]).to eq(locations[1])
        end
      end

      it "returns a proper jwt token" do
        user_session @teacher
        token = get("image_thumbnail_plain", params: { id: image.id, no_cache: true }).location.split("?token=")[1]
        expect { Canvas::Security.decode_jwt(token, [InstFS.jwt_secret]) }.not_to raise_error
      end

      it "returns the different jwts if no_cache is passed" do
        enable_cache do
          user_session @teacher
          locations = Array.new(2) do
            get("image_thumbnail_plain", params: { id: image.id, no_cache: true }).location
          end.map! { |l| l.split("?token=") }
          # This confirms that the two base URLS are the same, but the tokens handed are different
          expect([locations[0][0] == locations[1][0], locations[0][1] != locations[1][1]]).to all(be true)
        end
      end

      it "redirects to default no_pic thumbnail if access_allowed returns false" do
        allow_any_instance_of(FilesController).to receive(:access_allowed).and_return(false)
        user_session @teacher
        get "image_thumbnail_plain", params: { id: image.id }
        expect(response).to redirect_to("/images/no_pic.gif")
      end

      it "returns a 302 if access_allowed returns true" do
        allow_any_instance_of(FilesController).to receive(:access_allowed).and_return(true)
        user_session @teacher
        get "image_thumbnail_plain", params: { id: image.id }
        expect(response).to be_redirect
      end
    end
  end

  describe "process_content_type_from_instfs" do
    it "fixes doc files" do
      expect(controller.send(:process_content_type_from_instfs, "application/x-cfb", "file.doc")).to eq "application/msword"
    end

    it "fixes xls files" do
      expect(controller.send(:process_content_type_from_instfs, "application/x-cfb", "file.xls")).to eq "application/vnd.ms-excel"
    end

    it "fixes ppt files" do
      expect(controller.send(:process_content_type_from_instfs, "application/x-cfb", "file.ppt")).to eq "application/vnd.ms-powerpoint"
    end

    it "ignores case" do
      expect(controller.send(:process_content_type_from_instfs, "application/x-cfb", "file.DOC")).to eq "application/msword"
    end

    it "leaves other CFB types alone" do
      expect(controller.send(:process_content_type_from_instfs, "application/x-cfb", "file.msi")).to eq "application/x-cfb"
    end

    it "fixes kml files" do
      expect(controller.send(:process_content_type_from_instfs, "application/xml", "file.kml")).to eq "application/vnd.google-earth.kml+xml"
    end

    it "leaves other XML files alone" do
      expect(controller.send(:process_content_type_from_instfs, "application/xml", "file.xml")).to eq "application/xml"
    end

    it "leaves other content types alone" do
      expect(controller.send(:process_content_type_from_instfs, "application/pdf", "file.pdf")).to eq "application/pdf"
    end
  end

  describe "GET 'show_thumbnail'" do
    let(:user) { user_factory }
    let(:course) { course_factory }
    let(:image) { @teacher.attachments.create!(uploaded_data: stub_png_data, instfs_uuid: "1234") }
    let(:thumbnail) do
      Thumbnail.create!(filename: "tmp/test_thumb.png", content_type: "image/png", attachment: image, size: "200x50")
    end

    it "sends the thumbnail file if authorized" do
      local_storage!
      user_session(@teacher)
      expect_any_instance_of(FilesController).to receive(:safe_send_file)
        .with(thumbnail.full_filename, content_type: thumbnail.content_type).and_return(nil)
      get :show_thumbnail, params: { id: thumbnail.id }
    end

    it "returns unauthorized if not authorized" do
      local_storage!
      allow_any_instance_of(FilesController).to receive(:authorized_action).and_return(false)
      user_session(user)
      get :show_thumbnail, params: { id: thumbnail.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
