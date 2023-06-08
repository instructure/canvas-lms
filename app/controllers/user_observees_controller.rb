# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

# @API User Observees
# API for accessing information about the users a user is observing.

class UserObserveesController < ApplicationController
  before_action :require_user

  before_action :self_or_admin_permission_check, except: [:update]

  # @API List observees
  #
  # A paginated list of the users that the given user is observing.
  #
  # *Note:* all users are allowed to list their own observees. Administrators can list
  # other users' observees.
  #
  # The returned observees will include an attribute "observation_link_root_account_ids", a list
  # of ids for the root accounts the observer and observee are linked on. The observer will only be able to
  # observe in courses associated with these root accounts.
  #
  # @argument include[] [String, "avatar_url"]
  #   - "avatar_url": Optionally include avatar_url.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees \
  #          -X GET \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def index
    includes = params[:include] || []
    observed_users = observer.linked_students.order_by_sortable_name
    observed_users = Api.paginate(observed_users, self, api_v1_user_observees_url)

    UserPastLtiId.manual_preload_past_lti_ids(users, @domain_root_account) if ["uuid", "lti_id"].any? { |id| includes.include? id }
    data = users_json(observed_users, @current_user, session, includes, @domain_root_account)
    add_linked_root_account_ids_to_user_json(data)
    render json: data
  end

  # @API List observers
  # A paginated list of the observers of a given user.
  #
  # *Note:* all users are allowed to list their own observers. Administrators can list
  # other users' observers.
  #
  # The returned observers will include an attribute "observation_link_root_account_ids", a list
  # of ids for the root accounts the observer and observee are linked on. The observer will only be able to
  # observe in courses associated with these root accounts.
  #
  # @argument include[] [String, "avatar_url"]
  #   - "avatar_url": Optionally include avatar_url.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observers \
  #          -X GET \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def observers
    includes = params[:include] || []
    users = student.linked_observers.order_by_sortable_name
    users = Api.paginate(users, self, api_v1_user_observers_url)

    UserPastLtiId.manual_preload_past_lti_ids(users, @domain_root_account) if ["uuid", "lti_id"].any? { |id| includes.include? id }
    data = users_json(users, @current_user, session, includes, @domain_root_account)
    add_linked_root_account_ids_to_user_json(data)
    render json: data
  end

  # @API Add an observee with credentials
  #
  # Register the given user to observe another user, given the observee's credentials.
  #
  # *Note:* all users are allowed to add their own observees, given the observee's
  # credentials or access token are provided. Administrators can add observees given credentials, access token or
  # the {api:UserObserveesController#update observee's id}.
  #
  # @argument observee[unique_id] [Optional, String]
  #   The login id for the user to observe.  Required if access_token is omitted.
  #
  # @argument observee[password] [Optional, String]
  #   The password for the user to observe. Required if access_token is omitted.
  #
  # @argument access_token [Optional, String]
  #   The access token for the user to observe.  Required if <tt>observee[unique_id]</tt> or <tt>observee[password]</tt> are omitted.
  #
  # @argument pairing_code [Optional, String]
  #   A generated pairing code for the user to observe. Required if the Observer pairing code feature flag is enabled
  #
  # @argument root_account_id [Optional, Integer]
  #   The ID for the root account to associate with the observation link.
  #   Defaults to the current domain account.
  #   If 'all' is specified, a link will be created for each root account associated
  #   to both the observer and observee.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees \
  #          -X POST \
  #          -H 'Authorization: Bearer <token>' \
  #          -F 'observee[unique_id]=UNIQUE_ID' \
  #          -F 'observee[password]=PASSWORD'
  #
  # @returns User
  def create
    # verify target observee exists and is in an account with the observer
    if params[:access_token]
      verified_token = AccessToken.authenticate(params[:access_token])
      if verified_token.nil?
        render json: { errors: [{ "message" => "Unknown observee." }] }, status: :unprocessable_entity
        return
      end
      @student = verified_token.user
      common_root_accounts = common_root_accounts_for(observer, student)
    elsif params[:pairing_code]
      code = find_observer_pairing_code(params[:pairing_code])
      if code.nil?
        render json: { errors: [{ "message" => "Invalid pairing code." }] }, status: :unprocessable_entity
        return
      end
      @student = code.user
      common_root_accounts = common_root_accounts_for(observer, student)
      code.destroy
    else
      observee_pseudonym = @domain_root_account.pseudonyms.active_only.by_unique_id(params[:observee][:unique_id]).first

      common_root_accounts = common_root_accounts_for(observer, observee_pseudonym.user) if observee_pseudonym
      if observee_pseudonym.nil? || common_root_accounts.empty?
        render json: { errors: [{ "message" => "Unknown observee." }] }, status: :unprocessable_entity
        return
      end

      # if using external auth, save off form information then send to external
      # login form. remainder of adding observee happens in response to that flow
      if @domain_root_account.parent_registration?
        session[:parent_registration] = {}
        session[:parent_registration][:user_id] = @current_user.id
        session[:parent_registration][:observee] = params[:observee]
        session[:parent_registration][:observee_only] = true
        render(json: { redirect: saml_observee_path })
        return
      end

      # verify provided password
      unless Pseudonym.authenticate(params[:observee] || {}, [@domain_root_account.id] + @domain_root_account.trusted_account_ids)
        render json: { errors: [{ "message" => "Invalid credentials provided." }] }, status: :unauthorized
        return
      end

      # add observer
      @student = observee_pseudonym.user
    end

    if observer != @current_user
      common_root_accounts = common_root_accounts.select { |a| a.grants_right?(@current_user, :manage_user_observers) }
      return render_unauthorized_action if common_root_accounts.empty?
    end

    create_observation_links(common_root_accounts)

    render_student_json
  end

  def find_observer_pairing_code(pairing_code)
    ObserverPairingCode.active.where(code: pairing_code).first
  end

  # @API Show an observee
  #
  # Gets information about an observed user.
  #
  # *Note:* all users are allowed to view their own observees.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees/<observee_id> \
  #          -X GET \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def show
    raise ActiveRecord::RecordNotFound unless has_observation_link?

    render_student_json
  end

  # @API Show an observer
  #
  # Gets information about an observer.
  #
  # *Note:* all users are allowed to view their own observers.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observers/<observer_id> \
  #          -X GET \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def show_observer
    scope = student.as_student_observation_links.where(observer:)
    raise ActiveRecord::RecordNotFound unless scope.exists?

    json = user_json(observer, @current_user, session)
    add_linked_root_account_ids_to_user_json([json])
    render json:
  end

  # @API Add an observee
  #
  # Registers a user as being observed by the given user.
  #
  # @argument root_account_id [Optional, Integer]
  #   The ID for the root account to associate with the observation link.
  #   If not specified, a link will be created for each root account associated
  #   to both the observer and observee.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees/<observee_id> \
  #          -X PUT \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def update
    root_accounts = common_root_accounts_with_permissions(observer, student)
    if root_accounts_valid?(root_accounts)
      create_observation_links(root_accounts)

      render_student_json
    end
  end

  # @API Remove an observee
  #
  # Unregisters a user as being observed by the given user.
  #
  # @argument root_account_id [Optional, Integer]
  #   If specified, only removes the link for the given root account
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees/<observee_id> \
  #          -X DELETE \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def destroy
    scope = if observer == @current_user
              observer.as_observer_observation_links.where(student:)
            else
              observer.as_observer_observation_links.where(student:).for_root_accounts(@accounts_with_observer_permissions)
            end
    raise ActiveRecord::RecordNotFound unless scope.exists?

    scope.destroy_all
    render_student_json
  end

  private

  def observer
    param = params[:observer_id] || params[:user_id]
    @observer ||= param.nil? ? @current_user : api_find(User.active, param)
  end

  def student
    param = params[:observee_id] || params[:user_id]
    @student ||= api_find(User.active, param)
  end

  def user
    if ["observers", "show_observer"].include?(params[:action])
      student
    else
      observer
    end
  end

  def create_observation_links(root_accounts)
    updated = false
    root_accounts.each do |root_account|
      unless has_observation_link?(root_account)
        UserObservationLink.create_or_restore(student:, observer:, root_account:)
        updated = true
      end
    end
    observer.touch if updated
  end

  def has_observation_link?(root_account = nil)
    scope = observer.as_observer_observation_links.where(student:)
    scope = scope.for_root_accounts(root_account) if root_account
    scope.exists?
  end

  def self_or_admin_permission_check
    return true if user == @current_user

    admin_permission_check
  end

  def admin_permission_check
    @accounts_with_observer_permissions = common_root_accounts_with_permissions(user)
    root_accounts_valid?(@accounts_with_observer_permissions)
  end

  def root_accounts_valid?(accounts)
    if accounts.nil?
      raise ActiveRecord::RecordNotFound
    elsif accounts.empty?
      render_unauthorized_action
      false
    else
      true
    end
  end

  def common_root_accounts_for(*users)
    shards = users.map(&:associated_shards).reduce(:&)
    root_account = root_account_for_new_link
    Shard.with_each_shard(shards) do
      user_ids = users.map(&:id)
      scope = Account.where(id: UserAccountAssociation
        .joins(:account).where(accounts: { parent_account_id: nil })
        .where(user_id: user_ids)
        .group(:account_id)
        .having("count(*) = #{user_ids.length}") # user => account is unique for user_account_associations
        .select(:account_id))
      scope = scope.where(id: root_account) if root_account # scope down to a root_account if specified
      scope
    end
  end

  def root_account_for_new_link
    if %w[create update].include?(action_name)
      case params[:root_account_id]
      when "all"
        nil
      when nil
        @domain_root_account
      else
        api_find(Account, params[:root_account_id])
      end
    end
  end

  def common_root_accounts_with_permissions(*users)
    matching_accounts = common_root_accounts_for(*users)
    return nil if matching_accounts.empty?

    matching_accounts.select do |a|
      a.grants_right?(@current_user, :manage_user_observers)
    end
  end

  def render_student_json
    json = user_json(student, @current_user, session)
    add_linked_root_account_ids_to_user_json([json])
    render json:
  end

  def add_linked_root_account_ids_to_user_json(user_rows)
    user_rows = Array(user_rows)
    ra_id_map = {}
    if ["observers", "show_observer"].include?(params[:action])
      scope = student.as_student_observation_links.where(observer: user_rows.pluck("id"))
      column = :observer_id
    else
      scope = observer.as_observer_observation_links.where(student: user_rows.pluck("id"))
      column = :user_id
    end

    if user != @current_user
      scope = scope.where(root_account_id: @accounts_with_observer_permissions || common_root_accounts_with_permissions(user))
    end
    scope.pluck(column, :root_account_id).each do |user_id, ra_id|
      ra_id_map[user_id] ||= []
      ra_id_map[user_id] << ra_id
    end

    user_rows.each do |row|
      row["observation_link_root_account_ids"] = ra_id_map[row["id"]] || []
    end
  end
end
