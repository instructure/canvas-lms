
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
  before_filter :reject_student_view_student, :only => [:create, :show, :edit, :update]
  protect_from_forgery :except => [:registration_confirmation, :change_password, :forgot_password]

  include Api::V1::Pseudonym

  # @API List user logins
  # Given a user ID, return that user's logins for the given account.
  #
  # @argument user[id] The ID of the user to search on.
  #
  # @response_field account_id The ID of the login's account.
  # @response_field id The unique, numeric ID for the login.
  # @response_field sis_user_id The login's unique SIS id.
  # @response_field unique_id The unique ID for the login.
  # @response_field user_id The unique ID of the login's user.
  #
  # @example_response
  #   [
  #      { "account_id": 1, "id" 2, "sis_user_id": null, "unique_id": "belieber@example.com", "user_id": 2 }
  #   ]
  def index
    return unless get_user && authorized_action(@user, @current_user, :read)

    if @context.is_a?(Account)
      return unless context_is_root_account?
      @pseudonyms = Api.paginate(
        @user.pseudonyms.scoped(:conditions => { :account_id => @context.id }),
        self, api_v1_account_pseudonyms_path)
    else
      @pseudonyms = Api.paginate(@user.pseudonyms, self, api_v1_user_pseudonyms_path)
    end

    render :json => @pseudonyms.map { |p| pseudonym_json(p, @current_user, session) }
  end

  def forgot_password
    email = params[:pseudonym_session][:unique_id_forgot] if params[:pseudonym_session]
    @ccs = []
    if email.present?
      @ccs = CommunicationChannel.email.by_path(email).active.all
      if @ccs.empty?
        @ccs += CommunicationChannel.email.by_path(email).all
      end
      if @domain_root_account
        @domain_root_account.pseudonyms.active.custom_find_by_unique_id(email, :all).each do |p|
          cc = p.communication_channel if p.communication_channel && p.user
          cc ||= p.user.communication_channel rescue nil
          @ccs << cc
        end
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

  # @API Create a user login
  # Create a new login for an existing user in the given account.
  #
  # @argument user[id] The ID of the user to create the login for.
  # @argument login[unique_id] The unique ID for the new login.
  # @argument login[password] The new login's password.
  # @argument login[sis_user_id] SIS ID for the login. To set this parameter, the caller must be able to manage SIS permissions on the account.
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
      if Account.site_admin.grants_right?(@current_user, :manage_user_logins)
        params[:pseudonym][:account] = Account.root_accounts.find(account_id)
      else
        params[:pseudonym][:account] = @domain_root_account
        unless @domain_root_account.settings[:admins_can_change_passwords]
          params[:pseudonym].delete :password
          params[:pseudonym].delete :password_confirmation
        end
      end
    end

    sis_user_id = params[:pseudonym].delete(:sis_user_id)
    @pseudonym = @user.pseudonyms.build(params[:pseudonym])
    @pseudonym.sis_user_id = sis_user_id if sis_user_id.present? && @pseudonym.account.grants_right?(@current_user, session, :manage_sis)
    @pseudonym.generate_temporary_password if !params[:pseudonym][:password]
    if @pseudonym.save
      respond_to do |format|
        flash[:notice] = t 'notices.account_registered', "Account registered!"
        format.html { redirect_to user_profile_url(@current_user) }
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
    user_id = params[:user_id] || params[:user].try(:[], :id)
    @user = case
            when api_request? && user_id
              api_find(User, user_id)
            when user_id
              User.find(user_id)
            else
              @current_user
            end
    true
  end
  protected :get_user

  # @API Edit a user login
  # Update an existing login for a user in the given account.
  #
  # @argument login[unique_id] The new unique ID for the login.
  # @argument login[password] The new password for the login. Can only be set by an admin user if admins are allowed to change passwords for the account.
  # @argument login[sis_user_id] SIS ID for the login. To set this parameter, the caller must be able to manage SIS permissions on the account.
  def update
    if api_request?
      @pseudonym          = Pseudonym.find(params[:id])
      return unless @user = @pseudonym.user
      params[:pseudonym]  = params[:login]
    else
      return unless get_user
      @pseudonym = @user.pseudonyms.find(params[:id])
    end
    return unless @user == @current_user || authorized_action(@user, @current_user, :manage_logins)
    return render(:json => nil, :status => :bad_request) if params[:pseudonym].blank?
    params[:pseudonym].delete :account_id
    params[:pseudonym].delete :unique_id unless @user.grants_right?(@current_user, nil, :manage_logins)
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
      changed_sis_id = sis_id != @pseudonym.sis_user_id
      if changed_sis_id && @pseudonym.account.grants_right?(@current_user, session, :manage_sis)
        @pseudonym.sis_user_id = sis_id.blank? ? nil : sis_id
      end
    end
    # silently delete unallowed attributes
    params[:pseudonym].delete_if { |k, v| ![:unique_id, :password, :password_confirmation, :sis_user_id].include?(k.to_sym) }
    # return 401 if psuedonyms is empty here, because it means that the user doesn't have permissions to do anything.
    return render(:json => nil, :status => :unauthorized) if params[:pseudonym].blank? && changed_sis_id
    if @pseudonym.update_attributes(params[:pseudonym])
      flash[:notice] = t 'notices.account_updated', "Account updated!"
      respond_to do |format|
        format.html { redirect_to user_profile_url(@current_user) }
        format.json { render :json => pseudonym_json(@pseudonym, @current_user, session) }
      end
    else
      respond_to do |format|
        format.html { render :action => :edit }
        format.json { render :json => @pseudonym.errors.to_json, :status => :bad_request }
      end
    end
  end

  # @API Delete a user login
  # Delete an existing login.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/users/:user_id/logins/:login_id \ 
  #     -H "Authorization: Bearer <ACCESS-TOKEN>" \ 
  #     -X DELETE
  #
  # @example_response
  #   {
  #     "unique_id": "bieber@example.com",
  #     "sis_user_id": null,
  #     "account_id": 1,
  #     "id": 12345,
  #     "user_id": 2
  #   }
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
      api_request? ?
        render(:json => pseudonym_json(@pseudonym, @current_user, session)) :
        render(:json => @pseudonym.to_json)
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
