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

require_relative "../apis/api_spec_helper"

describe CommunicationChannelsController do
  before :once do
    user_with_pseudonym(active_user: true)
  end

  describe "POST 'create'" do
    before(:once) { user_model }

    it "creates a new CC unconfirmed" do
      user_session(@user)
      post "create", params: { user_id: @user.id, communication_channel: { address: "jt@instructure.com", type: "email" } }
      expect(response).to be_successful
      expect(@user.communication_channels.length).to eq 1
      expect(@user.email_channel).to be_unconfirmed
      expect(@user.email_channel.path).to eq "jt@instructure.com"
    end

    it "creates a new CC regardless of conflicts" do
      u = User.create!
      cc = u.communication_channels.create!(path: "jt@instructure.com", path_type: "email", workflow_state: "active")
      user_session(@user)
      post "create", params: { user_id: @user.id, communication_channel: { address: "jt@instructure.com", type: "email" } }
      expect(response).to be_successful
      expect(@user.communication_channels.length).to eq 1
      expect(@user.email_channel).not_to eq cc
      expect(@user.email_channel).to be_unconfirmed
      expect(@user.email_channel.path).to eq "jt@instructure.com"
    end

    it "resurrects retired CCs" do
      cc = @user.communication_channels.create!(
        path: "jt@instructure.com",
        path_type: "email",
        workflow_state: "retired",
        bounce_count: CommunicationChannel::RETIRE_THRESHOLD
      )
      user_session(@user)
      post "create", params: { user_id: @user.id, communication_channel: { address: "jt@instructure.com", type: "email" } }
      expect(response).to be_successful
      expect(@user.communication_channels.length).to eq 1
      expect(@user.email_channel).to be_unconfirmed
      expect(@user.email_channel.path).to eq "jt@instructure.com"
      expect(@user.email_channel).to eq cc
    end

    it "does not allow duplicate active CCs for a single user" do
      @user.communication_channels.create!(path: "jt@instructure.com", path_type: "email") { |cc| cc.workflow_state = "active" }
      user_session(@user)
      post "create", params: { user_id: @user.id, communication_channel: { address: "jt@instructure.com", type: "email" } }
      expect(response).not_to be_successful
    end

    it "prevents CC from being created if at the maximum number of CCs allowed" do
      domain_root_account = Account.default
      domain_root_account.settings[:max_communication_channels] = 1
      @user.communication_channels.create!(path: "cc@test.com")
      user_session(@user)
      post "create", params: {
        user_id: @user.id,
        communication_channel: {
          address: "cc2@test.com", type: "email"
        }
      }
      expect(response).not_to be_successful
      expect(
        response.parsed_body["errors"]["type"]
      ).to eq "Maximum number of communication channels reached"
    end

    it "does not create if user cannot manage comm channels" do
      user_with_pseudonym(active_user: true)
      user_session(@user, @pseudonym)
      @user.account.settings[:users_can_edit_comm_channels] = false
      @user.account.save!

      post "create", params: {
        user_id: @user.id,
        communication_channel: {
          address: "cc2@test.com", type: "email"
        }
      }
      expect(response).not_to be_successful
      expect(response).to have_http_status :unauthorized
    end
  end

  describe "GET 'confirm'" do
    context "add CC to existing user" do
      before(:once) { user_with_pseudonym(active_user: 1) }

      it "confirms an unconfirmed CC" do
        user_session(@user, @pseudonym)
        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to be_redirect
        expect(response).to redirect_to(user_profile_url(@user))
        @cc.reload
        expect(@cc).to be_active
      end

      it "redirects to login when trying to confirm" do
        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to be_redirect
        expect(response).to redirect_to(login_url(pseudonym_session: { unique_id: @pseudonym.unique_id }, expected_user_id: @pseudonym.user_id))
      end

      it "requires the correct user to confirm a cc" do
        @user1 = @user
        @pseudonym1 = @pseudonym
        user_with_pseudonym(active_user: 1, username: "jt@instructure.com")

        user_session(@user1, @pseudonym1)

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to redirect_to(login_url(pseudonym_session: { unique_id: @pseudonym.unique_id }, expected_user_id: @pseudonym.user_id))
      end

      it "does not confirm an already-confirmed CC with a registered user" do
        user_with_pseudonym
        @user.register
        user_session(@user, @pseudonym)
        code = @cc.confirmation_code
        @cc.confirm
        get "confirm", params: { nonce: code }
        expect(response).not_to be_successful
        expect(response).to render_template("confirm_failed")
        @cc.reload
        expect(@cc).to be_active
      end

      it "does not confirm invalid email addresses" do
        user_with_pseudonym(active_user: 1, username: "not-an-email@example.com")
        CommunicationChannel.where(id: @cc).update_all(path: "not-an-email")
        user_session(@user, @pseudonym)
        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).not_to be_successful
        expect(response).to render_template("confirm_failed")
      end

      it "confirms an already-confirmed CC with a pre-registered user" do
        user_with_pseudonym
        user_session(@user, @pseudonym)
        code = @cc.confirmation_code
        @cc.confirm
        get "confirm", params: { nonce: code }
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
      end
    end

    describe "open registration" do
      before :once do
        @account = Account.create!
        course_factory(active_all: true, account: @account)
        user_factory
      end

      it "shows a pre-registered user the confirmation form" do
        user_with_pseudonym(password: :autogenerate)
        @user.accept_terms
        @user.save
        expect(@user).to be_pre_registered

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to render_template("confirm")
        expect(assigns[:pseudonym]).to eq @pseudonym
        expect(assigns[:merge_opportunities]).to eq []
        @user.reload
        expect(@user).not_to be_registered
      end

      it "finalizes registration for a pre-registered user" do
        user_with_pseudonym(password: :autogenerate)
        @user.accept_terms
        @user.save
        expect(@user).to be_pre_registered

        post "confirm", params: { nonce: @cc.confirmation_code, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @cc.reload
        expect(@cc).to be_active
      end

      it "does not break when trying to register when psuedonym is not a valid email" do
        user_with_pseudonym(password: :autogenerate, username: "notanemail")
        @user.accept_terms
        @user.save

        post "confirm", params: { nonce: @cc.confirmation_code, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @cc.reload
        expect(@cc).to be_active
      end

      it "properly validates pseudonym for a pre-registered user" do
        u1 = user_with_communication_channel(username: "asdf@qwerty.com", user_state: "creation_pending")
        cc1 = @cc
        # another user claimed the pseudonym
        user_with_pseudonym(username: "asdf@qwerty.com", active_user: true)

        post "confirm", params: { nonce: cc1.confirmation_code, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        assert_status(400)
        u1.reload
        expect(u1).not_to be_registered
      end

      it "does not forget the account when registering for a non-default account" do
        @course = Course.create!(account: @account) { |c| c.workflow_state = "available" }
        user_with_pseudonym(account: @account, password: :autogenerate)
        @user.accept_terms
        @user.save
        @enrollment = @course.enroll_user(@user)
        expect(@pseudonym.account).to eq @account
        expect(@user).to be_pre_registered

        post "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @pseudonym.reload
        expect(@pseudonym.account).to eq @account
      end

      it "figures out the correct domain when registering" do
        user_with_pseudonym(account: @account, password: :autogenerate)
        expect(@pseudonym.account).to eq @account
        expect(@user).to be_pre_registered

        # @domain_root_account == Account.default
        post "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to be_successful
        expect(response).to render_template("confirm")
        expect(assigns[:pseudonym]).to eq @pseudonym
        expect(assigns[:root_account]).to eq @account
      end

      it "does not finalize registration for invalid parameters" do
        user_with_pseudonym(password: :autogenerate)
        @cc.confirm!
        get "confirm", params: { nonce: "asdf" }
        expect(response).to render_template("confirm_failed")
        @pseudonym.reload
        expect(@pseudonym.user).not_to be_registered
      end

      it "shows the confirm form for a creation_pending user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        get "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid }
        expect(response).to be_successful
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq "jt@instructure.com"
      end

      it "registers creation_pending user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        post "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        expect(response).to redirect_to(course_url(@course))
        @user.reload
        expect(@user).to be_registered
        @enrollment.reload
        expect(@enrollment).to be_active
        @cc.reload
        expect(@cc).to be_active
        expect(@user.pseudonyms.length).to eq 1
        @pseudonym = @user.pseudonyms.first
        expect(@pseudonym).to be_active
        expect(@pseudonym.unique_id).to eq "jt@instructure.com"
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "shows the confirm form for a creation_pending user that's logged in (masquerading)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        # not a full user session; just @current_user is set
        controller.instance_variable_set(:@current_user, @user)

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to be_successful
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq "jt@instructure.com"
      end

      it "registers creation_pending user that's logged in (masquerading)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        # not a full user session; just @current_user is set
        controller.instance_variable_set(:@current_user, @user)
        @domain_root_account = Account.default

        post "confirm", params: { nonce: @cc.confirmation_code, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        expect(response).to redirect_to(dashboard_url)
        @user.reload
        expect(@user).to be_registered
        @cc.reload
        expect(@cc).to be_active
        expect(@user.pseudonyms.length).to eq 1
        @pseudonym = @user.pseudonyms.first
        expect(@pseudonym).to be_active
        expect(@pseudonym.unique_id).to eq "jt@instructure.com"
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "prepares to register a creation_pending user in the correct account" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to be_successful
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq "jt@instructure.com"
        expect(assigns[:pseudonym].account).to eq @account
        expect(assigns[:root_account]).to eq @account
      end

      it "registers creation_pending user in the correct account" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        post "confirm", params: { nonce: @cc.confirmation_code, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @enrollment.reload
        expect(@enrollment).to be_invited
        @cc.reload
        expect(@cc).to be_active
        expect(@user.pseudonyms.length).to eq 1
        @pseudonym = @user.pseudonyms.first
        expect(@pseudonym).to be_active
        expect(@pseudonym.unique_id).to eq "jt@instructure.com"
        expect(@pseudonym.account).to eq @account
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "prepares to register a creation_pending user in the correct account (admin)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @account.account_users.create!(user: @user)
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        expect(@user).to be_creation_pending

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to be_successful
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq "jt@instructure.com"
        expect(assigns[:pseudonym].account).to eq @account
        expect(assigns[:root_account]).to eq @account
      end

      it "registers creation_pending user in the correct account (admin)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @account.account_users.create!(user: @user)
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        expect(@user).to be_creation_pending

        post "confirm", params: { nonce: @cc.confirmation_code, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @cc.reload
        expect(@cc).to be_active
        expect(@user.pseudonyms.length).to eq 1
        @pseudonym = @user.pseudonyms.first
        expect(@pseudonym).to be_active
        expect(@pseudonym.unique_id).to eq "jt@instructure.com"
        expect(@pseudonym.account).to eq @account
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "shows the confirm form for old creation_pending users that have a pseudonym" do
        course_factory(active_all: true)
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited
        @pseudonym = @user.pseudonyms.create!(unique_id: "jt@instructure.com")
        get "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid }
        expect(response).to be_successful
        expect(assigns[:pseudonym]).to eq @pseudonym
      end

      it "works for old creation_pending users that have a pseudonym" do
        course_factory(active_all: true)
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited
        @pseudonym = @user.pseudonyms.create!(unique_id: "jt@instructure.com")

        post "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        expect(response).to redirect_to(course_url(@course))
        @user.reload
        expect(@user).to be_registered
        @enrollment.reload
        expect(@enrollment).to be_active
        @cc.reload
        expect(@cc).to be_active
        expect(@user.pseudonyms.length).to eq 1
        @pseudonym.reload
        expect(@pseudonym).to be_active
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "allows the user to pick a new pseudonym if a conflict already exists" do
        user_with_pseudonym(active_all: 1, username: "jt@instructure.com")
        course_factory(active_all: true)
        user_factory
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        get "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid }
        expect(response).to be_successful
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to be_blank
      end

      it "forces the user to provide a unique_id if a conflict already exists" do
        user_with_pseudonym(active_all: 1, username: "jt@instructure.com")
        course_factory(active_all: true)
        user_factory
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        post "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        assert_status(400)
      end

      it "redirects to the confirmation_redirect url when present" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com", confirmation_redirect: "http://some.place/in-the-world")

        post "confirm", params: { nonce: @cc.confirmation_code, register: 1, pseudonym: { password: "asdfasdf" } }
        expect(response).to redirect_to("http://some.place/in-the-world?current_user_id=#{@user.id}")
      end
    end

    describe "merging" do
      before :once do
        @account1 = Account.create!(name: "A")
        @account2 = Account.create!(name: "B")
      end

      it "prepares to merge with an already-logged-in user" do
        user_with_pseudonym(username: "jt+1@instructure.com")
        @not_logged_user = @user
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        # render merge opportunities
        get "confirm", params: { nonce: @not_logged_user.email_channel.confirmation_code }
        expect(response).to render_template("confirm")
        expect(assigns[:merge_opportunities]).to eq [[@user, [@pseudonym]]]
      end

      it "merges with an already-logged-in user" do
        user_with_pseudonym(username: "jt+1@instructure.com")
        @not_logged_user = @user
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        @domain_root_account = Account.default

        get "confirm", params: { nonce: @not_logged_user.email_channel.confirmation_code, confirm: 1 }
        expect(response).to redirect_to(dashboard_url)

        @not_logged_user.reload
        expect(@not_logged_user).to be_deleted
        @logged_user.reload
        expect(@logged_user.communication_channels.map(&:path).sort).to eq ["jt@instructure.com", "jt+1@instructure.com"].sort
        expect(@logged_user.communication_channels.all?(&:active?)).to be_truthy
      end

      it "does not allow merging with someone that's observed through a UserObserver relationship" do
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1)
        @not_logged_user = @user
        user_with_pseudonym(username: "jt+1@instructure.com", active_all: 1)
        @logged_user = @user

        add_linked_observer(@not_logged_user, @logged_user)

        user_session(@logged_user, @pseudonym)

        get "confirm", params: { nonce: @not_logged_user.email_channel.confirmation_code, confirm: 1 }
        expect(response).to render_template("confirm_failed")
      end

      it "does not allow merging with someone that's observing through a UserObserver relationship" do
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1)
        @not_logged_user = @user
        user_with_pseudonym(username: "jt+1@instructure.com", active_all: 1)
        @logged_user = @user

        add_linked_observer(@logged_user, @not_logged_user)

        user_session(@logged_user, @pseudonym)

        get "confirm", params: { nonce: @not_logged_user.email_channel.confirmation_code, confirm: 1 }
        expect(response).to render_template("confirm_failed")
      end

      it "does not allow merging with someone that's not a merge opportunity" do
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1)
        @not_logged_user = @user
        user_with_pseudonym(username: "jt+1@instructure.com", active_all: 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        get "confirm", params: { nonce: @not_logged_user.email_channel.confirmation_code, confirm: 1 }
        expect(response).to render_template("confirm_failed")
      end

      it "shows merge opportunities for active users" do
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1)
        @user1 = @user
        user_with_pseudonym(username: "jt+1@instructure.com", active_all: 1)
        @cc = @user.communication_channels.create!(path: "jt@instructure.com") { |cc| cc.workflow_state = "active" }

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to render_template("confirm")
        expect(assigns[:merge_opportunities]).to eq [[@user1, [@user1.pseudonym]]]
      end

      it "does not show merge opportunities if an account has self-service merge disabled" do
        Account.default.disable_feature!(:self_service_user_merge)
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1)
        @user1 = @user
        user_with_pseudonym(username: "jt+1@instructure.com")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com", workflow_state: "active")

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to redirect_to dashboard_url
      end

      it "does not show users that can't have a pseudonym created for the correct account" do
        @account1.authentication_providers.scope.delete_all
        @account1.authentication_providers.create!(auth_type: "cas")
        user_with_pseudonym(active_all: 1, account: @account1, username: "jt@instructure.com")

        course_factory(active_all: true, account: @account2)
        user_factory
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_user(@user)

        get "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid }
        expect(response).to render_template("confirm")
        expect(assigns[:merge_opportunities]).to eq []
      end

      it "creates a pseudonym in the target account by copying an existing pseudonym when merging" do
        user_with_pseudonym(active_all: 1, username: "jt@instructure.com")
        @old_user = @user

        course_factory(active_all: true, account: @account2)
        user_factory
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @enrollment = @course.enroll_user(@user)
        user_session(@old_user, @old_user.pseudonym)

        get "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid, confirm: 1 }
        expect(response).to redirect_to(course_url(@course))
        @old_user.reload
        @user.reload
        expect(@user).to be_deleted
        @enrollment.reload
        expect(@enrollment.user).to eq @old_user
        expect(@old_user.pseudonyms.length).to eq 2
        expect(@old_user.pseudonyms.detect { |p| p.account == @account2 }.unique_id).to eq "jt@instructure.com"
      end

      it "includes all pseudonyms if there are multiple" do
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1, account: @account1)
        @pseudonym1 = @pseudonym
        @user1 = @user
        @pseudonym2 = @account2.pseudonyms.create!(user: @user1, unique_id: "jt")

        user_with_pseudonym(username: "jt+1@instructure.com", active_all: 1, account: Account.default)
        @cc = @user.communication_channels.create!(path: "jt@instructure.com") { |cc| cc.workflow_state = "active" }

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to render_template("confirm")
        expect(assigns[:merge_opportunities]).to eq [[@user1, [@pseudonym1, @pseudonym2]]]
      end

      it "only includes the current account's pseudonym if there are multiple" do
        @account1 = Account.default
        @account2 = Account.create!
        user_with_pseudonym(username: "jt@instructure.com", active_all: 1, account: @account1)
        @pseudonym1 = @pseudonym
        @user1 = @user
        @pseudonym2 = @account2.pseudonyms.create!(user: @user1, unique_id: "jt")

        user_with_pseudonym(username: "jt+1@instructure.com", active_all: 1, account: @account1)
        @cc = @user.communication_channels.create!(path: "jt@instructure.com") { |cc| cc.workflow_state = "active" }

        get "confirm", params: { nonce: @cc.confirmation_code }
        expect(response).to render_template("confirm")
        expect(assigns[:merge_opportunities]).to eq [[@user1, [@pseudonym1]]]
      end

      context "cross-shard user" do
        specs_require_sharding

        it "lets users confirm an email address on either shard" do
          @shard1.activate do
            @cc = @user.communication_channels.create!(path: "new1@foo.com")
            user_session(@user)
            post "confirm", params: { nonce: @cc.confirmation_code }
            @cc.reload
            expect(@cc.workflow_state).to eq "active"
          end
        end
      end
    end

    describe "invitations" do
      before(:once) { course_with_student(active_course: 1) }

      it "prepares to accept an invitation when creating a new user" do
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")

        get "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid }
        expect(response).to be_successful
        expect(assigns[:current_user]).to be_nil
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq "jt@instructure.com"
      end

      it "accepts an invitation when creating a new user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")

        post "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid, register: 1, pseudonym: { password: "asdfasdf", password_confirmation: "asdfasdf" } }
        expect(response).to be_redirect
        expect(response).to redirect_to(course_url(@course))
        @enrollment.reload
        expect(@enrollment).to be_active
        @user.reload
        expect(@user).to be_registered
        expect(@user.pseudonyms.length).to eq 1
        @cc.reload
        expect(@cc).to be_active
      end

      it "rejects pseudonym unique_id changes when creating a new user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, "creation_pending")
        @cc = @user.communication_channels.create!(path: "jt@instructure.com")

        post "confirm", params: { nonce: @cc.confirmation_code, enrollment: @enrollment.uuid, register: 1, pseudonym: { unique_id: "haxxor@example.com", password: "asdfasdf", password_confirmation: "asdfasdf" } }

        expect(@user.reload.pseudonyms.first.unique_id).to eq "jt@instructure.com"
      end

      it "previews acceptance of an invitation when merging with the current user" do
        @user.update_attribute(:workflow_state, "creation_pending")
        @old_cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @old_user = @user

        user_with_pseudonym(active_all: 1, username: "bob@instructure.com")
        user_session(@user, @pseudonym)

        get "confirm", params: { nonce: @old_cc.confirmation_code, enrollment: @enrollment.uuid }
        expect(response).to render_template("confirm")
        expect(assigns[:current_user]).to eq @user
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq "jt@instructure.com"
        expect(assigns[:merge_opportunities]).to eq [[@user, [@pseudonym]]]
      end

      it "accepts an invitation when merging with the current user" do
        @user.update_attribute(:workflow_state, "creation_pending")
        @old_cc = @user.communication_channels.create!(path: "jt@instructure.com")
        @old_user = @user

        user_with_pseudonym(active_all: 1, username: "bob@instructure.com")
        user_session(@user, @pseudonym)

        post "confirm", params: { nonce: @old_cc.confirmation_code, enrollment: @enrollment.uuid, confirm: 1 }
        expect(response).to redirect_to(course_url(@course))
        expect(assigns[:current_user]).to eq @user
        @enrollment.reload
        expect(@enrollment).to be_active
        expect(@enrollment.user).to eq @user
        @old_user.reload
        expect(@old_user).to be_deleted
        expect(@old_user.pseudonyms.length).to eq 0
        @old_cc.reload
        expect(@old_cc.user).to eq @user
      end

      it "prepares to transfer an enrollment to a different user" do
        course_with_student(active_user: 1, active_course: 1)
        @student_cc = @user.communication_channels.create!(path: "someone@somewhere.com") { |cc| cc.workflow_state = "active" }
        user_with_pseudonym(active_all: 1)
        user_session(@user, @pseudonym)

        get "confirm", params: { nonce: @student_cc.confirmation_code, enrollment: @enrollment.uuid }
        expect(response).to render_template("confirm")
      end

      it "transfers an enrollment to a different user" do
        course_with_student(active_user: 1, active_course: 1)
        @student_cc = @user.communication_channels.create!(path: "someone@somewhere.com") { |cc| cc.workflow_state = "active" }
        user_with_pseudonym(active_all: 1)
        user_session(@user, @pseudonym)

        get "confirm", params: { nonce: @student_cc.confirmation_code, enrollment: @enrollment.uuid, transfer_enrollment: 1 }
        expect(response).to redirect_to(course_url(@course))
        @enrollment.reload
        expect(@enrollment).to be_active
        expect(@enrollment.user).to eq @user
      end
    end

    it "uncaches user's cc's when confirming a CC" do
      user_with_pseudonym(active_user: true)
      user_session(@user, @pseudonym)
      User.record_timestamps = false
      begin
        @user.update_attribute(:updated_at, 1.second.ago)
        enable_cache do
          expect(@user.cached_active_emails).to eq []
          @cc = @user.communication_channels.create!(path: "jt@instructure.com")
          expect(@user.cached_active_emails).to eq []
          get "confirm", params: { nonce: @cc.confirmation_code }
          @user.reload
          expect(@user.cached_active_emails).to eq ["jt@instructure.com"]
        end
      ensure
        User.record_timestamps = true
      end
    end
  end

  describe "POST 'reset_bounce_count'" do
    it "allows siteadmins to reset the bounce count" do
      u = user_with_pseudonym
      cc1 = u.communication_channels.create!(path: "test@example.com", path_type: "email") do |cc|
        cc.workflow_state = "active"
        cc.bounce_count = 3
      end
      account_admin_user(account: Account.site_admin)
      user_session(@user)
      session[:become_user_id] = u.id
      post "reset_bounce_count", params: { user_id: u.id, id: cc1.id }
      expect(response).to be_successful
      cc1.reload
      expect(cc1.bounce_count).to eq(0)
    end

    it "does not allow account admins to reset the bounce count" do
      u = user_with_pseudonym
      cc1 = u.communication_channels.create!(path: "test@example.com", path_type: "email") do |cc|
        cc.workflow_state = "active"
        cc.bounce_count = 3
      end
      account_admin_user(account: Account.default)
      user_session(@user)
      session[:become_user_id] = u.id
      post "reset_bounce_count", params: { user_id: u.id, id: cc1.id }
      expect(response).to have_http_status(:unauthorized)
      cc1.reload
      expect(cc1.bounce_count).to eq(3)
    end
  end

  context "bulk actions" do
    def included_channels
      CSV.parse(response.body).drop(1).map do |row|
        CommunicationChannel.find(row[2])
      end
    end

    describe "GET 'bouncing_channel_report'" do
      def channel_csv(cc)
        [
          cc.user.id.try(:to_s),
          cc.user.name,
          cc.id.try(:to_s),
          cc.path_type,
          cc.path_description,
          cc.last_bounce_at&.iso8601,
          cc.last_bounce_summary.try(:to_s)
        ]
      end

      context "as an account admin" do
        before :once do
          @account = Account.default
          @account.settings[:admins_can_view_notifications] = true
          @account.save!
          account_admin_user_with_role_changes(account: @account, role_changes: { view_notifications: true })
        end

        before do
          user_session(@admin)
        end

        it "fetches communication channels in this account and orders by date" do
          now = Time.zone.now

          u1 = user_with_pseudonym
          u2 = user_with_pseudonym
          c1 = u1.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
            cc.last_bounce_at = now
          end
          c2 = u1.communication_channels.create!(path: "two@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 2
            cc.last_bounce_at = now - 1.hour
          end
          c3 = u2.communication_channels.create!(path: "three@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 3
            cc.last_bounce_at = now + 1.hour
            cc.last_bounce_details = { "bouncedRecipients" => [{ "diagnosticCode" => "stuff and things" }] }
          end

          get "bouncing_channel_report", params: { account_id: Account.default.id }
          expect(response).to have_http_status(:ok)

          csv = CSV.parse(response.body)
          expect(csv).to eq [
            ["User ID", "Name", "Communication channel ID", "Type", "Path", "Date of most recent bounce", "Bounce reason"],
            channel_csv(c2),
            channel_csv(c1),
            channel_csv(c3)
          ]

          # also test JSON format
          get "bouncing_channel_report", params: { account_id: Account.default.id, format: :json }
          json = response.parsed_body
          expect(json).to eq [
            ["User ID", "Name", "Communication channel ID", "Type", "Path", "Date of most recent bounce", "Bounce reason"],
            channel_csv(c2),
            channel_csv(c1),
            channel_csv(c3)
          ]
        end

        it "ignores communication channels in other accounts" do
          u1 = user_with_pseudonym
          a = account_model
          u2 = user_with_pseudonym(account: a)

          c1 = u1.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end
          u2.communication_channels.create!(path: "two@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end

          get "bouncing_channel_report", params: { account_id: Account.default.id }

          expect(included_channels).to eq([c1])
        end

        it "only reports active, bouncing communication channels" do
          user_with_pseudonym

          c1 = @user.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end
          @user.communication_channels.create!(path: "two@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
          end
          @user.communication_channels.create!(path: "three@example.com", path_type: "email") do |cc|
            cc.workflow_state = "retired"
            cc.bounce_count = 1
          end

          get "bouncing_channel_report", params: { account_id: Account.default.id }

          expect(included_channels).to eq([c1])
        end

        it "uses the requested account" do
          a = account_model
          account_admin_user_with_role_changes(user: @admin, account: a, role_changes: { view_notifications: true })
          a.settings[:admins_can_view_notifications] = true
          a.save!

          user_with_pseudonym(account: a)
          c = @user.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end

          get "bouncing_channel_report", params: { account_id: a.id }

          expect(included_channels).to eq([c])
        end

        it "filters by date" do
          user_with_pseudonym

          @user.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
            cc.last_bounce_at = 1.day.ago
          end
          c2 = @user.communication_channels.create!(path: "two@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now
          end
          @user.communication_channels.create!(path: "three@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
            cc.last_bounce_at = 1.day.from_now
          end

          get "bouncing_channel_report", params: { account_id: Account.default.id,
                                                   before: 1.hour.from_now,
                                                   after: 1.hour.ago }

          expect(included_channels).to eq([c2])
        end

        it "filters by pattern, and case insensitively" do
          user_with_pseudonym

          # Uppercase "A" in the path to make sure it's matching case insensitively
          c1 = @user.communication_channels.create!(path: "bAr@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end
          @user.communication_channels.create!(path: "foobar@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end

          get "bouncing_channel_report", params: { account_id: Account.default.id, pattern: "bar*" }

          expect(included_channels).to eq([c1])
        end

        it "limits to CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit" do
          allow(CommunicationChannel::BulkActions::ResetBounceCounts).to receive(:bulk_limit).and_return(5)
          now = Time.zone.now

          user_with_pseudonym

          ccs = Array.new(CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit + 1) do |n|
            @user.communication_channels.create!(path: "c#{n}@example.com", path_type: "email") do |cc|
              cc.workflow_state = "active"
              cc.bounce_count = 1
              cc.last_bounce_at = now + n.minutes
            end
          end

          get "bouncing_channel_report", params: { account_id: Account.default.id }

          expect(included_channels).to eq(ccs.first(CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit))
        end
      end

      context "as a normal user" do
        it "doesn't work" do
          user_with_pseudonym
          user_session(@user)
          get "bouncing_channel_report", params: { account_id: Account.default.id }
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    describe "POST 'bulk_reset_bounce_counts'" do
      context "as a site admin" do
        before do
          account_admin_user(account: Account.site_admin)
          user_session(@user)
        end

        it "resets bounce counts" do
          u1 = user_with_pseudonym
          u2 = user_with_pseudonym
          c1 = u1.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end
          c2 = u1.communication_channels.create!(path: "two@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 2
          end
          c3 = u2.communication_channels.create!(path: "three@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 3
          end

          post "bulk_reset_bounce_counts", params: { account_id: Account.default.id }

          expect(response).to have_http_status(:ok)
          [c1, c2, c3].each_with_index do |c, i|
            expect(c.reload.bounce_count).to eq(i + 1)
          end
          run_jobs
          [c1, c2, c3].each do |c|
            expect(c.reload.bounce_count).to eq(0)
          end
        end

        it "filters by date" do
          user_with_pseudonym

          c1 = @user.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
            cc.last_bounce_at = 1.day.ago
          end
          c2 = @user.communication_channels.create!(path: "two@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now
          end
          c3 = @user.communication_channels.create!(path: "three@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
            cc.last_bounce_at = 1.day.from_now
          end

          post "bulk_reset_bounce_counts", params: { account_id: Account.default.id,
                                                     before: 1.hour.from_now,
                                                     after: 1.hour.ago }

          run_jobs
          expect(c1.reload.bounce_count).to eq(1)
          expect(c2.reload.bounce_count).to eq(0)
          expect(c3.reload.bounce_count).to eq(1)
        end

        it "filters by pattern" do
          user_with_pseudonym

          c1 = @user.communication_channels.create!(path: "bar@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end
          c2 = @user.communication_channels.create!(path: "foobar@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end

          post "bulk_reset_bounce_counts", params: { account_id: Account.default.id, pattern: "bar*" }

          run_jobs
          expect(c1.reload.bounce_count).to eq(0)
          expect(c2.reload.bounce_count).to eq(1)
        end

        it "respects the BULK_LIMIT" do
          allow(CommunicationChannel::BulkActions::ResetBounceCounts).to receive(:bulk_limit).and_return(5)
          now = Time.zone.now

          user_with_pseudonym

          ccs = Array.new(CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit + 1) do |n|
            @user.communication_channels.create!(path: "c#{n}@example.com", path_type: "email") do |cc|
              cc.workflow_state = "active"
              cc.bounce_count = 1
              cc.last_bounce_at = now + n.minutes
            end
          end

          post "bulk_reset_bounce_counts", params: { account_id: Account.default.id }

          run_jobs
          ccs.each(&:reload)
          expect(ccs[-1].bounce_count).to eq(1)
          ccs.first(CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit).each do |cc|
            expect(cc.bounce_count).to eq(0)
          end
        end
      end

      context "as a normal user" do
        it "doesn't work" do
          user_with_pseudonym
          c = @user.communication_channels.create!(path: "one@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
            cc.bounce_count = 1
          end

          user_with_pseudonym
          user_session(@user)

          post "bulk_reset_bounce_counts", params: { account_id: Account.default.id }

          expect(response).to have_http_status(:unauthorized)
          expect(c.reload.bounce_count).to eq(1)
        end
      end
    end

    context "unconfirmed channels" do
      context "as a siteadmin" do
        before do
          account_admin_user(account: Account.site_admin)
          user_session(@user)

          user_with_pseudonym

          @c1 = @user.communication_channels.create!(path: "foo@example.com", path_type: "email") do |cc|
            cc.workflow_state = "unconfirmed"
          end
          @c2 = @user.communication_channels.create!(path: "bar@example.com", path_type: "email") do |cc|
            cc.workflow_state = "unconfirmed"
          end
          @c3 = @user.communication_channels.create!(path: "baz@example.com", path_type: "email") do |cc|
            cc.workflow_state = "active"
          end
          @c4 = @user.communication_channels.create!(path: "qux@example.com", path_type: "email") do |cc|
            cc.workflow_state = "unconfirmed"
          end
          CommunicationChannel.where(id: @c4).update_all(path: "qux@.")
          @c5 = @user.communication_channels.create!(path: "+18015550100", path_type: "sms") do |cc|
            cc.workflow_state = "unconfirmed"
          end
        end

        context "GET 'unconfirmed_channel_report'" do
          it "reports channels" do
            get "unconfirmed_channel_report", params: { account_id: Account.default.id }

            expect(response).to have_http_status(:ok)
            # can't expect to eq because we get stray channels for the users we created
            expect(included_channels).to include(@c1, @c2, @c5)
            expect(included_channels).to_not include(@c3, @c4)
          end

          it "filters by path type" do
            get "unconfirmed_channel_report", params: { account_id: Account.default.id, path_type: "sms" }

            expect(response).to have_http_status(:ok)
            expect(included_channels).to include(@c5)
            expect(included_channels).to_not include(@c1, @c2, @c3, @c4)
          end
        end

        context "POST 'bulk_confirm'" do
          it "confirms channels" do
            post "bulk_confirm", params: { account_id: Account.default.id }

            expect(@c1.reload.workflow_state).to eq("active")
            expect(@c2.reload.workflow_state).to eq("active")
          end

          it "excludes channels with invalid paths" do
            post "bulk_confirm", params: { account_id: Account.default.id }

            expect(@c4.reload.workflow_state).to eq("unconfirmed")
          end

          it "includes channels with invalid paths if requested" do
            post "bulk_confirm", params: { account_id: Account.default.id, with_invalid_paths: "1" }

            expect(@c1.reload.workflow_state).to eq("active")
            expect(@c2.reload.workflow_state).to eq("active")
            expect(@c4.reload.workflow_state).to eq("active")
          end
        end
      end

      context "as a normal user" do
        before do
          user_with_pseudonym
          user_session(@user)
        end

        context "GET 'unconfirmed_channel_report'" do
          it "doesn't work" do
            get "unconfirmed_channel_report", params: { account_id: Account.default.id }
            expect(response).to have_http_status(:unauthorized)
          end
        end

        context "POST 'bulk_confirm'" do
          it "doesn't work" do
            post "bulk_confirm", params: { account_id: Account.default.id }
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end
    end
  end

  context "re-sending confirmations" do
    it "re-sends communication channel invitation for an invited channel" do
      Notification.create(name: "Confirm Email Communication Channel")
      user_session(@user)
      get "re_send_confirmation", params: { user_id: @pseudonym.user_id, id: @cc.id }
      expect(response).to be_successful
      expect(assigns[:user]).to eql(@user)
      expect(assigns[:cc]).to eql(@cc)
      expect(assigns[:cc].messages_sent).not_to be_nil
    end

    it "requires a logged-in user" do
      get "re_send_confirmation", params: { user_id: @pseudonym.user_id, id: @cc.id }
      assert_unauthorized
    end

    it "requires self to be logged in to re-send (without enrollment)" do
      user_session(@user)
      user_with_pseudonym(active_all: true) # new user
      get "re_send_confirmation", params: { user_id: @pseudonym.user_id, id: @cc.id }
      assert_unauthorized
    end

    it "allows an account admin to re-send" do
      account_admin_user(user: @user)
      user_session(@user)
      user_with_pseudonym(active_all: true) # new user
      get "re_send_confirmation", params: { user_id: @pseudonym.user_id, id: @cc.id }
      expect(response).to be_successful
    end

    it "re-sends enrollment invitation for an invited user" do
      course_with_teacher_logged_in(active_all: true)

      user_with_pseudonym(active_all: true) # new user
      @enrollment = @course.enroll_user(@user)
      expect(@enrollment.context).to eql(@course)
      Notification.create(name: "Enrollment Invitation")

      get "re_send_confirmation", params: { user_id: @pseudonym.user_id, id: @cc.id, enrollment_id: @enrollment.id }
      expect(response).to be_successful
      expect(assigns[:user]).to eql(@user)
      expect(assigns[:enrollment]).to eql(@enrollment)
      expect(assigns[:enrollment].messages_sent).not_to be_nil
    end

    it "does not re-send registration to a registered user when trying to re-send invitation for an unavailable course" do
      course_with_teacher_logged_in(active_all: true)
      @course.update(start_at: 1.week.from_now,
                     restrict_student_future_view: true,
                     restrict_enrollments_to_course_dates: true)

      user_with_pseudonym(active_all: true) # new user
      @enrollment = @course.enroll_user(@user)

      expect_any_instantiation_of(@cc).not_to receive(:send_confirmation!)
      get "re_send_confirmation", params: { user_id: @pseudonym.user_id, id: @cc.id, enrollment_id: @enrollment.id }
      expect(response).to be_successful
    end

    it "requires an admin with rights in the course" do
      course_with_teacher_logged_in(active_all: true) # other course

      user_with_pseudonym(active_all: true)
      course_factory(active_all: true)
      @enrollment = @course.enroll_user(@user)

      get "re_send_confirmation", params: { user_id: @pseudonym.user_id, id: @cc.id, enrollment_id: @enrollment.id }
      assert_unauthorized
    end

    context "cross-shard user" do
      specs_require_sharding
      it "re-sends enrollment invitation for a cross-shard user" do
        course_with_teacher_logged_in(active_all: true)
        enrollment = nil
        @shard1.activate do
          user_with_pseudonym active_cc: true
          enrollment = @course.enroll_student(@user)
        end
        Notification.create(name: "Enrollment Invitation")
        post "re_send_confirmation", params: { user_id: enrollment.user_id, enrollment_id: enrollment.id }
        expect(response).to be_successful
        expect(assigns[:enrollment]).to eql(enrollment)
        expect(assigns[:enrollment].messages_sent).not_to be_nil
      end
    end
  end

  it "uncaches user's cc's when retiring a CC" do
    user_session(@user, @pseudonym)
    User.record_timestamps = false
    begin
      @user.update_attribute(:updated_at, 10.seconds.ago)
      enable_cache do
        expect(@user.cached_active_emails).to eq []
        @cc = @user.communication_channels.create!(path: "jt@instructure.com") { |cc| cc.workflow_state = "active" }
        expect(@user.cached_active_emails).to eq ["jt@instructure.com"]
        delete "destroy", params: { id: @cc.id }
        @user.reload
        expect(@user.cached_active_emails).to eq []
      end
    ensure
      User.record_timestamps = true
    end
  end

  it "does not delete if user cannot manage comm channels" do
    user_session(@user, @pseudonym)
    @pseudonym.account.settings[:users_can_edit_comm_channels] = false
    @pseudonym.account.save!

    delete "destroy", params: { id: @pseudonym.communication_channel.id }

    expect(response).to have_http_status :unauthorized
  end

  it "does not delete a required institutional channel" do
    user_session(@user, @pseudonym)
    Account.default.settings[:edit_institution_email] = false
    Account.default.save!
    @pseudonym.update_attribute(:sis_communication_channel_id, @pseudonym.communication_channel.id)

    delete "destroy", params: { id: @pseudonym.communication_channel.id }

    expect(response).to have_http_status :unauthorized
  end

  context "push token deletion" do
    let(:sns_response) { double(:[] => { endpoint_arn: "endpointarn" }, :attributes => { endpoint_arn: "endpointarn" }) }
    let(:sns_client) { double(create_platform_endpoint: sns_response, get_endpoint_attributes: sns_response) }
    let(:sns_developer_key_sns_field) { sns_client }

    let(:sns_developer_key) do
      allow(DeveloperKey).to receive(:sns).and_return(sns_developer_key_sns_field)
      DeveloperKey.default
    end

    let(:sns_access_token) { @user.access_tokens.create!(developer_key: sns_developer_key) }
    let(:sns_channel) { @user.communication_channels.create(path_type: CommunicationChannel::TYPE_PUSH, path: "push") }

    it "404s if there is no communication channel", type: :request do
      status = raw_api_call(:delete,
                            "/api/v1/users/self/communication_channels/push",
                            { controller: "communication_channels",
                              action: "delete_push_token",
                              format: "json",
                              push_token: "notatoken" },
                            { push_token: "notatoken" })
      expect(status).to eq(404)
    end

    it "deletes a push_token", type: :request do
      fake_token = "insttothemoon"
      sns_access_token.notification_endpoints.create!(token: fake_token)
      sns_channel

      json = api_call(:delete,
                      "/api/v1/users/self/communication_channels/push",
                      { controller: "communication_channels",
                        action: "delete_push_token",
                        format: "json",
                        push_token: fake_token },
                      { push_token: fake_token })
      expect(json["success"]).to be true
      endpoints = @user.notification_endpoints.where("lower(token) = ?", fake_token)
      expect(endpoints.length).to eq 0
    end

    context "has a push communication channel" do
      let(:second_sns_developer_key) do
        allow(DeveloperKey).to receive(:sns).and_return(sns_developer_key_sns_field)
        DeveloperKey.default
      end

      let(:second_sns_access_token) { @user.access_tokens.create!(developer_key: second_sns_developer_key) }
      let(:sns_channel) { @user.communication_channels.create(path_type: CommunicationChannel::TYPE_PUSH, path: "push") }

      before { sns_channel }

      it "shouldnt error if an endpoint does not exist for the push_token", type: :request do
        json = api_call(:delete,
                        "/api/v1/users/self/communication_channels/push",
                        { controller: "communication_channels",
                          action: "delete_push_token",
                          format: "json",
                          push_token: "notatoken" },
                        { push_token: "notatoken" })
        expect(json["success"]).to be true
      end

      context "has a notification endpoint" do
        let(:fake_token) { "insttothemoon" }

        before { sns_access_token.notification_endpoints.create!(token: fake_token) }

        context "cross-shard user" do
          specs_require_sharding

          it "deletes endpoints from all_shards", type: :request do
            @shard1.activate { @new_user = User.create!(name: "shard one") }
            UserMerge.from(@user).into(@new_user)
            @user = @new_user
            json = api_call(:delete,
                            "/api/v1/users/self/communication_channels/push",
                            { controller: "communication_channels",
                              action: "delete_push_token",
                              format: "json",
                              push_token: fake_token },
                            { push_token: fake_token })
            expect(json["success"]).to be true
            endpoints = @user.notification_endpoints.shard(@user).where("lower(token) = ?", fake_token)
            expect(endpoints.length).to eq 0
          end
        end

        it "deletes a push_token", type: :request do
          json = api_call(:delete,
                          "/api/v1/users/self/communication_channels/push",
                          { controller: "communication_channels",
                            action: "delete_push_token",
                            format: "json",
                            push_token: fake_token },
                          { push_token: fake_token })
          expect(json["success"]).to be true
          endpoints = @user.notification_endpoints.where("lower(token) = ?", fake_token)
          expect(endpoints.length).to eq 0
        end

        it "only deletes specified endpoint", type: :request do
          another_token = "another"
          another_endpoint = second_sns_access_token.notification_endpoints.create!(token: another_token)

          api_call(:delete,
                   "/api/v1/users/self/communication_channels/push",
                   { controller: "communication_channels",
                     action: "delete_push_token",
                     format: "json",
                     push_token: fake_token },
                   { push_token: fake_token })
          expect(NotificationEndpoint.find(another_endpoint.id).workflow_state).to eq("active")
          expect(NotificationEndpoint.where(token: fake_token).take.workflow_state).to eq("deleted")
        end

        it "does not delete the communication channel", type: :request do
          api_call(:delete,
                   "/api/v1/users/self/communication_channels/push",
                   { controller: "communication_channels",
                     action: "delete_push_token",
                     format: "json",
                     push_token: fake_token },
                   { push_token: fake_token })
          expect(CommunicationChannel.where(path: "push").take).to be_truthy
        end

        it "deletes all endpoints for the given token", type: :request do
          second_sns_access_token.notification_endpoints.create!(token: fake_token)
          api_call(:delete,
                   "/api/v1/users/self/communication_channels/push",
                   { controller: "communication_channels",
                     action: "delete_push_token",
                     format: "json",
                     push_token: fake_token },
                   { push_token: fake_token })
          expect(NotificationEndpoint.where(token: fake_token, workflow_state: "deleted").length).to eq(2)
        end
      end
    end
  end
end
