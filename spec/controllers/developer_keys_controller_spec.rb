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

describe DeveloperKeysController do
  let(:test_domain_root_account) { Account.create! }
  let(:site_admin_key) { DeveloperKey.create!(name: "Site Admin Key", visible: false) }
  let(:sub_account) { test_domain_root_account.sub_accounts.create!(parent_account: test_domain_root_account, root_account: test_domain_root_account) }

  let(:root_account_key) do
    DeveloperKey.create!(name: "Root Account Key", account: test_domain_root_account, visible: true)
  end

  let(:error_metric_name) do
    "canvas.developer_keys_controller.request_error"
  end

  context "Site admin" do
    before do
      account_admin_user(account: Account.site_admin)
    end

    describe "GET 'index'" do
      context "with no session" do
        it "requires authorization" do
          get "index", params: { account_id: Account.site_admin.id }
          expect(response).to be_redirect
        end
      end

      context "with a session" do
        let(:expected_id) { json_parse(response.body).first["id"] }

        before do
          user_session(@admin)
        end

        describe "Setting is set" do
          render_views

          it "sets the scopes to empty" do
            dk = DeveloperKey.create!
            enable_developer_key_account_binding!(dk)
            get "index", params: { account_id: Account.site_admin.id, format: :json }
            expect(response).to be_successful
            developer_key = json_parse(response.body).first
            expect(developer_key["scopes"]).to eq([])
          end
        end

        it "returns the list of developer keys" do
          dk = DeveloperKey.create!
          get "index", params: { account_id: Account.site_admin.id }, format: :json
          expect(response).to be_successful
          expect(expected_id).to eq(dk.global_id)
        end

        it "does not include non-siteadmin keys" do
          site_admin_key = DeveloperKey.create!
          DeveloperKey.create!(account: Account.default)

          get "index", params: { account_id: Account.site_admin.id }, format: :json

          expect(json_parse.pluck("id")).to match_array [site_admin_key.global_id]
        end

        it "includes valid LTI scopes in js env" do
          get "index", params: { account_id: Account.site_admin.id }
          expect(assigns[:js_env][:validLtiScopes]).to eq TokenScopes::LTI_SCOPES
        end

        it "includes all valid LTI placements in js env" do
          # enable conference placement
          Account.site_admin.enable_feature! :conference_selection_lti_placement
          get "index", params: { account_id: Account.site_admin.id }
          expect(assigns.dig(:js_env, :validLtiPlacements)).to match_array Lti::ResourcePlacement.public_placements(Account.site_admin)
        end

        it 'includes the "includes parameter" release flag' do
          get "index", params: { account_id: Account.site_admin.id }
          expect(assigns.dig(:js_env, :includesFeatureFlagEnabled)).to be false
        end

        describe "js bundles" do
          render_views

          it "includes developer_keys" do
            get "index", params: { account_id: Account.site_admin.id }
            expect(response).to render_template(:index)
            expect(response).to be_successful
          end
        end

        it "does not include deleted keys" do
          dk = DeveloperKey.create!
          dk.destroy
          get "index", params: { account_id: Account.site_admin.id }, format: :json
          expect(response).to be_successful
          expect(expected_id).not_to eq(dk.global_id)
        end

        it "includes inactive keys" do
          dk = DeveloperKey.create!
          dk.deactivate!
          get "index", params: { account_id: Account.site_admin.id }, format: :json
          expect(response).to be_successful
          expect(json_parse(response.body).second["id"]).to eq(dk.global_id)
        end

        it "includes the key's 'vendor_code'" do
          DeveloperKey.create!(vendor_code: "test_vendor_code")
          get "index", params: { account_id: Account.site_admin.id }, format: :json
          expect(json_parse(response.body).first["vendor_code"]).to eq "test_vendor_code"
        end

        it "includes the key's 'visibility'" do
          key = DeveloperKey.create!
          enable_developer_key_account_binding! key
          get "index", params: { account_id: Account.site_admin.id }, format: :json
          developer_key = json_parse(response.body).first
          expect(developer_key["visible"]).to eq(key.visible)
        end

        it "includes non-visible keys created in site admin" do
          site_admin_key = DeveloperKey.create!(name: "Site Admin Key", visible: false)
          get "index", params: { account_id: "site_admin" }, format: :json
          expect(expected_id).to eq site_admin_key.global_id
        end

        context "with inherited param" do
          before do
            site_admin_key
            root_account_key
          end

          context "on site_admin account" do
            it "returns empty array" do
              get "index", params: { inherited: true, account_id: "site_admin", format: "json" }
              developer_keys = json_parse(response.body)
              expect(developer_keys.size).to eq 0
            end
          end

          context "on root account" do
            context "with site_admin key visible" do
              it "returns only the keys from site_admin" do
                dev_key = DeveloperKey.create!(name: "Site Admin Key 2")
                enable_developer_key_account_binding! dev_key
                dev_key.update!(visible: true)
                get "index", params: { inherited: true, account_id: test_domain_root_account.id, format: "json" }
                developer_keys = json_parse(response.body)
                expect(developer_keys.size).to eq 1
                expect(developer_keys.first["name"]).to eq "Site Admin Key 2"
              end
            end

            context "with site_admin key not visible" do
              it "returns empty array" do
                get "index", params: { inherited: true, account_id: test_domain_root_account.id, format: "json" }
                developer_keys = json_parse(response.body)
                expect(developer_keys.size).to eq 0
              end
            end
          end
        end

        context "when request fails" do
          before do
            allow(InstStatsd::Statsd).to receive(:increment)
          end

          it "reports error metric" do
            get :index, params: { account_id: Account.last.id + 2, format: "json" }
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "index", code: 404 })
            expect(response).to be_not_found
          end
        end
      end
    end

    describe "POST 'create'" do
      let(:create_params) do
        {
          account_id: Account.site_admin.id,
          developer_key: {
            redirect_uri: "http://example.com/sdf"
          }
        }
      end

      before do
        user_session(@admin)
      end

      it "returns the newly created key" do
        post "create", params: create_params

        json_data = response.parsed_body
        expect(response).to be_successful
        key = DeveloperKey.find(json_data["id"])
        expect(key.account).to be_nil
      end

      it "cannot create keys for a subaccount" do
        post "create", params: create_params.merge(account_id: sub_account.id)
        expect(response).to be_not_found
      end

      context "when request errors" do
        before do
          allow(InstStatsd::Statsd).to receive(:increment)
        end

        context "when request fails" do
          before do
            # kind of weird trying to find _something_ that could fail during a key creation or serialization
            allow(DeveloperKey).to receive(:test_cluster_checks_enabled?).and_raise(ActiveRecord::StatementInvalid)
          end

          it "reports error metric with code 500" do
            post :create, params: create_params
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "create", code: 500 })
          end
        end

        context "when key validation fails" do
          let(:create_params) do
            {
              account_id: Account.site_admin.id,
              developer_key: {
                redirect_uri: "http://example.com/sdf",
                scopes: ["bad_scope"]
              }
            }
          end

          it "reports error metric with code 400" do
            post :create, params: create_params
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "create", code: 400 })
          end
        end
      end

      describe "scopes" do
        let(:valid_scopes) do
          %w[url:POST|/api/v1/courses/:course_id/quizzes/:id/validate_access_code
             url:GET|/api/v1/audit/grade_change/courses/:course_id/assignments/:assignment_id/graders/:grader_id]
        end
        let(:invalid_scopes) { ["url:POST/banana", "url:POST/invalid/scope"] }
        let(:root_account) { account_model }

        it 'allows setting "allow_includes"' do
          post "create", params: { account_id: root_account.id, developer_key: { scopes: valid_scopes, allow_includes: true } }
          expect(DeveloperKey.find(json_parse["id"]).allow_includes).to be true
        end

        it "allows setting scopes" do
          post "create", params: { account_id: root_account.id, developer_key: { scopes: valid_scopes } }
          expect(DeveloperKey.find(json_parse["id"]).scopes).to match_array valid_scopes
        end

        it "returns an error if an invalid scope is used" do
          post "create", params: { account_id: root_account.id, developer_key: { scopes: invalid_scopes } }
          expect(json_parse.dig("errors", "scopes").first["attribute"]).to eq "scopes"
        end

        it "does not create the key if any scopes are invalid" do
          expect do
            post "create", params: { account_id: root_account.id, developer_key: { scopes: invalid_scopes.concat(valid_scopes) } }
          end.not_to change(DeveloperKey, :count)
        end
      end
    end

    describe "PUT 'update'" do
      let(:dk) { DeveloperKey.create! }

      before do
        user_session(@admin)
      end

      it "deactivates a key" do
        put "update", params: { id: dk.id, developer_key: { event: :deactivate }, account_id: Account.site_admin.id }
        expect(response).to be_successful
        expect(dk.reload.state).to eq :inactive
      end

      it "reactivates a key" do
        dk.deactivate!
        put "update", params: { id: dk.id, developer_key: { event: :activate }, account_id: Account.site_admin.id }
        expect(response).to be_successful
        expect(dk.reload.state).to eq :active
      end

      context "when request errors" do
        before do
          allow(InstStatsd::Statsd).to receive(:increment)
        end

        context "when key is not found" do
          it "reports error metric with code 404" do
            put :update, params: { id: dk.id + 1, developer_key: { name: "update key" }, account_id: Account.site_admin.id }
            expect(response).to be_not_found
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "update", code: 404 })
          end
        end

        context "when request fails" do
          before do
            # kind of weird trying to find _something_ that could fail during a key update or serialization
            allow(DeveloperKey).to receive(:test_cluster_checks_enabled?).and_raise(ActiveRecord::StatementInvalid)
          end

          it "reports error metric with code 500" do
            put :update, params: { id: dk.id, developer_key: { name: "update key" }, account_id: Account.site_admin.id }
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "update", code: 500 })
          end
        end

        context "when key validation fails" do
          it "reports error metric with code 400" do
            put :update, params: { id: dk.id, developer_key: { scopes: ["bad_scope"] }, account_id: Account.site_admin.id }
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "update", code: 400 })
          end
        end
      end

      describe "scopes" do
        let(:valid_scopes) do
          %w[url:POST|/api/v1/courses/:course_id/quizzes/:id/validate_access_code
             url:GET|/api/v1/audit/grade_change/courses/:course_id/assignments/:assignment_id/graders/:grader_id]
        end
        let(:invalid_scopes) { ["url:POST|/api/v1/banana", "not_a_scope"] }
        let(:root_account) { account_model }
        let(:developer_key) { DeveloperKey.create!(account: account_model) }
        let(:site_admin_key) { DeveloperKey.create! }

        before do
          user_session(@admin)
        end

        it 'allows setting "allow_includes"' do
          put "update", params: { id: developer_key.id, developer_key: { scopes: valid_scopes, allow_includes: false } }
          expect(developer_key.reload.allow_includes).to be false
        end

        it "allows setting scopes for site admin keys" do
          put "update", params: { id: site_admin_key.id, developer_key: { scopes: valid_scopes } }
          expect(site_admin_key.reload.scopes).to match_array valid_scopes
        end

        it "allows setting scopes" do
          put "update", params: { id: developer_key.id, developer_key: { scopes: valid_scopes } }
          expect(developer_key.reload.scopes).to match_array valid_scopes
        end

        it "returns an error if an invalid scope is used" do
          put "update", params: { id: developer_key.id, developer_key: { scopes: invalid_scopes } }
          expect(json_parse.dig("errors", "scopes").first["attribute"]).to eq "scopes"
        end

        it "does not persist scopes if any are invalid" do
          put "update", params: { id: developer_key.id, developer_key: { scopes: invalid_scopes.concat(valid_scopes) } }
          expect(developer_key.reload.scopes).to be_blank
        end

        it "sets the scopes to empty if the scopes parameter is an empty string" do
          put "update", params: { id: developer_key.id, developer_key: { scopes: "" } }
          expect(developer_key.reload.scopes).to be_empty
        end
      end
    end

    describe "DELETE 'destroy'" do
      let(:dk) { DeveloperKey.create! }

      before do
        user_session(@admin)
      end

      it "softs delete a key" do
        delete :destroy, params: { id: dk.id, account_id: Account.site_admin.id }
        expect(response).to be_successful
        expect(dk.reload.state).to eq :deleted
      end

      context "when request errors" do
        before do
          allow(InstStatsd::Statsd).to receive(:increment)
        end

        context "when key is not found" do
          it "reports error metric with code 404" do
            delete :destroy, params: { id: dk.id + 1, account_id: Account.site_admin.id }
            expect(response).to be_not_found
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "destroy", code: 404 })
          end
        end

        context "when request fails" do
          before do
            # kind of weird trying to find _something_ that could fail during a key deletion or serialization
            allow(DeveloperKey).to receive(:test_cluster_checks_enabled?).and_raise(ActiveRecord::StatementInvalid)
          end

          it "reports error metric with code 500" do
            delete :destroy, params: { id: dk.id, account_id: Account.site_admin.id }
            expect(InstStatsd::Statsd).to have_received(:increment).with(error_metric_name, tags: { action: "destroy", code: 500 })
          end
        end
      end
    end
  end

  context "Account admin (not site admin)" do
    let(:test_domain_root_account_admin) { account_admin_user(account: test_domain_root_account) }

    before do
      user_session(test_domain_root_account_admin)
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(test_domain_root_account)
    end

    describe "#index" do
      let(:expected_id) { json_parse(response.body).first["id"] }

      before do
        site_admin_key
        root_account_key
        allow_any_instance_of(Account).to receive(:feature_enabled?).and_return(false)
      end

      it "responds with not found if the account is a subaccount" do
        allow(controller).to receive(:require_context_with_permission).and_return nil
        get "index", params: { account_id: sub_account.id }
        expect(response).to be_not_found
      end

      it "does not include non-visible keys from site admin" do
        get "index", params: { account_id: test_domain_root_account.id }, format: :json
        expect(expected_id).to eq root_account_key.global_id
      end

      it "does not include visible keys from site admin" do
        site_admin_key.update!(visible: true)
        get "index", params: { account_id: test_domain_root_account.id }, format: :json
        expect(expected_id).to eq root_account_key.global_id
      end

      it "includes non-visible keys created in the current context" do
        root_account_key.update!(visible: false)
        get "index", params: { account_id: test_domain_root_account.id }, format: :json
        expect(expected_id).to eq root_account_key.global_id
      end

      context 'with "inherited" parameter' do
        it "does not include account developer keys" do
          root_account_key
          get "index", params: { account_id: test_domain_root_account.id, inherited: true }, format: :json
          expect(json_parse(response.body)).to be_blank
        end
      end

      context "with sharding" do
        specs_require_sharding

        let(:root_account_admin) { root_account_shard.activate { account_admin_user(account: root_account) } }
        let(:site_admin_shard) { Account.site_admin.shard }
        let(:site_admin_key) do
          site_admin_shard.activate do
            key = DeveloperKey.create!
            key.update!(visible: true)
            key
          end
        end
        let(:root_account_shard) { @shard1 }
        let(:root_account) { root_account_shard.activate { account_model } }
        let(:root_account_key) { root_account_shard.activate { DeveloperKey.create!(account: root_account) } }

        before do
          site_admin_key
          root_account_key

          allow(controller).to receive(:account_context) do
            controller.send(:require_account_context)
            controller.send(:context)
          end
        end

        it "includes visible site admin keys from the site admin shard" do
          user_session(root_account_admin)

          root_account_shard.activate do
            get "index", params: { account_id: root_account.id, inherited: true }, format: :json
          end

          expect(expected_id).to eq site_admin_key.global_id
        end
      end
    end

    it "is allowed to access their dev keys" do
      get "index", params: { account_id: test_domain_root_account.id }
      expect(response).to be_successful
    end

    it "An account admin shouldn't be able to access site admin dev keys" do
      user_session(test_domain_root_account_admin)
      get "index", params: { account_id: Account.site_admin.id }
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    describe "Should be able to create developer key" do
      let(:create_params) do
        {
          account_id: test_domain_root_account.id,
          developer_key: {
            redirect_uri: "http://example.com/sdf"
          }
        }
      end

      it "is allowed to create a dev key" do
        post "create", params: create_params
        expect(response).to be_successful
      end

      it "is dev keys plus 1 key" do
        post "create", params: create_params
        expect(test_domain_root_account.developer_keys.count).to be 1
      end
    end

    it "is allowed update a dev key" do
      dk = test_domain_root_account.developer_keys.create!(redirect_uri: "http://asd.com/")
      put "update", params: { id: dk.id,
                              developer_key: {
                                redirect_uri: "http://example.com/sdf"
                              } }
      expect(response).to be_successful
      dk.reload
      expect(dk.redirect_uri).to eq("http://example.com/sdf")
    end

    it "is not allowed access dev keys for a sub account" do
      get "index", params: { account_id: sub_account.id }
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    it "is not allowed to create dev keys for a sub account" do
      post "create", params: { account_id: sub_account.id }
      expect(response).to be_redirect
      expect(flash[:error]).to eq "You don't have permission to access that page"
    end

    describe "Shouldn't be able to access other accounts" do
      before :once do
        @other_root_account = Account.create!
        @other_sub_account = @other_root_account.sub_accounts.create!(parent_account: @other_root_account, root_account: @other_root_account)
      end

      it "is not allowed access dev keys for a foreign account" do
        get "index", params: { account_id: @other_root_account.id }
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "is not allowed to create dev keys for a foreign account" do
        post "create", params: { account_id: @other_root_account.id }
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "is not allowed to update dev keys for a foreign account" do
        dk = @other_root_account.developer_keys.create!
        post "update", params: { id: dk.id, account_id: test_domain_root_account_admin.id, developer_key: { event: :deactivate } }
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "is not allowed to update global dev keys" do
        dk = DeveloperKey.create!
        post "update", params: { id: dk.id, account_id: test_domain_root_account_admin.id, developer_key: { event: :deactivate } }
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end

      it "is not allowed to view foreign accounts dev_key" do
        dk = @other_root_account.developer_keys.create!(redirect_uri: "http://asd.com/")

        post "update", params: { id: dk.id }
        expect(response).to be_redirect
        expect(flash[:error]).to eq "You don't have permission to access that page"
      end
    end
  end
end
