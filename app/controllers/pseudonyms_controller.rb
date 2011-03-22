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

class PseudonymsController < ApplicationController
  before_filter :require_user, :only => [:create, :show, :edit, :update]
  protect_from_forgery :except => [:registration_confirmation, :change_password, :forgot_password]
  ssl_allowed :forgot_password
  ssl_required :change_password, :confirm_change_password, :registration_confirmation
  
  def forgot_password
    email = params[:pseudonym_session][:unique_id_forgot] if params[:pseudonym_session]
    @ccs = []
    @ccs = CommunicationChannel.find_all_by_path_and_path_type_and_workflow_state(email, 'email', 'active')
    if @ccs.empty?
      @ccs += CommunicationChannel.find_all_by_path_and_path_type(email, 'email') if email and !email.empty?
    end
    if @domain_root_account && email && !email.empty?
      @domain_root_account.pseudonyms.active.find_all_by_unique_id(email).each do |p|
        p.assert_communication_channel(true)
        cc = p.communication_channel if p.communication_channel && p.user
        cc ||= p.user.communication_channel rescue nil
        @ccs << cc
      end
    end
    @ccs = @ccs.flatten.compact.uniq.select do |cc|
      if !cc.user
        false
      else
        cc.user.pseudonyms.active.each{|p| p.assert_communication_channel(true) }
        cc.pseudonym ||= cc.user.pseudonym rescue nil
        cc.save if cc.changed?
        !cc.user.pseudonyms.active.empty? && cc.user.pseudonyms.active.any?{|p| p.account_id == @domain_root_account.id || (!@domain_root_account.require_account_pseudonym? && p.account && p.account.password_authentication?) }
      end
    end
    respond_to do |format|
      # Whether the email was actually found or not, we display the same
      # message. Otherwise this form could be used to fish for valid
      # email addresses.
      flash[:notice] = "Confirmation email sent to #{email}, make sure to check your spam box"
      @ccs.each do |cc|
        cc.forgot_password!
      end
      format.json { render :json => {:requested => true}.to_json }
      format.js { render :json => {:requested => true}.to_json }
      format.html { redirect_to(login_url) }
    end
  end
  
  def confirm_change_password
    @pseudonym = Pseudonym.find(params[:pseudonym_id])
    @cc = @pseudonym.user.communication_channels.find_by_confirmation_code(params[:nonce])
    @cc = nil if @pseudonym.managed_password?
    @headers = false
    # Allow unregistered users to change password.  How else can they come back later
    # and finish the registration process? 
    if !@cc || @cc.path_type != 'email'
      flash[:error] = "Cannot change the password for that login, or login does not exist"
      redirect_to root_url
    end
  end
  
  def change_password
    @pseudonym = Pseudonym.find(params[:pseudonym][:id] || params[:pseudonym_id])
    @cc = @pseudonym.user.communication_channels.find_by_confirmation_code(params[:nonce])
    if @cc
      @pseudonym.password = params[:pseudonym][:password]
      @pseudonym.password_confirmation = params[:pseudonym][:password_confirmation]
    end
    if @cc && @pseudonym.save
      # If they changed the password (and we subsequently log them in) then
      # we're pretty confident this is the right user, and the communication
      # channel is valid, so register the user and approve the channel.
      @cc.set_confirmation_code(true)
      @cc.confirm
      @pseudonym.user.register

      # reset the session id cookie to prevent session fixation.
      reset_session

      @pseudonym_session = PseudonymSession.new(@pseudonym, true)
      flash[:notice] = "Password changed"
      redirect_to dashboard_url
    elsif @cc
      render :action => "confirm_change_password"
    else
      flash[:notice] = "The link you used appears to no longer be valid.  If you can't login, try clicking \"Don't Know My Password\" and having a new message sent for you."
      redirect_to login_url
    end
  end

  def re_send_confirmation
    @user = User.find(params[:user_id])
    @cc = @user.communication_channels.find(params[:id])
    @enrollment = params[:enrollment_id] && @user.enrollments.find(params[:enrollment_id])
    if @enrollment && (@enrollment.invited? || @enrollment.active?)
      @enrollment.re_send_confirmation!
    elsif @cc.unconfirmed?
      @cc.send_confirmation!
    else
      @cc.send_confirmation!
    end
    render :json => {:re_sent => true}
  end
  
  def claim_pseudonym
    @pseudonym = Pseudonym.find(params[:id])
    @headers = false
    nonce = params[:nonce]
    cc = CommunicationChannel.find_by_user_id_and_confirmation_code(@pseudonym.user_id, nonce)
    cc = nil if cc && (!cc.unconfirmed? || cc.confirmation_code != nonce)
    if @pseudonym && !cc
      flash[:error] = "The login #{@pseudonym.unique_id} has already been registered.  If you're not sure how to log in, click \"Don't Know My Password\" and enter the login \"#{@pseudonym.unique_id}\""
      redirect_to root_url #"/"
      return
    end
    if params[:claim] && @current_user
      already_confirmed = !cc.unconfirmed?
      if cc and cc.confirm
        unless already_confirmed
          cc.user = @current_user
          cc.save
          @pseudonym.move_to_user(@current_user)
        end
        flash[:notice] = "Registration confirmed!"
        respond_to do |format|
          format.html { redirect_to_enrollment_or_profile }
          format.json { render :json => cc.to_json }
        end
      else
        flash[:notice] = "Registration failed."
        respond_to do |format|
          format.html { redirect_to claim_pseudonym_url(@pseudonym.id, nonce) }
          format.json { render :json => cc.to_json }
        end
      end
    else
      session[:return_to] = claim_pseudonym_url(params[:id], params[:nonce])
      @communication_channel = cc
      respond_to do |format|
        format.html
      end
    end
  end
  
  def redirect_to_enrollment_or_profile(redirect_back=false)
    if session[:enrollment_uuid] || session[:to_be_accepted_enrollment_uuid]
      @enrollment = Enrollment.find_by_uuid_and_workflow_state(session[:to_be_accepted_enrollment_uuid], "invited")
      @enrollment ||= Enrollment.find_by_uuid_and_workflow_state(session[:enrollment_uuid], "invited")
      @enrollment = nil unless @enrollment && @enrollment.user_id == @pseudonym.user_id
    end
    if @enrollment 
      @enrollment.accept! if @enrollment.invited?
      session[:accepted_enrollment_uuid] = @enrollment.uuid
      redirect_to course_url(@enrollment.course_id)
    else
      if redirect_back  
        redirect_back_or_default dashboard_url
      else
        redirect_to dashboard_url 
      end
    end
  end
  protected :redirect_to_enrollment_or_profile
  
  # Used for the initial student registration.  This is a good candidate
  # for refactoring, swapping out the common code in
  # registration_confirmation and claim_pseudonym.  The reason these are
  # both here is the case where the teacher invites a group of students,
  # some of them already have an account with us.  claim_pseudonym is used
  # for using an existing pseudonym.  registration_confirmation is used
  # for setting up a new one. 
  def registration_confirmation
    id = params[:id]
    nonce = params[:nonce]
    pseudonym = Pseudonym.find(id)
    cc = pseudonym.user.communication_channels.find_by_confirmation_code(nonce)
    enrollment = pseudonym.user.enrollments.find_by_uuid_and_workflow_state(params[:enrollment], 'invited')
    @course = enrollment && enrollment.course
    @headers = false
    if cc
      @communication_channel = cc
      @pseudonym = pseudonym
      @user = @pseudonym.user
      if params[:register] && params[:user]
        user = pseudonym.user
        user.name = params[:user][:name] || user.name
        user.name = pseudonym.unique_id if !user.name || user.name.empty?
        user.time_zone = params[:user][:time_zone]
        user.short_name = params[:user][:short_name] || user.short_name
        user.subscribe_to_emails = params[:user][:subscribe_to_emails] || user.subscribe_to_emails
        user.save
      end
      if params[:register] && pseudonym.password_auto_generated && params[:pseudonym][:password]
        pseudonym.password = params[:pseudonym][:password]
        pseudonym.password_confirmation = params[:pseudonym][:password_confirmation]
        if params[:pseudonym][:password].empty? 
          flash[:error] = "You must type a password of at lest 6 characters."
        else 
          pseudonym.save
        end
      end
      if pseudonym.password_auto_generated
        respond_to do |format|
          format.html
        end
      elsif cc.active? || cc.confirm
        reset_session_saving_keys(:return_to)
        flash[:notice] = "Registration confirmed."
        pseudonym.user.register
        # Login, since we're satisfied that this person is the right person.
        @pseudonym_session = PseudonymSession.new(pseudonym, true)
        @pseudonym_session.save

        respond_to do |format|
          session[:return_to] = nil if session[:return_to] == claim_pseudonym_url(params[:id], params[:nonce])
          format.html { redirect_to_enrollment_or_profile true }
          format.json { render :json => cc.to_json(:except => [:confirmation_code] ) }
        end
      else
        @failed = "cant_confirm"
      end
    else
      @failed = "invalid_cc"
    end
    if @failed
      respond_to do |format|
        format.html { render :action => "registration_confirmation_failed" }
        format.json { render :json => {}.to_json, :status => :bad_request }
      end
    end
  end
  
  def show
    @user = @current_user
    @pseudonym = @current_pseudonym
  end

  def new
    @pseudonym = @current_user.pseudonyms.build(:account_id => @domain_root_account.id)
  end
  
  def create
    return unless get_user
    if !params[:pseudonym][:password]
      @existing_pseudonym = @user.pseudonyms.active.select{|p| p.account == Account.default }.first
    end
    account_id = params[:pseudonym].delete :account_id
    if current_user_is_site_admin?(:manage_user_logins)
      params[:pseudonym][:account] = Account.root_accounts.find(account_id)
    end
    params[:pseudonym][:account] ||= @domain_root_account
    @pseudonym = @user.pseudonyms.build(params[:pseudonym])
    unless @pseudonym.account && @pseudonym.account.settings[:admins_can_change_passwords]
      params[:pseudonym].delete :password
      params[:pseudonym].delete :password_confirmation
    end
    @pseudonym.generate_temporary_password if !params[:pseudonym][:password]
    if @pseudonym.save
      if @existing_pseudonym
        @pseudonym.password_salt = @existing_pseudonym.password_salt
        @pseudonym.crypted_password = @existing_pseudonym.crypted_password
        @pseudonym.password_auto_generated = @existing_pseudonym.password_auto_generated
        @pseudonym.save
      end
      respond_to do |format|
        flash[:notice] = "Account registered!"
        format.html { redirect_to profile_url }
        format.json { render :json => @pseudonym.to_json(:only => [:id, :unique_id, :account_id], :include => {:communication_channel => {:only => [:id, :path, :path_type]}}) }
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
        format.json { render :json => @pseudonym.errors.to_json }
      end
    end
  end

  def edit
    @user = @current_user
    @pseudonym = @current_pseudonym
  end
  
  def get_user
    if params[:user_id]
      @user = User.find(params[:user_id])
      if @user != @current_user && !authorized_action(@user, @current_user, :manage_logins)
        return false
      end
    else
      @user = @current_user
    end
    true
  end
  protected :get_user
  
  def update
    return unless get_user
    @pseudonym = @user.pseudonyms.find(params[:id])
    params[:pseudonym].delete :account_id
    params[:pseudonym].delete :unique_id unless @user.grants_rights?(@current_user, nil, :manage_logins)
    unless @pseudonym.account && @pseudonym.account.settings[:admins_can_change_passwords]
      params[:pseudonym].delete :password
      params[:pseudonym].delete :password_confirmation
    end
    if @pseudonym.update_attributes(params[:pseudonym])
      flash[:notice] = "Account updated!"
      respond_to do |format|
        format.html { redirect_to profile_url }
        format.json { render :json => @pseudonym.to_json }
      end
    else
      respond_to do |format|
        format.html { render :action => :edit }
        format.json { render :json => @pseudonym.errors.to_json }
      end
    end
  end
  
  def destroy
    return unless get_user
    @pseudonym = @user.pseudonyms.find(params[:id])
    if @user.pseudonyms.active.length < 2
      @pseudonym.errors.add_to_base('Users must have at least one login')
      render :json => @pseudonym.errors.to_json, :status => :bad_request
    elsif @pseudonym.destroy(@user.grants_right?(@current_user, session, :manage_logins))
      render :json => @pseudonym.to_json
    else
      render :json => @pseudonym.errors.to_json, :status => :bad_request
    end
  end
  
end
