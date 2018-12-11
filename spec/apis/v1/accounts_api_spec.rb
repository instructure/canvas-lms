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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../../sharding_spec_helper')

describe "Accounts API", type: :request do
  before :once do
    user_with_pseudonym(:active_all => true)
    @a1 = account_model(:name => 'root', :default_time_zone => 'UTC', :default_storage_quota_mb => 123, :default_user_storage_quota_mb => 45, :default_group_storage_quota_mb => 42)
    @a1.account_users.create!(user: @user)
    @sis_batch = @a1.sis_batches.create
    SisBatch.where(id: @sis_batch).update_all(workflow_state: 'imported')
    @a2 = account_model(:name => 'subby', :parent_account => @a1, :root_account => @a1, :sis_source_id => 'sis1',  :sis_batch_id => @sis_batch.id, :default_time_zone => 'Alaska', :default_storage_quota_mb => 321, :default_user_storage_quota_mb => 54, :default_group_storage_quota_mb => 41)
    @a2.account_users.create!(user: @user)
    @a3 = account_model(:name => 'no-access')
    # even if we have access to it implicitly, it's not listed
    @a4 = account_model(:name => 'implicit-access', :parent_account => @a1, :root_account => @a1)
  end

  describe 'index' do
    it "should return the account list" do
      json = api_call(:get, "/api/v1/accounts.json",
                      { :controller => 'accounts', :action => 'index', :format => 'json' })

      expect(json.sort_by { |a| a['id'] }).to eq [
        {
          'id' => @a1.id,
          'uuid' => @a1.uuid,
          'name' => 'root',
          'root_account_id' => nil,
          'parent_account_id' => nil,
          'default_time_zone' => 'Etc/UTC',
          'default_storage_quota_mb' => 123,
          'default_user_storage_quota_mb' => 45,
          'default_group_storage_quota_mb' => 42,
          'workflow_state' => 'active',
        },
        {
          'id' => @a2.id,
          'uuid' => @a2.uuid,
          'integration_id' => nil,
          'name' => 'subby',
          'root_account_id' => @a1.id,
          'parent_account_id' => @a1.id,
          'sis_account_id' => 'sis1',
          'sis_import_id' => @sis_batch.id,
          'default_time_zone' => 'America/Juneau',
          'default_storage_quota_mb' => 321,
          'default_user_storage_quota_mb' => 54,
          'default_group_storage_quota_mb' => 41,
          'workflow_state' => 'active'
        },
      ]
    end

    it "doesn't include deleted accounts" do
      @a2.destroy
      json = api_call(:get, "/api/v1/accounts.json",
                      { :controller => 'accounts', :action => 'index', :format => 'json' })

      expect(json.sort_by { |a| a['id'] }).to eq [
        {
          'id' => @a1.id,
          'name' => 'root',
          'root_account_id' => nil,
          'parent_account_id' => nil,
          'default_time_zone' => 'Etc/UTC',
          'default_storage_quota_mb' => 123,
          'default_user_storage_quota_mb' => 45,
          'default_group_storage_quota_mb' => 42,
          'workflow_state' => 'active',
          'uuid' => @a1.uuid
        },
      ]
    end

    it "should return accounts found through admin enrollments with the account list (but in limited form)" do
      course_with_teacher(:user => @user, :account => @a1)
      course_with_teacher(:user => @user, :account => @a1)# don't find it twice
      course_with_teacher(:user => @user, :account => @a2)

      json = api_call(:get, "/api/v1/course_accounts",
        { :controller => 'accounts', :action => 'course_accounts', :format => 'json' })
      expect(json.sort_by { |a| a['id'] }).to eq [
            {
              'id' => @a1.id,
              'name' => 'root',
              'root_account_id' => nil,
              'parent_account_id' => nil,
              'workflow_state' => 'active',
              'default_time_zone' => 'Etc/UTC',
              'uuid' => @a1.uuid
            },
            {
              'id' => @a2.id,
              'name' => 'subby',
              'root_account_id' => @a1.id,
              'parent_account_id' => @a1.id,
              'workflow_state' => 'active',
              'default_time_zone' => 'America/Juneau',
              'uuid' => @a2.uuid
            },
          ]
    end

    describe "with sharding" do
      specs_require_sharding
      it "should include cross-shard accounts in course_accounts" do
        course_with_teacher(:user => @user, :account => @a1)
        @shard1.activate do
          @a5 = account_model(:name => "crossshard", :default_time_zone => 'UTC')
          course_with_teacher(:user => @user, :account => @a5)
        end

        json = api_call(:get, "/api/v1/course_accounts",
                        { :controller => 'accounts', :action => 'course_accounts', :format => 'json' })
        expect(json.sort_by { |a| a['id'] }).to eq [
            {
                'id' => @a1.id,
                'name' => 'root',
                'root_account_id' => nil,
                'parent_account_id' => nil,
                'workflow_state' => 'active',
                'default_time_zone' => 'Etc/UTC',
                'uuid' => @a1.uuid
            },
            {
                'id' => @a5.global_id,
                'name' => 'crossshard',
                'root_account_id' => nil,
                'parent_account_id' => nil,
                'workflow_state' => 'active',
                'default_time_zone' => 'Etc/UTC',
                'uuid' => @a5.uuid
            },
        ]
      end
    end
  end

  describe 'sub_accounts' do
    before :once do
      root = @a1
      a1 = root.sub_accounts.create! :name => "Account 1"
      a2 = root.sub_accounts.create! :name => "Account 2"
      a1.sub_accounts.create! :name => "Account 1.1"
      @a1_2 = a1.sub_accounts.create! :name => "Account 1.2"
      a1.sub_accounts.create! :name => "Account 1.2.1"
      3.times.each do |i|
        a2.sub_accounts.create! :name => "Account 2.#{i+1}"
      end
    end

    it "should return child accounts" do
      json = api_call(:get,
        "/api/v1/accounts/#{@a1.id}/sub_accounts",
        {:controller => 'accounts', :action => 'sub_accounts',
         :account_id => @a1.id.to_s, :format => 'json'})
      expect(json.map { |j| j['name'] }).to eq ['subby', 'implicit-access',
        'Account 1', 'Account 2']
    end

    it "should add sub account" do
      previous_sub_count = @a1.sub_accounts.size
      api_call(:post,
        "/api/v1/accounts/#{@a1.id}/sub_accounts",
         {:controller=>'sub_accounts', :action=>'create',
          :account_id => @a1.id.to_s, :format => 'json'},
         {:account => { 'name' => 'New sub-account',
                        'sis_account_id' => '567',
                        'default_storage_quota_mb' => 123,
                        'default_user_storage_quota_mb' => 456,
                        'default_group_storage_quota_mb' => 147 }})
      expect(@a1.sub_accounts.size).to eq previous_sub_count + 1
      sub = @a1.sub_accounts.detect{|a| a.name == "New sub-account"}
      expect(sub).not_to be_nil
      expect(sub.sis_source_id).to eq '567'
      expect(sub.default_storage_quota_mb).to eq 123
      expect(sub.default_user_storage_quota_mb).to eq 456
      expect(sub.default_group_storage_quota_mb).to eq 147
    end

    it 'should destroy a sub_account' do
      json = api_call(:delete,
                      "/api/v1/accounts/#{@a1.id}/sub_accounts/#{@a1_2.id}",
                      {controller: 'sub_accounts', action: 'destroy',
                       account_id: @a1.to_param, format: 'json', id: @a1_2.to_param})
      expect(json['id']).to eq @a1_2.id
      expect(json['workflow_state']).to eq 'deleted'
      expect(@a1_2.reload.workflow_state).to eq 'deleted'
    end

    describe "recursive" do

      it "returns sub accounts recursively" do
        json = api_call(:get,
          "/api/v1/accounts/#{@a1.id}/sub_accounts?recursive=1",
          {:controller => 'accounts', :action => 'sub_accounts',
           :account_id => @a1.id.to_s, :recursive => "1", :format => 'json'})

        expect(json.map { |j| j['name'] }.sort).to eq ['subby', 'implicit-access',
          'Account 1', 'Account 1.1', 'Account 1.2', 'Account 1.2.1',
          'Account 2', 'Account 2.1', 'Account 2.2', 'Account 2.3'].sort
      end

      it "ignores deleted accounts" do
        @a1.sub_accounts.create!(:name => "Deleted Account").destroy
        parent_account = @a1.sub_accounts.create!(:name => "Deleted Parent Account")
        parent_account.sub_accounts.create!(:name => "Child Account")
        Account.where(id: parent_account).update_all(workflow_state: 'deleted')

        json = api_call(:get,
                        "/api/v1/accounts/#{@a1.id}/sub_accounts?recursive=1",
                        {:controller => 'accounts', :action => 'sub_accounts',
                         :account_id => @a1.id.to_s, :recursive => "1", :format => 'json'})

        expect(json.map { |j| j['name'] }.sort).to eq ['subby', 'implicit-access',
                                                   'Account 1', 'Account 1.1', 'Account 1.2', 'Account 1.2.1',
                                                   'Account 2', 'Account 2.1', 'Account 2.2', 'Account 2.3'].sort
      end
    end
  end

  describe 'show' do
    it "should return an individual account" do
      # by id
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}",
                      { :controller => 'accounts', :action => 'show', :id => @a1.to_param, :format => 'json' })
      expect(json).to eq(
        {
          'id' => @a1.id,
          'name' => 'root',
          'uuid' => @a1.uuid,
          'root_account_id' => nil,
          'parent_account_id' => nil,
          'default_time_zone' => 'Etc/UTC',
          'default_storage_quota_mb' => 123,
          'default_user_storage_quota_mb' => 45,
          'default_group_storage_quota_mb' => 42,
          'workflow_state' => 'active',
        }
      )
    end

    it "should return an individual account for a teacher (but in limited form)" do
      limited = account_model(:name => "limited")
      course_with_teacher(:user => @user, :account => limited)

      json = api_call(:get, "/api/v1/accounts/#{limited.id}",
                      { :controller => 'accounts', :action => 'show', :id => limited.to_param, :format => 'json' })
      expect(json).to eq(
          {
              'id' => limited.id,
              'name' => 'limited',
              'root_account_id' => nil,
              'parent_account_id' => nil,
              'workflow_state' => 'active',
              'default_time_zone' => 'Etc/UTC',
              'uuid' => limited.uuid
          }
      )
    end

    it "should return the lti_guid" do
      @a1.lti_guid = 'hey'
      @a1.save!
      json = api_call(:get, "/api/v1/accounts?include[]=lti_guid",
                      { :controller => 'accounts', :action => 'index', :format => 'json', :include => ['lti_guid'] }, {})
      expect(json[0]["lti_guid"]).to eq 'hey'
    end

    it "should honor deprecated includes parameter" do
      @a1.lti_guid = 'hey'
      @a1.save!
      json = api_call(:get, "/api/v1/accounts?includes[]=lti_guid",
                      { :controller => 'accounts', :action => 'index', :format => 'json', :includes => ['lti_guid'] }, {})
      expect(json[0]["lti_guid"]).to eq 'hey'
    end
  end

  describe 'update' do

    let(:header_options_hash) do
      {
        :controller => 'accounts',
        :action => 'update',
        :id => @a1.to_param,
        :format => 'json'
      }
    end

    let(:query_params_hash) do
      {
        :account => {
          :settings => {
            :sis_assignment_name_length_input => {
              :value => nil
            }
          }
        }
      }
    end

    it "should update the name for an account" do
      new_name = 'root2'
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
                      { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
                      { :account => {:name => new_name} })

      expect(json).to include({
        'id' => @a1.id,
        'name' => new_name,
      })

      @a1.reload
      expect(@a1.name).to eq new_name
    end

    it "should update account settings" do
      new_name = 'root2'
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
        { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
        { :account => {:settings => {:restrict_student_past_view => {:value => true, :locked => false}}} })

      @a1.reload
      expect(@a1.restrict_student_past_view).to eq({:value => true, :locked => false})
    end

    it "should update services" do
      expect(@a1.service_enabled?(:avatars)).to be_falsey
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
        { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
        { :account => {:services => {:avatars => "1"}}})

      expect(json['services']['avatars']).to be_truthy
      expect(Account.find(@a1.id).service_enabled?(:avatars)).to be_truthy
    end

    it "should update sis_id" do
      json = api_call(:put, "/api/v1/accounts/#{@a2.id}",
        { controller: 'accounts', action: 'update', id: @a2.to_param, format: 'json' },
        { account: {sis_account_id: 'subsis'}})

      expect(json['sis_account_id']).to eq 'subsis'
      expect(Account.find(@a2.id).sis_source_id).to eq 'subsis'
    end

    it "should not update sis_id for root_accounts" do
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
        { controller: 'accounts', action: 'update', id: @a1.to_param, format: 'json' },
        { account: {sis_account_id: 'subsis'}}, {}, expected_status: 401)
      expect(json["errors"]["unauthorized"].first["message"]).to eq 'Cannot set sis_account_id on a root_account.'
      expect(Account.find(@a1.id).sis_source_id).to be_nil
    end

    # These following tests focus on testing the sis_assignment_name_length_input account setting
    # through the API. This setting is used to enforce assignment name length for assignments.
    # Valid values for this setting are integers/strings between 0-255. If a value is set greater
    # than or less than those boundaries OR if the value is nil/some arbitrary string the default
    # assignment name length value of 255 will be assigned to the setting to mitigate these cases.
    # Otherwise the value sent in will be assigned to the setting.
    it "should update account with sis_assignment_name_length_input with string number value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = '120'
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '120'
    end

    it "should update account with sis_assignment_name_length_input with string text value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = 'too much tuna'
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should update account with sis_assignment_name_length_input with nil value" do
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should update account with sis_assignment_name_length_input with empty string value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = ''
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should update account with sis_assignment_name_length_input with integer value" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = 200
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '200'
    end

    it "should set sis_assignment_name_length_input to default 255 if value is integer and over 255" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = 400
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should set sis_assignment_name_length_input to default 255 if value is string and over 255" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = '300'
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should set sis_assignment_name_length_input to default 255 if value is string and less than 0" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = '-2'
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should set sis_assignment_name_length_input to default 255 if value is integer and under 0" do
      query_params_hash[:account][:settings][:sis_assignment_name_length_input][:value] = -12
      api_call(:put, "/api/v1/accounts/#{@a1.id}", header_options_hash, query_params_hash)

      expect(Account.find(@a1.id).settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should not update with a blank name" do
      @a1.name = "blah"
      @a1.save!
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
        { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
        { :account => {:name => ""} }, {}, :expected_status => 400)

      expect(json["errors"]["name"].first["message"]).to eq "The account name cannot be blank"

      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
        { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
        { :account => {:name => nil} }, {}, :expected_status => 400)

      expect(json["errors"]["name"].first["message"]).to eq "The account name cannot be blank"

      @a1.reload
      expect(@a1.name).to eq "blah"
    end

    it "should update the default_time_zone for an account with an IANA timezone name" do
      new_zone = 'America/Juneau'
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
                      { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
                      { :account => {:default_time_zone => new_zone} })

      expect(json).to include({
        'id' => @a1.id,
        'default_time_zone' => new_zone,
      })

      @a1.reload
      expect(@a1.default_time_zone.tzinfo.name).to eq new_zone
    end

    it "should update the default_time_zone for an account with a Rails timezone name" do
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
                      { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
                      { :account => {:default_time_zone => 'Alaska'} })

      expect(json).to include({
                              'id' => @a1.id,
                              'default_time_zone' => 'America/Juneau',
                          })

      @a1.reload
      expect(@a1.default_time_zone.name).to eq 'Alaska'
    end

    it "should check for a valid time zone" do
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
               { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
               { :account => {:default_time_zone => 'Booger'} }, {}, { :expected_status => 400 })
      expect(json["errors"]["default_time_zone"].first["message"]).to eq "'Booger' is not a recognized time zone"
    end

    it "should not update other attributes (yet)" do
      json = api_call(:put, "/api/v1/accounts/#{@a1.id}",
                      { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' },
                      { :account => {:settings => {:setting => 'set'}}} )

      expect(json).to include({
        'id' => @a1.id,
        'name' => @a1.name,
      })

      @a1.reload
      expect(@a1.settings).to be_empty
    end

    context 'with :manage_storage_quotas' do
      before(:once) do
        # remove the user from being an Admin
        @a1.account_users.where(user_id: @user).delete_all

        # re-add the user as an admin with quota rights
        role = custom_account_role 'quotas', :account => @a1
        @a1.role_overrides.create! :role => role, :permission => 'manage_storage_quotas', :enabled => true
        @a1.account_users.create!(user: @user, :role => role)

        @params = { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' }
      end

      it 'should allow the default storage quota to be set' do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, {:account => {:default_storage_quota_mb => 789}})

        expect(json).to include({
          'id' => @a1.id,
          'default_storage_quota_mb' => 789,
        })

        @a1.reload
        expect(@a1.default_storage_quota_mb).to eq 789
      end

      it 'should allow the default user quota to be set' do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, {:account => {:default_user_storage_quota_mb => 678}})

        expect(json).to include({
          'id' => @a1.id,
          'default_user_storage_quota_mb' => 678,
        })

        @a1.reload
        expect(@a1.default_user_storage_quota_mb).to eq 678
      end

      it 'should allow the default group quota to be set' do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, {:account => {:default_group_storage_quota_mb => 678}})

        expect(json).to include({
          'id' => @a1.id,
          'default_group_storage_quota_mb' => 678,
        })

        @a1.reload
        expect(@a1.default_group_storage_quota_mb).to eq 678
      end
    end

    context 'without :manage_storage_quotas' do
      before(:once) do
        # remove the user from being an Admin
        @a1.account_users.where(user_id: @user).delete_all

        # re-add the user as an admin without quota rights
        role = custom_account_role 'no-quotas', :account => @a1
        @a1.role_overrides.create! :role => role, :permission => 'manage_account_settings', :enabled => true
        @a1.role_overrides.create! :role => role, :permission => 'manage_storage_quotas', :enabled => false
        @a1.account_users.create!(user: @user, role: role)

        @params = { :controller => 'accounts', :action => 'update', :id => @a1.to_param, :format => 'json' }
      end

      it 'should not allow the default storage quota to be set' do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, {:account => {:default_storage_quota_mb => 789}}, {}, {:expected_status => 401})

        @a1.reload
        expect(@a1.default_storage_quota_mb).to eq 123
      end

      it 'should not allow the default user quota to be set' do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, {:account => {:default_user_storage_quota_mb => 678}}, {}, {:expected_status => 401})

        @a1.reload
        expect(@a1.default_user_storage_quota_mb).to eq 45
      end

      it 'should not allow the default group quota to be set' do
        json = api_call(:put, "/api/v1/accounts/#{@a1.id}", @params, {:account => {:default_group_storage_quota_mb => 678}}, {}, {:expected_status => 401})

        @a1.reload
        expect(@a1.default_group_storage_quota_mb).to eq 42
      end
    end
  end

  it "should find accounts by sis in only this root account" do
    Account.default.account_users.create!(user: @user)
    other_sub = account_model(:name => 'other_sub', :parent_account => Account.default, :root_account => Account.default, :sis_source_id => 'sis1')
    other_sub.account_users.create!(user: @user)

    # this is scoped to Account.default
    json = api_call(:get, "/api/v1/accounts/sis_account_id:sis1",
                    { :controller => 'accounts', :action => 'show', :id => "sis_account_id:sis1", :format => 'json' })
    expect(json['id']).to eq other_sub.id

    # we shouldn't find the account in the other root account by sis
    other_sub.update_attribute(:sis_source_id, 'sis2')
    raw_api_call(:get, "/api/v1/accounts/sis_account_id:sis1",
                    { :controller => 'accounts', :action => 'show', :id => "sis_account_id:sis1", :format => 'json' })
    assert_status(404)
  end

  context "courses_api" do
    it "should return courses for an account" do
      Time.use_zone(@user.time_zone) do
        @me = @user
        @c1 = course_model(:name => 'c1', :account => @a1, :root_account => @a1)
        @c1.enrollments.each(&:destroy_permanently!)
        @c2 = course_model(:name => 'c2', :account => @a2, :root_account => @a1, :sis_source_id => 'sis2')
        @c2.course_sections.create!
        @c2.course_sections.create!
        @user = @me
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json' })

        [@c1, @c2].each { |c| c.reload }
        expect(json.first['id']).to eq @c1.id
        expect(json.first['name']).to eq 'c1'
        expect(json.first['account_id']).to eq @c1.account_id
        expect(json.first['is_public']).to eq true

        expect(json.last['id']).to eq @c2.id
        expect(json.last['name']).to eq 'c2'
        expect(json.last['account_id']).to eq @c2.account_id

        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json' },
                          { :hide_enrollmentless_courses => '1' })
        expect(json.first['id']).to eq @c2.id
        expect(json.first['name']).to eq 'c2'
        expect(json.first['account_id']).to eq @c2.account_id

        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json' },
                          { :per_page => 1, :page => 2 })
        expect(json.first['id']).to eq @c2.id
        expect(json.first['name']).to eq 'c2'
        expect(json.first['account_id']).to eq @c2.account_id

      end
    end

    it "should honor the includes[]" do
      @c1 = course_model(:name => 'c1', :account => @a1, :root_account => @a1)
      @a1.account_users.create!(user: @user)
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?include[]=storage_quota_used_mb",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                        :format => 'json', :include => ['storage_quota_used_mb'] }, {})
      expect(json[0].has_key?("storage_quota_used_mb")).to be_truthy
    end

    it "should don't include fake students" do
      @c1 = course_model(:name => 'c1', :account => @a1, :root_account => @a1)
      @c1.student_view_student
      @a1.account_users.create!(user: @user)
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?include[]=total_students",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :include => ['total_students'] }, {})
      expect(json[0]["total_students"]).to eq 0
    end

    it "should include enrollment term information for each course" do
      @c1 = course_model(:name => 'c1', :account => @a1, :root_account => @a1)
      @a1.account_users.create!(user: @user)
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?include[]=term",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                        :format => 'json', :include => ['term'] })
      expect(json[0].has_key?('term')).to be_truthy
    end

    it "should return a teacher count if too many teachers are found" do
      @c1 = course_with_teacher(:account => @a1, :course_name => 'c1').course
      @c2 = course_with_teacher(:account => @a1, :course_name => 'c2').course
      @c2.enroll_teacher(user_factory)

      @a1.account_users.create!(user: @user)
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?include[]=teachers&teacher_limit=1",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :include => ['teachers'], :teacher_limit => "1" })
      c1_hash = json.detect{|h| h['id'] == @c1.id}
      expect(c1_hash['teachers']).to be_present
      c2_hash = json.detect{|h| h['id'] == @c2.id}
      expect(c2_hash.has_key?('teachers')).to eq false
      expect(c2_hash['teacher_count']).to eq 2
    end

    describe 'sort' do
      before :once do
        @me = @user
        @sub2 = @a1.sub_accounts.create!(name: 'b', sis_source_id: 'sub2', root_account: @a1)
        @sub1 = @a1.sub_accounts.create!(name: 'a', sis_source_id: 'sub1', root_account: @a1)

        @a1.courses.create!(name: 'in root')
        @sub1.courses.create!(name: 'in sub1')
        @sub2.courses.create!(name: 'in sub2')
      end

      it 'should sort by account name using subaccount for backwards compatibility' do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?sort=subaccount",
                        {controller: 'accounts', action: 'courses_api',
                         account_id: @a1.to_param, format: 'json', sort: 'subaccount'
                        })
        expect(json.first['name']).to eq('in sub1')
        expect(json.last['name']).to eq('in root')
      end

      it 'should sort by account name' do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?sort=account_name",
                        {controller: 'accounts', action: 'courses_api',
                         account_id: @a1.to_param, format: 'json', sort: 'account_name'
                        })
        expect(json.first['name']).to eq('in sub1')
        expect(json.last['name']).to eq('in root')
      end
    end

    describe "handles crosslisting properly" do
      before :once do
        @root_account = Account.create!
        @account1 = Account.create!({ :root_account => @root_account })
        @account2 = Account.create!({ :root_account => @root_account })
        @course1 = course_factory({ :account => @account1, :course_name => "course1" })
        @course2 = course_factory({ :account => @account2, :course_name => "course2" })
        @course2.course_sections.create!
        @course2.course_sections.first.crosslist_to_course(@course1)
      end

      it "don't include crosslisted course when querying account section was crosslisted from" do
        @account2.account_users.create!(user: @user)
        json = api_call(:get, "/api/v1/accounts/#{@account2.id}/courses",
          { :controller => 'accounts', :action => 'courses_api',
            :account_id => @account2.to_param, :format => 'json',
          })
        expect(json.length).to eq 1
        expect(json.first["name"]).to eq "course2"
      end

      it "don't include crosslisted course when querying account section was crosslisted to" do
        @account1.account_users.create!(user: @user)
        json = api_call(:get, "/api/v1/accounts/#{@account1.id}/courses",
          { :controller => 'accounts', :action => 'courses_api',
            :account_id => @account1.to_param, :format => 'json' })
        expect(json.length).to eq 1
        expect(json.first["name"]).to eq "course1"
      end

      it "include crosslisted course when querying account section was crosslisted from if requested" do
        @account2.account_users.create!(user: @user)
        json = api_call(:get, "/api/v1/accounts/#{@account2.id}/courses?include_crosslisted_courses=true",
          { :controller => 'accounts', :action => 'courses_api',
            :include_crosslisted_courses => true,
            :account_id => @account2.to_param, :format => 'json' })
        expect(json.length).to eq 2
        names = json.pluck("name")
        expect(names.include?("course1")).to be_truthy
        expect(names.include?("course2")).to be_truthy
      end

      it "don't include crosslisted course when querying account section was crosslisted to even if requested" do
        @account1.account_users.create!(user: @user)
        json = api_call(:get, "/api/v1/accounts/#{@account1.id}/courses",
          { :controller => 'accounts', :action => 'courses_api',
            :account_id => @account1.to_param, :format => 'json' })
        expect(json.length).to eq 1
        expect(json.first["name"]).to eq "course1"
      end
    end

    describe "courses filtered by state[]" do
      before :once do
        @me = @user
        [:c1, :c2, :c3, :c4].each do |course|
          instance_variable_set("@#{course}".to_sym, course_model(:name => course.to_s, :account => @a1))
        end
        @c2.destroy
        Course.where(id: @c1).update_all(workflow_state: 'claimed')
        Course.where(id: @c3).update_all(workflow_state: 'available')
        Course.where(id: @c4).update_all(workflow_state: 'completed')
        @user = @me
      end

      it "should return courses filtered by state[]='deleted'" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?state[]=deleted",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json', :state => %w[deleted] })
        expect(json.length).to eql 1
        expect(json.first['name']).to eql 'c2'
      end

      it "should return courses filtered by state[]=nil" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json' })
        expect(json.length).to eql 3
        expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@c1.id, @c3.id, @c4.id].sort
      end

      it "should return courses filtered by state[]='all'" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?state[]=all",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :state => %w[all] })
        expect(json.length).to eql 4
        expect(json.collect{ |c| c['id'].to_i }.sort).to eq [@c1.id, @c2.id, @c3.id, @c4.id].sort
      end
    end

    it "should return courses filtered by enrollment_term" do
      term = @a1.enrollment_terms.create!(:name => 'term 2')
      @a1.courses.create!(:name => 'c1')
      @a1.courses.create!(:name => 'c2', :enrollment_term => term)

      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?enrollment_term_id=#{term.id}",
                      { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                        :format => 'json', :enrollment_term_id => term.to_param })
      expect(json.length).to eql 1
      expect(json.first['name']).to eql 'c2'
    end

    describe "?with_enrollments" do
      before :once do
        @me = @user
        c1 = course_model(:account => @a1, :name => 'c1')    # has a teacher
        c2 = Course.create!(:account => @a1, :name => 'c2')  # has no enrollments
        @user = @me
      end

      it "should not apply if not specified" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :format => 'json', :account_id => @a1.to_param })
        expect(json.collect{|row|row['name']}).to eql ['c1', 'c2']
      end

      it "should filter on courses with enrollments" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?with_enrollments=1",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :with_enrollments => "1" })
        expect(json.collect{|row|row['name']}).to eql ['c1']
      end

      it "should filter on courses without enrollments" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?with_enrollments=0",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :with_enrollments => "0" })
        expect(json.collect{|row|row['name']}).to eql ['c2']
      end
    end

    describe "?published" do
      before :once do
        @me = @user
        [:c1, :c2].each do |course|
          instance_variable_set("@#{course}".to_sym, course_model(:name => course.to_s, :account => @a1))
        end
        @c1.offer!
        @user = @me
      end

      it "should not apply if not specified" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json' })
        expect(json.collect{|row|row['name']}).to eql ['c1', 'c2']
      end

      it "should filter courses on published state" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?published=true",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json', :published => "true" })
        expect(json.collect{|row|row['name']}).to eql ['c1']
      end

      it "should filter courses on non-published state" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?published=false",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json',
                          :published => "false" })
        expect(json.collect{|row|row['name']}).to eql ['c2']
      end
    end

    describe "?completed" do
      before :once do
        @me = @user
        [:c1, :c2, :c3, :c4].each do |course|
          instance_variable_set("@#{course}".to_sym, course_model(:name => course.to_s, :account => @a1, :conclude_at => 2.days.from_now))
        end

        @c2.start_at = 2.weeks.ago
        @c2.conclude_at = 1.week.ago
        @c2.save!

        term = @c3.root_account.enrollment_terms.create! :end_at => 2.days.ago
        @c3.enrollment_term = term
        @c3.save!

        @c4.complete!
        @user = @me
      end

      it "should not apply if not specified" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                           :account_id => @a1.to_param, :format => 'json' })
        expect(json.collect{|row|row['name']}).to eql ['c1', 'c2', 'c3', 'c4']
      end

      it "should filter courses on completed state" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?completed=yes",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json', :completed => "yes" })
        expect(json.collect{|row|row['name']}).to eql ['c2', 'c3', 'c4']
      end

      it "should filter courses on non-completed state" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?completed=no",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :completed => "no" })
        expect(json.collect{|row|row['name']}).to eql ['c1']
      end
    end

    describe "?by_teachers" do
      before :once do
        @me = @user
        course_with_teacher(:account => @a1, :course_name => 'c1a', :user => user_with_pseudonym(:account => @a1))
        @pseudonym.sis_user_id = 'a_sis_id'
        @pseudonym.save!
        @t1 = @teacher
        course_with_teacher(:account => @a1, :user => @t1, :course_name => 'c1b')
        course_with_teacher(:account => @a1, :course_name => 'c2')
        @teacher
        course_with_teacher(:account => @a1, :course_name => 'c3')
        @t3 = @teacher
        @user = @me
      end

      it "should not apply when not specified" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json' },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json.collect{|row|row['name']}).to eql ['c1a', 'c1b', 'c2', 'c3']
      end

      it "should filter courses by teacher enrollments" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_teachers[]=sis_user_id:a_sis_id&by_teachers[]=#{@t3.id}",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :by_teachers => ['sis_user_id:a_sis_id', "#{@t3.id}"] },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json.collect{|row|row['name']}).to eql ['c1a', 'c1b', 'c3']
      end

      it "should not break with an empty result set" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_teachers[]=bad_id",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :by_teachers => ['bad_id'] },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json).to eql []
      end
    end

    describe "?by_subaccounts" do
      before :once do
        @me = @user
        @sub1 = account_model(:name => 'sub1', :parent_account => @a1, :root_account => @a1, :sis_source_id => 'sub1')
        @sub1a = account_model(:name => 'sub1a', :parent_account => @sub1, :root_account => @a1, :sis_source_id => 'sub1a')
        @sub1b = account_model(:name => 'sub1b', :parent_account => @sub1, :root_account => @a1, :sis_source_id => 'sub1b')
        @sub2 = account_model(:name => 'sub2', :parent_account => @a1, :root_account => @a1, :sis_source_id => 'sub2')

        course_model(:name => 'in sub1', :account => @sub1)
        course_model(:name => 'in sub1a', :account => @sub1a)
        course_model(:name => 'in sub1b', :account => @sub1b)
        course_model(:name => 'in sub2', :account => @sub2)
        course_model(:name => 'in top level', :account => @a1)
        @user = @me
      end

      it "should not apply when not specified" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json' },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json.collect{|row|row['name']}).to eql ['in sub1', 'in sub1a', 'in sub1b', 'in sub2', 'in top level']
      end

      it "should include descendants of the specified subaccount" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=sis_account_id:sub1",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :by_subaccounts => ['sis_account_id:sub1'] },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json.collect{|row|row['name']}).to eql ['in sub1', 'in sub1a', 'in sub1b']
      end

      it "should work with multiple subaccounts specified" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=sis_account_id:sub1a&by_subaccounts[]=sis_account_id:sub1b",
                        { :controller => 'accounts', :action => 'courses_api',
                          :account_id => @a1.to_param, :format => 'json',
                          :by_subaccounts => ['sis_account_id:sub1a', 'sis_account_id:sub1b'] },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json.collect{|row|row['name']}).to eql ['in sub1a', 'in sub1b']
      end

      it "should work with a numeric ID" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=#{@sub2.id}",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :by_subaccounts => ["#{@sub2.id}"] },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json.collect{|row|row['name']}).to eql ['in sub2']
      end

      it "should not break with an empty result set" do
        json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?by_subaccounts[]=bad_id",
                        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
                          :format => 'json', :by_subaccounts => ['bad_id'] },
                        {}, {}, { :domain_root_account => @a1 })
        expect(json).to eql []
      end
    end

    it "should limit the maximum per-page returned" do
      create_courses(15, account: @a1, account_associations: true)
      expect(api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?per_page=12", :controller => "accounts",
        :action => "courses_api", :account_id => @a1.to_param, :format => 'json',
        :per_page => '12').size).to eq 12
      Setting.set('api_max_per_page', '5')
      expect(api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?per_page=12", :controller => "accounts", :action => "courses_api",
        :account_id => @a1.to_param, :format => 'json', :per_page => '12').size).to eq 5
    end

    it "should return courses filtered search term" do
      data = (5..12).map{ |i| {name: "name#{i}", course_code: "code#{i}" }}
      @courses = create_courses(data, account: @a1, account_associations: true, return_type: :record)
      @course = @courses.last

      search_term = "name"
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :search_term => search_term })
      expect(json.length).to eql @courses.length

      search_term = "code"
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
           :format => 'json', :search_term => search_term })
      expect(json.length).to eql @courses.length

      search_term = "name1"
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :search_term => search_term })
      expect(json.length).to eql 3

      search_term = Shard.global_id_for(@course)
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :search_term => search_term })
      expect(json.length).to eql 1
      expect(json.first['name']).to eq @course.name

      # Should return empty result set
      search_term = "0000000000"
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :search_term => search_term })
      expect(json.length).to eql 0

      # To short should return 400
      search_term = "a"
      response = raw_api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :search_term => search_term })
      expect(response).to eq 400

      # search on something that's a course name but looks like an id also
      one_more = create_courses(
        [{name: @courses[0].id.to_s, course_code: "name_looks_like_id"}],
        account: @a1, account_associations: true, return_type: :record
      )
      @courses.push(*one_more)
      search_term = @courses.last.name
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/courses?search_term=#{search_term}",
        { :controller => 'accounts', :action => 'courses_api', :account_id => @a1.to_param,
          :format => 'json', :search_term => search_term })
      expect(json.length).to be 2
      expect(json.map{ |c| [c['id'], c['name']] }).to match_array([[@courses.first.id, @courses.first.name], [@courses.last.id, @courses.last.name]])
    end

    context "blueprint courses" do
      before :once do
        @a = Account.create!
        @mc = course_model :name => 'MasterCourse', :account => @a
        @cc = course_model :name => 'ChildCourse', :account => @a
        @oc = course_model :name => 'OtherCourse', :account => @a
        template = MasterCourses::MasterTemplate.set_as_master_course(@mc)
        template.add_child_course!(@cc).destroy # ensure deleted subscriptions don't affect the result
        template.add_child_course!(@cc)
        account_admin_user(:account => @a)
      end

      it 'filters in blueprint courses' do
        json = api_call(:get, "/api/v1/accounts/#{@a.id}/courses?blueprint=true",
          { :controller => 'accounts', :action => 'courses_api', :account_id => @a.to_param,
            :format => 'json', :blueprint => true })
        expect(json.map{ |c| c['name'] }).to match_array %w(MasterCourse)
      end

      it 'filters out blueprint courses' do
        json = api_call(:get, "/api/v1/accounts/#{@a.id}/courses?blueprint=false",
          { :controller => 'accounts', :action => 'courses_api', :account_id => @a.to_param,
            :format => 'json', :blueprint => false })
        expect(json.map{ |c| c['name'] }).to match_array %w(ChildCourse OtherCourse)
      end

      it 'filters in associated courses' do
        json = api_call(:get, "/api/v1/accounts/#{@a.id}/courses?blueprint_associated=true",
          { :controller => 'accounts', :action => 'courses_api', :account_id => @a.to_param,
            :format => 'json', :blueprint_associated => true })
        expect(json.map{ |c| c['name'] }).to match_array %w(ChildCourse)
      end

      it 'filters out associated courses' do
        json = api_call(:get, "/api/v1/accounts/#{@a.id}/courses?blueprint_associated=false",
          { :controller => 'accounts', :action => 'courses_api', :account_id => @a.to_param,
            :format => 'json', :blueprint_associated => false })
        expect(json.map{ |c| c['name'] }).to match_array %w(MasterCourse OtherCourse)
      end
    end
  end

  context "permissions" do
    it "returns permissions" do
      json = api_call(:get, "/api/v1/accounts/#{@a1.id}/permissions?permissions[]=become_user&permissions[]=manage_blarghs",
                      :controller => 'accounts', :action => 'permissions', :account_id => @a1.to_param,
                      :format => 'json', :permissions => %w(become_user manage_blarghs))
      expect(json).to eq({"become_user"=>true, "manage_blarghs"=>false})
    end

    it "requires :read permission on the account" do
      api_call(:get, "/api/v1/accounts/#{@a3.id}/permissions?permissions[]=become_user",
               { :controller => 'accounts', :action => 'permissions', :account_id => @a3.to_param, :format => 'json',
                 :permissions => %w(become_user) }, {}, {}, { :expected_status => 401 })
    end
  end

  context "account api extension" do
    module MockPlugin
      def self.extend_account_json(hash, account, user, session, includes)
        hash[:extra_thing] = "something"
      end
    end

    module BadMockPlugin
      def self.not_the_right_method
      end
    end

    include Api::V1::Account

    it "should allow a plugin to extend the account_json method" do
      expect(Api::V1::Account.register_extension(BadMockPlugin)).to be_falsey
      expect(Api::V1::Account.register_extension(MockPlugin)).to be_truthy

      begin
        expect(account_json(@a1, @me, @session, [])[:extra_thing]).to eq "something"
      ensure
        Api::V1::Account.deregister_extension(MockPlugin)
      end
    end
  end
end
