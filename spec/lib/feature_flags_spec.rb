# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

require_relative "../feature_flag_helper"

describe FeatureFlags do
  include FeatureFlagHelper

  let(:t_site_admin) { Account.site_admin }
  let(:t_root_account) { account_model }
  let(:t_user) { user_with_pseudonym account: t_root_account }
  let(:t_sub_account) { account_model parent_account: t_root_account }
  let(:t_course) { course_with_teacher(user: t_user, account: t_sub_account, active_all: true).course }
  let(:analytics_service) { class_double(Services::FeatureAnalyticsService).as_stubbed_const }

  before do
    silence_undefined_feature_flag_errors
    allow_any_instance_of(User).to receive(:set_default_feature_flags)
    allow(InstStatsd::Statsd).to receive(:increment)
    allow(Feature).to receive(:definitions).and_return({
                                                         "site_admin_feature" => Feature.new(feature: "site_admin_feature", applies_to: "SiteAdmin", state: "allowed"),
                                                         "root_account_feature" => Feature.new(feature: "root_account_feature", applies_to: "RootAccount", state: "off"),
                                                         "account_feature" => Feature.new(feature: "account_feature", applies_to: "Account", state: "on"),
                                                         "course_feature" => Feature.new(feature: "course_feature", applies_to: "Course", state: "allowed"),
                                                         "user_feature" => Feature.new(feature: "user_feature", applies_to: "User", state: "allowed"),
                                                         "root_opt_in_feature" => Feature.new(feature: "root_opt_in_feature", applies_to: "Course", state: "allowed", root_opt_in: true),
                                                         "default_on_feature" => Feature.new(feature: "default_on_feature", applies_to: "Account", state: "allowed_on"),
                                                         "hidden_feature" => Feature.new(feature: "hidden_feature", applies_to: "Course", state: "hidden"),
                                                         "hidden_root_opt_in_feature" => Feature.new(feature: "hidden_feature", applies_to: "Course", state: "hidden", root_opt_in: true),
                                                         "hidden_user_feature" => Feature.new(feature: "hidden_user_feature", applies_to: "User", state: "hidden"),
                                                         "shadow_feature" => Feature.new(feature: "shadow_feature", applies_to: "Course", state: "on", shadow: true),
                                                         "disabled_feature" => Feature::DISABLED_FEATURE
                                                       })
    allow(analytics_service).to receive(:persist_feature_evaluation)
  end

  after do
    LocalCache.cache.clear(force: true)
  end

  describe "#feature_enabled?" do
    it "reports correctly" do
      expect(t_sub_account.feature_enabled?(:course_feature)).to be_falsey
      expect(t_sub_account.feature_enabled?(:default_on_feature)).to be_truthy
      expect(t_sub_account.feature_enabled?(:account_feature)).to be_truthy
      Account.ensure_dummy_root_account
      expect(Account.find(0).feature_enabled?(:account_feature)).to be false
    end

    it "logs feature enablement" do
      t_sub_account.feature_enabled?(:course_feature)
      expect(InstStatsd::Statsd).to have_received(:increment).with("feature_flag_check", tags: {
                                                                     feature: :course_feature,
                                                                     enabled: "false"
                                                                   }).exactly(:once)

      t_sub_account.feature_enabled?(:account_feature)
      expect(InstStatsd::Statsd).to have_received(:increment).with("feature_flag_check", tags: {
                                                                     feature: :account_feature,
                                                                     enabled: "true"
                                                                   }).exactly(:once)
    end
  end

  describe "#feature_allowed?" do
    it "returns true if the feature is 'on' or 'allowed', and false otherwise" do
      expect(t_site_admin.feature_allowed?(:site_admin_feature)).to be_truthy
      expect(t_sub_account.feature_allowed?(:account_feature)).to be_truthy
      expect(t_sub_account.feature_allowed?(:default_on_feature)).to be_truthy
      expect(t_root_account.feature_allowed?(:root_account_feature)).to be_falsey
      expect(t_course.feature_allowed?(:course_feature)).to be_truthy
    end
  end

  describe "lookup_feature_flag" do
    it "returns nil if the feature is currently disabled" do
      expect(t_course.lookup_feature_flag("disabled_feature")).to be_nil
    end

    it "returns nil if the feature doesn't apply" do
      expect(t_course.lookup_feature_flag("user_feature")).to be_nil
    end

    it "returns nil if the visible_on returns false" do
      feature = double(
        "Feature double",
        feature: "some_feature",
        visible_on: ->(_) { false },
        state: "allowed",
        shadow?: false
      )
      expect(feature).to receive(:applies_to_object).and_return(true)
      allow(Feature.definitions).to receive(:[]).and_call_original
      expect(Feature.definitions).to receive(:[]).with("some_feature").and_return(feature)
      expect(t_course.lookup_feature_flag("some_feature")).to be_nil
    end

    it "returns defaults when no flags exist" do
      expect(t_user.lookup_feature_flag("user_feature")).to be_default
    end

    context "overrides at site admin" do
      it "ignores site admin settings if definition doesn't allow override" do
        t_site_admin.feature_flags.create! feature: "root_account_feature", state: "allowed"
        expect(t_root_account.lookup_feature_flag("root_account_feature")).to be_default
      end

      it "applies site admin settings if definition does allow override" do
        t_site_admin.feature_flags.create! feature: "course_feature", state: "on"
        expect(t_course.lookup_feature_flag("course_feature").context).to eql t_site_admin
      end

      it "overrides lower settings if not allowed" do
        t_root_account.feature_flags.create! feature: "course_feature", state: "on"
        expect(t_root_account.lookup_feature_flag("course_feature").context).to eql t_root_account
        expect(t_course.feature_enabled?("course_feature")).to be_truthy
        t_site_admin.feature_flags.create! feature: "course_feature", state: "off"
        t_root_account.instance_variable_set(:@feature_flag_cache, nil)
        expect(t_root_account.lookup_feature_flag("course_feature").context).to eql t_site_admin
        t_course.instance_variable_set(:@feature_flag_cache, nil)
        expect(t_course.feature_enabled?("course_feature")).to be_falsey
      end
    end

    context "site admin flags" do
      it "works for site admin overrides" do
        expect(t_site_admin.feature_enabled?("site_admin_feature")).to be_falsey
        t_site_admin.feature_flags.create! feature: "site_admin_feature", state: "on"
        t_site_admin.instance_variable_set(:@feature_flag_cache, nil)
        expect(t_site_admin.feature_enabled?("site_admin_feature")).to be_truthy
      end
    end

    context "account flags" do
      it "applies settings at the sub-account level" do
        t_sub_account.feature_flags.create! feature: "course_feature", state: "on"
        expect(t_root_account.lookup_feature_flag("course_feature")).to be_default
        expect(t_root_account.feature_enabled?("course_feature")).to be_falsey
        expect(t_sub_account.lookup_feature_flag("course_feature").context).to eql t_sub_account
        expect(t_sub_account.feature_enabled?("course_feature")).to be_truthy
        expect(t_course.feature_enabled?("course_feature")).to be_truthy
        expect(course_model(account: t_root_account).feature_enabled?("course_feature")).to be_falsey
      end

      it "ignores settings locked by a higher account" do
        t_sub_account.feature_flags.create! feature: "course_feature", state: "on"
        t_root_account.feature_flags.create! feature: "course_feature", state: "off"
        expect(t_sub_account.lookup_feature_flag("course_feature").context).to eql t_root_account
        expect(t_sub_account.feature_enabled?("course_feature")).to be_falsey
        expect(t_course.feature_enabled?("course_feature")).to be_falsey
      end

      it "caches the lookup" do
        t_sub_account.feature_flags.create! feature: "course_feature", state: "on"
        t_root_account.feature_flags.create! feature: "course_feature", state: "off"
        expect(t_sub_account.lookup_feature_flag("course_feature").context).to eql t_root_account
        expect_any_instance_of(Account).not_to receive(:feature_flag)
        expect(t_sub_account.lookup_feature_flag("course_feature").context).to eql t_root_account
      end
    end

    context "course flags" do
      it "applies settings at the course level" do
        other_course = t_sub_account.courses.create!
        other_course.feature_flags.create! feature: "course_feature", state: "on"
        expect(other_course.feature_enabled?("course_feature")).to be_truthy
        expect(t_course.feature_enabled?("course_feature")).to be_falsey
      end
    end

    context "user flags" do
      it "applies settings at the site admin level" do
        expect(t_user.lookup_feature_flag("user_feature")).to be_default
        t_site_admin.feature_flags.create! feature: "user_feature", state: "off"
        t_user.instance_variable_set(:@feature_flag_cache, nil)
        expect(t_user.lookup_feature_flag("user_feature").context).to eql t_site_admin
        expect(t_user.feature_enabled?("user_feature")).to be_falsey
      end

      it "applies settings at the user level" do
        t_user.feature_flags.create! feature: "user_feature", state: "off"
        expect(t_user.lookup_feature_flag("user_feature").context).to eql t_user
        expect(t_user.feature_allowed?("user_feature")).to be_falsey
        expect(user_with_pseudonym(account: t_root_account).feature_allowed?("user_feature")).to be_truthy
      end
    end

    describe "root_opt_in" do
      context "with no feature flags" do
        it "does not find the feature beneath the root account" do
          expect(t_site_admin.lookup_feature_flag("root_opt_in_feature")).to be_default
          expect(t_root_account.lookup_feature_flag("root_opt_in_feature")).to be_new_record
          expect(t_sub_account.lookup_feature_flag("root_opt_in_feature")).to be_nil
          expect(t_course.lookup_feature_flag("root_opt_in_feature")).to be_nil
        end

        it "caches the nil of the feature beneath the root account" do
          expect(t_course.lookup_feature_flag("root_opt_in_feature")).to be_nil
          expect_any_instance_of(Account).not_to receive(:feature_flag)
          expect(t_course.lookup_feature_flag("root_opt_in_feature")).to be_nil
        end
      end

      context "with site admin feature flag" do
        it "does not find the feature beneath the root account" do
          t_site_admin.feature_flags.create! feature: "root_opt_in_feature"

          expect(t_site_admin.lookup_feature_flag("root_opt_in_feature").context).to eql t_site_admin
          expect(t_root_account.lookup_feature_flag("root_opt_in_feature")).to be_new_record
          expect(t_sub_account.lookup_feature_flag("root_opt_in_feature")).to be_nil
          expect(t_course.lookup_feature_flag("root_opt_in_feature")).to be_nil
        end

        it "finds the default_on feature beneath the root account" do
          t_site_admin.feature_flags.create! feature: "root_opt_in_feature", state: Feature::STATE_DEFAULT_ON
          expect(t_site_admin.lookup_feature_flag("root_opt_in_feature").context).to eql t_site_admin
          expect(t_root_account.lookup_feature_flag("root_opt_in_feature").context).to eql t_site_admin
          expect(t_sub_account.lookup_feature_flag("root_opt_in_feature").context).to eql t_site_admin
          expect(t_course.lookup_feature_flag("root_opt_in_feature").context).to eql t_site_admin
        end
      end

      context "with root account feature flag" do
        before do
          t_root_account.feature_flags.create! feature: "root_opt_in_feature"
        end

        it "finds the feature beneath the root account" do
          expect(t_root_account.lookup_feature_flag("root_opt_in_feature").context).to eql t_root_account
          expect(t_sub_account.lookup_feature_flag("root_opt_in_feature").context).to eql t_root_account
          expect(t_course.lookup_feature_flag("root_opt_in_feature").context).to eql t_root_account
        end
      end
    end

    describe "hidden" do
      context "with no feature flags" do
        it "does not find the feature beneath site admin" do
          expect(t_site_admin.lookup_feature_flag("hidden_feature")).to be_default
          expect(t_root_account.lookup_feature_flag("hidden_feature")).to be_nil
          expect(t_sub_account.lookup_feature_flag("hidden_feature")).to be_nil
          expect(t_course.lookup_feature_flag("hidden_feature")).to be_nil
          expect(t_user.lookup_feature_flag("hidden_user_feature")).to be_nil
        end

        it "finds hidden features if override_hidden is given" do
          expect(t_site_admin.lookup_feature_flag("hidden_feature", override_hidden: true)).to be_default
          expect(t_root_account.lookup_feature_flag("hidden_feature", override_hidden: true)).to be_default
          expect(t_sub_account.lookup_feature_flag("hidden_feature", override_hidden: true)).to be_default
          expect(t_course.lookup_feature_flag("hidden_feature", override_hidden: true)).to be_default
          expect(t_user.lookup_feature_flag("hidden_user_feature", override_hidden: true)).to be_default
        end

        it "does not create the implicit-off root_opt_in flag" do
          flag = t_root_account.lookup_feature_flag("hidden_root_opt_in_feature", override_hidden: true)
          expect(flag).to be_default
          expect(flag).to be_hidden
        end

        it "override_hidden should not trump root_opt_in" do
          expect(t_root_account.lookup_feature_flag("hidden_root_opt_in_feature", override_hidden: true)).to be_default
          expect(t_sub_account.lookup_feature_flag("hidden_root_opt_in_feature", override_hidden: true)).to be_nil
          expect(t_course.lookup_feature_flag("hidden_root_opt_in_feature", override_hidden: true)).to be_nil
        end
      end

      context "with site admin feature flag" do
        before do
          t_site_admin.feature_flags.create! feature: "hidden_feature"
          t_site_admin.feature_flags.create! feature: "hidden_user_feature"
        end

        it "finds the feature beneath site admin" do
          expect(t_site_admin.lookup_feature_flag("hidden_feature").context).to eql t_site_admin
          expect(t_root_account.lookup_feature_flag("hidden_feature").context).to eql t_site_admin
          expect(t_sub_account.lookup_feature_flag("hidden_feature").context).to eql t_site_admin
          expect(t_course.lookup_feature_flag("hidden_feature").context).to eql t_site_admin
          expect(t_user.lookup_feature_flag("hidden_user_feature").context).to eql t_site_admin
        end

        it "creates the implicit-off root_opt_in flag" do
          t_site_admin.feature_flags.create! feature: "hidden_root_opt_in_feature"
          flag = t_root_account.lookup_feature_flag("hidden_root_opt_in_feature")
          expect(flag).to be_new_record
          expect(flag.context).to eql t_root_account
          expect(flag.state).to eql "off"
        end
      end

      context "with root account feature flag" do
        before do
          t_root_account.feature_flags.create! feature: "hidden_feature"
        end

        it "finds the feature beneath site admin" do
          expect(t_site_admin.lookup_feature_flag("hidden_feature")).to be_default
          expect(t_root_account.lookup_feature_flag("hidden_feature").context).to eql t_root_account
          expect(t_sub_account.lookup_feature_flag("hidden_feature").context).to eql t_root_account
          expect(t_course.lookup_feature_flag("hidden_feature").context).to eql t_root_account
        end

        it "does not find the feature on a root account without a flag" do
          expect(account_model.lookup_feature_flag("hidden_feature")).to be_nil
        end
      end
    end

    describe "shadow" do
      it "does not find the feature unless site admin" do
        expect(t_root_account.lookup_feature_flag("shadow_feature", include_shadowed: false)).to be_nil
        expect(t_root_account.lookup_feature_flag("shadow_feature", include_shadowed: true)).to be_default
      end
    end

    context "cross-sharding" do
      specs_require_sharding

      it "searches on the correct shard" do
        t_sub_account.feature_flags.create! feature: "course_feature", state: "on"
        @other_course = t_sub_account.courses.create!

        @shard1.activate do
          flag = @other_course.lookup_feature_flag("course_feature")
          expect(flag).to_not be_default
          expect(@other_course.feature_enabled?("course_feature")).to be_truthy
        end
      end

      it "searches for site admin flags on the correct shard" do
        t_site_admin.feature_flags.create! feature: "course_feature", state: "on"

        @shard1.activate do
          account = Account.create!
          @other_course = account.courses.create!
          flag = @other_course.lookup_feature_flag("course_feature")
          expect(flag).to_not be_default
          expect(@other_course.feature_enabled?("course_feature")).to be_truthy
        end
      end
    end
  end

  describe "set_feature_flag!" do
    it "creates a feature flag" do
      t_root_account.set_feature_flag!(:course_feature, "allowed")
      expect(t_root_account.feature_flags.where(feature: "course_feature").first).to be_can_override
    end

    it "updates a feature flag" do
      flag = t_root_account.feature_flags.create! feature: "course_feature", state: "allowed"
      t_root_account.set_feature_flag!(:course_feature, "on")
      expect(flag.reload).to be_enabled
    end
  end

  describe "convenience methods" do
    it "enable_feature!s" do
      t_root_account.enable_feature! :course_feature
      expect(t_root_account.feature_flags.where(feature: "course_feature").first).to be_enabled
    end

    it "allow_feature!s" do
      t_root_account.allow_feature! :course_feature
      expect(t_root_account.feature_flags.where(feature: "course_feature").first).to be_can_override
    end

    it "reset_feature!s" do
      t_root_account.feature_flags.create! feature: "course_feature", state: "allowed"
      t_root_account.reset_feature! :course_feature
      expect(t_root_account.feature_flags.where(feature: "course_feature")).not_to be_any
    end
  end

  describe "caching" do
    let(:t_cache_key) { t_root_account.feature_flag_cache_key("course_feature") }

    before do
      t_root_account.feature_flags.create! feature: "course_feature", state: "allowed"
    end

    it "caches an object's feature flag" do
      enable_cache do
        t_root_account.feature_flag("course_feature")
        expect(Rails.cache).to exist(t_cache_key)
      end
    end

    it "caches a nil result" do
      enable_cache do
        t_root_account.feature_flag("course_feature2")
        expect(Rails.cache).to exist(t_root_account.feature_flag_cache_key("course_feature2"))
        expect(FeatureFlag).not_to receive(:where)
        t_root_account.reload.feature_flag("course_feature2")
      end
    end

    it "invalidates the cache when a feature flag is changed" do
      enable_cache do
        t_root_account.feature_flag("course_feature")
        t_root_account.feature_flags.where(feature: "course_feature").first.update_attribute(:state, "on")
        expect(Rails.cache).not_to exist(t_cache_key)
      end
    end

    it "invalidates the cache when a feature flag is destroyed" do
      enable_cache do
        t_root_account.feature_flag("course_feature")
        t_root_account.feature_flags.where(feature: "course_feature").first.destroy
        expect(Rails.cache).not_to exist(t_cache_key)
      end
    end

    it "skips the cache if requested" do
      enable_cache do
        flag = t_root_account.feature_flag("course_feature")
        expect(flag.state).to eq "allowed"
        allow(flag).to receive(:clear_cache).and_return(true) # pretend it was delayed
        flag.update_attribute(:state, "on") # update in db
        expect(t_root_account.feature_flag("course_feature").state).to eq "allowed" # still pulls from cache
        expect(t_root_account.feature_flag("course_feature", skip_cache: true).state).to eq "on" # skips it
      end
    end
  end

  describe "analytics" do
    it "sends nothing without a sampling_rate configured in DynamicSettings" do
      expect(analytics_service).not_to receive(:persist_feature_evaluation)
      t_sub_account.feature_enabled?(:account_feature)
    end

    it "send nothing if below the sampling rate" do
      allow(t_sub_account).to receive(:rand).and_return(0.8)
      override_dynamic_settings(private: { canvas: { feature_analytics: { sampling_rate: 0.5 } } }) do
        expect(analytics_service).not_to receive(:persist_feature_evaluation)
        t_sub_account.feature_enabled?(:account_feature)
      end
    end

    it "send feature context if above the sampling rate" do
      allow(t_sub_account).to receive(:rand).and_return(0.2)
      override_dynamic_settings(private: { canvas: { feature_analytics: { sampling_rate: 0.5 } } }) do
        expect(analytics_service).to receive(:persist_feature_evaluation)
        t_sub_account.feature_enabled?(:account_feature)
      end
    end

    it "caches redundant feature evaluations" do
      cache_key = t_sub_account.feature_analytics_cache_key("account_feature", true)
      override_dynamic_settings(private: { canvas: { feature_analytics: { sampling_rate: 1 } } }) do
        expect(analytics_service).to receive(:persist_feature_evaluation).once
        t_sub_account.feature_enabled?(:account_feature)
        t_sub_account.feature_enabled?(:account_feature)
        t_sub_account.feature_enabled?(:account_feature)
        expect(LocalCache.read(cache_key)).to be_truthy
      end
    end

    it "rescues and captures any unexpected exceptions" do
      err = StandardError.new("oh no!")
      expect(analytics_service).to receive(:persist_feature_evaluation).and_raise(err)
      expect(Canvas::Errors).to receive(:capture_exception).with(:feature_analytics, err)
      override_dynamic_settings(private: { canvas: { feature_analytics: { sampling_rate: 1 } } }) do
        t_sub_account.feature_enabled?(:account_feature)
      end
    end

    it "correctly sends context for root account-level flags" do
      expected_fields = {
        feature: :root_account_feature,
        context: "Account",
        root_account_id: t_root_account.global_id,
        account_id: t_root_account.global_id,
        course_id: nil,
        state: false
      }
      expect(analytics_service).to receive(:persist_feature_evaluation).with(hash_including(expected_fields))
      override_dynamic_settings(private: { canvas: { feature_analytics: { sampling_rate: 1 } } }) do
        t_root_account.feature_enabled?(:root_account_feature)
      end
    end

    it "correctly sends context for account-level flags" do
      expected_fields = {
        feature: :account_feature,
        context: "Account",
        root_account_id: t_root_account.global_id,
        account_id: t_sub_account.global_id,
        course_id: nil,
        state: true
      }
      expect(analytics_service).to receive(:persist_feature_evaluation).with(hash_including(expected_fields))
      override_dynamic_settings(private: { canvas: { feature_analytics: { sampling_rate: 1 } } }) do
        t_sub_account.feature_enabled?(:account_feature)
      end
    end

    it "correctly sends context for course-level flags" do
      expected_fields = {
        feature: :course_feature,
        context: "Course",
        root_account_id: t_root_account.global_id,
        account_id: t_sub_account.global_id,
        course_id: t_course.global_id,
        state: false
      }
      expect(analytics_service).to receive(:persist_feature_evaluation).with(hash_including(expected_fields))
      override_dynamic_settings(private: { canvas: { feature_analytics: { sampling_rate: 1 } } }) do
        t_course.feature_enabled?(:course_feature)
      end
    end
  end
end
