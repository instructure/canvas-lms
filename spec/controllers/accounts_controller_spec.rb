# frozen_string_literal: true

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

require_relative "../helpers/k5_common"

describe AccountsController do
  include K5Common

  def account_with_admin_logged_in(opts = {})
    account_with_admin(opts)
    user_session(@admin)
  end

  def account_with_admin(opts = {})
    @account = opts[:account] || Account.default
    account_admin_user(account: @account)
  end

  context "confirm_delete_user" do
    before(:once) { account_with_admin }

    before { user_session(@admin) }

    it "confirms deletion of canvas-authenticated users" do
      user_with_pseudonym account: @account
      get "confirm_delete_user", params: { account_id: @account.id, user_id: @user.id }
      expect(response).to be_successful
    end

    it "does not confirm deletion of non-existent users" do
      get "confirm_delete_user", params: { account_id: @account.id, user_id: (User.all.map(&:id).max + 1) }
      expect(response).to be_not_found
    end

    it "confirms deletion of managed password users" do
      user_with_managed_pseudonym account: @account
      get "confirm_delete_user", params: { account_id: @account.id, user_id: @user.id }
      expect(response).to be_successful
    end
  end

  context "remove_user" do
    before(:once) { account_with_admin }

    before { user_session(@admin) }

    it "removes user from the account" do
      user_with_pseudonym account: @account
      post "remove_user", params: { account_id: @account.id, user_id: @user.id }
      expect(flash[:notice]).to match(/successfully deleted/)
      expect(response).to redirect_to(account_users_url(@account))
      expect(@user.associated_accounts.map(&:id)).not_to include(@account.id)
    end

    it "404s for non-existent users as html" do
      post "remove_user", params: { account_id: @account.id, user_id: (User.all.map(&:id).max + 1) }
      expect(flash[:notice]).to be_nil
      expect(response).to be_not_found
    end

    it "404s for non-existent users as json" do
      post "remove_user", params: { account_id: @account.id, user_id: (User.all.map(&:id).max + 1) }, format: "json"
      expect(flash[:notice]).to be_nil
      expect(response).to be_not_found
    end

    it "only removes user from the account, but not delete them" do
      user_with_pseudonym account: @account
      workflow_state_was = @user.workflow_state
      post "remove_user", params: { account_id: @account.id, user_id: @user.id }
      expect(@user.reload.workflow_state).to eql workflow_state_was
    end

    it "only removes users from the specified account" do
      @other_account = account_model
      account_with_admin_logged_in
      user_with_pseudonym account: @account, username: "nobody@example.com"
      pseudonym @user, account: @other_account, username: "nobody2@example.com"
      post "remove_user", params: { account_id: @account.id, user_id: @user.id }
      expect(flash[:notice]).to match(/successfully deleted/)
      expect(response).to redirect_to(account_users_url(@account))
      expect(@user.associated_accounts.map(&:id)).not_to include(@account.id)
      expect(@user.associated_accounts.map(&:id)).to include(@other_account.id)
    end

    it "deletes the user's CCs when removed from their last account" do
      user_with_pseudonym account: @account
      post "remove_user", params: { account_id: @account.id, user_id: @user.id }
      expect(@user.communication_channels.unretired).to be_empty
    end

    it "does not delete the user's CCs when other accounts remain" do
      @other_account = account_model
      account_with_admin_logged_in
      user_with_pseudonym account: @account, username: "nobody@example.com"
      pseudonym @user, account: @other_account, username: "nobody2@example.com"
      post "remove_user", params: { account_id: @account.id, user_id: @user.id }
      expect(@user.communication_channels.unretired).not_to be_empty
    end

    it "removes users with managed passwords with html" do
      user_with_managed_pseudonym account: @account
      post "remove_user", params: { account_id: @account.id, user_id: @user.id }
      expect(flash[:notice]).to match(/successfully deleted/)
      expect(response).to redirect_to(account_users_url(@account))
      expect(@user.associated_accounts.map(&:id)).not_to include(@account.id)
    end

    it "removes users with managed passwords with json" do
      Timecop.freeze do
        user_with_managed_pseudonym account: @account, name: "John Doe"
        post "remove_user", params: { account_id: @account.id, user_id: @user.id }, format: "json"
        expect(flash[:notice]).to match(/successfully deleted/)
        expect(json_parse(response.body)).to eq json_parse(@user.reload.to_json)
        expect(@user.associated_accounts.map(&:id)).to_not include(@account.id)
      end
    end
  end

  context "restore_user" do
    before(:once) do
      account_with_admin
      @deleted_user = user_with_pseudonym(account: @account)
      @deleted_user.destroy
    end

    before { user_session(@admin) }

    it "allows admins to restore deleted users" do
      put "restore_user", params: { account_id: @account.id, user_id: @deleted_user.id }
      expect(@deleted_user.reload.workflow_state).to eq "registered"
      expect(@deleted_user.pseudonyms.take.workflow_state).to eq "active"
      expect(@deleted_user.user_account_associations.find_by(account: @account)).not_to be_nil
    end

    it "does not allow users without login permissions to restore deleted users" do
      account_admin_user_with_role_changes(user: @admin, role_changes: { manage_user_logins: false })
      put "restore_user", params: { account_id: @account.id, user_id: @deleted_user.id }, format: "json"
      expect(response).to be_unauthorized
    end

    it "404s for non-existent users" do
      put "restore_user", params: { account_id: @account.id, user_id: 0 }
      expect(response).to be_not_found

      # user without a pseudonym in the account
      @missing_user = user_factory
      @missing_user.destroy
      put "restore_user", params: { account_id: @account.id, user_id: @missing_user.id }
      expect(response).to be_not_found
    end

    it "does not change the state of users who were only removed from the account" do
      @doomed_user = user_with_pseudonym(account: @account, user_state: "pre_registered")
      @doomed_user.remove_from_root_account(@account)

      put "restore_user", params: { account_id: @account.id, user_id: @doomed_user.id }
      expect(@doomed_user.reload.workflow_state).to eq "pre_registered"
      expect(@doomed_user.pseudonyms.take.workflow_state).to eq "active"
      expect(@doomed_user.user_account_associations.find_by(account: @account)).not_to be_nil
    end

    it "400s for non-deleted users" do
      @active_user = user_with_pseudonym(account: @account)

      put "restore_user", params: { account_id: @account.id, user_id: @active_user.id }
      expect(response).to be_bad_request
    end
  end

  describe "add_account_user" do
    before(:once) { account_with_admin }

    before { user_session(@admin) }

    it "allows adding a new account admin" do
      post "add_account_user", params: { account_id: @account.id, role_id: admin_role.id, user_list: "testadmin@example.com" }
      expect(response).to be_successful

      new_admin = CommunicationChannel.where(path: "testadmin@example.com").first.user
      expect(new_admin).not_to be_nil
      @account.reload
      expect(@account.account_users.map(&:user)).to include(new_admin)
    end

    it "allows adding a new custom account admin" do
      role = custom_account_role("custom", account: @account)
      post "add_account_user", params: { account_id: @account.id, role_id: role.id, user_list: "testadmin@example.com" }
      expect(response).to be_successful

      new_admin = CommunicationChannel.find_by(path: "testadmin@example.com").user
      expect(new_admin).to_not be_nil
      @account.reload
      expect(@account.account_users.map(&:user)).to include(new_admin)
      expect(@account.account_users.find_by(role_id: role.id).user).to eq new_admin
    end

    it "allows adding an existing user to a sub account" do
      @subaccount = @account.sub_accounts.create!
      @munda = user_with_pseudonym(account: @account, active_all: 1, username: "munda@instructure.com")
      post "add_account_user", params: { account_id: @subaccount.id, role_id: admin_role.id, user_list: "munda@instructure.com" }
      expect(response).to be_successful
      expect(@subaccount.account_users.map(&:user)).to eq [@munda]
    end

    it "allows re-adding an user to a sub account (updating user account association)" do
      @subaccount = @account.sub_accounts.create!
      @usr = user_with_pseudonym(account: @subaccount, active_all: 1, username: "usr@instructure.com")
      @subaccount.account_users.create!(user_id: @usr.id, role_id: admin_role.id).destroy
      post "add_account_user", params: { account_id: @subaccount.id, role_id: admin_role.id, user_list: "usr@instructure.com" }
      expect(response).to be_successful
      expect(@subaccount.account_users.map(&:user)).to include(@usr)
      expect(@usr.user_account_associations.map(&:account)).to include(@subaccount)
    end
  end

  describe "remove_account_user" do
    it "removes account membership from a user" do
      a = Account.default
      user_to_remove = account_admin_user(account: a)
      au_id = user_to_remove.account_users.first.id
      account_with_admin_logged_in(account: a)
      post "remove_account_user", params: { account_id: a.id, id: au_id }
      expect(response).to be_redirect
      expect(AccountUser.active.where(id: au_id).first).to be_nil
    end

    it "verifies that the membership is in the caller's account" do
      a1 = Account.default
      a2 = Account.create!(name: "other root account")
      user_to_remove = account_admin_user(account: a1)
      au_id = user_to_remove.account_users.first.id
      account_with_admin_logged_in(account: a2)
      post "remove_account_user", params: { account_id: a2.id, id: au_id }
      expect(response).to be_not_found
      expect(AccountUser.where(id: au_id).first).not_to be_nil
    end
  end

  describe "update" do
    it "updates 'app_center_access_token'" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      access_token = SecureRandom.uuid
      post "update", params: { id: @account.id,
                               account: {
                                 settings: {
                                   app_center_access_token: access_token
                                 }
                               } }
      @account.reload
      expect(@account.settings[:app_center_access_token]).to eq access_token
    end

    it "updates 'emoji_deny_list'" do
      account_with_admin_logged_in
      @account.allow_feature!(:submission_comment_emojis)
      post(
        :update,
        params: {
          id: @account.id,
          account: {
            settings: {
              emoji_deny_list: "middle_finger,eggplant"
            }
          }
        }
      )
      @account.reload
      expect(@account.settings[:emoji_deny_list]).to eq "middle_finger,eggplant"
    end

    it "updates account with sis_assignment_name_length_input with value less than 255" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post "update", params: { id: @account.id,
                               account: {
                                 settings: {
                                   sis_assignment_name_length_input: {
                                     value: 5
                                   }
                                 }
                               } }
      @account.reload
      expect(@account.settings[:sis_assignment_name_length_input][:value]).to eq "5"
    end

    it "updates account with sis_assignment_name_length_input with 255 if none is given" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post "update", params: { id: @account.id,
                               account: {
                                 settings: {
                                   sis_assignment_name_length_input: {
                                     value: nil
                                   }
                                 }
                               } }
      @account.reload
      expect(@account.settings[:sis_assignment_name_length_input][:value]).to eq "255"
    end

    it "allows admins to set the sis_source_id on sub accounts" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post "update", params: { id: @account.id, account: { sis_source_id: "abc" } }
      @account.reload
      expect(@account.sis_source_id).to eq "abc"
    end

    it "does not allow setting the sis_source_id on root accounts" do
      account_with_admin_logged_in
      post "update", params: { id: @account.id, account: { sis_source_id: "abc" } }
      @account.reload
      expect(@account.sis_source_id).to be_nil
    end

    it "does not allow admins to set the trusted_referers on sub accounts" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      post "update", params: { id: @account.id,
                               account: { settings: {
                                 trusted_referers: "http://example.com"
                               } } }
      @account.reload
      expect(@account.settings[:trusted_referers]).to be_nil
    end

    it "allows admins to set the trusted_referers on root accounts" do
      account_with_admin_logged_in
      post "update", params: { id: @account.id,
                               account: { settings: {
                                 trusted_referers: "http://example.com"
                               } } }
      @account.reload
      expect(@account.settings[:trusted_referers]).to eq "http://example.com"
    end

    it "does not allow non-site-admins to update certain settings" do
      account_with_admin_logged_in
      post "update", params: { id: @account.id,
                               account: { settings: {
                                 global_includes: true,
                                 enable_profiles: true,
                                 enable_turnitin: true,
                                 admins_can_change_passwords: true,
                                 admins_can_view_notifications: true,
                                 limit_parent_app_web_access: true,
                               } } }
      @account.reload
      expect(@account.global_includes?).to be_falsey
      expect(@account.enable_profiles?).to be_falsey
      expect(@account.enable_turnitin?).to be_falsey
      expect(@account.admins_can_change_passwords?).to be_falsey
      expect(@account.admins_can_view_notifications?).to be_falsey
      expect(@account.limit_parent_app_web_access?).to be_falsey
    end

    it "allows site_admin to update certain settings" do
      user_factory
      user_session(@user)
      @account = Account.create!
      Account.site_admin.account_users.create!(user: @user)
      post "update", params: { id: @account.id,
                               account: { settings: {
                                 global_includes: true,
                                 enable_profiles: true,
                                 enable_turnitin: true,
                                 admins_can_change_passwords: true,
                                 admins_can_view_notifications: true,
                                 limit_parent_app_web_access: true,
                               } } }
      @account.reload
      expect(@account.global_includes?).to be_truthy
      expect(@account.enable_profiles?).to be_truthy
      expect(@account.enable_turnitin?).to be_truthy
      expect(@account.admins_can_change_passwords?).to be_truthy
      expect(@account.admins_can_view_notifications?).to be_truthy
      expect(@account.limit_parent_app_web_access?).to be_truthy
    end

    it "does not allow anyone to set unexpected settings" do
      user_factory
      user_session(@user)
      @account = Account.create!
      Account.site_admin.account_users.create!(user: @user)
      post "update", params: { id: @account.id,
                               account: { settings: {
                                 product_name: "blah"
                               } } }
      @account.reload
      expect(@account.settings[:product_name]).to be_nil
    end

    it "clears settings from subaccount that would be inherited with the same value" do
      account_with_admin_logged_in
      subaccount = @account.sub_accounts.create!

      post "update", params: { id: subaccount.id,
                               account: { settings: {
                                 restrict_student_future_view: { value: true }
                               } } }
      expect(subaccount.reload.settings[:restrict_student_future_view][:value]).to be true

      post "update", params: { id: subaccount.id,
                               account: { settings: {
                                 restrict_student_future_view: { value: false }
                               } } }
      expect(subaccount.reload.settings[:restrict_student_future_view]).to be_nil
    end

    it "allows updating setting in child account after updating from inheritable value" do
      account_with_admin_logged_in
      root_account = @account.sub_accounts.create!
      subaccount = root_account.sub_accounts.create!

      post "update", params: { id: subaccount.id, account: { settings: {} } }
      expect(subaccount.reload.settings[:restrict_student_future_view]).to be_nil
      expect(subaccount.restrict_student_future_view[:value]).to be false

      post "update", params: { id: root_account.id,
                               account: { settings: {
                                 restrict_student_future_view: { value: true }
                               } } }
      expect(subaccount.reload.settings[:restrict_student_future_view]).to be_nil
      expect(subaccount.restrict_student_future_view[:value]).to be true

      post "update", params: { id: subaccount.id,
                               account: { settings: {
                                 restrict_student_future_view: { value: false }
                               } } }
      expect(subaccount.reload.settings[:restrict_student_future_view][:value]).to be false
      expect(subaccount.restrict_student_future_view[:value]).to be false

      post "update", params: { id: subaccount.id,
                               account: { settings: {
                                 restrict_student_future_view: { value: true }
                               } } }
      expect(subaccount.reload.settings[:restrict_student_future_view]).to be_nil
      expect(subaccount.restrict_student_future_view[:value]).to be true
    end

    it "doesn't break I18n by setting the help_link_name unnecessarily" do
      account_with_admin_logged_in

      post "update", params: { id: @account.id,
                               account: { settings: {
                                 help_link_name: "Help"
                               } } }
      @account.reload
      expect(@account.settings[:help_link_name]).to be_nil

      post "update", params: { id: @account.id,
                               account: { settings: {
                                 help_link_name: "Halp"
                               } } }
      @account.reload
      expect(@account.settings[:help_link_name]).to eq "Halp"
    end

    it "doesn't break I18n by setting customized text for default help links unnecessarily" do
      Setting.set("show_feedback_link", "true")
      account_with_admin_logged_in
      post "update", params: { id: @account.id,
                               account: { custom_help_links: { "0" =>
        { id: "instructor_question",
          text: "Ask Your Instructor a Question",
          subtext: "Questions are submitted to your instructor",
          type: "default",
          url: "#teacher_feedback",
          available_to: ["student"] } } } }
      @account.reload
      link = @account.settings[:custom_help_links].detect { |l| l["id"] == "instructor_question" }
      expect(link).not_to have_key("text")
      expect(link).not_to have_key("subtext")
      expect(link).not_to have_key("url")

      post "update", params: { id: @account.id,
                               account: { custom_help_links: { "0" =>
        { id: "instructor_question",
          text: "yo",
          subtext: "wiggity",
          type: "default",
          url: "#dawg",
          available_to: ["student"] } } } }
      @account.reload
      link = @account.settings[:custom_help_links].detect { |l| l["id"] == "instructor_question" }
      expect(link["text"]).to eq "yo"
      expect(link["subtext"]).to eq "wiggity"
      expect(link["url"]).to eq "#dawg"
    end

    it "doesn't allow invalid help links" do
      account_with_admin_logged_in
      post "update", params: { id: @account.id,
                               account: { custom_help_links: { "0" =>
        { id: "instructor_question",
          text: "Ask Your Instructor a Question",
          subtext: "Questions are submitted to your instructor",
          type: "default",
          url: "#teacher_feedback",
          available_to: ["student"],
          is_featured: true,
          is_new: true } } } }
      expect(flash[:error]).to match(/update failed/)
      expect(@account.reload.settings[:custom_help_links]).to be_nil
    end

    it "allows updating services that appear in the ui for the current user" do
      AccountServices.register_service(:test1,
                                       { name: "test1", description: "", expose_to_ui: :setting, default: false })
      AccountServices.register_service(:test2,
                                       { name: "test2", description: "", expose_to_ui: :setting, default: false, expose_to_ui_proc: proc { false } })
      user_session(user_factory)
      @account = Account.create!
      AccountServices.register_service(:test3,
                                       { name: "test3", description: "", expose_to_ui: :setting, default: false, expose_to_ui_proc: proc { |_, account| account == @account } })
      Account.site_admin.account_users.create!(user: @user)
      post "update", params: { id: @account.id,
                               account: {
                                 services: {
                                   "test1" => "1",
                                   "test2" => "1",
                                   "test3" => "1",
                                 }
                               } }
      @account.reload
      expect(@account.allowed_services).to match(/\+test1/)
      expect(@account.allowed_services).not_to match(/\+test2/)
      expect(@account.allowed_services).to match(/\+test3/)
    end

    it "updates 'default_dashboard_view'" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      expect(@account.default_dashboard_view).to be_nil

      post "update", params: { id: @account.id,
                               account: {
                                 settings: {
                                   default_dashboard_view: "cards"
                                 }
                               } }
      @account.reload
      expect(@account.default_dashboard_view).to eq "cards"
    end

    it "overwrites account users' existing dashboard_view if specified" do
      account_with_admin_logged_in
      @subaccount = @account.sub_accounts.create!
      @account.save!

      course_with_teacher(account: @subaccount, active_all: true)
      course_with_student(account: @subaccount, active_all: true)

      @student.dashboard_view = "activity"
      @student.save!

      @account.pseudonyms.create!(unique_id: "student", user: @student)

      expect(@subaccount.default_dashboard_view).to be_nil
      # Tests against user-set dashboard views
      expect(@student.dashboard_view(@subaccount)).to eq "activity"
      # ... as well as default views the user hasn't set
      expect(@teacher.dashboard_view(@subaccount)).to eq "cards"

      post "update", params: { id: @subaccount.id,
                               account: {
                                 settings: {
                                   default_dashboard_view: "planner",
                                   force_default_dashboard_view: true
                                 }
                               } }
      run_jobs
      expect([@subaccount.reload.default_dashboard_view,
              @teacher.dashboard_view(@subaccount),
              @student.reload.dashboard_view(@subaccount)]).to match_array(Array.new(3, "planner"))
    end

    it "doesn't overwrite stuck sis fields" do
      account_with_admin_logged_in
      @account = @account.sub_accounts.create!
      name = "update the name to mark it as stuck"
      @account.update({ name: })

      new_account_name = "updated account name"
      put "update", params: { id: @account.id, "account[name]": new_account_name, override_sis_stickiness: false }, format: "json"
      @account.reload

      expect(response).to have_http_status :ok
      expect(@account.name).to eq name
    end

    describe "k5 settings" do
      def toggle_k5_params(account_id, enable)
        { id: account_id,
          account: {
            settings: {
              enable_as_k5_account: {
                value: enable
              }
            }
          } }
      end

      before :once do
        @account = Account.create!
        @user = account_admin_user(account: @account)
      end

      before do
        user_session(@user)
      end

      it "calls K5::EnablementService with correct args if enable_as_k5_account is present in params" do
        set_k5_settings_double = double("set_k5_settings")
        expect(K5::EnablementService).to receive(:new).with(@account).and_return(set_k5_settings_double)
        expect(set_k5_settings_double).to receive(:set_k5_settings).with(true, false)
        post "update", params: { id: @account.id,
                                 account: {
                                   settings: {
                                     enable_as_k5_account: {
                                       value: "true"
                                     },
                                     use_classic_font_in_k5: {
                                       value: "false"
                                     }
                                   }
                                 } }
      end

      it "doesn't call K5::EnablementService or change k5 settings if enable_as_k5_account isn't present in params" do
        @account.settings[:enable_as_k5_account] = {
          value: true,
          locked: true
        }
        @account.save!
        expect(K5::EnablementService).not_to receive(:new)
        post "update", params: { id: @account.id,
                                 account: {
                                   settings: {
                                     emoji_deny_list: "middle_finger,eggplant"
                                   }
                                 } }
        expect(@account.settings[:enable_as_k5_account][:value]).to be_truthy
        expect(@account.settings[:enable_as_k5_account][:locked]).to be_truthy
      end

      it "clears the cached k5_user value for all users when the setting is changed" do
        post "update", params: toggle_k5_params(@account.id, false)
        service = K5::UserService.new(@user, @account.root_account, nil)
        enable_cache(:redis_cache_store) do
          expect(service).to receive(:user_has_association?).twice
          service.send(:k5_user?)
          post "update", params: toggle_k5_params(@account.id, true)
          run_jobs
          service.send(:k5_user?)
        end
      end
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

      before do
        user_session(@user)
      end

      context "with :manage_storage_quotas" do
        before :once do
          role = custom_account_role "quota-setter", account: @account
          @account.role_overrides.create!(permission: "manage_account_settings",
                                          enabled: true,
                                          role:)
          @account.role_overrides.create!(permission: "manage_storage_quotas",
                                          enabled: true,
                                          role:)
          @account.account_users.create!(user: @user, role:)
        end

        it "allows setting default quota (mb)" do
          post "update", params: { id: @account.id,
                                   account: {
                                     default_storage_quota_mb: 999,
                                     default_user_storage_quota_mb: 99,
                                     default_group_storage_quota_mb: 9999
                                   } }
          @account.reload
          expect(@account.default_storage_quota_mb).to eq 999
          expect(@account.default_user_storage_quota_mb).to eq 99
          expect(@account.default_group_storage_quota_mb).to eq 9999
        end

        it "allows setting default quota (bytes)" do
          post "update", params: { id: @account.id,
                                   account: {
                                     default_storage_quota: 101.megabytes,
                                   } }
          @account.reload
          expect(@account.default_storage_quota).to eq 101.megabytes
        end

        it "allows setting storage quota" do
          post "update", params: { id: @account.id,
                                   account: {
                                     storage_quota: 777.megabytes
                                   } }
          @account.reload
          expect(@account.storage_quota).to eq 777.megabytes
        end
      end

      context "without :manage_storage_quotas" do
        before :once do
          role = custom_account_role "quota-example", account: @account
          @account.role_overrides.create!(permission: "manage_account_settings",
                                          enabled: true,
                                          role:)
          @account.account_users.create!(user: @user, role:)
        end

        it "disallows setting default quota (mb)" do
          post "update", params: { id: @account.id,
                                   account: {
                                     default_storage_quota: 999,
                                     default_user_storage_quota_mb: 99,
                                     default_group_storage_quota_mb: 9,
                                     default_time_zone: "Alaska"
                                   } }
          @account.reload
          expect(@account.default_storage_quota_mb).to eq 123
          expect(@account.default_user_storage_quota_mb).to eq 45
          expect(@account.default_group_storage_quota_mb).to eq 9001
          expect(@account.default_time_zone.name).to eq "Alaska"
        end

        it "disallows setting default quota (bytes)" do
          post "update", params: { id: @account.id,
                                   account: {
                                     default_storage_quota: 101.megabytes,
                                     default_time_zone: "Alaska"
                                   } }
          @account.reload
          expect(@account.default_storage_quota).to eq 123.megabytes
          expect(@account.default_time_zone.name).to eq "Alaska"
        end

        it "disallows setting storage quota" do
          post "update", params: { id: @account.id,
                                   account: {
                                     storage_quota: 777.megabytes,
                                     default_time_zone: "Alaska"
                                   } }
          @account.reload
          expect(@account.storage_quota).to eq 555.megabytes
          expect(@account.default_time_zone.name).to eq "Alaska"
        end
      end
    end

    context "turnitin" do
      before(:once) { account_with_admin }

      before { user_session(@admin) }

      it "allows setting turnitin values" do
        post "update", params: { id: @account.id,
                                 account: {
                                   turnitin_account_id: "123456",
                                   turnitin_shared_secret: "sekret",
                                   turnitin_host: "secret.turnitin.com",
                                   turnitin_pledge: "i will do it",
                                   turnitin_comments: "good work",
                                 } }

        @account.reload
        expect(@account.turnitin_account_id).to eq "123456"
        expect(@account.turnitin_shared_secret).to eq "sekret"
        expect(@account.turnitin_host).to eq "secret.turnitin.com"
        expect(@account.turnitin_pledge).to eq "i will do it"
        expect(@account.turnitin_comments).to eq "good work"
      end

      it "pulls out the host from a valid url" do
        post "update", params: { id: @account.id,
                                 account: {
                                   turnitin_host: "https://secret.turnitin.com/"
                                 } }
        expect(@account.reload.turnitin_host).to eq "secret.turnitin.com"
      end

      it "nils out the host if blank is passed" do
        post "update", params: { id: @account.id,
                                 account: {
                                   turnitin_host: ""
                                 } }
        expect(@account.reload.turnitin_host).to be_nil
      end

      it "errors on an invalid host" do
        post "update", params: { id: @account.id,
                                 account: {
                                   turnitin_host: "blah"
                                 } }
        expect(response).not_to be_successful
      end
    end

    context "terms of service settings" do
      before(:once) { account_with_admin }

      before { user_session(@admin) }

      it "is able to set and update a custom terms of service" do
        post "update", params: { id: @account.id,
                                 account: {
                                   terms_of_service: { terms_type: "custom", content: "stuff" }
                                 } }
        tos = @account.reload.terms_of_service
        expect(tos.terms_type).to eq "custom"
        expect(tos.terms_of_service_content.content).to eq "stuff"
      end

      it "is able to configure the 'passive' setting" do
        post "update", params: { id: @account.id, account: { terms_of_service: { passive: "0" } } }
        expect(@account.reload.terms_of_service.passive).to be false
        post "update", params: { id: @account.id, account: { terms_of_service: { passive: "1" } } }
        expect(@account.reload.terms_of_service.passive).to be true
      end
    end

    it "is set and unset outgoing email name" do
      account_with_admin_logged_in
      post "update", params: { id: @account.id,
                               account: {
                                 settings: { outgoing_email_default_name_option: "custom", outgoing_email_default_name: "beep" }
                               } }
      expect(@account.reload.settings[:outgoing_email_default_name]).to eq "beep"
      post "update", params: { id: @account.id,
                               account: {
                                 settings: { outgoing_email_default_name_option: "default" }
                               } }
      expect(@account.reload.settings[:outgoing_email_default_name]).to be_nil
    end

    context "course_template_id" do
      before do
        account_with_admin_logged_in
        @account.enable_feature!(:course_templates)
      end

      let(:template) { @account.courses.create!(template: true) }

      it "does nothing when not passed" do
        @account.update!(course_template: template)
        post "update", params: { id: @account.id, account: {} }
        @account.reload
        expect(@account.course_template).to eq template
      end

      it "sets to null when blank" do
        @account.grants_right?(@admin, :edit_course_template)
        @account.update!(course_template: template)
        post "update", params: { id: @account.id, account: { course_template_id: "" } }
        @account.reload
        expect(@account.course_template).to be_nil
      end

      it "sets it" do
        post "update", params: { id: @account.id, account: { course_template_id: template.id } }
        @account.reload
        expect(@account.course_template).to eq template
      end

      it "supports lookup by sis id" do
        template.update!(sis_source_id: "sis_id")
        post "update", params: { id: @account.id, account: { course_template_id: "sis_course_id:sis_id" } }
        @account.reload
        expect(@account.course_template).to eq template
      end
    end

    context "default_due_time" do
      before :once do
        account_with_admin
        @root = @account
        @subaccount = account_model(parent_account: @account)
      end

      before do
        user_session(@admin)
      end

      it "sets the default_due_time account setting to the normalized value" do
        post "update", params: { id: @root.id, account: { settings: { default_due_time: { value: "10:00 PM" } } } }
        expect(@root.reload.default_due_time).to eq({ value: "22:00:00" })
      end

      it "unsets a root account's default due time with `inherit`" do
        @root.update settings: { default_due_time: { value: "22:00:00" } }
        post "update", params: { id: @root.id, account: { settings: { default_due_time: { value: "inherit" } } } }
        expect(@root.reload.default_due_time[:value]).to be_nil
      end

      it "subaccount re-inherits the root account's default due time with `inherit`" do
        @root.update settings: { default_due_time: { value: "22:00:00" } }
        @subaccount.update settings: { default_due_time: { value: "23:00:00" } }
        post "update", params: { id: @subaccount.id, account: { settings: { default_due_time: { value: "inherit" } } } }
        expect(@subaccount.reload.default_due_time).to eq({ value: "22:00:00", inherited: true })
      end

      it "leaves the setting alone if the parameter is not supplied" do
        @root.update settings: { default_due_time: { value: "22:00:00" } }
        post "update", params: { id: @subaccount.id, account: { settings: { restrict_student_future_view: { value: true } } } }
        expect(@root.reload.default_due_time).to eq({ value: "22:00:00" })
      end
    end
  end

  describe "#settings" do
    describe "js_env" do
      let(:account) do
        account_with_admin_logged_in
        @account
      end

      it "sets the external tools create url" do
        get "settings", params: { account_id: account.id }
        expect(assigns.dig(:js_env, :EXTERNAL_TOOLS_CREATE_URL)).to eq(
          "http://test.host/accounts/#{account.id}/external_tools"
        )
      end

      it "sets the tool configuration show url" do
        get "settings", params: { account_id: account.id }
        expect(assigns.dig(:js_env, :TOOL_CONFIGURATION_SHOW_URL)).to eq(
          "http://test.host/api/lti/accounts/#{account.id}/developer_keys/:developer_key_id/tool_configuration"
        )
      end

      it "sets microsoft sync values" do
        allow(MicrosoftSync::LoginService).to receive(:client_id).and_return("1234")
        get "settings", params: { account_id: account.id }
        expect(assigns.dig(:js_env, :MICROSOFT_SYNC)).to include(
          CLIENT_ID: "1234",
          REDIRECT_URI: "https://www.instructure.com/",
          BASE_URL: "https://login.microsoftonline.com"
        )
      end
    end

    it "is not accessible to teachers" do
      course_with_teacher
      user_session(@teacher)
      get "settings", params: { account_id: @course.root_account.id }
      expect(response).to be_unauthorized
    end

    it "loads account report details" do
      account_with_admin_logged_in
      report_type = AccountReport.available_reports.keys.first
      report = @account.account_reports.create!(report_type:, user: @admin)

      get "reports_tab", params: { account_id: @account }
      expect(response).to be_successful

      expect(assigns[:last_reports].first.last).to eq report
    end

    it "puts up-to-date help link stuff in the env" do
      account_with_admin_logged_in
      @account.settings[:help_link_name] = "Clippy"
      @account.settings[:help_link_icon] = "paperclip"
      @account.save!
      allow_any_instance_of(ApplicationHelper).to receive(:help_link_name).and_return("old_cached_nonsense")
      allow_any_instance_of(ApplicationHelper).to receive(:help_link_icon).and_return("old_cached_nonsense")
      get "settings", params: { account_id: @account }
      expect(assigns[:js_env][:help_link_name]).to eq "Clippy"
      expect(assigns[:js_env][:help_link_icon]).to eq "paperclip"
    end

    it "orders desc announcements" do
      account_with_admin_logged_in
      Timecop.freeze do
        account_notification(account: @account, message: "Announcement 1", created_at: 1.minute.ago)
        @a1 = @announcement
        account_notification(account: @account, message: "Announcement 2", created_at: Time.zone.now)
        @a2 = @announcement
      end
      get "settings", params: { account_id: @account.id }
      expect(response).to be_successful
      expect(assigns[:announcements].first.id).to eq @a1.id
      expect(assigns[:announcements].last.id).to eq @a2.id
    end

    context "sharding" do
      specs_require_sharding

      it "loads even from the wrong shard" do
        account_with_admin_logged_in

        @shard1.activate do
          get "settings", params: { account_id: @account }
          expect(response).to be_successful
        end
      end
    end

    context "external_integration_keys" do
      before(:once) do
        ExternalIntegrationKey.key_type :external_key0, rights: { write: true }
        ExternalIntegrationKey.key_type :external_key1, rights: { write: false }
        ExternalIntegrationKey.key_type :external_key2, rights: { write: true }
      end

      before do
        user_factory
        user_session(@user)
        @account = Account.create!
        Account.site_admin.account_users.create!(user: @user)

        @eik = ExternalIntegrationKey.new
        @eik.context = @account
        @eik.key_type = :external_key0
        @eik.key_value = "42"
        @eik.save
      end

      it "loads account external integration keys" do
        get "settings", params: { account_id: @account }
        expect(response).to be_successful

        external_integration_keys = assigns[:external_integration_keys]
        expect(external_integration_keys).to have_key(:external_key0)
        expect(external_integration_keys).to have_key(:external_key1)
        expect(external_integration_keys).to have_key(:external_key2)
        expect(external_integration_keys[:external_key0]).to eq @eik
      end

      it "creates a new external integration key" do
        key_value = "2142"
        post "update", params: { id: @account.id,
                                 account: { external_integration_keys: {
                                   external_key0: "42",
                                   external_key2: key_value
                                 } } }
        @account.reload
        eik = @account.external_integration_keys.where(key_type: :external_key2).first
        expect(eik).to_not be_nil
        expect(eik.key_value).to eq "2142"
      end

      it "updates an existing external integration key" do
        key_value = "2142"
        post "update", params: { id: @account.id,
                                 account: { external_integration_keys: {
                                   external_key0: key_value,
                                   external_key1: key_value,
                                   external_key2: key_value
                                 } } }
        @account.reload

        # Should not be able to edit external_key1.  The user does not have the rights.
        eik = @account.external_integration_keys.where(key_type: :external_key1).first
        expect(eik).to be_nil

        eik = @account.external_integration_keys.where(key_type: :external_key0).first
        expect(eik.id).to eq @eik.id
        expect(eik.key_value).to eq "2142"
      end

      it "deletes an external integration key when not provided or the value is blank" do
        post "update", params: { id: @account.id,
                                 account: { external_integration_keys: {
                                   external_key0: nil
                                 } } }
        expect(@account.external_integration_keys.count).to eq 0
      end
    end
  end

  def admin_logged_in(account)
    user_session(user_factory)
    Account.site_admin.account_users.create!(user: @user)
    account_with_admin_logged_in(account:)
  end

  describe "terms of service" do
    before do
      @account = Account.create!
      course_with_teacher(account: @account)
      c1 = @course
      course_with_teacher(course: c1)
      @student = User.create
      c1.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
      c1.save
    end

    it "returns the terms of service content" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")

      admin_logged_in(@account)
      get "terms_of_service", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"content":"custom content"/)
    end

    it "returns the terms of service content as teacher" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")

      user_session(@teacher)
      get "terms_of_service", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"content":"custom content"/)
    end

    it "returns the terms of service content as student" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")

      user_session(@student)
      get "terms_of_service", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"content":"custom content"/)
    end

    it "returns default self_registration_type" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")

      remove_user_session
      get "terms_of_service", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"self_registration_type":"none"/)
    end

    it "returns other self_registration_type" do
      @account.update_terms_of_service(terms_type: "custom", content: "custom content")
      @account.canvas_authentication_provider.update_attribute(:self_registration, "observer")

      remove_user_session
      get "terms_of_service", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"self_registration_type":"observer"/)
    end
  end

  describe "help links" do
    before do
      account_with_admin_logged_in
      @account.settings[:custom_help_links] = [
        {
          id: "link1",
          text: "Custom Link!",
          subtext: "Custom subtext",
          url: "https://canvas.instructure.com/guides",
          type: "custom",
          available_to: %w[user student teacher],
        },
      ]
      @account.save
      course_with_teacher(account: @account)
      course_with_student(course: @course)
    end

    it "returns default help links" do
      Setting.set("show_feedback_link", "true")
      get "help_links", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"help_link_name":"Help"/)
      expect(response.body).to match(/"help_link_icon":"help"/)
      expect(response.body).to match(/"id":"report_a_problem"/)
      expect(response.body).to match(/"id":"instructor_question"/)
      expect(response.body).to match(/"id":"search_the_canvas_guides"/)
      expect(response.body).to match(/"type":"default"/)
      expect(response.body).to_not match(/"id":"covid"/)
    end

    context "with featured_help_links enabled" do
      it "returns the covid help link as a default" do
        Account.site_admin.enable_feature!(:featured_help_links)
        get "help_links", params: { account_id: @account.id }
        expect(response).to be_successful
        expect(response.body).to match(/"id":"covid"/)
      end
    end

    it "returns custom help links" do
      @account.settings[:help_link_name] = "Help and Policies"
      @account.settings[:help_link_icon] = "paperclip"
      @account.save
      get "help_links", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"help_link_name":"Help and Policies"/)
      expect(response.body).to match(/"help_link_icon":"paperclip"/)
      expect(response.body).to match(/"id":"link1"/)
      expect(response.body).to match(/"type":"custom"/)
      expect(response.body).to match(%r{"url":"https://canvas.instructure.com/guides"})
    end

    it "returns the help links as student" do
      user_session(@student)
      get "help_links", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"help_link_name":"Help"/)
    end

    it "returns the help links as teacher" do
      user_session(@teacher)
      get "help_links", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/"help_link_name":"Help"/)
    end
  end

  describe "manually_created_courses_account" do
    it "returns unauthorized if there's no user" do
      get "manually_created_courses_account"
      assert_unauthorized
    end

    it "returns the account with lots of detail if user has :read on the account" do
      account_with_admin_logged_in(active_all: true)

      get "manually_created_courses_account"
      expect(response).to be_successful
      account = json_parse(response.body)
      expect(account["name"]).to eq("Manually-Created Courses")
      expect(account["default_storage_quota_mb"]).to be(500)
    end

    it "returns limited details about the account to students" do
      course_with_student_logged_in(active_all: true)

      get "manually_created_courses_account"
      expect(response).to be_successful
      account = json_parse(response.body)
      expect(account["name"]).to eq("Manually-Created Courses")
      expect(account["default_storage_quota_mb"]).to be_nil
    end
  end

  describe "#statistics" do
    before do
      @account = Account.create!
      @sub1 = @account.sub_accounts.create!
      @sub2 = @account.sub_accounts.create!
      @ssub1 = @sub1.sub_accounts.create!
      @cr = course_factory(account: @account, course_name: "root")
      @c1 = course_factory(account: @sub1, course_name: "sc1")
      @c2 = course_factory(account: @sub2, course_name: "sc2")
      @c1_1 = course_factory(account: @ssub1, course_name: "ssc1")
    end

    it "does not allow sibling sub to view another siblings courses" do
      admin_logged_in(@sub1)
      get "statistics", params: { account_id: @sub1.id }
      expect(assigns(:recently_created_courses).to_a).not_to eq([@c2])
    end

    it "does not allow child to see parents created courses" do
      admin_logged_in(@sub2)
      get "statistics", params: { account_id: @sub2.id }
      expect(assigns(:recently_created_courses).to_a).to eq([@c2])
      expect(assigns(:recently_created_courses).to_a).not_to eq([@cr])
    end

    it "returns courses created by children and grandchildren" do
      admin_logged_in(@account)
      get "statistics", params: { account_id: @account.id }
      expect(assigns(:recently_created_courses).to_a).to match_array([@c1_1, @c1, @c2, @cr])
    end

    it "returns courses created by self and children" do
      admin_logged_in(@sub1)
      get "statistics", params: { account_id: @sub1.id }
      expect(assigns(:recently_created_courses).to_a).to match_array([@c1, @c1_1])
    end

    it "does not return deleted courses" do
      admin_logged_in(@sub1)
      @c1.update!(workflow_state: "deleted")
      get "statistics", params: { account_id: @sub1.id }
      expect(assigns(:recently_created_courses).to_a).to match_array([@c1_1])
    end
  end

  describe "#account_courses" do
    before do
      @account = Account.create!
      @c1 = course_factory(account: @account, course_name: "foo", sis_source_id: 42)
      @c2 = course_factory(account: @account, course_name: "bar", sis_source_id: 31)
    end

    it "does not allow get a list of courses with no permissions" do
      role = custom_account_role "non_course_reader", account: @account
      u = User.create(name: "billy bob")
      user_session(u)
      @account.role_overrides.create!(permission: "read_course_list",
                                      enabled: false,
                                      role:)
      @account.account_users.create!(user: u, role:)
      get "courses_api", params: { account_id: @account.id }
      assert_unauthorized
    end

    it "gets a list of courses" do
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(response.body).to match(/#{@c1.id}/)
      expect(response.body).to match(/#{@c2.id}/)
    end

    it "does not set pagination total_pages/last page link" do
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, per_page: 1 }

      expect(response).to be_successful
      expect(response.headers.to_a.find { |a| a.first.downcase == "link" }.last).to_not include("last")
    end

    it "sets pagination total_pages/last page link if includes ui_invoked is set" do
      Setting.set("ui_invoked_count_pages", "true")
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, per_page: 1, include: ["ui_invoked"] }

      expect(response).to be_successful
      expect(response.headers.to_a.find { |a| a.first.downcase == "link" }.last).to include("last")
    end

    it "properly removes sections from includes" do
      @s1 = @course.course_sections.create!
      @course.enroll_student(user_factory(active_all: true), section: @s1, allow_multiple_enrollments: true)

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, include: [:sections] }

      expect(response).to be_successful
      expect(response.body).not_to match(/sections/)
    end

    it "is able to sort courses by name ascending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "course_name", order: "asc" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"apple".+"name":"bar".+"name":"foo".+"name":"xylophone"/)
    end

    it "is able to sort courses by name descending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "course_name", order: "desc" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"xylophone".+"name":"foo".+"name":"bar".+"name":"apple"/)
    end

    it "is able to sort courses by id ascending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "sis_course_id", order: "asc" }

      expect(response).to be_successful
      expect(response.body).to match(/"sis_course_id":"30".+"sis_course_id":"31".+"sis_course_id":"42".+"sis_course_id":"52"/)
    end

    it "is able to sort courses by id descending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @account, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "sis_course_id", order: "desc" }

      expect(response).to be_successful
      expect(response.body).to match(/"sis_course_id":"52".+"sis_course_id":"42".+"sis_course_id":"31".+"sis_course_id":"30"/)
    end

    it "is able to sort courses by teacher ascending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate { user_factory(name: "Zach Zachary") }
      enrollment = @c3.enroll_user(user, "TeacherEnrollment")
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = "active"
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate { user_factory(name: "Example Another") }
      enrollment2 = @c3.enroll_user(user2, "TeacherEnrollment")
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = "active"
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: "Teach Teacherson", course: course_factory(account: @account, course_name: "xylophone", sis_source_id: 52))

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "teacher", order: "asc" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"apple".+"name":"xylophone".+"name":"foo".+"name":"bar"/)
    end

    it "is able to sort courses by teacher descending" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate { user_factory(name: "Zach Zachary") }
      enrollment = @c3.enroll_user(user, "TeacherEnrollment")
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = "active"
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate { user_factory(name: "Example Another") }
      enrollment2 = @c3.enroll_user(user2, "TeacherEnrollment")
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = "active"
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: "Teach Teacherson", course: course_factory(account: @account, course_name: "xylophone", sis_source_id: 52))

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "teacher", order: "desc" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"bar".+"name":"foo".+"name":"xylophone".+"name":"apple"/)
    end

    it "is able to sort courses by subaccount ascending" do
      @account.name = "Default"
      @account.save

      @a3 = Account.create!
      @a3.name = "Whatever University"
      @a3.root_account_id = @account.id
      @a3.parent_account_id = @account.id
      @a3.workflow_state = "active"
      @a3.save

      @a4 = Account.create!
      @a4.name = "A University"
      @a4.root_account_id = @account.id
      @a4.parent_account_id = @account.id
      @a4.workflow_state = "active"
      @a4.save

      @c3 = course_factory(account: @a3, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @a4, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "subaccount", order: "asc" }

      expect(response).to be_successful
      expect(response.body).to match(/"sis_course_id":"52".+"sis_course_id":"42".+"sis_course_id":"31".+"sis_course_id":"30"/)
    end

    it "is able to sort courses by subaccount descending" do
      @account.name = "Default"
      @account.save

      @a3 = Account.create!
      @a3.name = "Whatever University"
      @a3.root_account_id = @account.id
      @a3.parent_account_id = @account.id
      @a3.workflow_state = "active"
      @a3.save

      @a4 = Account.create!
      @a4.name = "A University"
      @a4.root_account_id = @account.id
      @a4.parent_account_id = @account.id
      @a4.workflow_state = "active"
      @a4.save

      @c3 = course_factory(account: @a3, course_name: "apple", sis_source_id: 30)
      @c4 = course_factory(account: @a4, course_name: "xylophone", sis_source_id: 52)
      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "subaccount", order: "desc" }

      expect(response).to be_successful
      expect(response.body).to match(/"sis_course_id":"30".+"sis_course_id":"31".+"sis_course_id":"42".+"sis_course_id":"52"/)
    end

    it "counts enrollments correctly" do
      admin_logged_in(@account)
      student1 = user_factory
      student2 = user_factory
      @c1.enroll_user(student1, "StudentEnrollment", enrollment_state: "active")
      @c1.enroll_user(student2, "StudentEnrollment", enrollment_state: "active")
      @c2.enroll_user(student1, "StudentEnrollment", enrollment_state: "active")
      get "courses_api", params: { account_id: @account.id, include: ["total_students"] }

      expect(response).to be_successful
      res = response.parsed_body
      expect(res.detect { |r| r["id"] == @c1.id }["total_students"]).to eq(2)
      expect(res.detect { |r| r["id"] == @c2.id }["total_students"]).to eq(1)
    end

    context "sorting by term" do
      let(:letters_in_random_order) { "daqwds".chars }

      before do
        @account = Account.create!
        create_courses(letters_in_random_order.map do |i|
          { enrollment_term_id: @account.enrollment_terms.create!(name: i).id }
        end,
                       account: @account)
        admin_logged_in(@account)
      end

      it "is able to sort courses by term ascending" do
        get "courses_api", params: { account_id: @account.id, sort: "term", order: "asc", include: ["term"] }

        expect(response).to be_successful
        term_names = json_parse(response.body).map { |c| c["term"]["name"] }
        expect(term_names).to eq(letters_in_random_order.sort)
      end

      it "is able to sort courses by term descending" do
        get "courses_api", params: { account_id: @account.id, sort: "term", order: "desc", include: ["term"] }

        expect(response).to be_successful
        term_names = json_parse(response.body).map { |c| c["term"]["name"] }
        expect(term_names).to eq(letters_in_random_order.sort.reverse)
      end
    end

    it "is able to search by teacher" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate { user_factory(name: "Zach Zachary") }
      enrollment = @c3.enroll_user(user, "TeacherEnrollment")
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = "active"
      enrollment.save!
      @c3.reload

      user2 = @c3.shard.activate { user_factory(name: "Example Another") }
      enrollment2 = @c3.enroll_user(user2, "TeacherEnrollment")
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = "active"
      enrollment2.save!
      @c3.reload

      @c4 = course_with_teacher(name: "Teach Teacherson", course: course_factory(account: @account, course_name: "xylophone", sis_source_id: 52))

      @c5 = course_with_teacher(name: "Teachy McTeacher", course: course_factory(account: @account, course_name: "hot dog eating", sis_source_id: 63))

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "teacher", order: "asc", search_by: "teacher", search_term: "teach" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"hot dog eating".+"name":"xylophone"/)
    end

    it "filters course search by teacher enrollment state" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      user = @c3.shard.activate { user_factory(name: "rejected") }
      enrollment = @c3.enroll_user(user, "TeacherEnrollment")
      user.save!
      enrollment.course = @c3
      enrollment.workflow_state = "rejected"
      enrollment.save!

      user2 = @c3.shard.activate { user_factory(name: "inactive") }
      enrollment2 = @c3.enroll_user(user2, "TeacherEnrollment")
      user2.save!
      enrollment2.course = @c3
      enrollment2.workflow_state = "inactive"
      enrollment2.save!

      user3 = @c3.shard.activate { user_factory(name: "completed") }
      enrollment3 = @c3.enroll_user(user, "TeacherEnrollment")
      user3.save!
      enrollment3.course = @c3
      enrollment3.workflow_state = "completed"
      enrollment3.save!

      user4 = @c3.shard.activate { user_factory(name: "deleted") }
      enrollment4 = @c3.enroll_user(user2, "TeacherEnrollment")
      user4.save!
      enrollment4.course = @c3
      enrollment4.workflow_state = "deleted"
      enrollment4.save!

      @c4 = course_with_teacher(name: "Teach Teacherson", course: course_factory(account: @account, course_name: "xylophone", sis_source_id: 52))
      @c5 = course_with_teacher(name: "Teachy McTeacher", course: course_factory(account: @account, course_name: "hot dog eating", sis_source_id: 63))

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "sis_course_id", order: "asc", search_by: "teacher", search_term: "teach" }

      expect(response.parsed_body.length).to eq 2
    end

    it "excludes teachers that don't have an active enrollment workflow state" do
      user = user_factory(name: "rejected")
      enrollment = @c1.enroll_user(user, "TeacherEnrollment")
      enrollment.update!(workflow_state: "rejected")

      user2 = user_factory(name: "inactive")
      enrollment2 = @c1.enroll_user(user2, "TeacherEnrollment")
      enrollment2.update!(workflow_state: "inactive")

      user3 = user_factory(name: "completed")
      enrollment3 = @c1.enroll_user(user3, "TeacherEnrollment")
      enrollment3.update!(workflow_state: "completed")

      user4 = user_factory(name: "deleted")
      enrollment4 = @c1.enroll_user(user4, "TeacherEnrollment")
      enrollment4.update!(workflow_state: "deleted")

      user5 = user_factory(name: "Teachy McTeacher")
      enrollment5 = @c1.enroll_user(user5, "TeacherEnrollment")
      enrollment5.update!(workflow_state: "active")

      admin_logged_in(@account)

      get "courses_api", params: { account_id: @account.id,
                                   sort: "sis_course_id",
                                   order: "asc",
                                   search_by: "course",
                                   include: ["active_teachers"] }

      expect(response.body).not_to match(/"display_name":"rejected"/)
      expect(response.body).not_to match(/"display_name":"inactive"/)
      expect(response.body).not_to match(/"display_name":"completed"/)
      expect(response.body).not_to match(/"display_name":"deleted"/)
      expect(response.body).to match(/"display_name":"Teachy McTeacher"/)
    end

    it "is able to search by course name" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30)

      @c4 = course_with_teacher(name: "Teach Teacherson", course: course_factory(account: @account, course_name: "Apps", sis_source_id: 52))

      @c5 = course_with_teacher(name: "Teachy McTeacher", course: course_factory(account: @account, course_name: "cappuccino", sis_source_id: 63))

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "course_name", order: "asc", search_by: "course", search_term: "aPp" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"apple".+"name":"Apps".+"name":"cappuccino"/)
      expect(response.body).not_to match(/"name":"apple".+"name":"Apps".+"name":"bar".+"name":"cappuccino".+"name":"foo"/)
    end

    it "is able to search by course sis id" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: 30_012)

      @c4 = course_with_teacher(name: "Teach Teacherson", course: course_factory(account: @account, course_name: "Apps", sis_source_id: 3002))

      @c5 = course_with_teacher(name: "Teachy McTeacher", course: course_factory(account: @account, course_name: "cappuccino", sis_source_id: 63))

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "course_name", order: "asc", search_by: "course", search_term: "300" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"apple".+"name":"Apps"/)
      expect(response.body).not_to match(/"name":"apple".+"name":"Apps".+"name":"bar".+"name":"cappuccino".+"name":"foo"/)
    end

    it "is able to search by a course sis id that is > than bigint max" do
      @c3 = course_factory(account: @account, course_name: "apple", sis_source_id: "9223372036854775808")

      @c4 = course_with_teacher(name: "Teach Teacherson", course: course_factory(account: @account, course_name: "Apps", sis_source_id: 3002))

      admin_logged_in(@account)
      get "courses_api", params: { account_id: @account.id, sort: "course_name", order: "asc", search_by: "course", search_term: "9223372036854775808" }

      expect(response).to be_successful
      expect(response.body).to match(/"name":"apple"/)
      expect(response.body).not_to match(/"name":"Apps"/)
    end

    context "sharding" do
      specs_require_sharding

      it "excludes inactive teachers regardless of requestor's active shard" do
        user = user_factory(name: "rejected")
        enrollment = @c1.enroll_user(user, "TeacherEnrollment")
        enrollment.update!(workflow_state: "rejected")

        user2 = user_factory(name: "inactive")
        enrollment2 = @c1.enroll_user(user2, "TeacherEnrollment")
        enrollment2.update!(workflow_state: "inactive")

        user3 = user_factory(name: "Teachy McTeacher")
        enrollment3 = @c1.enroll_user(user3, "TeacherEnrollment")
        enrollment3.update!(workflow_state: "active")

        @shard1.activate { @user4 = user_factory(name: "Cross Shard") }
        enrollment4 = @c1.enroll_user(@user4, "TeacherEnrollment")
        enrollment4.update!(workflow_state: "active")

        admin_logged_in(@account)

        @shard1.activate do
          get "courses_api", params: { account_id: @account.id,
                                       sort: "sis_course_id",
                                       order: "asc",
                                       search_by: "course",
                                       include: ["active_teachers"] }
        end

        expect(response.body).not_to match(/"display_name":"rejected"/)
        expect(response.body).not_to match(/"display_name":"inactive"/)
        expect(response.body).to match(/"display_name":"Teachy McTeacher"/)
        expect(response.body).to match(/"display_name":"Cross Shard"/)
      end

      it "excludes cross-shard teachers without an active enrollment workflow state" do
        user = user_factory(name: "rejected")
        enrollment = @c1.enroll_user(user, "TeacherEnrollment")
        enrollment.update!(workflow_state: "rejected")

        user2 = user_factory(name: "inactive")
        enrollment2 = @c1.enroll_user(user2, "TeacherEnrollment")
        enrollment2.update!(workflow_state: "inactive")

        user3 = user_factory(name: "Teachy McTeacher")
        enrollment3 = @c1.enroll_user(user3, "TeacherEnrollment")
        enrollment3.update!(workflow_state: "active")

        @shard1.activate { @user4 = user_factory(name: "Cross Shard") }
        enrollment4 = @c1.enroll_user(@user4, "TeacherEnrollment")
        enrollment4.update!(workflow_state: "active")

        admin_logged_in(@account)

        get "courses_api", params: { account_id: @account.id,
                                     sort: "sis_course_id",
                                     order: "asc",
                                     search_by: "course",
                                     include: ["active_teachers"] }

        expect(response.body).not_to match(/"display_name":"rejected"/)
        expect(response.body).not_to match(/"display_name":"inactive"/)
        expect(response.body).to match(/"display_name":"Teachy McTeacher"/)
        expect(response.body).to match(/"display_name":"Cross Shard"/)
      end

      it "counts enrollments correctly cross-shard" do
        admin_logged_in(@account)
        student1 = user_factory
        student2 = user_factory
        @c1.enroll_user(student1, "StudentEnrollment", enrollment_state: "active")
        @c1.enroll_user(student2, "StudentEnrollment", enrollment_state: "active")
        @c2.enroll_user(student1, "StudentEnrollment", enrollment_state: "active")
        @shard1.activate { get "courses_api", params: { account_id: @account.id, include: ["total_students"] } }

        expect(response).to be_successful
        res = response.parsed_body
        expect(res.detect { |r| r["id"] == @c1.global_id }["total_students"]).to eq(2)
        expect(res.detect { |r| r["id"] == @c2.global_id }["total_students"]).to eq(1)
      end
    end
  end

  describe "#eportfolio_moderation" do
    before do
      account_with_admin_logged_in

      author.eportfolios.create!(name: "boring")
      author.eportfolios.create!(name: "maybe spam", spam_status: "flagged_as_possible_spam")
      author.eportfolios.create!(name: "spam", spam_status: "marked_as_spam")
      author.eportfolios.create!(name: "not spam", spam_status: "marked_as_safe")
    end

    let(:author) do
      user = User.create!
      user.user_account_associations.create!(account: @account)
      user
    end

    let(:vanished_author) do
      user = User.create!
      user.user_account_associations.create!(account: @account)
      user.destroy
      user
    end

    let(:returned_portfolios) { assigns[:eportfolios] }

    it "returns eportfolios that have been auto-flagged as spam, or manually marked as spam/safe" do
      get "eportfolio_moderation", params: { account_id: @account.id }
      expect(returned_portfolios.count).to eq 3
    end

    it "ignores portfolios belonging to deleted users" do
      vanished_eportfolio = Eportfolio.create!(user_id: vanished_author.id, name: "hello", spam_status: "marked_as_spam")

      get "eportfolio_moderation", params: { account_id: @account.id }
      expect(returned_portfolios).not_to include(vanished_eportfolio)
    end

    it "returns flagged_as_possible_spam results, then marked_as_spam, then marked_as_safe" do
      get "eportfolio_moderation", params: { account_id: @account.id }
      expect(returned_portfolios.pluck(:name)).to eq ["maybe spam", "spam", "not spam"]
    end

    it "excludes results from authors who have no portfolios marked as possible or definitive spam" do
      safe_user = User.create!
      safe_user.user_account_associations.create!(account: @account)
      safe_eportfolio = safe_user.eportfolios.create!(name: ":)")
      safe_eportfolio.update!(spam_status: "marked_as_safe")

      get "eportfolio_moderation", params: { account_id: @account.id }
      expect(returned_portfolios.pluck(:id)).not_to include(safe_eportfolio.id)
    end

    context "pagination" do
      before do
        stub_const("AccountsController::EPORTFOLIO_MODERATION_PER_PAGE", 2)
      end

      it "does not return more than the specified results per page" do
        get "eportfolio_moderation", params: { account_id: @account.id }
        expect(returned_portfolios.count).to eq 2
      end

      it "returns the first page of results if no 'page' param is given" do
        get "eportfolio_moderation", params: { account_id: @account.id }
        expect(returned_portfolios.pluck(:name)).to eq ["maybe spam", "spam"]
      end

      it "paginates using the 'page' param if supplied" do
        get "eportfolio_moderation", params: { account_id: @account.id, page: 2 }
        expect(returned_portfolios.pluck(:name)).to eq ["not spam"]
      end
    end
  end

  describe("manageable_accounts") do
    before :once do
      @account1 = Account.create!(name: "Account 1", root_account: Account.default)
      account_with_admin(account: @account1)
      @admin1 = @admin
      @account2 = Account.create!(name: "Account 2", root_account: Account.default)
      account_admin_user(account: @account2, user: @admin1)
      @subaccount1 = @account1.sub_accounts.create!(name: "Subaccount 1")
    end

    it "includes all top-level and subaccounts" do
      user_session @admin1
      get "manageable_accounts"
      accounts = json_parse(response.body)
      expect(accounts[0]["name"]).to eq "Account 1"
      expect(accounts[1]["name"]).to eq "Subaccount 1"
      expect(accounts[2]["name"]).to eq "Account 2"
    end

    it "does not include accounts where admin doesn't have manage_courses or create_courses permissions" do
      Account.default.disable_feature!(:granular_permissions_manage_courses)
      account3 = Account.create!(name: "Account 3", root_account: Account.default)
      account_admin_user_with_role_changes(account: account3, user: @admin1, role_changes: { manage_courses: false, create_courses: false })
      user_session @admin1
      get "manageable_accounts"
      accounts = json_parse(response.body)
      expect(accounts.length).to be 3
      accounts.each do |a|
        expect(a["name"]).not_to eq "Account 3"
      end
    end

    it "does not include accounts where admin doesn't have manage_courses_admin or create_courses permissions (granular permissions)" do
      Account.default.enable_feature!(:granular_permissions_manage_courses)
      account3 = Account.create!(name: "Account 3", root_account: Account.default)
      account_admin_user_with_role_changes(
        account: account3,
        user: @admin1,
        role_changes: {
          manage_courses_admin: false,
          manage_courses_add: false
        }
      )
      user_session @admin1
      get "manageable_accounts"
      accounts = json_parse(response.body)
      expect(accounts.length).to be 3
      accounts.each { |a| expect(a["name"]).not_to eq "Account 3" }
    end

    it "returns an empty list for students" do
      student_in_course(active_all: true, account: @account1)
      user_session @student
      get "manageable_accounts"
      expect(response).to be_successful
      expect(json_parse(response.body).length).to be 0
    end
  end

  describe("course_creation_accounts") do
    context "sharding" do
      specs_require_sharding

      before { @user = user_factory(active_all: true) }

      it "succesfully returns empty result sets" do
        user_session @user
        get "course_creation_accounts"
        expect(response).to be_successful
        expect(json_parse(response.body)).to eq([])
      end

      it "returns properly paginated results" do
        4.times do |count|
          Account.create!(name: "Account #{count}", parent_account: Account.default).account_users.create!(user: @user)
        end
        user_session @user
        get "course_creation_accounts", params: { per_page: 2 }
        expect(response).to be_successful
        expect(json_parse(response.body).pluck("name")).to match_array(["Account 0", "Account 1"])
        get "course_creation_accounts", params: { per_page: 2, page: 2 }
        expect(json_parse(response.body).pluck("name")).to match_array(["Account 2", "Account 3"])
      end

      it "works for no_enrollments_can_create_courses account" do
        acc = Account.create!(name: "No enrollments")
        acc.update(settings: { no_enrollments_can_create_courses: true })
        usr = User.create!(root_account_ids: [acc.id])
        user_session usr
        get "course_creation_accounts"
        expect(response).to be_successful
        expect(json_parse(response.body).pluck("name")).to match_array(["Manually-Created Courses"])
        course_with_student(user: usr, active_all: true, account: Account.last)
        get "course_creation_accounts"
        expect(response).to be_successful
        expect(json_parse(response.body).pluck("name")).to be_empty
      end

      it "works fetching account associations across shards" do
        # sub account admin with creation rights
        Account.create!(name: "Sub Account", parent_account: Account.default).account_users.create!(user: @user)

        # sub sub account with no explicit creation rights
        Account.create!(name: "Sub Sub Account", parent_account: Account.last)

        # sub account admin with explicit lack of creation rights
        Account.create!(name: "Strange Account", parent_account: Account.default)
        Account.last.role_overrides.create! [{ role: admin_role, permission: "manage_courses_add", enabled: false }, { role: admin_role, permission: "manage_courses_admin", enabled: false }]
        Account.last.account_users.create!(user: @user)

        @shard2.activate do
          # alternative shard teacher enrollments with creation rights
          # MCC should appear only once for both of these
          Account.create!(name: "Teacher Creator #2").update(settings: { teachers_can_create_courses: true, students_can_create_courses: true })
          course_with_teacher(user: @user, active_all: true, account: Account.last)
          course_with_student(user: @user, active_all: true, account: Account.last)

          # alternative shard student enrollment with creation rights
          Account.create!(name: "Student Creator #2").update(settings: { students_can_create_courses: true })
          course_with_student(user: @user, active_all: true, account: Account.last)

          # alternative shard teacher enrollment with no creation rights
          Account.create!(name: "Teacher Whatever #2").update(settings: { students_can_create_courses: true })
          course_with_teacher(user: @user, active_all: true, account: Account.last)

          # alternative shard student enrollment with no creation rights
          Account.create!(name: "Student Whatever #2").update(settings: { teachers_can_create_courses: true })
          course_with_student(user: @user, active_all: true, account: Account.last)
        end

        Account.all.each do |acc|
          next if acc == Account.default || acc.root_account_id > 0

          acc.trust_links.create!(managing_account: Account.default)
          Account.default.trust_links.create!(managing_account: acc)
        end

        user_session @user
        get "course_creation_accounts"
        expect(response).to be_successful
        accounts = json_parse(response.body)
        expect(accounts.pluck("name")).to match_array(["Manually-Created Courses", "Manually-Created Courses", "Student Creator #2", "Sub Account", "Sub Sub Account", "Teacher Creator #2"])
        expect(accounts.pluck("name").length).to eq(accounts.pluck("id").uniq.length) # No, those are not actual duplicates
      end

      it "does not mix up an admin's student creation rights with actual admin rights" do
        Account.default.update(settings: { students_can_create_courses: true })
        Account.default.role_overrides.create! [{ role: admin_role, permission: "manage_courses_add", enabled: false }, { role: admin_role, permission: "manage_courses_admin", enabled: false }]
        Account.default.account_users.create!(user: @user)
        course_with_student(user: @user, active_all: true, account: Account.default)
        Account.create!(name: "Sub Account (shouldn't show up)", parent_account: Account.default)
        user_session @user
        get "course_creation_accounts"
        expect(response).to be_successful
        expect(json_parse(response.body).pluck("name")).to match_array(["Default Account", "Manually-Created Courses"])
      end
    end
  end

  describe "account_calendar_settings" do
    before :once do
      @account = Account.default
    end

    it "returns unauthorized if the user does not have manage_account_calendar_visibility permission" do
      account_admin_user_with_role_changes(account: @account, role_changes: { manage_account_calendar_visibility: false })
      user_session(@user)
      get "account_calendar_settings", params: { account_id: @account.id }

      expect(response).to be_unauthorized
    end

    it "renders a page and sets variables" do
      account_admin_user(account: @account)
      user_session(@user)
      get "account_calendar_settings", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(assigns["js_env"][:ACCOUNT_ID]).to be(@account.id)
    end

    it "adds account_calendars once to user's visited_tabs preference" do
      account_admin_user(account: @account)
      @user.set_preference(:visited_tabs, ["other_tab"])
      user_session(@user)
      get "account_calendar_settings", params: { account_id: @account.id }

      expect(response).to be_successful
      expect(@user.reload.get_preference(:visited_tabs)).to eq(%w[other_tab account_calendars])
    end

    it "emits account_calendars.settings.visit to statsd" do
      allow(InstStatsd::Statsd).to receive(:increment)
      account_admin_user(account: @account)
      user_session(@user)
      get "account_calendar_settings", params: { account_id: @account.id }

      expect(InstStatsd::Statsd).to have_received(:increment).once.with("account_calendars.settings.visit")
    end
  end
end
