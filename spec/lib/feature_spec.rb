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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Feature do
  let(:t_site_admin) { Account.site_admin }
  let(:t_root_account) { account_model }
  let(:t_sub_account) { account_model parent_account: t_root_account }
  let(:t_course) { course_factory account: t_sub_account, active_all: true }
  let(:t_user) { user_with_pseudonym account: t_root_account }

  before do
    allow_any_instance_of(User).to receive(:set_default_feature_flags)
    allow(Feature).to receive(:definitions).and_return({
        'SA' => Feature.new(feature: 'SA', applies_to: 'SiteAdmin', state: 'off'),
        'RA' => Feature.new(feature: 'RA', applies_to: 'RootAccount', state: 'hidden'),
        'A' => Feature.new(feature: 'A', applies_to: 'Account', state: 'on'),
        'C' => Feature.new(feature: 'C', applies_to: 'Course', state: 'off'),
        'U' => Feature.new(feature: 'U', applies_to: 'User', state: 'allowed'),
    })
  end

  describe "applies_to_object" do
    it "should work for SiteAdmin features" do
      feature = Feature.definitions['SA']
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_falsey
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "should work for RootAccount features" do
      feature = Feature.definitions['RA']
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "should work for Account features" do
      feature = Feature.definitions['A']
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_truthy
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "should work for Course features" do
      feature = Feature.definitions['C']
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_truthy
      expect(feature.applies_to_object(t_sub_account)).to be_truthy
      expect(feature.applies_to_object(t_course)).to be_truthy
      expect(feature.applies_to_object(t_user)).to be_falsey
    end

    it "should work for User features" do
      feature = Feature.definitions['U']
      expect(feature.applies_to_object(t_site_admin)).to be_truthy
      expect(feature.applies_to_object(t_root_account)).to be_falsey
      expect(feature.applies_to_object(t_sub_account)).to be_falsey
      expect(feature.applies_to_object(t_course)).to be_falsey
      expect(feature.applies_to_object(t_user)).to be_truthy
    end
  end

  describe "applicable_features" do
    it "should work for Site Admin" do
      expect(Feature.applicable_features(t_site_admin).map(&:feature).sort).to eql %w(A C RA SA U)
    end

    it "should work for RootAccounts" do
      expect(Feature.applicable_features(t_root_account).map(&:feature).sort).to eql %w(A C RA)
    end

    it "should work for Accounts" do
      expect(Feature.applicable_features(t_sub_account).map(&:feature).sort).to eql %w(A C)
    end

    it "should work for Courses" do
      expect(Feature.applicable_features(t_course).map(&:feature)).to eql %w(C)
    end

    it "should work for Users" do
      expect(Feature.applicable_features(t_user).map(&:feature)).to eql %w(U)
    end
  end

  describe "locked?" do
    it "should return true if context is nil" do
      expect(Feature.definitions['RA'].locked?(nil)).to be_truthy
      expect(Feature.definitions['A'].locked?(nil)).to be_truthy
      expect(Feature.definitions['C'].locked?(nil)).to be_truthy
      expect(Feature.definitions['U'].locked?(nil)).to be_truthy
    end

    it "should return true in a lower context if the definition disallows override" do
      expect(Feature.definitions['RA'].locked?(t_site_admin)).to be_falsey
      expect(Feature.definitions['A'].locked?(t_site_admin)).to be_truthy
      expect(Feature.definitions['C'].locked?(t_site_admin)).to be_truthy
      expect(Feature.definitions['U'].locked?(t_site_admin)).to be_falsey
    end
  end

  describe "RootAccount feature" do
    it "should imply root_opt_in" do
      expect(Feature.definitions['RA'].root_opt_in).to be_truthy
    end
  end

  describe "default_transitions" do
    it "should enumerate SiteAdmin transitions" do
      fd = Feature.definitions['SA']
      expect(fd.default_transitions(t_site_admin, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_site_admin, 'on')).to eql({"allowed"=>{"locked"=>true},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_site_admin, 'off')).to eql({"allowed"=>{"locked"=>true},'on'=>{'locked'=>false}})
    end

    it "should enumerate RootAccount transitions" do
      fd = Feature.definitions['RA']
      expect(fd.default_transitions(t_site_admin, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_site_admin, 'on')).to eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_site_admin, 'off')).to eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'on')).to eql({'allowed'=>{'locked'=>true},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'off')).to eql({'allowed'=>{'locked'=>true},'on'=>{'locked'=>false}})
    end

    it "should enumerate Account transitions" do
      fd = Feature.definitions['A']
      expect(fd.default_transitions(t_root_account, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'on')).to eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_root_account, 'off')).to eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_sub_account, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_sub_account, 'on')).to eql({'allowed'=>{'locked'=>false},'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_sub_account, 'off')).to eql({'allowed'=>{'locked'=>false},'on'=>{'locked'=>false}})
    end

    it "should enumerate Course transitions" do
      fd = Feature.definitions['C']
      expect(fd.default_transitions(t_course, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_course, 'on')).to eql({'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_course, 'off')).to eql({'on'=>{'locked'=>false}})
    end

    it "should enumerate User transitions" do
      fd = Feature.definitions['U']
      expect(fd.default_transitions(t_user, 'allowed')).to eql({'off'=>{'locked'=>false},'on'=>{'locked'=>false}})
      expect(fd.default_transitions(t_user, 'on')).to eql({'off'=>{'locked'=>false}})
      expect(fd.default_transitions(t_user, 'off')).to eql({'on'=>{'locked'=>false}})
    end
  end

  describe "remove_obsolete_flags" do
    it "removes old feature flags for nonexistent features" do
      # some hackery to circumvent the validation and create flags for nonexistent features
      t_root_account.feature_flags.create!(feature: 'RA', state: 'on').tap do |flag|
        FeatureFlag.where(id: flag.id).update_all(feature: 'nonexist')
      end
      t_root_account.feature_flags.create!(feature: 'RA', state: 'on').tap do |flag|
        FeatureFlag.where(id: flag.id).update_all(feature: 'nonexist-old', updated_at: 90.days.ago)
      end
      t_root_account.feature_flags.create!(feature: 'RA', state: 'on')

      Feature.remove_obsolete_flags
      expect(t_root_account.feature_flags.where(feature: %w(RA nonexist nonexist-old)).pluck(:feature))
        .to match_array(%w(RA nonexist))
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
      applies_to: 'RootAccount',
      state: 'allowed'
    }
  end

  let(:t_dev_feature_hash) do
    t_feature_hash.merge(environments: {production: {state: 'disabled'}})
  end

  it "should register a feature" do
    Feature.register({some_feature: t_feature_hash})
    expect(Feature.definitions).to be_frozen
    expect(Feature.definitions['some_feature'].display_name.call).to eql('some feature or other')
  end

  describe "development" do
    it "should register in a test environment" do
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).not_to be_nil
    end

    it "should register in a dev environment" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:development?).and_return(true)
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).not_to be_nil
    end

    it "should register in a production test cluster" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      allow(ApplicationController).to receive(:test_cluster?).and_return(true)
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).not_to be_nil
    end

    it "should not register in production" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      Feature.register({dev_feature: t_dev_feature_hash})
      expect(Feature.definitions['dev_feature']).to eq Feature::DISABLED_FEATURE
    end
  end

  let(:t_hidden_in_prod_feature_hash) do
    t_feature_hash.merge(environments: {production: {state: 'hidden'}})
  end

  describe 'hidden_in_prod' do
    it "should register as 'allowed' in a test environment" do
      Feature.register({dev_feature: t_hidden_in_prod_feature_hash})
      expect(Feature.definitions['dev_feature']).to be_allowed
    end

    it "should register as 'hidden' in production" do
      allow(Rails.env).to receive(:test?).and_return(false)
      allow(Rails.env).to receive(:production?).and_return(true)
      Feature.register({dev_feature: t_hidden_in_prod_feature_hash})
      expect(Feature.definitions['dev_feature']).to be_hidden
    end
  end
end
