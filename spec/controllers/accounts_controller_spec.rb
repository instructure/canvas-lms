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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountsController do
  def account_with_admin_logged_in(opts = {})
    account_with_admin(opts)
    user_session(@admin)
  end

  def account_with_admin(opts = {})
    @account = opts[:account] || Account.default
    account_admin_user(account: @account)
  end

  def cross_listed_course
    account_with_admin_logged_in
    @account1 = Account.create!
    @account1.account_users.create!(user: @user)
    @course1 = @course
    @course1.account = @account1
    @course1.save!
    @account2 = Account.create!
    @course2 = course
    @course2.account = @account2
    @course2.save!
    @course2.course_sections.first.crosslist_to_course(@course1)
  end

  context "confirm_delete_user" do
    before(:once) { account_with_admin }
    before(:each) { user_session(@admin) }

    it "should confirm deletion of canvas-authenticated users" do
      user_with_pseudonym :account => @account
      get 'confirm_delete_user', :account_id => @account.id, :user_id => @user.id
      expect(response).to be_success
    end

    it "should not confirm deletion of non-existent users" do
      get 'confirm_delete_user', :account_id => @account.id, :user_id => (User.all.map(&:id).max + 1)
      expect(response).to redirect_to(account_url(@account))
      expect(flash[:error]).to match /No user found with that id/
    end

    it "should confirm deletion of managed password users" do
      user_with_managed_pseudonym :account => @account
      get 'confirm_delete_user', :account_id => @account.id, :user_id => @user.id
      expect(response).to be_success
    end
  end

  context "remove_user" do
    before(:once) { account_with_admin }
    before(:each) { user_session(@admin) }

    it "should delete canvas-authenticated users" do
      user_with_pseudonym :account => @account
      expect(@user.workflow_state).to eq "pre_registered"
      post 'remove_user', :account_id => @account.id, :user_id => @user.id
      expect(flash[:notice]).to match /successfully deleted/
      expect(response).to redirect_to(account_users_url(@account))
      @user.reload
      expect(@user.workflow_state).to eq "deleted"
    end

    it "should do nothing for non-existent users as html" do
      post 'remove_user', :account_id => @account.id, :user_id => (User.all.map(&:id).max + 1)
      expect(flash[:notice]).to be_nil
      expect(response).to redirect_to(account_users_url(@account))
    end

    it "should do nothing for non-existent users as json" do
      post 'remove_user', :account_id => @account.id, :user_id => (User.all.map(&:id).max + 1), :format => "json"
      expect(flash[:notice]).to be_nil
      expect(json_parse(response.body)).to eq({})
    end

    it "should only remove users from the current account if the user exists in multiple accounts" do
      @other_account = account_model
      account_with_admin_logged_in
      user_with_pseudonym :account => @account, :username => "nobody@example.com"
      pseudonym @user, :account => @other_account, :username => "nobody2@example.com"
      expect(@user.workflow_state).to eq "pre_registered"
      expect(@user.associated_accounts.map(&:id).include?(@account.id)).to be_truthy
      expect(@user.associated_accounts.map(&:id).include?(@other_account.id)).to be_truthy
      post 'remove_user', :account_id => @account.id, :user_id => @user.id
      expect(flash[:notice]).to match /successfully deleted/
      expect(response).to redirect_to(account_users_url(@account))
      @user.reload
      expect(@user.workflow_state).to eq "pre_registered"
      expect(@user.associated_accounts.map(&:id).include?(@account.id)).to be_falsey
      expect(@user.associated_accounts.map(&:id).include?(@other_account.id)).to be_truthy
    end

    it "should delete users who have managed passwords with html" do
      user_with_managed_pseudonym :account => @account
      expect(@user.workflow_state).to eq "pre_registered"
      post 'remove_user', :account_id => @account.id, :user_id => @user.id
      expect(flash[:notice]).to match /successfully deleted/
      expect(response).to redirect_to(account_users_url(@account))
      @user.reload
      expect(@user.workflow_state).to eq "deleted"
    end

    it "should delete users who have managed passwords with json" do
      user_with_managed_pseudonym :account => @account
      expect(@user.workflow_state).to eq "pre_registered"
      post 'remove_user', :account_id => @account.id, :user_id => @user.id, :format => "json"
      expect(flash[:notice]).to match /successfully deleted/
      @user = json_parse(@user.reload.to_json)
      expect(json_parse(response.body)).to eq @user
      expect(@user["user"]["workflow_state"]).to eq "deleted"
    end
  end

  describe "add_account_user" do
    before(:once) { account_with_admin }
    before(:each) { user_session(@admin) }

    it "should allow adding a new account admin" do
      post 'add_account_user', :account_id => @account.id, :role_id => admin_role.id, :user_list => 'testadmin@example.com'
      expect(response).to be_success

      new_admin = CommunicationChannel.where(path: 'testadmin@example.com').first.user
      expect(new_admin).not_to be_nil
      @account.reload
      expect(@account.account_users.map(&:user)).to be_include(new_admin)
    end

    it "should allow adding a new custom account admin" do
      role = custom_account_role('custom', :account => @account)
      post 'add_account_user', :account_id => @account.id, :role_id => role.id, :user_list => 'testadmin@example.com'
      expect(response).to be_success

      new_admin = CommunicationChannel.find_by_path('testadmin@example.com').user
      expect(new_admin).to_not be_nil
      @account.reload
      expect(@account.account_users.map(&:user)).to be_include(new_admin)
      expect(@account.account_users.find_by_role_id(role.id).user).to eq new_admin
    end

    it "should allow adding an existing user to a sub account" do
      @subaccount = @account.sub_accounts.create!
      @munda = user_with_pseudonym(:account => @account, :active_all => 1, :username => 'munda@instructure.com')
      post 'add_account_user', :account_id => @subaccount.id, :role_id => admin_role.id, :user_list => 'munda@instructure.com'
      expect(response).to be_success
      expect(@subaccount.account_users.map(&:user)).to eq [@munda]
    end
  end

  describe "remove_account_user" do
    it "should remove account membership from a user" do
      a = Account.default
      user_to_remove = account_admin_user(account: a)
      au_id = user_to_remove.account_users.first.id
      account_with_admin_logged_in(account: a)
      post 'remove_account_user', account_id: a.id, id: au_id
      expect(response).to be_redirect
      expect(AccountUser.where(id: au_id).first).to be_nil
    end

    it "should verify that the membership is in the caller's account" do
      a1 = Account.default
      a2 = Account.create!(name: 'other root account')
      user_to_remove = account_admin_user(account: a1)
      au_id = user_to_remove.account_users.first.id
      account_with_admin_logged_in(account: a2)
      begin
        post 'remove_account_user', :account_id => a2.id, :id => au_id
        # rails3 returns 404 status
        expect(response).to be_not_found
      rescue ActiveRecord::RecordNotFound
        # rails2 passes the exception through here
      end
      expect(AccountUser.where(id: au_id).first).not_to be_nil
    end
  end

  describe "authentication" do
    it "should redirect to CAS if CAS is enabled" do
      account = account_with_cas({:account => Account.default})
      config = { :cas_base_url => account.account_authorization_config.auth_base }
      cas_client = CASClient::Client.new(config)
      get 'show', :id => account.id
      expect(response).to redirect_to(controller.delegated_auth_redirect_uri(cas_client.add_service_to_login_url(cas_login_url)))
    end

    it "should respect canvas_login=1" do
      account = account_with_cas({:account => Account.default})
      get 'show', :id => account.id, :canvas_login => '1'
      expect(response).to render_template("shared/unauthorized")
    end

    it "should set @is_delegated correctly for ldap/non-canvas" do
      Account.default.account_authorization_configs.create!(:auth_type =>'ldap')
      Account.default.settings[:canvas_authentication] = false
      Account.default.save!
      get 'show', :id => Account.default.id
      expect(response).to render_template("shared/unauthorized")
      expect(assigns['is_delegated']).to eq false
    end
  end

  describe "courses" do
    it "should count total courses correctly" do
      account = Account.create!
      account_with_admin_logged_in(account: account)
      course(account: account)
      @course.course_sections.create!
      @course.course_sections.create!
      @course.update_account_associations
      expect(@account.course_account_associations.length).to eq 3 # one for each section, and the "nil" section

      get 'show', :id => @account.id, :format => 'html'

      expect(assigns[:associated_courses_count]).to eq 1
    end
    # Check that both published and un-published courses have the correct count
    it "should count course's student enrollments" do
      account_with_admin_logged_in
      course_with_teacher(:account => @account)
      c1 = @course
      course_with_teacher(:course => c1)
      @student = User.create
      c1.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
      c1.save

      course_with_teacher(:account => @account, :active_all => true)
      c2 = @course
      @student1 = User.create
      c2.enroll_user(@student1, "StudentEnrollment", :enrollment_state => 'active')
      @student2 = User.create
      c2.enroll_user(@student2, "StudentEnrollment", :enrollment_state => 'active')
      c2.save

      get 'show', :id => @account.id, :format => 'html'

      expect(assigns[:courses].find {|c| c.id == c1.id }.student_count).to eq c1.student_enrollments.count
      expect(assigns[:courses].find {|c| c.id == c2.id }.student_count).to eq c2.student_enrollments.count

    end
  end

  context "special account ids" do
    before :once do
      account_with_admin(:account => Account.site_admin)
      @account = Account.create!
    end

    before :each do
      user_session(@admin)
      LoadAccount.stubs(:default_domain_root_account).returns(@account)
    end

    it "should allow self" do
      get 'show', :id => 'self', :format => 'html'
      expect(assigns[:account]).to eq @account
    end

    it "should allow default" do
      get 'show', :id => 'default', :format => 'html'
      expect(assigns[:account]).to eq Account.default
    end

    it "should allow site_admin" do
      get 'show', :id => 'site_admin', :format => 'html'
      expect(assigns[:account]).to eq Account.site_admin
    end
  end

  describe "update" do
    it "should allow admins to set the sis_source_id on sub accounts" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post 'update', :id => @account.id, :account => { :sis_source_id => 'abc' }
      @account.reload
      expect(@account.sis_source_id).to eq 'abc'
    end

    it "should not allow setting the sis_source_id on root accounts" do
      account_with_admin_logged_in
      post 'update', :id => @account.id, :account => { :sis_source_id => 'abc' }
      @account.reload
      expect(@account.sis_source_id).to be_nil
    end

    it "should not allow non-site-admins to update certain settings" do
      account_with_admin_logged_in
      post 'update', :id => @account.id, :account => { :settings => { 
        :global_includes => true,
        :enable_profiles => true,
        :admins_can_change_passwords => true,
        :admins_can_view_notifications => true,
      } }
      @account.reload
      expect(@account.global_includes?).to be_falsey
      expect(@account.enable_profiles?).to be_falsey
      expect(@account.admins_can_change_passwords?).to be_falsey
      expect(@account.admins_can_view_notifications?).to be_falsey
    end

    it "should allow site_admin to update certain settings" do
      user
      user_session(@user)
      @account = Account.create!
      Account.site_admin.account_users.create!(user: @user)
      post 'update', :id => @account.id, :account => { :settings => { 
        :global_includes => true,
        :enable_profiles => true,
        :admins_can_change_passwords => true,
        :admins_can_view_notifications => true,
      } }
      @account.reload
      expect(@account.global_includes?).to be_truthy
      expect(@account.enable_profiles?).to be_truthy
      expect(@account.admins_can_change_passwords?).to be_truthy
      expect(@account.admins_can_view_notifications?).to be_truthy
    end

    it "should allow updating services that appear in the ui for the current user" do
      Account.register_service(:test1, { name: 'test1', description: '', expose_to_ui: :setting, default: false })
      Account.register_service(:test2, { name: 'test2', description: '', expose_to_ui: :setting, default: false, expose_to_ui_proc: proc { |user, account| false } })
      user_session(user)
      @account = Account.create!
      Account.register_service(:test3, { name: 'test3', description: '', expose_to_ui: :setting, default: false, expose_to_ui_proc: proc { |user, account| account == @account } })
      Account.site_admin.account_users.create!(user: @user)
      post 'update', id: @account.id, account: {
        services: {
          'test1' => '1',
          'test2' => '1',
          'test3' => '1',
        }
      }
      @account.reload
      expect(@account.allowed_services).to match(%r{\+test1})
      expect(@account.allowed_services).not_to match(%r{\+test2})
      expect(@account.allowed_services).to match(%r{\+test3})
    end

    describe "quotas" do
      before :once do
        @account = Account.create!
        user
        @account.default_storage_quota_mb = 123
        @account.default_user_storage_quota_mb = 45
        @account.default_group_storage_quota_mb = 9001
        @account.storage_quota = 555.megabytes
        @account.save!
      end

      before :each do
        user_session(@user)
      end
      
      context "with :manage_storage_quotas" do
        before :once do
          role = custom_account_role 'quota-setter', :account => @account
          @account.role_overrides.create! :permission => 'manage_account_settings', :enabled => true,
                                          :role => role
          @account.role_overrides.create! :permission => 'manage_storage_quotas', :enabled => true,
                                          :role => role
          @account.account_users.create!(user: @user, role: role)
        end
        
        it "should allow setting default quota (mb)" do
          post 'update', :id => @account.id, :account => {
              :default_storage_quota_mb => 999,
              :default_user_storage_quota_mb => 99,
              :default_group_storage_quota_mb => 9999
          }
          @account.reload
          expect(@account.default_storage_quota_mb).to eq 999
          expect(@account.default_user_storage_quota_mb).to eq 99
          expect(@account.default_group_storage_quota_mb).to eq 9999
        end
        
        it "should allow setting default quota (bytes)" do
          post 'update', :id => @account.id, :account => {
              :default_storage_quota => 101.megabytes,
          }
          @account.reload
          expect(@account.default_storage_quota).to eq 101.megabytes
        end
        
        it "should allow setting storage quota" do
          post 'update', :id => @account.id, :account => {
            :storage_quota => 777.megabytes
          }
          @account.reload
          expect(@account.storage_quota).to eq 777.megabytes
        end
      end
      
      context "without :manage_storage_quotas" do
        before :once do
          role = custom_account_role 'quota-loser', :account => @account
          @account.role_overrides.create! :permission => 'manage_account_settings', :enabled => true,
                                          :role => role
          @account.account_users.create!(user: @user, role: role)
        end
        
        it "should disallow setting default quota (mb)" do
          post 'update', :id => @account.id, :account => {
              :default_storage_quota => 999,
              :default_user_storage_quota_mb => 99,
              :default_group_storage_quota_mb => 9,
              :default_time_zone => 'Alaska'
          }
          @account.reload
          expect(@account.default_storage_quota_mb).to eq 123
          expect(@account.default_user_storage_quota_mb).to eq 45
          expect(@account.default_group_storage_quota_mb).to eq 9001
          expect(@account.default_time_zone.name).to eq 'Alaska'
        end

        it "should disallow setting default quota (bytes)" do
          post 'update', :id => @account.id, :account => {
              :default_storage_quota => 101.megabytes,
              :default_time_zone => 'Alaska'
          }
          @account.reload
          expect(@account.default_storage_quota).to eq 123.megabytes
          expect(@account.default_time_zone.name).to eq 'Alaska'
        end

        it "should disallow setting storage quota" do
          post 'update', :id => @account.id, :account => {
              :storage_quota => 777.megabytes,
              :default_time_zone => 'Alaska'
          }
          @account.reload
          expect(@account.storage_quota).to eq 555.megabytes
          expect(@account.default_time_zone.name).to eq 'Alaska'
        end
      end
    end

    context "turnitin" do
      before(:once) { account_with_admin }
      before(:each) { user_session(@admin) }

      it "should allow setting turnitin values" do
        post 'update', :id => @account.id, :account => {
          :turnitin_account_id => '123456',
          :turnitin_shared_secret => 'sekret',
          :turnitin_host => 'secret.turnitin.com',
          :turnitin_pledge => 'i will do it',
          :turnitin_comments => 'good work',
        }

        @account.reload
        expect(@account.turnitin_account_id).to eq '123456'
        expect(@account.turnitin_shared_secret).to eq 'sekret'
        expect(@account.turnitin_host).to eq 'secret.turnitin.com'
        expect(@account.turnitin_pledge).to eq 'i will do it'
        expect(@account.turnitin_comments).to eq 'good work'
      end

      it "should pull out the host from a valid url" do
        post 'update', :id => @account.id, :account => {
          :turnitin_host => 'https://secret.turnitin.com/'
        }
        expect(@account.reload.turnitin_host).to eq 'secret.turnitin.com'
      end

      it "should nil out the host if blank is passed" do
        post 'update', :id => @account.id, :account => {
          :turnitin_host => ''
        }
        expect(@account.reload.turnitin_host).to be_nil
      end

      it "should error on an invalid host" do
        post 'update', :id => @account.id, :account => {
          :turnitin_host => 'blah'
        }
        expect(response).not_to be_success
      end
    end
  end

  describe "#settings" do
    it "should load account report details" do
      account_with_admin_logged_in
      report_type = AccountReport.available_reports.keys.first
      report = @account.account_reports.create!(report_type: report_type, user: @admin)

      get 'settings', account_id: @account
      expect(response).to be_success

      expect(assigns[:last_reports].first.last).to eq report
    end
  end
end
