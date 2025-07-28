# frozen_string_literal: true

#
# Copyright (C) 2014 Instructure, Inc.
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

require_relative "../api_spec_helper"
require_relative "../../lti_spec_helper"

module Lti
  describe LtiAppsController, type: :request do
    include LtiSpecHelper

    let(:account) { Account.create }

    describe "#launch_definitions" do
      before do
        tp = create_tool_proxy
        tp.bindings.create(context: account)
        rh = create_resource_handler(tp)
        @mh = create_message_handler(rh)
        @external_tool = new_valid_external_tool(account)
      end

      it "returns a list of launch definitions for a context and placements" do
        resource_tool = new_valid_external_tool(account, true)
        course_with_teacher(active_all: true, user: user_with_pseudonym, account:)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps",
                          action: "launch_definitions",
                          format: "json",
                          placements: %w[resource_selection],
                          course_id: @course.id.to_s })
        expect(json.detect { |j| j["definition_type"] == resource_tool.class.name && j["definition_id"] == resource_tool.id }).not_to be_nil
        expect(json.detect { |j| j["definition_type"] == @external_tool.class.name && j["definition_id"] == @external_tool.id }).to be_nil
      end

      it "works for a teacher even without manage_lti_add permissions" do
        course_with_teacher(active_all: true, user: user_with_pseudonym, account:)
        account.role_overrides.create!(permission: "manage_lti_add", enabled: false, role: teacher_role)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s })
        expect(json.count).to eq 1
        expect(json.detect { |j| j["definition_type"] == @external_tool.class.name && j["definition_id"] == @external_tool.id }).not_to be_nil
      end

      it "includes icon information for asset processor placements" do
        course_with_teacher(active_all: true, user: user_with_pseudonym, account:)

        tool1 = new_valid_external_tool(account)
        tool1.settings["ActivityAssetProcessor"] = { icon_url: "http://example.com/foo.png" }
        tool1.save!

        url = "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions"
        params = {
          controller: "lti/lti_apps", action: "launch_definitions", course_id: @course.to_param, format: "json"
        }
        placements = ["ActivityAssetProcessor"]
        json = api_call(:get, url, params, placements:)
        icon_url = json.first["placements"]["ActivityAssetProcessor"]["icon_url"]
        expect(icon_url).to eq "http://example.com/foo.png"
        tool_name = json.first["placements"]["ActivityAssetProcessor"]["tool_name_for_default_icon"]
        expect(tool_name).to eq tool1.name
      end

      it "returns authorized for a student but with no results when no placement is specified" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)

        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s })

        expect(response).to have_http_status :ok
        expect(json.count).to eq 0
      end

      it "student can not get definition with admin visibility" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)
        resource_tool = new_valid_external_tool(account, true)
        resource_tool.settings[:resource_selection][:visibility] = "admins"
        resource_tool.save!
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s, placements: %w[resource_selection] })

        expect(response).to have_http_status :ok
        expect(json.count).to eq 0
      end

      it "student can get definition with member visibility" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)
        resource_tool = new_valid_external_tool(account, true)
        resource_tool.settings[:resource_selection][:visibility] = "members"
        resource_tool.save!
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s, placements: %w[resource_selection] })

        expect(response).to have_http_status :ok
        expect(json.count).to eq 1
        expect(json.detect { |j| j["definition_type"] == resource_tool.class.name && j["definition_id"] == resource_tool.id }).not_to be_nil
      end

      it "student can get definition with public visibility" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)
        resource_tool = new_valid_external_tool(account, true)
        resource_tool.settings[:resource_selection][:visibility] = "public"
        resource_tool.save!
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s, placements: %w[resource_selection] })

        expect(response).to have_http_status :ok
        expect(json.count).to eq 1
        expect(json.detect { |j| j["definition_type"] == resource_tool.class.name && j["definition_id"] == resource_tool.id }).not_to be_nil
      end

      it "student can get definition for tool with unspecified visibility" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)
        resource_tool = new_valid_external_tool(account, true)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s, placements: %w[resource_selection] })

        expect(response).to have_http_status :ok
        expect(json.count).to eq 1
        expect(json.detect { |j| j["definition_type"] == resource_tool.class.name && j["definition_id"] == resource_tool.id }).not_to be_nil
      end

      it "public can get definition for tool with public visibility" do
        @course = create_course(active_all: true, account:)
        resource_tool = new_valid_external_tool(account, true)
        resource_tool.settings[:resource_selection][:visibility] = "public"
        resource_tool.save!
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s, placements: %w[resource_selection] })

        expect(response).to have_http_status :ok
        expect(json.count).to eq 1
        expect(json.detect { |j| j["definition_type"] == resource_tool.class.name && j["definition_id"] == resource_tool.id }).not_to be_nil
      end

      it "cannot get the definition of public stuff at the account level" do
        api_call(:get,
                 "/api/v1/accounts/self/lti_apps/launch_definitions",
                 { controller: "lti/lti_apps", action: "launch_definitions", format: "json", account_id: "self", placements: %w[global_navigation] })
        expect(response).to have_http_status :unauthorized
      end

      it "public can not get definition for tool with members visibility" do
        @course = create_course(active_all: true, account:)
        resource_tool = new_valid_external_tool(account, true)
        resource_tool.settings[:resource_selection][:visibility] = "members"
        resource_tool.save!
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s, placements: %w[resource_selection] })

        expect(response).to have_http_status :ok
        expect(json.count).to eq 0
      end

      it "returns global_navigation launches for a student using account context" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)

        tool = new_valid_external_tool(@course.root_account)
        tool.global_navigation = {
          text: "Global Nav"
        }
        tool.save!

        json = api_call(:get,
                        "/api/v1/accounts/#{account.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", account_id: account.id.to_param, format: "json" },
                        placements: ["global_navigation"])

        expect(response).to have_http_status :ok
        expect(json.count).to eq 1
        expect(json.first["definition_id"]).to eq tool.id
        # expect(json.detect {|j| j.key?('name') && j.key?('domain')}).not_to be_nil
      end

      describe "student visiblity of global_navigation launches" do
        before do
          course_with_student(active_all: true, user: user_with_pseudonym, account:)

          @tool = new_valid_external_tool(@course.root_account)
          @tool.global_navigation = {
            text: "Global Nav",
            visibility: "admins"
          }
          @tool.save!
        end

        # Some tools like arc, gauge have visibility settings on global_navigation placements.
        # For global_navigation we want to return all the launches, even if we are unsure what
        # visibility the user should have access to.
        it "returns global_navigation launches for a student even when visibility should not allow it" do
          json = api_call(:get,
                          "/api/v1/accounts/#{account.id}/lti_apps/launch_definitions",
                          { controller: "lti/lti_apps", action: "launch_definitions", account_id: account.id.to_param, format: "json" },
                          placements: ["global_navigation"])

          expect(response).to have_http_status :ok
          expect(json.count).to eq 1
          expect(json.first["definition_id"]).to eq @tool.id
        end

        it "does not ignore visibility on global_navigation launches if only_visible is given" do
          json = api_call(:get,
                          "/api/v1/accounts/#{account.id}/lti_apps/launch_definitions?only_visible=true",
                          { controller: "lti/lti_apps", action: "launch_definitions", account_id: account.id.to_param, format: "json", only_visible: "true" },
                          placements: ["global_navigation"])

          expect(response).to have_http_status :ok
          expect(json).to be_empty
        end
      end

      it "includes additional information for global navigation placements" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)

        tool1 = new_valid_external_tool(account)
        tool1.description = "foo foo"
        tool1.domain = "foo.org"
        tool1.global_navigation = {
          text: "Foo",
          visibility: "members",
          icon_url: "http://example.com/foo.png"
        }
        tool1.save!

        tool2 = new_valid_external_tool(account)
        tool2.description = "baz baz"
        tool2.domain = "baz.egg"
        tool2.global_navigation = {
          text: "Baz",
          visibility: "members",
          icon_svg_path_64: "baz svg...",
          windowTarget: "_blank"
        }
        tool2.save!

        json = api_call(:get,
                        "/api/v1/accounts/#{account.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", account_id: account.to_param, format: "json" },
                        placements: ["global_navigation"])

        tool1_index = json.find_index { |j| j["definition_id"] == tool1.id }
        tool1_info = json[tool1_index]["placements"]["global_navigation"]
        expect(tool1_info["title"]).to eq "Foo"
        expect(tool1_info["icon_url"]).to eq "http://example.com/foo.png"
        expect(tool1_info["icon_svg_path_64"]).to be_nil
        expect(tool1_info["html_url"]).to eq "/accounts/#{account.id}/external_tools/#{tool1.id}?launch_type=global_navigation"

        tool2_index = json.find_index { |j| j["definition_id"] == tool2.id }
        tool2_info = json[tool2_index]["placements"]["global_navigation"]
        expect(tool2_info["title"]).to eq "Baz"
        expect(tool2_info["icon_url"]).to be_nil
        expect(tool2_info["icon_svg_path_64"]).to eq "baz svg..."
        uri = URI.parse(tool2_info["html_url"])
        expect(uri.path).to eq "/accounts/#{account.id}/external_tools/#{tool2.id}"
        expect(Rack::Utils.parse_nested_query(uri.query)).to eq({ "display" => "borderless", "launch_type" => "global_navigation" })
      end

      it "paginates the launch definitions" do
        5.times { |_| new_valid_external_tool(account) }
        course_with_teacher(active_all: true, user: user_with_pseudonym, account:)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions?per_page=3",
                        { controller: "lti/lti_apps",
                          action: "launch_definitions",
                          format: "json",
                          placements: Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS,
                          course_id: @course.id.to_s,
                          per_page: "3" })

        json_next = follow_pagination_link("next", {
                                             controller: "lti/lti_apps",
                                             action: "launch_definitions",
                                             format: "json",
                                             course_id: @course.id.to_s
                                           })
        expect(json.count).to eq 3
        expect(json_next.count).to eq 3
        json
      end
    end

    describe "#index" do
      subject { api_call(:get, "/api/v1/courses/#{@course.id}/lti_apps", params) }

      include_context "key_storage_helper"

      let(:params) do
        {
          controller: "lti/lti_apps",
          action: "index",
          format: "json",
          course_id: @course.id.to_s
        }
      end

      before do
        course_with_teacher(active_all: true, user: user_with_pseudonym, account:)
      end

      context "lti 1.1 and 2.0, and 1.3 tools" do
        let(:dev_key) { DeveloperKey.create! account: }
        let(:tool_config) { lti_tool_configuration_model(developer_key: dev_key) }
        let(:enable_binding) { dev_key.developer_key_account_bindings.first.update! workflow_state: "on" }
        let(:advantage_tool) do
          t = new_valid_external_tool(account)
          t.use_1_3 = true
          t.developer_key = dev_key
          t.save!
          t
        end

        before do
          @tp = create_tool_proxy
          @tp.bindings.create(context: account)
          @external_tool = new_valid_external_tool(account)
          enable_binding
          tool_config
          advantage_tool
        end

        it "returns a list of app definitions for a context" do
          expect(subject.select { |j| j["app_type"] == @tp.class.name && j["app_id"] == @tp.id.to_s }).not_to be_nil
          expect(subject.select { |j| j["app_type"] == @external_tool.class.name && j["app_id"] == @external_tool.id.to_s }).not_to be_nil
          expect(subject.select { |j| j["app_type"] == @advantage_tool.class.name && j["app_id"] == @advantage_tool.id.to_s }).not_to be_nil
        end

        context "with pagination limit request" do
          let(:params) { super().merge per_page: "3" }
          let(:json) { subject }
          let(:json_next) do
            follow_pagination_link("next", {
                                     controller: "lti/lti_apps",
                                     action: "index",
                                     format: "json",
                                     course_id: @course.id.to_s
                                   })
          end

          before { 5.times { |_| new_valid_external_tool(account) } }

          it "paginates the launch definitions" do
            expect(subject.count).to eq 3
            expect(json_next.count).to eq 3
            json
          end
        end
      end
    end

    describe "#index on root account" do
      subject { api_call(:get, "/api/v1/accounts/#{account.id}/lti_apps", params) }

      let(:tool) { new_valid_external_tool(account, true) }
      let(:params) do
        {
          controller: "lti/lti_apps",
          action: "index",
          format: "json",
          account_id: account.id
        }
      end

      it "includes is_rce_favorite when applicable" do
        account_admin_user(account:)
        tool.editor_button = { url: "http://example.com", icon_url: "http://example.com" }
        tool.is_rce_favorite = true
        tool.save!
        expect(subject[0]["is_rce_favorite"]).to be true
      end

      it "does not include is_rce_favorite when not applicable" do
        account_admin_user(account:)
        tool
        expect(subject[0]).not_to have_key("is_rce_favorite")
      end
    end
  end
end
