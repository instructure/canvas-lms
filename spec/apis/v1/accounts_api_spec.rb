# frozen_string_literal: true

#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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

describe "Accounts API", type: :request do
  before :once do
    user_with_pseudonym(active_all: true)
    @a1 = account_model(name: "root", default_time_zone: "UTC", default_storage_quota_mb: 123, default_user_storage_quota_mb: 45, default_group_storage_quota_mb: 42)
    @a1.account_users.create!(user: @user)
    @sis_batch = @a1.sis_batches.create
    SisBatch.where(id: @sis_batch).update_all(workflow_state: "imported")
    @a2 = account_model(name: "subby", parent_account: @a1, root_account: @a1, sis_source_id: "sis1", sis_batch_id: @sis_batch.id, default_time_zone: "Alaska", default_storage_quota_mb: 321, default_user_storage_quota_mb: 54, default_group_storage_quota_mb: 41)
    @a2.account_users.create!(user: @user)
    @a3 = account_model(name: "no-access")
    # even if we have access to it implicitly, it's not listed
    @a4 = account_model(name: "implicit-access", parent_account: @a1, root_account: @a1)
  end

  describe "index" do
    it "returns the account list" do
      json = api_call(:get,
                      "/api/v1/accounts.json",
                      { controller: "accounts", action: "index", format: "json" })

      expect(json.sort_by { |a| a["id"] }).to eq [
        {
          "id" => @a1.id,
          "uuid" => @a1.uuid,
          "name" => "root",
          "root_account_id" => nil,
          "parent_account_id" => nil,
          "default_time_zone" => "Etc/UTC",
          "default_storage_quota_mb" => 123,
          "default_user_storage_quota_mb" => 45,
          "default_group_storage_quota_mb" => 42,
          "workflow_state" => "active",
        },
        {
          "id" => @a2.id,
          "uuid" => @a2.uuid,
          "integration_id" => nil,
          "name" => "subby",
          "root_account_id" => @a1.id,
          "parent_account_id" => @a1.id,
          "sis_account_id" => "sis1",
          "sis_import_id" => @sis_batch.id,
          "default_time_zone" => "America/Juneau",
          "default_storage_quota_mb" => 321,
          "default_user_storage_quota_mb" => 54,
          "default_group_storage_quota_mb" => 41,
          "workflow_state" => "active"
        },
      ]
    end

    it "doesn't return duplicates" do
      role = custom_account_role("some role", account: @a1)
      @a1.account_users.create!(user: @user, role:)

      json = api_call(:get,
                      "/api/v1/accounts.json",
                      { controller: "accounts", action: "index", format: "json" })
      expect(json.pluck("id")).to match_array([@a1.id, @a2.id])
    end

    it "doesn't include deleted accounts" do
      @a2.destroy
      json = api_call(:get,
                      "/api/v1/accounts.json",
                      { controller: "accounts", action: "index", format: "json" })

      expect(json.sort_by { |a| a["id"] }).to eq [
        {
          "id" => @a1.id,
          "name" => "root",
          "root_account_id" => nil,
          "parent_account_id" => nil,
          "default_time_zone" => "Etc/UTC",
          "default_storage_quota_mb" => 123,
          "default_user_storage_quota_mb" => 45,
          "default_group_storage_quota_mb" => 42,
          "workflow_state" => "active",
          "uuid" => @a1.uuid
        },
      ]
    end

    it "returns accounts found through admin enrollments with the account list (but in limited form)" do
      course_with_teacher(user: @user, account: @a1)
      course_with_teacher(user: @user, account: @a1) # don't find it twice
      course_with_teacher(user: @user, account: @a2)

      json = api_call(:get,
                      "/api/v1/course_accounts",
                      { controller: "accounts", action: "course_accounts", format: "json" })
      expect(json.sort_by { |a| a["id"] }).to eq [
        {
          "id" => @a1.id,
          "name" => "root",
          "root_account_id" => nil,
          "parent_account_id" => nil,
          "workflow_state" => "active",
          "default_time_zone" => "Etc/UTC",
          "uuid" => @a1.uuid
        },
        {
          "id" => @a2.id,
          "name" => "subby",
          "root_account_id" => @a1.id,
          "parent_account_id" => @a1.id,
          "workflow_state" => "active",
          "default_time_zone" => "America/Juneau",
          "uuid" => @a2.uuid
        },
      ]
    end

    describe "with sharding" do
      specs_require_sharding
      it "includes cross-shard accounts in course_accounts" do
        course_with_teacher(user: @user, account: @a1)
        @shard1.activate do
          @a5 = account_model(name: "crossshard", default_time_zone: "UTC")
          course_with_teacher(user: @user, account: @a5)
        end

        json = api_call(:get,
                        "/api/v1/course_accounts",
                        { controller: "accounts", action: "course_accounts", format: "json" })
        expect(json.sort_by { |a| a["id"] }).to eq [
          {
            "id" => @a1.id,
            "name" => "root",
            "root_account_id" => nil,
            "parent_account_id" => nil,
            "workflow_state" => "active",
            "default_time_zone" => "Etc/UTC",
            "uuid" => @a1.uuid
          },
          {
            "id" => @a5.global_id,
            "name" => "crossshard",
            "root_account_id" => nil,
            "parent_account_id" => nil,
            "workflow_state" => "active",
            "default_time_zone" => "Etc/UTC",
            "uuid" => @a5.uuid
          },
        ]
      end
    end
  end

  describe "sub_accounts" do
    before :once do
      root = @a1
      a1 = root.sub_accounts.create! name: "Account 1"
      a2 = root.sub_accounts.create! name: "Account 2"
      a1.sub_accounts.create! name: "Account 1.1"
      @a1_2 = a1.sub_accounts.create! name: "Account 1.2"
      a1.sub_accounts.create! name: "Account 1.2.1"
      3.times.each do |i|
        a2.sub_accounts.create! name: "Account 2.#{i + 1}"
      end
    end

    it "returns child accounts" do
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/sub_accounts",
                      { controller: "accounts",
                        action: "sub_accounts",
                        account_id: @a1.id.to_s,
                        format: "json" })
      expect(json.pluck("name")).to eq ["subby",
                                        "implicit-access",
                                        "Account 1",
                                        "Account 2"]
    end

    it "adds sub account" do
      previous_sub_count = @a1.sub_accounts.size
      api_call(:post,
               "/api/v1/accounts/#{@a1.id}/sub_accounts",
               { controller: "sub_accounts",
                 action: "create",
                 account_id: @a1.id.to_s,
                 format: "json" },
               { account: { "name" => "New sub-account",
                            "sis_account_id" => "567",
                            "default_storage_quota_mb" => 123,
                            "default_user_storage_quota_mb" => 456,
                            "default_group_storage_quota_mb" => 147 } })
      expect(@a1.sub_accounts.size).to eq previous_sub_count + 1
      sub = @a1.sub_accounts.detect { |a| a.name == "New sub-account" }
      expect(sub).not_to be_nil
      expect(sub.sis_source_id).to eq "567"
      expect(sub.default_storage_quota_mb).to eq 123
      expect(sub.default_user_storage_quota_mb).to eq 456
      expect(sub.default_group_storage_quota_mb).to eq 147
    end

    it "destroys a sub_account" do
      json = api_call(:delete,
                      "/api/v1/accounts/#{@a1.id}/sub_accounts/#{@a1_2.id}",
                      { controller: "sub_accounts",
                        action: "destroy",
                        account_id: @a1.to_param,
                        format: "json",
                        id: @a1_2.to_param })
      expect(json["id"]).to eq @a1_2.id
      expect(json["workflow_state"]).to eq "deleted"
      expect(@a1_2.reload.workflow_state).to eq "deleted"
    end

    describe "recursive" do
      it "returns sub accounts recursively" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/sub_accounts?recursive=1",
                        { controller: "accounts",
                          action: "sub_accounts",
                          account_id: @a1.id.to_s,
                          recursive: "1",
                          format: "json" })

        expect(json.pluck("name").sort).to eq ["subby",
                                               "implicit-access",
                                               "Account 1",
                                               "Account 1.1",
                                               "Account 1.2",
                                               "Account 1.2.1",
                                               "Account 2",
                                               "Account 2.1",
                                               "Account 2.2",
                                               "Account 2.3"].sort
      end

      it "ignores deleted accounts" do
        @a1.sub_accounts.create!(name: "Deleted Account").destroy
        parent_account = @a1.sub_accounts.create!(name: "Deleted Parent Account")
        parent_account.sub_accounts.create!(name: "Child Account")
        Account.where(id: parent_account).update_all(workflow_state: "deleted")

        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/sub_accounts?recursive=1",
                        { controller: "accounts",
                          action: "sub_accounts",
                          account_id: @a1.id.to_s,
                          recursive: "1",
                          format: "json" })

        expect(json.pluck("name").sort).to eq ["subby",
                                               "implicit-access",
                                               "Account 1",
                                               "Account 1.1",
                                               "Account 1.2",
                                               "Account 1.2.1",
                                               "Account 2",
                                               "Account 2.1",
                                               "Account 2.2",
                                               "Account 2.3"].sort
      end
    end
  end

  describe "show" do
    it "returns an individual account" do
      # by id
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "show", id: @a1.to_param, format: "json" })
      expect(json).to eq(
        {
          "id" => @a1.id,
          "name" => "root",
          "uuid" => @a1.uuid,
          "root_account_id" => nil,
          "parent_account_id" => nil,
          "default_time_zone" => "Etc/UTC",
          "default_storage_quota_mb" => 123,
          "default_user_storage_quota_mb" => 45,
          "default_group_storage_quota_mb" => 42,
          "workflow_state" => "active",
        }
      )
    end

    it "returns an individual account for a teacher (but in limited form)" do
      limited = account_model(name: "limited")
      course_with_teacher(user: @user, account: limited)

      json = api_call(:get,
                      "/api/v1/accounts/#{limited.id}",
                      { controller: "accounts", action: "show", id: limited.to_param, format: "json" })
      expect(json).to eq(
        {
          "id" => limited.id,
          "name" => "limited",
          "root_account_id" => nil,
          "parent_account_id" => nil,
          "workflow_state" => "active",
          "default_time_zone" => "Etc/UTC",
          "uuid" => limited.uuid
        }
      )
    end

    it "returns the lti_guid" do
      @a1.lti_guid = "hey"
      @a1.save!
      json = api_call(:get,
                      "/api/v1/accounts?include[]=lti_guid",
                      { controller: "accounts", action: "index", format: "json", include: ["lti_guid"] },
                      {})
      expect(json[0]["lti_guid"]).to eq "hey"
    end

    context "when the includes query param includes 'global_id'" do
      it "includes the account's global ID" do
        json = api_call(
          :get,
          "/api/v1/accounts?includes[]=global_id",
          {
            controller: "accounts",
            action: "index",
            format: "json",
            includes: ["global_id"]
          },
          {}
        )

        expect(json[0]["global_id"]).to eq @a1.global_id
      end
    end

    it "honors deprecated includes parameter" do
      @a1.lti_guid = "hey"
      @a1.save!
      json = api_call(:get,
                      "/api/v1/accounts?includes[]=lti_guid",
                      { controller: "accounts", action: "index", format: "json", includes: ["lti_guid"] },
                      {})
      expect(json[0]["lti_guid"]).to eq "hey"
    end
  end

  describe "update" do
    let(:header_options_hash) do
      {
        controller: "accounts",
        action: "update",
        id: @a1.to_param,
        format: "json"
      }
    end

    let(:query_params_hash) do
      {
        account: {
          settings: {
            sis_assignment_name_length_input: {
              value: nil
            }
          }
        }
      }
    end

    it "updates the name for an account" do
      new_name = "root2"
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { name: new_name } })

      expect(json).to include({
                                "id" => @a1.id,
                                "name" => new_name,
                              })

      @a1.reload
      expect(@a1.name).to eq new_name
    end

    it "updates account settings" do
      api_call(:put,
               "/api/v1/accounts/#{@a1.id}",
               { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
               { account: { settings: { restrict_student_past_view: { value: true, locked: false } } } })

      @a1.reload
      expect(@a1.restrict_student_past_view).to eq({ value: true, locked: false })
    end

    it "updates services" do
      expect(@a1.service_enabled?(:avatars)).to be_falsey
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { services: { avatars: "1" } } })

      expect(json["services"]["avatars"]).to be_truthy
      expect(Account.find(@a1.id).service_enabled?(:avatars)).to be_truthy
    end

    it "updates sis_id" do
      json = api_call(:put,
                      "/api/v1/accounts/#{@a2.id}",
                      { controller: "accounts", action: "update", id: @a2.to_param, format: "json" },
                      { account: { sis_account_id: "subsis" } })

      expect(json["sis_account_id"]).to eq "subsis"
      expect(Account.find(@a2.id).sis_source_id).to eq "subsis"
    end

    it "does not update sis_id for root_accounts" do
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { sis_account_id: "subsis" } },
                      {},
                      expected_status: 401)
      expect(json["errors"]["unauthorized"].first["message"]).to eq "Cannot set sis_account_id on a root_account."
      expect(Account.find(@a1.id).sis_source_id).to be_nil
    end

    # These following tests focus on testing the sis_assignment_name_length_input account setting
    # through the API. This setting is used to enforce assignment name length for assignments.
    # Valid values for this setting are integers/strings between 0-255. If a value is set greater
    # than or less than those boundaries OR if the value is nil/some arbitrary string the default
    # assignment name length value of 255 will be assigned to the setting to mitigate these cases.
    # Otherwise the value sent in will be assigned to the setting.
    it "updates account with sis_assignment_name_length_input with string number value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = "120"
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "120"
    end

    it "updates account with sis_assignment_name_length_input with string text value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = "too much tuna"
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "updates account with sis_assignment_name_length_input with nil value" do
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "updates account with sis_assignment_name_length_input with empty string value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = ""
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "updates account with sis_assignment_name_length_input with integer value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = 200
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "200"
    end

    it "sets sis_assignment_name_length_input to default 255 if value is integer and over 255" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = 400
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "sets sis_assignment_name_length_input to default 255 if value is string and over 255" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = "300"
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "sets sis_assignment_name_length_input to default 255 if value is string and less than 0" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = "-2"
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "sets sis_assignment_name_length_input to default 255 if value is integer and under 0" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = -12
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "does not update with a blank name" do
      @a1.name = "blah"
      @a1.save!
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { name: "" } },
                      {},
                      expected_status: 400)

      expect(json["errors"]["name"].first["message"]).to eq "The account name cannot be blank"

      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { name: nil } },
                      {},
                      expected_status: 400)

      expect(json["errors"]["name"].first["message"]).to eq "The account name cannot be blank"

      @a1.reload
      expect(@a1.name).to eq "blah"
    end

    it "updates the default_time_zone for an account with an IANA timezone name" do
      new_zone = "America/Juneau"
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { default_time_zone: new_zone } })

      expect(json).to include({
                                "id" => @a1.id,
                                "default_time_zone" => new_zone,
                              })

      @a1.reload
      expect(@a1.default_time_zone.tzinfo.name).to eq new_zone
    end

    it "updates the default_time_zone for an account with a Rails timezone name" do
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { default_time_zone: "Alaska" } })

      expect(json).to include({
                                "id" => @a1.id,
                                "default_time_zone" => "America/Juneau",
                              })

      @a1.reload
      expect(@a1.default_time_zone.name).to eq "Alaska"
    end

    it "checks for a valid time zone" do
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { default_time_zone: "Booger" } },
                      {},
                      { expected_status: 400 })
      expect(json["errors"]["default_time_zone"].first["message"]).to eq "'Booger' is not a recognized time zone"
    end

    it "does not update other attributes (yet)" do
      json = api_call(:put,
                      "/api/v1/accounts/#{@a1.id}",
                      { controller: "accounts", action: "update", id: @a1.to_param, format: "json" },
                      { account: { settings: { setting: "set" } } })

      expect(json).to include({
                                "id" => @a1.id,
                                "name" => @a1.name,
                              })

      @a1.reload
      expect(@a1.settings[:setting]).to be_nil
    end

    context "Microsoft Teams Sync" do
      let(:update_sync_settings_params) do
        {
          account: {
            settings: {
              microsoft_sync_enabled: sync_enabled,
              microsoft_sync_tenant: tenant_name,
              microsoft_sync_login_attribute: attribute,
              microsoft_sync_login_attribute_suffix: suffix,
              microsoft_sync_remote_attribute: remote_attribute
            }
          }
        }
      end
      let(:expected_settings) do
        update_sync_settings_params[:account][:settings].filter { |_key, value| !value.nil? && value != "" }
      end

      let(:account) { @a1 }
      let(:update_path) { "/api/v1/accounts/#{account.id}" }
      # We want to make sure we have valid settings so that when we're testing for failed requests,
      # it's actually because of the invalid setting we set, and not just cause we didn't have
      # any settings set.
      let(:sync_enabled) { true }
      let(:tenant_name) { "canvastest2.onmicrosoft.com" }
      let(:attribute) { "sis_user_id" }
      let(:suffix) { "@example.com" }
      let(:remote_attribute) { "mail" }
      let(:header_options_hash) do
        {
          controller: "accounts",
          action: "update",
          id: account.to_param,
          format: "json"
        }
      end

      before do
        user_session(@user)
      end

      shared_examples_for "a valid request" do
        it "saves the settings" do
          api_call(:put,
                   update_path,
                   header_options_hash,
                   update_sync_settings_params,
                   {},
                   { expected_status: 200 })
          account.reload
          expected_settings.each do |key, value|
            expect(account.settings[key]).to eq value
          end
        end
      end

      shared_examples_for "an invalid request" do
        it "returns a 400 and doesn't change the account settings" do
          api_call(:put,
                   update_path,
                   header_options_hash,
                   update_sync_settings_params,
                   {},
                   { expected_status: 400 })
          account.reload
          expected_settings.each_key do |key|
            expect(account.settings[key]).to be_nil
          end
        end
      end

      context "microsoft_group_enrollments_syncing flag disabled" do
        before { account.root_account.disable_feature!(:microsoft_group_enrollments_syncing) }

        it_behaves_like "an invalid request"

        context "subaccounts modifying settings" do
          let(:account) { @a2 }

          it_behaves_like "an invalid request"
        end
      end

      context "microsoft_group_enrollments_syncing flag enabled" do
        before { account.root_account.enable_feature!(:microsoft_group_enrollments_syncing) }

        context "no Microsoft Teams settings provided" do
          let(:tenant_name) { nil }
          let(:attribute) { nil }
          let(:suffix) { nil }
          let(:remote_attribute) { nil }

          it_behaves_like "an invalid request"
        end

        context "updating with valid settings" do
          it_behaves_like "a valid request"
        end

        context "non-string value provided for a setting" do
          let(:tenant_name) do
            {
              garbage: :input
            }
          end

          it_behaves_like "an invalid request"
        end

        context "invalid tenant name supplied" do
          let(:tenant_name) { "^&abcd.com" }

          it_behaves_like "an invalid request"
        end

        context "invalid login attribute" do
          let(:attribute) { "garbage" }

          it_behaves_like "an invalid request"
        end

        context "invalid suffix" do
          let(:suffix) { '\thello there' }

          it_behaves_like "an invalid request"
        end

        context "invalid remote attribute" do
          let(:remote_attribute) { "not-a-valid-remote-attribute" }

          it_behaves_like "an invalid request"
        end

        context "non-admin user" do
          let(:generic_user) { user_factory }

          it "can't update settings" do
            api_call_as_user(generic_user,
                             :put,
                             update_path,
                             header_options_hash,
                             update_sync_settings_params,
                             {},
                             { expected_result: 401 })
            account.reload
            expected_settings.each_key do |key|
              expect(account.settings[key]).to be_nil
            end
          end
        end

        context "disabling sync" do
          let(:sync_enabled) { false }

          context "specifying settings" do
            it_behaves_like "a valid request"
          end

          context("no settings specified") do
            let(:tenant_name) { nil }
            let(:attribute) { nil }
            let(:suffix) { nil }
            let(:remote_attribute) { nil }

            it_behaves_like "a valid request"
          end
        end

        context "using strings for sync_enabled" do
          let(:enabled) { "true" }

          it_behaves_like "a valid request"
        end

        MicrosoftSync::SettingsValidator::VALID_SYNC_LOGIN_ATTRIBUTES.each do |login_attr|
          context "setting login attribute to #{login_attr}" do
            let(:attribute) { login_attr }

            it_behaves_like "a valid request"
          end
        end

        MicrosoftSync::SettingsValidator::VALID_SYNC_REMOTE_ATTRIBUTES.each do |remote|
          context "setting the remote attribute to #{remote}" do
            let(:remote_attribute) { remote }

            it_behaves_like "a valid request"
          end
        end

        context "empty suffix" do
          let(:suffix) { "" }

          it_behaves_like "a valid request"
        end

        context "account already has settings" do
          before do
            account.settings = {
              microsoft_sync_enabled: true,
              microsoft_sync_tenant: "canvastest2.onmicrosoft.com",
              microsoft_sync_login_attribute: "email",
              microsoft_sync_login_attribute_suffix: "",
              microsoft_sync_remote_attribute: "mail"
            }
            account.save!
          end

          context "changing settings" do
            let(:tenant_name) { "testing.123.onmicrosoft.com" }
            let(:attribute) { "sis_user_id" }
            let(:suffix) { "@testschool.edu" }
            let(:remote_attribute) { "mailNickname" }

            it "tries to cleanup UserMappings" do
              expect(MicrosoftSync::UserMapping).to receive(:delete_old_user_mappings_later).with(account)
              api_call(:put,
                       update_path,
                       header_options_hash,
                       update_sync_settings_params,
                       {},
                       { expected_status: 200 })
            end

            it_behaves_like "a valid request"

            context "account has already has a suffix set" do
              before do
                account.settings[:microsoft_sync_login_attribute_suffix] = "@example.com"
                account.save!
              end

              context "and the request specifies a null suffix" do
                let(:suffix) { nil }

                it_behaves_like "a valid request"
              end

              context "and the request specifies an empty suffix" do
                let(:suffix) { "" }

                it_behaves_like "a valid request"
              end
            end
          end
        end

        context "subaccounts" do
          let(:account) { @a2 }

          it_behaves_like "a valid request"
        end
      end
    end

    context "with :manage_storage_quotas" do
      before(:once) do
        # remove the user from being an Admin
        @a1.account_users.where(user_id: @user).delete_all

        # re-add the user as an admin with quota rights
        role = custom_account_role "quotas", account: @a1
        @a1.role_overrides.create! role:, permission: "manage_storage_quotas", enabled: true
        @a1.account_users.create!(user: @user, role:)

        @params = { controller: "accounts", action: "update", id: @a1.to_param, format: "json" }
      end

      it "allows the default storage quota to be set" do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, { account: { default_storage_quota_mb: 789 } })

        expect(json).to include({
                                  "id" => @a1.id,
                                  "default_storage_quota_mb" => 789,
                                })

        @a1.reload
        expect(@a1.default_storage_quota_mb).to eq 789
      end

      it "allows the default user quota to be set" do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, { account: { default_user_storage_quota_mb: 678 } })

        expect(json).to include({
                                  "id" => @a1.id,
                                  "default_user_storage_quota_mb" => 678,
                                })

        @a1.reload
        expect(@a1.default_user_storage_quota_mb).to eq 678
      end

      it "allows the default group quota to be set" do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, { account: { default_group_storage_quota_mb: 678 } })

        expect(json).to include({
                                  "id" => @a1.id,
                                  "default_group_storage_quota_mb" => 678,
                                })

        @a1.reload
        expect(@a1.default_group_storage_quota_mb).to eq 678
      end
    end

    context "without :manage_storage_quotas" do
      before(:once) do
        # remove the user from being an Admin
        @a1.account_users.where(user_id: @user).delete_all

        # re-add the user as an admin without quota rights
        role = custom_account_role "no-quotas", account: @a1
        @a1.role_overrides.create! role:, permission: "manage_account_settings", enabled: true
        @a1.role_overrides.create! role:, permission: "manage_storage_quotas", enabled: false
        @a1.account_users.create!(user: @user, role:)

        @params = { controller: "accounts", action: "update", id: @a1.to_param, format: "json" }
      end

      it "does not allow the default storage quota to be set" do
        api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, { account: { default_storage_quota_mb: 789 } }, {}, { expected_status: 401 })

        @a1.reload
        expect(@a1.default_storage_quota_mb).to eq 123
      end

      it "does not allow the default user quota to be set" do
        api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, { account: { default_user_storage_quota_mb: 678 } }, {}, { expected_status: 401 })

        @a1.reload
        expect(@a1.default_user_storage_quota_mb).to eq 45
      end

      it "does not allow the default group quota to be set" do
        api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, { account: { default_group_storage_quota_mb: 678 } }, {}, { expected_status: 401 })

        @a1.reload
        expect(@a1.default_group_storage_quota_mb).to eq 42
      end
    end

    context "with course_template_id" do
      before do
        @a2.root_account.enable_feature!(:course_templates)
        @user.account_users.where(account: @a2).delete_all
      end

      let(:template) { @a2.courses.create!(template: true) }

      it "updates" do
        api_call(:put,
                 "/api/v1/accounts/#{@a2.id}",
                 { controller: "accounts", action: "update", id: @a2.to_param, format: "json" },
                 { account: { course_template_id: template.id } })
        @a2.reload
        expect(@a2.course_template).to eq template
      end

      it "returns unauthorized when you don't have permission to change it" do
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :add_course_template, enabled: false)
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :edit_course_template, enabled: false)
        api_call(:put,
                 "/api/v1/accounts/#{@a2.id}",
                 { controller: "accounts", action: "update", id: @a2.to_param, format: "json" },
                 { account: { course_template_id: template.id } },
                 {},
                 expected_status: 401)
      end

      it "returns bad request when you give a course that can't be a template" do
        template.update!(template: false)
        api_call(:put,
                 "/api/v1/accounts/#{@a2.id}",
                 { controller: "accounts", action: "update", id: @a2.to_param, format: "json" },
                 { account: { course_template_id: template.id } },
                 {},
                 expected_status: 404)
      end

      it "doesn't error when you pass a template of no change, even if you don't have permissions (template set)" do
        @a2.update!(course_template: template)
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :add_course_template, enabled: false)
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :edit_course_template, enabled: false)
        api_call(:put,
                 "/api/v1/accounts/#{@a2.id}",
                 { controller: "accounts", action: "update", id: @a2.to_param, format: "json" },
                 { account: { course_template_id: template.id } })
      end

      it "doesn't error when you pass a template of no change, even if you don't have permissions (inherit)" do
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :delete_course_template, enabled: false)
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :edit_course_template, enabled: false)
        api_call(:put,
                 "/api/v1/accounts/#{@a2.id}",
                 { controller: "accounts", action: "update", id: @a2.to_param, format: "json" },
                 { account: { course_template_id: nil } })
      end

      it "doesn't error when you pass a template of no change, even if you don't have permissions (no template)" do
        Course.ensure_dummy_course
        @a2.update!(course_template_id: 0)
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :delete_course_template, enabled: false)
        @a1.role_overrides.create!(role: @user.account_users.first.role, permission: :edit_course_template, enabled: false)
        api_call(:put,
                 "/api/v1/accounts/#{@a2.id}",
                 { controller: "accounts", action: "update", id: @a2.to_param, format: "json" },
                 { account: { course_template_id: 0 } })
      end
    end
  end

  describe "environment" do
    it "lists cached_js_env_account_settings" do
      expect_any_instance_of(ApplicationController).to receive(:cached_js_env_account_settings)
        .and_return({ calendar_contexts_limit: true })
      json = api_call(:get,
                      "/api/v1/settings/environment",
                      { controller: "accounts", action: "environment", format: "json" },
                      {},
                      {},
                      { expected_status: 200 })
      expect(json).to eq({ "calendar_contexts_limit" => true })
    end

    it "requires user session" do
      request_path = "https://www.example.com/api/v1/settings/environment"
      __send__(:get, request_path, params: { controller: "accounts", action: "environment", format: "json" })
      expect(response).to have_http_status(:unauthorized)
    end
  end

  it "finds accounts by sis in only this root account" do
    Account.default.account_users.create!(user: @user)
    other_sub = account_model(name: "other_sub", parent_account: Account.default, root_account: Account.default, sis_source_id: "sis1")
    other_sub.account_users.create!(user: @user)

    # this is scoped to Account.default
    json = api_call(:get,
                    "/api/v1/accounts/sis_account_id:sis1",
                    { controller: "accounts", action: "show", id: "sis_account_id:sis1", format: "json" })
    expect(json["id"]).to eq other_sub.id

    # we shouldn't find the account in the other root account by sis
    other_sub.update_attribute(:sis_source_id, "sis2")
    raw_api_call(:get,
                 "/api/v1/accounts/sis_account_id:sis1",
                 { controller: "accounts", action: "show", id: "sis_account_id:sis1", format: "json" })
    assert_status(404)
  end

  context "courses_api" do
    it "returns courses for an account" do
      Time.use_zone(@user.time_zone) do
        @me = @user
        @c1 = course_model(name: "c1", account: @a1, root_account: @a1)
        @c1.enrollments.each(&:destroy_permanently!)
        @c2 = course_model(name: "c2", account: @a2, root_account: @a1, sis_source_id: "sis2")
        @c2.course_sections.create!
        @c2.course_sections.create!
        @user = @me
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" })

        [@c1, @c2].each(&:reload)
        expect(json.first["id"]).to eq @c1.id
        expect(json.first["name"]).to eq "c1"
        expect(json.first["account_id"]).to eq @c1.account_id
        expect(json.first["is_public"]).to be true

        expect(json.last["id"]).to eq @c2.id
        expect(json.last["name"]).to eq "c2"
        expect(json.last["account_id"]).to eq @c2.account_id

        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" },
                        { hide_enrollmentless_courses: "1" })
        expect(json.first["id"]).to eq @c2.id
        expect(json.first["name"]).to eq "c2"
        expect(json.first["account_id"]).to eq @c2.account_id

        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" },
                        { per_page: 1, page: 2 })
        expect(json.first["id"]).to eq @c2.id
        expect(json.first["name"]).to eq "c2"
        expect(json.first["account_id"]).to eq @c2.account_id
      end
    end

    it "honors the includes[]" do
      @c1 = course_model(name: "c1", account: @a1, root_account: @a1)
      @a1.account_users.create!(user: @user)
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?include[]=storage_quota_used_mb&include[]=account_name",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        include: ["storage_quota_used_mb", "account_name"] },
                      {})
      expect(json[0]).to have_key("storage_quota_used_mb")
      expect(json[0]).to have_key("account_name")
    end

    it "don'ts include fake students" do
      @c1 = course_model(name: "c1", account: @a1, root_account: @a1)
      @c1.student_view_student
      @a1.account_users.create!(user: @user)
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?include[]=total_students",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        include: ["total_students"] },
                      {})
      expect(json[0]["total_students"]).to eq 0
    end

    it "don'ts override name with friendly_name" do
      @c1 = course_model(name: "c1", account: @a1, root_account: @a1, friendly_name: "barney")
      @a1.enable_as_k5_account!
      @a1.account_users.create!(user: @user)
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json" },
                      {})
      expect(json.size).to eq 1
      expect(json[0]["name"]).to eq "c1"
      expect(json[0]["friendly_name"]).to eq "barney"
      expect(json[0]["original_name"]).to be_nil
    end

    it "includes enrollment term information for each course" do
      @c1 = course_model(name: "c1", account: @a1, root_account: @a1)
      @a1.account_users.create!(user: @user)
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?include[]=term&include[]=concluded",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        include: ["term", "concluded"] })
      expect(json[0]).to have_key("term")
      expect(json[0]["concluded"]).to be false

      @c1.enrollment_term.update_attribute :end_at, 1.week.ago
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?include[]=term&include[]=concluded",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        include: ["term", "concluded"] })
      expect(json[0]).to have_key("term")
      expect(json[0]["concluded"]).to be true
    end

    it "returns a teacher count if too many teachers are found" do
      @c1 = course_with_teacher(account: @a1, course_name: "c1").course
      @c2 = course_with_teacher(account: @a1, course_name: "c2").course
      @c2.enroll_teacher(user_factory)

      @a1.account_users.create!(user: @user)
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?include[]=teachers&teacher_limit=1",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        include: ["teachers"],
                        teacher_limit: "1" })
      c1_hash = json.detect { |h| h["id"] == @c1.id }
      expect(c1_hash["teachers"]).to be_present
      c2_hash = json.detect { |h| h["id"] == @c2.id }
      expect(c2_hash).not_to have_key("teachers")
      expect(c2_hash["teacher_count"]).to eq 2
    end

    it "returns a better teacher count if a teacher is in too many sections" do
      @c1 = course_with_teacher(account: @a1, course_name: "c1").course
      s2 = @c1.course_sections.create!
      # should not think there are two teachers if one is in multiple sections
      @c1.enroll_teacher(@teacher, section: s2, allow_multiple_enrollments: true)
      @c2 = course_with_teacher(account: @a1, course_name: "c2", user: @teacher).course

      @a1.account_users.create!(user: @user)
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?include[]=teachers&teacher_limit=1",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        include: ["teachers"],
                        teacher_limit: "1" })
      [@c1, @c2].each do |c|
        expect(json.detect { |h| h["id"] == c.id }["teachers"].pluck("id")).to eq [@teacher.id]
      end
    end

    it "limits the response to homeroom courses if requested" do
      @c1 = course_factory(account: @a1, course_name: "c1")
      @c2 = course_factory(account: @a1, course_name: "c2")
      @c2.homeroom_course = true
      @c2.save!
      json = api_call_as_user(account_admin_user(account: @a1),
                              :get,
                              "/api/v1/accounts/#{@a1.id}/courses?homeroom=1",
                              controller: "accounts",
                              action: "courses_api",
                              account_id: @a1.to_param,
                              format: "json",
                              homeroom: "1")
      expect(json.pluck("name")).to match_array(["c2"])
    end

    describe "sort" do
      before :once do
        @me = @user
        @sub2 = @a1.sub_accounts.create!(name: "b", sis_source_id: "sub2", root_account: @a1)
        @sub1 = @a1.sub_accounts.create!(name: "a", sis_source_id: "sub1", root_account: @a1)

        @a1.courses.create!(name: "in root")
        @sub1.courses.create!(name: "in sub1")
        @sub2.courses.create!(name: "in sub2")
      end

      it "sorts by account name using subaccount for backwards compatibility" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?sort=subaccount",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          sort: "subaccount" })
        expect(json.first["name"]).to eq("in sub1")
        expect(json.last["name"]).to eq("in root")
      end

      it "sorts by account name" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?sort=account_name",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          sort: "account_name" })
        expect(json.first["name"]).to eq("in sub1")
        expect(json.last["name"]).to eq("in root")
      end
    end

    describe "handles crosslisting properly" do
      before :once do
        @root_account = Account.create!
        @account1 = Account.create!({ root_account: @root_account })
        @account2 = Account.create!({ root_account: @root_account })
        @course1 = course_factory({ account: @account1, course_name: "course1" })
        @course2 = course_factory({ account: @account2, course_name: "course2" })
        @course2.course_sections.create!
        @course2.course_sections.first.crosslist_to_course(@course1)
      end

      it "don't include crosslisted course when querying account section was crosslisted from" do
        @account2.account_users.create!(user: @user)
        json = api_call(:get,
                        "/api/v1/accounts/#{@account2.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @account2.to_param,
                          format: "json", })
        expect(json.length).to eq 1
        expect(json.first["name"]).to eq "course2"
      end

      it "don't include crosslisted course when querying account section was crosslisted to" do
        @account1.account_users.create!(user: @user)
        json = api_call(:get,
                        "/api/v1/accounts/#{@account1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @account1.to_param,
                          format: "json" })
        expect(json.length).to eq 1
        expect(json.first["name"]).to eq "course1"
      end

      it "include crosslisted course when querying account section was crosslisted from if requested" do
        @account2.account_users.create!(user: @user)
        json = api_call(:get,
                        "/api/v1/accounts/#{@account2.id}/courses?include_crosslisted_courses=true",
                        { controller: "accounts",
                          action: "courses_api",
                          include_crosslisted_courses: true,
                          account_id: @account2.to_param,
                          format: "json" })
        expect(json.length).to eq 2
        names = json.pluck("name")
        expect(names.include?("course1")).to be_truthy
        expect(names.include?("course2")).to be_truthy
      end
    end

    describe "courses filtered by state[]" do
      before :once do
        @me = @user
        %i[c1 c2 c3 c4].each do |course|
          instance_variable_set(:"@#{course}", course_model(name: course.to_s, account: @a1))
        end
        @c2.destroy
        Course.where(id: @c1).update_all(workflow_state: "claimed")
        Course.where(id: @c3).update_all(workflow_state: "available")
        Course.where(id: @c4).update_all(workflow_state: "completed")
        @user = @me
      end

      it "returns courses filtered by state[]='deleted'" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?state[]=deleted",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          state: %w[deleted] })
        expect(json.length).to be 1
        expect(json.first["name"]).to eql "c2"
      end

      it "returns courses filtered by state[]=nil" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" })
        expect(json.length).to be 3
        expect(json.collect { |c| c["id"].to_i }.sort).to eq [@c1.id, @c3.id, @c4.id].sort
      end

      it "returns courses filtered by state[]='all'" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?state[]=all",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          state: %w[all] })
        expect(json.length).to be 4
        expect(json.collect { |c| c["id"].to_i }.sort).to eq [@c1.id, @c2.id, @c3.id, @c4.id].sort
      end
    end

    it "returns courses filtered by enrollment_term" do
      term = @a1.enrollment_terms.create!(name: "term 2")
      @a1.courses.create!(name: "c1")
      @a1.courses.create!(name: "c2", enrollment_term: term)

      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?enrollment_term_id=#{term.id}",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        enrollment_term_id: term.to_param })
      expect(json.length).to be 1
      expect(json.first["name"]).to eql "c2"
    end

    describe "?with_enrollments" do
      before :once do
        @me = @user
        course_model(account: @a1, name: "c1")    # has a teacher
        Course.create!(account: @a1, name: "c2")  # has no enrollments
        @user = @me
      end

      it "does not apply if not specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          format: "json",
                          account_id: @a1.to_param })
        expect(json.pluck("name")).to eql ["c1", "c2"]
      end

      it "filters on courses with enrollments" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?with_enrollments=1",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          with_enrollments: "1" })
        expect(json.pluck("name")).to eql ["c1"]
      end

      it "filters on courses without enrollments" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?with_enrollments=0",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          with_enrollments: "0" })
        expect(json.pluck("name")).to eql ["c2"]
      end
    end

    describe "?published" do
      before :once do
        @me = @user
        [:c1, :c2].each do |course|
          instance_variable_set(:"@#{course}", course_model(name: course.to_s, account: @a1))
        end
        @c1.offer!
        @user = @me
      end

      it "does not apply if not specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" })
        expect(json.pluck("name")).to eql ["c1", "c2"]
      end

      it "filters courses on published state" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?published=true",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          published: "true" })
        expect(json.pluck("name")).to eql ["c1"]
      end

      it "filters courses on non-published state" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?published=false",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          published: "false" })
        expect(json.pluck("name")).to eql ["c2"]
      end
    end

    describe "?completed" do
      before :once do
        @me = @user
        %i[c1 c2 c3 c4 c5].each do |course|
          instance_variable_set(:"@#{course}", course_model(name: course.to_s, account: @a1, conclude_at: 2.days.from_now))
        end

        # c2 -- condluded
        @c2.start_at = 2.weeks.ago
        @c2.conclude_at = 1.week.ago
        @c2.save!

        # c3 -- term concluded, no conclude_at, so concluded
        term = @c3.root_account.enrollment_terms.create! end_at: 2.days.ago
        @c3.enrollment_term = term
        @c3.conclude_at = nil
        @c3.save!

        # c4 -- condluded via workflow_state
        @c4.complete!
        @user = @me

        # c5 -- expired term, but course term (non-concluded) overrides
        @c5.enrollment_term = term
        @c5.save!
      end

      it "does not apply if not specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" })
        expect(json.pluck("name")).to eql %w[c1 c2 c3 c4 c5]
      end

      it "filters courses on completed state" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?completed=yes",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          completed: "yes" })
        expect(json.pluck("name")).to eql %w[c2 c3 c4]
      end

      it "filters courses on non-completed state" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?completed=no",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          completed: "no" })
        expect(json.pluck("name")).to eql %w[c1 c5]
      end

      it "filters and sort without asploding" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?completed=yes&sort=course_name&order=desc",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          completed: "yes",
                          sort: "course_name",
                          order: "desc" })
        expect(json.pluck("name")).to eql %w[c4 c3 c2]
      end
    end

    describe "?starts_before" do
      before :once do
        @me = @user
        %i[c1 c2 c3 c4].each do |course|
          instance_variable_set(:"@#{course}", course_model(name: course.to_s, account: @a1, start_at: 2.days.ago))
        end

        @c2.start_at = 1.week.ago
        @c2.save!

        term = @c3.root_account.enrollment_terms.create! start_at: 3.days.ago.change(usec: 0)
        @c3.start_at = nil
        @c3.enrollment_term = term
        @c3.save!

        @c4.start_at = nil
        @c4.save!

        @user = @me
      end

      it "does not apply if not specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" })
        expect(json.pluck("name")).to eql %w[c1 c2 c3 c4]
      end

      it "filters inclusively and include null values" do
        date = @c3.enrollment_term.start_at
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?starts_before=#{date.iso8601}",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          starts_before: date.iso8601 })
        expect(json.pluck("name")).to eql %w[c2 c3 c4]
      end

      it "filters and sort without asploding" do
        date = @c3.enrollment_term.start_at
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?starts_before=#{date.iso8601}&sort=course_name&order=desc",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          starts_before: date.iso8601,
                          sort: "course_name",
                          order: "desc" })
        expect(json.pluck("name")).to eql %w[c4 c3 c2]
      end
    end

    describe "?ends_after" do
      before :once do
        @me = @user
        %i[c1 c2 c3 c4].each do |course|
          instance_variable_set(:"@#{course}", course_model(name: course.to_s, account: @a1, conclude_at: 2.days.from_now))
        end

        @c2.conclude_at = 1.week.from_now
        @c2.save!

        term = @c3.root_account.enrollment_terms.create! end_at: 3.days.from_now.change(usec: 0)
        @c3.conclude_at = nil
        @c3.enrollment_term = term
        @c3.save!

        @c4.conclude_at = nil
        @c4.save!

        @user = @me
      end

      it "does not apply if not specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" })
        expect(json.pluck("name")).to eql %w[c1 c2 c3 c4]
      end

      it "filters inclusively and include null values" do
        date = @c3.enrollment_term.end_at
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?ends_after=#{date.iso8601}",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          ends_after: date.iso8601 })
        expect(json.pluck("name")).to eql %w[c2 c3 c4]
      end

      it "filters and sort without asploding" do
        date = @c3.enrollment_term.end_at
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?ends_after=#{date.iso8601}&sort=course_name&order=desc",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          ends_after: date.iso8601,
                          sort: "course_name",
                          order: "desc" })
        expect(json.pluck("name")).to eql %w[c4 c3 c2]
      end
    end

    describe "?by_teachers" do
      before :once do
        @me = @user
        course_with_teacher(account: @a1, course_name: "c1a", user: user_with_pseudonym(account: @a1))
        @pseudonym.sis_user_id = "a_sis_id"
        @pseudonym.save!
        @t1 = @teacher
        course_with_teacher(account: @a1, user: @t1, course_name: "c1b")
        course_with_teacher(account: @a1, course_name: "c2")
        course_with_teacher(account: @a1, course_name: "c3")
        @t3 = @teacher
        @user = @me
      end

      it "does not apply when not specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json.pluck("name")).to eql %w[c1a c1b c2 c3]
      end

      it "filters courses by teacher enrollments" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?by_teachers[]=sis_user_id:a_sis_id&by_teachers[]=#{@t3.id}",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          by_teachers: ["sis_user_id:a_sis_id", @t3.id.to_s] },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json.pluck("name")).to eql %w[c1a c1b c3]
      end

      it "does not break with an empty result set" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?by_teachers[]=bad_id",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          by_teachers: ["bad_id"] },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json).to eql []
      end
    end

    describe "?by_subaccounts" do
      before :once do
        @me = @user
        @sub1 = account_model(name: "sub1", parent_account: @a1, root_account: @a1, sis_source_id: "sub1")
        @sub1a = account_model(name: "sub1a", parent_account: @sub1, root_account: @a1, sis_source_id: "sub1a")
        @sub1b = account_model(name: "sub1b", parent_account: @sub1, root_account: @a1, sis_source_id: "sub1b")
        @sub2 = account_model(name: "sub2", parent_account: @a1, root_account: @a1, sis_source_id: "sub2")

        course_model(name: "in sub1", account: @sub1)
        course_model(name: "in sub1a", account: @sub1a)
        course_model(name: "in sub1b", account: @sub1b)
        course_model(name: "in sub2", account: @sub2)
        course_model(name: "in top level", account: @a1)
        @user = @me
      end

      it "does not apply when not specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json" },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json.pluck("name")).to eql ["in sub1", "in sub1a", "in sub1b", "in sub2", "in top level"]
      end

      it "includes descendants of the specified subaccount" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=sis_account_id:sub1",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          by_subaccounts: ["sis_account_id:sub1"] },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json.pluck("name")).to eql ["in sub1", "in sub1a", "in sub1b"]
      end

      it "works with multiple subaccounts specified" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=sis_account_id:sub1a&by_subaccounts[]=sis_account_id:sub1b",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          by_subaccounts: ["sis_account_id:sub1a", "sis_account_id:sub1b"] },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json.pluck("name")).to eql ["in sub1a", "in sub1b"]
      end

      it "works with a numeric ID" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=#{@sub2.id}",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          by_subaccounts: [@sub2.id.to_s] },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json.pluck("name")).to eql ["in sub2"]
      end

      it "does not break with an empty result set" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=bad_id",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          by_subaccounts: ["bad_id"] },
                        {},
                        {},
                        { domain_root_account: @a1 })
        expect(json).to eql []
      end
    end

    it "limits the maximum per-page returned" do
      create_courses(110, account: @a1, account_associations: true)
      expect(api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?per_page=12",
                      controller: "accounts",
                      action: "courses_api",
                      account_id: @a1.to_param,
                      format: "json",
                      per_page: "12").size).to eq 12
      expect(api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?per_page=105",
                      controller: "accounts",
                      action: "courses_api",
                      account_id: @a1.to_param,
                      format: "json",
                      per_page: "105").size).to eq 100
    end

    it "returns courses filtered search term" do
      data = (5..12).map { |i| { name: "name#{i}", course_code: "code#{i}" } }
      @courses = create_courses(data, account: @a1, account_associations: true, return_type: :record)
      @course = @courses.last

      search_term = "name"
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        search_term: })
      expect(json.length).to eql @courses.length

      search_term = "code"
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        search_term: })
      expect(json.length).to eql @courses.length

      search_term = "name1"
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        search_term: })
      expect(json.length).to be 3

      # Should return empty result set
      search_term = "0000000000"
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        search_term: })
      expect(json.length).to be 0

      # To short should return 400
      search_term = "a"
      response = raw_api_call(:get,
                              "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
                              { controller: "accounts",
                                action: "courses_api",
                                account_id: @a1.to_param,
                                format: "json",
                                search_term: })
      expect(response).to eq 400

      # search on something that's a course name but looks like an id also
      course_with_long_id = @a1.courses.create!(id: @courses[0].id + 100, name: "long id") # make sure id is at least 3 characters long
      one_more = @a1.courses.create!(name: course_with_long_id.id.to_s)
      search_term = one_more.name
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
                      { controller: "accounts",
                        action: "courses_api",
                        account_id: @a1.to_param,
                        format: "json",
                        search_term: })
      expect(json.length).to be 2
      expect(json.map { |c| [c["id"], c["name"]] }).to match_array([
                                                                     [course_with_long_id.id, course_with_long_id.name], [one_more.id, one_more.name]
                                                                   ])
    end

    context "sharding" do
      specs_require_sharding

      it "is able to search on global id" do
        @course = @a1.courses.create!(name: "whee")
        search_term = Shard.global_id_for(@course)
        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a1.to_param,
                          format: "json",
                          search_term: })
        expect(json.length).to be 1
        expect(json.first["name"]).to eq @course.name
      end
    end

    context "blueprint courses" do
      before :once do
        @a = Account.create!
        @mc = course_model name: "MasterCourse", account: @a
        @cc = course_model name: "ChildCourse", account: @a
        @oc = course_model name: "OtherCourse", account: @a
        template = MasterCourses::MasterTemplate.set_as_master_course(@mc)
        template.add_child_course!(@cc).destroy # ensure deleted subscriptions don't affect the result
        template.add_child_course!(@cc)
        account_admin_user(account: @a)
      end

      it "filters in blueprint courses" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a.id}/courses?blueprint=true",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a.to_param,
                          format: "json",
                          blueprint: true })
        expect(json.pluck("name")).to match_array %w[MasterCourse]
      end

      it "filters out blueprint courses" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a.id}/courses?blueprint=false",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a.to_param,
                          format: "json",
                          blueprint: false })
        expect(json.pluck("name")).to match_array %w[ChildCourse OtherCourse]
      end

      it "filters in associated courses" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a.id}/courses?blueprint_associated=true",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a.to_param,
                          format: "json",
                          blueprint_associated: true })
        expect(json.pluck("name")).to match_array %w[ChildCourse]
      end

      it "filters out associated courses" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a.id}/courses?blueprint_associated=false",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a.to_param,
                          format: "json",
                          blueprint_associated: false })
        expect(json.pluck("name")).to match_array %w[MasterCourse OtherCourse]
      end
    end

    context "public courses" do
      before :once do
        @a = Account.create!
        @c1 = course_model(is_public: true, name: "Public", account: @a)
        @c2 = course_model(is_public: false, name: "NotPublic", account: @a)
        account_admin_user(account: @a)
      end

      it "does not filter out non-public courses" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a.id}/courses?",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a.to_param,
                          format: "json" })
        expect(json.pluck("name")).to match_array %w[Public NotPublic]
      end

      it "filters out non-public courses" do
        json = api_call(:get,
                        "/api/v1/accounts/#{@a.id}/courses?public=true",
                        { controller: "accounts",
                          action: "courses_api",
                          account_id: @a.to_param,
                          format: "json",
                          public: true })
        expect(json.pluck("name")).to match_array %w[Public]
      end
    end
  end

  context "permissions" do
    it "returns permissions" do
      json = api_call(:get,
                      "/api/v1/accounts/#{@a1.id}/permissions?permissions[]=become_user&permissions[]=manage_blarghs",
                      controller: "accounts",
                      action: "permissions",
                      account_id: @a1.to_param,
                      format: "json",
                      permissions: %w[become_user manage_blarghs])
      expect(json).to eq({ "become_user" => true, "manage_blarghs" => false })
    end

    it "requires :read permission on the account" do
      api_call(:get,
               "/api/v1/accounts/#{@a3.id}/permissions?permissions[]=become_user",
               { controller: "accounts",
                 action: "permissions",
                 account_id: @a3.to_param,
                 format: "json",
                 permissions: %w[become_user] },
               {},
               {},
               { expected_status: 401 })
    end
  end

  context "show settings" do
    let(:show_settings_path) { "/api/v1/accounts/#{@a1.id}/settings" }
    let(:show_settings_header) { { controller: :accounts, action: :show_settings, account_id: @a1.to_param, format: :json } }
    let(:generic_user) { user_factory }

    it "does not allow regular users to see settings" do
      api_call_as_user(generic_user, :get, show_settings_path, show_settings_header, {}, { expected_status: 401 })
    end

    it "allows account admins to see selected settings" do
      @a1.settings = { microsoft_sync_enabled: true, microsoft_sync_tenant: "testtenant.com" }
      @a1.save!
      json = api_call(:get, show_settings_path, show_settings_header, {}, { expected_status: 200 })
      expect(json["microsoft_sync_enabled"]).to be(true)
      expect(json["microsoft_sync_tenant"]).to eq("testtenant.com")
    end
  end

  context "account api extension" do
    let(:mock_plugin) do
      Module.new do
        def self.extend_account_json(hash, *)
          hash[:extra_thing] = "something"
        end
      end
    end

    include Api::V1::Account

    it "allows a plugin to extend the account_json method" do
      allow(Api::V1::Account).to receive(:extensions).and_return([mock_plugin])

      expect(account_json(@a1, @me, @session, [])[:extra_thing]).to eq "something"
    end
  end
end
