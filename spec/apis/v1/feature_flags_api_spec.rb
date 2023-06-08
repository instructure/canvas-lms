# frozen_string_literal: true

#
# Copyright (C) 2013 Instructure, Inc.
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

require "apis/api_spec_helper"
require "feature_flag_helper"

describe "Feature Flags API", type: :request do
  include FeatureFlagHelper

  let_once(:t_site_admin) { Account.site_admin }
  let_once(:t_root_account) { account_model }
  let_once(:t_teacher) { user_with_pseudonym account: t_root_account }
  let_once(:t_sub_account) { account_model parent_account: t_root_account }
  let_once(:t_course) { course_with_teacher(user: t_teacher, account: t_sub_account, active_all: true).course }
  let_once(:t_root_admin) { account_admin_user account: t_root_account }

  let(:live_event_feature) { Feature.new(feature: "compact_live_event_payloads", applies_to: "RootAccount", state: "allowed") }
  let(:granular_permissions_feature) do
    Feature.new(
      feature: "granular_permissions_manage_courses",
      applies_to: "RootAccount",
      state: "allowed"
    )
  end

  before do
    allow_any_instance_of(User).to receive(:set_default_feature_flags)
    allow(Feature).to receive(:definitions).and_return({
                                                         "root_account_feature" => Feature.new(feature: "root_account_feature", applies_to: "RootAccount", state: "allowed"),
                                                         "account_feature" => Feature.new(feature: "account_feature", applies_to: "Account", state: "on", display_name: -> { "Account Feature FRD" }, description: -> { "FRD!!" }, beta: true, autoexpand: true),
                                                         "course_feature" => Feature.new(feature: "course_feature", applies_to: "Course", state: "allowed", development: true, release_notes_url: "http://example.com", display_name: "not localized", description: "srsly"),
                                                         "user_feature" => Feature.new(feature: "user_feature", applies_to: "User", state: "allowed"),
                                                         "root_opt_in_feature" => Feature.new(feature: "root_opt_in_feature", applies_to: "Course", state: "allowed", root_opt_in: true),
                                                         "hidden_feature" => Feature.new(feature: "hidden_feature", applies_to: "Course", state: "hidden"),
                                                         "hidden_user_feature" => Feature.new(feature: "hidden_user_feature", applies_to: "User", state: "hidden"),
                                                         "compact_live_event_payloads" => live_event_feature
                                                       })
    silence_undefined_feature_flag_errors
  end

  describe "index" do
    it "checks permissions" do
      api_call_as_user(t_teacher,
                       :get,
                       "/api/v1/accounts/#{t_root_account.id}/features",
                       { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "returns the correct format" do
      t_root_account.feature_flags.create! feature: "course_feature", state: "on"
      json = api_call_as_user(t_root_admin,
                              :get,
                              "/api/v1/accounts/#{t_root_account.id}/features",
                              { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param })
      expect(json).to match_array(
        [{ "feature" => "account_feature",
           "display_name" => "Account Feature FRD",
           "description" => "FRD!!",
           "applies_to" => "Account",
           "beta" => true,
           "autoexpand" => true,
           "feature_flag" =>
              { "feature" => "account_feature",
                "state" => "on",
                "parent_state" => "on",
                "locked" => true,
                "transitions" => { "allowed" => { "locked" => false }, "off" => { "locked" => false }, "allowed_on" => { "locked" => false } } } },
         { "feature" => "course_feature",
           "applies_to" => "Course",
           "release_notes_url" => "http://example.com",
           "display_name" => "not localized",
           "description" => "srsly",
           "feature_flag" =>
              { "context_id" => t_root_account.id,
                "context_type" => "Account",
                "locking_account_id" => nil,
                "feature" => "course_feature",
                "state" => "on",
                "parent_state" => "allowed",
                "locked" => false,
                "transitions" => { "allowed" => { "locked" => false }, "off" => { "locked" => false }, "allowed_on" => { "locked" => false } } } },
         { "applies_to" => "RootAccount",
           "feature" => "compact_live_event_payloads",
           "feature_flag" =>
             { "context_id" => t_root_account.id,
               "context_type" => "Account",
               "feature" => "compact_live_event_payloads",
               "locked" => false,
               "locking_account_id" => nil,
               "state" => "off",
               "parent_state" => "off",
               "transitions" => { "allowed" => { "locked" => true }, "on" => { "locked" => false }, "allowed_on" => { "locked" => true } } },
           "root_opt_in" => true },
         { "feature" => "root_account_feature",
           "applies_to" => "RootAccount",
           "root_opt_in" => true,
           "feature_flag" =>
              { "context_id" => t_root_account.id,
                "context_type" => "Account",
                "locking_account_id" => nil,
                "feature" => "root_account_feature",
                "state" => "off",
                "parent_state" => "off",
                "locked" => false,
                "transitions" => { "allowed" => { "locked" => true }, "on" => { "locked" => false }, "allowed_on" => { "locked" => true } } } },
         { "feature" => "root_opt_in_feature",
           "applies_to" => "Course",
           "root_opt_in" => true,
           "feature_flag" =>
              { "context_id" => t_root_account.id,
                "context_type" => "Account",
                "feature" => "root_opt_in_feature",
                "state" => "off",
                "parent_state" => "off",
                "locking_account_id" => nil,
                "locked" => false,
                "transitions" => { "allowed" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => false } } } }]
      )
    end

    it "paginates" do
      json = api_call_as_user(t_root_admin,
                              :get,
                              "/api/v1/accounts/#{t_root_account.id}/features?per_page=3",
                              { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param, per_page: "3" })
      expect(json.size).to be 3
      json += api_call_as_user(t_root_admin,
                               :get,
                               "/api/v1/accounts/#{t_root_account.id}/features?per_page=3&page=2",
                               { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param, per_page: "3", page: "2" })
      expect(json.size).to be 5
      expect(json.pluck("feature").sort).to match_array %w[account_feature course_feature root_account_feature root_opt_in_feature compact_live_event_payloads]
    end

    it "returns only relevant features" do
      json = api_call_as_user(t_root_admin,
                              :get,
                              "/api/v1/accounts/#{t_sub_account.id}/features",
                              { controller: "feature_flags", action: "index", format: "json", account_id: t_sub_account.to_param })
      expect(json.pluck("feature").sort).to eql %w[account_feature course_feature]
    end

    it "respects root_opt_in" do
      t_root_account.feature_flags.create! feature: "root_opt_in_feature"
      json = api_call_as_user(t_root_admin,
                              :get,
                              "/api/v1/accounts/#{t_sub_account.id}/features",
                              { controller: "feature_flags", action: "index", format: "json", account_id: t_sub_account.to_param })
      expect(json.pluck("feature").sort).to eql %w[account_feature course_feature root_opt_in_feature]
    end

    describe "hidden" do
      it "shows hidden features on site admin" do
        json = api_call_as_user(site_admin_user,
                                :get,
                                "/api/v1/accounts/#{t_site_admin.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_site_admin.id.to_s })
        expect(json.pluck("feature")).to match_array %w[account_feature course_feature hidden_feature hidden_user_feature root_account_feature root_opt_in_feature user_feature compact_live_event_payloads]
        expect(json.find { |f| f["feature"] == "hidden_feature" }["feature_flag"]["hidden"]).to be true
      end

      it "shows hidden features on root accounts to a site admin user" do
        json = api_call_as_user(site_admin_user,
                                :get,
                                "/api/v1/accounts/#{t_root_account.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param })
        expect(json.pluck("feature")).to match_array %w[account_feature course_feature hidden_feature root_account_feature root_opt_in_feature compact_live_event_payloads]
        expect(json.find { |f| f["feature"] == "hidden_feature" }["feature_flag"]["hidden"]).to be true
      end

      it "shows un-hidden features to non-site-admins on root accounts" do
        t_root_account.allow_feature! :hidden_feature
        json = api_call_as_user(t_root_admin,
                                :get,
                                "/api/v1/accounts/#{t_root_account.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param })
        expect(json.find { |f| f["feature"] == "hidden_feature" }["feature_flag"]["hidden"]).to be_nil
        expect(json.pluck("feature")).to match_array %w[account_feature course_feature hidden_feature root_account_feature root_opt_in_feature compact_live_event_payloads]
      end

      it "shows 'hidden' tag to site admin on the feature flag that un-hides a hidden feature" do
        t_root_account.allow_feature! "hidden_feature"
        json = api_call_as_user(site_admin_user,
                                :get,
                                "/api/v1/accounts/#{t_root_account.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param })
        feature = json.find { |f| f["feature"] == "hidden_feature" }
        expect(feature["feature_flag"]["hidden"]).to be true
        expect(feature["feature_flag"]["state"]).to eq "allowed"
      end

      it "does not show 'hidden' tag on a lower-level feature flag" do
        t_root_account.allow_feature! :hidden_feature
        t_sub_account.enable_feature! :hidden_feature
        json = api_call_as_user(site_admin_user,
                                :get,
                                "/api/v1/accounts/#{t_sub_account.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_sub_account.to_param })
        feature = json.find { |f| f["feature"] == "hidden_feature" }
        expect(feature["feature_flag"]["hidden"]).to be false
        expect(feature["feature_flag"]["state"]).to eq "on"
      end

      it "does not show 'hidden' tag on an inherited feature flag" do
        t_root_account.allow_feature! :hidden_feature
        json = api_call_as_user(site_admin_user,
                                :get,
                                "/api/v1/accounts/#{t_sub_account.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_sub_account.to_param })
        feature = json.find { |f| f["feature"] == "hidden_feature" }
        expect(feature["feature_flag"]["hidden"]).to be false
        expect(feature["feature_flag"]["state"]).to eq "allowed"
      end
    end

    describe "shadow" do
      before do
        allow(Feature).to receive(:definitions).and_return({ "shadow_feature" => Feature.new(feature: "shadow_feature", applies_to: "Account", state: "allowed", shadow: true), })
      end

      it "shows shadow flag to a site admin user" do
        json = api_call_as_user(site_admin_user,
                                :get,
                                "/api/v1/accounts/#{t_root_account.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param })
        feature = json.find { |f| f["feature"] == "shadow_feature" }
        expect(feature).to have_key("shadow")
        expect(feature["shadow"]).to be true
      end

      it "does not show shadow feature at all to a non-site-admin user" do
        json = api_call_as_user(t_root_admin,
                                :get,
                                "/api/v1/accounts/#{t_root_account.id}/features",
                                { controller: "feature_flags", action: "index", format: "json", account_id: t_root_account.to_param })
        expect(json.find { |f| f["feature"] == "shadow_feature" }).to be_nil
      end
    end

    it "operates on a course" do
      allow(Feature).to receive(:definitions).and_return({
                                                           "granular_permissions_manage_courses" => granular_permissions_feature,
                                                           "course_feature" => Feature.new(
                                                             feature: "course_feature",
                                                             applies_to: "Course",
                                                             state: "allowed",
                                                             development: true,
                                                             release_notes_url: "http://example.com",
                                                             display_name: "not localized",
                                                             description: "srsly"
                                                           )
                                                         })
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/courses/#{t_course.id}/features",
                              { controller: "feature_flags", action: "index", format: "json", course_id: t_course.to_param })
      expect(json.pluck("feature")).to eql %w[course_feature]
    end

    it "operates on a user" do
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/users/#{t_teacher.id}/features",
                              { controller: "feature_flags", action: "index", format: "json", user_id: t_teacher.to_param })
      expect(json.pluck("feature")).to eql %w[user_feature]
    end
  end

  describe "enabled_features" do
    it "checks permissions" do
      api_call_as_user(t_teacher,
                       :get,
                       "/api/v1/accounts/#{t_root_account.id}/features/enabled",
                       { controller: "feature_flags", action: "enabled_features", format: "json", account_id: t_root_account.to_param },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "returns the correct format" do
      t_root_account.feature_flags.create! feature: "course_feature", state: "on"
      json = api_call_as_user(t_root_admin,
                              :get,
                              "/api/v1/accounts/#{t_root_account.id}/features/enabled",
                              { controller: "feature_flags", action: "enabled_features", format: "json", account_id: t_root_account.to_param })
      expect(json.sort).to eql %w[account_feature course_feature]
    end
  end

  describe "show" do
    it "checks permissions" do
      api_call_as_user(t_teacher,
                       :get,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/root_account_feature",
                       { controller: "feature_flags", action: "show", format: "json", account_id: t_root_account.to_param, feature: "root_account_feature" },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "404s if the feature doesn't exist" do
      api_call_as_user(t_root_admin,
                       :get,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/xyzzy",
                       { controller: "feature_flags", action: "show", format: "json", account_id: t_root_account.to_param, feature: "xyzzy" },
                       {},
                       {},
                       { expected_status: 404 })
    end

    it "skips cache for admins" do
      original = t_root_account.method(:lookup_feature_flag)
      @checked = false
      allow_any_instantiation_of(t_root_account).to receive(:lookup_feature_flag) do |feature, opts|
        if feature.to_s == "root_account_feature"
          @checked = true
          expect(opts[:skip_cache]).to be true
        end
        original.call(feature, *opts)
      end
      api_call_as_user(t_root_admin,
                       :get,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/root_account_feature",
                       { controller: "feature_flags", action: "show", format: "json", account_id: t_root_account.to_param, feature: "root_account_feature" })
      expect(@checked).to be true # should actually check the expectation
    end

    it "returns the correct format" do
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/users/#{t_teacher.id}/features/flags/user_feature",
                              { controller: "feature_flags", action: "show", format: "json", user_id: t_teacher.to_param, feature: "user_feature" })
      expect(json).to eql({ "feature" => "user_feature", "state" => "allowed", "parent_state" => "allowed", "locked" => false, "transitions" => { "on" => { "locked" => false }, "off" => { "locked" => false } } })

      t_teacher.feature_flags.create! feature: "user_feature", state: "on"
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/users/#{t_teacher.id}/features/flags/user_feature",
                              { controller: "feature_flags", action: "show", format: "json", user_id: t_teacher.to_param, feature: "user_feature" })
      expect(json).to eql({ "feature" => "user_feature",
                            "state" => "on",
                            "parent_state" => "allowed",
                            "context_type" => "User",
                            "context_id" => t_teacher.id,
                            "locked" => false,
                            "locking_account_id" => nil,
                            "transitions" => { "off" => { "locked" => false } } })
    end

    describe "hidden" do
      it "does not find a hidden feature if the caller is an account admin" do
        api_call_as_user(t_root_admin,
                         :get,
                         "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                         { controller: "feature_flags", action: "show", format: "json", account_id: t_root_account.to_param, feature: "hidden_feature" },
                         {},
                         {},
                         { expected_status: 404 })
      end

      it "finds a hidden feature on a root account if the caller is site admin" do
        json = api_call_as_user(site_admin_user,
                                :get,
                                "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                                { controller: "feature_flags", action: "show", format: "json", account_id: t_root_account.to_param, feature: "hidden_feature" })
        expect(json["state"]).to eql "hidden"
      end
    end
  end

  describe "update" do
    it "checks permissions" do
      api_call_as_user(t_teacher,
                       :put,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/root_account_feature",
                       { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "root_account_feature" },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "validates state" do
      api_call_as_user(t_root_admin,
                       :put,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature?state=bamboozled",
                       { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "course_feature", state: "bamboozled" },
                       {},
                       {},
                       { expected_status: 400 })
    end

    it "creates a new flag with an audit log" do
      allow(Feature).to receive(:definitions).and_return({
                                                           "granular_permissions_manage_courses" => granular_permissions_feature,
                                                           "course_feature" => Feature.new(
                                                             feature: "course_feature",
                                                             applies_to: "Course",
                                                             state: "allowed",
                                                             development: true,
                                                             release_notes_url: "http://example.com",
                                                             display_name: "not localized",
                                                             description: "srsly"
                                                           )
                                                         })
      params = {
        controller: "feature_flags",
        action: "update",
        format: "json",
        course_id: t_course.to_param,
        feature: "course_feature",
        state: "on"
      }
      url_path = "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=on"
      api_call_as_user(t_teacher, :put, url_path, params)
      flags = t_course.feature_flags
      expect(flags.size).to eq(1)
      flag = flags.first
      expect(flag.state).to eql "on"
      log = Auditors::FeatureFlag.for_feature_flag(flag).paginate(per_page: 1).first
      expect(log.context_type).to eq("Course")
      expect(log.context_id).to eq(t_course.id)
      expect(log.state_after).to eq("on")
    end

    it "updates an existing flag" do
      flag = t_root_account.feature_flags.create! feature: "course_feature", state: "on"
      api_call_as_user(t_root_admin,
                       :put,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature?state=off",
                       { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "course_feature", state: "off" })
      flag.reload
      expect(flag).not_to be_enabled
    end

    context "sharding" do
      specs_require_sharding

      it "does not explode with cross-shard updating" do
        @shard1.activate do
          user_factory
        end

        flag = @user.feature_flags.create! feature: "user_feature", state: "on"
        api_call_as_user(@user,
                         :put,
                         "/api/v1/users/#{@user.id}/features/flags/user_feature?state=off",
                         { controller: "feature_flags", action: "update", format: "json", user_id: @user.id, feature: "user_feature", state: "off" })
        flag.reload
        expect(flag).not_to be_enabled
      end
    end

    it "refuses to update if the canvas default locks the feature" do
      api_call_as_user(t_root_admin,
                       :put,
                       "/api/v1/accounts/#{t_sub_account.id}/features/flags/account_feature?state=off",
                       { controller: "feature_flags", action: "update", format: "json", account_id: t_sub_account.to_param, feature: "account_feature", state: "off" },
                       {},
                       {},
                       { expected_status: 403 })
    end

    it "refuses to update if a higher account's flag locks the feature" do
      t_root_account.feature_flags.create! feature: "course_feature", state: "off"
      api_call_as_user(t_root_admin,
                       :put,
                       "/api/v1/accounts/#{t_sub_account.id}/features/flags/course_feature?state=on",
                       { controller: "feature_flags", action: "update", format: "json", account_id: t_sub_account.to_param, feature: "course_feature", state: "on" },
                       {},
                       {},
                       { expected_status: 403 })
    end

    it "updates the implicitly created root_opt_in feature flag" do
      flag = t_root_account.lookup_feature_flag("root_opt_in_feature")
      expect(flag.context).to eql t_root_account
      expect(flag).to be_new_record

      api_call_as_user(t_root_admin,
                       :put,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/root_opt_in_feature?state=allowed",
                       { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "root_opt_in_feature", state: "allowed" })
      flag = t_root_account.feature_flag("root_opt_in_feature")
      expect(flag.state).to eq("allowed")
      expect(flag).not_to be_new_record
    end

    it "disallows 'allowed' setting for RootAccount features on (non-site-admin) root accounts" do
      t_root_account.disable_feature! :root_account_feature
      api_call_as_user(t_root_admin,
                       :put,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/root_account_feature?state=allowed",
                       { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "root_account_feature", state: "allowed" },
                       {},
                       {},
                       { expected_status: 403 })
    end

    it "clears the context's feature flag cache before deciding to insert or update" do
      cache_key = t_root_account.feature_flag_cache_key("course_feature")
      enable_cache do
        flag = t_root_account.feature_flags.create! feature: "course_feature", state: "on"
        # try to trick the controller into inserting (and violating a unique constraint) instead of updating
        MultiCache.fetch(cache_key) { nil } # rubocop:disable Style/RedundantFetchBlock it's a cache, not a Hash
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature?state=off",
                         { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "course_feature", state: "off" })
        assert_status(200)
        expect(flag.reload.state).to eq("off")
      end
    end

    describe "hidden" do
      it "creates a site admin feature flag" do
        api_call_as_user(site_admin_user,
                         :put,
                         "/api/v1/accounts/#{t_site_admin.id}/features/flags/hidden_feature",
                         { controller: "feature_flags", action: "update", format: "json", account_id: t_site_admin.id.to_s, feature: "hidden_feature" })
        expect(t_site_admin.feature_flags.where(feature: "hidden_feature").count).to be 1
      end

      it "creates a root account feature flag with site admin privileges" do
        api_call_as_user(site_admin_user,
                         :put,
                         "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                         { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "hidden_feature" })
        expect(t_root_account.feature_flags.where(feature: "hidden_feature").count).to be 1
      end

      it "creates a user feature flag with site admin priveleges" do
        site_admin_user
        api_call_as_user(@admin,
                         :put,
                         "/api/v1/users/#{@admin.id}/features/flags/hidden_user_feature",
                         { controller: "feature_flags", action: "update", format: "json", user_id: @admin.to_param, feature: "hidden_user_feature", state: "on" })
        expect(@admin.feature_flags.where(feature: "hidden_user_feature").count).to be 1
      end

      context "AccountManager" do
        before :once do
          role = custom_account_role("AccountManager", account: t_site_admin)
          t_site_admin.role_overrides.create!(permission: "manage_feature_flags",
                                              role:,
                                              enabled: true,
                                              applies_to_self: false,
                                              applies_to_descendants: true)
          t_site_admin.role_overrides.create!(permission: "view_feature_flags",
                                              role:,
                                              enabled: true,
                                              applies_to_self: true,
                                              applies_to_descendants: true)
          @site_admin_member = site_admin_user(role:)
        end

        it "views a hidden feature" do
          json = api_call_as_user(@site_admin_member,
                                  :get,
                                  "/api/v1/accounts/#{t_site_admin.id}/features/flags/hidden_feature",
                                  { controller: "feature_flags", action: "show", format: "json", account_id: t_site_admin.id.to_s, feature: "hidden_feature" })
          expect(json["state"]).to eq "hidden"
        end

        it "does not create a site admin feature flag" do
          api_call_as_user(@site_admin_member,
                           :put,
                           "/api/v1/accounts/#{t_site_admin.id}/features/flags/hidden_feature",
                           { controller: "feature_flags", action: "update", format: "json", account_id: t_site_admin.id.to_s, feature: "hidden_feature" },
                           {},
                           {},
                           { expected_status: 401 })
          expect(t_site_admin.feature_flags.where(feature: "hidden_feature")).not_to be_any
        end

        it "creates a root account feature flag" do
          api_call_as_user(@site_admin_member,
                           :put,
                           "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                           { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "hidden_feature" })
          expect(t_root_account.feature_flags.where(feature: "hidden_feature").count).to be 1
        end

        it "can unhide a hidden feature in a subaccount" do
          api_call_as_user(@site_admin_member,
                           :put,
                           "/api/v1/accounts/#{t_sub_account.id}/features/flags/hidden_feature?state=on",
                           { controller: "feature_flags", action: "update", format: "json", account_id: t_sub_account.to_param, feature: "hidden_feature", state: "on" },
                           {},
                           {},
                           { expected_status: 200 })
          expect(t_sub_account.feature_flags.where(feature: "hidden_feature").take).to be_enabled
        end
      end

      it "does not create a root account feature flag with root admin privileges" do
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                         { controller: "feature_flags", action: "update", format: "json", account_id: t_root_account.to_param, feature: "hidden_feature" },
                         {},
                         {},
                         { expected_status: 400 })
        expect(t_root_account.feature_flags.where(feature: "hidden_feature")).not_to be_any
      end

      it "modifies a root account feature flag with root admin privileges" do
        t_root_account.feature_flags.create! feature: "hidden_feature"
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature?state=on",
                         { controller: "feature_flags",
                           action: "update",
                           format: "json",
                           account_id: t_root_account.to_param,
                           feature: "hidden_feature",
                           state: "on" })
        expect(t_root_account.feature_flags.where(feature: "hidden_feature").first).to be_enabled
      end

      it "does not create a sub-account feature flag if no root-account or site-admin flag exists" do
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/accounts/#{t_sub_account.id}/features/flags/hidden_feature?state=on",
                         { controller: "feature_flags", action: "update", format: "json", account_id: t_sub_account.to_param, feature: "hidden_feature", state: "on" },
                         {},
                         {},
                         { expected_status: 400 })
      end

      it "creates a sub-account feature flag if a root-account feature flag exists" do
        t_root_account.feature_flags.create! feature: "hidden_feature"
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/accounts/#{t_sub_account.id}/features/flags/hidden_feature?state=on",
                         { controller: "feature_flags", action: "update", format: "json", account_id: t_sub_account.to_param, feature: "hidden_feature", state: "on" })
        expect(t_sub_account.feature_flags.where(feature: "hidden_feature").first).to be_enabled
      end

      it "creates a sub-account feature flag if a site-admin feature flag exists" do
        t_site_admin.feature_flags.create! feature: "hidden_feature"
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/accounts/#{t_sub_account.id}/features/flags/hidden_feature?state=on",
                         { controller: "feature_flags", action: "update", format: "json", account_id: t_sub_account.to_param, feature: "hidden_feature", state: "on" })
        expect(t_sub_account.feature_flags.where(feature: "hidden_feature").first).to be_enabled
      end
    end
  end

  describe "delete" do
    it "checks permissions" do
      api_call_as_user(t_teacher,
                       :delete,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature",
                       { controller: "feature_flags", action: "delete", format: "json", account_id: t_root_account.to_param, feature: "course_feature" },
                       {},
                       {},
                       { expected_status: 401 })
    end

    it "deletes a feature flag" do
      t_root_account.feature_flags.create! feature: "course_feature"
      api_call_as_user(t_root_admin,
                       :delete,
                       "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature",
                       { controller: "feature_flags", action: "delete", format: "json", account_id: t_root_account.to_param, feature: "course_feature" },
                       {},
                       {},
                       { expected_status: 200 })
      expect(t_root_account.feature_flags.where(feature: "course_feature")).to be_empty
    end

    it "does not delete an inherited flag" do
      t_root_account.feature_flags.create! feature: "course_feature"
      api_call_as_user(t_root_admin,
                       :delete,
                       "/api/v1/accounts/#{t_sub_account.id}/features/flags/course_feature",
                       { controller: "feature_flags", action: "delete", format: "json", account_id: t_sub_account.to_param, feature: "course_feature" },
                       {},
                       {},
                       { expected_status: 404 })
    end
  end

  describe "environment" do
    it "lists cached_js_env_account_features" do
      expect_any_instance_of(ApplicationController).to receive(:cached_js_env_account_features)
        .and_return({ telepathic_navigation: true })
      json = api_call(:get,
                      "/api/v1/features/environment",
                      { controller: "feature_flags", action: "environment", format: "json" },
                      {},
                      {},
                      { expected_status: 200 })
      expect(json).to eq({ "telepathic_navigation" => true })
    end
  end

  describe "custom_transition_proc" do
    before do
      allow(Feature).to receive(:definitions).and_return({
                                                           "custom_feature" => Feature.new(feature: "custom_feature",
                                                                                           applies_to: "Course",
                                                                                           state: "allowed",
                                                                                           custom_transition_proc: lambda do |_user, _context, from_state, transitions|
                                                                                                                     transitions["off"] = { "locked" => true, "message" => "don't ever turn this off" } if from_state == "on"
                                                                                                                     transitions["on"] = { "locked" => false, "message" => "this is permanent?!" } if transitions.key?("on")
                                                                                                                   end),
                                                           "compact_live_event_payloads" => live_event_feature,
                                                           "granular_permissions_manage_courses" => granular_permissions_feature
                                                         })
    end

    it "gives message for unlocked transition" do
      json = api_call_as_user(t_teacher,
                              :get,
                              "/api/v1/courses/#{t_course.id}/features",
                              { controller: "feature_flags", action: "index", format: "json", course_id: t_course.to_param })
      expect(json).to eql([
                            { "feature" => "custom_feature",
                              "applies_to" => "Course",
                              "feature_flag" =>
                                 { "feature" => "custom_feature",
                                   "state" => "allowed",
                                   "parent_state" => "allowed",
                                   "locked" => false,
                                   "transitions" => { "on" => { "locked" => false, "message" => "this is permanent?!" }, "off" => { "locked" => false } } } }
                          ])
    end

    context "locked transition" do
      before do
        t_course.enable_feature! :custom_feature
      end

      it "indicates a transition is locked" do
        json = api_call_as_user(t_teacher,
                                :get,
                                "/api/v1/courses/#{t_course.id}/features/flags/custom_feature",
                                { controller: "feature_flags", action: "show", format: "json", course_id: t_course.id, feature: "custom_feature" })
        expect(json).to eql({ "context_id" => t_course.id,
                              "context_type" => "Course",
                              "feature" => "custom_feature",
                              "locking_account_id" => nil,
                              "state" => "on",
                              "locked" => false,
                              "parent_state" => "allowed",
                              "transitions" => { "off" => { "locked" => true, "message" => "don't ever turn this off" } } })
      end

      it "rejects a locked state transition" do
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/courses/#{t_course.id}/features/flags/custom_feature?state=off",
                         { controller: "feature_flags", action: "update", format: "json", course_id: t_course.to_param, feature: "custom_feature", state: "off" },
                         {},
                         {},
                         { expected_status: 403 })
      end
    end
  end

  describe "after_state_change_proc" do
    let(:t_state_changes) { [] }

    before do
      allow(Feature).to receive(:definitions).and_return({
                                                           "custom_feature" => Feature.new(feature: "custom_feature",
                                                                                           applies_to: "Course",
                                                                                           state: "allowed",
                                                                                           after_state_change_proc: lambda do |user, context, from_state, to_state|
                                                                                                                      t_state_changes << [user.id, context.id, from_state, to_state]
                                                                                                                    end),
                                                           "compact_live_event_payloads" => live_event_feature,
                                                           "granular_permissions_manage_courses" => granular_permissions_feature
                                                         })
    end

    it "fires when creating a feature flag to enable an allowed feature" do
      expect do
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/courses/#{t_course.id}/features/flags/custom_feature?state=on",
                         { controller: "feature_flags", action: "update", format: "json", course_id: t_course.to_param, feature: "custom_feature", state: "on" })
      end.to change(t_state_changes, :size).by(1)
      expect(t_state_changes.last).to eql [t_root_admin.id, t_course.id, "allowed", "on"]
    end

    it "fires when changing a feature flag's state" do
      t_course.disable_feature! "custom_feature"
      expect do
        api_call_as_user(t_root_admin,
                         :put,
                         "/api/v1/courses/#{t_course.id}/features/flags/custom_feature?state=on",
                         { controller: "feature_flags", action: "update", format: "json", course_id: t_course.to_param, feature: "custom_feature", state: "on" })
      end.to change(t_state_changes, :size).by(1)
      expect(t_state_changes.last).to eql [t_root_admin.id, t_course.id, "off", "on"]
    end

    it "fires when deleting a feature flag override (because of a hidden feature or otherwise)" do
      t_course.enable_feature! "custom_feature"
      expect do
        api_call_as_user(t_root_admin,
                         :delete,
                         "/api/v1/courses/#{t_course.id}/features/flags/custom_feature",
                         { controller: "feature_flags", action: "delete", format: "json", course_id: t_course.to_param, feature: "custom_feature" })
      end.to change(t_state_changes, :size).by(1)
      expect(t_state_changes.last).to eql [t_root_admin.id, t_course.id, "on", "allowed"]
    end
  end
end
