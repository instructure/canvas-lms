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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Feature Flags API", type: :request do
  let_once(:t_site_admin) { Account.site_admin }
  let_once(:t_root_account) { account_model }
  let_once(:t_teacher) { user_with_pseudonym account: t_root_account }
  let_once(:t_sub_account) { account_model parent_account: t_root_account }
  let_once(:t_course) { course_with_teacher(user: t_teacher, account: t_sub_account, active_all: true).course }
  let_once(:t_root_admin) { account_admin_user account: t_root_account }

  before do
    Feature.stubs(:definitions).returns({
      'root_account_feature' => Feature.new(feature: 'root_account_feature', applies_to: 'RootAccount', state: 'allowed'),
      'account_feature' => Feature.new(feature: 'account_feature', applies_to: 'Account', state: 'on', display_name: lambda { "Account Feature FRD" }, description: lambda { "FRD!!" }, beta: true),
      'course_feature' => Feature.new(feature: 'course_feature', applies_to: 'Course', state: 'allowed', development: true, release_notes_url: 'http://example.com', display_name: "not localized", description: "srsly"),
      'user_feature' => Feature.new(feature: 'user_feature', applies_to: 'User', state: 'allowed'),
      'root_opt_in_feature' => Feature.new(feature: 'root_opt_in_feature', applies_to: 'Course', state: 'allowed', root_opt_in: true),
      'hidden_feature' => Feature.new(feature: 'hidden_feature', applies_to: 'Course', state: 'hidden'),
      'hidden_user_feature' => Feature.new(feature: 'hidden_user_feature', applies_to: 'User', state: 'hidden')
    })
  end

  describe "index" do
    it "should check permissions" do
      api_call_as_user(t_teacher, :get, "/api/v1/accounts/#{t_root_account.id}/features",
         { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_root_account.to_param },
         {}, {}, { expected_status: 401 })
    end

    it "should return the correct format" do
      t_root_account.feature_flags.create! feature: 'course_feature', state: 'on', locking_account: t_site_admin
      json = api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_root_account.id}/features",
         { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_root_account.to_param })
      json.sort_by { |f| f['feature'] }.should eql(
         [{"feature"=>"account_feature",
           "display_name"=>"Account Feature FRD",
           "description"=>"FRD!!",
           "applies_to"=>"Account",
           "beta"=>true,
           "feature_flag"=>
               {"feature"=>"account_feature",
                "state"=>"on",
                "locked"=>true,
                "transitions"=>{"allowed"=>{"locked"=>false}, "off"=>{"locked"=>false}}}},
          {"feature"=>"course_feature",
           "applies_to"=>"Course",
           "development"=>true,
           "release_notes_url"=>"http://example.com",
           "display_name"=>"not localized",
           "description"=>"srsly",
           "feature_flag"=>
               {"context_id"=>t_root_account.id,
                "context_type"=>"Account",
                "locking_account_id"=>t_site_admin.id,
                "feature"=>"course_feature",
                "state"=>"on",
                "locked"=>true,
                "transitions"=>{"allowed"=>{"locked"=>false}, "off"=>{"locked"=>false}}}},
          {"feature"=>"root_account_feature",
           "applies_to"=>"RootAccount",
           "root_opt_in"=>true,
           "feature_flag"=>
               {"context_id"=>t_root_account.id,
                "context_type"=>"Account",
                "locking_account_id"=>nil,
                "feature"=>"root_account_feature",
                "state"=>"off",
                "locked"=>false,
                "transitions"=>{"allowed"=>{"locked"=>true}, "on"=>{"locked"=>false}}}},
          {"feature"=>"root_opt_in_feature",
           "applies_to"=>"Course",
           "root_opt_in"=>true,
           "feature_flag"=>
               {"context_id"=>t_root_account.id,
                "context_type"=>"Account",
                "feature"=>"root_opt_in_feature",
                "state"=>"off",
                "locking_account_id"=>nil,
                "locked"=>false,
                "transitions"=>{"allowed"=>{"locked"=>false}, "on"=>{"locked"=>false}}}}])
    end

    it "should paginate" do
      json = api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_root_account.id}/features?per_page=3",
                      { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_root_account.to_param, per_page: '3' })
      json.size.should eql 3
      json += api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_root_account.id}/features?per_page=3&page=2",
                       { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_root_account.to_param, per_page: '3', page: '2' })
      json.size.should eql 4
      json.map { |f| f['feature'] }.sort.should eql %w(account_feature course_feature root_account_feature root_opt_in_feature)
    end

    it "should return only relevant features" do
      json = api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_sub_account.id}/features",
                      { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_sub_account.to_param })
      json.map { |f| f['feature'] }.sort.should eql %w(account_feature course_feature)
    end

    it "should respect root_opt_in" do
      t_root_account.feature_flags.create! feature: 'root_opt_in_feature'
      json = api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_sub_account.id}/features",
                      { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_sub_account.to_param })
      json.map { |f| f['feature'] }.sort.should eql %w(account_feature course_feature root_opt_in_feature)
    end

    describe "hidden" do
      it "should show hidden features on site admin" do
        json = api_call_as_user(site_admin_user, :get, "/api/v1/accounts/#{t_site_admin.id}/features",
                        { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_site_admin.to_param })
        json.map { |f| f['feature'] }.sort.should eql %w(account_feature course_feature hidden_feature hidden_user_feature root_account_feature root_opt_in_feature user_feature)
        json.find { |f| f['feature'] == 'hidden_feature' }['hidden'].should be_true
      end

      it "should show hidden features on root accounts to a site admin user" do
        json = api_call_as_user(site_admin_user, :get, "/api/v1/accounts/#{t_root_account.id}/features",
           { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_root_account.to_param })
        json.map { |f| f['feature'] }.sort.should eql %w(account_feature course_feature hidden_feature root_account_feature root_opt_in_feature)
        json.find { |f| f['feature'] == 'hidden_feature' }['hidden'].should be_true
      end

      it "should show un-hidden features on root accounts" do
        t_root_account.feature_flags.create! feature: 'hidden_feature'
        json = api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_root_account.id}/features",
                        { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_root_account.to_param })
        json.map { |f| f['feature'] }.sort.should eql %w(account_feature course_feature hidden_feature root_account_feature root_opt_in_feature)
        json.find { |f| f['feature'] == 'hidden_feature' }['hidden'].should be_nil
      end

      it "should show 'hidden' flag for site admin even after a feature has been un-hidden" do
        t_root_account.feature_flags.create! feature: 'hidden_feature'
        json = api_call_as_user(site_admin_user, :get, "/api/v1/accounts/#{t_root_account.id}/features",
                                { controller: 'feature_flags', action: 'index', format: 'json', account_id: t_root_account.to_param })
        feature = json.find { |f| f['feature'] == 'hidden_feature' }
        feature['hidden'].should be_true
        feature['feature_flag']['state'].should eql 'allowed'
      end
    end

    it "should operate on a course" do
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/features",
                      { controller: 'feature_flags', action: 'index', format: 'json', course_id: t_course.to_param })
      json.map { |f| f['feature'] }.should eql %w(course_feature)
    end

    it "should operate on a user" do
      json = api_call_as_user(t_teacher, :get, "/api/v1/users/#{t_teacher.id}/features",
                      { controller: 'feature_flags', action: 'index', format: 'json', user_id: t_teacher.to_param })
      json.map { |f| f['feature'] }.should eql %w(user_feature)
    end
  end

  describe "enabled_features" do
    it "should check permissions" do
       api_call_as_user(t_teacher, :get, "/api/v1/accounts/#{t_root_account.id}/features/enabled",
                { controller: 'feature_flags', action: 'enabled_features', format: 'json', account_id: t_root_account.to_param },
                {}, {}, { expected_status: 401 })
    end

    it "should return the correct format" do
      t_root_account.feature_flags.create! feature: 'course_feature', state: 'on'
      json = api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_root_account.id}/features/enabled",
               { controller: 'feature_flags', action: 'enabled_features', format: 'json', account_id: t_root_account.to_param })
      json.sort.should eql %w(account_feature course_feature)
    end
  end

  describe "show" do
    it "should check permissions" do
      api_call_as_user(t_teacher, :get, "/api/v1/accounts/#{t_root_account.id}/features/flags/root_account_feature",
               { controller: 'feature_flags', action: 'show', format: 'json', account_id: t_root_account.to_param, feature: 'root_account_feature' },
               {}, {}, { expected_status: 401 })
    end

    it "should 404 if the feature doesn't exist" do
      api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_root_account.id}/features/flags/xyzzy",
               { controller: 'feature_flags', action: 'show', format: 'json', account_id: t_root_account.to_param, feature: 'xyzzy' },
               {}, {}, { expected_status: 404 })
    end

    it "should return the correct format" do
      json = api_call_as_user(t_teacher, :get, "/api/v1/users/#{t_teacher.id}/features/flags/user_feature",
               { controller: 'feature_flags', action: 'show', format: 'json', user_id: t_teacher.to_param, feature: 'user_feature' })
      json.should eql({"feature"=>"user_feature", "state"=>"allowed", "locked"=>false, "transitions"=>{"on"=>{"locked"=>false}, "off"=>{"locked"=>false}}})

      t_teacher.feature_flags.create! feature: 'user_feature', state: 'on'
      json = api_call_as_user(t_teacher, :get, "/api/v1/users/#{t_teacher.id}/features/flags/user_feature",
                      { controller: 'feature_flags', action: 'show', format: 'json', user_id: t_teacher.to_param, feature: 'user_feature' })
      json.should eql({"feature"=>"user_feature", "state"=>"on", "context_type"=>"User", "context_id"=>t_teacher.id, "locked"=>false, "locking_account_id"=>nil,
                       "transitions"=>{"off"=>{"locked"=>false}}})
    end

    describe "hidden" do
      it "should not find a hidden feature if the caller is an account admin" do
        json = api_call_as_user(t_root_admin, :get, "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                        { controller: 'feature_flags', action: 'show', format: 'json', account_id: t_root_account.to_param, feature: 'hidden_feature' },
                        {}, {}, { expected_status: 404 })
      end

      it "should find a hidden feature on a root account if the caller is site admin" do
        json = api_call_as_user(site_admin_user, :get, "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                        { controller: 'feature_flags', action: 'show', format: 'json', account_id: t_root_account.to_param, feature: 'hidden_feature' })
        json['state'].should eql 'hidden'
      end
    end
  end

  describe "update" do
    it "should check permissions" do
      api_call_as_user(t_teacher, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/root_account_feature",
               { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'root_account_feature' },
               {}, {}, { expected_status: 401 })
    end

    it "should validate state" do
      api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature?state=bamboozled",
               { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'course_feature', state: 'bamboozled' },
               {}, {}, { expected_status: 400 })
    end

    it "should create a new flag" do
      api_call_as_user(t_teacher, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=on",
               { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature', state: 'on' })
      t_course.feature_flags.map(&:state).should eql ['on']
    end

    it "should update an existing flag" do
      flag = t_root_account.feature_flags.create! feature: 'course_feature', state: 'on'
      api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature?state=off",
               { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'course_feature', state: 'off' })
      flag.reload
      flag.should_not be_enabled
    end

    it "should refuse to update if the canvas default locks the feature" do
      api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_sub_account.id}/features/flags/account_feature?state=off",
               { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_sub_account.to_param, feature: 'account_feature', state: 'off' },
               {}, {}, { expected_status: 403 })
    end

    it "should refuse to update if a higher account's flag locks the feature" do
      t_root_account.feature_flags.create! feature: 'course_feature', state: 'off'
      api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_sub_account.id}/features/flags/course_feature?state=on",
               { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_sub_account.to_param, feature: 'course_feature', state: 'on' },
               {}, {}, { expected_status: 403 })
    end

    it "should update the implicitly created root_opt_in feature flag" do
      flag = t_root_account.lookup_feature_flag('root_opt_in_feature')
      flag.context.should eql t_root_account
      flag.should be_new_record

      api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/root_opt_in_feature?state=allowed",
               { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'root_opt_in_feature', state: 'allowed' })
      flag = t_root_account.feature_flag('root_opt_in_feature')
      flag.should be_allowed
      flag.should_not be_new_record
    end

    it "should disallow 'allowed' setting for RootAccount features on (non-site-admin) root accounts" do
      t_root_account.disable_feature! :root_account_feature
      api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/root_account_feature?state=allowed",
                       { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'root_account_feature', state: 'allowed' },
                       {}, {}, { expected_status: 403 })
    end

    it "should clear the context's feature flag cache before deciding to insert or update" do
      cache_key = t_root_account.feature_flag_cache_key('course_feature')
      enable_cache do
        flag = t_root_account.feature_flags.create! feature: 'course_feature', state: 'on'
        # try to trick the controller into inserting (and violating a unique constraint) instead of updating
        Rails.cache.write(cache_key, :nil)
        api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature?state=off",
                         { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'course_feature', state: 'off' })
      end
    end

    describe "locking_account_id" do
      it "should require admin rights in the locking account to lock a flag" do
        api_call_as_user(t_teacher, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=on&locking_account_id=#{t_root_account.id}",
                 { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature',
                   state: 'on', locking_account_id: t_root_account.to_param },
                 {}, {}, { expected_status: 403 })

        api_call_as_user(t_root_admin, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=on&locking_account_id=#{t_root_account.id}",
                 { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature',
                   state: 'on', locking_account_id: t_root_account.to_param })
        t_course.feature_flags.where(feature: 'course_feature').first.locking_account.should eql t_root_account
      end

      it "should require admin rights in the locking account to modify a locked flag" do
        t_course.feature_flags.create! feature: 'course_feature', state: 'on', locking_account: t_root_account
        api_call_as_user(t_teacher, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=off",
                 { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature',
                   state: 'off' }, {}, {}, { expected_status: 403 })

        api_call_as_user(t_root_admin, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=off",
                 { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature',
                   state: 'off' })
        t_course.feature_flags.where(feature: 'course_feature').first.should_not be_enabled
      end

      it "should fail if the locking account isn't in the chain" do
        other_account = account_model
        user = account_admin_user user: t_teacher, account: other_account
        json = api_call_as_user(user, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=on&locking_account_id=#{other_account.id}",
                 { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature',
                   state: 'on', locking_account_id: other_account.to_param }, {}, {}, { expected_status: 400 })
      end

      it "should accept a SIS ID for the locking account" do
        t_sub_account.update_attribute(:sis_source_id, 'rainbow_sparkle')
        json = api_call_as_user(t_root_admin, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?state=on&locking_account_id=sis_account_id:rainbow_sparkle",
                        { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature',
                          state: 'on', locking_account_id: 'sis_account_id:rainbow_sparkle' }, {}, {}, { domain_root_account: t_root_account })
        t_course.feature_flags.where(feature: 'course_feature').first.locking_account.should eql t_sub_account
      end

      it "should clear the locking account" do
        t_course.feature_flags.create! feature: 'course_feature', state: 'on', locking_account: t_root_account
        api_call_as_user(t_root_admin, :put, "/api/v1/courses/#{t_course.id}/features/flags/course_feature?locking_account_id=",
                 { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'course_feature',
                   locking_account_id: '' })
        t_course.feature_flags.where(feature: 'course_feature').first.locking_account.should be_nil
      end
    end

    describe "hidden" do
      it "should create a site admin feature flag" do
        api_call_as_user(site_admin_user, :put, "/api/v1/accounts/#{t_site_admin.id}/features/flags/hidden_feature",
                 { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_site_admin.to_param, feature: 'hidden_feature' })
        t_site_admin.feature_flags.where(feature: 'hidden_feature').count.should eql 1
      end

      it "should create a root account feature flag with site admin privileges" do
        api_call_as_user(site_admin_user, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                 { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'hidden_feature' })
        t_root_account.feature_flags.where(feature: 'hidden_feature').count.should eql 1
      end

      it "should create a user feature flag with site admin priveleges" do
        site_admin_user
        api_call_as_user(@admin, :put, "/api/v1/users/#{@admin.id}/features/flags/hidden_user_feature",
                         { controller: 'feature_flags', action: 'update', format: 'json', user_id: @admin.to_param, feature: 'hidden_user_feature', state: 'on' })
        @admin.feature_flags.where(feature: 'hidden_user_feature').count.should eql 1
      end

      context "AccountManager" do
        before :once do
          t_site_admin.role_overrides.create!(permission: 'manage_feature_flags',
                                              enrollment_type: 'AccountManager',
                                              enabled: true,
                                              applies_to_self: false,
                                              applies_to_descendants: true)
          @site_admin_member = site_admin_user(membership_type: 'AccountManager')
        end

        it "should not create a site admin feature flag" do
          api_call_as_user(@site_admin_member, :put, "/api/v1/accounts/#{t_site_admin.id}/features/flags/hidden_feature",
                           { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_site_admin.to_param, feature: 'hidden_feature' },
                           {}, {}, { expected_status: 401 })
          t_site_admin.feature_flags.where(feature: 'hidden_feature').should_not be_any
        end

        it "should create a root account feature flag" do
          api_call_as_user(@site_admin_member, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                           { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'hidden_feature' })
          t_root_account.feature_flags.where(feature: 'hidden_feature').count.should eql 1
        end
      end

      it "should not create a root account feature flag with root admin privileges" do
        api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature",
                 { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'hidden_feature' },
                 {}, {}, { expected_status: 400 })
        t_root_account.feature_flags.where(feature: 'hidden_feature').should_not be_any
      end

      it "should modify a root account feature flag with root admin privileges" do
        t_root_account.feature_flags.create! feature: 'hidden_feature'
        api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_root_account.id}/features/flags/hidden_feature?state=on",
                 { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_root_account.to_param, feature: 'hidden_feature',
                   state: 'on' })
        t_root_account.feature_flags.where(feature: 'hidden_feature').first.should be_enabled
      end

      it "should not create a sub-account feature flag if no root-account or site-admin flag exists" do
        api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_sub_account.id}/features/flags/hidden_feature?state=on",
                 { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_sub_account.to_param, feature: 'hidden_feature', state: 'on' },
                 {}, {}, { expected_status: 400 })
      end

      it "should create a sub-account feature flag if a root-account feature flag exists" do
        t_root_account.feature_flags.create! feature: 'hidden_feature'
        api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_sub_account.id}/features/flags/hidden_feature?state=on",
                 { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_sub_account.to_param, feature: 'hidden_feature', state: 'on' })
        t_sub_account.feature_flags.where(feature: 'hidden_feature').first.should be_enabled
      end

      it "should create a sub-account feature flag if a site-admin feature flag exists" do
        t_site_admin.feature_flags.create! feature: 'hidden_feature'
        api_call_as_user(t_root_admin, :put, "/api/v1/accounts/#{t_sub_account.id}/features/flags/hidden_feature?state=on",
                 { controller: 'feature_flags', action: 'update', format: 'json', account_id: t_sub_account.to_param, feature: 'hidden_feature', state: 'on' })
        t_sub_account.feature_flags.where(feature: 'hidden_feature').first.should be_enabled
      end
    end
  end

  describe "delete" do
    it "should check permissions" do
      api_call_as_user(t_teacher, :delete, "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature",
               { controller: 'feature_flags', action: 'delete', format: 'json', account_id: t_root_account.to_param, feature: 'course_feature' },
               {}, {}, { expected_status: 401 })
    end

    it "should delete a feature flag" do
      t_root_account.feature_flags.create! feature: 'course_feature'
      api_call_as_user(t_root_admin, :delete, "/api/v1/accounts/#{t_root_account.id}/features/flags/course_feature",
               { controller: 'feature_flags', action: 'delete', format: 'json', account_id: t_root_account.to_param, feature: 'course_feature' })
      t_root_account.feature_flags.where(feature: 'course_feature').should be_empty
    end

    it "should not delete an inherited flag" do
      t_root_account.feature_flags.create! feature: 'course_feature'
      api_call_as_user(t_root_admin, :delete, "/api/v1/accounts/#{t_sub_account.id}/features/flags/course_feature",
               { controller: 'feature_flags', action: 'delete', format: 'json', account_id: t_sub_account.to_param, feature: 'course_feature' },
               {}, {}, { expected_status: 404 })
    end

    it "should not delete a feature flag locked by a higher account" do
      t_teacher.feature_flags.create! feature: 'user_feature', state: 'on'
      api_call_as_user(t_teacher, :delete, "/api/v1/users/#{t_teacher.id}/features/flags/user_feature",
               { controller: 'feature_flags', action: 'delete', format: 'json', user_id: t_teacher.to_param, feature: 'user_feature' })
      t_teacher.feature_flags.where(feature: 'course_feature').should be_empty

      t_teacher.feature_flags.create! feature: 'user_feature', state: 'on', locking_account: t_root_account
      api_call_as_user(t_teacher, :delete, "/api/v1/users/#{t_teacher.id}/features/flags/user_feature",
               { controller: 'feature_flags', action: 'delete', format: 'json', user_id: t_teacher.to_param, feature: 'user_feature' },
               {}, {}, { expected_status: 403 })
    end
  end

  describe "custom_transition_proc" do
    before do
      Feature.stubs(:definitions).returns({
          'custom_feature' => Feature.new(feature: 'custom_feature', applies_to: 'Course', state: 'allowed',
                custom_transition_proc: ->(user, context, from_state, transitions) do
                  transitions['off'] = { 'locked'=>true, 'message'=>"don't ever turn this off" } if from_state == 'on'
                  transitions['on'] = { 'locked'=>false, 'message'=>"this is permanent?!" } if transitions.has_key?('on')
                end
          )
      })
    end

    it "should give message for unlocked transition" do
      json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/features",
          { controller: 'feature_flags', action: 'index', format: 'json', course_id: t_course.to_param })
      json.should eql([
          {"feature"=>"custom_feature",
           "applies_to"=>"Course",
           "feature_flag"=>
               {"feature"=>"custom_feature",
                "state"=>"allowed",
                "locked"=>false,
                "transitions"=>{"on"=>{"locked"=>false,"message"=>"this is permanent?!"},"off"=>{"locked"=>false}}}}])
    end

    context "locked transition" do
      before do
        t_course.enable_feature! :custom_feature
      end

      it "should indicate a transition is locked" do
        json = api_call_as_user(t_teacher, :get, "/api/v1/courses/#{t_course.id}/features/flags/custom_feature",
           { controller: 'feature_flags', action: 'show', format: 'json', course_id: t_course.id, feature: 'custom_feature' })
        json.should eql({"context_id"=>t_course.id,"context_type"=>"Course","feature"=>"custom_feature",
                         "locking_account_id"=>nil,"state"=>"on", "locked"=>false,
                         "transitions"=>{"off"=>{"locked"=>true,"message"=>"don't ever turn this off"}}})
      end

      it "should reject a locked state transition" do
        api_call_as_user(t_root_admin, :put, "/api/v1/courses/#{t_course.id}/features/flags/custom_feature?state=off",
           { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'custom_feature', state: 'off' },
           {}, {}, { expected_status: 403 })
      end
    end
  end

  describe "after_state_change_proc" do
    let(:t_state_changes) { [] }

    before do
      Feature.stubs(:definitions).returns({
          'custom_feature' => Feature.new(feature: 'custom_feature', applies_to: 'Course', state: 'allowed',
                after_state_change_proc: ->(context, from_state, to_state) do
                  t_state_changes << [context.id, from_state, to_state]
                end
          )
      })
    end

    it "should fire when creating a feature flag to enable an allowed feature" do
      expect {
        api_call_as_user(t_root_admin, :put, "/api/v1/courses/#{t_course.id}/features/flags/custom_feature?state=on",
           { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'custom_feature', state: 'on' })
      }.to change(t_state_changes, :size).by(1)
      t_state_changes.last.should eql [t_course.id, 'allowed', 'on']
    end

    it "should fire when changing a feature flag's state" do
      t_course.disable_feature! 'custom_feature'
      expect {
        api_call_as_user(t_root_admin, :put, "/api/v1/courses/#{t_course.id}/features/flags/custom_feature?state=on",
           { controller: 'feature_flags', action: 'update', format: 'json', course_id: t_course.to_param, feature: 'custom_feature', state: 'on' })
      }.to change(t_state_changes, :size).by(1)
      t_state_changes.last.should eql [t_course.id, 'off', 'on']
    end
  end

end
