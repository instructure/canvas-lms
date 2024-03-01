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

require_relative "../lti_1_3_spec_helper"
require_relative "../lib/token_scopes/last_known_accepted_scopes"
require_relative "../lib/token_scopes/spec_helper"

describe DeveloperKey do
  let(:account) { Account.create! }

  let(:developer_key_saved) do
    DeveloperKey.create(
      name: "test",
      email: "test@test.com",
      redirect_uri: "http://test.com",
      account_id: account.id
    )
  end

  # Tests that use this key will run faster because they don't need to
  # save an account and a developer_key to the db
  let(:developer_key_not_saved) do
    DeveloperKey.new(
      name: "test",
      email: "test@test.com",
      redirect_uri: "http://test.com"
    )
  end

  describe "#site_admin_service_auth?" do
    subject do
      developer_key_not_saved.update!(key_attributes)
      developer_key_not_saved.site_admin_service_auth?
    end

    let(:service_user) { user_model }
    let(:root_account) { account_model }

    context "when 'site_admin_service_auth' is enabled" do
      before { Account.site_admin.enable_feature!(:site_admin_service_auth) }

      context "and the service user association is not set" do
        let(:key_attributes) { { service_user: nil } }

        it { is_expected.to be false }
      end

      context "and the service user association is set" do
        let(:key_attributes) { { service_user: } }

        context "and the key is a site admin key" do
          let(:key_attributes) { { service_user:, account: nil } }

          it { is_expected.to be false }

          context "and the key is an internal service" do
            let(:key_attributes) { { service_user:, account: nil, internal_service: true } }

            it { is_expected.to be true }
          end
        end

        context "and the key is not a site admin key" do
          let(:key_attributes) { super().merge(account: root_account) }

          it { is_expected.to be false }
        end
      end
    end
  end

  describe "#find_cached" do
    it "raises error when not found, and caches that" do
      enable_cache do
        expect(DeveloperKey).to receive(:find_by).once.and_call_original
        expect { DeveloperKey.find_cached(0) }.to raise_error(ActiveRecord::RecordNotFound)
        # only calls the original once
        expect { DeveloperKey.find_cached(0) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "site_admin" do
    subject { DeveloperKey.site_admin }

    let!(:site_admin_key) { DeveloperKey.create! }
    let!(:root_account_key) { DeveloperKey.create!(account: Account.default) }

    it { is_expected.to match_array [site_admin_key] }
  end

  describe "default values for is_lti_key" do
    let(:public_jwk) do
      key_hash = CanvasSecurity::RSAKeyPair.new.public_jwk.to_h
      key_hash["kty"] = key_hash["kty"].to_s
      key_hash
    end
    let(:public_jwk_url) { "https://hello.world.com" }

    it "throws error if public jwk and public jwk are absent" do
      expect { DeveloperKey.create!(is_lti_key: true) }.to raise_error ActiveRecord::RecordInvalid
    end

    it "validates when public jwk is present" do
      expect { DeveloperKey.create!(is_lti_key: true, public_jwk:) }.to_not raise_error
    end

    it "validates when public jwk url is present" do
      expect { DeveloperKey.create!(is_lti_key: true, public_jwk_url:) }.to_not raise_error
    end
  end

  describe "external tool management" do
    specs_require_sharding
    include_context "lti_1_3_spec_helper"

    let(:shard_1_account) { @shard1.activate { account_model } }
    let(:developer_key) { @shard1.activate { DeveloperKey.create!(root_account: shard_1_account) } }
    let(:shard_1_tool) do
      tool = nil
      @shard1.activate do
        tool = ContextExternalTool.create!(
          name: "shard 1 tool",
          workflow_state: "public",
          developer_key:,
          context: shard_1_account,
          url: "https://www.test.com",
          consumer_key: "key",
          shared_secret: "secret"
        )
        DeveloperKeyAccountBinding.create!(
          developer_key: tool.developer_key,
          account: shard_1_account,
          workflow_state: "on"
        )
      end
      tool
    end
    let(:shard_2_account) { @shard2.activate { account_model } }
    let(:shard_2_tool) do
      tool = nil
      @shard2.activate do
        tool = ContextExternalTool.create!(
          name: "shard 2 tool",
          workflow_state: "public",
          developer_key:,
          context: shard_2_account,
          url: "https://www.test.com",
          consumer_key: "key",
          shared_secret: "secret"
        )
        DeveloperKeyAccountBinding.create!(
          developer_key: tool.developer_key,
          account: shard_2_account,
          workflow_state: "off"
        )
      end
      tool
    end

    describe "instrumentation" do
      def enable_external_tools
        developer_key.enable_external_tools!(account)
        Timecop.travel(10.seconds) do
          run_jobs
        end
      end

      before do
        developer_key
        @shard1.activate { tool_configuration }
        allow(InstStatsd::Statsd).to receive(:increment)
        allow(InstStatsd::Statsd).to receive(:timing)
      end

      around do |example|
        Timecop.freeze(&example)
      end

      context "when method succeeds" do
        it "increments success count" do
          enable_external_tools
          expect(InstStatsd::Statsd).to have_received(:increment).with("developer_key.manage_external_tools.count", any_args)
        end

        it "tracks success timing" do
          enable_external_tools
          expect(InstStatsd::Statsd).to have_received(:timing).with("developer_key.manage_external_tools.latency", be_within(5000).of(10_000), any_args)
        end
      end

      context "when method raises an exception" do
        def manage_external_tools
          developer_key.send(:manage_external_tools, developer_key.send(:tool_management_enqueue_args), :nonexistent_method, account)
          Timecop.travel(10.seconds) do
            run_jobs
          end
        end

        before do
          allow(Canvas::Errors).to receive(:capture_exception)
        end

        it "increments error count" do
          manage_external_tools
          expect(InstStatsd::Statsd).to have_received(:increment).with("developer_key.manage_external_tools.error.count", any_args)
        end

        it "tracks success timing" do
          manage_external_tools
          expect(InstStatsd::Statsd).to have_received(:timing).with("developer_key.manage_external_tools.error.latency", be_within(5000).of(10_000), any_args)
        end

        it "sends error to sentry" do
          manage_external_tools
          expect(Canvas::Errors).to have_received(:capture_exception).with(:developer_keys, instance_of(NoMethodError), :error)
        end
      end
    end

    describe "#restore_external_tools!" do
      context "when account is site admin" do
        before do
          developer_key
          @shard1.activate { tool_configuration }
          shard_1_tool.update!(root_account: shard_1_account)
          shard_2_tool.update!(root_account: shard_2_account)

          @shard1.activate do
            developer_key.restore_external_tools!(account)
            run_jobs
          end
        end

        let(:account) { Account.site_admin }

        it "restores tools in non-disabled states" do
          expect(shard_1_tool.reload.workflow_state).to eq "public"
        end

        it "restores tools in disabled states" do
          expect(shard_2_tool.reload.workflow_state).to eq "disabled"
        end
      end
    end

    describe "#disable_external_tools!" do
      before do
        developer_key
        @shard1.activate { tool_configuration }
        shard_1_tool
        shard_2_tool
        disable_external_tools
      end

      context "when account is site admin" do
        def disable_external_tools
          @shard1.activate do
            developer_key.disable_external_tools!(account)
            run_jobs
          end
        end

        let(:account) { Account.site_admin }

        it "disables tools on shard 1" do
          expect(shard_1_tool.reload.workflow_state).to eq "disabled"
        end

        it "disables tools on shard 2" do
          expect(shard_2_tool.reload.workflow_state).to eq "disabled"
        end
      end

      context "account is not site admin" do
        def disable_external_tools
          @shard1.activate do
            developer_key.disable_external_tools!(account)
            run_jobs
          end
        end

        let(:account) { shard_1_tool.root_account }

        it "disables associated tools on the active shard" do
          expect(shard_1_tool.reload.workflow_state).to eq "disabled"
        end

        it "does not disable tools on inactive shards" do
          expect(shard_2_tool.reload.workflow_state).to eq "public"
        end
      end
    end

    describe "#enable_external_tools!" do
      before do
        developer_key
        @shard1.activate { tool_configuration }
        shard_1_tool.update!(workflow_state: "disabled")
        shard_2_tool.update!(workflow_state: "disabled")
        @shard1.activate do
          developer_key.enable_external_tools!(account)
          run_jobs
        end
      end

      context "account is site admin" do
        let(:account) { Account.site_admin }

        it "enables tools on shard 1" do
          expect(shard_1_tool.reload.workflow_state).to eq "public"
        end

        it "enables tools on shard 2" do
          expect(shard_2_tool.reload.workflow_state).to eq "public"
        end
      end

      context "is_site_admin is false" do
        let(:account) { shard_1_tool.root_account }

        it "enables tools on shard 1" do
          expect(shard_1_tool.reload.workflow_state).to eq "public"
        end

        it "does not enable tools on shard 2" do
          expect(shard_2_tool.reload.workflow_state).to eq "disabled"
        end
      end

      context "privacy_level is not set on tool_configuration" do
        let(:account) { shard_1_tool.root_account }
        let(:tool_configuration) do
          tc = super()
          tc.update!(privacy_level: nil)
          tc
        end

        it "still correctly uses privacy_level from extensions" do
          expect(shard_1_tool.reload.workflow_state).to eq "public"
        end
      end
    end

    describe "#update_external_tools!" do
      def update_external_tools
        @shard1.activate do
          tool_configuration.settings["title"] = new_title
          tool_configuration.save!
          developer_key.update_external_tools!
          run_jobs
        end
      end

      let(:new_title) { "New Title!" }

      before do
        developer_key
        @shard1.activate { tool_configuration.update!(privacy_level: "anonymous") }
        shard_1_tool.update!(workflow_state: "disabled")
        shard_2_tool.update!(workflow_state: "disabled")
      end

      context "when site admin key" do
        before do
          developer_key.update!(account: nil)
          update_external_tools
          run_jobs
        end

        it "updates tools on all shard 1" do
          expect(shard_1_tool.reload.name).to eq new_title
        end

        it "updates tools on shard 2" do
          expect(shard_2_tool.reload.name).to eq new_title
        end

        it "respects tool workflow_state" do
          expect(shard_1_tool.reload.workflow_state).to eq "disabled"
          expect(shard_2_tool.reload.workflow_state).to eq "disabled"
        end
      end

      context "when non-site admin key" do
        before do
          developer_key.update!(account: shard_1_account)
          update_external_tools
          run_jobs
        end

        it "updates tools on shard 1" do
          expect(shard_1_tool.reload.name).to eq new_title
        end

        it "does not update tools on shard 2" do
          expect(shard_2_tool.reload.name).to eq "shard 2 tool"
        end

        it "respects tool workflow_state" do
          expect(shard_1_tool.reload.workflow_state).to eq "disabled"
        end
      end

      describe "when there are broken tools with no context" do
        it "does not raise an error" do
          tool = developer_key.context_external_tools.first
          tool.save!
          ContextExternalTool
            .where(id: tool.id)
            .update_all(context_id: Course.last&.id.to_i + 1, context_type: "Course")
          developer_key.tool_configuration.configuration["oidc_initiation_url"] = "example.com"
          developer_key.tool_configuration.save!
          update_external_tools
          run_jobs
          failed_jobs = Delayed::Job.where("tag LIKE ?", "DeveloperKey%").where.not(last_error: nil)
          expect(failed_jobs.to_a).to eq([])
        end
      end
    end

    describe "#manage_external_tools_multi_shard" do
      context "when there is an intermittent Postgres error" do
        it "retries the job" do
          expect(subject).to receive(:delay).and_raise(PG::ConnectionBad)
          expect do
            subject.send(:manage_external_tools_multi_shard, {}, :update_tools_on_active_shard, account_model, Time.now)
          end.to raise_error(Delayed::RetriableError)
        end
      end
    end

    describe "#manage_external_tools_multi_shard_in_region" do
      context "when there is an intermittent Postgres error" do
        it "retries the job" do
          expect(subject).to receive(:delay).and_raise(PG::ConnectionBad)
          expect do
            subject.send(:manage_external_tools_multi_shard_in_region, {}, :update_tools_on_active_shard, account_model, Time.now)
          end.to raise_error(Delayed::RetriableError)
        end
      end
    end
  end

  describe "usable_in_context?" do
    let(:account) { account_model }
    let(:developer_key) { DeveloperKey.create!(account:) }

    shared_examples_for "a boolean indicating the key is usable in context" do
      subject { developer_key.usable_in_context?(context) }

      let(:context) { raise "set in examples" }

      context "when the key is usable and the binding is on" do
        before do
          developer_key.account_binding_for(account).update!(workflow_state: "on")
        end

        it { is_expected.to be true }
      end

      context "when the key is not usable" do
        before { developer_key.update!(workflow_state: "deleted") }

        it { is_expected.to be false }
      end

      context "when the binding is not on" do
        it { is_expected.to be false }
      end
    end

    context "when the context is an account" do
      it_behaves_like "a boolean indicating the key is usable in context" do
        let(:context) { account }
      end
    end

    context "when the context is a course" do
      it_behaves_like "a boolean indicating the key is usable in context" do
        let(:context) { course_model(account:) }
      end
    end
  end

  describe "site_admin_lti scope" do
    specs_require_sharding
    include_context "lti_1_3_spec_helper"

    context "when root account and site admin keys exist" do
      subject do
        DeveloperKey.site_admin_lti(
          [
            root_account_key,
            site_admin_key,
            lti_site_admin_key
          ].map(&:global_id)
        )
      end

      let(:root_account_key) do
        @shard1.activate do
          a = account_model
          DeveloperKey.create!(
            account: a,
            tool_configuration: tool_configuration.dup
          )
        end
      end

      let(:site_admin_key) do
        Account.site_admin.shard.activate do
          DeveloperKey.create!
        end
      end

      let(:lti_site_admin_key) do
        Account.site_admin.shard.activate do
          k = DeveloperKey.create!
          Lti::ToolConfiguration.create!(
            developer_key: k,
            settings: settings.merge(public_jwk: tool_config_public_jwk)
          )
          k
        end
      end

      it { is_expected.to match_array [lti_site_admin_key] }
    end
  end

  describe "sets a default value" do
    it "when visible is not specified" do
      expect(developer_key_not_saved.valid?).to be(true)
      expect(developer_key_not_saved.visible).to be(false)
    end

    it "is false for site admin generated keys" do
      key = DeveloperKey.create!(
        name: "test",
        email: "test@test.com",
        redirect_uri: "http://test.com",
        account_id: nil
      )

      expect(key.visible).to be(false)
    end

    it "is true for non site admin generated keys" do
      key = DeveloperKey.create!(
        name: "test",
        email: "test@test.com",
        redirect_uri: "http://test.com",
        account_id: account.id
      )

      expect(key.visible).to be(true)
    end
  end

  describe "callbacks" do
    describe "public_jwk validations" do
      subject do
        developer_key_saved.save
      end

      before { developer_key_saved.generate_rsa_keypair! }

      context 'when the kty is not "RSA"' do
        before { developer_key_saved.public_jwk["kty"] = "foo" }

        it { is_expected.to be false }
      end

      context 'when the alg is not "RS256"' do
        before { developer_key_saved.public_jwk["alg"] = "foo" }

        it { is_expected.to be false }
      end

      context "when required claims are missing" do
        before { developer_key_saved.update public_jwk: { foo: "bar" } }

        it { is_expected.to be false }
      end
    end

    it "de-duplicates the scope list" do
      key = DeveloperKey.create!(
        scopes: [
          "url:GET|/api/v1/courses/:course_id/quizzes",
          "url:GET|/api/v1/courses/:course_id/users",
          "url:GET|/api/v1/courses/:course_id/quizzes",
          "url:GET|/api/v1/courses/:course_id/users",
        ]
      )

      expect(key.scopes.sort).to eq [
        "url:GET|/api/v1/courses/:course_id/quizzes",
        "url:GET|/api/v1/courses/:course_id/users",
      ]
    end

    it "does validate scopes" do
      expect do
        DeveloperKey.create!(
          scopes: ["not_a_valid_scope"]
        )
      end.to raise_exception ActiveRecord::RecordInvalid
    end

    it "rejects changes to routes.rb if it would break an existing scope" do
      stub_const("CanvasRails::Application", TokenScopesHelper::SpecHelper::MockCanvasRails::Application)
      all_routes = Set.new(TokenScopes.api_routes.pluck(:verb, :path))

      modified_scopes = TokenScopesHelper::SpecHelper.last_known_accepted_scopes.reject do |scope|
        all_routes.include? scope
      end

      error_message = <<~TEXT
        These routes are used by developer key scopes, and have been changed:
        #{modified_scopes.map { |scope| "- #{scope[0]}: #{scope[1]}" }.join("\n")}

        If these routes must be changed, it will require a data fixup to change
        the scope attribute of any developer keys that refer to those routes.
        The list of API routes used by developer keys can be changed in
        spec/lib/token_scopes/last_known_scopes.yml.
      TEXT
      expect(modified_scopes).to be_empty, error_message
    end

    it "ensures that newly added routes are included in the known scopes list" do
      all_routes_including_plugins = Set.new(TokenScopes.api_routes.pluck(:verb, :path))

      stub_const("CanvasRails::Application", TokenScopesHelper::SpecHelper::MockCanvasRails::Application)

      routes_from_plugins = Set.new
      Dir[Rails.root.join("{gems,vendor}/plugins/*/config/*routes.rb")].each do |plugin_path|
        CanvasRails::Application.reset_routes
        load plugin_path
        plugin_route_set = Set.new(CanvasRails::Application.routes.routes.map do |route|
          [route.verb, TokenScopesHelper.path_without_format(route)]
        end)
        routes_from_plugins = routes_from_plugins.merge(plugin_route_set)
      end

      # Take all routes, subtract the ones added in plugins (we'll look for those in their
      # respective repos), and then omit any that are already in the known route list.
      # If any routes remain, it must have been added after the known route list was last
      # updated.
      newly_added_routes = (all_routes_including_plugins - routes_from_plugins).reject! do |route|
        TokenScopesHelper::SpecHelper.last_known_accepted_scopes.include? route
      end

      error_message = <<~TEXT
        These routes have been added by your commit, and need to be included
        in spec/lib/token_scopes/last_known_accepted_scopes.rb.
        #{newly_added_routes.map { |scope| "- #{scope[0]}: #{scope[1]}" }.join("\n")}

        This allows us to keep track of which API routes can be specified on a
        developer key, so that we can avoid making breaking changes to those
        API routes later.
      TEXT

      expect(newly_added_routes).to be_empty, error_message
    end

    context "when api token scoping FF is enabled" do
      let(:valid_scopes) do
        %w[url:POST|/api/v1/courses/:course_id/quizzes/:id/validate_access_code
           url:GET|/api/v1/audit/grade_change/courses/:course_id/assignments/:assignment_id/graders/:grader_id]
      end

      describe "before_save" do
        subject do
          key.save!
          key.require_scopes
        end

        context "when a public jwk is set" do
          let(:key) do
            developer_key_not_saved.generate_rsa_keypair!
            developer_key_not_saved
          end

          it { is_expected.to be true }
        end

        context "when a public jwk is not set" do
          let(:key) { developer_key_not_saved }

          it { is_expected.to be false }
        end

        context "when a key requires scopes but has no public jwk" do
          let(:key) do
            developer_key_not_saved.update!(
              require_scopes: true,
              public_jwk: nil
            )
            developer_key_not_saved
          end

          it { is_expected.to be true }
        end
      end

      describe "after_update" do
        let(:user) { user_model }
        let(:developer_key_with_scopes) { DeveloperKey.create!(scopes: valid_scopes) }
        let(:access_token) { user.access_tokens.create!(developer_key: developer_key_with_scopes) }
        let(:valid_scopes) do
          [
            "url:GET|/api/v1/courses/:course_id/quizzes",
            "url:GET|/api/v1/courses/:course_id/quizzes/:id",
            "url:GET|/api/v1/courses/:course_id/users",
            "url:GET|/api/v1/courses/:id",
            "url:GET|/api/v1/users/:user_id/profile",
            "url:POST|/api/v1/courses/:course_id/assignments",
            "url:POST|/api/v1/courses/:course_id/quizzes",
          ]
        end

        before { access_token }

        it "deletes its associated access tokens if scopes are removed" do
          developer_key_with_scopes.update!(scopes: [valid_scopes.first])
          expect(developer_key_with_scopes.access_tokens).to be_empty
        end

        it "does not delete its associated access tokens if scopes are not changed" do
          developer_key_with_scopes.update!(email: "test@test.com")
          expect(developer_key_with_scopes.access_tokens).to match_array [access_token]
        end

        it "does not delete its associated access tokens if a new scope was added" do
          developer_key_with_scopes.update!(scopes: valid_scopes.push("url:PUT|/api/v1/courses/:course_id/quizzes/:id"))
          expect(developer_key_with_scopes.access_tokens).to match_array [access_token]
        end
      end

      it "raises an error if scopes contain invalid scopes" do
        expect do
          DeveloperKey.create!(
            scopes: ["not_a_valid_scope"]
          )
        end.to raise_exception("Validation failed: Scopes cannot contain not_a_valid_scope")
      end

      it "does not raise an error if all scopes are valid scopes" do
        expect do
          DeveloperKey.create!(
            scopes: valid_scopes
          )
        end.not_to raise_exception
      end
    end

    context "when site admin" do
      let(:key) { DeveloperKey.create!(account: nil) }

      it "creates a binding on save" do
        expect(key.developer_key_account_bindings.find_by(account: Account.site_admin)).to be_present
      end

      describe "destroy_external_tools!" do
        subject do
          @shard1.activate { ContextExternalTool.active }.merge(
            @shard2.activate { ContextExternalTool.active }
          )
        end

        include_context "lti_1_3_spec_helper"
        specs_require_sharding

        context "when developer key is an LTI key" do
          let(:shard_1_account) { @shard1.activate { account_model } }
          let(:shard_2_account) { @shard2.activate { account_model } }
          let(:configuration) { Account.site_admin.shard.activate { tool_configuration } }
          let(:shard_1_tool) do
            t = @shard1.activate { configuration.new_external_tool(shard_1_account) }
            t.save!
            t
          end
          let(:shard_2_tool) do
            t = @shard2.activate { configuration.new_external_tool(shard_2_account) }
            t.save!
            t
          end

          before do
            shard_1_tool
            shard_2_tool
            developer_key.update!(account: nil)
          end

          it "destroys associated tools across all shards" do
            developer_key.destroy
            run_jobs
            expect(subject).to be_empty
          end

          context "when tools are installed at the course level" do
            let(:shard_1_course) { shard_1_account.shard.activate { course_model(account: shard_1_account) } }
            let(:shard_1_course_tool) do
              t = @shard1.activate { configuration.new_external_tool(shard_1_course) }
              t.save!
              t
            end

            before do
              shard_1_course_tool
            end

            it "destroys associated tools across all shards" do
              developer_key.destroy
              run_jobs
              expect(subject).to be_empty
            end
          end
        end
      end
    end

    context "when not site admin" do
      it "creates a binding on save" do
        key = DeveloperKey.create!(account:)
        expect(key.developer_key_account_bindings.find_by(account:)).to be_present
      end

      describe "destroy_external_tools!" do
        subject { ContextExternalTool.active }

        include_context "lti_1_3_spec_helper"
        specs_require_sharding

        let(:account) { account_model }
        let(:tool) do
          t = tool_configuration.new_external_tool(account)
          t.save!
          t
        end

        before do
          tool
        end

        context "when developer key is an LTI key" do
          it "destroys associated tools on the current shard" do
            developer_key.destroy
            run_jobs
            expect(subject).to be_empty
          end

          context "when tools are installed at the course level" do
            let(:course) { course_model(account:) }
            let(:course_tool) do
              t = tool_configuration.new_external_tool(course)
              t.save!
              t
            end

            before { course_tool }

            it "destroys associated tools on the current shard" do
              developer_key.destroy
              run_jobs
              expect(subject).to be_empty
            end
          end
        end
      end
    end

    describe "after_save" do
      describe "set_root_account" do
        context "when account is not root account" do
          let(:account) { account_model(root_account: Account.create!) }

          it "sets root account equal to account's root account" do
            expect(developer_key_not_saved.root_account).to be_nil
            developer_key_not_saved.account = account
            developer_key_not_saved.save!
            expect(developer_key_not_saved.root_account).to eq account.root_account
          end
        end

        context "when accout is site admin" do
          subject { developer_key_not_saved.root_account }

          let(:account) { nil }

          before { developer_key_not_saved.update!(account:) }

          it { is_expected.to eq Account.site_admin }
        end

        context "when account is root account" do
          let(:account) { account_model }

          it "set root account equal to account" do
            expect(developer_key_not_saved.root_account).to be_nil
            developer_key_not_saved.account = account
            developer_key_not_saved.save!
            expect(developer_key_not_saved.root_account).to eq account
          end
        end
      end
    end
  end

  describe "associations" do
    let(:developer_key_account_binding) { developer_key_saved.developer_key_account_bindings.first }

    it { is_expected.to belong_to(:service_user) }

    it "destroys developer key account bindings when destroyed" do
      binding_id = developer_key_account_binding.id
      developer_key_saved.destroy_permanently!
      expect(DeveloperKeyAccountBinding.find_by(id: binding_id)).to be_nil
    end

    it "has many context external tools" do
      tool = ContextExternalTool.create!(
        context: account,
        consumer_key: "key",
        shared_secret: "secret",
        name: "test tool",
        url: "http://www.tool.com/launch",
        developer_key: developer_key_saved
      )
      expect(developer_key_saved.context_external_tools).to match_array [
        tool
      ]
    end
  end

  describe "#account_binding_for" do
    let(:site_admin_key) { DeveloperKey.create!(account: nil) }
    let(:root_account_key) { DeveloperKey.create!(account: root_account) }
    let(:root_account) { account_model }

    context "when account passed is nil" do
      it "returns nil" do
        expect(site_admin_key.account_binding_for(nil)).to be_nil
        expect(root_account_key.account_binding_for(nil)).to be_nil
      end
    end

    context "when site admin" do
      context 'when binding state is "allow"' do
        before do
          site_admin_key.developer_key_account_bindings.create!(
            account: root_account, workflow_state: "allow"
          )
        end

        it "finds the site admin binding when requesting site admin account" do
          binding = site_admin_key.account_binding_for(Account.site_admin)
          expect(binding.account).to eq Account.site_admin
        end

        it "finds the root account binding when requesting root account" do
          site_admin_key.developer_key_account_bindings.first.update!(workflow_state: "allow")
          binding = site_admin_key.account_binding_for(root_account)
          expect(binding.account).to eq root_account
        end
      end

      context 'when binding state is "on" or "off"' do
        before do
          site_admin_key.developer_key_account_bindings.create!(account: root_account, workflow_state: "on")
          sa_binding = site_admin_key.developer_key_account_bindings.find_by(account: Account.site_admin)
          sa_binding.update!(workflow_state: "off")
        end

        it "finds the site admin binding when requesting site admin account" do
          binding = site_admin_key.account_binding_for(Account.site_admin)
          expect(binding.account).to eq Account.site_admin
        end

        it "finds the site admin binding when requesting root account" do
          binding = site_admin_key.account_binding_for(root_account)
          expect(binding.account).to eq Account.site_admin
        end
      end
    end

    context "when not site admin" do
      context 'when binding state is "allow"' do
        it "finds the root account binding when requesting root account" do
          binding = root_account_key.account_binding_for(root_account)
          expect(binding.account).to eq root_account
        end
      end

      context 'when binding state is "on" or "off"' do
        before do
          root_account_key.developer_key_account_bindings.create!(account: Account.site_admin, workflow_state: "on")
          ra_binding = root_account_key.developer_key_account_bindings.find_by(account: root_account)
          ra_binding.update!(workflow_state: "off")
        end

        it "finds the site admin binding when requesting site admin account" do
          binding = root_account_key.account_binding_for(Account.site_admin)
          expect(binding.account).to eq Account.site_admin
        end

        it "finds the root account binding when requesting root account" do
          binding = root_account_key.account_binding_for(root_account)
          expect(binding.account).to eq root_account
        end
      end
    end

    context "sharding" do
      specs_require_sharding

      let(:root_account_shard) { @shard1 }
      let(:root_account) { root_account_shard.activate { account_model } }
      let(:sa_developer_key) { Account.site_admin.shard.activate { DeveloperKey.create!(name: "SA Key") } }
      let(:root_account_binding) do
        root_account_shard.activate do
          DeveloperKeyAccountBinding.create!(
            account_id: root_account.id,
            developer_key_id: sa_developer_key.global_id
          )
        end
      end
      let(:sa_account_binding) { sa_developer_key.developer_key_account_bindings.find_by(account: Account.site_admin) }

      context "when the developer key and account are on different, non site-admin shards" do
        it "doesn't return a binding for an account with the same local ID on a different shard" do
          expect(root_account.shard.id).to_not eq(@shard2.id)
          @shard2.activate do
            account = Account.find_by(id: root_account.local_id)
            account ||= Account.create!(id: root_account.local_id)
            shard2_developer_key = DeveloperKey.create!(name: "Shard 2 Key", account_id: account.id)
            expect(shard2_developer_key.account_binding_for(account)).to_not be_nil
            expect(shard2_developer_key.account_binding_for(root_account)).to be_nil
          end
        end
      end

      context "when the developer key and account are on different shards" do
        it "doesn't return a binding for an developer key with the same local ID on a different shard" do
          root_account2 = @shard2.activate { account_model }
          developer_key = root_account_shard.activate do
            DeveloperKey.create!(account: root_account)
          end

          @shard2.activate do
            dk2 = DeveloperKey.create!(account: root_account2, id: developer_key.local_id)
            DeveloperKeyAccountBinding.find_or_initialize_by(
              account: root_account2, developer_key: dk2
            ).update(workflow_state: :on)
            expect(developer_key.account_binding_for(root_account2)).to be_nil
          end
          expect(developer_key.account_binding_for(root_account2)).to be_nil

          root_account_shard.activate do
            # specifically, this one will fail if we look up by developer key id (local id on that shard)
            expect(developer_key.account_binding_for(root_account2)).to be_nil
          end
        end
      end

      context "when developer key binding is on the site admin shard" do
        it 'finds the site admin binding if it is set to "on"' do
          root_account_binding.update!(workflow_state: "on")
          sa_account_binding.update!(workflow_state: "off")
          binding = root_account_shard.activate { sa_developer_key.account_binding_for(root_account) }
          expect(binding.account).to eq Account.site_admin
        end

        it 'finds the site admin binding if it is set to "off"' do
          root_account_binding.update!(workflow_state: "off")
          sa_account_binding.update!(workflow_state: "on")
          binding = root_account_shard.activate { sa_developer_key.account_binding_for(root_account) }
          expect(binding.account).to eq Account.site_admin
        end

        it 'finds the root account binding if site admin binding is set to "allow"' do
          root_account_binding.update!(workflow_state: "on")
          sa_account_binding.update!(workflow_state: "allow")
          binding = root_account_shard.activate { sa_developer_key.account_binding_for(root_account) }
          expect(binding.account).to eq root_account
        end
      end
    end
  end

  describe "default" do
    context "sharding" do
      specs_require_sharding

      it "always creates the default key on the default shard" do
        @shard1.activate do
          expect(DeveloperKey.default.shard).to be_default
        end
      end

      it "sets new developer keys to auto expire tokens" do
        expect(developer_key_saved.auto_expire_tokens).to be_truthy
      end

      it "uses integer special keys properly because the query does not like strings" do
        # this test mirrors what happens in production when retrieving keys, but does not test it
        # directly because there's a short circuit clause in 'get_special_key' that pops out with a
        # different finder because of the transactions-in-test issue. this confirms that setting
        # a key id does not translate it to a string and therefore can be used with 'where(id: key_id)'
        # safely

        Setting.set("rspec_developer_key_id", developer_key_saved.id)
        key_id = Setting.get("rspec_developer_key_id", nil)
        expect(DeveloperKey.where(id: key_id).first).to eq(developer_key_saved)
      end
    end
  end

  it "allows non-http redirect URIs" do
    developer_key_not_saved.redirect_uri = "tealpass://somewhere.edu/authentication"
    developer_key_not_saved.redirect_uris = ["tealpass://somewhere.edu/authentication"]
    expect(developer_key_not_saved).to be_valid
  end

  it "doesn't allow redirect_uris over 4096 characters" do
    developer_key_not_saved.redirect_uris = ["https://test.example.com/" + ("a" * 4097), "https://example.com"]
    expect(developer_key_not_saved).not_to be_valid
  end

  it "doesn't allow non-URIs" do
    developer_key_not_saved.redirect_uris = ["@?!"]
    expect(developer_key_not_saved).not_to be_valid
  end

  it "returns the correct count of access_tokens" do
    expect(developer_key_saved.access_token_count).to eq 0

    AccessToken.create!(user: user_model, developer_key: developer_key_saved)
    AccessToken.create!(user: user_model, developer_key: developer_key_saved)
    AccessToken.create!(user: user_model, developer_key: developer_key_saved)

    expect(developer_key_saved.reload.access_token_count).to eq 3
  end

  it "returns the last_used_at value for a key" do
    expect(developer_key_saved.last_used_at).to be_nil
    at = AccessToken.create!(user: user_model, developer_key: developer_key_saved)
    at.used!
    expect(developer_key_saved.last_used_at).not_to be_nil
  end

  describe "#generate_rsa_keypair!" do
    context 'when "public_jwk" is already set' do
      subject do
        developer_key.generate_rsa_keypair!
        developer_key
      end

      let(:developer_key) do
        key = DeveloperKey.create!
        key.generate_rsa_keypair!
        key.save!
        key
      end
      let(:public_jwk) { developer_key.public_jwk }

      context 'when "override" is false' do
        it 'does not change the "public_jwk"' do
          expect(subject.public_jwk).to eq public_jwk
        end

        it 'does not change the "private_jwk" attribute' do
          previous_private_key = developer_key.private_jwk
          expect(subject.private_jwk).to eq previous_private_key
        end
      end

      context 'when "override: is true' do
        subject do
          developer_key.generate_rsa_keypair!(overwrite: true)
          developer_key
        end

        it 'does change the "public_jwk"' do
          previous_public_key = developer_key.public_jwk
          expect(subject.public_jwk).not_to eq previous_public_key
        end

        it 'does change the "private_jwk"' do
          previous_private_key = developer_key.private_jwk
          expect(subject.private_jwk).not_to eq previous_private_key
        end
      end
    end

    context 'when "public_jwk" is not set' do
      subject { DeveloperKey.new }

      before { subject.generate_rsa_keypair! }

      it 'populates the "public_jwk" column with a public key' do
        expect(subject.public_jwk["kty"]).to eq CanvasSecurity::RSAKeyPair::KTY
      end

      it 'populates the "private_jwk" attribute with a private key' do
        expect(subject.private_jwk["kty"]).to eq CanvasSecurity::RSAKeyPair::KTY.to_sym
      end
    end
  end

  describe "#redirect_domain_matches?" do
    it "matches domains exactly, and sub-domains" do
      developer_key_not_saved.redirect_uri = "http://example.com/a/b"

      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/a/b")).to be_truthy

      # other paths on the same domain are ok
      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/other")).to be_truthy

      # completely separate domain
      expect(developer_key_not_saved.redirect_domain_matches?("http://example2.com/a/b")).to be_falsey

      # not a sub-domain
      expect(developer_key_not_saved.redirect_domain_matches?("http://wwwexample.com/a/b")).to be_falsey
      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com.evil/a/b")).to be_falsey
      expect(developer_key_not_saved.redirect_domain_matches?("http://www.example.com.evil/a/b")).to be_falsey

      # sub-domains are ok
      expect(developer_key_not_saved.redirect_domain_matches?("http://www.example.com/a/b")).to be_truthy
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/a/b")).to be_truthy
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/other")).to be_truthy
    end

    it "does not allow subdomains when it matches in redirect_uris" do
      developer_key_not_saved.redirect_uris << "http://example.com/a/b"

      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/a/b")).to be true

      # other paths on the same domain are NOT ok
      expect(developer_key_not_saved.redirect_domain_matches?("http://example.com/other")).to be false
      # sub-domains are not ok either
      expect(developer_key_not_saved.redirect_domain_matches?("http://www.example.com/a/b")).to be false
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/a/b")).to be false
      expect(developer_key_not_saved.redirect_domain_matches?("http://a.b.example.com/other")).to be false
    end

    it "requires scheme to match on lenient matches" do
      developer_key_not_saved.redirect_uri = "http://example.com/a/b"

      expect(developer_key_not_saved.redirect_domain_matches?("http://www.example.com/a/b")).to be true
      expect(developer_key_not_saved.redirect_domain_matches?("intents://www.example.com/a/b")).to be false
    end
  end

  context "Account scoped keys" do
    shared_examples "authorized_for_account?" do
      it "allows access to its own account" do
        expect(@key.authorized_for_account?(Account.find(@account.id))).to be true
      end

      it "does not allow access to a foreign account" do
        expect(@key.authorized_for_account?(@not_sub_account)).to be false
      end

      it "allows access if the account is in its account chain" do
        sub_account = Account.create!(parent_account: @account)
        expect(@key.authorized_for_account?(sub_account)).to be true
      end
    end

    context "with sharding" do
      specs_require_sharding

      before :once do
        @account = Account.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(redirect_uri: "http://example.com/a/b", account: @account)
        enable_developer_key_account_binding!(@key)
      end

      include_examples "authorized_for_account?"

      describe "#by_cached_vendor_code" do
        let(:vendor_code) { "tool vendor code" }
        let(:not_site_admin_shard) { @shard1 }

        it "finds keys in the site admin shard" do
          site_admin_key = nil

          Account.site_admin.shard.activate do
            site_admin_key = DeveloperKey.create!(vendor_code:)
          end

          not_site_admin_shard.activate do
            expect(DeveloperKey.by_cached_vendor_code(vendor_code)).to include site_admin_key
          end
        end

        it "finds keys in the current shard" do
          local_key = DeveloperKey.create!(vendor_code:, account: account_model)
          expect(DeveloperKey.by_cached_vendor_code(vendor_code)).to include local_key
        end
      end
    end

    context "without sharding" do
      before :once do
        @account = Account.create!

        @not_sub_account = Account.create!
        @key = DeveloperKey.create!(redirect_uri: "http://example.com/a/b", account: @account)
        enable_developer_key_account_binding!(@key)
      end

      include_examples "authorized_for_account?"
    end
  end

  it "doesn't allow the default key to be deleted" do
    expect { DeveloperKey.default.destroy }.to raise_error "Please never delete the default developer key"
    expect { DeveloperKey.default.deactivate }.to raise_error "Please never delete the default developer key"
  end

  describe "issue_token" do
    subject { DeveloperKey.create! }

    let(:claims) { { "key" => "value" } }
    let(:asymmetric_keypair) { CanvasSecurity::RSAKeyPair.new.to_jwk }
    let(:asymmetric_public_key) { asymmetric_keypair.to_key.public_key.to_jwk }

    before do
      # set up assymetric key
      allow(Canvas::OAuth::KeyStorage).to receive(:present_key).and_return(asymmetric_keypair)
    end

    it "defaults to internal symmetric encryption with no audience set" do
      expect(subject.client_credentials_audience).to be_nil
      token = subject.issue_token(claims)
      decoded = Canvas::Security.decode_jwt(token)
      expect(decoded).to eq claims
    end

    it "uses to symmetric encryption with audience set to internal" do
      subject.client_credentials_audience = "internal"
      subject.save!
      token = subject.issue_token(claims)
      decoded = Canvas::Security.decode_jwt(token)
      expect(decoded).to eq claims
    end

    it "uses to asymmetric encryption with audience set to external" do
      subject.client_credentials_audience = "external"
      subject.save!
      token = subject.issue_token(claims)
      decoded = JSON::JWT.decode(token, asymmetric_public_key)
      expect(decoded).to eq claims
    end
  end
end
