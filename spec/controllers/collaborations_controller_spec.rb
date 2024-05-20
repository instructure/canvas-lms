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

describe CollaborationsController do
  before :once do
    plugin_setting = PluginSetting.new(name: "etherpad", settings: {})
    plugin_setting.save!
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)

    group_model(context: @course)
  end

  describe "GET 'index'" do
    it "requires authorization" do
      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "redirects 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{ "id" => 16, "hidden" => true }])
      get "index", params: { course_id: @course.id }
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end

    it "assigns variables" do
      user_session(@student)
      allow(controller).to receive(:google_drive_connection).and_return(double(authorized?: true))

      get "index", params: { course_id: @course.id }

      expect(response).to be_successful
      expect(assigns(:user_has_google_drive)).to be true
    end

    it "handles users without google authorized" do
      user_session(@student)
      allow(controller).to receive(:google_drive_connection).and_return(double(authorized?: false))

      get "index", params: { course_id: @course.id }

      expect(response).to be_successful
      expect(assigns(:user_has_google_drive)).to be false
    end

    it "handles users that need to upgrade to google_drive" do
      user_session(@student)
      plugin = Canvas::Plugin.find(:google_drive)
      plugin_setting = PluginSetting.find_by_name(plugin.id) || PluginSetting.new(name: plugin.id, settings: plugin.default_settings)
      plugin_setting.posted_settings = {}
      plugin_setting.save!
      get "index", params: { course_id: @course.id }

      expect(response).to be_successful
      expect(assigns(:user_has_google_drive)).to be false
    end

    it "does not allow the student view student to access collaborations" do
      course_with_teacher_logged_in(active_user: true)
      expect(@course).not_to be_available
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      get "index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "works with groups" do
      user_session(@student)
      gc = group_category
      group = gc.groups.create!(context: @course)
      group.add_user(@student, "accepted")

      # allow(controller).to receive(:google_docs_connection).and_return(double(authorized?:false))

      get "index", params: { group_id: group.id }
      expect(response).to be_successful
    end

    it "only returns collaborations that the user has access to read" do
      user_session(@student)
      @course.collaborations.create!(
        title: "inaccessible",
        user: @teacher
      ).tap { |c| c.update_attribute :url, "http://www.example.com" }

      collab2 = @course.collaborations.create!(
        title: "accessible",
        user: @student
      ).tap { |c| c.update_attribute :url, "http://www.example.com" }

      gc = group_category

      valid_group = gc.groups.create!(context: @course, name: "valid")
      valid_group.add_user(@student, "accepted")
      valid_collab = @course.collaborations.create!(
        title: "valid",
        user: @teacher
      ).tap do |c|
        c.update_attribute :url, "http://www.example.com"
        c.update_members([], [valid_group.id])
      end

      invalid_group = gc.groups.create!(context: @course, name: "invalid")
      invalid_group.add_user(@student, "deleted")
      invalid_collab = @course.collaborations.create!(
        title: "invalid",
        user: @teacher
      ).tap do |c|
        c.update_attribute :url, "http://www.example.com"
        c.update_members([], [invalid_group.id])
      end

      get "index", params: { course_id: @course.id }
      expect(assigns[:collaborations]).to match_array [collab2, valid_collab]
      expect(assigns[:collaborations]).not_to include invalid_collab
    end
  end

  describe "GET 'members'" do
    before do
      @collab = @course.collaborations.create!(
        title: "accessible",
        user: @student,
        url: "http://www.example.com"
      )
      @collab.reload
    end

    it "requires authorization" do
      get "members", params: { id: @collab.id }
      assert_unauthorized
    end

    context "with user access token" do
      before do
        pseudonym(@student)
        @student.save!
        enable_default_developer_key!
        token = @student.access_tokens.create!(purpose: "test").full_token
        @request.headers["Authorization"] = "Bearer #{token}"
      end

      it "returns back collaboration members" do
        get "members", params: { id: @collab.id }
        hash = JSON.parse(@response.body).first

        expect(hash["id"]).to eq @collab.collaborators.first.id
        expect(hash["type"]).to eq "user"
        expect(hash["name"]).to eq @student.sortable_name
        expect(hash["collaborator_id"]).to eq @student.id
      end

      it "includes collaborator_lti_id" do
        get "members", params: { id: @collab.id, include: ["collaborator_lti_id"] }
        @student.reload
        hash = JSON.parse(@response.body).first

        expect(hash["collaborator_lti_id"]).to eq @student.lti_context_id
      end

      it "includes collaborator old_lti_id" do
        Lti::Asset.opaque_identifier_for(@student)
        UserPastLtiId.create!(user: @student, context: @collab.context, user_lti_id: @student.lti_id, user_lti_context_id: "old_lti_id", user_uuid: "old")
        get "members", params: { id: @collab.id, include: ["collaborator_lti_id"] }
        @student.reload
        hash = JSON.parse(@response.body).first

        expect(hash["collaborator_lti_id"]).to eq "old_lti_id"
      end

      it "includes avatar_image_url" do
        @student.avatar_image_url = "https://www.example.com/awesome-avatar.png"
        @student.save!
        get "members", params: { id: @collab.id, include: ["avatar_image_url"] }
        hash = JSON.parse(@response.body).first

        expect(hash["avatar_image_url"]).to eq @student.avatar_image_url
      end
    end
  end

  describe "GET 'lti_index'" do
    it "requires authorization for the course" do
      get "lti_index", params: { course_id: @course.id }
      assert_unauthorized
    end

    it "requires authorization for the group" do
      get "lti_index", params: { group_id: @group.id }
      assert_unauthorized
    end
  end

  describe "GET 'show'" do
    let(:collaboration) do
      @course.collaborations.create!(
        title: "my collab",
        user: @teacher
      ).tap { |c| c.update_attribute :url, "http://www.example.com" }
    end

    let(:url) { "http://www.example.com/launch" }
    let(:domain) { "example.com" }
    let(:developer_key) { dev_key_model_1_3(account: @course.account) }
    let(:new_tool) { external_tool_1_3_model(context: @course, developer_key:, opts: { url:, name: "1.3 tool" }) }
    let(:old_tool) { external_tool_model(context: @course, opts: { url:, domain: }) }

    context "when the collaboration includes a resource_link_lookup_uuid" do
      subject { get "show", params: { course_id: @course.id, id: collaboration.id } }

      let(:lookup_uuid) { SecureRandom.uuid }
      let(:collaboration) do
        ExternalToolCollaboration.create!(
          title: "my collab",
          user: @teacher,
          url: "http://www.example.com",
          context: @course,
          resource_link_lookup_uuid: lookup_uuid
        )
      end

      before do
        user_session(@teacher)
        new_tool
      end

      it "adds the lookup ID to the redirect URL" do
        url = CGI.escape(collaboration[:url])
        expect(subject).to redirect_to(
          "/courses/#{@course.id}/external_tools/retrieve?display=borderless&resource_link_lookup_id=#{lookup_uuid}&url=#{url}"
        )
      end
    end

    context "when the original tool is 1.1 and there is a 1.3 tool" do
      let(:collaboration) do
        ExternalToolCollaboration.create!(
          title: "my collab",
          user: @teacher,
          url:,
          context: @course
        )
      end

      before do
        user_session(@teacher)
        old_tool
        new_tool
      end

      it "migrates the collaboration to 1.3" do
        get "show", params: { course_id: @course.id, id: collaboration.id }
        expect(collaboration.reload.resource_link_lookup_uuid).to eq(Lti::ResourceLink.last.lookup_uuid)
      end
    end

    it "redirects to the lti launch url for ExternalToolCollaborations" do
      course_with_teacher(active_all: true)
      user_session(@teacher)
      old_tool
      collab = ExternalToolCollaboration.new(
        title: "my collab",
        user: @teacher,
        url: "http://www.example.com"
      )
      collab.context = @course
      collab.save!
      get "show", params: { course_id: @course.id, id: collab.id }
      url = CGI.escape(collab[:url])
      expect(response).to redirect_to "/courses/#{@course.id}/external_tools/retrieve?display=borderless&url=#{url}"
    end

    context "logged in user" do
      before :once do
        Setting.set("enable_page_views", "db")
        course_with_teacher(active_all: true)
      end

      before do
        user_session(@teacher)
        get "show", params: { course_id: @course.id, id: collaboration.id }
      end

      it "loads the correct collaboration" do
        expect(assigns(:collaboration)).to eq collaboration
      end

      it "logs an asset access record for the discussion topic" do
        accessed_asset = assigns[:accessed_asset]
        expect(accessed_asset[:code]).to eq collaboration.asset_string
        expect(accessed_asset[:category]).to eq "collaborations"
        expect(accessed_asset[:level]).to eq "participate"
      end

      it "registers a page view" do
        page_view = assigns[:page_view]
        expect(page_view).not_to be_nil
        expect(page_view.http_method).to eq "get"
        expect(page_view.url).to match %r{^http://test\.host/courses/\d+/collaborations}
        expect(page_view.participated).to be_truthy
      end
    end

    context "logged out user" do
      it "rejects access properly" do
        get "show", params: { course_id: @course.id, id: collaboration.id }

        expect(response).to have_http_status :found
        expect(response.headers["Location"]).to match(/login/)
      end
    end
  end

  describe "POST 'create'" do
    before(:once) { course_with_teacher(active_all: true) }

    it "requires authorization" do
      post "create", params: { course_id: @course.id, collaboration: {} }
      assert_unauthorized
    end

    it "fails with invalid collaboration type" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, collaboration: { title: "My Collab" } }
      assert_status(400)
    end

    it "creates collaboration" do
      user_session(@teacher)
      post "create", params: { course_id: @course.id, collaboration: { collaboration_type: "EtherPad", title: "My Collab" } }
      expect(response).to be_redirect
      expect(assigns[:collaboration]).not_to be_nil
      expect(assigns[:collaboration].class).to eql(EtherpadCollaboration)
      expect(assigns[:collaboration].collaboration_type).to eql("EtherPad")
      expect(Collaboration.find(assigns[:collaboration].id)).to be_is_a(EtherpadCollaboration)
    end

    context "content_items" do
      let(:content_items) do
        [
          {
            title: "my collab",
            text: "collab description",
            url: "http://example.invalid/test",
            confirmUrl: "http://example.com/confirm/343"
          }
        ]
      end

      context "with the deep linking extension" do
        subject do
          post(:create, params:)
          Collaboration.find(assigns[:collaboration].id)
        end

        let(:teacher) { @teacher }
        let(:student) { student_in_course(course:, active_all: true).user }
        let(:course) { @course }
        let(:params) { { course_id: course.id, contentItems: [content_item].to_json } }
        let(:content_item) do
          {
            type: "ltiResourceLink",
            url: "http://test-tool.docker/launch?deep_linking=true",
            title: "Lti 1.3 Tool Title",
            text: "Lti 1.3 Tool Text",
            icon: "https://img.icons8.com/metro/1600/unicorn.png",
            thumbnail: "https://via.placeholder.com/150?text=thumbnail",
            lookup_uuid: "9446c291-168f-4f46-bf3c-785dd3d986d3"
          }
        end

        before { user_session(teacher) }

        context "with a group set" do
          let(:group) { group_model(course:) }
          let(:content_item) do
            super().merge(
              Collaboration::DEEP_LINKING_EXTENSION => {
                groups: [Lti::Asset.opaque_identifier_for(group)]
              }
            )
          end

          before { group.add_user(student, "active") }

          it "associates the group to the collaboration" do
            expect(subject.collaborators.pluck(:group_id).compact).to match_array [group.id]
          end
        end

        context "with users set" do
          let(:content_item) do
            super().merge(Collaboration::DEEP_LINKING_EXTENSION => { users: [student.lti_id] })
          end

          it "associates the users to the collaboration" do
            expect(subject.collaborators.pluck(:user_id)).to match_array [teacher.id, student.id]
          end
        end
      end

      it "creates a collaboration using content-item" do
        user_session(@teacher)

        post "create", params: { course_id: @course.id, contentItems: content_items.to_json }
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(assigns[:collaboration]).not_to be_nil
        expect(assigns[:collaboration].class).to eql(ExternalToolCollaboration)
        expect(collaboration).to be_is_a(ExternalToolCollaboration)
        expect(collaboration.title).to eq content_items.first[:title]
        expect(collaboration.description).to eq content_items.first[:text]
        expect(collaboration.url).to eq content_items[0][:url]
      end

      it "callback url should not be nil if provided" do
        user_session(@teacher)
        post "create", params: { course_id: @course.id, contentItems: content_items.to_json }
        collaboration = ExternalToolCollaboration.last
        expect(collaboration.data["confirmUrl"]).to eq "http://example.com/confirm/343"
      end

      it "callbacks on success" do
        user_session(@teacher)
        content_item_util_stub = double("ContentItemUtil")
        expect(content_item_util_stub).to receive(:success_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        post "create", params: { course_id: @course.id, contentItems: content_items.to_json }
      end

      it "callbacks on failure" do
        user_session(@teacher)
        expect_any_instance_of(Collaboration).to receive(:save).and_return(false)
        content_item_util_stub = double("ContentItemUtil")
        expect(content_item_util_stub).to receive(:failure_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        post "create", params: { course_id: @course.id, contentItems: content_items.to_json }
      end

      it "adds users if sent" do
        user_session(@teacher)
        users = Array.new(2) { student_in_course(course: @course, active_all: true).user }
        lti_user_ids = users.map { |student| Lti::Asset.opaque_identifier_for(student) }
        content_items.first["ext_canvas_visibility"] = { users: lti_user_ids }
        post "create", params: { course_id: @course.id, contentItems: content_items.to_json }
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.map(&:user_id)).to match_array([*users, @teacher].map(&:id))
      end

      it "adds groups if sent" do
        user_session(@teacher)
        group = group_model(context: @course)
        group.add_user(@teacher, "active")
        content_items.first["ext_canvas_visibility"] = { groups: [Lti::Asset.opaque_identifier_for(group)] }
        post "create", params: { course_id: @course.id, contentItems: content_items.to_json }
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.filter_map(&:group_id)).to match_array([group.id])
      end

      context "when tool_id is a 1.3 tool" do
        before { user_session(@teacher) }

        it "creates a resource link for the collaboration with the url and custom parameters" do
          tool = external_tool_1_3_model(context: @course)
          content_items = [{ title: "hi", url: tool.url, custom: { "a" => "b" } }]
          post "create", params: { course_id: @course.id, contentItems: content_items.to_json, tool_id: tool.id }
          collaboration = Collaboration.find(assigns[:collaboration].id)
          lrl = Lti::ResourceLink.find_by(lookup_uuid: collaboration.reload.resource_link_lookup_uuid)
          expect(lrl.url).to eq(content_items.first[:url])
          expect(lrl.custom).to eq(content_items.first[:custom])
        end

        context "when the tool context is not compatible with the collaboration context" do
          it "returns an unauthorized response" do
            tool = external_tool_1_3_model(context: account_model)
            content_items = [{ title: "hi", url: tool.url, custom: { "a" => "b" } }]
            post "create", params: { course_id: @course.id, contentItems: content_items.to_json, tool_id: tool.id }
            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end
  end

  describe "PUT #update" do
    context "content_items" do
      let(:collaboration) do
        collab = @course.collaborations.create!(
          title: "a collab",
          user: @teacher
        )
        collab.update_attribute :url, "http://www.example.com"
        collab.update_attribute :type, "ExternalToolCollaboration"
        collab
      end

      let(:content_items) do
        [
          {
            title: "my collab",
            text: "collab description",
            url: "http://example.invalid/test",
            confirmUrl: "http://example.com/confirm/343"
          }
        ]
      end

      it "updates a collaboration using content-item" do
        user_session(@teacher)
        put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json }
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(assigns[:collaboration]).not_to be_nil
        expect(assigns[:collaboration].class).to eql(ExternalToolCollaboration)
        expect(collaboration).to be_is_a(ExternalToolCollaboration)
        expect(collaboration.title).to eq content_items.first[:title]
        expect(collaboration.description).to eq content_items.first[:text]
        expect(collaboration.url).to eq content_items[0][:url]
      end

      it "callback url should not be nil if provided" do
        user_session(@teacher)
        put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json }
        c = ExternalToolCollaboration.find(collaboration.id)
        expect(c.data["confirmUrl"]).to eq "http://example.com/confirm/343"
      end

      it "callbacks on success" do
        user_session(@teacher)
        content_item_util_stub = double("ContentItemUtil")
        expect(content_item_util_stub).to receive(:success_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json }
      end

      it "callbacks on failure" do
        user_session(@teacher)
        allow_any_instance_of(Collaboration).to receive(:save).and_return(false)
        content_item_util_stub = double("ContentItemUtil")
        expect(content_item_util_stub).to receive(:failure_callback)
        allow(Lti::ContentItemUtil).to receive(:new).and_return(content_item_util_stub)
        put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json }
      end

      it "adds users if sent" do
        user_session(@teacher)
        users = Array.new(2) { student_in_course(course: @course, active_all: true).user }
        lti_user_ids = users.map { |student| Lti::Asset.opaque_identifier_for(student) }
        content_items.first["ext_canvas_visibility"] = { users: lti_user_ids }
        put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json }
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.map(&:user_id)).to match_array([*users, @teacher].map(&:id))
      end

      it "adds groups if sent" do
        user_session(@teacher)
        group = group_model(context: @course)
        group.add_user(@teacher, "active")
        content_items.first["ext_canvas_visibility"] = { groups: [Lti::Asset.opaque_identifier_for(group)] }
        put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json }
        collaboration = Collaboration.find(assigns[:collaboration].id)
        expect(collaboration.collaborators.filter_map(&:group_id)).to match_array([group.id])
      end

      it "adds each group only once on multiple requests" do
        user_session(@teacher)
        group = group_model(context: @course)
        group.add_user(@teacher, "active")
        content_items.first["ext_canvas_visibility"] = {
          groups: [Lti::Asset.opaque_identifier_for(group)],
          users: [Lti::Asset.opaque_identifier_for(@teacher)]
        }
        2.times do
          put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json }
        end
        collaboration = Collaboration.find(assigns[:collaboration].id)

        expect(collaboration.collaborators.filter_map(&:group_id)).to match_array([group.id])
      end

      context "when a tool_id for an LTI 1.3 tool is passed in" do
        subject do
          put "update", params: { id: collaboration.id, course_id: @course.id, contentItems: content_items.to_json, tool_id: tool.id }
        end

        let(:tool_context) { @course.account }
        let(:tool) { external_tool_1_3_model(context: tool_context) }
        let(:content_items) { [{ title: "hi", url: tool.url, custom: { "a" => "b" } }] }

        before { user_session(@teacher) }

        context "when the collaboration has a resource_link_lookup_uiud" do
          it "updates the url and custom parameters in the resource link" do
            lrl = Lti::ResourceLink.create_with(@course, tool, nil, collaboration.url)
            collaboration.update! resource_link_lookup_uuid: lrl.lookup_uuid
            subject

            expect(collaboration.reload.resource_link_lookup_uuid).to eq(lrl.lookup_uuid)
            expect(lrl.reload.url).to eq(content_items.first[:url])
            expect(lrl.custom).to eq(content_items.first[:custom])
          end
        end

        context "when the collaboration does not have a resource_link_lookup_uuid" do
          it "creates a resource link for the collaboration with the url and custom parameters" do
            subject
            lrl = Lti::ResourceLink.find_by(lookup_uuid: collaboration.reload.resource_link_lookup_uuid)
            expect(lrl.url).to eq(content_items.first[:url])
            expect(lrl.custom).to eq(content_items.first[:custom])
          end

          context "when the tool context is not compatible with the collaboration context" do
            let(:tool_context) { account_model }

            it "returns a 'bad request' response" do
              subject
              expect(response).to have_http_status(:bad_request)
            end
          end

          context "when the tool is not compatible with the URL" do
            it "returns a 'bad request' response" do
              content_items.first[:url] = "http://some-other-url.com"
              subject
              expect(response).to have_http_status(:bad_request)
            end
          end
        end
      end
    end
  end
end
