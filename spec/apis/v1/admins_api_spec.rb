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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')
require_relative '../../sharding_spec_helper'

describe "Admins API", type: :request do
  before :once do
    @admin = account_admin_user
    user_with_pseudonym(:user => @admin)
  end

  describe "create" do
    before :once do
      @new_user = user_factory(:name => 'new guy')
      @admin.account.root_account.pseudonyms.create!(unique_id: 'user', user: @new_user)
      @user = @admin
    end

    it "should flag the user as an admin for the account" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
        { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        { :user_id => @new_user.id })
      @new_user.reload
      expect(@new_user.account_users.size).to eq 1
      admin = @new_user.account_users.first
      expect(admin.account).to eq @admin.account
    end

    it "should default the role of the admin association to AccountAdmin" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
        { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        { :user_id => @new_user.id })
      @new_user.reload
      admin = @new_user.account_users.first
      expect(admin.role).to eq admin_role
    end

    it "should respect the provided role, if any" do
      role = custom_account_role('CustomAccountUser', :account => @admin.account)
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
        { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        { :user_id => @new_user.id, :role_id => role.id })
      @new_user.reload
      admin = @new_user.account_users.first
      expect(admin.role).to eq role
    end

    it "should be able to find a role by name (though deprecated)" do
      role = custom_account_role('CustomAccountUser', :account => @admin.account)
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
                      { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
                      { :user_id => @new_user.id, :role => "CustomAccountUser" })
      @new_user.reload
      admin = @new_user.account_users.first
      expect(admin.role).to eq role
    end

    it "should return json of the new admin association" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
                      {:controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s},
                      {:user_id => @new_user.id})
      @new_user.reload
      admin = @new_user.account_users.first
      expect(json).to eq({
                           "id" => admin.id,
                           "role_id" => admin.role_id,
                           "role" => admin.role.name,
                           "user" => {
                             "id" => @new_user.id,
                             "name" => @new_user.name,
                             "short_name" => @new_user.short_name,
                             "sis_user_id"=>nil,
                             "integration_id"=>nil,
                             "sis_import_id"=>nil,
                             "sortable_name" => @new_user.sortable_name,
                             "login_id" => "user",
                           },
                           "workflow_state" => 'active'
                         })
    end

    it "should not send a notification email if passed a 0 'send_confirmation' value" do
      expect_any_instance_of(AccountUser).to receive(:account_user_notification!).never
      expect_any_instance_of(AccountUser).to receive(:account_user_registration!).never

      api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
               {:controller => 'admins', :action => 'create', :format => 'json',
                :account_id => @admin.account.to_param },
               {:user_id => @new_user.to_param, :send_confirmation => '0'})

      # Both of the expectations above should pass.
    end

    it "should not send a notification email if passed a false 'send_confirmation' value" do
      expect_any_instance_of(AccountUser).to receive(:account_user_notification!).never
      expect_any_instance_of(AccountUser).to receive(:account_user_registration!).never

      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
                      {:controller => 'admins', :action => 'create', :format => 'json',
                       :account_id => @admin.account.to_param },
                      {:user_id => @new_user.to_param, :send_confirmation => 'false'})

      # Both of the expectations above should pass.
    end

    it "should send a notification email if 'send_confirmation' isn't set" do
      expect_any_instance_of(AccountUser).to receive(:account_user_registration!).once

      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
                      {:controller => 'admins', :action => 'create', :format => 'json',
                       :account_id => @admin.account.to_param },
                      {:user_id => @new_user.to_param})

      # Expectation above should pass.
    end

    it "should not allow you to add a random user" do
      @new_user.pseudonym.destroy
      raw_api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
                   { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
                   { :user_id => @new_user.id })
      expect(response.code).to eq '404'
    end
  end

  describe "destroy" do
    before :once do
      @account = Account.default
      @new_user = user_with_managed_pseudonym(:name => 'bad admin', :account => @account, :sis_user_id => 'badmin')
      @user = @admin
      @base_path = "/api/v1/accounts/#{@account.id}/admins/"
      @path = @base_path + "#{@new_user.id}"
      @path_opts = { :controller => "admins", :action => "destroy", :format => "json",
                     :account_id => @account.to_param, :user_id => @new_user.to_param }
    end

    context "unauthorized caller" do
      before do
        @au = @account.account_users.create! :user => @new_user
        @user = user_factory :account => @account
      end

      it "should 401" do
        api_call(:delete, @path, @path_opts, {}, {}, :expected_status => 401)
      end
    end

    context "with AccountAdmin membership" do
      before :once do
        @au = @account.account_users.create! :user => @new_user
      end

      it "should remove AccountAdmin membership" do
        json = api_call(:delete, @path, @path_opts)
        expect(json['user']['id']).to eq @new_user.id
        expect(json['id']).to eq @au.id
        expect(json['role']).to eq 'AccountAdmin'
        expect(json['workflow_state']).to eq 'deleted'
        expect(@au.reload.workflow_state).to eq 'deleted'
      end

      it "should remove AccountAdmin membership explicitly" do
        api_call(:delete, @path + "?role=AccountAdmin", @path_opts.merge(:role => "AccountAdmin"))
        expect(@account.account_users.active.where(user_id: @new_user)).not_to be_exists
      end

      it "should 404 if the user doesn't exist" do
        temp_user = User.create!
        bad_id = temp_user.to_param
        temp_user.destroy_permanently!
        api_call(:delete, @base_path + bad_id, @path_opts.merge(:user_id => bad_id),
                 {}, {}, :expected_status => 404)
      end

      it "should work by sis user id" do
        api_call(:delete, @base_path + "sis_user_id:badmin",
                 @path_opts.merge(:user_id => "sis_user_id:badmin"))
        expect(@account.account_users.active.where(user_id: @new_user)).not_to be_exists
      end
    end

    context "with custom membership" do
      before :once do
        @role = custom_account_role('CustomAdmin', account: @account)
        @au = @account.account_users.create!(user: @new_user, role: @role)
      end

      it "should remove a custom membership from a user" do
        api_call(:delete, @path + "?role_id=#{@role.id}", @path_opts.merge(role_id: @role.id))
        expect(@account.account_users.active.find_by_user_id_and_role_id(@new_user.id, @role.id)).to be_nil
      end

      it "should still work using the deprecated role param" do
        api_call(:delete, @path + "?role=CustomAdmin", @path_opts.merge(role: "CustomAdmin"))
        expect(@account.account_users.active.where(user_id: @new_user, role_id: @role.id).exists?).to eq false
      end

      it "should 404 if the membership type doesn't exist" do
        api_call(:delete, @path + "?role=Blah", @path_opts.merge(role: "Blah"), {}, {}, expected_status: 404)
        expect(@account.account_users.where(user_id: @new_user, role_id: @role.id).exists?).to eq true
      end

      it "should 404 if the membership type isn't specified" do
        api_call(:delete, @path, @path_opts, {}, {}, expected_status: 404)
        expect(@account.account_users.where(user_id: @new_user, role_id: @role.id).exists?).to eq true
      end
    end

    context "with multiple memberships" do
      before :once do
        @role = custom_account_role('CustomAdmin', :account => @account)
        @au1 = @account.account_users.create! :user => @new_user
        @au2 = @account.account_users.create! :user => @new_user, :role => @role
      end

      it "should leave the AccountAdmin membership alone when deleting the custom membership" do
        api_call(:delete, @path + "?role_id=#{@role.id}", @path_opts.merge(:role_id => @role.id))
        expect(@account.account_users.active.where(:user_id => @new_user.id).map(&:role_id)).to eq [admin_role.id]
      end

      it "should leave the custom membership alone when deleting the AccountAdmin membership implicitly" do
        api_call(:delete, @path, @path_opts)
        expect(@account.account_users.active.where(:user_id => @new_user.id).map(&:role_id)).to eq [@role.id]
      end

      it "should leave the custom membership alone when deleting the AccountAdmin membership explicitly" do
        api_call(:delete, @path + "?role_id=#{admin_role.id}", @path_opts.merge(:role_id => admin_role.id))
        expect(@account.account_users.active.where(:user_id => @new_user.id).map(&:role_id)).to eq [@role.id]
      end
    end
  end

  describe "index" do
    before :once do
      @account = Account.default
      @path = "/api/v1/accounts/#{@account.id}/admins"
      @path_opts = { :controller => "admins", :action => "index", :format => "json", :account_id => @account.to_param }
    end

    context "unauthorized caller" do
      before do
        @user = user_factory :account => @account
      end

      it "should 401" do
        api_call(:get, @path, @path_opts, {}, {}, :expected_status => 401)
      end
    end

    context "with account users" do
      before :once do
        @roles = {}
        2.times do |x|
          u = user_factory(:name => "User #{x}", :account => @account)
          @roles[x] = custom_account_role("MT #{x}", :account => @account)
          @account.account_users.create!(:user => u, :role => @roles[x])
        end
        @another_admin = @user
        @user = @admin
      end

      it "should return the correct format" do
        json = api_call(:get, @path, @path_opts)
        expect(json).to be_include({"id" => @admin.account_users.first.id,
                                    "role" => "AccountAdmin",
                                    "role_id" => admin_role.id,
                                    "user" =>
                                      {"id" => @admin.id,
                                       "name" => @admin.name,
                                       "sortable_name" => @admin.sortable_name,
                                       "short_name" => @admin.short_name,
                                       "sis_user_id"=>nil,
                                       "integration_id"=>nil,
                                       "sis_import_id"=>nil,
                                       "login_id" => @admin.pseudonym.unique_id},
                                    "workflow_state" => 'active'})
      end

      it "should scope the results to the user_id if given" do
        json = api_call(:get, @path, @path_opts.merge(user_id: @admin.id))
        expect(json).to eq [{"id" => @admin.account_users.first.id,
                             "role" => "AccountAdmin",
                             "role_id" => admin_role.id,
                             "user" =>
                               {"id" => @admin.id,
                                "name" => @admin.name,
                                "sortable_name" => @admin.sortable_name,
                                "short_name" => @admin.short_name,
                                "sis_user_id"=>nil,
                                "integration_id"=>nil,
                                "sis_import_id"=>nil,
                                "login_id" => @admin.pseudonym.unique_id},
                             "workflow_state" => 'active'}]
      end

      it "should scope the results to the array of user_ids if given" do
        json = api_call(:get, @path, @path_opts.merge(user_id: [@admin.id, @another_admin.id]))
        expect(json).to eq [{"id" => @admin.account_users.first.id,
                             "role" => "AccountAdmin",
                             "role_id" => admin_role.id,
                             "user" =>
                               {"id" => @admin.id,
                                "name" => @admin.name,
                                "sortable_name" => @admin.sortable_name,
                                "short_name" => @admin.short_name,
                                "sis_user_id"=>nil,
                                "integration_id"=>nil,
                                "sis_import_id"=>nil,
                                "login_id" => @admin.pseudonym.unique_id},
                             "workflow_state" => 'active'},
                            {"id" => @another_admin.account_users.first.id,
                             "role" => "MT 1",
                             "role_id" => @roles[1].id,
                             "user" =>
                               {"id" => @another_admin.id,
                                "name" => @another_admin.name,
                                "sortable_name" => @another_admin.sortable_name,
                                "sis_user_id"=>nil,
                                "integration_id"=>nil,
                                "sis_import_id"=>nil,
                                "short_name" => @another_admin.short_name},
                             "workflow_state" => 'active'}]
      end

      context 'sharding' do
        specs_require_sharding

        it "should work with cross-shard users" do
          @shard1.activate { @other_admin = user_factory }
          au = Account.default.account_users.create!(:user => @other_admin)

          @user = @admin
          json = api_call(:get, @path, @path_opts.merge(user_id: [@other_admin.id]))

          expect(json.first["id"]).to eq au.id
        end
      end

      it "should paginate" do
        json = api_call(:get, @path + "?per_page=2", @path_opts.merge(:per_page => '2'))
        expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=2.*>; rel="last"})
        expect(json.map{ |au| { :user => au['user']['name'], :role => au['role'], :role_id => au['role_id'] } }).to eq [
            { :user => @admin.name, :role => 'AccountAdmin', :role_id => admin_role.id },
            { :user => "User 0", :role => "MT 0", :role_id => @roles[0].id },
        ]
        json = api_call(:get, @path + "?per_page=2&page=2", @path_opts.merge(:per_page => '2', :page => '2'))
        expect(response.headers['Link']).to match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=2.*>; rel="last"})
        expect(json.map{ |au| { :user => au['user']['name'], :role => au['role'], :role_id => au['role_id'] } }).to eq [
            { :user => "User 1", :role => "MT 1", :role_id => @roles[1].id }
        ]
      end
    end
  end
end
