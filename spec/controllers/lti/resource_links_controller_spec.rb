# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Lti::ResourceLinksController, type: :request do
  let(:response_json) do
    body = response.parsed_body
    body.is_a?(Array) ? body.map(&:with_indifferent_access) : body.with_indifferent_access
  end

  let_once(:account) { account_model }
  let_once(:admin) { account_admin_user(name: "A User", account:) }
  let_once(:course) { course_model(account:) }
  let_once(:registration) { lti_registration_with_tool(account:) }
  let_once(:tool) { registration.deployments.first }

  before do
    user_session(admin)
  end

  describe "GET #index" do
    subject { get "/api/v1/courses/#{course.id}/lti_resource_links" }

    let_once(:url) { "https://example.com/lti/launch" }
    let_once(:overrides) { { with_context_external_tool: tool } }
    let_once(:assignment) { assignment_model(course:) }
    let_once(:assignment_rl) { resource_link_model(context: assignment, overrides:) }
    let_once(:context_module) do
      ContextModule.create!(
        context: course,
        name: "External Tools"
      )
    end
    let_once(:module_item) do
      ContentTag.create!(
        context: course,
        context_module:,
        tag_type: :context_module,
        content: tool,
        url:,
        associated_asset: module_item_rl
      )
    end
    let_once(:module_item_rl) { resource_link_model(context: course, overrides:) }
    let_once(:collaboration) do
      ExternalToolCollaboration.create!(
        title: "my collab",
        user: admin,
        url:,
        context: course,
        resource_link_lookup_uuid: collaboration_rl.lookup_uuid
      )
    end
    let_once(:collaboration_rl) { resource_link_model(context: course) }
    let_once(:rich_content_rl) { resource_link_model(context: course) }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      before { user_session(student_in_course(account:).user) }

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "includes all types of resource links" do
      subject
      expect(response_json.to_h { |rl| [rl["id"], rl["resource_type"]] }).to eq({
                                                                                  assignment_rl.id => "assignment",
                                                                                  module_item_rl.id => "module_item",
                                                                                  collaboration_rl.id => "collaboration",
                                                                                  rich_content_rl.id => "rich_content",
                                                                                })
    end

    it "includes launch_url for each resource link" do
      subject
      launch_urls = response_json.to_h { |rl| [rl["id"], rl["canvas_launch_url"]] }
      expect(launch_urls[assignment_rl.id]).to eq("http://www.example.com/courses/#{course.id}/assignments/#{assignment.id}")
      expect(launch_urls[module_item_rl.id]).to eq("http://www.example.com/courses/#{course.id}/external_tools/retrieve?resource_link_lookup_uuid=#{module_item_rl.lookup_uuid}")
      expect(launch_urls[collaboration_rl.id]).to eq("http://www.example.com/courses/#{course.id}/external_tools/retrieve?resource_link_lookup_uuid=#{collaboration_rl.lookup_uuid}")
      expect(launch_urls[rich_content_rl.id]).to eq("http://www.example.com/courses/#{course.id}/external_tools/retrieve?resource_link_lookup_uuid=#{rich_content_rl.lookup_uuid}")
    end

    it "includes corresponding module_item_id for resource link" do
      subject
      content_types = response_json.to_h { |rl| [rl["id"], rl["associated_content_type"]] }
      content_ids = response_json.to_h { |rl| [rl["id"], rl["associated_content_id"]] }

      expect(content_types[module_item_rl.id]).to eq("ModuleItem")
      expect(content_ids[module_item_rl.id]).to eq(module_item.id)
      expect(content_types[assignment_rl.id]).to be_nil
      expect(content_ids[assignment_rl.id]).to be_nil
    end

    context "with deleted link and content" do
      before do
        collaboration_rl.destroy
        assignment.destroy
      end

      it "does not include the deleted links" do
        subject
        expect(response_json.size).to eq(2)
      end

      context "with include_deleted param" do
        subject { get "/api/v1/courses/#{course.id}/lti_resource_links?include_deleted=true" }

        it "includes the deleted links" do
          subject
          expect(response_json.size).to eq(4)
        end
      end
    end

    context "with per_page param" do
      subject { get "/api/v1/courses/#{course.id}/lti_resource_links?per_page=#{per_page}" }

      let(:per_page) { 2 }

      it "returns the specified number of resource links" do
        subject
        expect(response_json.size).to eq(per_page)
      end

      it "includes a Link header" do
        subject
        expect(response.headers["Link"]).to include("rel=\"next\"")
      end
    end
  end

  describe "GET #show" do
    subject { get "/api/v1/courses/#{course.id}/lti_resource_links/#{id}" }

    let(:resource_link) { resource_link_model(context: course) }
    let(:id) { resource_link.id }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      before { user_session(student_in_course(account:).user) }

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "returns the resource link" do
      subject
      expect(response_json).to include({ id: })
    end

    it "includes the canvas launch url" do
      subject
      expect(response_json["canvas_launch_url"]).to eq(retrieve_course_external_tools_url(course, resource_link_lookup_uuid: resource_link.lookup_uuid))
    end

    context "with lookup_uuid" do
      let(:id) { "lookup_uuid:#{resource_link.lookup_uuid}" }

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns the resource link" do
        subject
        expect(response_json).to include({ id: resource_link.id })
      end
    end

    context "with resource_link_uuid" do
      let(:id) { "resource_link_uuid:#{resource_link.resource_link_uuid}" }

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns the resource link" do
        subject
        expect(response_json).to include({ id: resource_link.id })
      end
    end

    context "with deleted link" do
      before { resource_link.destroy }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end

      context "with include_deleted param" do
        subject { get "/api/v1/courses/#{course.id}/lti_resource_links/#{id}?include_deleted=true" }

        it "returns resource link" do
          subject
          expect(response_json).to include({ id: resource_link.id })
        end
      end
    end
  end

  describe "PUT #update" do
    subject { put "/api/v1/courses/#{course.id}/lti_resource_links/#{id}", params: }

    let(:resource_link) do
      resource_link_model(context: course, course:, overrides: {
                            url: tool.url
                          })
    end
    let(:id) { resource_link.id }
    let(:params) { {} }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      before { user_session(student_in_course(account:).user) }

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "returns the resource link" do
      subject
      expect(response_json).to include({ id: })
    end

    context "with url param" do
      let(:url) { resource_link.original_context_external_tool.url + "/deeplink" }
      let(:params) { { url: } }

      it "updates the resource link" do
        subject
        expect(response).to be_successful
        expect(resource_link.reload.url).to eq(url)
      end

      context "invalid" do
        let(:url) { "hello world!" }

        it "returns 422" do
          subject
          expect(response).to be_unprocessable
        end
      end

      context "does not match tool url" do
        let(:url) { "https://othertool.com/lti/launch" }

        it "returns 422" do
          subject
          expect(response).to be_unprocessable
        end
      end
    end

    context "with custom param" do
      let(:custom) { { "hello" => "world" } }
      let(:params) { { custom: } }

      it "updates the resource link" do
        subject
        expect(resource_link.reload.custom).to eq(custom)
      end

      context "invalid" do
        let(:custom) { "hello" }

        it "returns 422" do
          subject
          expect(response).to be_unprocessable
        end
      end
    end

    context "with deleted link" do
      before { resource_link.destroy }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end

      context "with include_deleted param" do
        let(:params) { { include_deleted: true } }

        it "returns resource link" do
          subject
          expect(response_json).to include({ id: resource_link.id })
        end
      end
    end

    context "with tool id" do
      let(:tool2) { registration.new_external_tool(account) }
      let(:params) { { context_external_tool_id: tool2.id } }

      it "updates the resource link" do
        subject
        expect(response).to be_successful
        expect(resource_link.reload.context_external_tool_id).to eq(tool2.id)
      end

      context "invalid" do
        let(:params) { { context_external_tool_id: 0 } }

        it "returns 422" do
          subject
          expect(response).to be_unprocessable
        end
      end

      context "that does not match original url" do
        let(:registration) do
          lti_registration_with_tool(account:,
                                     configuration_params: {
                                       target_link_uri: "https://otherurl.com",
                                       oidc_initiation_url: "https://otherurl.com/oidc",
                                       domain: "otherurl.com",
                                       placements: [
                                         {
                                           placement: "course_navigation",
                                         }
                                       ]
                                     })
        end
        let(:tool2) { registration.deployments.first }
        let(:params) { { context_external_tool_id: tool2.id } }

        it "returns 422" do
          subject
          expect(response).to be_unprocessable
        end
      end
    end
  end

  describe "POST #create" do
    subject { post "/api/v1/courses/#{course.id}/lti_resource_links", params: }

    let(:custom) { { "hello" => "world" } }
    let(:url) { "#{tool.url}/launch" }
    let(:title) { "My LTI Link" }
    let(:params) { { url:, custom:, title: } }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      before { user_session(student_in_course(account:).user) }

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "creates a resource link" do
      expect { subject }.to change { course.lti_resource_links.count }.by(1)
    end

    it "returns the resource link" do
      subject
      expect(response_json).to include({ url:, title:, custom: }.stringify_keys)
    end

    context "with no matching tool" do
      let(:url) { "https://othertool.com/lti/launch" }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end
    end

    context "with invalid url param" do
      let(:url) { "hello world!" }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end
    end

    context "with invalid custom param" do
      let(:custom) { "hello" }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end
    end
  end

  describe "POST #bulk_create" do
    subject { post "/api/v1/courses/#{course.id}/lti_resource_links/bulk", params:, as: :json }

    let(:params) do
      [
        { url: tool.url, title: "My LTI Link 1" },
        { url: tool.url, title: "My LTI Link 2", custom: { "hello" => "world" } }
      ]
    end

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      before { user_session(student_in_course(account:).user) }

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "creates resource links" do
      expect { subject }.to change { course.lti_resource_links.count }.by(2)
      first = course.lti_resource_links.find_by(title: "My LTI Link 1")
      expect(first.custom).to be_nil
      expect(first.url).to eq(params[0][:url])
      second = course.lti_resource_links.find_by(title: "My LTI Link 2")
      expect(second.custom).to eq({ "hello" => "world" })
      expect(second.url).to eq(params[1][:url])
    end

    it "returns the resource links" do
      subject
      expect(response_json.size).to eq(2)
    end

    context "with one invalid link" do
      let(:params) do
        [
          { url: "hello world!", title: "My LTI Link 1" },
        ]
      end

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end

      it "does not create any links" do
        expect { subject }.not_to change { course.lti_resource_links.count }
      end
    end

    context "with some invalid links" do
      let(:params) do
        [
          { url: "hello world!", title: "My LTI Link 1" },
          { url: "https://example.com/lti/launch", title: "My LTI Link 2", custom: { "hello" => "world" } }
        ]
      end

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end

      it "does not create any links" do
        expect { subject }.not_to change { course.lti_resource_links.count }
      end
    end

    context "with more links than are allowed" do
      let(:max_size) { 10 }
      let(:params) { Array.new(12) { { url: "https://example.com/lti/launch", title: "My LTI Link" } } }

      before do
        stub_const("Lti::ResourceLinksController::MAX_BULK_CREATE", max_size)
      end

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end

      it "creates no links" do
        expect { subject }.not_to change { course.lti_resource_links.count }
      end
    end
  end

  describe "DELETE #destroy" do
    subject { delete "/api/v1/courses/#{course.id}/lti_resource_links/#{id}" }

    let(:resource_link) { resource_link_model(context: course) }
    let(:id) { resource_link.id }
    let(:url) { resource_link.url }

    context "without user session" do
      before { remove_user_session }

      it "returns 401" do
        subject
        expect(response).to be_unauthorized
      end
    end

    context "with non-admin user" do
      before { user_session(student_in_course(account:).user) }

      it "returns 403" do
        subject
        expect(response).to be_forbidden
      end
    end

    it "is successful" do
      subject
      expect(response).to be_successful
    end

    it "returns the resource link" do
      subject
      expect(response_json).to include({ id: })
    end

    it "deletes the resource link" do
      subject
      expect(resource_link.reload).to be_deleted
    end

    context "with lookup_uuid" do
      let(:id) { "lookup_uuid:#{resource_link.lookup_uuid}" }

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns the resource link" do
        subject
        expect(response_json).to include({ id: resource_link.id })
      end

      it "deletes the resource link" do
        subject
        expect(resource_link.reload).to be_deleted
      end
    end

    context "with resource_link_uuid" do
      let(:id) { "resource_link_uuid:#{resource_link.resource_link_uuid}" }

      it "is successful" do
        subject
        expect(response).to be_successful
      end

      it "returns the resource link" do
        subject
        expect(response_json).to include({ id: resource_link.id })
      end

      it "deletes the resource link" do
        subject
        expect(resource_link.reload).to be_deleted
      end

      context "with already deleted link" do
        before { resource_link.destroy }

        it "returns 404" do
          subject
          expect(response).to be_not_found
        end
      end
    end

    context "with already deleted link" do
      before { resource_link.destroy }

      it "returns 404" do
        subject
        expect(response).to be_not_found
      end

      context "with include_deleted param" do
        subject { delete "/api/v1/courses/#{course.id}/lti_resource_links/#{id}?include_deleted=true" }

        it "returns 404" do
          subject
          expect(response).to be_not_found
        end
      end
    end

    context "with assignment resource link" do
      let(:resource_link) { resource_link_model(context: assignment_model(course:)) }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end
    end

    context "with module item resource link" do
      let_once(:context_module) do
        ContextModule.create!(
          context: course,
          name: "External Tools"
        )
      end
      let_once(:module_item) do
        ContentTag.create!(
          context: course,
          context_module:,
          tag_type: :context_module,
          content: tool,
          url:,
          associated_asset: resource_link
        )
      end
      let_once(:resource_link) { resource_link_model(context: course) }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end
    end

    context "with collaboration resource link" do
      let_once(:collaboration) do
        ExternalToolCollaboration.create!(
          title: "my collab",
          user: admin,
          url:,
          context: course,
          resource_link_lookup_uuid: resource_link.lookup_uuid
        )
      end
      let_once(:resource_link) { resource_link_model(context: course) }

      it "returns 422" do
        subject
        expect(response).to be_unprocessable
      end
    end
  end
end
