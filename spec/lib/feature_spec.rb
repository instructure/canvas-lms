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

require_relative "../spec_helper"
require_relative "../feature_flag_helper"

describe Feature do
  include FeatureFlagHelper

  let(:t_site_admin) { Account.site_admin }
  let(:t_root_account) { account_model }
  let(:t_sub_account) { account_model parent_account: t_root_account }
  let(:t_course) { course_factory account: t_sub_account, active_all: true }
  let(:t_user) { user_with_pseudonym account: t_root_account }

  before do
    silence_undefined_feature_flag_errors
    allow_any_instance_of(User).to receive(:set_default_feature_flags)
    allow(Feature).to receive(:definitions).and_return({
                                                         "SA" => Feature.new(feature: "SA", applies_to: "SiteAdmin", state: "off"),
                                                         "RA" => Feature.new(feature: "RA", applies_to: "RootAccount", state: "hidden"),
                                                         "A" => Feature.new(feature: "A", applies_to: "Account", state: "on"),
                                                         "C" => Feature.new(feature: "C", applies_to: "Course", state: "off"),
                                                         "U" => Feature.new(feature: "U", applies_to: "User", state: "allowed"),
                                                       })
  end

  describe "applies_to_object" do
    it "works for SiteAdmin features" do
      feature = Feature.definitions["SA"]
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_falsey
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "works for RootAccount features" do
      feature = Feature.definitions["RA"]
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "works for Account features" do
      feature = Feature.definitions["A"]
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_truthy
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "works for Course features" do
      feature = Feature.definitions["C"]
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_truthy
      expect(feature.applies_to_object(t_course)).to be_truthy
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "works for User features" do
      feature = Feature.definitions["U"]
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_falsey
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_truthy
    end
  end

  describe "applicable_features" do
    it "works for Site Admin" do
      expect(Feature.applicable_features(t_site_admin).map(&:feature).sort).to eql %w[A C RA SA U]
    end

    it "works for RootAccounts" do
      expect(Feature.applicable_features(t_root_account).map(&:feature).sort).to eql %w[A C RA]
    end

    it "works for Accounts" do
      expect(Feature.applicable_features(t_sub_account).map(&:feature).sort).to eql %w[A C]
    end

    it "works for Courses" do
      expect(Feature.applicable_features(t_course).map(&:feature)).to eql %w[C]
    end

    it "works for Users" do
      expect(Feature.applicable_features(t_user).map(&:feature)).to eql %w[U]
    end
  end

  describe "locked?" do
    it "returns true if context is nil" do
      expect(Feature.definitions["RA"].locked?(nil)).to be_truthy
      expect(Feature.definitions["A"].locked?(nil)).to be_truthy
      expect(Feature.definitions["C"].locked?(nil)).to be_truthy
      expect(Feature.definitions["U"].locked?(nil)).to be_truthy
    end

    it "returns true in a lower context if the definition disallows override" do
      expect(Feature.definitions["RA"].locked?(t_site_admin)).to be_falsey
      expect(Feature.definitions["A"].locked?(t_site_admin)).to be_truthy
      expect(Feature.definitions["C"].locked?(t_site_admin)).to be_truthy
      expect(Feature.definitions["U"].locked?(t_site_admin)).to be_falsey
    end
  end

  describe "Shadow features" do
    it "is not shadow? by default" do
      expect(Feature.definitions["SA"].shadow?).to be_falsey
      expect(Feature.definitions["RA"].shadow?).to be_falsey
      expect(Feature.definitions["A"].shadow?).to be_falsey
      expect(Feature.definitions["C"].shadow?).to be_falsey
      expect(Feature.definitions["U"].shadow?).to be_falsey
    end

    context "when shadowed" do
      before do
        Feature.definitions["SA"].instance_variable_set(:@shadow, true)
        Feature.definitions["RA"].instance_variable_set(:@shadow, true)
        Feature.definitions["A"].instance_variable_set(:@shadow, true)
        Feature.definitions["C"].instance_variable_set(:@shadow, true)
        Feature.definitions["U"].instance_variable_set(:@shadow, true)
      end

      it "is shadow?" do
        expect(Feature.definitions["SA"].shadow?).to be_truthy
        expect(Feature.definitions["RA"].shadow?).to be_truthy
        expect(Feature.definitions["A"].shadow?).to be_truthy
        expect(Feature.definitions["C"].shadow?).to be_truthy
        expect(Feature.definitions["U"].shadow?).to be_truthy
      end
    end
  end

  describe "RootAccount feature" do
    it "implies root_opt_in" do
      expect(Feature.definitions["RA"].root_opt_in).to be_truthy
    end
  end

  describe "default_transitions" do
    it "enumerates SiteAdmin transitions" do
      fd = Feature.definitions["SA"]
      expect(fd.default_transitions(t_site_admin, "allowed")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => true } })
      expect(fd.default_transitions(t_site_admin, "allowed_on")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed" => { "locked" => true } })
      expect(fd.default_transitions(t_site_admin, "on")).to eql({ "allowed" => { "locked" => true }, "off" => { "locked" => false }, "allowed_on" => { "locked" => true } })
      expect(fd.default_transitions(t_site_admin, "off")).to eql({ "allowed" => { "locked" => true }, "on" => { "locked" => false }, "allowed_on" => { "locked" => true } })
    end

    it "enumerates RootAccount transitions" do
      fd = Feature.definitions["RA"]
      expect(fd.default_transitions(t_site_admin, "allowed")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_site_admin, "allowed_on")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed" => { "locked" => false } })
      expect(fd.default_transitions(t_site_admin, "on")).to eql({ "allowed" => { "locked" => false }, "off" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_site_admin, "off")).to eql({ "allowed" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_root_account, "allowed")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => true } })
      expect(fd.default_transitions(t_root_account, "allowed_on")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed" => { "locked" => true } })
      expect(fd.default_transitions(t_root_account, "on")).to eql({ "allowed" => { "locked" => true }, "off" => { "locked" => false }, "allowed_on" => { "locked" => true } })
      expect(fd.default_transitions(t_root_account, "off")).to eql({ "allowed" => { "locked" => true }, "on" => { "locked" => false }, "allowed_on" => { "locked" => true } })
    end

    it "enumerates Account transitions" do
      fd = Feature.definitions["A"]
      expect(fd.default_transitions(t_root_account, "allowed")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_root_account, "allowed_on")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed" => { "locked" => false } })
      expect(fd.default_transitions(t_root_account, "on")).to eql({ "allowed" => { "locked" => false }, "off" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_root_account, "off")).to eql({ "allowed" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_sub_account, "allowed")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_sub_account, "allowed_on")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false }, "allowed" => { "locked" => false } })
      expect(fd.default_transitions(t_sub_account, "on")).to eql({ "allowed" => { "locked" => false }, "off" => { "locked" => false }, "allowed_on" => { "locked" => false } })
      expect(fd.default_transitions(t_sub_account, "off")).to eql({ "allowed" => { "locked" => false }, "on" => { "locked" => false }, "allowed_on" => { "locked" => false } })
    end

    it "enumerates Course transitions" do
      fd = Feature.definitions["C"]
      expect(fd.default_transitions(t_course, "allowed")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false } })
      expect(fd.default_transitions(t_course, "on")).to eql({ "off" => { "locked" => false } })
      expect(fd.default_transitions(t_course, "off")).to eql({ "on" => { "locked" => false } })
    end

    it "enumerates User transitions" do
      fd = Feature.definitions["U"]
      expect(fd.default_transitions(t_user, "allowed")).to eql({ "off" => { "locked" => false }, "on" => { "locked" => false } })
      expect(fd.default_transitions(t_user, "on")).to eql({ "off" => { "locked" => false } })
      expect(fd.default_transitions(t_user, "off")).to eql({ "on" => { "locked" => false } })
    end
  end

  describe "remove_obsolete_flags" do
    it "removes old feature flags for nonexistent features" do
      # some hackery to circumvent the validation and create flags for nonexistent features
      t_root_account.feature_flags.create!(feature: "RA", state: "on").tap do |flag|
        FeatureFlag.where(id: flag.id).update_all(feature: "nonexist")
      end
      t_root_account.feature_flags.create!(feature: "RA", state: "on").tap do |flag|
        FeatureFlag.where(id: flag.id).update_all(feature: "nonexist-old", updated_at: 90.days.ago)
      end
      t_root_account.feature_flags.create!(feature: "RA", state: "on")

      Feature.remove_obsolete_flags
      expect(t_root_account.feature_flags.where(feature: %w[RA nonexist nonexist-old]).pluck(:feature))
        .to match_array(%w[RA nonexist])
    end
  end
end

describe "Feature.register" do
  before do
    # unregister the default features
    @old_features = Feature.instance_variable_get(:@features)
    Feature.instance_variable_set(:@features, nil)
  end

  after do
    Feature.instance_variable_set(:@features, @old_features)
  end

  let(:t_feature_hash) do
    {
      display_name: -> { "some feature or other" },
      description: -> { "this does something" },
      applies_to: "RootAccount",
      state: "allowed",
      type: "feature_option"
    }
  end

  let(:t_dev_feature_hash) do
    t_feature_hash.merge(environments: { production: { state: "disabled" } })
  end

  let(:t_hidden_in_prod_feature_hash) do
    t_feature_hash.merge(environments: { production: { state: "hidden" } })
  end

  it "registers a feature" do
    Feature.register({ some_feature: t_feature_hash })
    expect(Feature.definitions).to be_frozen
    expect(Feature.definitions["some_feature"].display_name.call).to eql("some feature or other")
  end

  describe "development" do
    it "registers in a test environment" do
      Feature.register({ dev_feature: t_dev_feature_hash })
      expect(Feature.definitions["dev_feature"]).not_to be_nil
    end

    it "registers in a dev environment" do
      allow(Rails.env).to receive_messages(test?: false, development?: true)
      Feature.register({ dev_feature: t_dev_feature_hash })
      expect(Feature.definitions["dev_feature"]).not_to be_nil
    end

    it "registers in a production test cluster" do
      allow(Rails.env).to receive_messages(test?: false, production?: true)
      allow(ApplicationController).to receive(:test_cluster?).and_return(true)
      Feature.register({ dev_feature: t_dev_feature_hash })
      expect(Feature.definitions["dev_feature"]).not_to be_nil
    end

    it "does not register in production" do
      allow(Rails.env).to receive_messages(test?: false, production?: true)
      Feature.register({ dev_feature: t_dev_feature_hash })
      expect(Feature.definitions["dev_feature"]).to eq Feature::DISABLED_FEATURE
    end
  end

  describe "hidden_in_prod" do
    it "registers as 'allowed' in a test environment" do
      Feature.register({ dev_feature: t_hidden_in_prod_feature_hash })
      expect(Feature.definitions["dev_feature"]).to be_can_override
    end

    it "registers as 'hidden' in production" do
      allow(Rails.env).to receive_messages(test?: false, production?: true)
      Feature.register({ dev_feature: t_hidden_in_prod_feature_hash })
      expect(Feature.definitions["dev_feature"]).to be_hidden
    end
  end
end
