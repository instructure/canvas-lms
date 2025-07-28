# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require "timecop"

describe ProfileController do
  let(:mfa_settings) { :disabled }
  let(:otp_via_sms) { false }

  before :once do
    course_with_teacher(active_all: true)
    user_with_pseudonym(active_user: true)
  end

  before do
    allow_any_instance_of(ProfileHelper).to receive(:current_mfa_settings).and_return(mfa_settings)
    allow_any_instance_of(Login::OtpHelper).to receive(:otp_via_sms_in_us_region?).and_return(otp_via_sms)
  end

  describe "show" do
    it "does not require an id for yourself" do
      user_session(@user)

      get "show"
      expect(response).to render_template("profile")
    end

    it "chains to settings when it's the same user" do
      user_session(@user)

      get "show", params: { user_id: @user.id }
      expect(response).to render_template("profile")
    end

    it "requires a password session when chaining to settings" do
      user_session(@user)
      session[:used_remember_me_token] = true

      get "show", params: { user_id: @user.id }
      expect(response).to redirect_to(login_url)
    end

    describe "other user's profile" do
      before do
        # to allow viewing other user's profile
        allow(@controller).to receive(:api_request?).and_return(true)
      end

      it "includes common contexts in @user_data" do
        user_session(@teacher)

        # teacher and user have a group and course in common
        group = group()
        group.add_user(@teacher, "accepted")
        group.add_user(@user, "accepted")
        student_in_course(user: @user, active_all: true)

        get "show", params: { user_id: @user.id }
        expect(assigns(:user_data)[:common_contexts].size).to be(2)
        expect(assigns(:user_data)[:common_contexts][0]["id"]).to eql(@course.id)
        expect(assigns(:user_data)[:common_contexts][0]["roles"]).to eql(["Student"])
        expect(assigns(:user_data)[:common_contexts][1]["id"]).to eql(group.id)
        expect(assigns(:user_data)[:common_contexts][1]["roles"]).to eql(["Member"])
      end

      it "does not include differentiation Tags in @user_data" do
        user_session(@teacher)
        student_in_course(user: @user, active_all: true)

        @non_collaborative_group_category = @course.group_categories.create!(name: "Test non collaborative", non_collaborative: true)
        @non_collaborative_group = @course.groups.create!(name: "Non Collaborative group", group_category: @non_collaborative_group_category)
        @non_collaborative_group.add_user(@user, "accepted")
        @non_collaborative_group.add_user(@teacher, "accepted")

        get "show", params: { user_id: @user.id }
        # Expect that the non-collaborative group is not included in the common contexts
        # The only common_context included is the course
        expect(assigns(:user_data)[:common_contexts].size).to be(1)
        expect(assigns(:user_data)[:common_contexts][0]["id"]).to eql(@course.id)
      end
    end
  end

  describe "update" do
    it "allows changing the default e-mail address and nothing else" do
      user_session(@user, @pseudonym)
      cc = @cc
      expect(cc.position).to eq 1
      cc2 = communication_channel(@user, { username: "email2@example.com", active_cc: true })
      expect(cc2.position).to eq 2
      put "update", params: { user_id: @user.id, default_email_id: cc2.id }, format: "json"
      expect(response).to be_successful
      expect(cc2.reload.position).to eq 1
      expect(cc.reload.position).to eq 2
    end

    it "clears email cache" do
      enable_cache do
        @user.email # prime cache
        user_session(@user, @pseudonym)
        @cc2 = communication_channel(@user, { username: "email2@example.com", active_cc: true })
        put "update", params: { user_id: @user.id, default_email_id: @cc2.id }, format: "json"
        expect(response).to be_successful
        expect(@user.email).to eq @cc2.path
      end
    end

    it "allows changing the default e-mail address and nothing else (name changing disabled)" do
      @account = Account.default
      @account.settings = { users_can_edit_name: false }
      @account.save!
      user_session(@user, @pseudonym)
      cc = @cc
      expect(cc.position).to eq 1
      cc2 = communication_channel(@user, { username: "email2@example.com", active_cc: true })
      expect(cc2.position).to eq 2
      put "update", params: { user_id: @user.id, default_email_id: cc2.id }, format: "json"
      expect(response).to be_successful
      expect(cc2.reload.position).to eq 1
      expect(cc.reload.position).to eq 2
    end

    it "does not let an unconfirmed e-mail address be set as default" do
      user_session(@user, @pseudonym)
      cc = @cc
      cc2 = communication_channel(@user, { username: "email2@example.com", cc_state: "unconfirmed" })
      put "update", params: { user_id: @user.id, default_email_id: cc2.id }, format: "json"
      expect(@user.email).to eq cc.path
    end

    it "does not allow a student view student profile to be edited" do
      user_session(@teacher)
      @fake_student = @course.student_view_student
      session[:become_user_id] = @fake_student.id

      put "update", params: { user_id: @fake_student.id }
      assert_unauthorized
    end
  end

  describe "personal pronouns" do
    before :once do
      @user.account.settings = { can_add_pronouns: true }
      @user.account.save!
    end

    describe "settings" do
      specs_require_sharding

      it "returns pronouns based on settings of the active account" do
        @user.update!(pronouns: "he_him")
        shard_one_account = @shard1.activate { Account.create!(name: "Shard1 Acc", settings: { can_add_pronouns: true }) }
        # other tests for pronouns don't use this because pronouns falls back on user.account
        allow(Account).to receive(:current_domain_root_account).and_return(shard_one_account)
        @shard1.activate do
          user_session(@user)
          get "settings", params: { user_id: @user.id }, format: "json"

          expect(response).to be_successful
          json = json_parse(response.body)
          expect(json["pronouns"]).to eq "He/Him"
        end
      end
    end

    describe "update" do
      it "allows changing pronouns" do
        user_session(@user, @pseudonym)
        expect(@user.pronouns).to be_nil
        put "update", params: { user: { pronouns: "  He/Him " } }, format: "json"
        expect(response).to be_successful
        @user.reload
        expect(@user["pronouns"]).to eq "he_him"
        expect(@user.pronouns).to eq "He/Him"
      end

      it "allows unsetting pronouns" do
        user_session(@user, @pseudonym)
        @user.pronouns = " Dude/Guy  "
        @user.save!
        expect(@user.pronouns).to eq "Dude/Guy"
        put "update", params: { user: { pronouns: "" } }, format: "json"
        expect(response).to be_successful
        @user.reload
        expect(@user.pronouns).to be_nil
      end

      it "does not allow setting pronouns not on the approved list" do
        user_session(@user, @pseudonym)
        expect(@user.pronouns).to be_nil
        put "update", params: { user: { pronouns: "Pro/Noun" } }, format: "json"
        expect(response).to be_successful
        @user.reload
        expect(@user.pronouns).to be_nil
      end

      it "does not allow setting pronouns if the setting is disabled" do
        @user.account.settings[:can_change_pronouns] = false
        @user.account.save!
        user_session(@user, @pseudonym)
        put "update", params: { user: { pronouns: "Pro/Noun" } }, format: "json"
        expect(response).to be_successful
        @user.reload
        expect(@user.pronouns).to be_nil
      end
    end
  end

  describe "update_profile" do
    before :once do
      user_with_pseudonym
      @user.register
    end

    before do
      # reload to catch the user change
      user_session(@user, @pseudonym.reload)
    end

    it "alert is set to success when profile update is successful" do
      put "update_profile",
          params: { user: { short_name: "Monsturd", name: "Jenkins" },
                    user_profile: { bio: "...", title: "!!!" } },
          format: "json"
      expect(flash[:success]).to be_truthy
    end

    it "alert is set to failed when user validation fails" do
      name = "a" * 1000
      put "update_profile",
          params: { user: { short_name: name, name: "Jenkins" },
                    user_profile: { bio: "...", title: "!!!" } },
          format: "json"
      expect(flash[:success]).to be_falsey
    end

    it "alert is set to failed when user profile validation fails" do
      Account.default.settings[:enable_name_pronunciation] = true
      Account.default.settings[:allow_name_pronunciation_edit_for_students] = true
      Account.default.save!
      # requires base role of student to edit
      student_in_course(active_all: true)
      user_session(@student)
      pronunciation = "a" * 1000
      put "update_profile",
          params: { user: { short_name: "Monsturd", name: "Jenkins" },
                    user_profile: { bio: "...", title: "!!!", pronunciation: } },
          format: "json"
      expect(flash[:success]).to be_falsey
    end

    it "lets you change your short_name and profile information" do
      put "update_profile",
          params: { user: { short_name: "Monsturd", name: "Jenkins" },
                    user_profile: { bio: "...", title: "!!!" } },
          format: "json"
      expect(response).to be_successful

      @user.reload
      expect(@user.short_name).to eql "Monsturd"
      expect(@user.name).not_to eql "Jenkins"
      expect(@user.profile.bio).to eql "..."
      expect(@user.profile.title).to eql "!!!"
    end

    it "does not let you change your short_name information if you are not allowed" do
      account = Account.default
      account.settings = { users_can_edit_name: false }
      account.save!

      old_name = @user.short_name
      old_title = @user.profile.title
      put "update_profile",
          params: { user: { short_name: "Monsturd", name: "Jenkins" },
                    user_profile: { bio: "...", title: "!!!" } },
          format: "json"
      expect(response).to be_successful

      @user.reload
      expect(@user.short_name).to eql old_name
      expect(@user.name).not_to eql "Jenkins"
      expect(@user.profile.bio).to eql "..."
      expect(@user.profile.title).to eql old_title
    end

    it "does not let you change your profile information if you are not allowed" do
      account = Account.default
      account.settings = { users_can_edit_profile: false }
      account.save!

      old_bio = @user.profile.bio
      put "update_profile",
          params: { user: { short_name: "Monsturd", name: "Jenkins" },
                    user_profile: { bio: "...", title: "!!!" } },
          format: "json"
      expect(response).to be_successful

      @user.reload
      expect(@user.profile.bio).to eql old_bio
    end

    it "lets you set visibility on user_services" do
      @user.user_services.create! service: "skype", service_user_name: "user", service_user_id: "user", visible: true
      @user.user_services.create! service: "diigo", service_user_name: "user", service_user_id: "user", visible: false

      put "update_profile",
          params: { user_profile: { bio: "..." },
                    user_services: { diigo: "1", skype: "false" } },
          format: "json"
      expect(response).to be_successful

      @user.reload
      expect(@user.user_services.where(service: "skype").first.visible?).to be_falsey
      expect(@user.user_services.where(service: "diigo").first.visible?).to be_truthy
    end

    it "lets you set your profile links" do
      put "update_profile",
          params: { user_profile: { bio: "..." },
                    link_urls: ["example.com", "foo.com", "", "///////invalid"],
                    link_titles: ["Example.com", "Foo", "", "invalid"] },
          format: "json"
      expect(response).to be_successful

      @user.reload
      expect(@user.profile.links.map { |l| [l.url, l.title] }).to eq [
        %w[http://example.com Example.com],
        %w[http://foo.com Foo]
      ]
    end

    it "lets you remove set pronouns" do
      @user.update(pronouns: "he_him")
      @user.account.settings[:can_add_pronouns] = true
      @user.account.save!

      expect(@user.pronouns).to eq("He/Him")
      put "update_profile", params: { pronouns: nil }, format: "json"
      expect(@user.reload.pronouns).to be_nil
      expect(response).to be_successful
    end
  end

  describe "content_shares" do
    before :once do
      teacher_in_course(active_all: true)
      student_in_course(active_all: true)
    end

    it "shows if user has any non-student enrollments" do
      allow(DynamicSettings).to receive(:find).and_return(DynamicSettings::FallbackProxy.new({ "base_url" => "the_ccv_url" }))
      user_session(@teacher)
      get "content_shares", params: { user_id: @teacher.id }
      expect(response).to render_template("content_shares")
      expect(assigns.dig(:js_env, :COMMON_CARTRIDGE_VIEWER_URL)).to eq("the_ccv_url")
    end

    it "shows if the user has an account membership" do
      user_session(account_admin_user)
      get "content_shares", params: { user_id: @admin.id }
      expect(response).to render_template("content_shares")
    end

    it "404s if user has only student enrollments" do
      user_session(@student)
      get "content_shares", params: { user_id: @student.id }
      expect(response).to be_not_found
    end
  end

  describe "GET #qr_mobile_login" do
    context "mobile_qr_login setting is enabled" do
      before :once do
        Account.default.settings[:mobile_qr_login_is_enabled] = true
        Account.default.save
      end

      it "renders empty html layout" do
        user_session(@user)
        get "qr_mobile_login"
        expect(response).to render_template "layouts/application"
        expect(response.body).to eq ""
      end

      it "redirects to login if no active session" do
        get "qr_mobile_login"
        expect(response).to redirect_to "/login"
      end

      it "404s if IMP is missing" do
        allow_any_instance_of(ProfileController).to receive(:instructure_misc_plugin_available?).and_return(false)
        user_session(@user)
        get "qr_mobile_login"
        expect(response).to be_not_found
      end
    end

    context "mobile_qr_login setting is disabled" do
      before :once do
        Account.default.settings[:mobile_qr_login_is_enabled] = false
        Account.default.save
      end

      it "404s" do
        user_session(@user)
        get "qr_mobile_login"
        expect(response).to be_not_found
      end
    end
  end

  describe "communication" do
    before :once do
      # shouldn't be used, but to make sure it's not equal to any of the other
      # time zones in play
      Time.use_zone("UTC") do
        # time zones of interest
        @central = ActiveSupport::TimeZone.us_zones.find { |zone| zone.name == "Central Time (US & Canada)" }

        # set up user in central time (different than the specific time zones
        # referenced in set_send_at)
        @account = Account.create!(name: "new acct")
        @user = user_with_pseudonym(account: @account)
        @user.time_zone = @central.name
        @user.pseudonym.update_attribute(:account, @account)
        @user.save
      end
    end

    context "when rendering the full view" do
      render_views

      it "sets the appropriate page title" do
        user_session(@user)
        get "communication"
        expect(response.body).to include "<title>Notification Settings</title>"
      end
    end

    describe "js_env" do
      context "register_cc_tabs" do
        let(:mfa_settings) { :required }
        let(:otp_via_sms) { true }

        it "should include 'sms'" do
          user_session(@user)

          get "settings"

          expect(assigns[:js_env][:register_cc_tabs]).to include("sms")
        end

        it "should include 'slack'" do
          @user.account.enable_feature! :slack_notifications
          user_session(@user)

          get "settings"

          expect(assigns[:js_env][:register_cc_tabs]).to include("slack")
        end
      end

      context "is_default_account" do
        it "should be 'true' if the domain root account is the default" do
          user_session(@user)

          get "settings"

          expect(assigns[:js_env][:is_default_account]).to be true
        end
      end

      context "can_update_tokens" do
        it "should be 'true' if the user has permission to update tokens" do
          user_session(@user)
          get "settings"

          expect(assigns[:js_env][:PERMISSIONS][:can_update_tokens]).to be true
        end

        it "should be 'false' if the user does not have permission to update tokens" do
          @user.account.change_root_account_setting!(:limit_personal_access_tokens, true)
          @user.account.enable_feature!(:admin_manage_access_tokens)
          user_session(@user)
          get "settings"

          expect(assigns[:js_env][:PERMISSIONS][:can_update_tokens]).to be false
        end
      end

      it "sets discussions_reporting to falsey if discussions_reporting is off" do
        Account.default.disable_feature! :discussions_reporting
        user_session(@user)
        get "communication"
        expect(assigns[:js_env][:discussions_reporting]).to be_falsey
      end

      it "sets discussions_reporting to truthy if discussions_reporting is on" do
        Account.default.enable_feature! :discussions_reporting
        user_session(@user)
        get "communication"
        expect(assigns[:js_env][:discussions_reporting]).to be_truthy
      end

      it "sets the weekly_notification_range" do
        allow(@user).to receive(:weekly_notification_bucket).and_return(0)
        user_session(@user)
        Timecop.freeze(Time.zone.local(2021, 9, 22, 1, 0, 0)) do
          get "communication"

          expect(assigns[:js_env][:NOTIFICATION_PREFERENCES_OPTIONS][:weekly_notification_range][:weekday]).to eq("Friday")
          expect(assigns[:js_env][:NOTIFICATION_PREFERENCES_OPTIONS][:weekly_notification_range].keys).to eq(%i[weekday start_time end_time])
          expect(assigns[:js_env][:NOTIFICATION_PREFERENCES_OPTIONS][:weekly_notification_range][:start_time]).to eq "10pm"
          expect(assigns[:js_env][:NOTIFICATION_PREFERENCES_OPTIONS][:weekly_notification_range][:end_time]).to eq "12am"
        end
      end

      it "sets the daily_notification_time" do
        user_session(@user)
        Timecop.freeze(Time.zone.local(2021, 9, 22, 1, 0, 0)) do
          get "communication"

          expect(assigns[:js_env][:NOTIFICATION_PREFERENCES_OPTIONS][:daily_notification_time]).to eq("6pm")
        end
      end
    end
  end
end
