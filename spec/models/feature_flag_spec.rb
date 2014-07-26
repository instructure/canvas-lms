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
  let_once(:t_course) { course account: t_sub_account, active_all: true }

  before do
    Feature.stubs(:definitions).returns({
      'root_account_feature' => Feature.new(feature: 'root_account_feature', applies_to: 'RootAccount'),
      'account_feature' => Feature.new(feature: 'account_feature', applies_to: 'Account'),
      'course_feature' => Feature.new(feature: 'course_feature', applies_to: 'Course'),
      'user_feature' => Feature.new(feature: 'user_feature', applies_to: 'User')
    })
  end

  context "validation" do
    it "should validate the state" do
      flag = t_root_account.feature_flags.build(feature: 'root_account_feature', state: 'nonplussed')
      flag.should_not be_valid
    end

    it "should validate the feature exists" do
      flag = t_root_account.feature_flags.build(feature: 'xyzzy')
      flag.should_not be_valid
    end

    it "should allow 'allowed' state only in accounts" do
      flag = t_sub_account.feature_flags.build(feature: 'course_feature', state: 'allowed')
      flag.should be_valid

      flag = t_course.feature_flags.build(feature: 'course_feature', state: 'allowed')
      flag.should_not be_valid
    end

    it "should validate the feature applies to the context" do
      flag = t_root_account.feature_flags.build(feature: 'root_account_feature')
      flag.should be_valid

      flag = t_sub_account.feature_flags.build(feature: 'root_account_feature')
      flag.should_not be_valid
    end

    it "should validate the locking account is in the chain" do
      flag = t_course.feature_flags.build(feature: 'course_feature', state: 'on', locking_account: t_sub_account)
      flag.should be_valid

      other_account = account_model
      flag = t_course.feature_flags.build(feature: 'course_feature', state: 'on', locking_account: other_account)
      flag.should_not be_valid
    end
  end

  describe "locked?" do
    it "should return false for allowed features" do
      flag = t_root_account.feature_flags.create! feature: 'account_feature', state: 'allowed'
      flag.locked?(t_root_account).should be_false
      flag.locked?(t_sub_account).should be_false
    end

    describe "not allowed" do
      let!(:t_flag) { t_root_account.feature_flags.create! feature: 'account_feature', state: 'off' }

      it "should be false in the setting context" do
        t_flag.locked?(t_root_account).should be_false
      end

      it "should be true in a lower context" do
        t_flag.locked?(t_sub_account).should be_true
      end

      describe "locking_account" do
        before do
          t_flag.locking_account = Account.site_admin
          t_flag.save!
        end

        it "should be false if the user has privileges" do
          site_admin_user
          t_flag.locked?(t_root_account, @user).should be_false
        end

        it "should be true if the user does not have privileges" do
          account_admin_user account: t_root_account
          t_flag.locked?(t_root_account, @user).should be_true
        end

        it "should be true if the user is unspecified" do
          t_flag.locked?(t_root_account).should be_true
        end
      end
    end
  end
end
