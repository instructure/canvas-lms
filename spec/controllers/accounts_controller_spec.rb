#
# Copyright (C) 2011 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe AccountsController do
  def account_with_admin_logged_in(opts = {})
    account_with_admin(opts)
    user_session(@admin)
  end

  def account_with_admin(opts = {})
    @account = opts[:account] || Account.default
    account_admin_user(account: @account)
  end

  context "confirm_delete_user" do
    before(:once) {account_with_admin}
    before(:each) {user_session(@admin)}

    it "should confirm deletion of canvas-authenticated users" do
      user_with_pseudonym :account => @account
      get 'confirm_delete_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(response).to be_success
    end

    it "should not confirm deletion of non-existent users" do
      get 'confirm_delete_user', params: {:account_id => @account.id, :user_id => (User.all.map(&:id).max + 1)}
      expect(response).to be_not_found
    end

    it "should confirm deletion of managed password users" do
      user_with_managed_pseudonym :account => @account
      get 'confirm_delete_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(response).to be_success
    end
  end

  context "remove_user" do
    before(:once) {account_with_admin}
    before(:each) {user_session(@admin)}

    it "should remove user from the account" do
      user_with_pseudonym :account => @account
      post 'remove_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(flash[:notice]).to match /successfully deleted/
      expect(response).to redirect_to(account_users_url(@account))
      expect(@user.associated_accounts.map(&:id)).not_to include(@account.id)
    end

    it "should 404 for non-existent users as html" do
      post 'remove_user', params: {:account_id => @account.id, :user_id => (User.all.map(&:id).max + 1)}
      expect(flash[:notice]).to be_nil
      expect(response).to be_not_found
    end

    it "should 404 for non-existent users as json" do
      post 'remove_user', params: {:account_id => @account.id, :user_id => (User.all.map(&:id).max + 1)}, :format => "json"
      expect(flash[:notice]).to be_nil
      expect(response).to be_not_found
    end

    it "should only remove user from the account, but not delete them" do
      user_with_pseudonym :account => @account
      workflow_state_was = @user.workflow_state
      post 'remove_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(@user.reload.workflow_state).to eql workflow_state_was
    end

    it "should only remove users from the specified account" do
      @other_account = account_model
      account_with_admin_logged_in
      user_with_pseudonym :account => @account, :username => "nobody@example.com"
      pseudonym @user, :account => @other_account, :username => "nobody2@example.com"
      post 'remove_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(flash[:notice]).to match /successfully deleted/
      expect(response).to redirect_to(account_users_url(@account))
      expect(@user.associated_accounts.map(&:id)).not_to include(@account.id)
      expect(@user.associated_accounts.map(&:id)).to include(@other_account.id)
    end

    it "should delete the user's CCs when removed from their last account" do
      user_with_pseudonym :account => @account
      post 'remove_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(@user.communication_channels.unretired).to be_empty
    end

    it "should not delete the user's CCs when other accounts remain" do
      @other_account = account_model
      account_with_admin_logged_in
      user_with_pseudonym :account => @account, :username => "nobody@example.com"
      pseudonym @user, :account => @other_account, :username => "nobody2@example.com"
      post 'remove_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(@user.communication_channels.unretired).not_to be_empty
    end

    it "should remove users with managed passwords with html" do
      user_with_managed_pseudonym :account => @account
      post 'remove_user', params: {:account_id => @account.id, :user_id => @user.id}
      expect(flash[:notice]).to match /successfully deleted/
      expect(response).to redirect_to(account_users_url(@account))
      expect(@user.associated_accounts.map(&:id)).not_to include(@account.id)
    end

    it "should remove users with managed passwords with json" do
      Timecop.freeze do
        user_with_managed_pseudonym :account => @account, :name => "John Doe"
        post 'remove_user', params: {:account_id => @account.id, :user_id => @user.id}, :format => "json"
        expect(flash[:notice]).to match /successfully deleted/
        expect(json_parse(response.body)).to eq json_parse(@user.reload.to_json)
        expect(@user.associated_accounts.map(&:id)).to_not include(@account.id)
      end
    end
  end

  describe "add_account_user" do
    before(:once) {account_with_admin}
    before(:each) {user_session(@admin)}

    it "should allow adding a new account admin" do
      post 'add_account_user', params: {:account_id => @account.id, :role_id => admin_role.id, :user_list => 'testadmin@example.com'}
      expect(response).to be_success

      new_admin = CommunicationChannel.where(path: 'testadmin@example.com').first.user
      expect(new_admin).not_to be_nil
      @account.reload
      expect(@account.account_users.map(&:user)).to be_include(new_admin)
    end

    it "should allow adding a new custom account admin" do
      role = custom_account_role('custom', :account => @account)
      post 'add_account_user', params: {:account_id => @account.id, :role_id => role.id, :user_list => 'testadmin@example.com'}
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
      post 'add_account_user', params: {:account_id => @subaccount.id, :role_id => admin_role.id, :user_list => 'munda@instructure.com'}
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
      post 'remove_account_user', params: {account_id: a.id, id: au_id}
      expect(response).to be_redirect
      expect(AccountUser.active.where(id: au_id).first).to be_nil
    end

    it "should verify that the membership is in the caller's account" do
      a1 = Account.default
      a2 = Account.create!(name: 'other root account')
      user_to_remove = account_admin_user(account: a1)
      au_id = user_to_remove.account_users.first.id
      account_with_admin_logged_in(account: a2)
      begin
        post 'remove_account_user', params: {:account_id => a2.id, :id => au_id}
        # rails3 returns 404 status
        expect(response).to be_not_found
      rescue ActiveRecord::RecordNotFound
        # rails2 passes the exception through here
      end
      expect(AccountUser.where(id: au_id).first).not_to be_nil
    end
  end

  describe "courses" do
    it "should count total courses correctly" do
      account = Account.create!
      account_with_admin_logged_in(account: account)
      course_factory(account: account)
      @course.course_sections.create!
      @course.course_sections.create!
      @course.update_account_associations
      expect(@account.course_account_associations.length).to eq 3 # one for each section, and the "nil" section

      get 'show', params: {:id => @account.id}, :format => 'html'

      expect(assigns[:associated_courses_count]).to eq 1
    end

    it "should redirect for admins without course read rights when course_user_search is enabled" do
      Account.default.enable_feature!(:course_user_search)
      account_admin_user_with_role_changes(:role_changes => {:read_course_list => false, :read_roster => false} )
      user_session(@admin)

      get 'show', params: {:id => Account.default.id}, :format => 'html'

      expect(response).to redirect_to(account_settings_url(Account.default))
    end

    describe "check crosslisting" do
      before :once do
        @root_account = Account.create!
        @account1 = Account.create!({ :root_account => @root_account })
        @account2 = Account.create!({ :root_account => @root_account })
        @course1 = course_factory({ :account => @account1, :course_name => "course1" })
        @course2 = course_factory({ :account => @account2, :course_name => "course2" })
        @course2.course_sections.create!
        @course2.course_sections.first.crosslist_to_course(@course1)
      end

      it "if crosslisted a section to another account's course, don't show that other course" do
        account_with_admin_logged_in(account: @account2)
        get 'show', params: {:id => @account2.id }, :format => 'html'
        expect(assigns[:associated_courses_count]).to eq 1
      end

      it "if crosslisted a section to this account, do *not* show other account's course" do
        account_with_admin_logged_in(account: @account1)
        get 'show', params: {:id => @account1.id }, :format => 'html'
        expect(assigns[:associated_courses_count]).to eq 1
      end

      it "if crosslisted a section to another account, do show other if that param is not set" do
        account_with_admin_logged_in(account: @account2)
        get 'show', params: {:id => @account2.id, :include_crosslisted_courses => true}, :format => 'html'
        expect(assigns[:associated_courses_count]).to eq 2
      end

      it "if crosslisted a section to this account, do *not* show other account's course even if param is not set" do
        account_with_admin_logged_in(account: @account1)
        get 'show', params: {:id => @account1.id, :include_crosslisted_courses => true}, :format => 'html'
        expect(assigns[:associated_courses_count]).to eq 1
      end
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

      get 'show', params: {:id => @account.id}, :format => 'html'

      expect(assigns[:courses].find {|c| c.id == c1.id}.student_count).to eq c1.student_enrollments.count
      expect(assigns[:courses].find {|c| c.id == c2.id}.student_count).to eq c2.student_enrollments.count
    end


    it "should list student counts in unclaimed courses" do
      account_with_admin_logged_in
      c1 = @account.courses.create!(:name => "something", :workflow_state => 'created')
      @student = User.create
      c1.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')

      get 'show', params: {:id => @account.id}, :format => 'html'

      expect(assigns[:courses].first.student_count).to eq 1
    end

    it "should not list rejected teachers" do
      account_with_admin_logged_in
      course_with_teacher(:account => @account)
      @teacher2 = User.create(:name => "rejected")
      reject = @course.enroll_user(@teacher2, "TeacherEnrollment")
      reject.reject!

      get 'show', params: {:id => @account.id}, :format => 'html'

      expect(assigns[:courses].find {|c| c.id == @course.id}.teacher_names).to eq [@teacher.name]
    end

    it "should sort courses as specified" do
      account_with_admin_logged_in(account: @account)
      course_with_teacher(:account => @account)
      expect_any_instance_of(Account).to receive(:fast_all_courses).with(include(order: "courses.created_at DESC"))
      get 'show', params: {:id => @account.id, :courses_sort_order => "created_at_desc"}, :format => 'html'
      expect(@admin.reload.preferences[:course_sort]).to eq 'created_at_desc'
    end

    it 'can search and sort simultaneously' do
      account_with_admin_logged_in(account: @account)
      @account.courses.create! name: 'blah A'
      @account.courses.create! name: 'blah C'
      @account.courses.create! name: 'blah B'
      @account.courses.create! name: 'bleh Z'
      get 'courses', params: {:account_id => @account.id, :course => {:name => 'blah'}, :courses_sort_order => 'name_desc'}, :format => 'html'
      expect(assigns['courses'].map(&:name)).to eq(['blah C', 'blah B', 'blah A'])
      expect(@admin.reload.preferences[:course_sort]).to eq 'name_desc'
    end
  end

  context "special account ids" do
    before :once do
      account_with_admin(:account => Account.site_admin)
      @account = Account.create!
    end

    before :each do
      user_session(@admin)
      allow(LoadAccount).to receive(:default_domain_root_account).and_return(@account)
    end

    it "should allow self" do
      get 'show', params: {:id => 'self'}, :format => 'html'
      expect(assigns[:account]).to eq @account
    end

    it "should allow default" do
      get 'show', params: {:id => 'default'}, :format => 'html'
      expect(assigns[:account]).to eq Account.default
    end

    it "should allow site_admin" do
      get 'show', params: {:id => 'site_admin'}, :format => 'html'
      expect(assigns[:account]).to eq Account.site_admin
    end
  end

  describe "update" do
    it "should update 'app_center_access_token'" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      access_token = SecureRandom.uuid
      post 'update', params: { id: @account.id,
                               account: {
                                settings: {
                                  app_center_access_token: access_token
                                }
                              }}
      @account.reload
      expect(@account.settings[:app_center_access_token]).to eq access_token
    end

    it "should update account with sis_assignment_name_length_input with value less than 255" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post 'update', params: {:id => @account.id,
                              :account => {
                                :settings => {
                                  :sis_assignment_name_length_input => {
                                    :value => 5
                                  }
                                }
                              }}
      @account.reload
      expect(@account.settings[:sis_assignment_name_length_input][:value]).to eq '5'
    end

    it "should update account with sis_assignment_name_length_input with 255 if none is given" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post 'update', params: {:id => @account.id,
                              :account => {
                                :settings => {
                                  :sis_assignment_name_length_input => {
                                    :value => nil
                                  }
                                }
                              }}
      @account.reload
      expect(@account.settings[:sis_assignment_name_length_input][:value]).to eq '255'
    end

    it "should allow admins to set the sis_source_id on sub accounts" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post 'update', params: {:id => @account.id, :account => {:sis_source_id => 'abc'}}
      @account.reload
      expect(@account.sis_source_id).to eq 'abc'
    end

    it "should not allow setting the sis_source_id on root accounts" do
      account_with_admin_logged_in
      post 'update', params: {:id => @account.id, :account => {:sis_source_id => 'abc'}}
      @account.reload
      expect(@account.sis_source_id).to be_nil
    end

    it "should not allow admins to set the trusted_referers on sub accounts" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post 'update', params: {:id => @account.id, :account => {:settings => {
        :trusted_referers => 'http://example.com'
      }}}
      @account.reload
      expect(@account.settings[:trusted_referers]).to be_nil
    end

    it "should allow admins to set the trusted_referers on root accounts" do
      account_with_admin_logged_in
      post 'update', params: {:id => @account.id, :account => {:settings => {
        :trusted_referers => 'http://example.com'
      }}}
      @account.reload
      expect(@account.settings[:trusted_referers]).to eq 'http://example.com'
    end

    it "should not allow non-site-admins to update certain settings" do
      account_with_admin_logged_in
      post 'update', params: {:id => @account.id, :account => {:settings => {
        :global_includes => true,
        :enable_profiles => true,
        :enable_turnitin => true,
        :admins_can_change_passwords => true,
        :admins_can_view_notifications => true,
      }}}
      @account.reload
      expect(@account.global_includes?).to be_falsey
      expect(@account.enable_profiles?).to be_falsey
      expect(@account.enable_turnitin?).to be_falsey
      expect(@account.admins_can_change_passwords?).to be_falsey
      expect(@account.admins_can_view_notifications?).to be_falsey
    end

    it "should allow site_admin to update certain settings" do
      user_factory
      user_session(@user)
      @account = Account.create!
      Account.site_admin.account_users.create!(user: @user)
      post 'update', params: {:id => @account.id, :account => {:settings => {
        :global_includes => true,
        :enable_profiles => true,
        :enable_turnitin => true,
        :admins_can_change_passwords => true,
        :admins_can_view_notifications => true,
      }}}
      @account.reload
      expect(@account.global_includes?).to be_truthy
      expect(@account.enable_profiles?).to be_truthy
      expect(@account.enable_turnitin?).to be_truthy
      expect(@account.admins_can_change_passwords?).to be_truthy
      expect(@account.admins_can_view_notifications?).to be_truthy
    end

    it 'does not allow anyone to set unexpected settings' do
      user_factory
      user_session(@user)
      @account = Account.create!
      Account.site_admin.account_users.create!(user: @user)
      post 'update', params: {:id => @account.id, :account => {:settings => {
        :product_name => 'blah'
      }}}
      @account.reload
      expect(@account.settings[:product_name]).to be_nil
    end

    it "doesn't break I18n by setting the help_link_name unnecessarily" do
      account_with_admin_logged_in

      post 'update', params: {:id => @account.id, :account => {:settings => {
        :help_link_name  => 'Help'
      }}}
      @account.reload
      expect(@account.settings[:help_link_name]).to be_nil

      post 'update', params: {:id => @account.id, :account => {:settings => {
        :help_link_name => 'Halp'
      }}}
      @account.reload
      expect(@account.settings[:help_link_name]).to eq 'Halp'
    end

    it "doesn't break I18n by setting customized text for default help links unnecessarily" do
      account_with_admin_logged_in
      post 'update', params: {:id => @account.id, :account => { :custom_help_links => { '0' =>
        { :id => 'instructor_question', :text => 'Ask Your Instructor a Question',
          :subtext => 'Questions are submitted to your instructor', :type => 'default',
          :url => '#teacher_feedback', :available_to => ['student'] }
      }}}
      @account.reload
      link = @account.settings[:custom_help_links].detect { |link| link['id'] == 'instructor_question' }
      expect(link).not_to have_key('text')
      expect(link).not_to have_key('subtext')
      expect(link).not_to have_key('url')

      post 'update', params: {:id => @account.id, :account => { :custom_help_links => { '0' =>
        { :id => 'instructor_question', :text => 'yo', :subtext => 'wiggity', :type => 'default',
          :url => '#dawg', :available_to => ['student'] }
      }}}
      @account.reload
      link = @account.settings[:custom_help_links].detect { |link| link['id'] == 'instructor_question' }
      expect(link['text']).to eq 'yo'
      expect(link['subtext']).to eq 'wiggity'
      expect(link['url']).to eq '#dawg'
    end

    it "should allow updating services that appear in the ui for the current user" do
      AccountServices.register_service(:test1,
                                       {name: 'test1', description: '', expose_to_ui: :setting, default: false})
      AccountServices.register_service(:test2,
                                       {name: 'test2', description: '', expose_to_ui: :setting, default: false, expose_to_ui_proc: proc {false}})
      user_session(user_factory)
      @account = Account.create!
      AccountServices.register_service(:test3,
                                       {name: 'test3', description: '', expose_to_ui: :setting, default: false, expose_to_ui_proc: proc {|_, account| account == @account}})
      Account.site_admin.account_users.create!(user: @user)
      post 'update', params: {id: @account.id, account: {
        services: {
          'test1' => '1',
          'test2' => '1',
          'test3' => '1',
        }
      }}
      @account.reload
      expect(@account.allowed_services).to match(%r{\+test1})
      expect(@account.allowed_services).not_to match(%r{\+test2})
      expect(@account.allowed_services).to match(%r{\+test3})
    end

    it "should update 'default_dashboard_view'" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      expect(@account.default_dashboard_view).to be_nil

      post 'update', params: { id: @account.id,
                               account: {
                                  settings: {
                                    default_dashboard_view: "cards"
                                  }
                                }
                             }
      @account.reload
      expect(@account.default_dashboard_view).to eq "cards"
    end

    describe "quotas" do
      before :once do
        @account = Account.create!
        user_factory
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
          post 'update', params: {:id => @account.id, :account => {
            :default_storage_quota_mb => 999,
            :default_user_storage_quota_mb => 99,
            :default_group_storage_quota_mb => 9999
          }}
          @account.reload
          expect(@account.default_storage_quota_mb).to eq 999
          expect(@account.default_user_storage_quota_mb).to eq 99
          expect(@account.default_group_storage_quota_mb).to eq 9999
        end

        it "should allow setting default quota (bytes)" do
          post 'update', params: {:id => @account.id, :account => {
            :default_storage_quota => 101.megabytes,
          }}
          @account.reload
          expect(@account.default_storage_quota).to eq 101.megabytes
        end

        it "should allow setting storage quota" do
          post 'update', params: {:id => @account.id, :account => {
            :storage_quota => 777.megabytes
          }}
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
          post 'update', params: {:id => @account.id, :account => {
            :default_storage_quota => 999,
            :default_user_storage_quota_mb => 99,
            :default_group_storage_quota_mb => 9,
            :default_time_zone => 'Alaska'
          }}
          @account.reload
          expect(@account.default_storage_quota_mb).to eq 123
          expect(@account.default_user_storage_quota_mb).to eq 45
          expect(@account.default_group_storage_quota_mb).to eq 9001
          expect(@account.default_time_zone.name).to eq 'Alaska'
        end

        it "should disallow setting default quota (bytes)" do
          post 'update', params: {:id => @account.id, :account => {
            :default_storage_quota => 101.megabytes,
            :default_time_zone => 'Alaska'
          }}
          @account.reload
          expect(@account.default_storage_quota).to eq 123.megabytes
          expect(@account.default_time_zone.name).to eq 'Alaska'
        end

        it "should disallow setting storage quota" do
          post 'update', params: {:id => @account.id, :account => {
            :storage_quota => 777.megabytes,
            :default_time_zone => 'Alaska'
          }}
          @account.reload
          expect(@account.storage_quota).to eq 555.megabytes
          expect(@account.default_time_zone.name).to eq 'Alaska'
        end
      end
    end

    context "turnitin" do
      before(:once) {account_with_admin}
      before(:each) {user_session(@admin)}

      it "should allow setting turnitin values" do
        post 'update', params: {:id => @account.id, :account => {
          :turnitin_account_id => '123456',
          :turnitin_shared_secret => 'sekret',
          :turnitin_host => 'secret.turnitin.com',
          :turnitin_pledge => 'i will do it',
          :turnitin_comments => 'good work',
        }}

        @account.reload
        expect(@account.turnitin_account_id).to eq '123456'
        expect(@account.turnitin_shared_secret).to eq 'sekret'
        expect(@account.turnitin_host).to eq 'secret.turnitin.com'
        expect(@account.turnitin_pledge).to eq 'i will do it'
        expect(@account.turnitin_comments).to eq 'good work'
      end

      it "should pull out the host from a valid url" do
        post 'update', params: {:id => @account.id, :account => {
          :turnitin_host => 'https://secret.turnitin.com/'
        }}
        expect(@account.reload.turnitin_host).to eq 'secret.turnitin.com'
      end

      it "should nil out the host if blank is passed" do
        post 'update', params: {:id => @account.id, :account => {
          :turnitin_host => ''
        }}
        expect(@account.reload.turnitin_host).to be_nil
      end

      it "should error on an invalid host" do
        post 'update', params: {:id => @account.id, :account => {
          :turnitin_host => 'blah'
        }}
        expect(response).not_to be_success
      end
    end

    context "terms of service settings" do
      before(:once) {account_with_admin}
      before(:each) {user_session(@admin)}

      it "should be able to set and update a custom terms of service" do
        post 'update', params: {:id => @account.id, :account => {
          :terms_of_service => {:terms_type => "custom", :content => "stuff"}
        }}
        tos = @account.reload.terms_of_service
        expect(tos.terms_type).to eq 'custom'
        expect(tos.terms_of_service_content.content).to eq "stuff"
      end

      it "should be able to configure the 'passive' setting" do
        post 'update', params: {:id => @account.id, :account => {:terms_of_service => {:passive => "0"}}}
        expect(@account.reload.terms_of_service.passive).to eq false
        post 'update', params: {:id => @account.id, :account => {:terms_of_service => {:passive => "1"}}}
        expect(@account.reload.terms_of_service.passive).to eq true
      end
    end
  end

  describe "#settings" do
    it "should load account report details" do
      account_with_admin_logged_in
      report_type = AccountReport.available_reports.keys.first
      report = @account.account_reports.create!(report_type: report_type, user: @admin)

      get 'settings', params: {account_id: @account}
      expect(response).to be_success

      expect(assigns[:last_reports].first.last).to eq report
    end

    it "puts up-to-date help link stuff in the env" do
      account_with_admin_logged_in
      @account.settings[:help_link_name] = 'Clippy'
      @account.settings[:help_link_icon] = 'paperclip'
      @account.save!
      allow_any_instance_of(ApplicationHelper).to receive(:help_link_name).and_return('old_cached_nonsense')
      allow_any_instance_of(ApplicationHelper).to receive(:help_link_icon).and_return('old_cached_nonsense')
      get 'settings', params: {account_id: @account}
      expect(assigns[:js_env][:help_link_name]).to eq 'Clippy'
      expect(assigns[:js_env][:help_link_icon]).to eq 'paperclip'
    end

    context "sharding" do
      specs_require_sharding

      it "loads even from the wrong shard" do
        account_with_admin_logged_in

        @shard1.activate do
          get 'settings', params: {account_id: @account}
          expect(response).to be_success
        end
      end
    end

    context "external_integration_keys" do
      before(:once) do
        ExternalIntegrationKey.key_type :external_key0, rights: {write: true}
        ExternalIntegrationKey.key_type :external_key1, rights: {write: false}
        ExternalIntegrationKey.key_type :external_key2, rights: {write: true}
      end

      before do
        user_factory
        user_session(@user)
        @account = Account.create!
        Account.site_admin.account_users.create!(user: @user)

        @eik = ExternalIntegrationKey.new
        @eik.context = @account
        @eik.key_type = :external_key0
        @eik.key_value = '42'
        @eik.save
      end

      it "should load account external integration keys" do
        get 'settings', params: {account_id: @account}
        expect(response).to be_success

        external_integration_keys = assigns[:external_integration_keys]
        expect(external_integration_keys.key?(:external_key0)).to be_truthy
        expect(external_integration_keys.key?(:external_key1)).to be_truthy
        expect(external_integration_keys.key?(:external_key2)).to be_truthy
        expect(external_integration_keys[:external_key0]).to eq @eik
      end

      it "should create a new external integration key" do
        key_value = "2142"
        post 'update', params: {:id => @account.id, :account => {:external_integration_keys => {
          external_key0: "42",
          external_key2: key_value
        }}}
        @account.reload
        eik = @account.external_integration_keys.where(key_type: :external_key2).first
        expect(eik).to_not be_nil
        expect(eik.key_value).to eq "2142"
      end

      it "should update an existing external integration key" do
        key_value = "2142"
        post 'update', params: {:id => @account.id, :account => {:external_integration_keys => {
          external_key0: key_value,
          external_key1: key_value,
          external_key2: key_value
        }}}
        @account.reload

        # Should not be able to edit external_key1.  The user does not have the rights.
        eik = @account.external_integration_keys.where(key_type: :external_key1).first
        expect(eik).to be_nil

        eik = @account.external_integration_keys.where(key_type: :external_key0).first
        expect(eik.id).to eq @eik.id
        expect(eik.key_value).to eq "2142"
      end

      it "should delete an external integration key when not provided or the value is blank" do
        post 'update', params: {:id => @account.id, :account => {:external_integration_keys => {
          external_key0: nil
        }}}
        expect(@account.external_integration_keys.count).to eq 0
      end
    end
  end

  def admin_logged_in(account)
    user_session(user_factory)
    Account.site_admin.account_users.create!(user: @user)
    account_with_admin_logged_in(account: account)
  end

  describe "terms of service" do
    before do
      @account = Account.create!
      course_with_teacher(:account => @account)
      c1 = @course
      course_with_teacher(:course => c1)
      @student = User.create
      c1.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active')
      c1.save
    end

    it "should return the terms of service content" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")

      admin_logged_in(@account)
      get 'terms_of_service', params: {account_id: @account.id}

      expect(response).to be_success
      expect(response.body).to match(/\"content\":\"custom content\"/)
    end

    it "should return the terms of service content as student" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")

      user_session(@teacher)
      get 'terms_of_service', params: {account_id: @account.id}

      expect(response).to be_success
      expect(response.body).to match(/\"content\":\"custom content\"/)
    end

    it "should return the terms of service content as teacher" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")

      user_session(@student)
      get 'terms_of_service', params: {account_id: @account.id}

      expect(response).to be_success
      expect(response.body).to match(/\"content\":\"custom content\"/)
    end
  end

  describe "#account_courses" do
    before do
      @account = Account.create!
      @c1 = course_factory(account: @account, course_name: "foo", sis_source_id: 42)
      @c2 = course_factory(account: @account, course_name: "bar", sis_source_id: 31)
    end

    it "should not allow get a list of courses with no permissions" do
      role = custom_account_role 'non_course_reader', account: @account
      u = User.create(name: 'billy bob')
      user_session(u)
      @account.role_overrides.create! permission: 'read_course_list',
                                      enabled: false, role: role
      @account.account_users.create!(user: u, role: role)
      get 'courses_api', params: {account_id: @account.id}
      assert_unauthorized
    end

    it "should get a list of courses" do
      admin_logged_in(@account)
      get 'courses_api', params: {:account_id => @account.id}

      expect(response).to be_success
      expect(response.body).to match(/#{@c1.id}/)
      expect(response.body).to match(/#{@c2.id}/)
    end

    it "should properly remove sections from includes" do
      @s1 = @course.course_sections.create!
      @course.enroll_student(user_factory(:active_all => true), :section => @s1, :allow_multiple_enrollments => true)

      admin_logged_in(@account)
      get 'courses_api', params: {:account_id => @account.id, :include => [:sections]}

      expect(response).to be_success
      expect(response.body).not_to match(/sections/)
    end

    it "should be able to sort courses by name ascending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "course_name", order: "asc"}

      expect(response).to be_success
      expect(response.body).to match(/\"name\":\"apple\".+\"name\":\"bar\".+\"name\":\"foo\".+\"name\":\"xylophone\"/)
    end

    it "should be able to sort courses by name descending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "course_name", order: "desc"}

      expect(response).to be_success
      expect(response.body).to match(/\"name\":\"xylophone\".+\"name\":\"foo\".+\"name\":\"bar\".+\"name\":\"apple\"/)
    end

    it "should be able to sort courses by id ascending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "sis_course_id", order: "asc"}

      expect(response).to be_success
      expect(response.body).to match(/\"sis_course_id\":\"30\".+\"sis_course_id\":\"31\".+\"sis_course_id\":\"42\".+\"sis_course_id\":\"52\"/)
    end

    it "should be able to sort courses by id descending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "sis_course_id", order: "desc"}

      expect(response).to be_success
      expect(response.body).to match(/\"sis_course_id\":\"52\".+\"sis_course_id\":\"42\".+\"sis_course_id\":\"31\".+\"sis_course_id\":\"30\"/)
    end

    it "should be able to sort courses by teacher ascending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate {user_factory(name: 'Zach Zachary')}
      enrollment = @c3.enroll_user(user, 'TeacherEnrollment')
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = 'active'
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate {user_factory(name: 'Example Another')}
      enrollment2 = @c3.enroll_user(user2, 'TeacherEnrollment')
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = 'active'
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: 'Teach Teacherson', course: course_factory(account: @account, course_name: "xylophone", sis_source_id: 52))

      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "teacher", order: "asc"}

      expect(response).to be_success
      expect(response.body).to match(/\"name\":\"apple\".+\"name\":\"xylophone\".+\"name\":\"foo\".+\"name\":\"bar\"/)
    end

    it "should be able to sort courses by teacher descending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate {user_factory(name: 'Zach Zachary')}
      enrollment = @c3.enroll_user(user, 'TeacherEnrollment')
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = 'active'
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate {user_factory(name: 'Example Another')}
      enrollment2 = @c3.enroll_user(user2, 'TeacherEnrollment')
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = 'active'
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: 'Teach Teacherson', course: course_factory(account: @account, course_name: "xylophone", sis_source_id: 52))

      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "teacher", order: "desc"}

      expect(response).to be_success
      expect(response.body).to match(/\"name\":\"bar\".+\"name\":\"foo\".+\"name\":\"xylophone\".+\"name\":\"apple\"/)
    end

    it "should be able to sort courses by subaccount ascending" do
      @account.name = "Default"
      @account.save

      @a3 = Account.create!
      @a3.name = "Whatever University"
      @a3.root_account_id = @account.id
      @a3.parent_account_id = @account.id
      @a3.workflow_state = 'active'
      @a3.save

      @a4 = Account.create!
      @a4.name = "A University"
      @a4.root_account_id = @account.id
      @a4.parent_account_id = @account.id
      @a4.workflow_state = 'active'
      @a4.save

      @c3 = course_factory(account: @a3, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @a4, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "subaccount", order: "asc"}

      expect(response).to be_success
      expect(response.body).to match(/\"sis_course_id\":\"52\".+\"sis_course_id\":\"42\".+\"sis_course_id\":\"31\".+\"sis_course_id\":\"30\"/)
    end

    it "should be able to sort courses by subaccount descending" do
      @account.name = "Default"
      @account.save

      @a3 = Account.create!
      @a3.name = "Whatever University"
      @a3.root_account_id = @account.id
      @a3.parent_account_id = @account.id
      @a3.workflow_state = 'active'
      @a3.save

      @a4 = Account.create!
      @a4.name = "A University"
      @a4.root_account_id = @account.id
      @a4.parent_account_id = @account.id
      @a4.workflow_state = 'active'
      @a4.save

      @c3 = course_factory(account: @a3, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @a4, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "subaccount", order: "desc"}

      expect(response).to be_success
      expect(response.body).to match(/\"sis_course_id\":\"30\".+\"sis_course_id\":\"31\".+\"sis_course_id\":\"42\".+\"sis_course_id\":\"52\"/)
    end

    context "sorting by term" do
      let(:letters_in_random_order) { 'daqwds'.split('') }
      before do
        @account = Account.create!
        create_courses(letters_in_random_order.map { |i|
          {enrollment_term_id: @account.enrollment_terms.create!(name: i).id}
        }, account: @account)
        admin_logged_in(@account)
      end

      it "should be able to sort courses by term ascending" do
        get 'courses_api', params: {account_id: @account.id, sort: "term", order: "asc", include: ['term']}

        expect(response).to be_success
        term_names = json_parse(response.body).map{|c| c['term']['name']}
        expect(term_names).to eq(letters_in_random_order.sort)
      end

      it "should be able to sort courses by term descending" do
        get 'courses_api', params: {account_id: @account.id, sort: "term", order: "desc", include: ['term']}

        expect(response).to be_success
        term_names = json_parse(response.body).map{|c| c['term']['name']}
        expect(term_names).to eq(letters_in_random_order.sort.reverse)
      end
    end

    it "should be able to search by teacher" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate { user_factory(name: 'Zach Zachary') }
      enrollment = @c3.enroll_user(user, 'TeacherEnrollment')
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = 'active'
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate { user_factory(name: 'Example Another') }
      enrollment2 = @c3.enroll_user(user2, 'TeacherEnrollment')
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = 'active'
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: 'Teach Teacherson', course: course_factory(account: @account, course_name: "xylophone", sis_source_id: 52))

      @c5 = course_with_teacher(name: 'Teachy McTeacher', course: course_factory(account: @account, course_name: "hot dog eating", sis_source_id: 63))


      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "teacher", order: "asc", search_by: "teacher", search_term: "teach"}

      expect(response).to be_success
      expect(response.body).to match(/\"name\":\"hot dog eating\".+\"name\":\"xylophone\"/)
    end

    it "should be able to search by course name" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate { user_factory(name: 'Zach Zachary') }
      enrollment = @c3.enroll_user(user, 'TeacherEnrollment')
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = 'active'
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate { user_factory(name: 'Example Another') }
      enrollment2 = @c3.enroll_user(user2, 'TeacherEnrollment')
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = 'active'
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: 'Teach Teacherson', course: course_factory(account: @account, course_name: "Apps", sis_source_id: 52))

      @c5 = course_with_teacher(name: 'Teachy McTeacher', course: course_factory(account: @account, course_name: "cappuccino", sis_source_id: 63))


      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "course_name", order: "asc", search_by: "course", search_term: "aPp"}

      expect(response).to be_success
      expect(response.body).to match(/\"name\":\"apple\".+\"name\":\"Apps\".+\"name\":\"cappuccino\"/)
      expect(response.body).not_to match(/\"name\":\"apple\".+\"name\":\"Apps\".+\"name\":\"bar\".+\"name\":\"cappuccino\".+\"name\":\"foo\"/)
    end

    it "should be able to search by course sis id" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30012)

      user = @c3.shard.activate { user_factory(name: 'Zach Zachary') }
      enrollment = @c3.enroll_user(user, 'TeacherEnrollment')
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = 'active'
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate { user_factory(name: 'Example Another') }
      enrollment2 = @c3.enroll_user(user2, 'TeacherEnrollment')
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = 'active'
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: 'Teach Teacherson', course: course_factory(account: @account, course_name: "Apps", sis_source_id: 3002))

      @c5 = course_with_teacher(name: 'Teachy McTeacher', course: course_factory(account: @account, course_name: "cappuccino", sis_source_id: 63))


      admin_logged_in(@account)
      get 'courses_api', params: {account_id: @account.id, sort: "course_name", order: "asc", search_by: "course", search_term: "300"}

      expect(response).to be_success
      expect(response.body).to match(/\"name\":\"apple\".+\"name\":\"Apps\"/)
      expect(response.body).not_to match(/\"name\":\"apple\".+\"name\":\"Apps\".+\"name\":\"bar\".+\"name\":\"cappuccino\".+\"name\":\"foo\"/)
    end

  end
end
