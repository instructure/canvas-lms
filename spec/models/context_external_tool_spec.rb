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
    let_once(:tool) do
      ContextExternalTool.create!(
        context: @course,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        developer_key:,
        lti_version: "1.3",
        root_account: @root_account
      )
    end

    it "allows setting the developer key" do
      expect(tool.developer_key).to eq developer_key
    end

    it "allows setting the root account" do
      expect(tool.root_account).to eq @root_account
    end

    it { expect(tool).to validate_length_of(:consumer_key).is_at_most(2048) }
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
      expect(tool.deployment_id).to eq "#{tool.id}:#{Lti::Asset.opaque_identifier_for(tool.context)}"
    end

    it "sends only 255 chars" do
      allow(Lti::Asset).to receive(:opaque_identifier_for).and_return("a" * 256)
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

  describe "from_content_tag" do
    subject { ContextExternalTool.from_content_tag(*arguments) }

    let(:arguments) { [content_tag, tool.context] }
    let(:assignment) { assignment_model(course: tool.context) }
    let(:tool) { external_tool_model }
    let(:content_tag_opts) { { url: tool.url, content_type: "ContextExternalTool", context: assignment } }
    let(:content_tag) { ContentTag.new(content_tag_opts) }
    let(:developer_key) { DeveloperKey.create! }
    let(:lti_1_3_tool) do
      t = tool.dup
      t.developer_key_id = developer_key.id
      t.lti_version = "1.3"
      t.save!
      t
    end

    it { is_expected.to eq tool }

    context "when the tool is linked to the tag by id (LTI 1.1)" do
      let(:content_tag_opts) { super().merge({ content_id: tool.id }) }

      it { is_expected.to eq tool }

      context "and an LTI 1.3 tool has a conflicting URL" do
        let(:arguments) do
          [content_tag, tool.context]
        end

        before { lti_1_3_tool }

        it { is_expected.to be_use_1_3 }
      end
    end

    context "when the tool is linked to a tag by id (LTI 1.3)" do
      let(:content_tag_opts) { super().merge({ content_id: lti_1_3_tool.id }) }
      let(:duplicate_1_3_tool) do
        t = lti_1_3_tool.dup
        t.save!
        t
      end

      context "and an LTI 1.1 tool has a conflicting URL" do
        before { tool } # initialized already, but included for clarity

        it { is_expected.to eq lti_1_3_tool }

        context "and there are multiple matching LTI 1.3 tools" do
          before { duplicate_1_3_tool }

          let(:arguments) { [content_tag, tool.context] }
          let(:content_tag_opts) { super().merge({ content_id: lti_1_3_tool.id }) }

          it { is_expected.to eq lti_1_3_tool }
        end

        context "and the LTI 1.3 tool gets reinstalled" do
          before do
            # "install" a copy of the tool
            duplicate_1_3_tool

            # "uninstall" the original tool
            lti_1_3_tool.destroy!
          end

          it { is_expected.to eq duplicate_1_3_tool }
        end
      end
    end

    context "when there are blank arguments" do
      context "when the content tag argument is blank" do
        let(:arguments) { [nil, tool.context] }

        it { is_expected.to be_nil }
      end
    end
  end

  describe "find_external_tool" do
    it "matches on the same domain" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    context "when context is a course on a different shard" do
      specs_require_sharding

      it "matches on the same domain" do
        @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @shard2.activate do
          @found_tool = ContextExternalTool.find_external_tool("http://google.com/is/cool", @course)
        end
        expect(@found_tool).to eql(@tool)
      end
    end

    it "is case insensitive when matching on the same domain" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "Google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://google.com/is/cool", Course.find(@course.id), @tool.id)
      expect(@found_tool).to eql(@tool)
    end

    it "matches on a subdomain" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "matches on a domain with a scheme attached" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "http://google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "does not match on non-matching domains" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool2 = @course.context_external_tools.create!(name: "a", domain: "www.google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://mgoogle.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to be_nil
      @found_tool = ContextExternalTool.find_external_tool("http://sgoogle.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to be_nil
    end

    it "does not match on the closest matching domain" do
      @tool = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool2 = @course.context_external_tools.create!(name: "a", domain: "www.google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.www.google.com/is/cool", Course.find(@course.id))
      expect(@found_tool).to eql(@tool2)
    end

    it "matches on exact url" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "matches on url ignoring query parameters" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?a=1&b=2", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "matches on url even when tool url contains query parameters" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness?a=1&b=2", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?b=2&a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?c=3&b=2&d=4&a=1", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "does not match on url if the tool url contains query parameters that the search url doesn't" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness?a=1", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness?a=2", Course.find(@course.id))
      expect(@found_tool).to be_nil
    end

    it "does not match on url before matching on domain" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", consumer_key: "12345", shared_secret: "secret")
      @tool2 = @course.context_external_tools.create!(name: "a", domain: "www.google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "does not match on domain if domain is nil" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://malicious.domain./hahaha", Course.find(@course.id))
      expect(@found_tool).to be_nil
    end

    it "matches on url or domain for a tool that has both" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com/coolness", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      expect(ContextExternalTool.find_external_tool("http://google.com/is/cool", Course.find(@course.id))).to eql(@tool)
      expect(ContextExternalTool.find_external_tool("http://www.google.com/coolness", Course.find(@course.id))).to eql(@tool)
    end

    it "finds the context's tool matching on url first" do
      @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the nearest account's tool matching on url if there are no url-matching context tools" do
      @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool = @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the root account's tool matching on url before matching by domain on the course" do
      @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @tool = @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the context's tool matching on domain if no url-matching tools are found" do
      @tool = @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the nearest account's tool matching on domain if no url-matching tools are found" do
      @tool = @account.context_external_tools.create!(name: "c", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @root_account.context_external_tools.create!(name: "e", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    it "finds the root account's tool matching on domain if no url-matching tools are found" do
      @tool = @root_account.context_external_tools.create!(name: "e", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
      @found_tool = ContextExternalTool.find_external_tool("http://www.google.com/", Course.find(@course.id))
      expect(@found_tool).to eql(@tool)
    end

    context "when exclude_tool_id is set" do
      subject { ContextExternalTool.find_external_tool("http://www.google.com", Course.find(course.id), nil, exclude_tool.id) }

      let(:course) { @course }
      let(:exclude_tool) do
        course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
      end

      it "does not return the excluded tool" do
        expect(subject).to be_nil
      end
    end

    context "preferred_tool_id" do
      it "finds the preferred tool if there are two matching-priority tools" do
        @tool1 = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @tool2 = @course.context_external_tools.create!(name: "b", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1.id)
        expect(@found_tool).to eql(@tool1)
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool2.id)
        expect(@found_tool).to eql(@tool2)
        @tool1.destroy
        @tool2.destroy

        @tool1 = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool2 = @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1.id)
        expect(@found_tool).to eql(@tool1)
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool2.id)
        expect(@found_tool).to eql(@tool2)
      end

      it "finds the preferred tool even if there is a higher priority tool configured" do
        @tool = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @preferred = @root_account.context_external_tools.create!(name: "f", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")

        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @preferred.id)
        expect(@found_tool).to eql(@preferred)
      end

      it "does not find the preferred tool if it is deleted" do
        @preferred = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @preferred.destroy
        @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool = @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @preferred.id)
        expect(@found_tool).to eql(@tool)
      end

      it "does not find the preferred tool if it is disabled" do
        @preferred = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @preferred.update!(workflow_state: "disabled")
        @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool = @account.context_external_tools.create!(name: "c", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @account.context_external_tools.create!(name: "d", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "e", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @root_account.context_external_tools.create!(name: "f", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @preferred.id)
        expect(@found_tool).to eql(@tool)
      end

      it "does not return preferred tool outside of context chain" do
        preferred = @root_account.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        expect(ContextExternalTool.find_external_tool("http://www.google.com", @course, preferred.id)).to eq preferred
      end

      it "does not return preferred tool if url doesn't match" do
        c1 = @course
        preferred = c1.account.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        expect(ContextExternalTool.find_external_tool("http://example.com", c1, preferred.id)).to be_nil
      end

      it "finds preferred tool if url doesn't match but url's domain is a subdomain of the tool domain" do
        c1 = @course
        preferred = c1.account.context_external_tools.create!(name: "a", url: "http://www.google.com", domain: "example.com", consumer_key: "12345", shared_secret: "secret")
        # If we didn't favor the preferred tool, we would return this tool because it's in a closer context
        c1.context_external_tools.create!(name: "a", url: "http://www.google.com", domain: "example.com", consumer_key: "12345", shared_secret: "secret")
        expect(ContextExternalTool.find_external_tool("http://subdomain.example.com", c1, preferred.id)).to eq(preferred)
      end

      it "returns the preferred tool if the url is nil" do
        c1 = @course
        preferred = c1.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        expect(ContextExternalTool.find_external_tool(nil, c1, preferred.id)).to eq preferred
      end

      it "does not return preferred tool if it is 1.1 and there is a matching 1.3 tool" do
        developer_key = DeveloperKey.create!
        @tool1_1 = @course.context_external_tools.create!(name: "a", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @tool1_3 = @course.context_external_tools.create!(name: "b", url: "http://www.google.com", consumer_key: "12345", shared_secret: "secret")
        @tool1_3.lti_version = "1.3"
        @tool1_3.developer_key = developer_key
        @tool1_3.save!

        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1_1.id)
        expect(@found_tool).to eql(@tool1_3)
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1_3.id)
        expect(@found_tool).to eql(@tool1_3)
        @tool1_1.destroy
        @tool1_3.destroy

        @tool1_1 = @course.context_external_tools.create!(name: "a", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool1_3 = @course.context_external_tools.create!(name: "b", domain: "google.com", consumer_key: "12345", shared_secret: "secret")
        @tool1_3.lti_version = "1.3"
        @tool1_3.developer_key = developer_key
        @tool1_3.save!
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1_1.id)
        expect(@found_tool).to eql(@tool1_3)
        @found_tool = ContextExternalTool.find_external_tool("http://www.google.com", Course.find(@course.id), @tool1_3.id)
        expect(@found_tool).to eql(@tool1_3)
      end
    end

    context "when multiple ContextExternalTools have domain/url conflict" do
      before do
        ContextExternalTool.create!(
          context: @course,
          consumer_key: "key1",
          shared_secret: "secret1",
          name: "test faked tool",
          url: "http://nothing",
          domain: "www.tool.com",
          tool_id: "faked"
        )

        ContextExternalTool.create!(
          context: @course,
          consumer_key: "key2",
          shared_secret: "secret2",
          name: "test tool",
          url: "http://www.tool.com/launch",
          tool_id: "real"
        )
      end

      it "picks up url in higher priority" do
        tool = ContextExternalTool.find_external_tool("http://www.tool.com/launch?p1=2082", Course.find(@course.id))
        expect(tool.tool_id).to eq("real")
      end

      context "and there is a difference in LTI version" do
        def find_tool(url, **opts)
          ContextExternalTool.find_external_tool(url, context, **opts)
        end

        before do
          # Creation order is important. Be default Canvas uses
          # creation order as a tie-breaker. Creating the LTI 1.3
          # tool first ensures we are actually exercising the preferred
          # LTI version matching logic.
          lti_1_1_tool
          lti_1_3_tool
        end

        let(:context) { @course }
        let(:domain) { "www.test.com" }
        let(:opts) { { url:, domain: } }
        let(:url) { "https://www.test.com/foo?bar=1" }
        let(:lti_1_1_tool) { external_tool_model(context:, opts:) }
        let(:lti_1_3_tool) { external_tool_1_3_model(context:, opts:) }

        it "prefers LTI 1.3 tools when there is an exact URL match" do
          expect(find_tool(url)).to eq lti_1_3_tool
        end

        it "prefers LTI 1.3 tools when there is an partial URL match" do
          expect(find_tool("#{url}&extra_param=1")).to eq lti_1_3_tool
        end

        it "prefers LTI 1.3 tools when there is an domain match" do
          expect(find_tool("https://www.test.com/another_endpoint")).to eq lti_1_3_tool
        end

        context "when prefer_1_1: true is passed in" do
          it "prefers LTI 1.1 tools when there is an exact URL match" do
            expect(find_tool(url, prefer_1_1: true)).to eq lti_1_1_tool
          end

          it "prefers LTI 1.1 tools when there is an partial URL match" do
            expect(find_tool("#{url}&extra_param=1", prefer_1_1: true)).to eq lti_1_1_tool
          end

          it "prefers LTI 1.1 tools when there is an domain match" do
            expect(find_tool("https://www.test.com/another_endpoint", prefer_1_1: true)).to \
              eq lti_1_1_tool
          end
        end
      end
    end

    context("with a client id") do
      let(:url) { "http://test.com" }
      let(:tool_params) do
        {
          name: "a",
          url:,
          consumer_key: "12345",
          shared_secret: "secret",
        }
      end
      let!(:tool1) { @course.context_external_tools.create!(tool_params) }
      let!(:tool2) do
        @course.context_external_tools.create!(
          tool_params.merge(developer_key: DeveloperKey.create!)
        )
      end

      it "preferred_tool_id has precedence over preferred_client_id" do
        external_tool = ContextExternalTool.find_external_tool(
          url, @course, tool1.id, nil, tool2.developer_key.id
        )
        expect(external_tool).to eq tool1
      end

      it "finds the tool based on developer key id" do
        external_tool = ContextExternalTool.find_external_tool(
          url, @course, nil, nil, tool2.developer_key.id
        )
        expect(external_tool).to eq tool2
      end
    end

    context "with duplicate tools" do
      let(:url) { "http://example.com/launch" }
      let(:tool) do
        t = @course.context_external_tools.create!(name: "test", domain: "example.com", url:, consumer_key: "12345", shared_secret: "secret")
        t.global_navigation = {
          url: "http://www.example.com",
          text: "Example URL"
        }
        t.save!
        t
      end
      let(:duplicate) do
        t = tool.dup
        t.save!
        t
      end

      context "when original tool exists" do
        it "finds original tool" do
          tool
          expect(ContextExternalTool.find_external_tool(url, @course)).to eq tool
        end
      end

      context "when original tool is gone" do
        before do
          duplicate
          tool.destroy
        end

        it "finds duplicate tool" do
          expect(ContextExternalTool.find_external_tool(url, @course)).to eq duplicate
        end
      end

      context "when non-duplicate tool was created later" do
        before do
          duplicate
          tool.update_column :identity_hash, "duplicate"
          # re-calculate the identity hash for the later tool
          duplicate.update!(domain: "fake.com")
          duplicate.update!(domain: "example.com")
        end

        it "finds tool with non-duplicate identity_hash" do
          expect(ContextExternalTool.find_external_tool(url, @course)).to eq duplicate
        end
      end

      context "when duplicate is 1.3" do
        before do
          duplicate.lti_version = "1.3"
          duplicate.developer_key = DeveloperKey.create!
          duplicate.save!
          duplicate.update_column :identity_hash, "duplicate"
        end

        it "finds duplicate tool" do
          expect(ContextExternalTool.find_external_tool(url, @course)).to eq duplicate
        end
      end
    end

    describe "when only_1_3 is passed in" do
      let(:url) { "http://example.com/launch" }
      let(:tool) do
        @course.context_external_tools.create!(name: "test", domain: "example.com", url:, consumer_key: "12345", shared_secret: "secret")
      end

      context "when the matching tool is 1.1" do
        it "returns nil" do
          expect(ContextExternalTool.find_external_tool(url, @course, only_1_3: true)).to be_nil
        end
      end

      context "when the matching tool is 1.3" do
        before do
          tool.lti_version = "1.3"
          tool.developer_key = DeveloperKey.create!
          tool.save!
        end

        it "returns the tool" do
          expect(ContextExternalTool.find_external_tool(url, @course, only_1_3: true)).to eq tool
        end
      end
    end

    context "with env-specific override urls" do
      subject { ContextExternalTool.find_external_tool(given_url, @course) }

      let(:given_url) { "http://example.beta.com/launch?foo=bar" }
      let(:tool) do
        t = @course.context_external_tools.create!(name: "test", domain: "example.com", url: "http://example.com/launch", consumer_key: "12345", shared_secret: "secret")
        t.global_navigation = {
          url: "http://www.example.com",
          text: "Example URL"
        }
        t.save!
        t
      end

      shared_examples_for "matches tool with overrides" do
        context "in production environment" do
          it "does not match" do
            expect(subject).to be_nil
          end
        end

        context "in nonprod environment" do
          before do
            allow(ApplicationController).to receive_messages(test_cluster?: true, test_cluster_name: "beta")
          end

          it "matches on override" do
            expect(subject).to eq tool
          end
        end
      end

      context "when tool has override domain" do
        before do
          tool.settings[:environments] = {
            domain: "example.beta.com"
          }
          tool.save!
        end

        it_behaves_like "matches tool with overrides"
      end

      context "when tool has override url" do
        before do
          tool.settings[:environments] = {
            launch_url: "http://example.beta.com/launch"
          }
          tool.save!
        end

        it_behaves_like "matches tool with overrides"
      end

      context "when tool has override url with query parameters" do
        before do
          tool.settings[:environments] = {
            launch_url: "http://example.beta.com/launch?foo=bar"
          }
          tool.save!
        end

        it_behaves_like "matches tool with overrides"
      end
    end

    context "when closest matching tool is from a different developer key" do
      let(:url) { "http://test.com" }
      let(:tool_params) do
        {
          name: "a",
          url:,
          consumer_key: "12345",
          shared_secret: "secret",
          developer_key: original_key
        }
      end
      let(:original_key) { DeveloperKey.create! }
      let(:other_key) { DeveloperKey.create! }
      let(:original_tool) { @course.context_external_tools.create!(tool_params) }
      let(:matching_tool) { @course.root_account.context_external_tools.create!(tool_params) }
      let(:closest_tool) { @course.context_external_tools.create!(tool_params.merge(developer_key: other_key)) }

      before do
        original_tool.destroy!
        matching_tool
        closest_tool
      end

      context "and the flag is disabled" do
        before do
          @course.root_account.disable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "returns the closest matching tool" do
          expect(ContextExternalTool.find_external_tool(url, @course, original_tool.id)).to eq closest_tool
        end
      end

      context "and the flag is enabled" do
        before do
          @course.root_account.enable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "prefers tool from the same developer key" do
          expect(ContextExternalTool.find_external_tool(url, @course, original_tool.id)).to eq matching_tool
        end
      end
    end
  end

  describe "find_and_order_tools" do
    subject do
      ContextExternalTool.find_and_order_tools(context: @course, preferred_tool_id:, exclude_tool_id:, preferred_client_id:, original_client_id:).to_a
    end

    let(:tool1) { external_tool_model(context: @course, opts: { name: "tool1" }) }
    let(:tool2) { external_tool_model(context: @course, opts: { name: "tool2" }) }
    let(:tool3) { external_tool_model(context: @course, opts: { name: "tool3" }) }
    let(:tools) { [tool1, tool2, tool3] }
    let(:preferred_tool_id) { nil }
    let(:exclude_tool_id) { nil }
    let(:preferred_client_id) { nil }
    let(:original_client_id) { nil }
    let(:key) { DeveloperKey.create! }

    before do
      # initialize tools
      tools
    end

    context "when preferred_tool_id contains a sql injection" do
      let(:preferred_tool_id) { "123\npsql syntax error" }

      it "does not raise an error" do
        expect { subject }.not_to raise_error
      end
    end

    context "when tool is deleted" do
      before do
        tool1.destroy
      end

      it "is not included" do
        expect(subject).not_to include(tool1)
      end
    end

    context "when tool is from separate context" do
      let(:other_tool) { external_tool_model(context: Course.create!) }

      it "does not include tools from separate contexts" do
        expect(subject).not_to include(other_tool)
      end
    end

    context "when exclude_tool_is is provided" do
      let(:exclude_tool_id) { tool2.id }

      it "does not include tool with that id" do
        expect(subject).not_to include(tool2)
      end
    end

    context "when preferred_client_id is provided" do
      let(:key) { DeveloperKey.create! }
      let(:other_key) { DeveloperKey.create! }
      let(:preferred_client_id) { key.id }

      before do
        tool3.update!(developer_key: key)
        tool1.update!(developer_key: other_key)
      end

      it "includes tool from that developer key" do
        expect(subject).to include(tool3)
      end

      it "does not include a tool from other developer key" do
        expect(subject).not_to include(tool1)
      end

      it "does not include tool without developer key" do
        expect(subject).not_to include(tool2)
      end
    end

    context "with tools in the context chain" do
      let(:account_tool) { external_tool_model(context: @course.account, opts: { name: "Account Tool" }) }

      before do
        tool2.destroy
        tool3.destroy
        account_tool
      end

      it "sorts tool from immediate context to the front" do
        expect(subject.first).to eq tool1
      end

      it "sorts tool from farthest context to the back" do
        expect(subject.last).to eq account_tool
      end
    end

    context "with tools that have subdomains and urls" do
      before do
        tool2.update!(domain: "c.b.a.com")
        tool3.update!(domain: "a.com")
        tool1.update!(url: "https://a.com/launch")
      end

      it "sorts tools with more subdomains to the front" do
        expect(subject.first).to eq tool2
      end

      it "sorts tools with fewer subdomains to the back" do
        expect(subject.second).to eq tool3
      end

      it "sorts tools with url and no domain to the back" do
        expect(subject.last).to eq tool1
      end
    end

    context "with different LTI versions" do
      before do
        tool3.developer_key_id = key.id
        tool3.lti_version = "1.3"
        tool3.save!
      end

      it "sorts 1.3 tools to the front" do
        expect(subject.first).to eq tool3
      end

      it "sorts 1.1 tools to the back" do
        expect(subject.last).to eq tool2
      end

      context "when prefer_1_1 is true" do
        subject do
          ContextExternalTool.find_and_order_tools(context: @course, preferred_tool_id:, exclude_tool_id:, preferred_client_id:, prefer_1_1: true).to_a
        end

        it "sorts 1.1 tools to the front and 1.3 tools to the back" do
          expect(subject.first).to eq tool1
          expect(subject.last).to eq tool3
        end
      end
    end

    context "with duplicate tools" do
      before do
        tool2.update!(name: "tool1")
      end

      it "sorts non-duplicate tools to the front" do
        expect(subject.first).to eq tool1
      end

      it "sorts duplicate tools to the back" do
        expect(subject.last).to eq tool2
      end
    end

    context "when preferred_tool_id is provided" do
      let(:preferred_tool_id) { tool2.id }

      it "sorts tool with that id to the front" do
        expect(subject.first).to eq tool2
      end
    end

    context "when closest matching tool is from a different developer key" do
      let(:preferred_tool_id) { tool3.id }
      let(:original_client_id) { key.id }

      before do
        # preferred tool is gone,
        tool3.developer_key = key
        tool3.save!
        tool3.destroy!

        # the tool we actually want is farther up in context chain
        tool1.context = @course.account
        tool1.developer_key = key
        tool1.save!

        # the tool that matches first is from the wrong dev key
        tool2.developer_key = DeveloperKey.create!
        tool2.save!
      end

      context "and flag is enabled" do
        before do
          @course.root_account.enable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "prefers tool from the same developer key" do
          expect(subject.first).to eq tool1
        end
      end

      context "and flag is disabled" do
        before do
          @course.root_account.disable_feature!(:lti_find_external_tool_prefer_original_client_id)
        end

        it "prefers tool from closer context" do
          expect(subject.first).to eq tool2
        end
      end
    end

    context "with many tools that mix all ordering conditions" do
      before do
        tool3.developer_key_id = key.id
        tool3.lti_version = "1.3"
        tool3.domain = "c.com"
        tool3.save!

        tool1.developer_key_id = key.id
        tool1.lti_version = "1.3"
        tool1.domain = "a.b.c.com"
        tool1.save

        account_tool.developer_key_id = key.id
        account_tool.lti_version = "1.3"
        account_tool.domain = "b.c.com"
        account_tool.save!

        lti1tool
        preferred_tool
        dupe_tool
      end

      let(:account_tool) { external_tool_model(context: @course.account, opts: { name: "Account Tool" }) }
      let(:lti1tool) do
        t = tool1.dup
        t.developer_key_id = nil
        t.lti_version = "1.1"
        t.domain = "b.c.com"
        t.save!
        t
      end
      let(:dupe_tool) do
        t = tool1.dup
        t.save!
        t
      end
      let(:preferred_tool) do
        t = tool1.dup
        t.name = "preferred"
        t.save!
        t
      end
      let(:preferred_tool_id) { preferred_tool.id }

      it "sorts tools in order of order clauses" do
        expect(subject.map(&:id)).to eq [
          preferred_tool,
          tool1,
          tool3,
          account_tool,
          dupe_tool,
          lti1tool,
          tool2
        ].map(&:id)
      end
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

    context "when allow_lti_tools_editor_button_placement_without_icon FF is disabled" do
      let(:ff) { :allow_lti_tools_editor_button_placement_without_icon }

      before { @root_account.disable_feature! ff }
      after { @root_account.enable_feature! ff }

      it "deletes the editor_button if icon_url is not present" do
        tool = new_external_tool
        tool.settings = { editor_button: { url: "http://www.example.com" } }
        tool.save
        expect(tool.editor_button).to be_nil
      end
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
        expect(tool.display_type(:course_navigation)).to eq "in_context"
      end

      it "is configurable by a property" do
        tool.course_navigation = { enabled: true }
        tool.settings[:display_type] = "custom_display_type"
        tool.save!
        expect(tool.display_type(:course_navigation)).to eq "custom_display_type"
      end

      it "is configurable in extension" do
        tool.course_navigation = { display_type: "other_display_type" }
        tool.save!
        expect(tool.display_type(:course_navigation)).to eq "other_display_type"
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

  describe "find_for" do
    before :once do
      course_model
    end

    def new_external_tool(context)
      context.context_external_tools.new(name: "bob", consumer_key: "bob", shared_secret: "bob", domain: "google.com")
    end

    it "finds the tool if it's attached to the course" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(ContextExternalTool.find_for(tool.id, @course, :course_navigation)).to eq tool
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "finds the tool if it's attached to the course's account" do
      tool = new_external_tool @course.account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(ContextExternalTool.find_for(tool.id, @course, :course_navigation)).to eq tool
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "finds the tool if it's attached to the course's root account" do
      tool = new_external_tool @course.root_account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect(ContextExternalTool.find_for(tool.id, @course, :course_navigation)).to eq tool
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find the tool if it's attached to a sub-account" do
      @account = @course.account.sub_accounts.create!(name: "sub-account")
      tool = new_external_tool @account
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find the tool if it's attached to another course" do
      @course2 = @course
      @course = course_model
      tool = new_external_tool @course2
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find the tool if it's not enabled for the correct navigation type" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :user_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises RecordNotFound if the id is invalid" do
      expect { ContextExternalTool.find_for("horseshoes", @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find a course tool with workflow_state deleted" do
      tool = new_external_tool @course
      tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.workflow_state = "deleted"
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not find an account tool with workflow_state deleted" do
      tool = new_external_tool @account
      tool.account_navigation = { url: "http://www.example.com", text: "Example URL" }
      tool.workflow_state = "deleted"
      tool.save!
      expect { ContextExternalTool.find_for(tool.id, @account, :account_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when the workflow state is "disabled"' do
      let(:tool) do
        tool = new_external_tool @account
        tool.account_navigation = { url: "http://www.example.com", text: "Example URL" }
        tool.workflow_state = "disabled"
        tool.save!
        tool
      end

      it "does not find an account tool with workflow_state disabled" do
        expect { ContextExternalTool.find_for(tool.id, @account, :account_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context "when the tool is installed in a course" do
        let(:tool) do
          tool = new_external_tool @course
          tool.course_navigation = { url: "http://www.example.com", text: "Example URL" }
          tool.workflow_state = "disabled"
          tool.save!
          tool
        end

        it "does not find a course tool with workflow_state disabled" do
          expect { ContextExternalTool.find_for(tool.id, @course, :course_navigation) }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
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
      context_id = Lti::Asset.global_context_id_for(@course)
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
      time = Time.now
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
      time = Time.now
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

    describe ".from_assignment" do
      let(:tool) do
        @course.context_external_tools.create(
          name: "a",
          consumer_key: "12345",
          shared_secret: "secret",
          url: "http://example.com/launch"
        )
      end

      it "finds the tool from an assignment" do
        a = @course.assignments.create!(title: "test",
                                        submission_types: "external_tool",
                                        external_tool_tag_attributes: { url: tool.url })
        expect(described_class.from_assignment(a)).to eq tool
      end

      it "returns nil if there is no content tag" do
        a = @course.assignments.create!(title: "test",
                                        submission_types: "external_tool")
        expect(described_class.from_assignment(a)).to be_nil
      end
    end

    describe ".visible?" do
      let(:u) { user_factory }
      let(:admin) { account_admin_user(account: c.root_account) }
      let(:c) { course_factory(active_course: true) }
      let(:student) do
        student = factory_with_protected_attributes(User, valid_user_attributes)
        e = c.enroll_student(student)
        e.invite
        e.accept
        student
      end
      let(:teacher) do
        teacher = factory_with_protected_attributes(User, valid_user_attributes)
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

    it "includes a boolean false for always_on" do
      Setting.set("rce_always_on_developer_key_ids", "90000000000001,90000000000002")
      json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
      expect(json[0][:always_on]).to be false
    end

    it "includes a boolean true for always_on" do
      Setting.set("rce_always_on_developer_key_ids", "90000000000001,#{tool.developer_key.global_id}")
      json = ContextExternalTool.editor_button_json([tool], @course, user_with_pseudonym, nil, "")
      expect(json[0][:always_on]).to be true
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
      expect(tool.developer_key.global_id).to be_a(Integer)
      expect(tool.default_icon_path).to eq("/lti/tool_default_icon?id=#{tool.developer_key.global_id}&name=foo")
    end

    it "uses tool ID if there is no developer key id" do
      tool = external_tool_model(opts: { name: "foo" })
      expect(tool.global_id).to be_a(Integer)
      expect(tool.default_icon_path).to eq("/lti/tool_default_icon?id=#{tool.global_id}&name=foo")
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

  describe "associated_1_1_tool" do
    specs_require_cache(:redis_cache_store)

    subject { lti_1_3_tool.associated_1_1_tool(context, requested_url) }

    let(:context) { @course }
    let(:domain) { "test.com" }
    let(:opts) { { url:, domain: } }
    let(:requested_url) { nil }
    let(:url) { "https://test.com/foo?bar=1" }
    let!(:lti_1_1_tool) { external_tool_model(context:, opts:) }
    let!(:lti_1_3_tool) { external_tool_1_3_model(context:, opts:) }

    it { is_expected.to eq lti_1_1_tool }

    it "caches the result" do
      expect(subject).to eq lti_1_1_tool

      allow(ContextExternalTool).to receive(:find_external_tool)
      lti_1_3_tool.associated_1_1_tool(context)
      expect(ContextExternalTool).not_to have_received(:find_external_tool)
    end

    it "finds deleted 1.1 tools" do
      lti_1_1_tool.destroy
      expect(subject).to eq(lti_1_1_tool)
    end

    it "finds nil and doesn't error on tools with invalid URL & Domains" do
      lti_1_1_tool.update_column(:url, "http://url path>/invalidurl}")
      lti_1_1_tool.update_column(:domain, "url path>/invalidurl}")

      expect { subject }.not_to raise_error
      expect(subject).to be_nil
    end

    it "finds tools in a higher level context" do
      lti_1_1_tool.update!(context: context.account)
      expect(subject).to eq(lti_1_1_tool)
    end

    it "ignores duplicate tools" do
      lti_1_1_tool.dup.save!
      expect(subject).to eq(lti_1_1_tool)
    end

    context "the request is to a subdomain of the tools' domain" do
      let(:requested_url) { "https://morespecific.test.com/foo?bar=1" }

      it { is_expected.to eq(lti_1_1_tool) }

      context "there's another 1.1 tool with that subdomain" do
        let(:specific_opts) do
          {
            url: "https://morespecific.test.com/foo?bar=1",
            domain: "https://morespecific.test.com"
          }
        end
        let!(:specific_1_1_tool) { external_tool_model(context:, opts: specific_opts) }

        it { is_expected.to eq(specific_1_1_tool) }
      end
    end
  end

  describe "#placement_allowed?" do
    subject { tool.placement_allowed?(placement) }

    let(:developer_key) { DeveloperKey.create! }
    let(:domain) { "http://example.com" }
    let(:tool) { external_tool_1_3_model(developer_key:, opts: { domain: }) }

    context "when the tool has a submission_type_selection placement" do
      let(:placement) { :submission_type_selection }

      context "when the placement is not on any allow list" do
        it { is_expected.to be false }
      end

      context "when the placement is allowed by developer_key_id" do
        before do
          Setting.set("submission_type_selection_allowed_dev_keys", Shard.global_id_for(developer_key.id).to_s)
        end

        it { is_expected.to be true }
      end

      context "when the placement is allowed by the domain" do
        before do
          Setting.set("submission_type_selection_allowed_launch_domains", domain)
        end

        it { is_expected.to be true }
      end

      context "when the tool has no domain and domain list is containing an empty space" do
        before do
          tool.update!(domain: "")
          tool.update!(developer_key: nil)
          Setting.set("submission_type_selection_allowed_launch_domains", ", ,,")
          Setting.set("submission_type_selection_allowed_dev_keys", ", ,,")
        end

        it { is_expected.to be false }
      end
    end

    it "return true for all placements other than submission_type_selection" do
      expect(tool.placement_allowed?(:collaboration)).to be true
    end
  end
end
