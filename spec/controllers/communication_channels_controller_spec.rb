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

require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe CommunicationChannelsController do
  before :once do
    user_with_pseudonym(:active_user => true)
  end

  describe "POST 'create'" do
    before(:once) { user_model }

    it "should create a new CC unconfirmed" do
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email'  }
      expect(response).to be_success
      expect(@user.communication_channels.length).to eq 1
      expect(@user.email_channel).to be_unconfirmed
      expect(@user.email_channel.path).to eq 'jt@instructure.com'
    end

    it "should create a new CC regardless of conflicts" do
      u = User.create!
      cc = u.communication_channels.create!(:path => 'jt@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email' }
      expect(response).to be_success
      expect(@user.communication_channels.length).to eq 1
      expect(@user.email_channel).not_to eq cc
      expect(@user.email_channel).to be_unconfirmed
      expect(@user.email_channel.path).to eq 'jt@instructure.com'
    end

    it "should resurrect retired CCs" do
      cc = @user.communication_channels.create!(:path => 'jt@instructure.com', :path_type => 'email') { |cc|
        cc.workflow_state = 'retired'
        cc.bounce_count = CommunicationChannel::RETIRE_THRESHOLD
      }
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email' }
      expect(response).to be_success
      expect(@user.communication_channels.length).to eq 1
      expect(@user.email_channel).to be_unconfirmed
      expect(@user.email_channel.path).to eq 'jt@instructure.com'
      expect(@user.email_channel).to eq cc
    end

    it "should not allow duplicate active CCs for a single user" do
      cc = @user.communication_channels.create!(:path => 'jt@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email' }
      expect(response).not_to be_success
    end
  end

  describe "GET 'confirm'" do
    context "add CC to existing user" do
      before(:once) { user_with_pseudonym(active_user: 1) }

      it "should confirm an unconfirmed CC" do
        user_session(@user, @pseudonym)
        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to be_redirect
        expect(response).to redirect_to(user_profile_url(@user))
        @cc.reload
        expect(@cc).to be_active
      end

      it "should redirect to login when trying to confirm" do
        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to be_redirect
        expect(response).to redirect_to(login_url(:pseudonym_session => { :unique_id => @pseudonym.unique_id }, :expected_user_id => @pseudonym.user_id))
      end

      it "should require the correct user to confirm a cc" do
        @user1 = @user
        @pseudonym1 = @pseudonym
        user_with_pseudonym(:active_user => 1, :username => 'jt@instructure.com')

        user_session(@user1, @pseudonym1)

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to redirect_to(login_url(:pseudonym_session => { :unique_id => @pseudonym.unique_id }, :expected_user_id => @pseudonym.user_id))
      end

      it "should not confirm an already-confirmed CC with a registered user" do
        user_with_pseudonym
        @user.register
        user_session(@user, @pseudonym)
        code = @cc.confirmation_code
        @cc.confirm
        get 'confirm', :nonce => code
        expect(response).not_to be_success
        expect(response).to render_template("confirm_failed")
        @cc.reload
        expect(@cc).to be_active
      end

      it "does not confirm invalid email addresses" do
        user_with_pseudonym(:active_user => 1, :username => 'not-an-email')
        user_session(@user, @pseudonym)
        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).not_to be_success
        expect(response).to render_template("confirm_failed")
      end

      it "should confirm an already-confirmed CC with a pre-registered user" do
        user_with_pseudonym
        user_session(@user, @pseudonym)
        code = @cc.confirmation_code
        @cc.confirm
        get 'confirm', :nonce => code
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
      end
    end

    describe "open registration" do
      before :once do
        @account = Account.create!
        course(:active_all => 1, :account => @account)
        user
      end

      it "should show a pre-registered user the confirmation form" do
        user_with_pseudonym(:password => :autogenerate)
        @user.accept_terms
        @user.save
        expect(@user).to be_pre_registered

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to render_template('confirm')
        expect(assigns[:pseudonym]).to eq @pseudonym
        expect(assigns[:merge_opportunities]).to eq []
        @user.reload
        expect(@user).not_to be_registered
      end

      it "should finalize registration for a pre-registered user" do
        user_with_pseudonym(:password => :autogenerate)
        @user.accept_terms
        @user.save
        expect(@user).to be_pre_registered

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @cc.reload
        expect(@cc).to be_active
      end

      it "should properly validate pseudonym for a pre-registered user" do
        u1 = user_with_communication_channel(:username => 'asdf@qwerty.com', :user_state => 'creation_pending')
        cc1 = @cc
        # another user claimed the pseudonym
        u2 = user_with_pseudonym(:username => 'asdf@qwerty.com', :active_user => true)

        post 'confirm', :nonce => cc1.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        assert_status(400)
        u1.reload
        expect(u1).not_to be_registered
      end

      it "should not forget the account when registering for a non-default account" do
        @course = Course.create!(:account => @account) { |c| c.workflow_state = 'available' }
        user_with_pseudonym(:account => @account, :password => :autogenerate)
        @user.accept_terms
        @user.save
        @enrollment = @course.enroll_user(@user)
        expect(@pseudonym.account).to eq @account
        expect(@user).to be_pre_registered

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @pseudonym.reload
        expect(@pseudonym.account).to eq @account
      end

      it "should figure out the correct domain when registering" do
        user_with_pseudonym(:account => @account, :password => :autogenerate)
        expect(@pseudonym.account).to eq @account
        expect(@user).to be_pre_registered

        # @domain_root_account == Account.default
        post 'confirm', :nonce => @cc.confirmation_code
        expect(response).to be_success
        expect(response).to render_template('confirm')
        expect(assigns[:pseudonym]).to eq @pseudonym
        expect(assigns[:root_account]).to eq @account
      end

      it "should not finalize registration for invalid parameters" do
        user_with_pseudonym(:password => :autogenerate)
        @cc.confirm!
        get 'confirm', :nonce => "asdf"
        expect(response).to render_template("confirm_failed")
        @pseudonym.reload
        expect(@pseudonym.user).not_to be_registered
      end

      it "should show the confirm form for a creation_pending user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        expect(response).to be_success
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq 'jt@instructure.com'
      end

      it "should register creation_pending user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
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
        expect(@pseudonym.unique_id).to eq 'jt@instructure.com'
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "should show the confirm form for a creation_pending user that's logged in (masquerading)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        # not a full user session; just @current_user is set
        controller.instance_variable_set(:@current_user, @user)

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to be_success
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq 'jt@instructure.com'
      end

      it "should register creation_pending user that's logged in (masquerading)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        # not a full user session; just @current_user is set
        controller.instance_variable_set(:@current_user, @user)
        @domain_root_account = Account.default

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        expect(response).to be_redirect
        expect(response).to redirect_to(dashboard_url)
        @user.reload
        expect(@user).to be_registered
        @cc.reload
        expect(@cc).to be_active
        expect(@user.pseudonyms.length).to eq 1
        @pseudonym = @user.pseudonyms.first
        expect(@pseudonym).to be_active
        expect(@pseudonym.unique_id).to eq 'jt@instructure.com'
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "should prepare to register a creation_pending user in the correct account" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to be_success
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq 'jt@instructure.com'
        expect(assigns[:pseudonym].account).to eq @account
        expect(assigns[:root_account]).to eq @account
      end

      it "should register creation_pending user in the correct account" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
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
        expect(@pseudonym.unique_id).to eq 'jt@instructure.com'
        expect(@pseudonym.account).to eq @account
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "should prepare to register a creation_pending user in the correct account (admin)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @account.account_users.create!(user: @user)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        expect(@user).to be_creation_pending

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to be_success
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq 'jt@instructure.com'
        expect(assigns[:pseudonym].account).to eq @account
        expect(assigns[:root_account]).to eq @account
      end

      it "should register creation_pending user in the correct account (admin)" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @account.account_users.create!(user: @user)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        expect(@user).to be_creation_pending

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        expect(response).to be_redirect
        @user.reload
        expect(@user).to be_registered
        @cc.reload
        expect(@cc).to be_active
        expect(@user.pseudonyms.length).to eq 1
        @pseudonym = @user.pseudonyms.first
        expect(@pseudonym).to be_active
        expect(@pseudonym.unique_id).to eq 'jt@instructure.com'
        expect(@pseudonym.account).to eq @account
        # communication_channel is redefed to do a lookup
        expect(@pseudonym.communication_channel_id).to eq @cc.id
      end

      it "should show the confirm form for old creation_pending users that have a pseudonym" do
        course(:active_all => 1)
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited
        @pseudonym = @user.pseudonyms.create!(:unique_id => 'jt@instructure.com')
        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        expect(response).to be_success
        expect(assigns[:pseudonym]).to eq @pseudonym
      end

      it "should work for old creation_pending users that have a pseudonym" do
        course(:active_all => 1)
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited
        @pseudonym = @user.pseudonyms.create!(:unique_id => 'jt@instructure.com')

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
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

      it "should allow the user to pick a new pseudonym if a conflict already exists" do
        user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com')
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        expect(response).to be_success
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to be_blank
      end

      it "should force the user to provide a unique_id if a conflict already exists" do
        user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com')
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        expect(@user).to be_creation_pending
        expect(@enrollment).to be_invited

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        assert_status(400)
      end
    end

    describe "merging" do
      before :once do
        @account1 = Account.create!(:name => 'A')
        @account2 = Account.create!(:name => 'B')
      end

      it "should prepare to merge with an already-logged-in user" do
        user_with_pseudonym(:username => 'jt+1@instructure.com')
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        # render merge opportunities
        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code
        expect(response).to render_template('confirm')
        expect(assigns[:merge_opportunities]).to eq [[@user, [@pseudonym]]]
      end

      it "should merge with an already-logged-in user" do
        user_with_pseudonym(:username => 'jt+1@instructure.com')
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        @domain_root_account = Account.default

        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code, :confirm => 1
        expect(response).to redirect_to(dashboard_url)

        @not_logged_user.reload
        expect(@not_logged_user).to be_deleted
        @logged_user.reload
        expect(@logged_user.communication_channels.map(&:path).sort).to eq ['jt@instructure.com', 'jt+1@instructure.com'].sort
        expect(@logged_user.communication_channels.all? { |cc| cc.active? }).to be_truthy
      end

      it "should not allow merging with someone that's observed through a UserObserver relationship" do
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1)
        @logged_user = @user

        @not_logged_user.observers << @logged_user

        user_session(@logged_user, @pseudonym)

        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code, :confirm => 1
        expect(response).to render_template('confirm_failed')
      end

      it "should not allow merging with someone that's observing through a UserObserver relationship" do
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1)
        @logged_user = @user

        @logged_user.observers << @not_logged_user

        user_session(@logged_user, @pseudonym)

        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code, :confirm => 1
        expect(response).to render_template('confirm_failed')
      end

      it "should not allow merging with someone that's not a merge opportunity" do
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code, :confirm => 1
        expect(response).to render_template('confirm_failed')
      end

      it "should show merge opportunities for active users" do
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @user1 = @user
        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to render_template('confirm')
        expect(assigns[:merge_opportunities]).to eq [[@user1, [@user1.pseudonym]]]
      end

      it "should not show users that can't have a pseudonym created for the correct account" do
        Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
        @account1.authentication_providers.scope.delete_all
        @account1.authentication_providers.create!(:auth_type => 'cas')
        user_with_pseudonym(:active_all => 1, :account => @account1, :username => 'jt@instructure.com')

        course(:active_all => 1, :account => @account2)
        user
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_user(@user)

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        expect(response).to render_template('confirm')
        expect(assigns[:merge_opportunities]).to eq []
      end

      it "should create a pseudonym in the target account by copying an existing pseudonym when merging" do
        Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
        user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com')
        @old_user = @user

        course(:active_all => 1, :account => @account2)
        user
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_user(@user)
        user_session(@old_user, @old_user.pseudonym)

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :confirm => 1
        expect(response).to redirect_to(course_url(@course))
        @old_user.reload
        @user.reload
        expect(@user).to be_deleted
        @enrollment.reload
        expect(@enrollment.user).to eq @old_user
        expect(@old_user.pseudonyms.length).to eq 2
        expect(@old_user.pseudonyms.detect { |p| p.account == @account2 }.unique_id).to eq 'jt@instructure.com'
      end

      it "should include all pseudonyms if there are multiple" do
        Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :account => @account1)
        @pseudonym1 = @pseudonym
        @user1 = @user
        @pseudonym2 = @account2.pseudonyms.create!(:user => @user1, :unique_id => 'jt')

        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1, :account => Account.default)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to render_template('confirm')
        expect(assigns[:merge_opportunities]).to eq [[@user1, [@pseudonym1, @pseudonym2]]]
      end

      it "should only include the current account's pseudonym if there are multiple" do
        @account1 = Account.default
        @account2 = Account.create!
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :account => @account1)
        @pseudonym1 = @pseudonym
        @user1 = @user
        @pseudonym2 = @account2.pseudonyms.create!(:user => @user1, :unique_id => 'jt')

        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1, :account => @account1)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }

        get 'confirm', :nonce => @cc.confirmation_code
        expect(response).to render_template('confirm')
        expect(assigns[:merge_opportunities]).to eq [[@user1, [@pseudonym1]]]
      end
    end

    describe "invitations" do
      before(:once) { course_with_student(:active_course => 1) }

      it "should prepare to accept an invitation when creating a new user" do
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        expect(response).to be_success
        expect(assigns[:current_user]).to be_nil
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq 'jt@instructure.com'
      end

      it "should accept an invitation when creating a new user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
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

      it "should reject pseudonym unique_id changes when creating a new user" do
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:unique_id => "haxxor@example.com", :password => 'asdfasdf', :password_confirmation => 'asdfasdf'}

        expect(@user.reload.pseudonyms.first.unique_id).to eq "jt@instructure.com"
      end

      it "should accept an invitation when merging with the current user" do
        @user.update_attribute(:workflow_state, 'creation_pending')
        @old_cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @old_user = @user

        user_with_pseudonym(:active_all => 1, :username => 'bob@instructure.com')
        user_session(@user, @pseudonym)

        get 'confirm', :nonce => @old_cc.confirmation_code, :enrollment => @enrollment.uuid
        expect(response).to render_template('confirm')
        expect(assigns[:current_user]).to eq @user
        expect(assigns[:pseudonym]).to be_new_record
        expect(assigns[:pseudonym].unique_id).to eq 'jt@instructure.com'
        expect(assigns[:merge_opportunities]).to eq [[@user, [@pseudonym]]]
      end

      it "should accept an invitation when merging with the current user" do
        @user.update_attribute(:workflow_state, 'creation_pending')
        @old_cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @old_user = @user

        user_with_pseudonym(:active_all => 1, :username => 'bob@instructure.com')
        user_session(@user, @pseudonym)

        post 'confirm', :nonce => @old_cc.confirmation_code, :enrollment => @enrollment.uuid, :confirm => 1
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

      it "should prepare to transfer an enrollment to a different user" do
        course_with_student(:active_user => 1, :active_course => 1)
        @student_cc = @user.communication_channels.create!(:path => 'someone@somewhere.com') { |cc| cc.workflow_state = 'active' }
        user_with_pseudonym(:active_all => 1)
        user_session(@user, @pseudonym)

        get 'confirm', :nonce => @student_cc.confirmation_code, :enrollment => @enrollment.uuid
        expect(response).to render_template('confirm')
      end

      it "should transfer an enrollment to a different user" do
        course_with_student(:active_user => 1, :active_course => 1)
        @student_cc = @user.communication_channels.create!(:path => 'someone@somewhere.com') { |cc| cc.workflow_state = 'active' }
        user_with_pseudonym(:active_all => 1)
        user_session(@user, @pseudonym)

        get 'confirm', :nonce => @student_cc.confirmation_code, :enrollment => @enrollment.uuid, :transfer_enrollment => 1
        expect(response).to redirect_to(course_url(@course))
        @enrollment.reload
        expect(@enrollment).to be_active
        expect(@enrollment.user).to eq @user
      end
    end

    it "should uncache user's cc's when confirming a CC" do
      user_with_pseudonym(:active_user => true)
      user_session(@user, @pseudonym)
      User.record_timestamps = false
      begin
        @user.update_attribute(:updated_at, 1.second.ago)
        enable_cache do
          expect(@user.cached_active_emails).to eq []
          @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
          expect(@user.cached_active_emails).to eq []
          get 'confirm', :nonce => @cc.confirmation_code
          @user.reload
          expect(@user.cached_active_emails).to eq ['jt@instructure.com']
        end
      ensure
        User.record_timestamps = true
      end
    end
  end

  describe "POST 'reset_bounce_count'" do
    it 'should allow siteadmins to reset the bounce count' do
      u = user_with_pseudonym
      cc1 = u.communication_channels.create!(:path => 'test@example.com', :path_type => 'email') do |cc|
        cc.workflow_state = 'active'
        cc.bounce_count = 3
      end
      account_admin_user(account: Account.site_admin)
      user_session(@user)
      session[:become_user_id] = u.id
      post 'reset_bounce_count', :user_id => u.id, :id => cc1.id
      expect(response).to be_success
      cc1.reload
      expect(cc1.bounce_count).to eq(0)
    end

    it 'should not allow account admins to reset the bounce count' do
      u = user_with_pseudonym
      cc1 = u.communication_channels.create!(:path => 'test@example.com', :path_type => 'email') do |cc|
        cc.workflow_state = 'active'
        cc.bounce_count = 3
      end
      account_admin_user(account: Account.default)
      user_session(@user)
      session[:become_user_id] = u.id
      post 'reset_bounce_count', :user_id => u.id, :id => cc1.id
      expect(response).to have_http_status(401)
      cc1.reload
      expect(cc1.bounce_count).to eq(3)
    end
  end

  context 'bulk actions' do

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
          cc.last_bounce_at.try(:to_s),
          cc.last_bounce_summary.try(:to_s)
        ]
      end

      context 'as a site admin' do
        before do
          account_admin_user(account: Account.site_admin)
          user_session(@user)
        end

        it 'fetches communication channels in this account and orders by date' do
          now = Time.zone.now

          u1 = user_with_pseudonym
          u2 = user_with_pseudonym
          c1 = u1.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
            cc.last_bounce_at = now
          end
          c2 = u1.communication_channels.create!(path: 'two@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 2
            cc.last_bounce_at = now - 1.hour
          end
          c3 = u2.communication_channels.create!(path: 'three@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 3
            cc.last_bounce_at = now + 1.hour
            cc.last_bounce_details = {'bouncedRecipients' => [{'diagnosticCode' => 'stuff and things'}]}
          end

          get 'bouncing_channel_report', account_id: Account.default.id
          expect(response).to have_http_status(:ok)

          csv = CSV.parse(response.body)
          expect(csv).to eq [
            ['User ID', 'Name', 'Communication channel ID', 'Type', 'Path', 'Date of most recent bounce', 'Bounce reason'],
            channel_csv(c2),
            channel_csv(c1),
            channel_csv(c3)
          ]
        end

        it 'ignores communication channels in other accounts' do
          u1 = user_with_pseudonym
          a = account_model
          u2 = user_with_pseudonym(account: a)

          c1 = u1.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end
          u2.communication_channels.create!(path: 'two@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end

          get 'bouncing_channel_report', account_id: Account.default.id

          expect(included_channels).to eq([c1])
        end

        it "only reports active, bouncing communication channels" do
          user_with_pseudonym

          c1 = @user.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end
          @user.communication_channels.create!(path: 'two@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
          end
          @user.communication_channels.create!(path: 'three@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'retired'
            cc.bounce_count = 1
          end

          get 'bouncing_channel_report', account_id: Account.default.id

          expect(included_channels).to eq([c1])
        end

        it 'uses the requested account' do
          a = account_model
          user_with_pseudonym(account: a)

          c = @user.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end

          get 'bouncing_channel_report', account_id: a.id

          expect(included_channels).to eq([c])
        end

        it 'filters by date' do
          user_with_pseudonym

          @user.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now - 1.day
          end
          c2 = @user.communication_channels.create!(path: 'two@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now
          end
          @user.communication_channels.create!(path: 'three@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now + 1.day
          end

          get 'bouncing_channel_report', account_id: Account.default.id,
                                         before: Time.zone.now + 1.hour,
                                         after: Time.zone.now - 1.hour

          expect(included_channels).to eq([c2])
        end

        it 'filters by pattern, and case insensitively' do
          user_with_pseudonym

          # Uppercase "A" in the path to make sure it's matching case insensitively
          c1 = @user.communication_channels.create!(path: 'bAr@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end
          @user.communication_channels.create!(path: 'foobar@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end

          get 'bouncing_channel_report', account_id: Account.default.id, pattern: 'bar*'

          expect(included_channels).to eq([c1])
        end

        it 'limits to CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit' do
          CommunicationChannel::BulkActions::ResetBounceCounts.stubs(:bulk_limit).returns(5)
          now = Time.zone.now

          user_with_pseudonym

          ccs = (CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit + 1).times.map do |n|
            @user.communication_channels.create!(path: "c#{n}@example.com", path_type: 'email') do |cc|
              cc.workflow_state = 'active'
              cc.bounce_count = 1
              cc.last_bounce_at = now + n.minutes
            end
          end

          get 'bouncing_channel_report', account_id: Account.default.id

          expect(included_channels).to eq(ccs.first(CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit))
        end
      end

      context 'as a normal user' do
        it "doesn't work" do
          user_with_pseudonym
          user_session(@user)
          get 'bouncing_channel_report', account_id: Account.default.id
          expect(response).to have_http_status(401)
        end
      end
    end

    describe "POST 'bulk_reset_bounce_counts'" do
      context 'as a site admin' do
        before do
          account_admin_user(account: Account.site_admin)
          user_session(@user)
        end

        it 'resets bounce counts' do
          u1 = user_with_pseudonym
          u2 = user_with_pseudonym
          c1 = u1.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end
          c2 = u1.communication_channels.create!(path: 'two@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 2
          end
          c3 = u2.communication_channels.create!(path: 'three@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 3
          end

          post 'bulk_reset_bounce_counts', account_id: Account.default.id

          expect(response).to have_http_status(:ok)
          [c1, c2, c3].each_with_index do |c,i|
            expect(c.reload.bounce_count).to eq(i+1)
          end
          run_jobs
          [c1, c2, c3].each do |c|
            expect(c.reload.bounce_count).to eq(0)
          end
        end

        it 'filters by date' do
          user_with_pseudonym

          c1 = @user.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now - 1.day
          end
          c2 = @user.communication_channels.create!(path: 'two@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now
          end
          c3 = @user.communication_channels.create!(path: 'three@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
            cc.last_bounce_at = Time.zone.now + 1.day
          end

          post 'bulk_reset_bounce_counts', account_id: Account.default.id,
                                           before: Time.zone.now + 1.hour,
                                           after: Time.zone.now - 1.hour

          run_jobs
          expect(c1.reload.bounce_count).to eq(1)
          expect(c2.reload.bounce_count).to eq(0)
          expect(c3.reload.bounce_count).to eq(1)
        end

        it 'filters by pattern' do
          user_with_pseudonym

          c1 = @user.communication_channels.create!(path: 'bar@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end
          c2 = @user.communication_channels.create!(path: 'foobar@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end

          post 'bulk_reset_bounce_counts', account_id: Account.default.id, pattern: 'bar*'

          run_jobs
          expect(c1.reload.bounce_count).to eq(0)
          expect(c2.reload.bounce_count).to eq(1)
        end

        it 'respects the BULK_LIMIT' do
          CommunicationChannel::BulkActions::ResetBounceCounts.stubs(:bulk_limit).returns(5)
          now = Time.zone.now

          user_with_pseudonym

          ccs = (CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit + 1).times.map do |n|
            @user.communication_channels.create!(path: "c#{n}@example.com", path_type: 'email') do |cc|
              cc.workflow_state = 'active'
              cc.bounce_count = 1
              cc.last_bounce_at = now + n.minutes
            end
          end

          post 'bulk_reset_bounce_counts', account_id: Account.default.id

          run_jobs
          ccs.each(&:reload)
          expect(ccs[-1].bounce_count).to eq(1)
          ccs.first(CommunicationChannel::BulkActions::ResetBounceCounts.bulk_limit).each do |cc|
            expect(cc.bounce_count).to eq(0)
          end
        end
      end

      context 'as a normal user' do
        it "doesn't work" do
          user_with_pseudonym
          c = @user.communication_channels.create!(path: 'one@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
            cc.bounce_count = 1
          end

          user_with_pseudonym
          user_session(@user)

          post 'bulk_reset_bounce_counts', account_id: Account.default.id

          expect(response).to have_http_status(401)
          expect(c.reload.bounce_count).to eq(1)
        end
      end
    end

    context 'unconfirmed channels' do
      context 'as a siteadmin' do
        before do
          account_admin_user(account: Account.site_admin)
          user_session(@user)

          user_with_pseudonym

          @c1 = @user.communication_channels.create!(path: 'foo@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'unconfirmed'
          end
          @c2 = @user.communication_channels.create!(path: 'bar@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'unconfirmed'
          end
          @c3 = @user.communication_channels.create!(path: 'baz@example.com', path_type: 'email') do |cc|
            cc.workflow_state = 'active'
          end
          @c4 = @user.communication_channels.create!(path: 'qux@.', path_type: 'email') do |cc|
            cc.workflow_state = 'unconfirmed'
          end
          @c5 = @user.communication_channels.create!(path: '+18015550100', path_type: 'sms') do |cc|
            cc.workflow_state = 'unconfirmed'
          end
        end

        context "GET 'unconfirmed_channel_report'" do
          it 'reports channels' do
            get 'unconfirmed_channel_report', account_id: Account.default.id

            expect(response).to have_http_status(:ok)
            # can't expect to eq because we get stray channels for the users we created
            expect(included_channels).to include(@c1, @c2, @c5)
            expect(included_channels).to_not include(@c3, @c4)
          end

          it 'filters by path type' do
            get 'unconfirmed_channel_report', account_id: Account.default.id, path_type: 'sms'

            expect(response).to have_http_status(:ok)
            expect(included_channels).to include(@c5)
            expect(included_channels).to_not include(@c1, @c2, @c3, @c4)
          end
        end

        context "POST 'bulk_confirm'" do
          it 'confirms channels' do
            post 'bulk_confirm', account_id: Account.default.id

            expect(@c1.reload.workflow_state).to eq('active')
            expect(@c2.reload.workflow_state).to eq('active')
          end

          it 'excludes channels with invalid paths' do
            post 'bulk_confirm', account_id: Account.default.id

            expect(@c4.reload.workflow_state).to eq('unconfirmed')
          end

          it 'includes channels with invalid paths if requested' do
            post 'bulk_confirm', account_id: Account.default.id, with_invalid_paths: '1'

            expect(@c1.reload.workflow_state).to eq('active')
            expect(@c2.reload.workflow_state).to eq('active')
            expect(@c4.reload.workflow_state).to eq('active')
          end
        end
      end

      context 'as a normal user' do
        before do
          user_with_pseudonym
          user_session(@user)
        end

        context "GET 'unconfirmed_channel_report'" do
          it "doesn't work" do
            get 'unconfirmed_channel_report', account_id: Account.default.id
            expect(response).to have_http_status(401)
          end
        end

        context "POST 'bulk_confirm'" do
          it "doesn't work" do
            post 'bulk_confirm', account_id: Account.default.id
            expect(response).to have_http_status(401)
          end
        end
      end
    end
  end

  it "should re-send communication channel invitation for an invited channel" do
    Notification.create(:name => 'Confirm Email Communication Channel')
    get 're_send_confirmation', :user_id => @pseudonym.user_id, :id => @cc.id
    expect(response).to be_success
    expect(assigns[:user]).to eql(@user)
    expect(assigns[:cc]).to eql(@cc)
    expect(assigns[:cc].messages_sent).not_to be_nil
  end

  it "should re-send enrollment invitation for an invited user" do
    course(:active_all => true)
    @enrollment = @course.enroll_user(@user)
    expect(@enrollment.context).to eql(@course)
    Notification.create(:name => 'Enrollment Invitation')
    get 're_send_confirmation', :user_id => @pseudonym.user_id, :id => @cc.id, :enrollment_id => @enrollment.id
    expect(response).to be_success
    expect(assigns[:user]).to eql(@user)
    expect(assigns[:enrollment]).to eql(@enrollment)
    expect(assigns[:enrollment].messages_sent).not_to be_nil
  end

  context "cross-shard user" do
    specs_require_sharding
    it "should re-send enrollment invitation for a cross-shard user" do
      course(:active_all => true)
      enrollment = nil
      @shard1.activate do
        user_with_pseudonym :active_cc => true
        enrollment = @course.enroll_student(@user)
      end
      Notification.create(:name => 'Enrollment Invitation')
      post 're_send_confirmation', :user_id => enrollment.user_id, :enrollment_id => enrollment.id
      expect(response).to be_success
      expect(assigns[:enrollment]).to eql(enrollment)
      expect(assigns[:enrollment].messages_sent).not_to be_nil
    end
  end

  it "should uncache user's cc's when retiring a CC" do
    user_session(@user, @pseudonym)
    User.record_timestamps = false
    begin
      @user.update_attribute(:updated_at, 10.seconds.ago)
      enable_cache do
        expect(@user.cached_active_emails).to eq []
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
        # still cached
        expect(@user.cached_active_emails).to eq []
        @user.update_attribute(:updated_at, 5.seconds.ago)
        expect(@user.cached_active_emails).to eq ['jt@instructure.com']
        delete 'destroy', :id => @cc.id
        @user.reload
        expect(@user.cached_active_emails).to eq []
      end
    ensure
      User.record_timestamps = true
    end
  end

  it "should not delete a required institutional channel" do
    user_session(@user, @pseudonym)
    Account.default.settings[:edit_institution_email] = false
    Account.default.save!
    @pseudonym.update_attribute(:sis_communication_channel_id, @pseudonym.communication_channel.id)

    delete 'destroy', :id => @pseudonym.communication_channel.id

    expect(response.code).to eq '401'
  end
end
