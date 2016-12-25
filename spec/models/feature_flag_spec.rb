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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe FeatureFlag do
  let_once(:t_root_account) { account_model }
  let_once(:t_sub_account) { account_model parent_account: t_root_account }
  let_once(:t_course) { course_factory account: t_sub_account, active_all: true }

  before do
    Feature.stubs(:definitions).returns({
      'root_account_feature' => Feature.new(feature: 'root_account_feature', applies_to: 'RootAccount'),
      'account_feature' => Feature.new(feature: 'account_feature', applies_to: 'Account'),
      'course_feature' => Feature.new(feature: 'course_feature', applies_to: 'Course'),
      'user_feature' => Feature.new(feature: 'user_feature', applies_to: 'User'),
      'hidden_feature' => Feature.new(feature: 'hidden_feature', state: 'hidden', applies_to: 'Course'),
      'hidden_root_opt_in_feature' => Feature.new(feature: 'hidden_feature', state: 'hidden', applies_to: 'Course', root_opt_in: true)
    })
  end

  context "validation" do
    it "should validate the state" do
      flag = t_root_account.feature_flags.build(feature: 'root_account_feature', state: 'nonplussed')
      expect(flag).not_to be_valid
    end

    it "should validate the feature exists" do
      flag = t_root_account.feature_flags.build(feature: 'xyzzy')
      expect(flag).not_to be_valid
    end

    it "should allow 'allowed' state only in accounts" do
      flag = t_sub_account.feature_flags.build(feature: 'course_feature', state: 'allowed')
      expect(flag).to be_valid

      flag = t_course.feature_flags.build(feature: 'course_feature', state: 'allowed')
      expect(flag).not_to be_valid
    end

    it "should validate the feature applies to the context" do
      flag = t_root_account.feature_flags.build(feature: 'root_account_feature')
      expect(flag).to be_valid

      flag = t_sub_account.feature_flags.build(feature: 'root_account_feature')
      expect(flag).not_to be_valid
    end
  end

  describe "locked?" do
    it "should return false for allowed features" do
      flag = t_root_account.feature_flags.create! feature: 'account_feature', state: 'allowed'
      expect(flag.locked?(t_root_account)).to be_falsey
      expect(flag.locked?(t_sub_account)).to be_falsey
    end

    describe "not allowed" do
      let!(:t_flag) { t_root_account.feature_flags.create! feature: 'account_feature', state: 'off' }

      it "should be false in the setting context" do
        expect(t_flag.locked?(t_root_account)).to be_falsey
      end

      it "should be true in a lower context" do
        expect(t_flag.locked?(t_sub_account)).to be_truthy
      end
    end
  end

  describe "unhides_feature?" do
    it "should be true on a site admin feature flag" do
      Account.site_admin.allow_feature! :hidden_feature
      expect(Account.site_admin.lookup_feature_flag(:hidden_feature)).to be_unhides_feature
    end

    it "should be true on a root account feature flag with no site admin flag set" do
      t_root_account.allow_feature! :hidden_feature
      expect(t_root_account.lookup_feature_flag(:hidden_feature)).to be_unhides_feature
    end

    it "should be false on a root account feature flag with site admin flag set" do
      Account.site_admin.allow_feature! :hidden_feature
      t_root_account.enable_feature! :hidden_feature
      expect(t_root_account.lookup_feature_flag(:hidden_feature)).not_to be_unhides_feature
    end

    it "should be true on a sub-account feature flag with no root or site admin flags set" do
      t_sub_account.allow_feature! :hidden_feature
      expect(t_sub_account.lookup_feature_flag(:hidden_feature)).to be_unhides_feature
    end

    it "should be false on a sub-account feature flag with a root flag set" do
      t_root_account.allow_feature! :hidden_feature
      t_sub_account.enable_feature! :hidden_feature
      expect(t_sub_account.lookup_feature_flag(:hidden_feature)).not_to be_unhides_feature
    end

    it "should be true on a sub-account root-opt-in feature flag with no root or site admin flags set" do
      t_course.enable_feature! :hidden_root_opt_in_feature
      expect(t_course.feature_flag(:hidden_root_opt_in_feature)).to be_unhides_feature
    end
  end
end
