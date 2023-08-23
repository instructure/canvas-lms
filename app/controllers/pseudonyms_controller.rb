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

# @API Logins
# API for creating and viewing user logins under an account
class PseudonymsController < ApplicationController
  before_action :get_context, only: [:index, :create]
  before_action :require_user, only: %i[create show edit update]
  before_action :reject_student_view_student, only: %i[create show edit update]
  protect_from_forgery except: %i[registration_confirmation change_password forgot_password], with: :exception

  include Api::V1::Pseudonym

  # @API List user logins
  # Given a user ID, return a paginated list of that user's logins for the given account.
  #
  # @response_field account_id The ID of the login's account.
  # @response_field id The unique, numeric ID for the login.
  # @response_field sis_user_id The login's unique SIS ID.
  # @response_field integration_id The login's unique integration ID.
  # @response_field unique_id The unique ID for the login.
  # @response_field user_id The unique ID of the login's user.
  # @response_field authentication_provider_id The ID of the authentication
  #                 provider that this login is associated with
  # @response_field authentication_provider_type The type of the authentication
  #                 provider that this login is associated with
  # @response_field workflow_state The current status of the login
  # @response_field declared_user_type The declared intention for this user's role
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
  #       "authentication_provider_type": "facebook",
  #       "workflow_state": "active",
  #       "declared_user_type": null,
  #     }
  #   ]
  def index
    return unless get_user && authorized_action(@user, @current_user, :read)

    if @context.is_a?(Account)
      return unless context_is_root_account?

      scope = @context.pseudonyms.active.where(user_id: @user)
      @pseudonyms = Api.paginate(
        scope,
        self,
        api_v1_account_pseudonyms_url
      )
    else
      bookmark = BookmarkedCollection::SimpleBookmarker.new(Pseudonym, :id)
      @pseudonyms = ShardedBookmarkedCollection.build(bookmark, @user.pseudonyms.shard(@user).active.order(:id))
      @pseudonyms = Api.paginate(@pseudonyms, self, api_v1_user_pseudonyms_url)
    end

    render json: @pseudonyms.map { |p| pseudonym_json(p, @current_user, session) }
  end

  # @API Kickoff password recovery flow
  # Given a user email, generate a nonce and email it to the user
  #
  # @response_field requested The recovery request status
  #
  # @example_response
  #   {
  #     "requested": true
  #   }
  def forgot_password
    if api_request?
      return unless authorized_action(@current_user.pseudonym.account, @current_user, [:manage_user_logins])
    end

    email = if api_request?
              params[:email]
            elsif params[:pseudonym_session]
              params[:pseudonym_session][:unique_id_forgot]
            end
    @ccs = []
    if email.present?
      shards = Set.new
      shards << Shard.current
      associated_shards = CommunicationChannel.associated_shards(email)
      @domain_root_account.trusted_account_ids.each do |account_id|
        shard = Shard.shard_for(account_id)
        shards << shard if associated_shards.include?(shard)
      end
      @ccs = CommunicationChannel.email.by_path(email).shard(shards.to_a).active.to_a
      if @domain_root_account
        @domain_root_account.pseudonyms.active_only.by_unique_id(email).each do |p|
          cc = p.communication_channel if p.communication_channel && p.user
          cc ||= p.user.communication_channel rescue nil
          @ccs << cc
        end
      end
    end

    @ccs = @ccs.flatten.compact.uniq.select do |cc|
      if cc.user
        cc.pseudonym ||= cc.user.pseudonym rescue nil
        cc.save if cc.changed?
        found = false
        Shard.partition_by_shard([@domain_root_account.id] + @domain_root_account.trusted_account_ids) do |account_ids|
          next unless cc.user.associated_shards.include?(Shard.current)

          if Pseudonym.active.where(user_id: cc.user_id, account_id: account_ids).exists?
            found = true
            break
          end
        end
        found
      else
        false
      end
    end

    if api_request?
      @ccs.each do |cc|
        return unless authorized_action(cc.pseudonym.account, @current_user, [:manage_user_logins])
      end

      if @ccs.empty?
        render json: { requested: false }, status: :not_found
        return
      end
    end

    respond_to do |format|
      # Whether the email was actually found or not, we display the same
      # message. Otherwise this form could be used to fish for valid
      # email addresses.
      flash[:notice] = t("notices.email_sent", "Confirmation email sent to %{email}, make sure to check your spam box", email:)
      @ccs.each(&:forgot_password!)
      format.html { redirect_to(canvas_login_url) }
      format.json { render json: { requested: true } }
      format.js { render json: { requested: true } }
    end
  end

  def confirm_change_password
    @pseudonym = Pseudonym.find(params[:pseudonym_id])
    @cc = @pseudonym.user.communication_channels.where(confirmation_code: params[:nonce]).first
    @cc = nil if @pseudonym.managed_password?
    @headers = false
    # Allow unregistered users to change password.  How else can they come back later
    # and finish the registration process?
    if !@cc || @cc.path_type != "email"
      flash[:error] = t "errors.cant_change_password", "Cannot change the password for that login, or login does not exist"
      redirect_to canvas_login_url
    else
      if @cc.confirmation_code_expires_at.present? && @cc.confirmation_code_expires_at <= Time.now.utc
        flash[:error] = t 'The link you used has expired. Click "Forgot Password?" to get a new reset-password link.'
        redirect_to canvas_login_url
      end
      @password_pseudonyms = @cc.user.pseudonyms.active_only.select { |p| p.account.canvas_authentication? }
      js_env PASSWORD_POLICY: @domain_root_account.password_policy,
             PASSWORD_POLICIES: @password_pseudonyms.to_h { |p| [p.id, p.account.password_policy] }
    end
  end

  def change_password
    @pseudonym = Pseudonym.find(params[:pseudonym][:id] || params[:pseudonym_id])
    if (@cc = @pseudonym.user.communication_channels.where(confirmation_code: params[:nonce])
                       .where("confirmation_code_expires_at IS NULL OR confirmation_code_expires_at > ?", Time.now.utc).first)
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
        render json: @pseudonym, status: :ok # -> dashboard
      else
        render json: { pseudonym: @pseudonym.errors.as_json[:errors] }, status: :bad_request
      end
    else
      render json: { errors: { nonce: "expired" } }, status: :bad_request # -> login url
    end
  end

  def show
    @user = @current_user
    @pseudonym = @current_pseudonym
  end

  def new
    @pseudonym = @domain_root_account.pseudonyms.build(user: @current_user)
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
  # @argument login[integration_id] [String]
  #   Integration ID for the login. To set this parameter, the caller must be able to
  #   manage SIS permissions on the account. The Integration ID is a secondary
  #   identifier useful for more complex SIS integrations.
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
  # @argument login[declared_user_type] [String]
  #   The declared intention of the user type. This can be set, but does
  #   not change any Canvas functionality with respect to their access.
  #   A user can still be a teacher, admin, student, etc. in any particular
  #   context without regard to this setting. This can be used for
  #   administrative purposes for integrations to be able to more easily
  #   identify why the user was created.
  #   Valid values are:
  #     * administrative
  #     * observer
  #     * staff
  #     * student
  #     * student_other
  #     * teacher
  #
  # @argument user[existing_user_id] [String]
  #   A Canvas User ID to identify a user in a trusted account (alternative to `id`,
  #   `existing_sis_user_id`, or `existing_integration_id`). This parameter is
  #   not available in OSS Canvas.
  #
  # @argument user[existing_integration_id] [String]
  #   An Integration ID to identify a user in a trusted account (alternative to `id`,
  #   `existing_user_id`, or `existing_sis_user_id`). This parameter is not
  #   available in OSS Canvas.
  #
  # @argument user[existing_sis_user_id] [String]
  #   An SIS User ID to identify a user in a trusted account (alternative to `id`,
  #   `existing_integration_id`, or `existing_user_id`). This parameter is not
  #   available in OSS Canvas.
  #
  # @argument user[trusted_account] [String]
  #   The domain of the account to search for the user. This field is required when
  #   identifying a user in a trusted account. This parameter is not available in OSS
  #   Canvas.
  #
  # @example_request
  #
  #   #create a facebook login for user with ID 123
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/logins' \
  #        -F 'user[id]=123' \
  #        -F 'login[unique_id]=112233445566' \
  #        -F 'login[authentication_provider_id]=facebook' \
  #        -H 'Authorization: Bearer <token>'
  #
  # @example_request
  #
  #   #create a login for user in another trusted account:
  #   curl 'https://<canvas>/api/v1/accounts/<account_id>/logins' \
  #        -F 'user[existing_user_sis_id]=SIS42' \
  #        -F 'user[trusted_account]=canvas.example.edu' \
  #        -F 'login[unique_id]=112233445566' \
  #        -H 'Authorization: Bearer <token>'
  #
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

    @pseudonym.generate_temporary_password unless params[:pseudonym][:password]
    if Pseudonym.unique_constraint_retry { @pseudonym.save_without_session_maintenance }
      respond_to do |format|
        flash[:notice] = t "notices.account_registered", "Account registered!"
        format.html { redirect_to user_profile_url(@current_user) }
        format.json { render json: pseudonym_json(@pseudonym, @current_user, session) }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: @pseudonym.errors, status: :bad_request }
      end
    end
  end

  def edit
    @user = @current_user
    @pseudonym = @current_pseudonym
  end

  def get_user
    user_id = params[:user_id] || params[:user].try(:[], :id)
    @user = user_id ? api_find(User, user_id) : @current_user
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
  #
  # @argument login[integration_id] [String]
  #   Integration ID for the login. To set this parameter, the caller must be able to
  #   manage SIS permissions on the account. The Integration ID is a secondary
  #   identifier useful for more complex SIS integrations.
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
  # @argument login[workflow_state] [String, "active"|"suspended"]
  #   Used to suspend or re-activate a login.
  #
  # @argument login[declared_user_type] [String]
  #   The declared intention of the user type. This can be set, but does
  #   not change any Canvas functionality with respect to their access.
  #   A user can still be a teacher, admin, student, etc. in any particular
  #   context without regard to this setting. This can be used for
  #   administrative purposes for integrations to be able to more easily
  #   identify why the user was created.
  #   Valid values are:
  #     * administrative
  #     * observer
  #     * staff
  #     * student
  #     * student_other
  #     * teacher
  #
  # @argument override_sis_stickiness [boolean]
  #   Default is true. If false, any fields containing “sticky” changes will not be updated.
  #   See SIS CSV Format documentation for information on which fields can have SIS stickiness
  #
  # @example_request
  #   curl https://<canvas>/api/v1/accounts/:account_id/logins/:login_id \
  #     -H "Authorization: Bearer <ACCESS-TOKEN>" \
  #     -X PUT
  #
  # @example_response
  #   {
  #     "id": 1,
  #     "user_id": 2,
  #     "account_id": 3,
  #     "unique_id": "bieber@example.com",
  #     "created_at": "2020-01-29T19:33:35Z",
  #     "sis_user_id": null,
  #     "integration_id": null,
  #     "authentication_provider_id": null,
  #     "workflow_state": "active",
  #     "declared_user_type": "teacher"
  #   }
  def update
    if api_request?
      @pseudonym = Pseudonym.active.find(params[:id])
      return unless (@user = @pseudonym.user)

      params[:login] ||= {}
      params[:login][:password_confirmation] = params[:login][:password] if params[:login][:password]
      params[:pseudonym] = params[:login]
    else
      return unless get_user

      @pseudonym = Pseudonym.active.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @pseudonym.user_id == @user.id
    end

    return unless authorized_action(@pseudonym, @current_user, [:update, :change_password])
    return unless find_authentication_provider
    return unless update_pseudonym_from_params

    if @pseudonym.save_without_session_maintenance
      flash[:notice] = t "notices.account_updated", "Account updated!"
      respond_to do |format|
        format.html { redirect_to user_profile_url(@current_user) }
        format.json { render json: pseudonym_json(@pseudonym, @current_user, session) }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: @pseudonym.errors, status: :bad_request }
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
    @pseudonym.current_user = @current_user
    raise ActiveRecord::RecordNotFound unless @pseudonym.user_id == @user.id
    return unless authorized_action(@pseudonym, @current_user, :delete)

    if @user.all_active_pseudonyms.length < 2
      @pseudonym.errors.add(:base, t("errors.login_required", "Users must have at least one login"))
      render json: @pseudonym.errors, status: :bad_request
    elsif @pseudonym.destroy
      if api_request?
        render(json: pseudonym_json(@pseudonym, @current_user, session))
      else
        render(json: @pseudonym)
      end
    else
      render json: @pseudonym.errors, status: :bad_request
    end
  end

  protected

  def context_is_root_account?
    if @context.root_account?
      true
    else
      render(json: { "message" => "Action must be called on a root account." }, status: :bad_request)
      false
    end
  end

  def find_authentication_provider
    return true unless params[:pseudonym][:authentication_provider_id]

    params[:pseudonym][:authentication_provider] = @domain_root_account
                                                   .authentication_providers.active
                                                   .find(params[:pseudonym][:authentication_provider_id])
  end

  def update_pseudonym_from_params
    # you have to at least attempt something recognized...
    if params[:pseudonym].slice(
      :unique_id,
      :password,
      :sis_user_id,
      :authentication_provider_id,
      :integration_id,
      :workflow_state,
      :declared_user_type
    ).blank?
      render json: nil, status: :bad_request
      return false
    end

    # perform updates (if they have permission
    # to make them). silently ignore unrecognized fields.
    # note: make sure sis_user_id is updated (if happening)
    # before password, since it may affect the :change_password permissions

    @override_sis_stickiness = !params[:override_sis_stickiness] || value_to_boolean(params[:override_sis_stickiness]) || params[:action] != "update"

    has_right_if_requests_change(:unique_id, :update) do
      if can_modify_field(@override_sis_stickiness, @pseudonym.stuck_sis_fields, :unique_id)
        @pseudonym.unique_id = params[:pseudonym][:unique_id]
      end
    end or return false

    has_right_if_requests_change(:authentication_provider, :update) do
      if can_modify_field(@override_sis_stickiness, @pseudonym.stuck_sis_fields, :authentication_provider)
        @pseudonym.authentication_provider = params[:pseudonym][:authentication_provider]
      end
    end or return false

    has_right_if_requests_change(:declared_user_type, :update) do
      if can_modify_field(@override_sis_stickiness, @pseudonym.stuck_sis_fields, :declared_user_type)
        @pseudonym.declared_user_type = params[:pseudonym][:declared_user_type]
      end
    end or return false

    has_right_if_requests_change(:sis_user_id, :manage_sis) do
      # convert "" -> nil for sis_user_id
      @pseudonym.sis_user_id = params[:pseudonym][:sis_user_id].presence
    end or return false

    has_right_if_requests_change(:integration_id, :manage_sis) do
      # convert "" -> nil for integration_id
      @pseudonym.integration_id = params[:pseudonym][:integration_id].presence
    end or return false

    # give a 400 instead of a 401 if it doesn't make sense to change the password
    if params[:pseudonym].key?(:password) && !@pseudonym.passwordable?
      @pseudonym.errors.add(:password, "password can only be set for Canvas authentication")
      respond_to do |format|
        format.html { render((params[:action] == "edit") ? :edit : :new) }
        format.json { render json: @pseudonym.errors, status: :bad_request }
      end
      return false
    end

    has_right_if_requests_change(:password, :change_password) do
      if can_modify_field(@override_sis_stickiness, @pseudonym.stuck_sis_fields, :password)
        @pseudonym.password = params[:pseudonym][:password]
        @pseudonym.password_confirmation = params[:pseudonym][:password_confirmation]
      end
    end or return false

    # give a 400 instead of a 401 if the workflow_state doesn't make sense
    if params[:pseudonym].key?(:workflow_state) && !%w[active suspended].include?(params[:pseudonym][:workflow_state])
      @pseudonym.errors.add(:workflow_state, "invalid workflow_state")
      respond_to do |format|
        format.html { render((params[:action] == "edit") ? :edit : :new) }
        format.json { render json: @pseudonym.errors, status: :bad_request }
      end
      return false
    end

    has_right_if_requests_change(:workflow_state, :delete) do
      if can_modify_field(@override_sis_stickiness, @pseudonym.stuck_sis_fields, :workflow_state)
        @pseudonym.workflow_state = params[:pseudonym][:workflow_state]
      end
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

  def can_modify_field(override_sis_stickiness, stick_fields_set, key)
    override_sis_stickiness || !stick_fields_set.include?(key)
  end
end
