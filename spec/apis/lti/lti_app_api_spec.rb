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
require_relative "../../lti_1_3_spec_helper"

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

      it "works for a teacher even without lti_add_edit permissions" do
        course_with_teacher(active_all: true, user: user_with_pseudonym, account:)
        account.role_overrides.create!(permission: "lti_add_edit", enabled: false, role: teacher_role)
        json = api_call(:get,
                        "/api/v1/courses/#{@course.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", format: "json", course_id: @course.id.to_s })
        expect(json.count).to eq 1
        expect(json.detect { |j| j["definition_type"] == @external_tool.class.name && j["definition_id"] == @external_tool.id }).not_to be_nil
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

      # Some tools like arc, gauge have visibility settings on global_navigation placements.
      # For global_navigation we want to return all the launches, even if we are unsure what
      # visibility the user should have access to.
      it "returns global_navigation launches for a student even when visibility should not allow it" do
        course_with_student(active_all: true, user: user_with_pseudonym, account:)

        tool = new_valid_external_tool(@course.root_account)
        tool.global_navigation = {
          text: "Global Nav",
          visibility: "admins"
        }
        tool.save!

        json = api_call(:get,
                        "/api/v1/accounts/#{account.id}/lti_apps/launch_definitions",
                        { controller: "lti/lti_apps", action: "launch_definitions", account_id: account.id.to_param, format: "json" },
                        placements: ["global_navigation"])

        expect(response).to have_http_status :ok
        expect(json.count).to eq 1
        expect(json.first["definition_id"]).to eq tool.id
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

      include_context "lti_1_3_spec_helper"

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
        let(:tool_config) { dev_key.create_tool_configuration! settings: }
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
