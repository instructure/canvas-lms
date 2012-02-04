#
# Copyright (C) 2011-2012 Instructure, Inc.
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

# @API Logins
# API for creating and viewing user logins under an account
class PseudonymsController < ApplicationController
  before_filter :get_context, :only => [:index, :create]
  before_filter :require_user, :only => [:create, :show, :edit, :update]
  protect_from_forgery :except => [:registration_confirmation, :change_password, :forgot_password]

  include Api::V1::Pseudonym

  # @API
  # Given a user ID, return that user's logins for the given account.
  #
  # @argument user[id] The ID of the user to search on.
  def index
    return unless get_user && authorized_action(@user, @current_user, :read)
    return unless context_is_root_account?
    @pseudonyms = Api.paginate(
      @user.pseudonyms.scoped(:conditions => { :account_id => @context.id }),
      self, api_v1_pseudonyms_path)
    render :json => @pseudonyms.map { |p| pseudonym_json(p, @current_user, session) }
  end

  def forgot_password
    email = params[:pseudonym_session][:unique_id_forgot] if params[:pseudonym_session]
    @ccs = []
    @ccs = CommunicationChannel.find_all_by_path_and_path_type_and_workflow_state(email, 'email', 'active')
    if @ccs.empty?
      @ccs += CommunicationChannel.find_all_by_path_and_path_type(email, 'email') if email and !email.empty?
    end
    if @domain_root_account && email && !email.empty?
      @domain_root_account.pseudonyms.active.custom_find_by_unique_id(email, :all).each do |p|
        cc = p.communication_channel if p.communication_channel && p.user
        cc ||= p.user.communication_channel rescue nil
        @ccs << cc
      end
    end
    @ccs = @ccs.flatten.compact.uniq.select do |cc|
      if !cc.user
        false
      else
        cc.pseudonym ||= cc.user.pseudonym rescue nil
        cc.save if cc.changed?
        !cc.user.pseudonyms.active.empty? && cc.user.pseudonyms.active.any?{|p| p.account_id == @domain_root_account.id || (p.works_for_account?(@domain_root_account) && p.account && p.account.password_authentication?) }
      end
    end
    respond_to do |format|
      # Whether the email was actually found or not, we display the same
      # message. Otherwise this form could be used to fish for valid
      # email addresses.
      flash[:notice] = t 'notices.email_sent', "Confirmation email sent to %{email}, make sure to check your spam box", :email => email
      @ccs.each do |cc|
        cc.forgot_password!
      end
      format.html { redirect_to(login_url) }
      format.json { render :json => {:requested => true}.to_json }
      format.js { render :json => {:requested => true}.to_json }
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
      flash[:error] = t 'errors.cant_change_password', "Cannot change the password for that login, or login does not exist"
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
      flash[:notice] = t 'notices.password_changed', "Password changed"
      redirect_to dashboard_url
    elsif @cc
      render :action => "confirm_change_password"
    else
      flash[:notice] = t 'notices.link_invalid', "The link you used appears to no longer be valid.  If you can't login, try clicking \"Don't Know My Password\" and having a new message sent for you."
      redirect_to login_url
    end
  end

  def show
    @user = @current_user
    @pseudonym = @current_pseudonym
  end

  def new
    @pseudonym = @current_user.pseudonyms.build(:account_id => @domain_root_account.id)
  end

  # @API
  # Create a new login for an existing user in the given account.
  #
  # @argument user[id] The ID of the user to create the login for.
  # @argument login[unique_id] The unique ID for the new login.
  # @argument login[password] The new login's password.
  # @arugment login[sis_user_id] SIS ID for the login. To set this parameter, the caller must be able to manage SIS permissions on the account.
  def create
    return unless get_user
    return unless @user == @current_user || authorized_action(@user, @current_user, :manage_logins)

    if api_request?
      return unless context_is_root_account?
      params[:pseudonym] = params[:login].merge(
        :password_confirmation => params[:login][:password],
        :account => @context
      )
    else
      account_id = params[:pseudonym].delete(:account_id)
      if current_user_is_site_admin?(:manage_user_logins)
        params[:pseudonym][:account] = Account.root_accounts.find(account_id)
      else
        params[:pseudonym][:account] = @domain_root_account
      end
    end

    if !params[:pseudonym][:password]
      @existing_pseudonym = @user.pseudonyms.active.select{|p| p.account == Account.default }.first
    end

    sis_user_id = params[:pseudonym].delete(:sis_user_id)
    @pseudonym = @user.pseudonyms.build(params[:pseudonym])
    @pseudonym.sis_user_id = sis_user_id if sis_user_id.present? && @pseudonym.account.grants_right?(@current_user, session, :manage_sis)
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
        flash[:notice] = t 'notices.account_registered', "Account registered!"
        format.html { redirect_to profile_url }
        format.json { render :json => pseudonym_json(@pseudonym, @current_user, session) }
      end
    else
      respond_to do |format|
        format.html { render :action => :new }
        format.json { render :json => @pseudonym.errors.to_json, :status => :bad_request }
      end
    end
  end

  def edit
    @user = @current_user
    @pseudonym = @current_pseudonym
  end
  
  def get_user
    if params[:user_id] || api_request?
      @user = api_request? ? api_find(User, params[:user] && params[:user][:id]) : User.find(params[:user_id])
    else
      @user = @current_user
    end
    true
  end
  protected :get_user
  
  def update
    return unless get_user
    return unless @user == @current_user || authorized_action(@user, @current_user, :manage_logins)
    @pseudonym = @user.pseudonyms.find(params[:id])
    params[:pseudonym].delete :account_id
    unless @pseudonym.account.grants_right?(@current_user, session, :manage_user_logins)
      params[:pseudonym].delete :unique_id
      params[:pseudonym].delete :password
      params[:pseudonym].delete :password_confirmation
    end
    unless @pseudonym.account && @pseudonym.account.settings[:admins_can_change_passwords]
      params[:pseudonym].delete :password
      params[:pseudonym].delete :password_confirmation
    end
    if sis_id = params[:pseudonym].delete(:sis_user_id)
      if sis_id != @pseudonym.sis_user_id && @pseudonym.account.grants_right?(@current_user, session, :manage_sis)
        if sis_id == ''
          @pseudonym.sis_user_id = nil
        else
          @pseudonym.sis_user_id = sis_id
        end
      end
    end
    
    if @pseudonym.update_attributes(params[:pseudonym])
      flash[:notice] = t 'notices.account_updated', "Account updated!"
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
    return unless @user == @current_user || authorized_action(@user, @current_user, :manage_logins)
    @pseudonym = @user.pseudonyms.find(params[:id])
    if @user.pseudonyms.active.length < 2
      @pseudonym.errors.add_to_base(t('errors.login_required', "Users must have at least one login"))
      render :json => @pseudonym.errors.to_json, :status => :bad_request
    elsif @pseudonym.sis_user_id && !@pseudonym.account.grants_right?(@current_user, session, :manage_sis)
      return render_unauthorized_action(@pseudonym)
    elsif @pseudonym.destroy(@user.grants_right?(@current_user, session, :manage_logins))
      render :json => @pseudonym.to_json
    else
      render :json => @pseudonym.errors.to_json, :status => :bad_request
    end
  end

  protected
  def context_is_root_account?
    if @context.root_account?
      true
    else
      render(:json => { 'message' => 'Action must be called on a root account.' }.to_json, :status => :bad_request)
      false
    end
  end
end
