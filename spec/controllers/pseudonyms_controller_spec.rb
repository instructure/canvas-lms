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

describe PseudonymsController do

  describe "registration" do
    it "should approve an unapproved communication channel" do
      user_with_pseudonym
      user_session(@user, @pseudonym)
      get 'claim_pseudonym', :id => @pseudonym, :nonce => @cc.confirmation_code, :claim => '1'
      response.should be_redirect
      response.should redirect_to(dashboard_url)
      @cc.reload
      @cc.should be_active
    end
    
    it "should not approve an already-approved communication channel" do
      user_with_pseudonym
      user_session(@user, @pseudonym)
      code = @cc.confirmation_code
      @cc.confirm
      get 'claim_pseudonym', :id => @pseudonym, :nonce => code, :claim => '1'
      response.should be_redirect
      response.should redirect_to(root_url)
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
      assigns[:cc].should eql(@cc)
      assigns[:enrollment].should eql(@enrollment)
      assigns[:enrollment].messages_sent.should_not be_nil
    end
    
    it "should send password-change email for a registered user" do
      user_with_pseudonym
      get 'forgot_password', :pseudonym_session => {:unique_id_forgot => @pseudonym.unique_id}
      response.should be_success
      assigns[:ccs].should include(@cc)
      assigns[:ccs].detect{|cc| cc == @cc}.messages_sent.should_not be_nil
    end
    
    it "should render confirm change password view for registered user's email" do
      user_with_pseudonym(:active_user => true)
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_success
    end
    
    it "should not render confirm change password view for non-email channels" do
      user_with_pseudonym(:active_user => true)
      @cc.update_attributes(:path_type => 'sms')
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_redirect
    end
    
    it "should render confirm change password view for unregistered user" do
      user_with_pseudonym
      get 'confirm_change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_success
    end
    
    it "should change the password if authorized" do
      user_with_pseudonym
      pword = @pseudonym.crypted_password
      code = @cc.confirmation_code
      post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code, :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
      response.should be_redirect
      assigns[:pseudonym].should eql(@pseudonym)
      assigns[:pseudonym].crypted_password.should_not eql(pword)
      assigns[:pseudonym].user.should be_registered
      assigns[:cc].confirmation_code.should_not eql(code)
      assigns[:cc].should be_active
    end
    
    it "should not change the password if unauthorized" do
      user_with_pseudonym
      pword = @pseudonym.crypted_password
      code = @cc.confirmation_code
      post 'change_password', :pseudonym_id => @pseudonym.id, :nonce => @cc.confirmation_code + 'a', :pseudonym => {:password => '12341234', :password_confirmation => '12341234'}
      response.should be_redirect
      assigns[:pseudonym].should eql(@pseudonym)
      assigns[:pseudonym].crypted_password.should eql(pword)
      assigns[:pseudonym].user.should_not be_registered
      @cc.reload
      @cc.confirmation_code.should eql(code)
      @cc.should_not be_active
    end
    
    it "should render 'claim pseudonym' page" do
      user_with_pseudonym
      get 'claim_pseudonym', :id => @pseudonym.id, :nonce => @cc.confirmation_code, :claim => '1'
      response.should be_success
      assigns[:pseudonym].should eql(@pseudonym)
    end
    
    it "should claim pseudonym for an already-logged-in user" do
      user
      @not_logged_user = @user
      user_with_pseudonym
      @logged_user = @user
      user_session(@logged_user, @pseudonym)
      @p2 = @not_logged_user.pseudonyms.create!(:unique_id => 'another@example.com', :path => 'another@example.com', :password => 'asdfqwer', :password_confirmation => 'asdfqwer')
      @cc2 = @p2.communication_channel
      get 'claim_pseudonym', :id => @p2.id, :nonce => @cc2.confirmation_code, :claim => '1'
      response.should be_redirect
      assigns[:pseudonym].reload
      assigns[:pseudonym].should eql(@p2)
      assigns[:pseudonym].user.should eql(@logged_user)
      assigns[:pseudonym].communication_channel.reload
      assigns[:pseudonym].communication_channel.should be_active
      @not_logged_user.reload
      @not_logged_user.should be_deleted
    end
    
    it "should finalize registration for a pre-registered user" do
      user_with_pseudonym
      get 'registration_confirmation', :id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_redirect
      @pseudonym.reload
      @pseudonym.user.should be_registered
      @cc.reload
      @cc.should be_active
    end
    
    it "should not finalize registration for invalid parameters" do
      user_with_pseudonym
      @cc.confirm!
      get 'registration_confirmation', :id => @pseudonym.id, :nonce => "asdf" #@cc.confirmation_code
      response.should render_template("registration_confirmation_failed")
      @pseudonym.reload
      @pseudonym.user.should_not be_registered
    end
    
    it "should register creation_pending user" do
      course
      @course.should_not be_available
      user_with_pseudonym
      @enrollment = @course.enroll_student(@user)
      @user.should_not be_registered
      @enrollment.should be_creation_pending
      get 'registration_confirmation', :id => @pseudonym.id, :nonce => @cc.confirmation_code
      response.should be_redirect
      @user.reload
      @user.should be_registered
    end
  end
  
  describe "destroy" do
    it "should not destroy if for the wrong user" do
      rescue_action_in_public!
      user_model
      @other_user = @user
      @other_pseudonym = @user.pseudonyms.create!(:unique_id => "test@test.com", :password => "password", :password_confirmation => "password")
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      delete 'destroy', :user_id => @user.id, :id => @other_pseudonym.id
      assert_status(404)
      @other_pseudonym.should be_active
      @pseudonym.should be_active

      delete 'destroy', :user_id => @other_user.id, :id => @pseudonym.id
      assert_unauthorized
      @other_pseudonym.should be_active
      @pseudonym.should be_active
    end
    
    it "should not destroy if it's the last active pseudonym" do
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      delete 'destroy', :user_id => @user.id, :id => @pseudonym.id
      assert_status(400)
      @pseudonym.should be_active
    end
    
    it "should destroy if for the current user with more than one pseudonym" do
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      @p2 = @user.pseudonyms.create!(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(200)
      @pseudonym.should be_active
      @p2.reload.should be_deleted
    end
    
    it "should not destroy if for the current user and it's a system-generated pseudonym" do
      rescue_action_in_public!
      user_with_pseudonym(:active_all => true)
      user_session(@user, @pseudonym)
      @p2 = @user.pseudonyms.create!(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      @p2.sis_source_id = 'test'
      @p2.save!
      @p2.account.account_authorization_config = AccountAuthorizationConfig.new(:auth_type => 'ldap')
      @p2.account.account_authorization_config.account_id = @pseudonym.account_id
      @p2.account.account_authorization_config.save!
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(500)
      @pseudonym.should be_active
      @p2.should be_active
    end
    
    it "should destroy if authorized to delete pseudonyms" do
      rescue_action_in_public!
      user_with_pseudonym(:active_all => true)
      Account.site_admin.add_user(@user)
      user_session(@user, @pseudonym)
      @p2 = @user.pseudonyms.build(:unique_id => "another_one@test.com",:password => 'password', :password_confirmation => 'password')
      @p2.sis_source_id = 'test'
      @p2.save!
      @p2.account.account_authorization_config = AccountAuthorizationConfig.new(:auth_type => 'ldap')
      @p2.account.account_authorization_config.account_id = @pseudonym.account_id
      @p2.account.account_authorization_config.save!
      delete 'destroy', :user_id => @user.id, :id => @p2.id
      assert_status(200)
      @pseudonym.should be_active
      @p2.should be_active
    end
  end

end
