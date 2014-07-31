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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe CommunicationChannelsController do
  describe "POST 'create'" do
    it "should create a new CC unconfirmed" do
      user_model
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email'  }
      response.should be_success
      @user.communication_channels.length.should == 1
      @user.email_channel.should be_unconfirmed
      @user.email_channel.path.should == 'jt@instructure.com'
    end

    it "should create a new CC regardless of conflicts" do
      u = User.create!
      cc = u.communication_channels.create!(:path => 'jt@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
      user_model
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email' }
      response.should be_success
      @user.communication_channels.length.should == 1
      @user.email_channel.should_not == cc
      @user.email_channel.should be_unconfirmed
      @user.email_channel.path.should == 'jt@instructure.com'
    end

    it "should resurrect retired CCs" do
      user_model
      cc = @user.communication_channels.create!(:path => 'jt@instructure.com', :path_type => 'email') { |cc|
        cc.workflow_state = 'retired'
        cc.bounce_count = CommunicationChannel::RETIRE_THRESHOLD
      }
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email' }
      response.should be_success
      @user.communication_channels.length.should == 1
      @user.email_channel.should be_unconfirmed
      @user.email_channel.path.should == 'jt@instructure.com'
      @user.email_channel.should == cc
    end

    it "should not allow duplicate active CCs for a single user" do
      user_model
      cc = @user.communication_channels.create!(:path => 'jt@instructure.com', :path_type => 'email') { |cc| cc.workflow_state = 'active' }
      user_session(@user)
      post 'create', :user_id => @user.id, :communication_channel => { :address => 'jt@instructure.com', :type => 'email' }
      response.should_not be_success
    end
  end

  describe "GET 'confirm'" do
    context "add CC to existing user" do
      it "should confirm an unconfirmed CC" do
        user_with_pseudonym(:active_user => 1)
        user_session(@user, @pseudonym)
        get 'confirm', :nonce => @cc.confirmation_code
        response.should be_redirect
        response.should redirect_to(user_profile_url(@user))
        @cc.reload
        @cc.should be_active
      end

      it "should redirect to login when trying to confirm" do
        user_with_pseudonym(:active_user => 1)
        get 'confirm', :nonce => @cc.confirmation_code
        response.should be_redirect
        response.should redirect_to(login_url(:pseudonym_session => { :unique_id => @pseudonym.unique_id }, :expected_user_id => @pseudonym.user_id))
      end

      it "should require the correct user to confirm a cc" do
        user_with_pseudonym(:active_all => 1)
        @user1 = @user
        @pseudonym1 = @pseudonym
        user_with_pseudonym(:active_user => 1, :username => 'jt@instructure.com')

        user_session(@user1, @pseudonym1)

        get 'confirm', :nonce => @cc.confirmation_code
        response.should redirect_to(login_url(:pseudonym_session => { :unique_id => @pseudonym.unique_id }, :expected_user_id => @pseudonym.user_id))
      end

      it "should not confirm an already-confirmed CC" do
        user_with_pseudonym
        user_session(@user, @pseudonym)
        code = @cc.confirmation_code
        @cc.confirm
        get 'confirm', :nonce => code
        response.should_not be_success
        response.should render_template("confirm_failed")
        @cc.reload
        @cc.should be_active
      end
    end

    describe "open registration" do
      it "should show a pre-registered user the confirmation form" do
        user_with_pseudonym(:password => :autogenerate)
        @user.accept_terms
        @user.save
        @user.should be_pre_registered

        get 'confirm', :nonce => @cc.confirmation_code
        response.should render_template('confirm')
        assigns[:pseudonym].should == @pseudonym
        assigns[:merge_opportunities].should == []
        @user.reload
        @user.should_not be_registered
      end

      it "should finalize registration for a pre-registered user" do
        user_with_pseudonym(:password => :autogenerate)
        @user.accept_terms
        @user.save
        @user.should be_pre_registered

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        @user.reload
        @user.should be_registered
        @cc.reload
        @cc.should be_active
      end

      it "should properly validate pseudonym for a pre-registered user" do
        u1 = user_with_communication_channel(:username => 'asdf@qwerty.com', :user_state => 'creation_pending')
        cc1 = @cc
        # another user claimed the pseudonym
        u2 = user_with_pseudonym(:username => 'asdf@qwerty.com', :active_user => true)

        post 'confirm', :nonce => cc1.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        assert_status(400)
        u1.reload
        u1.should_not be_registered
      end

      it "should not forget the account when registering for a non-default account" do
        @account = Account.create!
        @course = Course.create!(:account => @account) { |c| c.workflow_state = 'available' }
        user_with_pseudonym(:account => @account, :password => :autogenerate)
        @user.accept_terms
        @user.save
        @enrollment = @course.enroll_user(@user)
        @pseudonym.account.should == @account
        @user.should be_pre_registered

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        @user.reload
        @user.should be_registered
        @pseudonym.reload
        @pseudonym.account.should == @account
      end

      it "should figure out the correct domain when registering" do
        @account = Account.create!
        user_with_pseudonym(:account => @account, :password => :autogenerate)
        @pseudonym.account.should == @account
        @user.should be_pre_registered

        # @domain_root_account == Account.default
        post 'confirm', :nonce => @cc.confirmation_code
        response.should be_success
        response.should render_template('confirm')
        assigns[:pseudonym].should == @pseudonym
        assigns[:root_account].should == @account
      end

      it "should not finalize registration for invalid parameters" do
        user_with_pseudonym(:password => :autogenerate)
        @cc.confirm!
        get 'confirm', :nonce => "asdf"
        response.should render_template("confirm_failed")
        @pseudonym.reload
        @pseudonym.user.should_not be_registered
      end

      it "should show the confirm form for a creation_pending user" do
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        response.should be_success
        assigns[:pseudonym].should be_new_record
        assigns[:pseudonym].unique_id.should == 'jt@instructure.com'
      end

      it "should register creation_pending user" do
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        response.should redirect_to(course_url(@course))
        @user.reload
        @user.should be_registered
        @enrollment.reload
        @enrollment.should be_active
        @cc.reload
        @cc.should be_active
        @user.pseudonyms.length.should == 1
        @pseudonym = @user.pseudonyms.first
        @pseudonym.should be_active
        @pseudonym.unique_id.should == 'jt@instructure.com'
        # communication_channel is redefed to do a lookup
        @pseudonym.communication_channel_id.should == @cc.id
      end

      it "should show the confirm form for a creation_pending user that's logged in (masquerading)" do
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        # not a full user session; just @current_user is set
        controller.instance_variable_set(:@current_user, @user)

        get 'confirm', :nonce => @cc.confirmation_code
        response.should be_success
        assigns[:pseudonym].should be_new_record
        assigns[:pseudonym].unique_id.should == 'jt@instructure.com'
      end

      it "should register creation_pending user that's logged in (masquerading)" do
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        # not a full user session; just @current_user is set
        controller.instance_variable_set(:@current_user, @user)

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        response.should redirect_to(dashboard_url)
        @user.reload
        @user.should be_registered
        @cc.reload
        @cc.should be_active
        @user.pseudonyms.length.should == 1
        @pseudonym = @user.pseudonyms.first
        @pseudonym.should be_active
        @pseudonym.unique_id.should == 'jt@instructure.com'
        # communication_channel is redefed to do a lookup
        @pseudonym.communication_channel_id.should == @cc.id
      end

      it "should prepare to register a creation_pending user in the correct account" do
        @account = Account.create!
        course(:active_all => 1, :account => @account)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited

        get 'confirm', :nonce => @cc.confirmation_code
        response.should be_success
        assigns[:pseudonym].should be_new_record
        assigns[:pseudonym].unique_id.should == 'jt@instructure.com'
        assigns[:pseudonym].account.should == @account
        assigns[:root_account].should == @account
      end

      it "should register creation_pending user in the correct account" do
        @account = Account.create!
        course(:active_all => 1, :account => @account)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        @user.reload
        @user.should be_registered
        @enrollment.reload
        @enrollment.should be_invited
        @cc.reload
        @cc.should be_active
        @user.pseudonyms.length.should == 1
        @pseudonym = @user.pseudonyms.first
        @pseudonym.should be_active
        @pseudonym.unique_id.should == 'jt@instructure.com'
        @pseudonym.account.should == @account
        # communication_channel is redefed to do a lookup
        @pseudonym.communication_channel_id.should == @cc.id
      end

      it "should prepare to register a creation_pending user in the correct account (admin)" do
        @account = Account.create!
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @account.account_users.create!(user: @user)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @user.should be_creation_pending

        get 'confirm', :nonce => @cc.confirmation_code
        response.should be_success
        assigns[:pseudonym].should be_new_record
        assigns[:pseudonym].unique_id.should == 'jt@instructure.com'
        assigns[:pseudonym].account.should == @account
        assigns[:root_account].should == @account
      end

      it "should register creation_pending user in the correct account (admin)" do
        @account = Account.create!
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @account.account_users.create!(user: @user)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @user.should be_creation_pending

        post 'confirm', :nonce => @cc.confirmation_code, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        @user.reload
        @user.should be_registered
        @cc.reload
        @cc.should be_active
        @user.pseudonyms.length.should == 1
        @pseudonym = @user.pseudonyms.first
        @pseudonym.should be_active
        @pseudonym.unique_id.should == 'jt@instructure.com'
        @pseudonym.account.should == @account
        # communication_channel is redefed to do a lookup
        @pseudonym.communication_channel_id.should == @cc.id
      end

      it "should show the confirm form for old creation_pending users that have a pseudonym" do
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited
        @pseudonym = @user.pseudonyms.create!(:unique_id => 'jt@instructure.com')
        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        response.should be_success
        assigns[:pseudonym].should == @pseudonym
      end

      it "should work for old creation_pending users that have a pseudonym" do
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited
        @pseudonym = @user.pseudonyms.create!(:unique_id => 'jt@instructure.com')

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        response.should redirect_to(course_url(@course))
        @user.reload
        @user.should be_registered
        @enrollment.reload
        @enrollment.should be_active
        @cc.reload
        @cc.should be_active
        @user.pseudonyms.length.should == 1
        @pseudonym.reload
        @pseudonym.should be_active
        # communication_channel is redefed to do a lookup
        @pseudonym.communication_channel_id.should == @cc.id
      end

      it "should allow the user to pick a new pseudonym if a conflict already exists" do
        user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com')
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        response.should be_success
        assigns[:pseudonym].should be_new_record
        assigns[:pseudonym].unique_id.should be_blank
      end

      it "should force the user to provide a unique_id if a conflict already exists" do
        user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com')
        course(:active_all => 1)
        user
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_student(@user)
        @user.should be_creation_pending
        @enrollment.should be_invited

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        assert_status(400)
      end
    end

    describe "merging" do
      it "should prepare to merge with an already-logged-in user" do
        user_with_pseudonym(:username => 'jt+1@instructure.com')
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        # render merge opportunities
        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code
        response.should render_template('confirm')
        assigns[:merge_opportunities].should == [[@user, [@pseudonym]]]
      end

      it "should merge with an already-logged-in user" do
        user_with_pseudonym(:username => 'jt+1@instructure.com')
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code, :confirm => 1
        response.should redirect_to(dashboard_url)

        @not_logged_user.reload
        @not_logged_user.should be_deleted
        @logged_user.reload
        @logged_user.communication_channels.map(&:path).sort.should == ['jt@instructure.com', 'jt+1@instructure.com'].sort
        @logged_user.communication_channels.all? { |cc| cc.active? }.should be_true
      end

      it "should not allow merging with someone that's not a merge opportunity" do
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @not_logged_user = @user
        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1)
        @logged_user = @user
        user_session(@logged_user, @pseudonym)

        get 'confirm', :nonce => @not_logged_user.email_channel.confirmation_code, :confirm => 1
        response.should render_template('confirm_failed')
      end

      it "should show merge opportunities for active users" do
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1)
        @user1 = @user
        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }

        get 'confirm', :nonce => @cc.confirmation_code
        response.should render_template('confirm')
        assigns[:merge_opportunities].should == [[@user1, [@user1.pseudonym]]]
      end

      it "should not show users that can't have a pseudonym created for the correct account" do
        Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
        @account1 = Account.create!
        @account1.account_authorization_configs.create!(:auth_type => 'cas')
        user_with_pseudonym(:active_all => 1, :account => @account1, :username => 'jt@instructure.com')

        @account2 = Account.create!
        course(:active_all => 1, :account => @account2)
        user
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_user(@user)

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        response.should render_template('confirm')
        assigns[:merge_opportunities].should == []
      end

      it "should create a pseudonym in the target account by copying an existing pseudonym when merging" do
        Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
        user_with_pseudonym(:active_all => 1, :username => 'jt@instructure.com')
        @old_user = @user

        @account2 = Account.create!
        course(:active_all => 1, :account => @account2)
        user
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @enrollment = @course.enroll_user(@user)
        user_session(@old_user, @old_user.pseudonym)

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :confirm => 1
        response.should redirect_to(course_url(@course))
        @old_user.reload
        @user.reload
        @user.should be_deleted
        @enrollment.reload
        @enrollment.user.should == @old_user
        @old_user.pseudonyms.length.should == 2
        @old_user.pseudonyms.detect { |p| p.account == @account2 }.unique_id.should == 'jt@instructure.com'
      end

      it "should include all pseudonyms if there are multiple" do
        Pseudonym.any_instance.stubs(:works_for_account?).returns(false)
        @account1 = Account.create!(:name => 'A')
        @account2 = Account.create!(:name => 'B')
        user_with_pseudonym(:username => 'jt@instructure.com', :active_all => 1, :account => @account1)
        @pseudonym1 = @pseudonym
        @user1 = @user
        @pseudonym2 = @account2.pseudonyms.create!(:user => @user1, :unique_id => 'jt')

        user_with_pseudonym(:username => 'jt+1@instructure.com', :active_all => 1, :account => Account.default)
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }

        get 'confirm', :nonce => @cc.confirmation_code
        response.should render_template('confirm')
        assigns[:merge_opportunities].should == [[@user1, [@pseudonym1, @pseudonym2]]]
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
        response.should render_template('confirm')
        assigns[:merge_opportunities].should == [[@user1, [@pseudonym1]]]
      end
    end

    describe "invitations" do
      it "should prepare to accept an invitation when creating a new user" do
        course_with_student(:active_course => 1)
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')

        get 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid
        response.should be_success
        assigns[:current_user].should be_nil
        assigns[:pseudonym].should be_new_record
        assigns[:pseudonym].unique_id.should == 'jt@instructure.com'
      end

      it "should accept an invitation when creating a new user" do
        course_with_student(:active_course => 1)
        @user.accept_terms
        @user.update_attribute(:workflow_state, 'creation_pending')
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')

        post 'confirm', :nonce => @cc.confirmation_code, :enrollment => @enrollment.uuid, :register => 1, :pseudonym => {:password => 'asdfasdf', :password_confirmation => 'asdfasdf'}
        response.should be_redirect
        response.should redirect_to(course_url(@course))
        @enrollment.reload
        @enrollment.should be_active
        @user.reload
        @user.should be_registered
        @user.pseudonyms.length.should == 1
        @cc.reload
        @cc.should be_active
      end

      it "should accept an invitation when merging with the current user" do
        course_with_student(:active_course => 1)
        @user.update_attribute(:workflow_state, 'creation_pending')
        @old_cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @old_user = @user

        user_with_pseudonym(:active_all => 1, :username => 'bob@instructure.com')
        user_session(@user, @pseudonym)

        get 'confirm', :nonce => @old_cc.confirmation_code, :enrollment => @enrollment.uuid
        response.should render_template('confirm')
        assigns[:current_user].should == @user
        assigns[:pseudonym].should be_new_record
        assigns[:pseudonym].unique_id.should == 'jt@instructure.com'
        assigns[:merge_opportunities].should == [[@user, [@pseudonym]]]
      end

      it "should accept an invitation when merging with the current user" do
        course_with_student(:active_course => 1)
        @user.update_attribute(:workflow_state, 'creation_pending')
        @old_cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
        @old_user = @user

        user_with_pseudonym(:active_all => 1, :username => 'bob@instructure.com')
        user_session(@user, @pseudonym)

        post 'confirm', :nonce => @old_cc.confirmation_code, :enrollment => @enrollment.uuid, :confirm => 1
        response.should redirect_to(course_url(@course))
        assigns[:current_user].should == @user
        @enrollment.reload
        @enrollment.should be_active
        @enrollment.user.should == @user
        @old_user.reload
        @old_user.should be_deleted
        @old_user.pseudonyms.length.should == 0
        @old_cc.reload
        @old_cc.user.should == @user
      end

      it "should prepare to transfer an enrollment to a different user" do
        course_with_student(:active_user => 1, :active_course => 1)
        @student_cc = @user.communication_channels.create!(:path => 'someone@somewhere.com') { |cc| cc.workflow_state = 'active' }
        user_with_pseudonym(:active_all => 1)
        user_session(@user, @pseudonym)

        get 'confirm', :nonce => @student_cc.confirmation_code, :enrollment => @enrollment.uuid
        response.should render_template('confirm')
      end

      it "should transfer an enrollment to a different user" do
        course_with_student(:active_user => 1, :active_course => 1)
        @student_cc = @user.communication_channels.create!(:path => 'someone@somewhere.com') { |cc| cc.workflow_state = 'active' }
        user_with_pseudonym(:active_all => 1)
        user_session(@user, @pseudonym)

        get 'confirm', :nonce => @student_cc.confirmation_code, :enrollment => @enrollment.uuid, :transfer_enrollment => 1
        response.should redirect_to(course_url(@course))
        @enrollment.reload
        @enrollment.should be_active
        @enrollment.user.should == @user
      end
    end

    it "should uncache user's cc's when confirming a CC" do
      user_with_pseudonym(:active_user => true)
      user_session(@user, @pseudonym)
      User.record_timestamps = false
      begin
        @user.update_attribute(:updated_at, 1.second.ago)
        enable_cache do
          @user.cached_active_emails.should == []
          @cc = @user.communication_channels.create!(:path => 'jt@instructure.com')
          @user.cached_active_emails.should == []
          get 'confirm', :nonce => @cc.confirmation_code
          @user.reload
          @user.cached_active_emails.should == ['jt@instructure.com']
        end
      ensure
        User.record_timestamps = true
      end
    end
  end

  it "should re-send communication channel invitation for an invited channel" do
    user_with_pseudonym(:active_user => true)
    Notification.create(:name => 'Confirm Email Communication Channel')
    get 're_send_confirmation', :user_id => @pseudonym.user_id, :id => @cc.id
    response.should be_success
    assigns[:user].should eql(@user)
    assigns[:cc].should eql(@cc)
    assigns[:cc].messages_sent.should_not be_nil
  end

  it "should re-send enrollment invitation for an invited user" do
    user_with_pseudonym(:active_user => true)
    course(:active_all => true)
    @enrollment = @course.enroll_user(@user)
    @enrollment.context.should eql(@course)
    Notification.create(:name => 'Enrollment Invitation')
    get 're_send_confirmation', :user_id => @pseudonym.user_id, :id => @cc.id, :enrollment_id => @enrollment.id
    response.should be_success
    assigns[:user].should eql(@user)
    assigns[:enrollment].should eql(@enrollment)
    assigns[:enrollment].messages_sent.should_not be_nil
  end

  it "should uncache user's cc's when retiring a CC" do
    user_with_pseudonym(:active_user => true)
    user_session(@user, @pseudonym)
    User.record_timestamps = false
    begin
      @user.update_attribute(:updated_at, 10.seconds.ago)
      enable_cache do
        @user.cached_active_emails.should == []
        @cc = @user.communication_channels.create!(:path => 'jt@instructure.com') { |cc| cc.workflow_state = 'active' }
        # still cached
        @user.cached_active_emails.should == []
        @user.update_attribute(:updated_at, 5.seconds.ago)
        @user.cached_active_emails.should == ['jt@instructure.com']
        delete 'destroy', :id => @cc.id
        @user.reload
        @user.cached_active_emails.should == []
      end
    ensure
      User.record_timestamps = true
    end
  end

  it "should not delete a required institutional channel" do
    user_with_pseudonym(:active_user => true)
    user_session(@user, @pseudonym)
    Account.default.settings[:edit_institution_email] = false
    Account.default.save!
    @pseudonym.update_attribute(:sis_communication_channel_id, @pseudonym.communication_channel.id)

    delete 'destroy', :id => @pseudonym.communication_channel.id

    response.code.should == '401'
  end
end
