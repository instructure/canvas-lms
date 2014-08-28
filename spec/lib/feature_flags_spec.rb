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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe FeatureFlags do
  let(:t_site_admin) { Account.site_admin }
  let(:t_root_account) { account_model }
  let(:t_user) { user_with_pseudonym account: t_root_account }
  let(:t_sub_account) { account_model parent_account: t_root_account }
  let(:t_course) { course_with_teacher(user: t_user, account: t_sub_account, active_all: true).course }

  before do
    Feature.stubs(:definitions).returns({
      'root_account_feature' => Feature.new(feature: 'root_account_feature', applies_to: 'RootAccount', state: 'off'),
      'account_feature' => Feature.new(feature: 'account_feature', applies_to: 'Account', state: 'on'),
      'course_feature' => Feature.new(feature: 'course_feature', applies_to: 'Course', state: 'allowed'),
      'user_feature' => Feature.new(feature: 'user_feature', applies_to: 'User', state: 'allowed'),
      'root_opt_in_feature' => Feature.new(feature: 'root_opt_in_feature', applies_to: 'Course', state: 'allowed', root_opt_in: true),
      'hidden_feature' => Feature.new(feature: 'hidden_feature', applies_to: 'Course', state: 'hidden'),
      'hidden_root_opt_in_feature' => Feature.new(feature: 'hidden_feature', applies_to: 'Course', state: 'hidden', root_opt_in: true),
      'hidden_user_feature' => Feature.new(feature: 'hidden_user_feature', applies_to: 'User', state: 'hidden')
  })
  end

  it "should report feature_enabled? correctly" do
    t_sub_account.feature_enabled?(:course_feature).should be_false
    t_sub_account.feature_enabled?(:account_feature).should be_true
  end

  it "should report feature_allowed? correctly" do
    t_root_account.feature_allowed?(:root_account_feature).should be_false
    t_course.feature_allowed?(:course_feature).should be_true
  end

  describe "lookup_feature_flag" do
    it "should return nil if the feature isn't defined" do
      t_root_account.lookup_feature_flag('blah').should be_nil
    end

    it "should return nil if the feature doesn't apply" do
      t_course.lookup_feature_flag('user_feature').should be_nil
    end

    it "should return defaults when no flags exist" do
      t_user.lookup_feature_flag('user_feature').should be_default
    end

    context "site admin flags" do
      it "should ignore site admin settings if definition doesn't allow override" do
        t_site_admin.feature_flags.create! feature: 'root_account_feature', state: 'allowed'
        t_root_account.lookup_feature_flag('root_account_feature').should be_default
      end

      it "should apply site admin settings if definition does allow override" do
        t_site_admin.feature_flags.create! feature: 'course_feature', state: 'on'
        t_course.lookup_feature_flag('course_feature').context.should eql t_site_admin
      end

      it "should override lower settings if not allowed" do
        t_root_account.feature_flags.create! feature: 'course_feature', state: 'on'
        t_root_account.lookup_feature_flag('course_feature').context.should eql t_root_account
        t_course.feature_enabled?('course_feature').should be_true
        t_site_admin.feature_flags.create! feature: 'course_feature', state: 'off'
        t_root_account.instance_variable_set(:@feature_flag_cache, nil)
        t_root_account.lookup_feature_flag('course_feature').context.should eql t_site_admin
        t_course.instance_variable_set(:@feature_flag_cache, nil)
        t_course.feature_enabled?('course_feature').should be_false
      end
    end

    context "account flags" do
      it "should apply settings at the sub-account level" do
        t_sub_account.feature_flags.create! feature: 'course_feature', state: 'on'
        t_root_account.lookup_feature_flag('course_feature').should be_default
        t_root_account.feature_enabled?('course_feature').should be_false
        t_sub_account.lookup_feature_flag('course_feature').context.should eql t_sub_account
        t_sub_account.feature_enabled?('course_feature').should be_true
        t_course.feature_enabled?('course_feature').should be_true
        course_model(account: t_root_account).feature_enabled?('course_feature').should be_false
      end

      it "should ignore settings locked by a higher account" do
        t_sub_account.feature_flags.create! feature: 'course_feature', state: 'on'
        t_root_account.feature_flags.create! feature: 'course_feature', state: 'off'
        t_sub_account.lookup_feature_flag('course_feature').context.should eql t_root_account
        t_sub_account.feature_enabled?('course_feature').should be_false
        t_course.feature_enabled?('course_feature').should be_false
      end

      it "should cache the lookup" do
        t_sub_account.feature_flags.create! feature: 'course_feature', state: 'on'
        t_root_account.feature_flags.create! feature: 'course_feature', state: 'off'
        t_sub_account.lookup_feature_flag('course_feature').context.should eql t_root_account
        Account.any_instance.expects(:feature_flag).never
        t_sub_account.lookup_feature_flag('course_feature').context.should eql t_root_account
      end
    end

    context "course flags" do
      it "should apply settings at the course level" do
        other_course = t_sub_account.courses.create!
        other_course.feature_flags.create! feature: 'course_feature', state: 'on'
        other_course.feature_enabled?('course_feature').should be_true
        t_course.feature_enabled?('course_feature').should be_false
      end
    end

    context "user flags" do
      it "should apply settings at the site admin level" do
        t_user.lookup_feature_flag('user_feature').should be_default
        t_site_admin.feature_flags.create! feature: 'user_feature', state: 'off'
        t_user.instance_variable_set(:@feature_flag_cache, nil)
        t_user.lookup_feature_flag('user_feature').context.should eql t_site_admin
        t_user.feature_enabled?('user_feature').should be_false
      end

      it "should apply settings at the user level" do
        t_user.feature_flags.create! feature: 'user_feature', state: 'off'
        t_user.lookup_feature_flag('user_feature').context.should eql t_user
        t_user.feature_allowed?('user_feature').should be_false
        user_with_pseudonym(account: t_root_account).feature_allowed?('user_feature').should be_true
      end
    end

    describe "root_opt_in" do
      context "with no feature flags" do
        it "should not find the feature beneath the root account" do
          t_site_admin.lookup_feature_flag('root_opt_in_feature').should be_default
          t_root_account.lookup_feature_flag('root_opt_in_feature').should be_new_record
          t_sub_account.lookup_feature_flag('root_opt_in_feature').should be_nil
          t_course.lookup_feature_flag('root_opt_in_feature').should be_nil
        end

        it "should cache the nil of the feature beneath the root account" do
          t_course.lookup_feature_flag('root_opt_in_feature').should be_nil
          Account.any_instance.expects(:feature_flag).never
          t_course.lookup_feature_flag('root_opt_in_feature').should be_nil
        end
      end

      context "with site admin feature flag" do
        before do
          t_site_admin.feature_flags.create! feature: 'root_opt_in_feature'
        end

        it "should not find the feature beneath the root account" do
          t_site_admin.lookup_feature_flag('root_opt_in_feature').context.should eql t_site_admin
          t_root_account.lookup_feature_flag('root_opt_in_feature').should be_new_record
          t_sub_account.lookup_feature_flag('root_opt_in_feature').should be_nil
          t_course.lookup_feature_flag('root_opt_in_feature').should be_nil
        end
      end

      context "with root account feature flag" do
        before do
          t_root_account.feature_flags.create! feature: 'root_opt_in_feature'
        end

        it "should find the feature beneath the root account" do
          t_root_account.lookup_feature_flag('root_opt_in_feature').context.should eql t_root_account
          t_sub_account.lookup_feature_flag('root_opt_in_feature').context.should eql t_root_account
          t_course.lookup_feature_flag('root_opt_in_feature').context.should eql t_root_account
        end
      end
    end

    describe "hidden" do
      context "with no feature flags" do
        it "should not find the feature beneath site admin" do
          t_site_admin.lookup_feature_flag('hidden_feature').should be_default
          t_root_account.lookup_feature_flag('hidden_feature').should be_nil
          t_sub_account.lookup_feature_flag('hidden_feature').should be_nil
          t_course.lookup_feature_flag('hidden_feature').should be_nil
          t_user.lookup_feature_flag('hidden_user_feature').should be_nil
        end

        it "should find hidden features if override_hidden is given" do
          t_site_admin.lookup_feature_flag('hidden_feature', true).should be_default
          t_root_account.lookup_feature_flag('hidden_feature', true).should be_default
          t_sub_account.lookup_feature_flag('hidden_feature', true).should be_default
          t_course.lookup_feature_flag('hidden_feature', true).should be_default
          t_user.lookup_feature_flag('hidden_user_feature', true).should be_default
        end

        it "should not create the implicit-off root_opt_in flag" do
          flag = t_root_account.lookup_feature_flag('hidden_root_opt_in_feature', true)
          flag.should be_default
          flag.should be_hidden
        end

        it "override_hidden should not trump root_opt_in" do
          t_root_account.lookup_feature_flag('hidden_root_opt_in_feature', true).should be_default
          t_sub_account.lookup_feature_flag('hidden_root_opt_in_feature', true).should be_nil
          t_course.lookup_feature_flag('hidden_root_opt_in_feature', true).should be_nil
        end
      end

      context "with site admin feature flag" do
        before do
          t_site_admin.feature_flags.create! feature: 'hidden_feature'
          t_site_admin.feature_flags.create! feature: 'hidden_user_feature'
        end

        it "should find the feature beneath site admin" do
          t_site_admin.lookup_feature_flag('hidden_feature').context.should eql t_site_admin
          t_root_account.lookup_feature_flag('hidden_feature').context.should eql t_site_admin
          t_sub_account.lookup_feature_flag('hidden_feature').context.should eql t_site_admin
          t_course.lookup_feature_flag('hidden_feature').context.should eql t_site_admin
          t_user.lookup_feature_flag('hidden_user_feature').context.should eql t_site_admin
        end

        it "should create the implicit-off root_opt_in flag" do
          t_site_admin.feature_flags.create! feature: 'hidden_root_opt_in_feature'
          flag = t_root_account.lookup_feature_flag('hidden_root_opt_in_feature')
          flag.should be_new_record
          flag.context.should eql t_root_account
          flag.state.should eql 'off'
        end
      end

      context "with root account feature flag" do
        before do
          t_root_account.feature_flags.create! feature: 'hidden_feature'
        end

        it "should find the feature beneath site admin" do
          t_site_admin.lookup_feature_flag('hidden_feature').should be_default
          t_root_account.lookup_feature_flag('hidden_feature').context.should eql t_root_account
          t_sub_account.lookup_feature_flag('hidden_feature').context.should eql t_root_account
          t_course.lookup_feature_flag('hidden_feature').context.should eql t_root_account
        end

        it "should not find the feature on a root account without a flag" do
          account_model.lookup_feature_flag('hidden_feature').should be_nil
        end
      end
    end
  end

  describe "set_feature_flag!" do
    it "should create a feature flag" do
      t_root_account.set_feature_flag!(:course_feature, 'allowed')
      t_root_account.feature_flags.where(feature: 'course_feature').first.should be_allowed
    end

    it "should update a feature flag" do
      flag = t_root_account.feature_flags.create! feature: 'course_feature', state: 'allowed'
      t_root_account.set_feature_flag!(:course_feature, 'on')
      flag.reload.should be_enabled
    end
  end

  describe "convenience methods" do
    it "should enable_feature!" do
      t_root_account.enable_feature! :course_feature
      t_root_account.feature_flags.where(feature: 'course_feature').first.should be_enabled
    end

    it "should allow_feature!" do
      t_root_account.allow_feature! :course_feature
      t_root_account.feature_flags.where(feature: 'course_feature').first.should be_allowed
    end

    it "should reset_feature!" do
      t_root_account.feature_flags.create! feature: 'course_feature', state: 'allowed'
      t_root_account.reset_feature! :course_feature
      t_root_account.feature_flags.where(feature: 'course_feature').should_not be_any
    end
  end

  describe "caching" do
    let(:t_cache_key) { t_root_account.feature_flag_cache_key('course_feature') }
    before do
      t_root_account.feature_flags.create! feature: 'course_feature', state: 'allowed'
    end

    it "should cache an object's feature flag" do
      enable_cache do
        t_root_account.feature_flag('course_feature')
        Rails.cache.should be_exist(t_cache_key)
      end
    end

    it "should cache a nil result" do
      enable_cache do
        t_root_account.feature_flag('course_feature2')
        Rails.cache.should be_exist(t_root_account.feature_flag_cache_key('course_feature2'))
        t_root_account.expects(:feature_flags).never
        t_root_account.feature_flag('course_feature2')
      end
    end

    it "should invalidate the cache when a feature flag is changed" do
      enable_cache do
        t_root_account.feature_flag('course_feature')
        t_root_account.feature_flags.where(feature: 'course_feature').first.update_attribute(:state, 'on')
        Rails.cache.should_not be_exist(t_cache_key)
      end
    end

    it "should invalidate the cache when a feature flag is destroyed" do
      enable_cache do
        t_root_account.feature_flag('course_feature')
        t_root_account.feature_flags.where(feature: 'course_feature').first.destroy
        Rails.cache.should_not be_exist(t_cache_key)
      end
    end
  end
end
