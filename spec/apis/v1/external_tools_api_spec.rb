# frozen_string_literal: true

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

require "apis/api_spec_helper"

require "nokogiri"

describe ExternalToolsController, type: :request do
  describe "in a course" do
    before(:once) do
      course_with_teacher(active_all: true, user: user_with_pseudonym)
      @group = group_model(context: @course)
    end

    it "shows an external tool" do
      show_call(@course)
    end

    it "shows prefer_sis_email when saved in settings" do
      et = tool_with_everything(@course, allow_membership_service_access: true)
      et.settings = { "prefer_sis_email" => "true" }
      et.save
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/external_tools/#{et.id}.json",
                      { controller: "external_tools",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        external_tool_id: et.id.to_s })
      expect(json["prefer_sis_email"]).to eq "true"
    end

    it "includes allow_membership_service_access if feature flag enabled" do
      allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
      allow_any_instance_of(Account).to receive(:feature_enabled?).with(:membership_service_for_lti_tools).and_return(true)
      et = tool_with_everything(@course, allow_membership_service_access: true)
      json = api_call(:get,
                      "/api/v1/courses/#{@course.id}/external_tools/#{et.id}.json",
                      { controller: "external_tools",
                        action: "show",
                        format: "json",
                        course_id: @course.id.to_s,
                        external_tool_id: et.id.to_s })
      expect(json["allow_membership_service_access"]).to be true
    end

    it "returns 404 for not found tool" do
      not_found_call(@course)
    end

    it "returns external tools" do
      index_call(@course)
    end

    it "returns filtered external tools" do
      index_call_with_placement(@course, "collaboration")
    end

    it "searches for external tools by name" do
      search_call(@course)
    end

    it "only finds selectable tools" do
      only_selectables(@course)
    end

    it "creates an external tool" do
      create_call(@course)
    end

    it "updates an external tool" do
      update_call(@course)
    end

    it "destroys an external tool" do
      destroy_call(@course)
    end

    it "gives errors for required properties that aren't included" do
      error_call(@course)
    end

    it "gives authorized response" do
      course_with_student_logged_in(active_all: true, course: @course, name: "student")
      authorized_call(@course)
    end

    it "paginates" do
      paginate_call(@course)
    end

    if Canvas.redis_enabled?

      describe "sessionless launch" do
        let(:tool) { tool_with_everything(@course) }

        it "allows sessionless launches by url" do
          response = sessionless_launch(@course, { url: tool.url })
          expect(response.code).to eq "200"

          doc = Nokogiri::HTML5(response.body)
          expect(doc.at_css("form")).not_to be_nil
          expect(doc.at_css("form")["action"]).to eq tool.url
        end

        it "allows sessionless launches by tool id" do
          response = sessionless_launch(@course, { id: tool.id.to_s })
          expect(response.code).to eq "200"

          doc = Nokogiri::HTML5(response.body)
          expect(doc.at_css("form")).not_to be_nil
          expect(doc.at_css("form")["action"]).to eq tool.url
        end

        it "returns 401 if the user is not authorized for the course" do
          user_with_pseudonym
          params = { id: tool.id.to_s }
          code = get_raw_sessionless_launch_url(@course, params)
          expect(code).to eq 401
        end

        it "returns a service unavailable if redis isn't available" do
          allow(Canvas).to receive(:redis_enabled?).and_return(false)
          params = { id: tool.id.to_s }
          code = get_raw_sessionless_launch_url(@course, params)
          expect(code).to eq 503
          json = JSON.parse(response.body)
          expect(json["errors"]["redis"].first["message"]).to eq "Redis is not enabled, but is required for sessionless LTI launch"
        end

        context "assessment launch" do
          before do
            allow(BasicLTI::Sourcedid).to receive(:encryption_secret) { "encryption-secret-5T14NjaTbcYjc4" }
            allow(BasicLTI::Sourcedid).to receive(:signing_secret) { "signing-secret-vp04BNqApwdwUYPUI" }
          end

          it "returns a bad request response if there is no assignment_id" do
            params = { id: tool.id.to_s, launch_type: "assessment" }
            code = get_raw_sessionless_launch_url(@course, params)
            expect(code).to eq 400
            json = JSON.parse(response.body)
            expect(json["errors"]["assignment_id"].first["message"]).to eq "An assignment id must be provided for assessment LTI launch"
          end

          it "returns a not found response if the assignment is not found in the class" do
            params = { id: tool.id.to_s, launch_type: "assessment", assignment_id: -1 }
            code = get_raw_sessionless_launch_url(@course, params)
            expect(code).to eq 404
            json = JSON.parse(response.body)
            expect(json["errors"].first["message"]).to eq "The specified resource does not exist."
          end

          it "returns an unauthorized response if the user can't read the assignment" do
            assignment_model(course: @course, name: "tool assignment", submission_types: "external_tool", points_possible: 20, grading_type: "points")
            tag = @assignment.build_external_tool_tag(url: tool.url)
            tag.content_type = "ContextExternalTool"
            tag.save!
            @assignment.unpublish
            student_in_course(course: @course)
            params = { id: tool.id.to_s, launch_type: "assessment", assignment_id: @assignment.id }
            code = get_raw_sessionless_launch_url(@course, params)
            expect(code).to eq 401
          end

          it "returns a bad request if the assignment doesn't have an external_tool_tag" do
            assignment = @course.assignments.create!(
              title: "published assignemnt",
              submission_types: "online_url"
            )
            params = { id: tool.id.to_s, launch_type: "assessment", assignment_id: assignment.id }
            code = get_raw_sessionless_launch_url(@course, params)
            expect(code).to eq 400
            json = JSON.parse(response.body)
            expect(json["errors"]["assignment_id"].first["message"]).to eq "The assignment must have an external tool tag"
          end

          it "returns a sessionless launch url" do
            assignment_model(course: @course, name: "tool assignment", submission_types: "external_tool", points_possible: 20, grading_type: "points")
            tag = @assignment.build_external_tool_tag(url: tool.url)
            tag.content_type = "ContextExternalTool"
            tag.save!
            params = { id: tool.id.to_s, launch_type: "assessment", assignment_id: @assignment.id }
            sessionless_launch(@course, params)
            expect(response).to have_http_status :ok
          end

          it "returns sessionless launch URL when default URL is not set and placement URL is" do
            tool.update!(url: nil)
            params = { id: tool.id.to_s, launch_type: "course_navigation" }
            sessionless_launch(@course, params)
            expect(response).to have_http_status :ok
          end

          it "returns sessionless launch URL for an assignment launch no URL is set on the tool" do
            tool = @course.context_external_tools.create!(
              name: "Example Tool",
              consumer_key: "fakefake",
              shared_secret: "sofakefake",
              domain: "example.com"
            )
            assignment = assignment_model(
              course: @course,
              name: "tool assignment",
              submission_types: "external_tool",
              points_possible: 20,
              grading_type: "points"
            )
            assignment.create_external_tool_tag!(
              url: "http://www.example.com/ims/lti",
              content_type: "ContextExternalTool",
              content_id: tool.id
            )
            params = { id: tool.id.to_s, launch_type: "assessment", assignment_id: @assignment.id }
            json = get_sessionless_launch_url(@course, params)
            expect(json["url"]).to include(course_external_tools_sessionless_launch_url(@course))
          end

          it "returns a json error if there is no matching tool" do
            params = { url: "http://my_non_esisting_tool_domain.com", id: -1 }
            json = get_sessionless_launch_url(@course, params)
            expect(json["errors"]["external_tool"]).to eq "Unable to find a matching external tool"
          end
        end

        it "returns a bad request response if there is no tool_id or url" do
          params = {}
          code = get_raw_sessionless_launch_url(@course, params)
          expect(code).to eq 400
          json = JSON.parse(response.body)
          expect(json["errors"]["id"].first["message"]).to eq "A tool id, tool url, module item id, or resource link lookup uuid must be provided"
          expect(json["errors"]["url"].first["message"]).to eq "A tool id, tool url, module item id, or resource link lookup uuid must be provided"
        end
      end
    end

    describe "in a group" do
      it "returns course level external tools" do
        group_index_call(@group)
      end

      it "paginates" do
        group_index_paginate_call(@group)
      end
    end
  end

  describe "in an account" do
    before(:once) do
      account_admin_user(active_all: true, user: user_with_pseudonym)
      @account = @user.account
      @group = group_model(context: @account)
    end

    it "shows an external tool" do
      show_call(@account)
    end

    it "returns 404 for not found tool" do
      not_found_call(@account)
    end

    it "returns external tools" do
      index_call(@account)
    end

    it "searches for external tools by name" do
      search_call(@account)
    end

    it "only finds selectable tools" do
      only_selectables(@account)
    end

    it "creates an external tool" do
      create_call(@account)
    end

    it "updates an external tool" do
      update_call(@account)
    end

    it "destroys an external tool" do
      destroy_call(@account)
    end

    it "gives unauthorized response" do
      course_with_student_logged_in(active_all: true, name: "student")
      unauthorized_call(@account)
    end

    it "paginates" do
      paginate_call(@account)
    end

    describe "with environment-specific overrides" do
      subject do
        api_call(:get,
                 "/api/v1/accounts/#{@account.id}/external_tools/#{tool.id}.json",
                 { controller: "external_tools",
                   action: "show",
                   format: "json",
                   account_id: @account.id.to_s,
                   external_tool_id: tool.id.to_s })
      end

      let(:icon_url) { "https://www.example.com/lti/icon" }
      let(:tool) do
        t = tool_with_everything(@account)
        t.icon_url = icon_url
        t.domain = "www.example.com"
        t.settings[:editor_button][:icon_url] = icon_url
        t.save!
        t
      end
      let(:expected_json) do
        json = example_json(tool)
        json["icon_url"] = icon_url
        json["editor_button"]["icon_url"] = icon_url
        json
      end

      before do
        allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")
        allow(Setting).to receive(:set).with("allow_tc_access_").and_return("true")
      end

      let(:domain) { "www.example-beta.com" }

      def expect_domain_override(url)
        expect(url).to include(domain)
      end

      def expect_no_override(url)
        expect(url).not_to include(domain)
      end

      context "with domain override" do
        let(:override_icon_url) { "https://www.example-beta.com/lti/icon" }
        let(:tool) do
          t = super()
          t.settings[:environments] = {
            domain:
          }
          t.save!
          t
        end

        it "overrides base icon_url" do
          expect_domain_override(subject["icon_url"])
        end

        it "overrides placement icon_url" do
          expect_domain_override(subject.dig("editor_button", "icon_url"))
        end

        it "overrides placement url" do
          expect_domain_override(subject.dig("editor_button", "url"))
        end

        it "overrides url" do
          expect_domain_override(subject["url"])
        end

        it "overrides domain" do
          expect_domain_override(subject["domain"])
        end
      end

      context "with launch_url override" do
        let(:override_url) { "https://www.example-beta.com/lti/launch" }
        let(:tool) do
          t = super()
          t.settings[:environments] = {
            launch_url: override_url
          }
          t.save!
          t
        end

        it "overrides url" do
          expect(subject["url"]).to eq override_url
        end

        it "does not override placement url" do
          expect_no_override(subject.dig("editor_button", "url"))
        end

        it "does not override placement icon_url" do
          expect_no_override(subject.dig("editor_button", "icon_url"))
        end

        it "does not override icon url" do
          expect_no_override(subject["icon_url"])
        end

        it "does not override domain" do
          expect_no_override(subject["domain"])
        end
      end
    end

    if Canvas.redis_enabled?
      describe "sessionless launch" do
        let(:tool) { tool_with_everything(@account) }

        it "allows sessionless launches by url" do
          response = sessionless_launch(@account, { url: tool.url })
          expect(response.code).to eq "200"

          doc = Nokogiri::HTML5(response.body)
          expect(doc.at_css("form")).not_to be_nil
          expect(doc.at_css("form")["action"]).to eq tool.url
        end

        it "allows sessionless launches by tool id" do
          response = sessionless_launch(@account, { id: tool.id.to_s })
          expect(response.code).to eq "200"

          doc = Nokogiri::HTML5(response.body)
          expect(doc.at_css("form")).not_to be_nil
          expect(doc.at_css("form")["action"]).to eq tool.url
        end
      end
    end

    describe "in a group" do
      it "returns account level external tools" do
        group_index_call(@group)
      end
    end
  end

  context "rce favoriting" do
    def create_editor_tool(account)
      ContextExternalTool.create!(
        context: account,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        editor_button: { url: "http://example.com", icon_url: "http://example.com" }
      )
    end

    describe "#add_rce_favorite" do
      before :once do
        @root_tool = create_editor_tool(Account.default)
        @sub_account = Account.default.sub_accounts.create!
        @sub_tool = create_editor_tool(@sub_account)
        account_admin_user(active_all: true)
      end

      def add_favorite_tool(account, tool)
        json = api_call(:post,
                        "/api/v1/accounts/#{account.id}/external_tools/rce_favorites/#{tool.id}",
                        { controller: "external_tools",
                          action: "add_rce_favorite",
                          format: "json",
                          account_id: account.id.to_s,
                          id: tool.id.to_s },
                        {},
                        {},
                        { expected_status: 200 })
        account.reload
        json
      end

      it "requires authorization" do
        student_in_course(active_all: true)
        @user = @student
        api_call(:post,
                 "/api/v1/accounts/#{Account.default.id}/external_tools/rce_favorites/#{@root_tool.id}",
                 { controller: "external_tools",
                   action: "add_rce_favorite",
                   format: "json",
                   account_id: Account.default.id.to_s,
                   id: @root_tool.id.to_s },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "requires a tool in the context" do
        api_call(:post,
                 "/api/v1/accounts/#{Account.default.id}/external_tools/rce_favorites/#{@sub_tool.id}",
                 { controller: "external_tools",
                   action: "add_rce_favorite",
                   format: "json",
                   account_id: Account.default.id.to_s,
                   id: @sub_tool.id.to_s },
                 {},
                 {},
                 { expected_status: 404 })
      end

      it "doesn't allow adding too many tools" do
        tool2 = create_editor_tool(Account.default)
        tool3 = create_editor_tool(Account.default)
        Account.default.tap do |ra|
          ra.settings[:rce_favorite_tool_ids] = { value: [tool2.global_id, tool3.global_id] }
          ra.save!
        end

        json = api_call(:post,
                        "/api/v1/accounts/#{Account.default.id}/external_tools/rce_favorites/#{@root_tool.id}",
                        { controller: "external_tools",
                          action: "add_rce_favorite",
                          format: "json",
                          account_id: Account.default.id.to_s,
                          id: @root_tool.id.to_s },
                        {},
                        {},
                        { expected_status: 400 })
        expect(json["message"]).to eq "Cannot have more than 2 favorited tools"
      end

      describe "handling deleted tools" do
        before do
          @tool2 = create_editor_tool(Account.default)
          @tool3 = create_editor_tool(Account.default)
          Account.default.tap do |ra|
            ra.settings[:rce_favorite_tool_ids] = { value: [@tool2.global_id, @tool3.global_id] }
            ra.save!
          end
        end

        it "handles adding a favorite after a previous tool is deleted" do
          @tool3.destroy
          add_favorite_tool(Account.default, @root_tool) # can add it now because the other reference is invalid
        end

        it "uses Lti::ContextToolFinder to return tools and can handle global ids" do
          scope_union_double = instance_double(Lti::ScopeUnion)
          expect(Lti::ContextToolFinder).to receive(:new).and_return(
            instance_double(Lti::ContextToolFinder, all_tools_scope_union: scope_union_double)
          )
          expect(scope_union_double).to receive(:pluck).with(:id).and_return([@tool2.global_id])

          add_favorite_tool(Account.default, @root_tool) # can add it now because the other reference is invalid
        end
      end

      it "adds to existing favorites configured with old column if not specified on account" do
        @root_tool.update_attribute(:is_rce_favorite, true)
        tool2 = create_editor_tool(Account.default)
        add_favorite_tool(Account.default, tool2)
        expect(@root_tool.is_rce_favorite_in_context?(Account.default)).to be true
        expect(tool2.is_rce_favorite_in_context?(Account.default)).to be true
      end

      it "can add a root account tool as a favorite for a sub-account" do
        add_favorite_tool(@sub_account, @root_tool)
        expect(@root_tool.is_rce_favorite_in_context?(@sub_account)).to be true
        expect(@root_tool.is_rce_favorite_in_context?(Account.default)).to be false # didn't affect parent account
      end

      it "adds to existing favorites for a sub-account inherited from a root account" do
        add_favorite_tool(Account.default, @root_tool)
        add_favorite_tool(@sub_account, @sub_tool)

        expect(@root_tool.is_rce_favorite_in_context?(@sub_account)).to be true # now saved directly on sub-account
        expect(@sub_tool.is_rce_favorite_in_context?(@sub_account)).to be true
      end
    end

    describe "#remove_rce_favorite" do
      before :once do
        @root_tool = create_editor_tool(Account.default)
        @sub_account = Account.default.sub_accounts.create!
        @sub_tool = create_editor_tool(@sub_account)
        account_admin_user(active_all: true)
      end

      def remove_favorite_tool(account, tool)
        json = api_call(:delete,
                        "/api/v1/accounts/#{account.id}/external_tools/rce_favorites/#{tool.id}",
                        { controller: "external_tools",
                          action: "remove_rce_favorite",
                          format: "json",
                          account_id: account.id.to_s,
                          id: tool.id.to_s },
                        {},
                        {},
                        { expected_status: 200 })
        account.reload
        json
      end

      it "requires authorization" do
        student_in_course(active_all: true)
        @user = @student
        api_call(:delete,
                 "/api/v1/accounts/#{Account.default.id}/external_tools/rce_favorites/#{@root_tool.id}",
                 { controller: "external_tools",
                   action: "remove_rce_favorite",
                   format: "json",
                   account_id: Account.default.id.to_s,
                   id: @root_tool.id.to_s },
                 {},
                 {},
                 { expected_status: 401 })
      end

      it "works with existing favorites configured with old column if not specified on account" do
        @root_tool.update_attribute(:is_rce_favorite, true)
        tool2 = create_editor_tool(Account.default)
        tool2.update_attribute(:is_rce_favorite, true)
        remove_favorite_tool(Account.default, @root_tool)
        expect(Account.default.reload.settings[:rce_favorite_tool_ids][:value]).to eq [tool2.global_id] # saves it onto the account
      end

      it "removes from sub-account favorites inherited from a root account" do
        root_tool2 = create_editor_tool(Account.default)
        Account.default.tap do |ra|
          ra.settings[:rce_favorite_tool_ids] = { value: [@root_tool.global_id, root_tool2.global_id] }
          ra.save!
        end

        remove_favorite_tool(@sub_account, @root_tool)
        expect(@sub_account.settings[:rce_favorite_tool_ids][:value]).to eq [root_tool2.global_id]
      end
    end
  end

  def show_call(context)
    type = context.class.table_name
    et = tool_with_everything(context)
    json = api_call(:get,
                    "/api/v1/#{type}/#{context.id}/external_tools/#{et.id}.json",
                    { controller: "external_tools",
                      action: "show",
                      format: "json",
                      "#{type.singularize}_id": context.id.to_s,
                      external_tool_id: et.id.to_s })
    expect(json).to eq example_json(et)
  end

  def not_found_call(context)
    type = context.class.table_name
    raw_api_call(:get,
                 "/api/v1/#{type}/#{context.id}/external_tools/0.json",
                 { controller: "external_tools",
                   action: "show",
                   format: "json",
                   "#{type.singularize}_id": context.id.to_s,
                   external_tool_id: "0" })
    assert_status(404)
  end

  def group_index_call(group)
    et = tool_with_everything(group.context)

    json = api_call(:get,
                    "/api/v1/groups/#{group.id}/external_tools?include_parents=true",
                    { controller: "external_tools",
                      action: "index",
                      format: "json",
                      group_id: group.id.to_s,
                      include_parents: true })

    expect(json.size).to eq 1
    expect(json.first).to eq example_json(et)
  end

  def group_index_paginate_call(group)
    7.times { tool_with_everything(group.context) }

    json = api_call(:get,
                    "/api/v1/groups/#{group.id}/external_tools",
                    { controller: "external_tools",
                      action: "index",
                      format: "json",
                      group_id: group.id.to_s,
                      include_parents: true,
                      per_page: "3" })

    expect(json.length).to eq 3
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/groups/#{group.id}/external_tools} }).to be_truthy
    expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3/)

    # get the last page
    json = api_call(:get,
                    "/api/v1/groups/#{group.id}/external_tools",
                    { controller: "external_tools",
                      action: "index",
                      format: "json",
                      group_id: group.id.to_s,
                      include_parents: true,
                      per_page: "3",
                      page: "3" })

    expect(json.length).to eq 1
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/groups/#{group.id}/external_tools} }).to be_truthy
    expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3/)
  end

  def index_call(context)
    type = context.class.table_name
    et = tool_with_everything(context)

    json = api_call(:get,
                    "/api/v1/#{type}/#{context.id}/external_tools.json",
                    { controller: "external_tools",
                      action: "index",
                      format: "json",
                      "#{type.singularize}_id": context.id.to_s })

    expect(json.size).to eq 1
    expect(json.first).to eq example_json(et)
  end

  def index_call_with_placement(context, placement)
    type = context.class.table_name
    tool_with_everything(context).update(name: "tool 1")
    et_with_placement = tool_with_everything(context, { placement: })

    json = api_call(:get,
                    "/api/v1/#{type}/#{context.id}/external_tools.json",
                    { controller: "external_tools",
                      action: "index",
                      format: "json",
                      placement:,
                      "#{type.singularize}_id": context.id.to_s })

    expect(json.size).to eq 1
    expect(json.first).to eq example_json(et_with_placement)
  end

  def search_call(context)
    type = context.class.table_name
    2.times { |i| context.context_external_tools.create!(name: "first_#{i}", consumer_key: "fakefake", shared_secret: "sofakefake", url: "http://www.example.com/ims/lti") }
    ids = context.context_external_tools.map(&:id)

    2.times { |i| context.context_external_tools.create!(name: "second_#{i}", consumer_key: "fakefake", shared_secret: "sofakefake", url: "http://www.example.com/ims/lti") }

    json = api_call(:get,
                    "/api/v1/#{type}/#{context.id}/external_tools.json?search_term=fir",
                    { controller: "external_tools",
                      action: "index",
                      format: "json",
                      "#{type.singularize}_id": context.id.to_s,
                      search_term: "fir" })

    expect(json.pluck("id").sort).to eq ids.sort
  end

  def only_selectables(context)
    type = context.class.table_name
    context.context_external_tools.create!(name: "first", consumer_key: "fakefake", shared_secret: "sofakefake", url: "http://www.example.com/ims/lti", not_selectable: true)
    not_selectable = context.context_external_tools.create!(name: "second", consumer_key: "fakefake", shared_secret: "sofakefake", url: "http://www.example.com/ims/lti")

    json = api_call(:get,
                    "/api/v1/#{type}/#{context.id}/external_tools.json?selectable=true",
                    { controller: "external_tools",
                      action: "index",
                      format: "json",
                      "#{type.singularize}_id": context.id.to_s,
                      selectable: "true" })

    expect(json.length).to eq 1
    expect(json.first["id"]).to eq not_selectable.id
  end

  def create_call(context)
    type = context.class.table_name
    json = api_call(:post,
                    "/api/v1/#{type}/#{context.id}/external_tools.json",
                    { controller: "external_tools",
                      action: "create",
                      format: "json",
                      "#{type.singularize}_id": context.id.to_s },
                    post_hash)
    expect(context.context_external_tools.count).to eq 1

    et = context.context_external_tools.last
    expect(json).to eq example_json(et)
  end

  def update_call(context, successful: true)
    type = context.class.table_name
    et = context.context_external_tools.create!(name: "test", consumer_key: "fakefake", shared_secret: "sofakefake", url: "http://www.example.com/ims/lti")

    json = api_call(:put,
                    "/api/v1/#{type}/#{context.id}/external_tools/#{et.id}.json",
                    { controller: "external_tools",
                      action: "update",
                      format: "json",
                      "#{type.singularize}_id": context.id.to_s,
                      external_tool_id: et.id.to_s },
                    post_hash)
    et.reload
    expect(json).to eq example_json(et)
  end

  def destroy_call(context)
    type = context.class.table_name
    et = context.context_external_tools.create!(name: "test", consumer_key: "fakefake", shared_secret: "sofakefake", domain: "example.com")
    api_call(:delete,
             "/api/v1/#{type}/#{context.id}/external_tools/#{et.id}.json",
             { controller: "external_tools",
               action: "destroy",
               format: "json",
               "#{type.singularize}_id": context.id.to_s,
               external_tool_id: et.id.to_s })

    et.reload
    expect(et.workflow_state).to eq "deleted"
    expect(context.context_external_tools.active.count).to eq 0
  end

  def error_call(context)
    type = context.class.table_name
    raw_api_call(:post,
                 "/api/v1/#{type}/#{context.id}/external_tools.json",
                 { controller: "external_tools",
                   action: "create",
                   format: "json",
                   "#{type.singularize}_id": context.id.to_s },
                 {})
    json = JSON.parse response.body
    expect(response).to have_http_status :bad_request
    expect(json["errors"]["name"]).not_to be_nil
    expect(json["errors"]["shared_secret"]).not_to be_nil
    expect(json["errors"]["consumer_key"]).not_to be_nil
    expect(json["errors"]["url"].first["message"]).to eq "Either the url or domain should be set."
    expect(json["errors"]["domain"].first["message"]).to eq "Either the url or domain should be set."
  end

  def unauthorized_call(context)
    type = context.class.table_name
    raw_api_call(:get,
                 "/api/v1/#{type}/#{context.id}/external_tools.json",
                 { controller: "external_tools",
                   action: "index",
                   format: "json",
                   "#{type.singularize}_id": context.id.to_s })
    expect(response).to have_http_status :unauthorized
  end

  def authorized_call(context)
    type = context.class.table_name
    raw_api_call(:get,
                 "/api/v1/#{type}/#{context.id}/external_tools.json",
                 { controller: "external_tools",
                   action: "index",
                   format: "json",
                   "#{type.singularize}_id": context.id.to_s })
    expect(response).to have_http_status :ok
  end

  def paginate_call(context)
    type = context.class.table_name
    7.times { |i| context.context_external_tools.create!(name: "test_#{i}", consumer_key: "fakefake", shared_secret: "sofakefake", url: "http://www.example.com/ims/lti") }
    expect(context.context_external_tools.count).to eq 7
    json = api_call(:get,
                    "/api/v1/#{type}/#{context.id}/external_tools.json?per_page=3",
                    { controller: "external_tools", action: "index", format: "json", "#{type.singularize}_id": context.id.to_s, per_page: "3" })

    expect(json.length).to eq 3
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/#{type}/#{context.id}/external_tools} }).to be_truthy
    expect(links.find { |l| l.include?('rel="next"') }).to match(/page=2/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3/)

    # get the last page
    json = api_call(:get,
                    "/api/v1/#{type}/#{context.id}/external_tools.json?page=3&per_page=3",
                    { controller: "external_tools", action: "index", format: "json", "#{type.singularize}_id": context.id.to_s, per_page: "3", page: "3" })
    expect(json.length).to eq 1
    links = response.headers["Link"].split(",")
    expect(links.all? { |l| l =~ %r{api/v1/#{type}/#{context.id}/external_tools} }).to be_truthy
    expect(links.find { |l| l.include?('rel="prev"') }).to match(/page=2/)
    expect(links.find { |l| l.include?('rel="first"') }).to match(/page=1/)
    expect(links.find { |l| l.include?('rel="last"') }).to match(/page=3/)
  end

  def tool_with_everything(context, opts = {})
    et = context.context_external_tools.new
    et.name = opts[:name] || "External Tool Eh"
    et.description = "For testing stuff"
    et.consumer_key = "oi"
    et.shared_secret = "hoyt"
    et.not_selectable = true
    et.url = "http://www.example.com/ims/lti"
    et.workflow_state = "public"
    et.custom_fields = { key1: "val1", key2: "val2" }
    et.course_navigation = { :url => "http://www.example.com/ims/lti/course", :visibility => "admins", :text => "Course nav", "default" => "disabled" }
    et.account_navigation = { url: "http://www.example.com/ims/lti/account", text: "Account nav", custom_fields: { "key" => "value" } }
    et.user_navigation = { url: "http://www.example.com/ims/lti/user", text: "User nav" }
    et.editor_button = { url: "http://www.example.com/ims/lti/editor", icon_url: "/images/delete.png", selection_width: 50, selection_height: 50, text: "editor button" }
    et.homework_submission = { url: "http://www.example.com/ims/lti/editor", selection_width: 50, selection_height: 50, text: "homework submission" }
    et.resource_selection = { url: "http://www.example.com/ims/lti/resource", text: "", selection_width: 50, selection_height: 50 }
    et.migration_selection = { url: "http://www.example.com/ims/lti/resource", text: "migration selection", selection_width: 42, selection_height: 24 }
    et.course_home_sub_navigation = { url: "http://www.example.com/ims/lti/resource", text: "course home sub navigation", display_type: "full_width", visibility: "admins" }
    et.course_settings_sub_navigation = { url: "http://www.example.com/ims/lti/resource", text: "course settings sub navigation", display_type: "full_width", visibility: "admins" }
    et.global_navigation = { url: "http://www.example.com/ims/lti/resource", text: "global navigation", display_type: "full_width", visibility: "admins" }
    et.assignment_menu = { url: "http://www.example.com/ims/lti/resource", text: "assignment menu", display_type: "full_width", visibility: "admins" }
    et.assignment_index_menu = { url: "http://www.example.com/ims/lti/resource", text: "assignment index menu", display_type: "full_width", visibility: "admins" }
    et.assignment_group_menu = { url: "http://www.example.com/ims/lti/resource", text: "assignment group menu", display_type: "full_width", visibility: "admins" }
    et.discussion_topic_menu = { url: "http://www.example.com/ims/lti/resource", text: "discussion topic menu", display_type: "full_width", visibility: "admins" }
    et.discussion_topic_index_menu = { url: "http://www.example.com/ims/lti/resource", text: "discussion topic index menu", display_type: "full_width", visibility: "admins" }
    et.file_menu = { url: "http://www.example.com/ims/lti/resource", text: "file menu", display_type: "full_width", visibility: "admins" }
    et.file_index_menu = { url: "http://www.example.com/ims/lti/resource", text: "file index menu", display_type: "full_width", visibility: "admins" }
    et.module_menu = { url: "http://www.example.com/ims/lti/resource", text: "module menu", display_type: "full_width", visibility: "admins" }
    et.module_index_menu = { url: "http://www.example.com/ims/lti/resource", text: "modules index menu", display_type: "full_width", visibility: "admins" }
    et.module_index_menu_modal = { url: "http://www.example.com/ims/lti/resource", text: "modules index menu (modal)", display_type: "full_width", visibility: "admins" }
    et.module_group_menu = { url: "http://www.example.com/ims/lti/resource", text: "modules group menu", display_type: "full_width", visibility: "admins" }
    et.module_menu_modal = { url: "http://www.example.com/ims/lti/resource", text: "modules menu (modal)", display_type: "full_width", visibility: "admins" }
    et.quiz_menu = { url: "http://www.example.com/ims/lti/resource", text: "quiz menu", display_type: "full_width", visibility: "admins" }
    et.quiz_index_menu = { url: "http://www.example.com/ims/lti/resource", text: "quiz index menu", display_type: "full_width", visibility: "admins" }
    et.submission_type_selection = { url: "http://www.example.com/ims/lti/resource", text: "submission type selection", display_type: "full_width", visibility: "admins" }
    et.wiki_page_menu = { url: "http://www.example.com/ims/lti/resource", text: "wiki page menu", display_type: "full_width", visibility: "admins" }
    et.wiki_index_menu = { url: "http://www.example.com/ims/lti/resource", text: "wiki index menu", display_type: "full_width", visibility: "admins" }
    et.student_context_card = { url: "http://www.example.com/ims/lti/resource", text: "context card link", display_type: "full_width", visibility: "admins" }
    if context.is_a? Course
      et.course_assignments_menu = { url: "http://www.example.com/ims/lti/resource", text: "course assignments menu" }
    end
    et.context_external_tool_placements.new(placement_type: opts[:placement]) if opts[:placement]
    et.allow_membership_service_access = opts[:allow_membership_service_access] if opts[:allow_membership_service_access]
    et.conference_selection = { url: "http://www.example.com/ims/lti/conference", icon_url: "/images/delete.png", text: "conference selection" }
    et.save!
    et
  end

  def post_hash
    hash = example_json
    hash["shared_secret"] = "I will kill you if you tell"
    hash.delete "created_at"
    hash.delete "updated_at"
    hash.delete "id"
    hash.each_with_object({}) do |(key, val), result|
      unless val.is_a?(Hash)
        result[key] = val
        next
      end

      val.each_pair do |sub_key, sub_val|
        result["#{key}[#{sub_key}]"] = sub_val
      end
    end
  end

  def sessionless_launch(context, params)
    # initial api call
    json = get_sessionless_launch_url(context, params)
    expect(json).to include("url")

    # remove the user session (it's supposed to be sessionless, after all), and make the request
    remove_user_session

    # request/verify the lti launch page
    get json["url"]

    # sessionless launches now may include a session_token which logs in and then launches tool
    get response.location if response.location && response.code.to_i == 302
    response
  end

  def get_sessionless_launch_url(context, params)
    type = context.class.table_name
    api_call(
      :get,
      "/api/v1/#{type}/#{context.id}/external_tools/sessionless_launch?#{params.map { |k, v| "#{k}=#{v}" }.join("&")}",
      { controller: "external_tools", action: "generate_sessionless_launch", format: "json", "#{type.singularize}_id": context.id.to_s }.merge(params)
    )
  end

  def get_raw_sessionless_launch_url(context, params)
    type = context.class.table_name
    raw_api_call(
      :get,
      "/api/v1/#{type}/#{@course.id}/external_tools/sessionless_launch?#{params.map { |k, v| "#{k}=#{v}" }.join("&")}",
      { controller: "external_tools", action: "generate_sessionless_launch", format: "json", "#{type.singularize}_id": context.id.to_s }.merge(params)
    )
  end

  def example_json(et = nil)
    example = {
      "name" => "External Tool Eh",
      "created_at" => et ? et.created_at.as_json : "",
      "updated_at" => et ? et.updated_at.as_json : "",
      "consumer_key" => "oi",
      "domain" => nil,
      "url" => "http://www.example.com/ims/lti",
      "tool_configuration" => nil,
      "id" => et&.id,
      "not_selectable" => et&.not_selectable,
      "workflow_state" => "public",
      "vendor_help_link" => nil,
      "version" => "1.1",
      "deployment_id" => et&.deployment_id,
      "resource_selection" => {
        "enabled" => true,
        "text" => "",
        "url" => "http://www.example.com/ims/lti/resource",
        "selection_height" => 50,
        "selection_width" => 50,
        "label" => ""
      },
      "privacy_level" => "public",
      "editor_button" => {
        "enabled" => true,
        "icon_url" => "/images/delete.png",
        "text" => "editor button",
        "url" => "http://www.example.com/ims/lti/editor",
        "selection_height" => 50,
        "selection_width" => 50,
        "label" => "editor button"
      },
      "homework_submission" => {
        "enabled" => true,
        "text" => "homework submission",
        "url" => "http://www.example.com/ims/lti/editor",
        "selection_height" => 50,
        "selection_width" => 50,
        "label" => "homework submission"
      },
      "custom_fields" => { "key1" => "val1", "key2" => "val2" },
      "description" => "For testing stuff",
      "user_navigation" => {
        "enabled" => true,
        "text" => "User nav",
        "url" => "http://www.example.com/ims/lti/user",
        "label" => "User nav",
        "selection_height" => 400,
        "selection_width" => 800
      },
      "course_navigation" => {
        "enabled" => true,
        "text" => "Course nav",
        "url" => "http://www.example.com/ims/lti/course",
        "visibility" => "admins",
        "default" => "disabled",
        "label" => "Course nav",
        "selection_height" => 400,
        "selection_width" => 800
      },
      "account_navigation" => {
        "enabled" => true,
        "text" => "Account nav",
        "url" => "http://www.example.com/ims/lti/account",
        "custom_fields" => { "key" => "value" },
        "label" => "Account nav",
        "selection_height" => 400,
        "selection_width" => 800
      },
      "migration_selection" => {
        "enabled" => true,
        "text" => "migration selection",
        "label" => "migration selection",
        "url" => "http://www.example.com/ims/lti/resource",
        "selection_height" => 24,
        "selection_width" => 42
      },
      "course_home_sub_navigation" => {
        "enabled" => true,
        "text" => "course home sub navigation",
        "label" => "course home sub navigation",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "course_settings_sub_navigation" => {
        "enabled" => true,
        "text" => "course settings sub navigation",
        "label" => "course settings sub navigation",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "global_navigation" => {
        "enabled" => true,
        "text" => "global navigation",
        "label" => "global navigation",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "assignment_menu" => {
        "enabled" => true,
        "text" => "assignment menu",
        "label" => "assignment menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "assignment_index_menu" => {
        "enabled" => true,
        "text" => "assignment index menu",
        "label" => "assignment index menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "assignment_group_menu" => {
        "enabled" => true,
        "text" => "assignment group menu",
        "label" => "assignment group menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "discussion_topic_menu" => {
        "enabled" => true,
        "text" => "discussion topic menu",
        "label" => "discussion topic menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "discussion_topic_index_menu" => {
        "enabled" => true,
        "text" => "discussion topic index menu",
        "label" => "discussion topic index menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "file_menu" => {
        "enabled" => true,
        "text" => "file menu",
        "label" => "file menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "file_index_menu" => {
        "enabled" => true,
        "text" => "file index menu",
        "label" => "file index menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "module_menu" => {
        "enabled" => true,
        "text" => "module menu",
        "label" => "module menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "module_index_menu" => {
        "enabled" => true,
        "text" => "modules index menu",
        "label" => "modules index menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "module_group_menu" => {
        "enabled" => true,
        "text" => "modules group menu",
        "label" => "modules group menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "quiz_menu" => {
        "enabled" => true,
        "text" => "quiz menu",
        "label" => "quiz menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "quiz_index_menu" => {
        "enabled" => true,
        "text" => "quiz index menu",
        "label" => "quiz index menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "submission_type_selection" => {
        "enabled" => true,
        "text" => "submission type selection",
        "label" => "submission type selection",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "wiki_page_menu" => {
        "enabled" => true,
        "text" => "wiki page menu",
        "label" => "wiki page menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "student_context_card" => {
        "enabled" => true,
        "text" => "context card link",
        "label" => "context card link",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "wiki_index_menu" => {
        "enabled" => true,
        "text" => "wiki index menu",
        "label" => "wiki index menu",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "module_index_menu_modal" => {
        "enabled" => true,
        "text" => "modules index menu (modal)",
        "label" => "modules index menu (modal)",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "module_menu_modal" => {
        "enabled" => true,
        "text" => "modules menu (modal)",
        "label" => "modules menu (modal)",
        "url" => "http://www.example.com/ims/lti/resource",
        "visibility" => "admins",
        "display_type" => "full_width",
        "selection_height" => 400,
        "selection_width" => 800,
      },
      "link_selection" => nil,
      "assignment_selection" => nil,
      "post_grades" => nil,
      "collaboration" => nil,
      "similarity_detection" => nil,
      "assignment_edit" => nil,
      "assignment_view" => nil,
      # Add when conference_selection_lti_placement FF removed
      #  "conference_selection"=>
      #   {"icon_url"=>"/images/delete.png",
      #     "enabled"=>true,
      #     "text"=>"conference selection",
      #     "url"=>"http://www.example.com/ims/lti/conference",
      #     "label"=>"conference selection",
      #     "selection_height"=>400,
      #     "selection_width"=>800},
      "course_assignments_menu" => if et&.course_assignments_menu
                                     {
                                       "enabled" => true,
                                       "text" => "course assignments menu",
                                       "url" => "http://www.example.com/ims/lti/resource",
                                       "label" => "course assignments menu",
                                       "selection_width" => 800,
                                       "selection_height" => 400
                                     }
                                   end
    }
    example["is_rce_favorite"] = et.is_rce_favorite if et&.can_be_rce_favorite?
    example
  end
end
