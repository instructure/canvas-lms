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

describe ContextExternalTool do
  before(:once) do
    @root_account = Account.default
    @account = account_model(root_account: @root_account, parent_account: @root_account)
    course_model(account: @account)
  end

  describe "associations and validations" do
    let_once(:developer_key) { DeveloperKey.create! }
    let_once(:lti_registration) { lti_registration_model }
    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        developer_key:,
        lti_version: "1.3",
        root_account: @root_account,
        lti_registration:
      )
    end

    it "allows setting the developer key" do
      expect(tool.developer_key).to eq developer_key
    end

    it "allows setting the root account" do
      expect(tool.root_account).to eq @root_account
    end

    it "belongs to an lti registration" do
      expect(tool.lti_registration).to eq lti_registration
    end

    describe "asset_processor_eula_required" do
      it "defaults null for new tools" do
        expect(tool.asset_processor_eula_required).to be_nil
      end

      it "can be updated" do
        tool.update!(asset_processor_eula_required: false)
        expect(tool.reload.asset_processor_eula_required).to be false
      end
    end
  end

  describe "available_in_context?" do
    let_once(:account) { account_model }
    let_once(:registration) do
      lti_developer_key_model(account:).tap do |k|
        lti_tool_configuration_model(account: k.account, developer_key: k, lti_registration: k.lti_registration)
      end.lti_registration
    end
    let_once(:tool) { registration.new_external_tool(account) }

    context "with the lti_registrations_next flag off" do
      before do
        account.disable_feature!(:lti_registrations_next)
      end

      it "returns true" do
        expect(tool.available_in_context?(account)).to be true
      end

      it "returns true even if the tool is not set to available" do
        tool.context_controls.first.update!(available: false)
        expect(tool.available_in_context?(account)).to be true
      end
    end

    it "returns true for 1.1 tools" do
      lti_1_1_tool = external_tool_model(context: account)
      expect(lti_1_1_tool.available_in_context?(account)).to be true
    end

    it "returns true if the tool is set to available" do
      expect(tool.available_in_context?(account)).to be true
    end

    it "returns false if the tool is set to unavailable" do
      tool.context_controls.first.update!(available: false)

      expect(tool.available_in_context?(account)).to be false
    end

    it "ignores context controls associated with other tools from the same registration" do
      duplicate_tool = registration.new_external_tool(account)
      duplicate_tool.context_controls.first.update!(available: false)

      expect(tool.available_in_context?(account)).to be true
    end

    it "sends an error to sentry if no context control is found" do
      tool.context_controls.destroy_all

      sentry_scope = double(Sentry::Scope)
      expect(Sentry).to receive(:with_scope).and_yield(sentry_scope)
      expect(sentry_scope).to receive(:set_tags).with(context_id: account.global_id)
      expect(sentry_scope).to receive(:set_tags).with(lti_registration_id: tool.lti_registration.global_id)
      expect(sentry_scope).to receive(:set_context).with("tool", tool.global_id)

      expect(tool.available_in_context?(account)).to be true
    end
  end

  describe "#permission_given?" do
    subject { tool.permission_given?(launch_type, user, context) }

    let(:required_permission) { "some-permission" }
    let(:launch_type) { "some-launch-type" }
    let(:tool) do
      ContextExternalTool.create!(
        context: @root_account,
        name: "Requires Permission",
        consumer_key: "key",
        shared_secret: "secret",
        domain: "requires.permission.com",
        settings: {
          global_navigation: {
            "required_permissions" => required_permission,
            :text => "Global Navigation (permission checked)",
            :url => "http://requires.permission.com"
          },
          assignment_selection: {
            "required_permissions" => required_permission,
            :text => "Assignment selection",
            :url => "http://requires.permission.com"
          },
          course_navigation: {
            text: "Course Navigation",
            url: "https://doesnot.requirepermission.com"
          }
        }
      )
    end
    let(:course) { course_with_teacher(account: @root_account).context }
    let(:user) { course.teachers.first }
    let(:context) { course }

    context "when the placement does not require a specific permission" do
      let(:launch_type) { "course_navigation" }

      it { is_expected.to be true }

      context "and the context is blank" do
        let(:launch_type) { "course_navigation" }
        let(:context) { nil }

        it { is_expected.to be true }
      end
    end

    context "when the placement does require a specific permission" do
      context "and the context is blank" do
        let(:required_permission) { "view_group_pages" }
        let(:launch_type) { "assignment_selection" }
        let(:context) { nil }

        it { is_expected.to be false }
      end

      context "and the user has the needed permission in the context" do
        let(:required_permission) { "view_group_pages" }
        let(:launch_type) { "assignment_selection" }

        it { is_expected.to be true }
      end

      context 'and the placement is "global_navigation"' do
        context "and the user has an enrollment with the needed permission" do
          let(:required_permission) { "view_group_pages" }
          let(:launch_type) { "global_navigation" }

          it { is_expected.to be true }
        end
      end
    end
  end

  describe "#global_navigation_tools" do
    subject do
      ContextExternalTool.filtered_global_navigation_tools(
        @root_account,
        granted_permissions
      )
    end

    let(:granted_permissions) do
      ContextExternalTool.global_navigation_granted_permissions(root_account: @root_account,
                                                                user: global_nav_user,
                                                                context: global_nav_context,
                                                                session: nil)
    end
    let(:global_nav_user) { nil }
    let(:global_nav_context) { nil }
    let(:required_permission) { "some-permission" }

    let!(:permission_required_tool) do
      ContextExternalTool.create!(
        context: @root_account,
        name: "Requires Permission",
        consumer_key: "key",
        shared_secret: "secret",
        domain: "requires.permission.com",
        settings: {
          global_navigation: {
            "required_permissions" => required_permission,
            :text => "Global Navigation (permission checked)",
            :url => "http://requires.permission.com"
          }
        }
      )
    end
    let!(:no_permission_required_tool) do
      ContextExternalTool.create!(
        context: @root_account,
        name: "No Requires Permission",
        consumer_key: "key",
        shared_secret: "secret",
        domain: "no.requires.permission.com",
        settings: {
          global_navigation: {
            text: "Global Navigation (no permission)",
            url: "http://no.requries.permission.com"
          }
        }
      )
    end

    context "when a user and context are provided" do
      let(:global_nav_user) { @course.teachers.first }
      let(:global_nav_context) { @course }

      context "when the current user has the required permission" do
        let(:required_permission) { "send_messages_all" }

        before { @course.update!(workflow_state: "created") }

        it { is_expected.to match_array [no_permission_required_tool, permission_required_tool] }
      end

      context "when the current user does not have the required permission" do
        it { is_expected.to match_array [no_permission_required_tool] }
      end
    end

    context "when a user and context are not provided" do
      let(:required_permission) { nil }

      it { is_expected.to match_array [no_permission_required_tool, permission_required_tool] }
    end
  end

  describe "#login_or_launch_url" do
    let_once(:developer_key) { DeveloperKey.create! }
    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        developer_key:
      )
    end

    it "returns the launch url" do
      expect(tool.login_or_launch_url).to eq tool.url
    end

    context "when a preferred_launch_url is specified" do
      let(:preferred_launch_url) { "https://www.test.com/tool-launch" }

      it "returns the preferred_launch_url" do
        expect(tool.login_or_launch_url(preferred_launch_url:)).to eq preferred_launch_url
      end
    end

    context "when the extension url is present" do
      let(:placement_url) { "http://www.test.com/editor_button" }

      before do
        tool.editor_button = {
          "url" => placement_url,
          "text" => "LTI 1.3 twoa",
          "enabled" => true,
          "icon_url" => "https://static.thenounproject.com/png/131630-200.png",
          "message_type" => "LtiDeepLinkingRequest",
          "canvas_icon_class" => "icon-lti"
        }
      end

      it "returns the extension url" do
        expect(tool.login_or_launch_url(extension_type: :editor_button)).to eq placement_url
      end
    end

    context "lti_1_3 tool" do
      let(:oidc_initiation_url) { "http://www.test.com/oidc/login" }

      before do
        tool.lti_version = "1.3"
        developer_key.update!(oidc_initiation_url:)
      end

      it "returns the oidc login url" do
        expect(tool.login_or_launch_url).to eq oidc_initiation_url
      end

      context "when the tool configuration has oidc_initiation_urls" do
        before do
          tool.settings["oidc_initiation_urls"] = {
            "us-west-2" => "http://www.test.com/oidc/login/oregon",
            "eu-west-1" => "http://www.test.com/oidc/login/ireland"
          }
        end

        it "returns the region-specific oidc login url" do
          allow(Shard.current.database_server).to receive(:config).and_return({ region: "eu-west-1" })
          expect(tool.login_or_launch_url).to eq "http://www.test.com/oidc/login/ireland"
        end

        it "falls back to the default oidc login url if there is none for the current region" do
          allow(Shard.current.database_server).to receive(:config).and_return({ region: "us-east-1" })
          expect(tool.login_or_launch_url).to eq "http://www.test.com/oidc/login"
        end

        context "when the developer key and active shard are different from the tool shard" do
          specs_require_sharding

          it "uses the tool shard for region" do
            shard1_tool = @shard1.activate do
              opts = {
                lti_version: 1.3,
                developer_key:,
                settings: {
                  "oidc_initiation_urls" => {
                    "us-west-2" => "http://www.test.com/oidc/login/oregon-tool2",
                    "eu-west-1" => "http://www.test.com/oidc/login/ireland-tool2"
                  }
                }
              }
              external_tool_model(context: account_model, opts:)
            end

            @shard2.activate do
              possible_shards = [developer_key.shard, shard1_tool.shard, Shard.current]
              expect(possible_shards.map(&:id).uniq.length).to eq(3)
              allow(shard1_tool.shard.database_server).to receive(:config).and_return({ region: "eu-west-1" })
              allow(Shard.current.database_server).to receive(:config).and_return({ region: "us-west-2" })
              expect(shard1_tool.login_or_launch_url).to eq "http://www.test.com/oidc/login/ireland-tool2"
            end
          end
        end
      end
    end
  end

  describe "#launch_url" do
    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch"
      )
    end

    it "returns the launch url" do
      expect(tool.launch_url).to eq tool.url
    end

    context "when a preferred_launch_url is specified" do
      let(:preferred_launch_url) { "https://www.test.com/tool-launch" }

      it "returns the preferred_launch_url" do
        expect(tool.launch_url(preferred_launch_url:)).to eq preferred_launch_url
      end
    end

    context "when the extension url is present" do
      let(:placement_url) { "http://www.test.com/editor_button" }

      before do
        tool.editor_button = {
          "url" => placement_url,
          "text" => "LTI 1.3 twoa",
          "enabled" => true,
          "icon_url" => "https://static.thenounproject.com/png/131630-200.png",
          "message_type" => "LtiDeepLinkingRequest",
          "canvas_icon_class" => "icon-lti"
        }
      end

      it "returns the extension url" do
        expect(tool.launch_url(extension_type: :editor_button)).to eq placement_url
      end
    end

    context "with a lti_1_3 tool" do
      before do
        tool.lti_version = "1.3"
      end

      context "when the extension target_link_uri is present" do
        let(:placement_url) { "http://www.test.com/editor_button" }

        before do
          tool.editor_button = {
            "target_link_uri" => placement_url,
            "text" => "LTI 1.3 twoa",
            "enabled" => true,
            "icon_url" => "https://static.thenounproject.com/png/131630-200.png",
            "message_type" => "LtiDeepLinkingRequest",
            "canvas_icon_class" => "icon-lti"
          }
        end

        it "returns the extension target_link_uri" do
          expect(tool.launch_url(extension_type: :editor_button)).to eq placement_url
        end
      end

      it "returns the launch url" do
        expect(tool.launch_url).to eq tool.url
      end
    end

    context "with environment-specific url overrides" do
      let(:override_url) { "http://www.test-beta.net/launch" }

      before do
        allow(tool).to receive(:url_with_environment_overrides).and_return(override_url)
      end

      it "returns the override url" do
        expect(tool.launch_url).to eq override_url
      end

      context "when the extension url is present" do
        let(:placement_url) { "http://www.test.com/editor_button" }
        let(:override_url) { "http://www.test-beta.net/editor_button" }

        before do
          tool.editor_button = {
            "url" => placement_url,
            "text" => "LTI 1.3 twoa",
            "enabled" => true,
            "icon_url" => "https://static.thenounproject.com/png/131630-200.png",
            "message_type" => "LtiDeepLinkingRequest",
            "canvas_icon_class" => "icon-lti"
          }
        end

        it "returns the extension url" do
          expect(tool.launch_url(extension_type: :editor_button)).to eq override_url
        end
      end
    end
  end

  describe "#url_with_environment_overrides" do
    subject { tool.url_with_environment_overrides(url, include_launch_url:) }

    let(:url) { "http://www.tool.com/launch" }
    let(:include_launch_url) { false }

    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url:
      )
    end

    before do
      allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")
      allow(tool).to receive(:use_environment_overrides?).and_return(true)
    end

    context "when prechecks do not pass" do
      before do
        allow(tool).to receive(:use_environment_overrides?).and_return(false)
      end

      it "does not override url" do
        expect(subject).to eq url
      end
    end

    context "when launch_url override is configured" do
      let(:override_url) { "http://www.test.com/override" }
      let(:include_launch_url) { true }

      before do
        tool.settings[:environments] = {
          launch_url: override_url
        }
      end

      it "returns the launch_url override" do
        expect(subject).to eq override_url
      end

      context "with base_url query string" do
        let(:url) { super() + "?hello=world" }

        it "includes the query string in returned url" do
          expect(subject).to eq override_url + "?hello=world"
        end
      end

      context "with launch_url query string" do
        let(:override_url) { super() + "?hello=world" }

        it "includes the query string in returned url" do
          expect(subject).to eq override_url
        end
      end

      context "with query strings on both urls" do
        let(:url) { super() + "?hello=world&test=this" }
        let(:override_url) { super() + "?hello=there" }

        it "merges both query strings in returned url" do
          expect(subject).to eq override_url + "&test=this"
        end
      end
    end

    context "when env_launch_url override is configured" do
      let(:override_url) { "http://www.test.com/override" }
      let(:beta_url) { "#{override_url}/beta" }
      let(:include_launch_url) { true }

      before do
        tool.settings[:environments] = {
          launch_url: override_url,
          beta_launch_url: beta_url
        }
      end

      it "prefers env_launch_url over launch_url" do
        expect(subject).to eq beta_url
      end
    end

    context "when domain override is configured" do
      let(:override_url) { "http://www.test-change.net/launch" }
      let(:override_domain) { "www.test-change.net" }

      before do
        tool.settings[:environments] = {
          domain: override_domain
        }
      end

      it "replaces the domain of launch_url with override" do
        expect(subject).to eq override_url
      end

      context "when domain includes protocol" do
        let(:override_domain) { "http://www.test-change.net" }

        it "replaces the domain with override" do
          expect(subject).to eq override_url
        end
      end

      context "when domain includes trailing slash" do
        let(:override_domain) { "www.test-change.net/" }

        it "replaces the domain with override" do
          expect(subject).to eq override_url
        end
      end
    end

    context "when env_domain override is configured" do
      let(:override_url) { "http://www.test-change.beta.net/launch" }
      let(:override_domain) { "www.test-change.net" }
      let(:beta_domain) { "www.test-change.beta.net" }

      before do
        tool.settings[:environments] = {
          domain: override_domain,
          beta_domain:
        }
      end

      it "replaces the domain of launch_url with override" do
        expect(subject).to eq override_url
      end
    end

    context "when both domain and launch_url override are configured" do
      let(:override_url) { "http://www.test-change.beta.net/launch" }
      let(:override_domain) { "www.test-change.net" }

      before do
        tool.settings[:environments] = {
          domain: override_domain,
          launch_url: override_url
        }
      end

      it "prefers domain override" do
        expect(subject).to eq "http://www.test-change.net/launch"
      end

      context "when include_launch_url is true" do
        let(:include_launch_url) { true }

        it "prefers url override over domain" do
          expect(subject).to eq override_url
        end
      end
    end

    # TODO: implement this behavior, both old and new don't account for it yet
    # context "when domain contains port" do
    #   let(:override_url) { "http://www.test-change.net:3001/launch" }
    #   let(:override_domain) { "www.test-change.net:3001" }
    #   let(:domain_with_port) { "localhost:3000" }
    #   let(:url) { "http://#{domain_with_port}/launch" }

    #   before do
    #     tool.domain = domain_with_port
    #     tool.url = url
    #     tool.settings[:environments] = {
    #       domain: override_domain
    #     }
    #     tool.save!
    #   end

    #   it "accounts for port when replacing" do
    #     expect(subject).to eq override_url
    #   end
    # end
  end

  describe "#domain_with_environment_overrides" do
    subject { tool.domain_with_environment_overrides }

    let(:domain) { "example.com" }
    let(:override_domain) { "beta.example.com" }

    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        domain:
      )
    end

    before do
      tool.settings[:environments] = { domain: override_domain }
      allow(tool).to receive(:use_environment_overrides?).and_return(true)
    end

    context "when prechecks do not pass" do
      before do
        allow(tool).to receive(:use_environment_overrides?).and_return(false)
      end

      it "returns base domain" do
        expect(subject).to eq domain
      end
    end

    context "when there is no environment override for domain" do
      before do
        tool.settings[:environments] = { launch_url: "https://example.com/test-launch" }
      end

      it "returns base domain" do
        expect(subject).to eq domain
      end
    end

    it "returns override domain" do
      expect(subject).to eq override_domain
    end
  end

  describe "#environment_overrides_for" do
    subject { tool.environment_overrides_for(key) }

    let(:key) { nil }
    let(:domain) { "test.example.com" }
    let(:beta_domain) { "beta.example.com" }
    let(:launch_url) { "https://example.com/test-launch" }
    let(:beta_launch_url) { "https://example.com/beta-launch" }

    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        domain: "example.com"
      )
    end

    before do
      tool.settings[:environments] = {}
      allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")
    end

    context "when key isn't valid" do
      let(:key) { :wrong }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when tool doesn't have override for key" do
      let(:key) { "domain" }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "domain override" do
      let(:key) { :domain }

      before do
        tool.settings[:environments][:domain] = domain
      end

      it "returns base domain override" do
        expect(subject).to eq domain
      end

      context "with env-specific override" do
        before do
          tool.settings[:environments][:beta_domain] = beta_domain
        end

        it "returns env-specific domain" do
          expect(subject).to eq beta_domain
        end
      end
    end

    context "launch_url override" do
      let(:key) { :launch_url }

      before do
        tool.settings[:environments][:launch_url] = launch_url
      end

      it "returns base launch_url override" do
        expect(subject).to eq launch_url
      end

      context "with env-specific override" do
        before do
          tool.settings[:environments][:beta_launch_url] = beta_launch_url
        end

        it "returns env-specific launch_url" do
          expect(subject).to eq beta_launch_url
        end
      end
    end
  end

  describe "#use_environment_overrides?" do
    subject { tool.use_environment_overrides? }

    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        domain: "example.com"
      )
    end

    before do
      tool.settings[:environments] = { domain: "beta.example.com" }
      allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")
    end

    context "in standard Canvas" do
      before do
        allow(ApplicationController).to receive(:test_cluster?).and_return(false)
      end

      it { is_expected.to be false }
    end

    context "with a lti_1_3 tool" do
      before do
        tool.lti_version = "1.3"
      end

      it { is_expected.to be false }
    end

    context "when tool does not have overrides configured" do
      before do
        tool.settings.delete :environments
      end

      it { is_expected.to be false }
    end

    it { is_expected.to be true }
  end

  describe "#deployment_id" do
    let_once(:tool) do
      ContextExternalTool.create!(
        id: 1,
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch"
      )
    end

    it "returns the correct deployment_id" do
      expect(tool.deployment_id).to eq "#{tool.id}:#{Lti::V1p1::Asset.opaque_identifier_for(tool.context)}"
    end

    it "sends only 255 chars" do
      allow(Lti::V1p1::Asset).to receive(:opaque_identifier_for).and_return("a" * 256)
      expect(tool.deployment_id.size).to eq 255
    end
  end

  describe "#matches_host?" do
    subject { tool.matches_host?(given_url, use_environment_overrides:) }

    let(:tool) { external_tool_model }
    let(:given_url) { "https://www.given-url.com/test?foo=bar" }
    let(:use_environment_overrides) { false }

    context "when the tool has a url and no domain" do
      let(:url) { "https://app.test.com/foo" }

      before do
        tool.update!(
          domain: nil,
          url:
        )
      end

      context "and the tool url host does not match that of the given url host" do
        it { is_expected.to be false }
      end

      context "and the tool url host matches that of the given url host" do
        let(:url) { "https://www.given-url.com/foo?foo=bar" }

        it { is_expected.to be true }
      end

      context "and the tool url host matches except for case" do
        let(:url) { "https://www.GiveN-url.cOm/foo?foo=bar" }

        it { is_expected.to be true }
      end

      context "and use_environment_overrides is true" do
        let(:use_environment_overrides) { true }
        let(:override_url) { "https://beta.app.test.com/foo" }

        before do
          allow(tool).to receive(:use_environment_overrides?).and_return(true)

          tool.settings[:environments] = { launch_url: override_url }
          tool.save!
        end

        context "and the override url host does not match the given url host" do
          it { is_expected.to be false }
        end

        context "and the override url host matches the given url host" do
          let(:given_url) { "https://beta.app.test.com/foo?foo=bar" }

          it { is_expected.to be true }
        end
      end
    end

    context "when the tool has a domain and no url" do
      let(:domain) { "app.test.com" }

      before do
        tool.update!(
          url: nil,
          domain:
        )
      end

      context "and the tool domain host does not match that of the given url host" do
        it { is_expected.to be false }

        context "and the tool url and given url are both nil" do
          let(:given_url) { nil }

          it { is_expected.to be false }
        end
      end

      context "and the tool domain host matches that of the given url host" do
        let(:domain) { "www.given-url.com" }

        it { is_expected.to be true }
      end

      context "and the tool domain matches except for case" do
        let(:domain) { "www.gIvEn-URL.cOm" }

        it { is_expected.to be true }
      end

      context "and the tool domain contains the protocol" do
        let(:domain) { "https://www.given-url.com" }

        it { is_expected.to be true }
      end

      context "and the domain and given URL contain a port" do
        let(:domain) { "localhost:3001" }
        let(:given_url) { "http://localhost:3001/link_location" }

        it { is_expected.to be true }
      end
    end
  end

  describe "#matches_tool_domain?" do
    it "escapes the tool domain" do
      tool = external_tool_model(opts: { domain: "foo.bar.com" })
      tool.save
      expect(tool.matches_tool_domain?("https://waz.fooxbar.com")).to be false
      expect(tool.matches_tool_domain?("https://waz.foo.bar.com")).to be true
    end
  end

  describe "#duplicated_in_context?" do
    shared_examples_for "detects duplication in contexts" do
      subject { second_tool.duplicated_in_context? }

      let(:context) { raise "Override in spec" }
      let(:second_tool) { tool.dup }
      let(:settings) do
        {
          "editor_button" => {
            "icon_url" => "http://www.example.com/favicon.ico",
            "text" => "Example",
            "url" => "http://www.example.com",
            "selection_height" => 400,
            "selection_width" => 600
          }
        }
      end
      let(:tool) do
        ContextExternalTool.create!(
          settings:,
          context:,
          name: "first tool",
          consumer_key: "key",
          shared_secret: "secret",
          url: "http://www.tool.com/launch"
        )
      end

      context "when url is not set" do
        let(:domain) { "instructure.com" }

        before { tool.update!(url: nil, domain:) }

        context "when no other tools are installed in the context" do
          it "does not count as duplicate" do
            expect(tool.duplicated_in_context?).to be false
          end
        end

        context "when a tool with matching domain is found" do
          it { is_expected.to be true }
        end

        context "when a tool with matching domain is found in different context" do
          before { second_tool.update!(context: course_model) }

          it { is_expected.to be false }
        end

        context "when a tool with matching domain is not found" do
          before { second_tool.domain = "different-domain.com" }

          it { is_expected.to be false }
        end
      end

      context "when no other tools are installed in the context" do
        it "does not count as duplicate" do
          expect(tool.duplicated_in_context?).to be false
        end
      end

      context "when a tool with matching settings and different URL is found" do
        before { second_tool.url << "/different/url" }

        it { is_expected.to be false }
      end

      context "when a tool with different settings and matching URL is found" do
        before { second_tool.settings[:different_key] = "different value" }

        it { is_expected.to be true }
      end

      context "when a tool with different settings and different URL is found" do
        before do
          second_tool.url << "/different/url"
          second_tool.settings[:different_key] = "different value"
        end

        it { is_expected.to be false }
      end

      context "when a tool with matching settings and matching URL is found" do
        it { is_expected.to be true }
      end
    end

    context "duplicated in account chain" do
      it_behaves_like "detects duplication in contexts" do
        let(:context) { account_model }
      end
    end

    context "duplicated in course" do
      it_behaves_like "detects duplication in contexts" do
        let(:context) { course_model }
      end
    end

    context "called from another shard" do
      specs_require_sharding

      it_behaves_like "detects duplication in contexts" do
        # Some of the specs would fail if ContextToolFinder doesn't translate IDs correctly,
        # so that tests that.
        subject do
          second_tool
          @shard2.activate { second_tool.duplicated_in_context? }
        end

        let(:context) { course_model }
      end
    end

    it "uses Lti::ContextToolFinder" do
      course = course_model
      tool = ContextExternalTool.create!(
        context: course,
        name: "first tool",
        consumer_key: "key",
        shared_secret: "secret",
        domain: "www.tool.com"
      )

      expect(Lti::ContextToolFinder).to receive(:all_tools_scope_union)
        .with(course, base_scope: anything)
        .and_return(Lti::ScopeUnion.new([ContextExternalTool.all]))
      expect(tool.duplicated_in_context?).to be(true)
    end
  end

  describe "#calculate_identity_hash" do
    it "calculates an identity hash" do
      tool = external_tool_model
      expect { tool.calculate_identity_hash }.not_to raise_error
      expect(tool.calculate_identity_hash).to be_a(String)
    end

    it "reordering settings creates the same identity_hash" do
      tool1 = external_tool_model(context: @course, opts: { name: "t", consumer_key: "12345", shared_secret: "secret", url: "http://google.com/launch_url" })
      tool1.update(settings: { selection_width: 100, selection_height: 100, icon_url: "http://www.example.com/favicon.ico" })

      tool2 = external_tool_model(context: @course, opts: { name: "t", consumer_key: "12345", shared_secret: "secret", url: "http://google.com/launch_url" })
      tool2.update(settings: { icon_url: "http://www.example.com/favicon.ico", selection_height: 100, selection_width: 100 })
      expect(tool1.calculate_identity_hash).to eq tool2.calculate_identity_hash
    end

    it "changing the settings creates a different identity_hash" do
      tool1 = external_tool_model(context: @course, opts: { name: "t", consumer_key: "12345", shared_secret: "secret", url: "http://google.com/launch_url" })
      tool1.update(settings: { selection_width: 100, selection_height: 100, icon_url: "http://www.example.com/favicon.ico" })

      tool2 = external_tool_model(context: @course, opts: { name: "t", consumer_key: "12345", shared_secret: "secret", url: "http://google.com/launch_url" })
      tool2.update(settings: { selection_width: 100, selection_height: 100 })
      expect(tool1.calculate_identity_hash).not_to eq tool2.calculate_identity_hash
    end
  end

  describe "add_identity_hash" do
    it "adds 'duplicate' as the identity_hash if another tool already exists with that hash" do
      external_tool_model(context: @course)
      tool2 = external_tool_model(context: @course)
      expect(tool2.identity_hash).to eq "duplicate"
    end

    it "doesn't recalculate the identity field if none of the important fields have changed" do
      tool = external_tool_model
      ident_hash = tool.identity_hash
      expect(tool).not_to receive(:calculate_identity_hash)
      tool.update(updated_at: Time.zone.now)
      expect(tool.identity_hash).to eq ident_hash
    end

    it "does recalculate the identity field if one of the important fields has changed" do
      tool = external_tool_model
      ident_hash = tool.identity_hash
      expect(tool).to receive(:calculate_identity_hash)
      tool.update(name: "differenter_name")
      expect(tool.identity_hash).not_to eq ident_hash
    end
  end

  describe "#content_migration_configured?" do
    let(:tool) do
      ContextExternalTool.new.tap do |t|
        t.settings = {
          "content_migration" => {
            "export_start_url" => "https://lti.example.com/begin_export",
            "import_start_url" => "https://lti.example.com/begin_import",
          }
        }
      end
    end

    it "must return false when the content_migration key is missing from the settings hash" do
      tool.settings.delete("content_migration")
      expect(tool.content_migration_configured?).to be false
    end

    it "must return false when the content_migration key is present in the settings hash but the export_start_url sub key is missing" do
      tool.settings["content_migration"].delete("export_start_url")
      expect(tool.content_migration_configured?).to be false
    end

    it "must return false when the content_migration key is present in the settings hash but the import_start_url sub key is missing" do
      tool.settings["content_migration"].delete("import_start_url")
      expect(tool.content_migration_configured?).to be false
    end

    it "must return true when the content_migration key and all relevant sub-keys are present" do
      expect(tool.content_migration_configured?).to be true
    end
  end

  describe "url or domain validation" do
    it "validates with a domain setting" do
      @tool = @course.context_external_tools.create(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end

    it "validates with a url setting" do
      @tool = @course.context_external_tools.create(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end

    it "validates with a canvas lti extension url setting" do
      @tool = @course.context_external_tools.new(name: "a", consumer_key: "12345", shared_secret: "secret")
      @tool.editor_button = {
        "icon_url" => "http://www.example.com/favicon.ico",
        "text" => "Example",
        "url" => "http://www.example.com",
        "selection_height" => 400,
        "selection_width" => 600
      }
      @tool.save
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end

    def url_test(nav_url = nil)
      course_with_teacher(active_all: true)
      @tool = @course.context_external_tools.new(name: "a", consumer_key: "12345", shared_secret: "secret", url: "http://www.example.com")
      Lti::ResourcePlacement::PLACEMENTS.each do |type|
        @tool.send :"#{type}=", {
          url: nav_url,
          text: "Example",
          icon_url: "http://www.example.com/image.ico",
          selection_width: 50,
          selection_height: 50
        }

        launch_url = @tool.extension_setting(type, :url)

        if nav_url
          expect(launch_url).to eq nav_url
        else
          expect(launch_url).to eq @tool.url
        end
      end
    end

    it "allows extension to not have a url if the main config has a url" do
      url_test
    end

    it "prefers the extension url to the main config url" do
      url_test("https://example.com/special_launch_of_death")
    end

    it "does not allow extension with no custom url and a domain match" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool.course_navigation = {
        text: "Example"
      }
      @tool.save!
      expect(@tool.has_placement?(:course_navigation)).to be false
    end

    it "does not validate with no domain or url setting" do
      @tool = @course.context_external_tools.create(name: "a", consumer_key: "12345", shared_secret: "secret")
      expect(@tool).to be_new_record
      expect(@tool.errors["url"]).to eq ["Either the url or domain should be set."]
      expect(@tool.errors["domain"]).to eq ["Either the url or domain should be set."]
    end

    it "accepts both a domain and a url" do
      @tool = @course.context_external_tools.create(name: "a", domain: "google.com", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
      expect(@tool).not_to be_new_record
      expect(@tool.errors).to be_empty
    end
  end

  it "allows extension with only 'enabled' key" do
    @tool = @course.context_external_tools.create!(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
    @tool.course_navigation = {
      enabled: "true"
    }
    @tool.save!
    expect(@tool.has_placement?(:course_navigation)).to be true
  end

  it "allows accept_media_types setting exclusively for file_menu extension" do
    @tool = @course.context_external_tools.create!(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
    @tool.course_navigation = {
      accept_media_types: "types"
    }
    @tool.file_menu = {
      accept_media_types: "types"
    }
    @tool.save!
    expect(@tool.extension_setting(:course_navigation, :accept_media_types)).to be_blank
    expect(@tool.extension_setting(:file_menu, :accept_media_types)).to eq "types"
  end

  it "allows description and require_resource_selection exclusively for submission_type_selection extension" do
    @tool = external_tool_model
    description = "my description"
    require_resource_selection = true
    @tool.submission_type_selection = { description:, require_resource_selection: }
    @tool.file_menu = { description:, require_resource_selection: }
    @tool.save!
    expect(@tool.extension_setting(:submission_type_selection, :description)).to eq description
    expect(@tool.extension_setting(:submission_type_selection, :require_resource_selection)).to eq require_resource_selection
    expect(@tool.extension_setting(:file_menu, :description)).to be_blank
    expect(@tool.extension_setting(:file_menu, :require_resource_selection)).to be_blank
  end

  it "clears disabled extensions" do
    @tool = @course.context_external_tools.create!(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
    @tool.course_navigation = {
      enabled: "false"
    }
    @tool.save!
    expect(@tool.has_placement?(:course_navigation)).to be false
  end

  describe "validate_urls" do
    subject { tool.valid? }

    let(:tool) do
      course.context_external_tools.build(
        name: "a", url:, consumer_key: "12345", shared_secret: "secret", settings:
      )
    end
    let(:settings) { {} }
    let_once(:course) { course_model }
    let(:url) { "https://example.com" }

    context "with bad launch_url" do
      let(:url) { "https://example.com>" }

      it { is_expected.to be false }
    end

    context "with bad settings_url" do
      let(:settings) do
        { course_navigation: {
          url: "https://example.com>",
          text: "Example",
          icon_url: "http://www.example.com/image.ico",
          selection_width: 50,
          selection_height: 50
        } }
      end

      it { is_expected.to be false }
    end
  end

  describe "active?" do
    subject { tool.active? }

    let(:tool) { external_tool_model(opts: tool_opts) }
    let(:tool_opts) { {} }

    it { is_expected.to be true }

    context 'when "workflow_state" is "deleted"' do
      let(:tool_opts) { { workflow_state: "deleted" } }

      it { is_expected.to be false }
    end

    context 'when "workflow_state" is "disabled"' do
      let(:tool_opts) { { workflow_state: "disabled" } }

      it { is_expected.to be false }
    end
  end

  describe "uses_preferred_lti_version?" do
    subject { tool.uses_preferred_lti_version? }

    let_once(:tool) { external_tool_model }

    it { is_expected.to be false }

    context "when the tool uses LTI 1.3" do
      before do
        tool.lti_version = "1.3"
        tool.save!
      end

      it { is_expected.to be true }
    end
  end

  describe "#extension_setting" do
    let(:tool) do
      tool = @course.context_external_tools.new(name: "bob",
                                                consumer_key: "bob",
                                                shared_secret: "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.settings[:windowTarget] = "_blank"
      tool.save!
      tool
    end

    it "returns the top level extension setting if no placement is given" do
      expect(tool.extension_setting(nil, :windowTarget)).to eq "_blank"
    end

    context "with environment-specific overrides" do
      let(:override_url) { "http://www.example.com/icon/override" }
      let(:launch_url) { "http://www.example.com/launch/course_navigation" }

      before do
        allow(tool).to receive(:url_with_environment_overrides).and_return(override_url)
        tool.course_navigation = {
          url: launch_url,
          icon_url: "http://www.example.com/icon/course_navigation"
        }
      end

      it "returns override for icon_url" do
        expect(tool.extension_setting(:course_navigation, :icon_url)).to eq override_url
      end

      it "returns actual url for other properties" do
        expect(tool.extension_setting(:course_navigation, :url)).to eq launch_url
      end
    end
  end

  describe "#icon_url" do
    let(:icon_url) { "http://wwww.example.com/icon/lti" }
    let(:tool) do
      tool = @course.context_external_tools.new(name: "bob",
                                                consumer_key: "bob",
                                                shared_secret: "bob")
      tool.url = "http://www.example.com/basic_lti"
      tool.settings[:icon_url] = icon_url
      tool.save!
      tool
    end

    it "returns settings.icon_url" do
      expect(tool.icon_url).to eq tool.settings[:icon_url]
    end

    context "with environment-specific overrides" do
      let(:override_url) { "http://www.example.com/icon/override" }

      before do
        allow(tool).to receive(:url_with_environment_overrides).and_return(override_url)
      end

      it "returns override for icon_url" do
        expect(tool.icon_url).to eq override_url
      end
    end
  end

  describe "custom fields" do
    it "parses custom_fields_string from a text field" do
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      tool.custom_fields_string = ("a=1\nbT^@!#n_40=123\n\nc=")
      expect(tool.custom_fields).not_to be_nil
      expect(tool.custom_fields.keys.length).to eq 2
      expect(tool.custom_fields["a"]).to eq "1"
      expect(tool.custom_fields["bT^@!#n_40"]).to eq "123"
      expect(tool.custom_fields["c"]).to be_nil
    end

    it "returns custom_fields_string as a text-formatted field" do
      tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret", custom_fields: { "a" => "123", "b" => "456" })
      fields_string = tool.custom_fields_string
      expect(fields_string).to eq "a=123\nb=456"
    end

    it "merges custom fields for extension launches" do
      course_with_teacher(active_all: true)
      @tool = @course.context_external_tools.new(name: "a", consumer_key: "12345", shared_secret: "secret", custom_fields: { "a" => "1", "b" => "2" }, url: "http://www.example.com")
      Lti::ResourcePlacement::PLACEMENTS.each do |type|
        @tool.send :"#{type}=", {
          text: "Example",
          url: "http://www.example.com",
          icon_url: "http://www.example.com/image.ico",
          custom_fields: { "b" => "5", "c" => "3" },
          selection_width: 50,
          selection_height: 50
        }
        @tool.save!

        hash = @tool.set_custom_fields(type)
        expect(hash["custom_a"]).to eq "1"
        expect(hash["custom_b"]).to eq "5"
        expect(hash["custom_c"]).to eq "3"

        @tool.settings[type.to_sym][:custom_fields] = nil
        hash = @tool.set_custom_fields(type)

        expect(hash["custom_a"]).to eq "1"
        expect(hash["custom_b"]).to eq "2"
        expect(hash).not_to have_key("custom_c")
      end
    end
  end

  describe "placements" do
    it "returns multiple requested placements" do
      tool1 = @course.context_external_tools.create!(name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "Another Tool", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:editor_button] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(name: "Third Tool", consumer_key: "key", shared_secret: "secret")
      tool3.settings[:resource_selection] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool3.save!
      placements = Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS + ["resource_selection"]
      expect(ContextExternalTool.where(context: @course).placements(*placements).to_a).to contain_exactly(tool1, tool3)
    end

    it "only returns a single requested placements" do
      @course.context_external_tools.create!(name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "Another Tool", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:editor_button] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(name: "Third Tool", consumer_key: "key", shared_secret: "secret")
      tool3.settings[:resource_selection] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool3.save!
      expect(ContextExternalTool.where(context: @course).placements("resource_selection").to_a).to eql([tool3])
    end

    it "doesn't return not selectable tools placements for module_item" do
      tool1 = @course.context_external_tools.create!(name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "Another Tool", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:editor_button] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool2.save!
      tool3 = @course.context_external_tools.new(name: "Third Tool", consumer_key: "key", shared_secret: "secret")
      tool3.settings[:resource_selection] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
      tool3.not_selectable = true
      tool3.save!
      expect(ContextExternalTool.where(context: @course).placements(*Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS).to_a).to eql([tool1])
    end

    context "when passed the legacy default placements" do
      it "doesn't return tools with a developer key (LTI 1.3 tools)" do
        tool1 = @course.context_external_tools.create!(
          name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret"
        )
        @course.context_external_tools.create!(
          name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret", developer_key: DeveloperKey.create!, lti_version: "1.3"
        )
        expect(ContextExternalTool.where(context: @course).placements(*Lti::ResourcePlacement::LEGACY_DEFAULT_PLACEMENTS).to_a).to eql([tool1])
      end
    end

    describe "enabling/disabling placements" do
      let!(:tool) do
        tool = @course.context_external_tools.create!(name: "First Tool", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
        tool.homework_submission = { enabled: true, selection_height: 300 }
        tool.save
        tool
      end

      it "moves inactive placement data back to active when re-enabled" do
        tool.homework_submission = { enabled: false }
        expect(tool.settings[:inactive_placements][:homework_submission][:enabled]).to be_falsey

        tool.homework_submission = { enabled: true }
        expect(tool.settings[:homework_submission]).to include({ enabled: true, selection_height: 300 })
        expect(tool.settings).not_to have_key(:inactive_placements)
      end

      it "moves placement data to inactive placements when disabled" do
        tool.homework_submission = { enabled: false }
        expect(tool.settings[:inactive_placements][:homework_submission]).to include({ enabled: false, selection_height: 300 })
        expect(tool.settings).not_to have_key(:homework_submission)
      end

      it "keeps already inactive placement data when disabled again" do
        tool.homework_submission = { enabled: false }
        expect(tool.settings[:inactive_placements][:homework_submission]).to include({ enabled: false, selection_height: 300 })

        tool.homework_submission = { enabled: false }
        expect(tool.settings[:inactive_placements][:homework_submission]).to include({ enabled: false, selection_height: 300 })
      end

      it "keeps already active placement data when enabled again" do
        tool.homework_submission = { enabled: true }
        expect(tool.settings[:homework_submission]).to include({ enabled: true, selection_height: 300 })
      end

      it "toggles not_selectable when placement is resource_selection" do
        tool.resource_selection = { enabled: true }

        tool.resource_selection = { enabled: false }
        tool.save
        expect(tool.not_selectable).to be_truthy

        tool.resource_selection = { enabled: true }
        tool.save
        expect(tool.not_selectable).to be_falsy
      end
    end
  end

  describe "visible" do
    it "returns all tools to admins" do
      course_with_teacher(active_all: true, user: user_with_pseudonym, account: @account)
      tool1 = @course.context_external_tools.create!(name: "1", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "2", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:assignment_view] = { url: "http://www.example.com" }.with_indifferent_access
      tool2.save!
      expect(ContextExternalTool.where(context: @course).visible(@user, @course, nil, []).to_a).to contain_exactly(tool1, tool2)
    end

    it "returns nothing if a non-admin requests without specifying placement" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      @course.context_external_tools.create!(name: "1", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "2", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:assignment_view] = { url: "http://www.example.com" }.with_indifferent_access
      tool2.save!
      expect(ContextExternalTool.where(context: @course).visible(@user, @course, nil, []).to_a).to eql([])
    end

    it "returns only tools with placements matching the requested placement" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      @course.context_external_tools.create!(name: "1", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool2 = @course.context_external_tools.new(name: "2", consumer_key: "key", shared_secret: "secret")
      tool2.settings[:assignment_view] = { url: "http://www.example.com" }.with_indifferent_access
      tool2.save!
      expect(ContextExternalTool.where(context: @course).visible(@user, @course, nil, ["assignment_view"]).to_a).to eql([tool2])
    end

    it "does not return admin tools to students" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      tool = @course.context_external_tools.create!(name: "1", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool.settings[:assignment_view] = { url: "http://www.example.com", visibility: "admins" }.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.where(context: @course).visible(@user, @course, nil, ["assignment_view"]).to_a).to eql([])
    end

    it "does return member tools to students" do
      course_with_student(active_all: true, user: user_with_pseudonym, account: @account)
      tool = @course.context_external_tools.create!(name: "1", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool.settings[:assignment_view] = { url: "http://www.example.com", visibility: "members" }.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.where(context: @course).visible(@user, @course, nil, ["assignment_view"]).to_a).to eql([tool])
    end

    it "does not return member tools to public" do
      tool = @course.context_external_tools.create!(name: "1", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool.settings[:assignment_view] = { url: "http://www.example.com", visibility: "members" }.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.where(context: @course).visible(nil, @course, nil, ["assignment_view"]).to_a).to eql([])
    end

    it "does return public tools to public" do
      tool = @course.context_external_tools.create!(name: "1", url: "http://www.example.com", consumer_key: "key", shared_secret: "secret")
      tool.settings[:assignment_view] = { url: "http://www.example.com", visibility: "public" }.with_indifferent_access
      tool.save!
      expect(ContextExternalTool.where(context: @course).visible(nil, @course, nil, ["assignment_view"]).to_a).to eql([tool])
    end
  end

  describe "infer_defaults" do
    def new_external_tool
      @root_account.context_external_tools.new(name: "t", consumer_key: "12345", shared_secret: "secret", domain: "google.com")
    end

    context "setting the root account" do
      let(:new_tool) do
        context.context_external_tools.new(
          name: "test",
          consumer_key: "key",
          shared_secret: "secret",
          domain: "www.test.com"
        )
      end

      shared_examples_for "a tool that infers the root account" do
        let(:context) { raise 'set "context" in examples' }

        it "sets the root account" do
          expect { new_tool.save! }.to change { new_tool.root_account }.from(nil).to context.root_account
        end
      end

      context "when the context is a course" do
        it_behaves_like "a tool that infers the root account" do
          let(:context) { course_model }
        end
      end

      context "when the context is an account" do
        it_behaves_like "a tool that infers the root account" do
          let(:context) { account_model }
        end
      end
    end

    it "requires valid configuration for user navigation settings" do
      tool = new_external_tool
      tool.settings = { user_navigation: { bob: "asfd" } }
      tool.save
      expect(tool.user_navigation).to be_nil
      tool.settings = { user_navigation: { url: "http://www.example.com" } }
      tool.save
      expect(tool.user_navigation).not_to be_nil
    end

    it "requires valid configuration for course navigation settings" do
      tool = new_external_tool
      tool.settings = { course_navigation: { bob: "asfd" } }
      tool.save
      expect(tool.course_navigation).to be_nil
      tool.settings = { course_navigation: { url: "http://www.example.com" } }
      tool.save
      expect(tool.course_navigation).not_to be_nil
    end

    it "requires valid configuration for account navigation settings" do
      tool = new_external_tool
      tool.settings = { account_navigation: { bob: "asfd" } }
      tool.save
      expect(tool.account_navigation).to be_nil
      tool.settings = { account_navigation: { url: "http://www.example.com" } }
      tool.save
      expect(tool.account_navigation).not_to be_nil
    end

    it "requires valid configuration for resource selection settings" do
      tool = new_external_tool
      tool.settings = { resource_selection: { bob: "asfd" } }
      tool.save
      expect(tool.resource_selection).to be_nil
      tool.settings = { resource_selection: { url: "http://www.example.com", selection_width: 100, selection_height: 100 } }
      tool.save
      expect(tool.resource_selection).not_to be_nil
    end

    it "requires valid configuration for editor button settings" do
      tool = new_external_tool
      tool.settings = { editor_button: { bob: "asfd" } }
      tool.save
      expect(tool.editor_button).to be_nil
      tool.settings = { editor_button: { url: "http://www.example.com" } }
      tool.save
      # icon_url now optional, a default will be provided
      expect(tool.editor_button).not_to be_nil
      tool.settings = { editor_button: { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 } }
      tool.save
      expect(tool.editor_button).not_to be_nil
    end

    it "sets user_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = { user_navigation: { url: "http://www.example.com" } }
      expect(tool.has_placement?(:user_navigation)).to be_falsey
      tool.save
      expect(tool.has_placement?(:user_navigation)).to be_truthy
    end

    it "sets course_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = { course_navigation: { url: "http://www.example.com" } }
      expect(tool.has_placement?(:course_navigation)).to be_falsey
      tool.save
      expect(tool.has_placement?(:course_navigation)).to be_truthy
    end

    it "sets account_navigation if navigation configured" do
      tool = new_external_tool
      tool.settings = { account_navigation: { url: "http://www.example.com" } }
      expect(tool.has_placement?(:account_navigation)).to be_falsey
      tool.save
      expect(tool.has_placement?(:account_navigation)).to be_truthy
    end

    it "sets resource_selection if selection configured" do
      tool = new_external_tool
      tool.settings = { resource_selection: { url: "http://www.example.com", selection_width: 100, selection_height: 100 } }
      expect(tool.has_placement?(:resource_selection)).to be_falsey
      tool.save
      expect(tool.has_placement?(:resource_selection)).to be_truthy
    end

    it "sets editor_button if button configured" do
      tool = new_external_tool
      tool.settings = { editor_button: { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 } }
      expect(tool.has_placement?(:editor_button)).to be_falsey
      tool.save
      expect(tool.has_placement?(:editor_button)).to be_truthy
    end

    it "removes and add placements according to configuration" do
      tool = new_external_tool
      tool.settings = {
        editor_button: { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 },
        resource_selection: { url: "http://www.example.com", selection_width: 100, selection_height: 100 }
      }
      tool.save!
      expect(tool.context_external_tool_placements.pluck(:placement_type)).to match_array(["editor_button", "resource_selection"])
      tool.settings.delete(:editor_button)
      tool.settings[:account_navigation] = { url: "http://www.example.com" }
      tool.save!
      expect(tool.context_external_tool_placements.pluck(:placement_type)).to match_array(["resource_selection", "account_navigation"])
    end

    it "allows setting tool_id and icon_url" do
      tool = new_external_tool
      tool.tool_id = "new_tool"
      tool.icon_url = "http://www.example.com/favicon.ico"
      tool.save
      expect(tool.tool_id).to eq "new_tool"
      expect(tool.icon_url).to eq "http://www.example.com/favicon.ico"
    end
  end

  describe "extension settings" do
    let(:tool) do
      tool = @root_account.context_external_tools.new({ name: "t", consumer_key: "12345", shared_secret: "secret", url: "http://google.com/launch_url" })
      tool.settings = { selection_width: 100, selection_height: 100, icon_url: "http://www.example.com/favicon.ico" }
      tool.save
      tool
    end

    it "gets the tools launch url if no extension urls are configured" do
      tool.editor_button = { enabled: true }
      tool.save
      expect(tool.editor_button(:url)).to eq "http://google.com/launch_url"
    end

    it "falls back to tool defaults" do
      tool.editor_button = { url: "http://www.example.com" }
      tool.save
      expect(tool.editor_button).not_to be_nil
      expect(tool.editor_button(:url)).to eq "http://www.example.com"
      expect(tool.editor_button(:icon_url)).to eq "http://www.example.com/favicon.ico"
      expect(tool.editor_button(:selection_width)).to eq 100
    end

    it "returns nil if the tool is not enabled" do
      expect(tool.resource_selection).to be_nil
      expect(tool.resource_selection(:url)).to be_nil
    end

    it "gets properties for each tool extension" do
      tool.course_navigation = { enabled: true }
      tool.account_navigation = { enabled: true }
      tool.user_navigation = { enabled: true }
      tool.resource_selection = { enabled: true }
      tool.editor_button = { enabled: true }
      tool.save
      expect(tool.course_navigation).not_to be_nil
      expect(tool.account_navigation).not_to be_nil
      expect(tool.user_navigation).not_to be_nil
      expect(tool.resource_selection).not_to be_nil
      expect(tool.editor_button).not_to be_nil
    end

    it "gets and keeps launch_height setting from extension" do
      tool.course_navigation = { enabled: true, launch_height: 200 }
      tool.save
      expect(tool.course_navigation[:launch_height]).to be 200
    end

    context "placement enabled setting" do
      context "when placement has enabled defined" do
        before do
          tool.course_navigation = { enabled: false }
          tool.save
        end

        it "includes enabled from placement" do
          expect(tool.course_navigation[:enabled]).to be false
        end
      end

      context "when placement does not have enabled defined" do
        before do
          tool.course_navigation = { text: "hello world" }
        end

        it "includes enabled: true" do
          expect(tool.course_navigation[:enabled]).to be true
        end
      end
    end

    describe "display_type" do
      it "is 'in_context' by default" do
        expect(tool.display_type(:course_navigation)).to eq "in_context"
        tool.course_navigation = { enabled: true }
        tool.save!
        expect(tool.display_type("course_navigation")).to eq "in_context"
      end

      it "is configurable by a property" do
        tool.course_navigation = { enabled: true }
        tool.settings[:display_type] = "custom_display_type"
        tool.save!
        expect(tool.display_type("course_navigation")).to eq "custom_display_type"
      end

      it "is configurable in extension" do
        tool.course_navigation = { display_type: "other_display_type" }
        tool.save!
        expect(tool.display_type("course_navigation")).to eq "other_display_type"
      end

      it "is 'full_width' for global_navigation and analytics_hub by default" do
        tool.global_navigation = { enabled: true }
        tool.analytics_hub = { enabled: true }
        tool.save!
        expect(tool.display_type("global_navigation")).to eq "full_width"
        expect(tool.display_type("analytics_hub")).to eq "full_width"
      end

      it "allows the 'full_width' default for global_navigation and analytics_hub to be overridden with accepted type" do
        tool.global_navigation = { display_type: "borderless" }
        tool.analytics_hub = { display_type: "borderless" }
        tool.save!
        expect(tool.display_type("global_navigation")).to eq "borderless"
        expect(tool.display_type("analytics_hub")).to eq "borderless"
      end

      it "does not allow the 'full_width' default for global_navigation and analytics_hub to be overridden with unaccepted type" do
        tool.global_navigation = { display_type: "other_display_type" }
        tool.analytics_hub = { display_type: "other_display_type" }
        tool.save!
        expect(tool.display_type("global_navigation")).to eq "full_width"
        expect(tool.display_type("analytics_hub")).to eq "full_width"
      end

      it "is full_width for global_navigation when tool does not define global_navigation" do
        tool.global_navigation = nil
        tool.save!
        expect(tool.display_type("global_navigation")).to eq "full_width"
      end
    end

    describe "validation" do
      def set_visibility(v)
        tool.file_menu = { enabled: true, visibility: v }
        tool.save!
        tool.reload
      end

      context "when visibility is included in placement config" do
        it "accepts `admins`" do
          set_visibility("admins")
          expect(tool.file_menu[:visibility]).to eq "admins"
        end

        it "accepts `members`" do
          set_visibility("members")
          expect(tool.file_menu[:visibility]).to eq "members"
        end

        it "accepts `public`" do
          set_visibility("public")
          expect(tool.file_menu[:visibility]).to eq "public"
        end

        it "does not accept any other values" do
          set_visibility("public")
          set_visibility("fake")
          expect(tool.file_menu[:visibility]).to eq "public"
        end

        it "accepts `nil` and removes visibility" do
          set_visibility("members")
          set_visibility(nil)
          expect(tool.file_menu).not_to have_key(:visibility)
        end
      end
    end
  end

  describe "#setting_with_default_enabled" do
    subject do
      tool.setting_with_default_enabled(type)
    end

    let(:tool) do
      t = external_tool_model(context: @root_account)
      t.settings = settings
      t.save
      t
    end

    context "when settings does not contain type" do
      let(:settings) { { oauth_compliant: true } }
      let(:type) { :course_navigation }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when settings contains type" do
      context "when type is not a placement" do
        let(:settings) { { oauth_compliant: true } }
        let(:type) { :oauth_compliant }

        it "returns settings[type]" do
          expect(subject).to eq settings[type]
        end
      end

      context "when type is a placement" do
        let(:type) { :course_navigation }

        context "when type configuration defines `enabled`" do
          let(:settings) do
            {
              course_navigation: { enabled: false, text: "hello world" }
            }
          end

          it "returns settings[type]" do
            expect(subject).to eq settings[type].with_indifferent_access
          end
        end

        context "when type configuration does not define `enabled`" do
          let(:settings) do
            {
              course_navigation: { text: "hello world" }
            }
          end

          it "returns settings[type] with enabled: true" do
            expect(subject[:enabled]).to be true
            expect(subject.except(:enabled)).to eq settings[type].with_indifferent_access
          end
        end
      end
    end
  end

  describe "#extension_default_value" do
    it "returns resource_selection when the type is 'resource_selection'" do
      expect(subject.extension_default_value(:resource_selection, :message_type)).to eq "resource_selection"
    end

    it "returns basic-lti-launch-request for all other types" do
      expect(subject.extension_default_value(:course_navigation, :message_type)).to eq "basic-lti-launch-request"
    end

    context "the tool uses 1.3" do
      let(:tool) do
        external_tool_1_3_model(context: @root_account)
      end

      it "returns LtiResourceLinkRequest when the property is 'message_type'" do
        expect(tool.extension_default_value(:course_navigation, :message_type)).to eq "LtiResourceLinkRequest"
      end

      it "returns LtiDeepLinkingRequest when the property is 'message_type' and type is editor_button" do
        expect(tool.extension_default_value(:editor_button, :message_type)).to eq "LtiDeepLinkingRequest"
      end
    end
  end

  describe "change_domain" do
    let(:prod_base_url) { "http://www.example.com" }
    let(:new_host) { "test.example.com" }

    let(:tool) do
      tool = @root_account.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "www.example.com", url: prod_base_url)
      tool.settings = { url: prod_base_url, icon_url: "#{prod_base_url}/icon.ico" }
      tool.account_navigation = { url: "#{prod_base_url}/launch?my_var=1" }
      tool.editor_button = { url: "#{prod_base_url}/resource_selection", icon_url: "#{prod_base_url}/resource_selection.ico" }
      tool
    end

    it "updates the domain" do
      tool.change_domain! new_host
      expect(tool.domain).to eq new_host
      expect(URI.parse(tool.url).host).to eq new_host
      expect(URI.parse(tool.settings[:url]).host).to eq new_host
      expect(URI.parse(tool.icon_url).host).to eq new_host
      expect(URI.parse(tool.account_navigation[:url]).host).to eq new_host
      expect(URI.parse(tool.editor_button[:url]).host).to eq new_host
      expect(URI.parse(tool.editor_button[:icon_url]).host).to eq new_host
    end

    it "ignores domain if it is nil" do
      tool.domain = nil
      tool.change_domain! new_host
      expect(tool.domain).to be_nil
    end

    it "ignores launch url if it is nil" do
      tool.url = nil
      tool.change_domain! new_host
      expect(tool.url).to be_nil
    end

    it "ignores custom fields" do
      tool.custom_fields = { url: "http://www.google.com/" }
      tool.change_domain! new_host
      expect(tool.custom_fields[:url]).to eq "http://www.google.com/"
    end

    it "ignores environments fields" do
      environments = { launch_url: "http://www.google.com/" }.with_indifferent_access
      tool.settings["environments"] = environments
      tool.change_domain! new_host
      expect(tool.settings["environments"]).to eq(environments)
    end

    it "ignores an existing invalid url" do
      tool.url = "null"
      tool.change_domain! new_host
      expect(tool.url).to eq "null"
    end

    it "ignores boolean fields (enabled: true)" do
      tool.account_navigation = { url: "#{prod_base_url}/launch?my_var=1", enabled: true }
      tool.change_domain! new_host
      expect(URI.parse(tool.account_navigation[:url]).host).to eq new_host
      expect(tool.account_navigation[:enabled]).to be(true)
    end
  end

  describe "standardize_url" do
    it "standardizes urls" do
      url = ContextExternalTool.standardize_url("http://www.google.com?a=1&b=2")
      expect(url).to eql(ContextExternalTool.standardize_url("http://www.google.com?b=2&a=1"))
      expect(url).to eql(ContextExternalTool.standardize_url("http://www.google.com/?b=2&a=1"))
      expect(url).to eql(ContextExternalTool.standardize_url("www.google.com/?b=2&a=1"))
    end

    it "handles spaces in front of url" do
      url = ContextExternalTool.standardize_url(" http://sub_underscore.google.com?a=1&b=2").to_s
      expect(url).to eql("http://sub_underscore.google.com/?a=1&b=2")
    end

    it "handles tabs in front of url" do
      url = ContextExternalTool.standardize_url("\thttp://sub_underscore.google.com?a=1&b=2").to_s
      expect(url).to eql("http://sub_underscore.google.com/?a=1&b=2")
    end

    it "handles unicode whitespace" do
      url = ContextExternalTool.standardize_url("\u00A0http://sub_underscore.go\u2005ogle.com?a=1\u2002&b=2").to_s
      expect(url).to eql("http://sub_underscore.google.com/?a=1&b=2")
    end

    it "handles underscores in the domain" do
      url = ContextExternalTool.standardize_url("http://sub_underscore.google.com?a=1&b=2").to_s
      expect(url).to eql("http://sub_underscore.google.com/?a=1&b=2")
    end
  end

  describe "default_label" do
    append_before do
      @tool = @root_account.context_external_tools.new(consumer_key: "12345", shared_secret: "secret", url: "http://example.com", name: "tool name")
    end

    it "returns the default label if no language or name is specified" do
      expect(@tool.default_label).to eq "tool name"
    end

    it "returns the localized label if a locale is specified" do
      @tool.settings = { url: "http://example.com", text: "course nav", labels: { "en-US" => "english nav" } }
      @tool.save!
      expect(@tool.default_label("en-US")).to eq "english nav"
    end
  end

  describe "label_for" do
    append_before do
      @tool = @root_account.context_external_tools.new(name: "tool", consumer_key: "12345", shared_secret: "secret", url: "http://example.com")
    end

    it "returns the tool name if nothing else is configured and no key is sent" do
      @tool.save!
      expect(@tool.label_for(nil)).to eq "tool"
    end

    it "returns the tool name if nothing else is set and text is an empty string" do
      @tool.settings = { text: "" }
      @tool.save!
      expect(@tool.label_for(nil)).to eq "tool"
    end

    it "returns the tool name if nothing is configured on the sent key" do
      @tool.settings = { course_navigation: { bob: "asfd" } }
      @tool.save!
      expect(@tool.label_for(:course_navigation)).to eq "tool"
    end

    it "returns the tool's 'text' value if no key is sent" do
      @tool.settings = { text: "tool label", course_navigation: { url: "http://example.com", text: "course nav" } }
      @tool.save!
      expect(@tool.label_for(nil)).to eq "tool label"
    end

    it "returns the tool's 'text' value if no 'text' value is set for the sent key" do
      @tool.settings = { text: "tool label", course_navigation: { bob: "asdf" } }
      @tool.save!
      expect(@tool.label_for(:course_navigation)).to eq "tool label"
    end

    it "returns the tool's locale-specific 'text' value if no 'text' value is set for the sent key" do
      @tool.settings = { text: "tool label", labels: { "en" => "translated tool label" }, course_navigation: { bob: "asdf" } }
      @tool.save!
      expect(@tool.label_for(:course_navigation, "en")).to eq "translated tool label"
    end

    it "returns the setting's 'text' value for the sent key if available" do
      @tool.settings = { text: "tool label", course_navigation: { url: "http://example.com", text: "course nav" } }
      @tool.save!
      expect(@tool.label_for(:course_navigation)).to eq "course nav"
    end

    it "returns the locale-specific label if specified and matching exactly" do
      @tool.settings = { text: "tool label", course_navigation: { url: "http://example.com", text: "course nav", labels: { "en-US" => "english nav" } } }
      @tool.save!
      expect(@tool.label_for(:course_navigation, "en-US")).to eq "english nav"
      expect(@tool.label_for(:course_navigation, "es")).to eq "course nav"
    end

    it "returns the locale-specific label if specified and matching based on general locale" do
      @tool.settings = { text: "tool label", course_navigation: { url: "http://example.com", text: "course nav", labels: { "en" => "english nav" } } }
      @tool.save!
      expect(@tool.label_for(:course_navigation, "en-US")).to eq "english nav"
    end
  end

  describe "opaque_identifier_for" do
    context "when the asset is nil" do
      subject { ContextExternalTool.opaque_identifier_for(nil, Shard.first) }

      it { is_expected.to be_nil }
    end

    it "creates lti_context_id for asset" do
      expect(@course.lti_context_id).to be_nil
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      context_id = @tool.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq context_id
    end

    it "does not create new lti_context for asset if exists" do
      @course.lti_context_id = "dummy_context_id"
      @course.save!
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq "dummy_context_id"
    end

    it "uses the global_asset_id for new assets that are stored in the db" do
      expect(@course.lti_context_id).to be_nil
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      context_id = Lti::V1p1::Asset.global_context_id_for(@course)
      @tool.opaque_identifier_for(@course)
      @course.reload
      expect(@course.lti_context_id).to eq context_id
    end
  end

  describe "global navigation" do
    before(:once) do
      @account = account_model
    end

    it "lets account admins see admin tools" do
      account_admin_user(account: @account, active_all: true)
      expect(ContextExternalTool.global_navigation_granted_permissions(
        root_account: @account, user: @user, context: @account
      )[:original_visibility]).to eq "admins"
    end

    it "lets teachers see admin tools" do
      course_with_teacher(account: @account, active_all: true)
      expect(ContextExternalTool.global_navigation_granted_permissions(
        root_account: @account, user: @user, context: @account
      )[:original_visibility]).to eq "admins"
    end

    it "does not let concluded teachers see admin tools" do
      course_with_teacher(account: @account, active_all: true)
      term = @course.enrollment_term
      term.enrollment_dates_overrides.create!(enrollment_type: "TeacherEnrollment", end_at: 1.week.ago, context: term.root_account)
      expect(ContextExternalTool.global_navigation_granted_permissions(
        root_account: @account, user: @user, context: @account
      )[:original_visibility]).to eq "members"
    end

    it "does not let students see admin tools" do
      course_with_student(account: @account, active_all: true)
      expect(ContextExternalTool.global_navigation_granted_permissions(
        root_account: @account, user: @user, context: @account
      )[:original_visibility]).to eq "members"
    end

    it "updates the visibility cache if enrollments are updated or user is touched" do
      time = Time.zone.now
      enable_cache(:redis_cache_store) do
        Timecop.freeze(time) do
          course_with_student(account: @account, active_all: true)
          expect(ContextExternalTool.global_navigation_granted_permissions(
            root_account: @account, user: @user, context: @account
          )[:original_visibility]).to eq "members"
        end

        Timecop.freeze(time + 1.second) do
          course_with_teacher(account: @account, active_all: true, user: @user)
          expect(ContextExternalTool.global_navigation_granted_permissions(
            root_account: @account, user: @user, context: @account
          )[:original_visibility]).to eq "admins"
        end

        Timecop.freeze(time + 2.seconds) do
          @user.teacher_enrollments.update_all(workflow_state: "deleted")
          # should not have affected the earlier cache
          expect(ContextExternalTool.global_navigation_granted_permissions(
            root_account: @account, user: @user, context: @account
          )[:original_visibility]).to eq "admins"

          @user.clear_cache_key(:enrollments)
          expect(ContextExternalTool.global_navigation_granted_permissions(
            root_account: @account, user: @user, context: @account
          )[:original_visibility]).to eq "members"
        end
      end
    end

    it "updates the global navigation menu cache key when the global navigation tools are updated (or removed)" do
      time = Time.zone.now
      enable_cache do
        Timecop.freeze(time) do
          @admin_tool = @account.context_external_tools.new(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
          @admin_tool.global_navigation = { visibility: "admins", url: "http://www.example.com", text: "Example URL" }
          @admin_tool.save!
          @member_tool = @account.context_external_tools.new(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
          @member_tool.global_navigation = { url: "http://www.example.com", text: "Example URL" }
          @member_tool.save!
          @other_tool = @account.context_external_tools.create!(name: "c", domain: "google.com", consumer_key: "12345", shared_secret: "secret")

          @admin_cache_key = ContextExternalTool.global_navigation_menu_render_cache_key(@account, { original_visibility: "admins" })
          @member_cache_key = ContextExternalTool.global_navigation_menu_render_cache_key(@account, { original_visibility: "members" })
        end

        Timecop.freeze(time + 1.second) do
          @other_tool.save!
          # cache keys should remain the same
          expect(ContextExternalTool.global_navigation_menu_render_cache_key(@account, { original_visibility: "admins" })).to eq @admin_cache_key
          expect(ContextExternalTool.global_navigation_menu_render_cache_key(@account, { original_visibility: "members" })).to eq @member_cache_key
        end

        Timecop.freeze(time + 2.seconds) do
          @admin_tool.global_navigation = nil
          @admin_tool.save!
          # should update the admin key
          expect(ContextExternalTool.global_navigation_menu_render_cache_key(@account, { original_visibility: "admins" })).not_to eq @admin_cache_key
          # should not update the members key
          expect(ContextExternalTool.global_navigation_menu_render_cache_key(@account, { original_visibility: "members" })).to eq @member_cache_key
        end
      end
    end

    describe "#has_placement?" do
      it "returns true for module item if it has selectable, and a url" do
        tool = @course.context_external_tools.create!(name: "a", url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
        expect(tool.has_placement?(:link_selection)).to be true
      end

      it "returns true for module item if it has selectable, and a domain" do
        tool = @course.context_external_tools.create!(name: "a", domain: "http://google.com", consumer_key: "12345", shared_secret: "secret")
        expect(tool.has_placement?(:link_selection)).to be true
      end

      it "does not assume default placements for LTI 1.3 tools" do
        tool = @course.context_external_tools.create!(
          name: "a", domain: "http://google.com", consumer_key: "12345", shared_secret: "secret", lti_version: "1.3"
        )
        expect(tool.has_placement?(:link_selection)).to be false
      end

      it "returns false for module item if it is not selectable" do
        tool = @course.context_external_tools.create!(name: "a", not_selectable: true, url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
        expect(tool.has_placement?(:link_selection)).to be false
      end

      it "returns false for module item if it has selectable, and no domain or url" do
        tool = @course.context_external_tools.new(name: "a", consumer_key: "12345", shared_secret: "secret")
        tool.settings[:resource_selection] = { url: "http://www.example.com", icon_url: "http://www.example.com", selection_width: 100, selection_height: 100 }.with_indifferent_access
        tool.save!
        expect(tool.has_placement?(:link_selection)).to be false
      end

      it "returns true for module item if it is not selectable but has the explicit link_selection placement" do
        tool = @course.context_external_tools.create!(name: "a", not_selectable: true, url: "http://google.com", consumer_key: "12345", shared_secret: "secret")
        tool.link_selection = {
          url: "http://google.com",
          text: "Example"
        }
        tool.save!
        expect(tool.has_placement?(:link_selection)).to be true
      end
    end

    describe ".visible?" do
      let(:u) { user_factory }
      let(:admin) { account_admin_user(account: c.root_account) }
      let(:c) { course_factory(active_course: true) }
      let(:student) do
        student = User.create!(valid_user_attributes)
        e = c.enroll_student(student)
        e.invite
        e.accept
        student
      end
      let(:teacher) do
        teacher = User.create!(valid_user_attributes)
        e = c.enroll_teacher(teacher)
        e.invite
        e.accept
        teacher
      end

      it "returns true for public visibility" do
        expect(described_class.visible?("public", u, c)).to be true
      end

      it "returns false for non members if visibility is members" do
        expect(described_class.visible?("members", u, c)).to be false
      end

      it "returns true for members visibility if a student in the course" do
        expect(described_class.visible?("members", student, c)).to be true
      end

      it "returns true for members visibility if a teacher in the course" do
        expect(described_class.visible?("members", teacher, c)).to be true
      end

      it "returns true for admins visibility if a teacher" do
        expect(described_class.visible?("admins", teacher, c)).to be true
      end

      it "returns true for admins visibility if an admin" do
        expect(described_class.visible?("admins", admin, c)).to be true
      end

      it "returns false for admins visibility if a student" do
        expect(described_class.visible?("admins", student, c)).to be false
      end

      it "returns false for admins visibility if a non member user" do
        expect(described_class.visible?("admins", u, c)).to be false
      end

      it "returns true if visibility is invalid" do
        expect(described_class.visible?("true", u, c)).to be true
      end

      it "returns true if visibility is nil" do
        expect(described_class.visible?(nil, u, c)).to be true
      end
    end

    describe "#feature_flag_enabled?" do
      let(:tool) do
        analytics_2_tool_factory
      end

      it "returns true if the feature is enabled in context" do
        @course.enable_feature!(:analytics_2)
        expect(tool.feature_flag_enabled?(@course)).to be true
      end

      it "returns true if the feature is enabled in higher context" do
        Account.default.enable_feature!(:analytics_2)
        expect(tool.feature_flag_enabled?(@course)).to be true
      end

      it "checks the feature flag in the tool context if none provided" do
        Account.default.enable_feature!(:analytics_2)
        expect(tool.feature_flag_enabled?).to be true
      end

      it "returns false if the feature is disabled" do
        expect(tool.feature_flag_enabled?(@course)).to be false
        expect(tool.feature_flag_enabled?).to be false
      end

      it "returns true if called on tools that aren't mapped to feature flags" do
        other_tool = @course.context_external_tools.create!(
          name: "other_feature",
          consumer_key: "key",
          shared_secret: "secret",
          url: "http://example.com/launch",
          tool_id: "yo"
        )
        expect(other_tool.feature_flag_enabled?).to be true
      end
    end

    describe "set_policy" do
      let(:tool) do
        @course.context_external_tools.create(
          name: "a",
          consumer_key: "12345",
          shared_secret: "secret",
          url: "http://example.com/launch"
        )
      end

      it "grants update_manually to the proper individuals" do
        @admin = account_admin_user

        course_with_teacher(active_all: true, account: Account.default)
        @teacher = user_factory(active_all: true)
        @course.enroll_teacher(@teacher).accept!

        @designer = user_factory(active_all: true)
        @course.enroll_designer(@designer).accept!

        @ta = user_factory(active_all: true)
        @course.enroll_ta(@ta).accept!

        @student = user_factory(active_all: true)
        @course.enroll_student(@student).accept!

        expect(tool.grants_right?(@admin, :update_manually)).to be_truthy
        expect(tool.grants_right?(@teacher, :update_manually)).to be_truthy
        expect(tool.grants_right?(@designer, :update_manually)).to be_truthy
        expect(tool.grants_right?(@ta, :update_manually)).to be_truthy
        expect(tool.grants_right?(@student, :update_manually)).to be_falsey
      end
    end
  end

  describe "editor_button_json" do
    let(:tool) do
      @root_account.context_external_tools.new({
                                                 name: "editor thing",
                                                 domain: "www.example.com",
                                                 developer_key: DeveloperKey.create,
                                               })
    end

    before { tool.editor_button = {} }

    it "includes a boolean false for use_tray" do
      tool.editor_button = { use_tray: "false" }
      json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
      expect(json[0][:use_tray]).to be false
    end

    it "includes a boolean true for use_tray" do
      tool.editor_button = { use_tray: "true" }
      json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
      expect(json[0][:use_tray]).to be true
    end

    it "includes a boolean false for on_by_default" do
      Setting.set("rce_always_on_developer_key_ids", "90000000000001,90000000000002")
      json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
      expect(json[0][:on_by_default]).to be false
    end

    it "includes a boolean true for on_by_default" do
      Setting.set("rce_always_on_developer_key_ids", "90000000000001,#{tool.developer_key.global_id}")
      json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
      expect(json[0][:on_by_default]).to be true
    end

    describe "includes the description" do
      it "parsed into HTML" do
        tool.description = "the first paragraph.\n\nthe second paragraph."
        json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
        expect(json[0][:description]).to eq "<p>the first paragraph.</p>\n\n<p>the second paragraph.</p>\n"
      end

      it 'with target="_blank" on links' do
        tool.description = "[link text](http://the.url)"
        json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
        expect(json[0][:description]).to eq "<p><a href=\"http://the.url\" target=\"_blank\">link text</a></p>\n"
      end
    end

    describe "icon_url" do
      let(:base_url) { "https://myexampleschool.instructure.com" }

      def editor_button_icon_url(tool)
        ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, base_url)[0][:icon_url]
      end

      it "includes an icon_url when a tool has an top-level icon_url" do
        tool.editor_button = {}
        tool.settings[:icon_url] = "https://example.com/icon.png"
        expect(editor_button_icon_url(tool)).to eq("https://example.com/icon.png")
      end

      it "includes an icon_url when a tool has an icon_url in editor_button" do
        tool.editor_button = { icon_url: "https://example.com/icon.png" }
        expect(editor_button_icon_url(tool)).to eq("https://example.com/icon.png")
      end

      it "doesn't include an icon_url when the tool has a canvas_icon_class and no icon_url" do
        tool.editor_button = { canvas_icon_class: "icon_lti" }
        expect(editor_button_icon_url(tool)).to be_nil
      end

      it "uses a default tool icon_url when the tool has no icon_url or canvas_icon_class" do
        tool.editor_button = {}
        expect(editor_button_icon_url(tool)).to match(
          %r{^https://myexampleschool.instructure.com/.*tool_default_icon.*name=editor.thing}
        )
      end
    end
  end

  describe "#default_icon_path" do
    it "references the lti_tool_default_icon_path, tool name, and tool developer key id" do
      tool = external_tool_1_3_model(opts: { name: "foo" })
      expect(tool.default_icon_path).to eq("/lti/tool_default_icon?name=foo")
    end
  end

  describe "is_rce_favorite" do
    def tool_in_context(context)
      ContextExternalTool.create!(
        context:,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        editor_button: { url: "http://example.com", icon_url: "http://example.com" }
      )
    end

    it "can be an rce favorite if it has an editor_button placement" do
      tool = tool_in_context(@root_account)
      expect(tool.can_be_rce_favorite?).to be true
    end

    it "cannot be an rce favorite if no editor_button placement" do
      tool = tool_in_context(@root_account)
      tool.editor_button = nil
      tool.save!
      expect(tool.can_be_rce_favorite?).to be false
    end

    it "does not set tools as an rce favorite for any context by default" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(@root_account)
      expect(tool.is_rce_favorite_in_context?(@root_account)).to be false
      expect(tool.is_rce_favorite_in_context?(sub_account)).to be false
    end

    it "inherits from the old is_rce_favorite column if the accounts have not be seen up yet" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(@root_account)
      tool.is_rce_favorite = true
      tool.save!
      expect(tool.is_rce_favorite_in_context?(@root_account)).to be true
      expect(tool.is_rce_favorite_in_context?(sub_account)).to be true
    end

    it "inherits from root account configuration if not set on sub-account" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(@root_account)
      @root_account.settings[:rce_favorite_tool_ids] = { value: [tool.global_id] }
      @root_account.save!
      expect(tool.is_rce_favorite_in_context?(@root_account)).to be true
      expect(tool.is_rce_favorite_in_context?(sub_account)).to be true
    end

    it "overrides with sub-account configuration if specified" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(@root_account)
      @root_account.settings[:rce_favorite_tool_ids] = { value: [tool.global_id] }
      @root_account.save!
      sub_account.settings[:rce_favorite_tool_ids] = { value: [] }
      sub_account.save!
      expect(tool.is_rce_favorite_in_context?(@root_account)).to be true
      expect(tool.is_rce_favorite_in_context?(sub_account)).to be false
    end

    it "can set sub-account tools as favorites" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(sub_account)
      sub_account.settings[:rce_favorite_tool_ids] = { value: [tool.global_id] }
      sub_account.save!
      expect(tool.is_rce_favorite_in_context?(sub_account)).to be true
    end
  end

  context "top_navigation placement" do
    def tool_in_context(context, with_placement: true)
      tool = ContextExternalTool.create!(
        context:,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch"
      )
      tool.context_external_tool_placements.create(placement_type: :top_navigation) if with_placement
      tool
    end

    it "can be a top nav favorite if it has a top_navigation placement" do
      tool = tool_in_context(@root_account)
      expect(tool.can_be_top_nav_favorite?).to be true
    end

    it "cannot be a top nav favorite if no top_navigation placement" do
      tool = tool_in_context(@root_account, with_placement: false)
      expect(tool.can_be_rce_favorite?).to be false
    end

    it "does not set tools as a top nav favorite for any context by default" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(@root_account)
      expect(tool.top_nav_favorite_in_context?(@root_account)).to be false
      expect(tool.top_nav_favorite_in_context?(sub_account)).to be false
    end

    it "inherits from root account configuration if not set on sub-account" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(@root_account)
      @root_account.settings[:top_nav_favorite_tool_ids] = { value: [tool.global_id] }
      @root_account.save!
      expect(tool.top_nav_favorite_in_context?(@root_account)).to be true
      expect(tool.top_nav_favorite_in_context?(sub_account)).to be true
    end

    it "overrides with sub-account configuration if specified" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(@root_account)
      @root_account.settings[:top_nav_favorite_tool_ids] = { value: [tool.global_id] }
      @root_account.save!
      sub_account.settings[:top_nav_favorite_tool_ids] = { value: [] }
      sub_account.save!
      expect(tool.top_nav_favorite_in_context?(@root_account)).to be true
      expect(tool.top_nav_favorite_in_context?(sub_account)).to be false
    end

    it "can set sub-account tools as favorites" do
      sub_account = @root_account.sub_accounts.create!
      tool = tool_in_context(sub_account)
      sub_account.settings[:top_nav_favorite_tool_ids] = { value: [tool.global_id] }
      sub_account.save!
      expect(tool.top_nav_favorite_in_context?(sub_account)).to be true
    end
  end

  describe "upgrading from 1.1 to 1.3" do
    let(:domain) { "special.url" }
    let(:url) { "https://special.url" }
    let(:old_tool) { external_tool_model(opts: { url:, domain: }) }
    let(:tool) do
      t = old_tool.dup
      t.lti_version = "1.3"
      t.save!
      t
    end

    context "prechecks" do
      it "ignores 1.1 tools" do
        expect(old_tool).not_to receive(:migrate_content_to_1_3)
        old_tool.migrate_content_to_1_3_if_needed!
      end

      it "ignores 1.3 tools without matching 1.1 tool" do
        other_tool = external_tool_model(opts: { url: "http://other.url" })
        expect(other_tool).not_to receive(:migrate_content_to_1_3)
        other_tool.migrate_content_to_1_3_if_needed!
      end

      it "starts process when needed" do
        expect(tool).to receive(:migrate_content_to_1_3)
        tool.migrate_content_to_1_3_if_needed!
      end

      it "finds the correct 1.1 tool even if there are similar 1.3 tools" do
        expect(tool).to receive(:migrate_content_to_1_3).with(old_tool.id)
        t = tool.dup
        t.url += "/1_3/launch"
        t.save!

        tool.migrate_content_to_1_3_if_needed!
      end
    end

    describe "#migrate_content_to_1_3" do
      subject { tool.migrate_content_to_1_3(old_tool.id) }

      let(:course) { course_model(account:) }
      let(:account) { account_model }
      let(:url) { "https://special.url" }
      let(:direct_assignment) do
        a = assignment_model(context: course, title: "direct", submission_types: "external_tool")
        a.external_tool_tag = ContentTag.create!(context: a, content: old_tool)
        a.save!
        a
      end
      let(:indirect_assignment) do
        a = assignment_model(context: course, title: "indirect", submission_types: "external_tool")
        a.external_tool_tag = ContentTag.create!(context: a, content: old_tool)
        a.save!
        a
      end
      let(:indirect_collaboration) do
        external_tool_collaboration_model(
          context: course,
          title: "Indirect Collaboration",
          root_account_id: course.root_account_id,
          url:
        )
      end
      let(:old_tool) { external_tool_model(context: course, opts: { url: }) }
      let(:tool) do
        t = old_tool.dup
        t.lti_version = "1.3"
        t.developer_key = DeveloperKey.create!
        t.save!
        t
      end

      it "calls assignment#migrate_to_1_3_if_needed!" do
        expect(direct_assignment.line_items.count).to eq 0
        expect(indirect_assignment.line_items.count).to eq 0
        subject
        expect(direct_assignment.line_items.count).to eq 1
        expect(indirect_assignment.line_items.count).to eq 1
      end

      it "calls external_tool_collaboration#migrate_to_1_3_if_needed!" do
        indirect_collaboration
        expect(course.lti_resource_links.count).to eq 0
        subject
        expect(course.lti_resource_links.count).to eq 1
      end

      shared_examples_for "finds related content" do
        before do
          # content that should never get returned
          ## assignments
          diff_context = assignment_model(context: course_model, title: "diff context", submission_types: "external_tool")
          diff_context.external_tool_tag = ContentTag.create!(context: diff_context, content: old_tool)
          diff_context.save!

          diff_account = assignment_model(context: course_model(account: account_model), title: "diff account", submission_types: "external_tool")
          diff_account.external_tool_tag = ContentTag.create!(context: diff_account, content: old_tool)
          diff_account.save!

          invalid_url = assignment_model(context: course)
          invalid_url.external_tool_tag = ContentTag.create!(context: invalid_url, url: "https://invalid.url")
          invalid_url.save!

          other_tool = external_tool_model(opts: { url: "https://different.url" })
          diff_url = assignment_model(context: course, submission_types: "external_tool", title: "diff url")
          diff_url = ContentTag.create!(context: diff_url, url: other_tool.url)
          diff_url.save!

          ## module items
          ContentTag.create!(context: course_model, content: old_tool)
          ContentTag.create!(context: course_model(account: account_model), content: old_tool)
          ContentTag.create!(context: course, url: "https://invalid.url")
          ContentTag.create!(context: course, url: other_tool.url)

          allow(tool).to receive(:prepare_content_for_migration)
        end

        it "finds assignments using tool id" do
          direct = assignment_model(context: course, title: "direct")
          ContentTag.create!(context: direct, content: old_tool)
          subject
          expect(tool).to have_received(:prepare_content_for_migration).with(direct)
        end

        it "finds assignments using tool url" do
          indirect = assignment_model(context: course, title: "indirect")
          ContentTag.create!(context: indirect, url: old_tool.url)
          subject
          expect(tool).to have_received(:prepare_content_for_migration).with(indirect)
        end

        it "finds both direct and indirect assignments" do
          direct = assignment_model(context: course, title: "direct")
          ContentTag.create!(context: direct, content: old_tool)
          indirect = assignment_model(context: course, title: "indirect")
          ContentTag.create!(context: indirect, url: old_tool.url)
          subject
          expect(tool).to have_received(:prepare_content_for_migration).with(direct)
          expect(tool).to have_received(:prepare_content_for_migration).with(indirect)
        end

        it "finds both direct and indirect module items" do
          direct = ContentTag.create!(context: course, content: old_tool, tag_type: "context_module")
          indirect = ContentTag.create!(context: course, url: old_tool.url, tag_type: "context_module")
          subject
          expect(tool).to have_received(:prepare_content_for_migration).with(direct)
          expect(tool).to have_received(:prepare_content_for_migration).with(indirect)
        end

        it "finds indirect collaboration" do
          indirect_collaboration
          subject
          expect(tool).to have_received(:prepare_content_for_migration).with(indirect_collaboration)
        end
      end

      context "when installed in a course" do
        let(:old_tool) { external_tool_model(context: course, opts: { url: "https://special.url" }) }
        let(:tool) do
          t = old_tool.dup
          t.lti_version = "1.3"
          t.save!
          t
        end

        it_behaves_like "finds related content"
      end

      context "when installed in an account" do
        let(:old_tool) { external_tool_model(context: account, opts: { url: "https://special.url" }) }
        let(:tool) do
          t = old_tool.dup
          t.lti_version = "1.3"
          t.save!
          t
        end

        it_behaves_like "finds related content"
      end

      context "with assignments that error" do
        let(:valid_assignment) do
          a = assignment_model(context: course, title: "valid", submission_types: "external_tool")
          a.external_tool_tag = ContentTag.create!(context: a, content: old_tool)
          a
        end
        let(:invalid_assignment) do
          a = assignment_model(context: course, title: "invalid", submission_types: "external_tool", points_possible: nil)
          a.external_tool_tag = ContentTag.create!(context: a, content: old_tool)
          a
        end
        let(:scope) { double("scope") }

        before do
          valid_assignment
          invalid_assignment
          allow(Sentry).to receive(:capture_message).and_return(nil)
          allow(Sentry).to receive(:with_scope).and_yield(scope)
          allow(scope).to receive(:set_tags)
          allow(scope).to receive(:set_context)
        end

        it "sends errors to sentry" do
          subject
          expect(Sentry).to have_received(:capture_message)
          expect(scope).to have_received(:set_tags).with(content_id: invalid_assignment.global_id)
          expect(scope).to have_received(:set_tags).with(tool_id: tool.global_id)
          expect(scope).to have_received(:set_tags).with(exception_class: "ActiveRecord::RecordInvalid")
          expect(scope).to have_received(:set_tags).with(content_type: "Assignment")
        end

        it "completes the batch" do
          subject
          expect(valid_assignment.reload.line_items.count).to eq 1
        end
      end
    end
  end

  describe "lti_version" do
    let(:tool) { external_tool_model }

    it "can be 1.1" do
      tool.lti_version = "1.1"
      expect(tool.save).to be true
    end

    it "can be 1.3" do
      tool.lti_version = "1.3"
      expect(tool.save).to be true
    end

    it "can't be any other value" do
      tool.lti_version = "2.0"
      expect(tool.save).to be false
    end

    it "defaults to 1.1" do
      expect(tool.lti_version).to eq "1.1"
    end
  end

  describe "#internal_tool_domain_allowlist" do
    subject { tool.send :internal_tool_domain_allowlist }

    let(:tool) { external_tool_model }

    context "when config does not exist" do
      it "returns an empty array" do
        expect(subject).to eq []
      end
    end

    context "when config exists" do
      let(:allowlist) { [".docker", "localhost"] }

      before do
        allow(DynamicSettings).to receive(:find).and_return(DynamicSettings::FallbackProxy.new({ "internal_tool_domain_allowlist" => YAML.dump(allowlist) }))
      end

      it "returns correct config value" do
        expect(subject).to eq allowlist
      end
    end
  end

  describe "#internal_service?" do
    subject { tool.internal_service?(launch_url) }

    let(:tool) { external_tool_1_3_model }
    let(:launch_url) { "http://tool.instructure.com/launch" }

    before do
      allow(tool).to receive(:internal_tool_domain_allowlist).and_return(["instructure.com", "localhost"])
      tool.developer_key.update!(internal_service: true)
    end

    context "when tool has no developer key" do
      before do
        tool.update!(developer_key_id: nil)
      end

      it { is_expected.to be false }
    end

    context "when developer key is not internal_service" do
      before do
        tool.developer_key.update!(internal_service: false)
      end

      it { is_expected.to be false }
    end

    context "when launch url is nil" do
      let(:launch_url) { nil }

      it { is_expected.to be false }
    end

    context "when launch url is malformed" do
      let(:launch_url) { "in valid" }

      it { is_expected.to be false }
    end

    context "when launch url domain does not match allowlist" do
      let(:launch_url) { "https://example.com/launch" }

      it { is_expected.to be false }
    end

    context "when launch url contains but does not end with domain in allowlist" do
      let(:launch_url) { "https://instructure.com.l33thaxxors.net" }

      it { is_expected.to be false }
    end

    context "when launch_url exactly matches domain in allowlist" do
      let(:launch_url) { "http://localhost/launch" }

      it { is_expected.to be true }
    end

    context "with a correctly configured 1.1 tool" do
      before do
        tool.update!(lti_version: "1.1")
      end

      it { is_expected.to be true }
    end

    context "with a correctly configured 1.3 tool" do
      it { is_expected.to be true }
    end
  end

  describe "settings serialization" do
    let(:tool) do
      t = @course.context_external_tools.create(
        name: "a",
        consumer_key: "12345",
        shared_secret: "secret",
        url: "http://example.com/launch"
      )
      t.save!
      t
    end

    describe "during tool creation" do
      it "defaults to indifferent access hash" do
        tool.settings # read and initialize to default value
        expect(tool.attributes_before_type_cast["settings"]).to include("!ruby/hash:ActiveSupport::HashWithIndifferentAccess")
      end
    end

    describe "reading `settings`" do
      context "when settings is serialized as a Hash" do
        before do
          tool.settings = { hello: "world" }
          tool.save!
        end

        it "presents as a HashWithIndifferentAccess" do
          expect(tool.reload.settings.class).to eq(ActiveSupport::HashWithIndifferentAccess)
        end
      end

      context "when settings is serialized as a HashWithIndifferentAccess" do
        before do
          tool.settings = { hello: "world" }.with_indifferent_access
          tool.save!
        end

        it "presents as a HashWithIndifferentAccess" do
          expect(tool.reload.settings.class).to eq(ActiveSupport::HashWithIndifferentAccess)
        end
      end
    end
  end

  describe "#sort_key" do
    it "is based on the collation key of the name, then id" do
      sk1 = external_tool_model(opts: { name: "a" }).sort_key
      # collation key puts "E" after "e"
      sk2 = external_tool_model(opts: { name: "A" }).sort_key
      sk3 = external_tool_model(opts: { name: "a" }).sort_key
      expect([sk1, sk2, sk3].sort).to eq([sk1, sk3, sk2])
    end
  end

  describe "#placement_allowed?" do
    subject { tool.placement_allowed?(placement) }

    let(:developer_key) { DeveloperKey.create! }
    let(:domain) { "http://www.example.com" }
    let(:tool) { external_tool_1_3_model(developer_key:, opts: { domain: }) }

    %w[submission_type_selection top_navigation].each do |restricted_placement|
      context "when the tool has a #{restricted_placement} placement" do
        let(:placement) { restricted_placement.to_sym }

        context "when the placement is not on any allow list" do
          it { is_expected.to be false }
        end

        context "when the placement is allowed by developer_key_id" do
          before do
            Setting.set("#{restricted_placement}_allowed_dev_keys", Shard.global_id_for(developer_key.id).to_s)
          end

          it { is_expected.to be true }
        end

        context "when the placement is allowed by the domain" do
          before do
            Setting.set("#{restricted_placement}_allowed_launch_domains", domain)
          end

          it { is_expected.to be true }
        end

        context "when the placement is allowed by a wildcard domain" do
          before do
            Setting.set("#{restricted_placement}_allowed_launch_domains", "*.example.com")
          end

          it { is_expected.to be true }

          it "doesn't match a different domain that happens to end with the wildcard domain" do
            %w[fooexample.com http://fooexample.com https://fooexample.com].each do |domain|
              tool.update!(domain:)
              expect(tool.placement_allowed?(placement)).to be false
            end
          end

          context "and the tool's domain is nil" do
            before { tool.update!(domain: nil) }

            it { is_expected.to be false }
          end
        end

        context "when the tool has no domain and domain list is containing an empty space" do
          before do
            tool.update!(domain: "")
            tool.update!(developer_key: nil)
            Setting.set("#{restricted_placement}_allowed_launch_domains", ", ,,")
            Setting.set("#{restricted_placement}_allowed_dev_keys", ", ,,")
          end

          it { is_expected.to be false }
        end
      end
    end

    it "return true for all other placements" do
      expect(tool.placement_allowed?(:collaboration)).to be true
    end
  end

  describe "#save" do
    subject { tool }

    let(:tool_name) { "test tool" }
    let(:tool_id) { "test_tool_id" }
    let(:tool_domain) { "www.example.com" }
    let(:tool_version) { "1.1" }
    let(:tool_url) { "http://www.tool.com/launch" }
    let(:unified_tool_id) { "unified_tool_id_12345" }

    let_once(:tool) do
      ContextExternalTool.new(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: tool_name,
        tool_id:,
        domain: tool_domain,
        url: tool_url,
        lti_version: tool_version,
        root_account: @root_account
      )
    end

    context "the tool version is 1.1" do
      let(:tool_version) { "1.1" }

      before do
        allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id).and_return(unified_tool_id)
      end

      it "calls the LearnPlatform::GlobalApi service and update the unified_tool_id attribute" do
        subject.save
        run_jobs
        expect(LearnPlatform::GlobalApi).to have_received(:get_unified_tool_id).with(
          { lti_domain: tool_domain,
            lti_name: tool_name,
            lti_tool_id: tool_id,
            lti_url: tool_url,
            lti_version: tool_version }
        )
        tool.reload
        expect(tool.unified_tool_id).to eq(unified_tool_id)
      end

      it "starts a background job to update the unified_tool_id" do
        expect do
          subject.save
        end.to change(Delayed::Job, :count).by(1)
      end

      context "when the tool is a redirect tool" do
        let(:redirect_url) { "https://example.com" }

        before do
          tool.tool_id = "redirect"
          tool.settings[:custom_fields] = { "url" => redirect_url }
        end

        it "calls the LearnPlatform::GlobalApi service with the correct lti_redirect_url" do
          subject.save
          run_jobs
          expect(LearnPlatform::GlobalApi).to have_received(:get_unified_tool_id).with(hash_including(lti_redirect_url: redirect_url))
        end
      end
    end

    context "the tool version is 1.3" do
      let(:tool_version) { "1.3" }
      let(:account) { account_model }

      let_once(:developer_key) { lti_developer_key_model(account:) }
      let_once(:tool_configuration) do
        lti_tool_configuration_model(developer_key:, unified_tool_id:)
      end
      let_once(:tool) do
        ContextExternalTool.new(
          context: @course,
          consumer_key: "key",
          shared_secret: "secret",
          name: tool_name,
          tool_id:,
          domain: tool_domain,
          url: tool_url,
          lti_version: tool_version,
          root_account: @root_account,
          developer_key:
        )
      end

      before do
        run_jobs # to empty the job queue
      end

      it "does not call the LearnPlatform::GlobalApi service" do
        allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id)
        subject.save
        run_jobs
        expect(LearnPlatform::GlobalApi).not_to have_received(:get_unified_tool_id)
      end

      it "does update the unified_tool_id attribute" do
        subject.save
        run_jobs
        tool.reload
        expect(tool.unified_tool_id).to eq(unified_tool_id)
      end
    end

    context "when the tool already exists" do
      before do
        subject.save
        run_jobs
        allow(LearnPlatform::GlobalApi).to receive(:get_unified_tool_id)
      end

      context "when the tool is 'deleted'" do
        it "does not call the LearnPlatform::GlobalApi service" do
          subject.workflow_state = "deleted"
          subject.name = "new name"
          subject.save
          run_jobs
          expect(LearnPlatform::GlobalApi).not_to have_received(:get_unified_tool_id)
        end
      end

      context "when the tool's name changed" do
        it "calls the LearnPlatform::GlobalApi service" do
          subject.name = "new name"
          subject.save
          run_jobs
          expect(LearnPlatform::GlobalApi).to have_received(:get_unified_tool_id)
        end
      end

      context "when the tool's description changed" do
        it "does not call the LearnPlatform::GlobalApi service" do
          subject.description = "new description"
          subject.save
          run_jobs
          expect(LearnPlatform::GlobalApi).not_to have_received(:get_unified_tool_id)
        end
      end
    end

    context "unified_tool_id backfill job" do
      let(:tool) { external_tool_model }

      it "can save last_updated" do
        now = Time.zone.now
        tool.unified_tool_id_last_updated_at = now
        expect(tool.save).to be true
        expect(tool.reload.unified_tool_id_last_updated_at).to eq(now)
      end

      it "can save needs_update" do
        expect(tool.unified_tool_id_needs_update).to be false
        tool.unified_tool_id_needs_update = true
        expect(tool.save).to be true
        expect(tool.reload.unified_tool_id_needs_update).to be true
      end
    end
  end

  describe "#destroy" do
    subject { deployment.destroy }

    let_once(:registration) { lti_registration_with_tool(account:) }
    let_once(:account) { account_model }
    let_once(:deployment) do
      registration.deployments.first
    end

    it "soft-deletes the tool and it's context controls" do
      expect { subject }.to change { deployment.reload.workflow_state }.to("deleted")
      expect(deployment.context_controls.reload.pluck(:workflow_state))
        .to all(eq("deleted"))
    end

    context "when the tool has lots of controls" do
      let_once(:subaccount1) { account_model(parent_account: account) }
      let_once(:subaccount2) { account_model(parent_account: account) }
      let_once(:subcourse) { course_model(account: subaccount1) }

      before(:once) do
        Lti::ContextControl.create!(account: subaccount1,
                                    registration:,
                                    deployment:,
                                    workflow_state: "active")
        Lti::ContextControl.create!(account: subaccount2,
                                    registration:,
                                    deployment:,
                                    workflow_state: "active")
        Lti::ContextControl.create!(course: subcourse,
                                    registration:,
                                    deployment:,
                                    workflow_state: "active")
      end

      it "soft-deletes all controls" do
        subject
        expect(deployment.context_controls.reload.pluck(:workflow_state))
          .to all(eq("deleted"))
      end
    end
  end

  describe "#can_access_content_tag?" do
    it "returns true for a 1.1 content tag with the same tool" do
      tool = external_tool_model

      content_tag = ContentTag.create!(context: @course, content: tool)
      expect(tool.can_access_content_tag?(content_tag)).to be true
    end

    context "when the content tag was created by a 1.1 tool that now corresponds to a 1.3 tool" do
      let(:domain) { "example.instructure.com" }
      let(:url) { "https://example.instructure.com" }
      let(:opts) { { domain:, url: } }
      let(:old_tool) { external_tool_model(opts:) }
      let(:developer_key) { DeveloperKey.create! }
      let(:new_tool1) { external_tool_1_3_model(opts:, developer_key:) }
      let(:new_tool2) { external_tool_1_3_model(opts:, developer_key:) }

      it "returns true if the 1.3 tool matches on developer_key (module item)" do
        content_tag = ContentTag.create!(context: @course, content: old_tool, url:)
        expect(Lti::ToolFinder).to receive(:from_content_tag).with(content_tag, content_tag.context).and_return(new_tool1)
        expect(new_tool2.can_access_content_tag?(content_tag)).to be true
      end

      it "returns true if the 1.3 tool matches on developer_key (assignment)" do
        assignment = assignment_model(context: @course, submission_types: "external_tool")
        content_tag = ContentTag.create!(context: assignment, content: old_tool, url:)
        expect(Lti::ToolFinder).to receive(:from_content_tag).with(content_tag, content_tag.context.context).and_return(new_tool1)
        expect(new_tool2.can_access_content_tag?(content_tag)).to be true
      end

      it "returns false if the 1.3 tool does not match on developer_key" do
        content_tag = ContentTag.create!(context: @course, content: old_tool, url:)
        new_tool1.update!(developer_key: DeveloperKey.create!)
        expect(Lti::ToolFinder).to receive(:from_content_tag).with(content_tag, content_tag.context).and_return(new_tool1)
        expect(new_tool2.can_access_content_tag?(content_tag)).to be false
      end
    end
  end

  describe "#asset_processor_eula_url" do
    let(:tool) { external_tool_model }

    it "returns the correct EULA URL for the tool" do
      expected_url = "http://#{tool.context.root_account.environment_specific_domain}/api/lti/asset_processor_eulas/#{tool.id}"
      expect(tool.asset_processor_eula_url).to eq(expected_url)
    end
  end

  describe "eula fields" do
    let(:tool) do
      ContextExternalTool.create!(
        context: @root_account,
        name: "EULA Tool",
        consumer_key: "key",
        shared_secret: "secret",
        url: "http://www.tool.com/launch",
        settings:
      )
    end
    let(:settings) { {} }

    describe "#eula_launch_url" do
      it "returns the extension eula_launch_url if present" do
        settings[:ActivityAssetProcessor] = { eula: { target_link_uri: "http://eula.example.com/launch" } }
        expect(tool.eula_launch_url).to eq "http://eula.example.com/launch"
      end

      it "returns the launch_url if extension eula_launch_url is not present" do
        expect(tool.eula_launch_url).to eq tool.launch_url
      end
    end

    describe "#eula_custom_fields" do
      it "returns the fields if custom_fields is a hash" do
        custom_fields = { "field1" => "value1", "field2" => "value2" }
        settings[:ActivityAssetProcessor] = { eula: { custom_fields: } }

        expected = { "field1" => "value1", "field2" => "value2" }
        expect(tool.eula_custom_fields).to eq(expected)
      end

      it "returns {} if custom_fields is not given" do
        expect(tool.eula_custom_fields).to eq({})
      end
    end
  end
end
