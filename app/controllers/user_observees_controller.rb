#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
  before_filter :require_user

  before_filter :self_or_admin_permission_check, except: [:update]
  before_filter :admin_permission_check, only: [:update]

  # @API List observees
  #
  # List the users that the given user is observing.
  #
  # *Note:* all users are allowed to list their own observees. Administrators can list
  # other users' observees.
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
    observed_users = user.observed_users.active_user_observers.active.order_by_sortable_name
    observed_users = Api.paginate(observed_users, self, api_v1_user_observees_url)
    render json: users_json(observed_users, @current_user, session,includes )
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
        render json: {errors: [{'message' => 'Unknown observee.'}]}, status: 422
        return
      end
      observee_user = verified_token.user
    else
      observee_pseudonym = @domain_root_account.pseudonyms.active.by_unique_id(params[:observee][:unique_id]).first
      if observee_pseudonym.nil? || common_accounts_for(user, observee_pseudonym.user).empty?
        render json: {errors: [{'message' => 'Unknown observee.'}]}, status: 422
        return
      end


      # if using external auth, save off form information then send to external
      # login form. remainder of adding observee happens in response to that flow
      if @domain_root_account.parent_registration?
        session[:parent_registration] = {}
        session[:parent_registration][:user_id] = @current_user.id
        session[:parent_registration][:observee] = params[:observee]
        session[:parent_registration][:observee_only] = true
        render(json: {redirect: saml_observee_path})
        return
      end

      # verify provided password
      unless Pseudonym.authenticate(params[:observee] || {}, [@domain_root_account.id] + @domain_root_account.trusted_account_ids)
        render json: {errors: [{'message' => 'Invalid credentials provided.'}]}, status: :unauthorized
        return
      end

      # add observer
      observee_user = observee_pseudonym.user
    end
    add_observee(observee_user)
    render json: user_json(observee_user, @current_user, session)
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
    raise ActiveRecord::RecordNotFound unless has_observee?(observee)

    render json: user_json(observee, @current_user, session)
  end

  # @API Add an observee
  #
  # Registers a user as being observed by the given user.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees/<observee_id> \
  #          -X PUT \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def update
    raise ActiveRecord::RecordNotFound unless can_manage_observers_for?(user, observee)

    add_observee(observee)
    render json: user_json(observee, @current_user, session)
  end

  # @API Remove an observee
  #
  # Unregisters a user as being observed by the given user.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees/<observee_id> \
  #          -X DELETE \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns User
  def destroy
    raise ActiveRecord::RecordNotFound unless has_observee?(observee)

    user.user_observees.active.where(user_id: observee).destroy_all
    render json: user_json(observee, @current_user, session)
  end

  private

  def user
    @user ||= params[:user_id].nil? ? @current_user : api_find(User.active, params[:user_id])
  end

  def observee
    @observee ||= api_find(User.active, params[:observee_id])
  end

  def add_observee(observee)
    @current_user.shard.activate do
      unless has_observee?(observee)
        user.user_observees.create_or_restore(user_id: observee)
        user.touch
      end
    end
  end

  def has_observee?(observee)
    user.user_observees.active.where(user_id: observee).exists?
  end

  def self_or_admin_permission_check
    return true if user == @current_user
    admin_permission_check
  end

  def admin_permission_check
    return true if can_manage = can_manage_observers_for?(user)

    if can_manage.nil?
      raise ActiveRecord::RecordNotFound
    else
      render_unauthorized_action
    end
  end

  def common_accounts_for(*users)
    shards = users.map(&:associated_shards).reduce(:&)
    Shard.with_each_shard(shards) do
      user_ids = users.map(&:id)
      Account.where(id: UserAccountAssociation.
        joins(:account).where(accounts: {parent_account_id: nil}).
        where(user_id: user_ids).
        group(:account_id).
        having("count(*) = #{user_ids.length}"). # user => account is unique for user_account_associations
        select(:account_id)
      )
    end
  end

  def can_manage_observers_for?(*users)
    matching_accounts = common_accounts_for(*users)
    return nil if matching_accounts.empty?

    matching_accounts.any? do |a|
      return true if a.grants_right?(@current_user, :manage_user_observers)
    end
  end
end
