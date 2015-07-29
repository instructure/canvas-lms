
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
  # @response_field account_id The ID of the login's account.
  # @response_field id The unique, numeric ID for the login.
  # @response_field sis_user_id The login's unique SIS id.
  # @response_field unique_id The unique ID for the login.
  # @response_field user_id The unique ID of the login's user.
  # @response_field authentication_provider_id The ID of the authentication
  #                 provider that this login is associated with
  # @response_field authentication_provider_type The type of the authentication
  #                 provider that this login is associated with
  #
  # @example_response
  #   [
  #     {
  #       "account_id": 1,
  #       "id" 2,
  #       "sis_user_id": null,
  #       "unique_id": "belieber@example.com",
  #       "user_id": 2,
  #       "authentication_provider_id": 1,
  #       "authentication_provider_type": "facebook"
  #     }
  #   ]
  def index
    return unless get_user && authorized_action(@user, @current_user, :read)

    if @context.is_a?(Account)
      return unless context_is_root_account?
      scope = @context.pseudonyms.active.where(:user_id => @user)
      @pseudonyms = Api.paginate(
        scope,
        self, api_v1_account_pseudonyms_url)
    else
      bookmark = BookmarkedCollection::SimpleBookmarker.new(Pseudonym, :id)
      @pseudonyms = ShardedBookmarkedCollection.build(bookmark, @user.pseudonyms) { |scope| scope.active }
      @pseudonyms = Api.paginate(@pseudonyms, self, api_v1_user_pseudonyms_url)
    end

    render :json => @pseudonyms.map { |p| pseudonym_json(p, @current_user, session) }
  end

  def forgot_password
    email = params[:pseudonym_session][:unique_id_forgot] if params[:pseudonym_session]
    @ccs = []
    if email.present?
      @ccs = CommunicationChannel.email.by_path(email).active.to_a
      if @ccs.empty?
        @ccs += CommunicationChannel.email.by_path(email).to_a
      end
      if @domain_root_account
        @domain_root_account.pseudonyms.active.by_unique_id(email).each do |p|
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
        !cc.user.pseudonyms.active.empty? && cc.user.pseudonyms.active.any?{|p| p.account_id == @domain_root_account.id || (p.works_for_account?(@domain_root_account) && p.account && p.account.canvas_authentication?) }
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
      format.json { render :json => {:requested => true} }
      format.js { render :json => {:requested => true} }
    end
  end

  def confirm_change_password
    @pseudonym = Pseudonym.find(params[:pseudonym_id])
    @cc = @pseudonym.user.communication_channels.where(confirmation_code: params[:nonce]).first
    @cc = nil if @pseudonym.managed_password?
    @headers = false
    # Allow unregistered users to change password.  How else can they come back later
    # and finish the registration process?
    if !@cc || @cc.path_type != 'email'
      flash[:error] = t 'errors.cant_change_password', "Cannot change the password for that login, or login does not exist"
      redirect_to root_url
    else
      @password_pseudonyms = @cc.user.pseudonyms.active.select{|p| p.account.canvas_authentication? }
      js_env :PASSWORD_POLICY => @domain_root_account.password_policy,
             :PASSWORD_POLICIES => Hash[@password_pseudonyms.map{ |p| [p.id, p.account.password_policy]}]
    end
  end

  def change_password
    @pseudonym = Pseudonym.find(params[:pseudonym][:id] || params[:pseudonym_id])
    if @cc = @pseudonym.user.communication_channels.where(confirmation_code: params[:nonce]).first
      @pseudonym.require_password = true
      @pseudonym.password = params[:pseudonym][:password]
      @pseudonym.password_confirmation = params[:pseudonym][:password_confirmation]
      if @pseudonym.save_without_session_maintenance
        # If they changed the password (and we subsequently log them in) then
        # we're pretty confident this is the right user, and the communication
        # channel is valid, so register the user and approve the channel.
        @cc.set_confirmation_code(true)
        @cc.confirm
        @cc.save
        @pseudonym.user.register

        # reset the session id cookie to prevent session fixation.
        reset_session

        @pseudonym_session = PseudonymSession.new(@pseudonym, true)
        flash[:notice] = t 'notices.password_changed', "Password changed"
        render :json => @pseudonym, :status => :ok # -> dashboard
      else
        render :json => {:pseudonym => @pseudonym.errors.as_json[:errors]}, :status => :bad_request
      end
    else
      flash[:notice] = t 'notices.link_invalid', "The link you used is no longer valid.  If you can't log in, click \"Don't know your password?\" to reset your password."
      render :json => {:errors => {:nonce => 'expired'}}, :status => :bad_request # -> login url
    end
  end

  def show
    @user = @current_user
    @pseudonym = @current_pseudonym
  end

  def new
    @pseudonym = @domain_root_account.pseudonyms.build(:user => @current_user)
  end

  # @API Create a user login
  # Create a new login for an existing user in the given account.
  #
  # @argument user[id] [Required, String]
  #   The ID of the user to create the login for.
  #
  # @argument login[unique_id] [Required, String]
  #   The unique ID for the new login.
  #
  # @argument login[password] [String]
  #   The new login's password.
  #
  # @argument login[sis_user_id] [String]
  #   SIS ID for the login. To set this parameter, the caller must be able to
  #   manage SIS permissions on the account.
  #
  # @argument login[authentication_provider_id] [String]
  #   The authentication provider this login is associated with. Logins
  #   associated with a specific provider can only be used with that provider.
  #   Legacy providers (LDAP, CAS, SAML) will search for logins associated with
  #   them, or unassociated logins. New providers will only search for logins
  #   explicitly associated with them. This can be the integer ID of the
  #   provider, or the type of the provider (in which case, it will find the
  #   first matching provider).
  #
  # @example_request
  #
  #   #create a facebook login for user with ID 123
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/logins' \
  #        -F 'user[id]=123' \
  #        -F 'login[unique_id]=112233445566' \
  #        -F 'login[authentication_provider_id]=facebook' \
  #        -H 'Authorization: Bearer <token>'
  def create
    return unless get_user

    if api_request?
      return unless context_is_root_account?
      @account = @context
      params[:login] ||= {}
      params[:login][:password_confirmation] = params[:login][:password]
      params[:pseudonym] = params[:login]
    else
      account_id = params[:pseudonym].delete(:account_id)
      @account = Account.root_accounts.find(account_id) if account_id
      @account ||= @domain_root_account
    end

    @pseudonym = @account.pseudonyms.build(user: @user)
    return unless authorized_action(@pseudonym, @current_user, :create)
    return unless find_authentication_provider
    return unless update_pseudonym_from_params

    @pseudonym.generate_temporary_password if !params[:pseudonym][:password]
    if @pseudonym.save_without_session_maintenance
      respond_to do |format|
        flash[:notice] = t 'notices.account_registered', "Account registered!"
        format.html { redirect_to user_profile_url(@current_user) }
        format.json { render :json => pseudonym_json(@pseudonym, @current_user, session) }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render :json => @pseudonym.errors, :status => :bad_request }
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
            when user_id
              api_find(User, user_id)
            else
              @current_user
            end
    true
  end
  protected :get_user

  # @API Edit a user login
  # Update an existing login for a user in the given account.
  #
  # @argument login[unique_id] [String]
  #   The new unique ID for the login.
  #
  # @argument login[password] [String]
  #   The new password for the login. Can only be set by an admin user if admins
  #   are allowed to change passwords for the account.
  #
  # @argument login[sis_user_id] [String]
  #   SIS ID for the login. To set this parameter, the caller must be able to
  #   manage SIS permissions on the account.
  def update
    if api_request?
      @pseudonym          = Pseudonym.active.find(params[:id])
      return unless @user = @pseudonym.user
      params[:login][:password_confirmation] = params[:login][:password] if params[:login][:password]
      params[:pseudonym]  = params[:login]
    else
      return unless get_user
      @pseudonym = Pseudonym.active.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @pseudonym.user_id == @user.id
    end

    return unless authorized_action(@pseudonym, @current_user, [:update, :change_password])
    return unless update_pseudonym_from_params

    if @pseudonym.save_without_session_maintenance
      flash[:notice] = t 'notices.account_updated', "Account updated!"
      respond_to do |format|
        format.html { redirect_to user_profile_url(@current_user) }
        format.json { render :json => pseudonym_json(@pseudonym, @current_user, session) }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render :json => @pseudonym.errors, :status => :bad_request }
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
    @pseudonym = Pseudonym.active.find(params[:id])
    raise ActiveRecord::RecordNotFound unless @pseudonym.user_id == @user.id
    return unless authorized_action(@pseudonym, @current_user, :delete)

    if @user.all_active_pseudonyms.length < 2
      @pseudonym.errors.add(:base, t('errors.login_required', "Users must have at least one login"))
      render :json => @pseudonym.errors, :status => :bad_request
    elsif @pseudonym.destroy
      api_request? ?
        render(:json => pseudonym_json(@pseudonym, @current_user, session)) :
        render(:json => @pseudonym)
    else
      render :json => @pseudonym.errors, :status => :bad_request
    end
  end

  protected
  def context_is_root_account?
    if @context.root_account?
      true
    else
      render(:json => { 'message' => 'Action must be called on a root account.' }, :status => :bad_request)
      false
    end
  end

  def find_authentication_provider
    return true unless params[:pseudonym][:authentication_provider_id]
    params[:pseudonym][:authentication_provider] = @domain_root_account.
      authentication_providers.active.
      find(params[:pseudonym][:authentication_provider_id])
  end

  def update_pseudonym_from_params
    # you have to at least attempt something recognized...
    if params[:pseudonym].slice(:unique_id, :password, :sis_user_id, :authentication_provider).blank?
      render json: nil, status: :bad_request
      return false
    end

    # perform updates (if they have permission
    # to make them). silently ignore unrecognized fields.
    # note: make sure sis_user_id is updated (if happening)
    # before password, since it may affect the :change_password permissions

    has_right_if_requests_change(:unique_id, :update) do
      @pseudonym.unique_id = params[:pseudonym][:unique_id]
    end or return false

    has_right_if_requests_change(:authentication_provider, :update) do
      @pseudonym.authentication_provider = params[:pseudonym][:authentication_provider]
    end or return false

    has_right_if_requests_change(:sis_user_id, :manage_sis) do
      # convert "" -> nil for sis_user_id
      @pseudonym.sis_user_id = params[:pseudonym][:sis_user_id].presence
    end or return false

    has_right_if_requests_change(:password, :change_password) do
      @pseudonym.password = params[:pseudonym][:password]
      @pseudonym.password_confirmation = params[:pseudonym][:password_confirmation]
    end or return false
  end

  private
  def has_right_if_requests_change(key, right)
    return true unless params[:pseudonym].key?(key.to_sym)

    if @pseudonym.grants_right?(@current_user, right.to_sym)
      yield
      true
    else
      render_unauthorized_action
      false
    end
  end
end
