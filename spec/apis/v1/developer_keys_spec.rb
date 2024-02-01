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

require_relative "../api_spec_helper"
require_relative "../../lti_1_3_spec_helper"

describe DeveloperKeysController, type: :request do
  include_context "lti_1_3_spec_helper"
  let(:sa_id) { Account.site_admin.id }

  describe "GET 'index'" do
    it "requires authorization" do
      unauthorized_api_call(:get, "/api/v1/accounts/#{sa_id}/developer_keys.json", {
                              controller: "developer_keys",
                              action: "index",
                              format: "json",
                              account_id: sa_id.to_s
                            })
    end

    it "has the default developer key" do
      admin_session
      json = api_call(:get, "/api/v1/accounts/#{sa_id}/developer_keys.json", {
                        controller: "developer_keys",
                        action: "index",
                        format: "json",
                        account_id: sa_id.to_s
                      })

      confirm_valid_key_in_json(json, DeveloperKey.default)
    end

    it "returns the list of developer keys" do
      admin_session
      key = DeveloperKey.create!
      json = api_call(:get, "/api/v1/accounts/#{sa_id}/developer_keys.json", {
                        controller: "developer_keys",
                        action: "index",
                        format: "json",
                        account_id: sa_id.to_s
                      })

      confirm_valid_key_in_json(json, key)
    end

    it "stringifies the nested stuff" do
      admin_session
      key = DeveloperKey.create!
      json = api_call(:get,
                      "/api/v1/accounts/#{sa_id}/developer_keys.json",
                      {
                        controller: "developer_keys", action: "index", format: "json", account_id: sa_id.to_s
                      },
                      {},
                      { "Accept" => "application/json+canvas-string-ids" })
      row = json.detect { |r| r["id"] == key.global_id.to_s }
      expect(row["developer_key_account_binding"]["developer_key_id"]).to eq key.global_id.to_s
    end

    it "only includes a subset of attributes if inherited is set" do
      a = Account.create!
      allow_any_instance_of(DeveloperKeysController).to receive(:context_is_domain_root_account?).and_return(true)
      user_session(account_admin_user(account: a))
      d = DeveloperKey.create!(account: nil)
      d.update! visible: true
      get "/api/v1/accounts/#{a.id}/developer_keys", params: { inherited: true }
      expect(json_parse.first.keys).to match_array(
        %w[name created_at icon_url workflow_state id developer_key_account_binding is_lti_key inherited_from is_lti_registration]
      )
    end

    context "when inherited is set for siteadmin key" do
      subject { get "/api/v1/accounts/#{account.id}/developer_keys", params: { inherited: true } }

      let(:account) { Account.create! }
      let(:key) do
        d = DeveloperKey.create!(account: nil)
        d.update! visible: true
        d
      end

      before do
        allow_any_instance_of(DeveloperKeysController).to receive(:context_is_domain_root_account?).and_return(true)
        user_session(account_admin_user(account:))
        key
      end

      it "only includes a subset of attributes" do
        subject
        expect(json_parse.first.keys).to match_array(
          %w[name created_at icon_url workflow_state id developer_key_account_binding is_lti_key inherited_from is_lti_registration]
        )
      end

      it "sets inherited_from to global" do
        subject
        expect(json_parse.first["inherited_from"]).to eq "global"
      end
    end

    it "only includes tool_configuration if inherited is not set" do
      a = Account.create!
      allow_any_instance_of(DeveloperKeysController).to receive(:context_is_domain_root_account?).and_return(true)
      user_session(account_admin_user(account: a))
      d = DeveloperKey.create!(account: a)
      d.update! visible: true
      get "/api/v1/accounts/#{a.id}/developer_keys"
      expect(json_parse.first.keys).to include "tool_configuration"
    end

    it 'includes "allow_includes"' do
      a = Account.create!
      allow_any_instance_of(DeveloperKeysController).to receive(:context_is_domain_root_account?).and_return(true)
      user_session(account_admin_user(account: a))
      d = DeveloperKey.create!(account: a)
      d.update! visible: true
      get "/api/v1/accounts/#{a.id}/developer_keys"
      expect(json_parse.first.keys).to include "allow_includes"
    end

    it "does not include `test_cluster_only` by default" do
      admin_session
      DeveloperKey.create!
      json = api_call(:get, "/api/v1/accounts/#{sa_id}/developer_keys.json", {
                        controller: "developer_keys",
                        action: "index",
                        format: "json",
                        account_id: sa_id.to_s
                      })
      expect(json.first.keys).not_to include("test_cluster_only")
    end

    it "does include `test_cluster_only` when enabled" do
      Setting.set("dev_key_test_cluster_checks_enabled", true)
      admin_session
      DeveloperKey.create!
      json = api_call(:get, "/api/v1/accounts/#{sa_id}/developer_keys.json", {
                        controller: "developer_keys",
                        action: "index",
                        format: "json",
                        account_id: sa_id.to_s
                      })
      expect(json.first.keys).to include("test_cluster_only")
    end

    describe "developer key account bindings" do
      specs_require_sharding

      context "when context is site admin" do
        it "includes the site admin binding for the key" do
          user_session(account_admin_user(account: Account.site_admin))
          sa_key = Account.site_admin.shard.activate { DeveloperKey.create!(account: nil) }
          get "/api/v1/accounts/site_admin/developer_keys"

          site_admin_key_json = json_parse.find { |d| d["id"] == sa_key.global_id }
          expect(Account.find(site_admin_key_json.dig("developer_key_account_binding", "account_id"))).to eq Account.site_admin
          expect(site_admin_key_json.dig("developer_key_account_binding", "account_owns_binding")).to be true
        end
      end

      context "when context is not site admin" do
        let(:root_account) { account_model }

        it "includes the site admin binding if it is set" do
          user_session(account_admin_user(account: Account.site_admin))
          sa_key = Account.site_admin.shard.activate { DeveloperKey.create!(account: nil) }
          sa_key.update!(visible: true)
          root_account.developer_key_account_bindings.create!(developer_key: sa_key, workflow_state: "on")

          get "/api/v1/accounts/#{root_account.id}/developer_keys?inherited=true"

          site_admin_key_json = json_parse.find { |d| d["id"] == sa_key.global_id }

          expect(Account.find(site_admin_key_json.dig("developer_key_account_binding", "account_id"))).to eq Account.site_admin
          expect(site_admin_key_json.dig("developer_key_account_binding", "account_owns_binding")).to be false
        end
      end
    end
  end

  describe "POST 'create'" do
    it "requires authorization" do
      unauthorized_api_call(:post,
                            "/api/v1/accounts/#{sa_id}/developer_keys.json",
                            {
                              controller: "developer_keys",
                              action: "create",
                              format: "json",
                              account_id: sa_id.to_s
                            },
                            { developer_key: {} })
    end

    it "creates a new developer key" do
      create_call
    end
  end

  describe "PUT 'update'" do
    it "requires authorization" do
      key = DeveloperKey.create!
      unauthorized_api_call(:put,
                            "/api/v1/developer_keys/#{key.id}.json",
                            {
                              controller: "developer_keys",
                              action: "update",
                              id: key.id.to_s,
                              format: "json"
                            },
                            { developer_key: {} })
    end

    it "updates an existing developer key" do
      update_call
    end
  end

  describe "DELETE 'destroy'" do
    it "requires authorization" do
      key = DeveloperKey.create!
      unauthorized_api_call(:delete, "/api/v1/developer_keys/#{key.id}.json", {
                              controller: "developer_keys",
                              action: "destroy",
                              id: key.id.to_s,
                              format: "json"
                            })
    end

    it "deletes an existing developer key" do
      destroy_call
    end
  end

  def admin_session
    account_admin_user(account: Account.site_admin)
  end

  def create_call
    admin_session
    post_hash = { developer_key: { name: "cool tool", icon_url: "" } }
    # make sure this key is created
    DeveloperKey.default
    json = api_call(:post,
                    "/api/v1/accounts/#{sa_id}/developer_keys.json",
                    {
                      controller: "developer_keys",
                      action: "create",
                      format: "json",
                      account_id: sa_id.to_s
                    },
                    post_hash)

    expect(DeveloperKey.count).to eq 2
    confirm_valid_key_in_json([json], DeveloperKey.last)
  end

  def update_call
    admin_session
    key = DeveloperKey.create!
    post_hash = { developer_key: { name: "cool tool" } }
    json = api_call(:put,
                    "/api/v1/developer_keys/#{key.id}.json",
                    {
                      controller: "developer_keys",
                      action: "update",
                      format: "json",
                      id: key.id.to_s
                    },
                    post_hash)

    key.reload
    confirm_valid_key_in_json([json], key)
  end

  def destroy_call
    admin_session
    key = DeveloperKey.create!
    api_call(:delete, "/api/v1/developer_keys/#{key.id}.json", {
               controller: "developer_keys",
               action: "destroy",
               format: "json",
               id: key.id.to_s
             })

    expect(DeveloperKey.where(id: key).first).to be_deleted
  end

  def unauthorized_api_call(*args)
    raw_api_call(*args)
    expect(response).to have_http_status :unauthorized
  end

  def confirm_valid_key_in_json(json, key)
    json.map! do |hash|
      hash.keep_if { |k, _| %w[id icon_url name].include?(k) }
    end

    expect(json.include?(key_to_hash(key))).to be true
  end

  def key_to_hash(key)
    {
      "id" => key.global_id,
      "icon_url" => key.icon_url,
      "name" => key.name
    }
  end
end
