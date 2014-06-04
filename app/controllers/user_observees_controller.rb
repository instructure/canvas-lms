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

  before_filter :self_or_admin_permission_check, only: [:index, :create, :show]
  before_filter :admin_permission_check, except: [:index, :create, :show]

  # @API List observees
  #
  # List the users that the given user is observing.
  #
  # *Note:* all users are allowed to list their own observees. Administrators can list 
  # other users' observees.
  #
  # @example_request
  #     curl https://<canvas>/api/v1/users/<user_id>/observees \
  #          -X GET \
  #          -H 'Authorization: Bearer <token>'
  #
  # @returns [User]
  def index
    observed_users = user.observed_users.order_by_sortable_name
    observed_users = Api.paginate(observed_users, self, api_v1_user_observees_url)
    render json: users_json(observed_users, @current_user, session)
  end

  # @API Add an observee with credentials
  #
  # Register the given user to observe another user, given the observee's credentials.
  #
  # *Note:* all users are allowed to add their own observees, given the observee's
  # credentials are provided. Administrators can add observees given credentials or
  # the {api:UserObserveesController#update observee's id}.
  #
  # @argument observee[unique_id] [String]
  #   The login id for the user to observe.
  #
  # @argument observee[password] [String]
  #   The password for the user to observe.
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
    observee_pseudonym = Pseudonym.authenticate(params[:observee] || {}, [@domain_root_account.id] + @domain_root_account.trusted_account_ids)

    observee_user = observee_pseudonym.user if observee_pseudonym && common_accounts_for(user, observee_pseudonym.user).present?
    if observee_user
      add_observee(observee_user)
      render json: user_json(observee_user, @current_user, session)
    else
      render json: {errors: [{'message' => 'Invalid credentials provided.'}]}, status: :unauthorized
    end
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

    remove_observee(observee)
    render json: user_json(observee, @current_user, session)
  end

  private

  def user
    @user ||= params[:user_id].nil? ? @current_user : api_find(User, params[:user_id])
  end

  def observee
    @observee ||= api_find(User, params[:observee_id])
  end

  def add_observee(observee)
    unless has_observee?(observee)
      user.user_observees.create! do |uo|
        uo.user_id = observee.id
      end
    end
  end

  def remove_observee(observee)
    user.user_observees.where(user_id: observee).destroy_all
  end

  def has_observee?(observee)
    user.user_observees.where(user_id: observee).exists?
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
      Account.where(id: UserAccountAssociation
        .joins(:account).where(accounts: {parent_account_id: nil})
        .where(user_id: user_ids)
        .group(:account_id)
        .having("count(*) = #{user_ids.length}") # user => account is unique for user_account_associations
        .select(:account_id)
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
