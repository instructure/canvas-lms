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

describe "Admins API", type: :request do
  before :once do
    @admin = account_admin_user
    user_with_pseudonym(:user => @admin)
  end

  describe "create" do
    before :once do
      @new_user = user(:name => 'new guy')
      @admin.account.root_account.pseudonyms.create!(unique_id: 'user', user: @new_user)
      @user = @admin
    end

    it "should flag the user as an admin for the account" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
        { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        { :user_id => @new_user.id })
      @new_user.reload
      @new_user.account_users.size.should == 1
      admin = @new_user.account_users.first
      admin.account.should == @admin.account
    end

    it "should default the role of the admin association to AccountAdmin" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
        { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        { :user_id => @new_user.id })
      @new_user.reload
      admin = @new_user.account_users.first
      admin.membership_type.should == 'AccountAdmin'
    end

    it "should respect the provided role, if any" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
        { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        { :user_id => @new_user.id, :role => "CustomAccountUser" })
      @new_user.reload
      admin = @new_user.account_users.first
      admin.membership_type.should == 'CustomAccountUser'
    end

    it "should return json of the new admin association" do
      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
        { :controller => 'admins', :action => 'create', :format => 'json', :account_id => @admin.account.id.to_s },
        { :user_id => @new_user.id })
      @new_user.reload
      admin = @new_user.account_users.first
      json.should == {
        "id" => admin.id,
        "role" => admin.membership_type,
        "user" => {
          "id" => @new_user.id,
          "name" => @new_user.name,
          "short_name" => @new_user.short_name,
          "sortable_name" => @new_user.sortable_name,
          "login_id" => "user",
        }
      }
    end

    it "should not send a notification email if passed a valid 'send_confirmation' value" do
      AccountUser.any_instance.expects(:account_user_notification!).never
      AccountUser.any_instance.expects(:account_user_registration!).never

      json = api_call(:post, "/api/v1/accounts/#{@admin.account.id}/admins",
                      {:controller => 'admins', :action => 'create', :format => 'json',
                       :account_id => @admin.account.to_param },
                      {:user_id => @new_user.to_param, :send_confirmation => '0'})

      # Both of the expectations above should pass.
    end

    it "should send a notification email if 'send_confirmation' isn't set" do
      AccountUser.any_instance.expects(:account_user_registration!).once

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
      response.code.should == '404'
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
        @user = user :account => @account
      end

      it "should 401" do
        api_call(:delete, @path, @path_opts, {}, {}, :expected_status => 401)
      end
    end

    context "with AccountAdmin membership" do
      before :once do
        @au = @account.account_users.create! :user => @new_user
        @account.account_users.find_by_user_id(@new_user.id).should_not be_nil
      end

      it "should remove AccountAdmin membership implicitly" do
        json = api_call(:delete, @path, @path_opts)
        json['user']['id'].should == @new_user.id
        json['id'].should == @au.id
        json['role'].should == 'AccountAdmin'
        json['status'].should == 'deleted'
        @account.account_users.find_by_user_id(@new_user.id).should be_nil
      end

      it "should remove AccountAdmin membership explicitly" do
        api_call(:delete, @path + "?role=AccountAdmin", @path_opts.merge(:role => "AccountAdmin"))
        @account.account_users.find_by_user_id(@new_user.id).should be_nil
      end

      it "should 404 if the user doesn't exist" do
        temp_user = User.create!
        bad_id = temp_user.to_param
        temp_user.destroy!
        api_call(:delete, @base_path + bad_id, @path_opts.merge(:user_id => bad_id),
                 {}, {}, :expected_status => 404)
      end

      it "should work by sis user id" do
        api_call(:delete, @base_path + "sis_user_id:badmin",
                 @path_opts.merge(:user_id => "sis_user_id:badmin"))
        @account.account_users.find_by_user_id(@new_user.id).should be_nil
      end
    end

    context "with custom membership" do
      before :once do
        @au = @account.account_users.create! :user => @new_user, :membership_type => 'CustomAdmin'
      end

      it "should remove a custom membership from a user" do
        api_call(:delete, @path + "?role=CustomAdmin", @path_opts.merge(:role => "CustomAdmin"))
        @account.account_users.find_by_user_id_and_membership_type(@new_user.id, 'CustomAdmin').should be_nil
      end

      it "should 404 if the membership type doesn't exist" do
        api_call(:delete, @path + "?role=Blah", @path_opts.merge(:role => "Blah"), {}, {}, :expected_status => 404)
        @account.account_users.find_by_user_id_and_membership_type(@new_user.id, 'CustomAdmin').should_not be_nil
      end

      it "should 404 if the membership type isn't specified" do
        api_call(:delete, @path, @path_opts, {}, {}, :expected_status => 404)
        @account.account_users.find_by_user_id_and_membership_type(@new_user.id, 'CustomAdmin').should_not be_nil
      end
    end

    context "with multiple memberships" do
      before :once do
        @au1 = @account.account_users.create! :user => @new_user
        @au2 = @account.account_users.create! :user => @new_user, :membership_type => 'CustomAdmin'
      end

      it "should leave the AccountAdmin membership alone when deleting the custom membership" do
        api_call(:delete, @path + "?role=CustomAdmin", @path_opts.merge(:role => "CustomAdmin"))
        @account.account_users.find_all_by_user_id(@new_user.id).map(&:membership_type).should == ["AccountAdmin"]
      end

      it "should leave the custom membership alone when deleting the AccountAdmin membership implicitly" do
        api_call(:delete, @path, @path_opts)
        @account.account_users.find_all_by_user_id(@new_user.id).map(&:membership_type).should == ["CustomAdmin"]
      end

      it "should leave the custom membership alone when deleting the AccountAdmin membership explicitly" do
        api_call(:delete, @path + "?role=AccountAdmin", @path_opts.merge(:role => "AccountAdmin"))
        @account.account_users.find_all_by_user_id(@new_user.id).map(&:membership_type).should == ["CustomAdmin"]
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
        @user = user :account => @account
      end

      it "should 401" do
        api_call(:get, @path, @path_opts, {}, {}, :expected_status => 401)
      end
    end

    context "with account users" do
      before :once do
        2.times do |x|
          u = user(:name => "User #{x}", :account => @account)
          @account.account_users.create!(:user => u, :membership_type => "MT #{x}")
        end
        @another_admin = @user
        @user = @admin
      end

      it "should return the correct format" do
        json = api_call(:get, @path, @path_opts)
        json.should be_include({"id"=>@admin.account_users.first.id,
                                "role"=>"AccountAdmin",
                                "user"=>
                                    {"id"=>@admin.id,
                                     "name"=>@admin.name,
                                     "sortable_name"=>@admin.sortable_name,
                                     "short_name"=>@admin.short_name,
                                     "login_id"=>@admin.pseudonym.unique_id}})
      end

      it "should scope the results to the user_id if given" do
        json = api_call(:get, @path, @path_opts.merge(user_id: @admin.id))
        json.should ==[{"id"=>@admin.account_users.first.id,
                        "role"=>"AccountAdmin",
                        "user"=>
                            {"id"=>@admin.id,
                             "name"=>@admin.name,
                             "sortable_name"=>@admin.sortable_name,
                             "short_name"=>@admin.short_name,
                             "login_id"=>@admin.pseudonym.unique_id}}]
      end

      it "should scope the results to the array of user_ids if given" do
        json = api_call(:get, @path, @path_opts.merge(user_id: [@admin.id, @another_admin.id]))
        json.should ==[{"id"=>@admin.account_users.first.id,
                        "role"=>"AccountAdmin",
                        "user"=>
                            {"id"=>@admin.id,
                             "name"=>@admin.name,
                             "sortable_name"=>@admin.sortable_name,
                             "short_name"=>@admin.short_name,
                             "login_id"=>@admin.pseudonym.unique_id}},
                       {"id"=>@another_admin.account_users.first.id,
                        "role"=>"MT 1",
                        "user"=>
                            {"id"=>@another_admin.id,
                             "name"=>@another_admin.name,
                             "sortable_name"=>@another_admin.sortable_name,
                             "short_name"=>@another_admin.short_name}}]
      end

      it "should paginate" do
        json = api_call(:get, @path + "?per_page=2", @path_opts.merge(:per_page => '2'))
        response.headers['Link'].should match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=2.*>; rel="next",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=2.*>; rel="last"})
        json.map{ |au| { :user => au['user']['name'], :role => au['role'] } }.should == [
            { :user => @admin.name, :role => 'AccountAdmin' },
            { :user => "User 0", :role => "MT 0" },
        ]
        json = api_call(:get, @path + "?per_page=2&page=2", @path_opts.merge(:per_page => '2', :page => '2'))
        response.headers['Link'].should match(%r{<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=1.*>; rel="prev",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=1.*>; rel="first",<http://www.example.com/api/v1/accounts/#{@account.id}/admins\?.*page=2.*>; rel="last"})
        json.map{ |au| { :user => au['user']['name'], :role => au['role'] } }.should == [
            { :user => "User 1", :role => "MT 1" }
        ]
      end
    end
  end
end
