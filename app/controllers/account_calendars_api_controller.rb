# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

# @API Account Calendars
#
# API for viewing and toggling visibility of account calendars.
#
# An account calendar is available for each account in Canvas. All account calendars
# are visible by default, but administrators with the
# `manage_account_calendar_visibility` permission may hide calendars. Administrators
# with the `manage_account_calendar_events` permission can create events in visible
# account calendars, and users associated with an account can add the calendar and
# see its events (if the calendar is visible).
#
# @model AccountCalendar
#     {
#       "id": "AccountCalendar",
#       "properties": {
#         "id": {
#           "description": "the ID of the account associated with this calendar",
#           "example": 204,
#           "type": "integer"
#         },
#         "name": {
#           "description": "the name of the account associated with this calendar",
#           "example": "Department of Chemistry",
#           "type": "string"
#         },
#         "parent_account_id": {
#           "description": "the account's parent ID, or null if this is the root account",
#           "example": 1,
#           "type": "integer"
#         },
#         "root_account_id": {
#           "description": "the ID of the root account, or null if this is the root account",
#           "example": 1,
#           "type": "integer"
#         },
#         "visible": {
#           "description": "whether this calendar is visible to users",
#           "example": true,
#           "type": "boolean"
#         },
#         "has_subaccounts": {
#           "description": "whether this account has any sub-accounts",
#           "example": false,
#           "type": "boolean"
#         }
#       }
#     }
class AccountCalendarsApiController < ApplicationController
  include Api::V1::AccountCalendar

  before_action :require_user
  before_action :require_feature_flag # remove once :account_calendar_events FF is gone

  # @API List available account calendars
  #
  # Returns a paginated list of account calendars available to the current user.
  # Includes visible account calendars where the user has an account association.
  #
  # @argument search_term [Optional, String]
  #   When included, searches available account calendars for the term. Returns matching
  #   results. Term must be at least 2 characters.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/account_calendars \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [AccountCalendar]
  def index
    GuardRail.activate(:secondary) do
      search_term = params[:search_term]
      accounts = @current_user.associated_accounts.active.where(account_calendar_visible: true)
      accounts = Account.search_by_attribute(accounts, :name, search_term) if search_term.present?
      paginated_accounts = Api.paginate(accounts.reorder(Account.best_unicode_collation_key("name"), :id), self, api_v1_account_calendars_url)
      render json: account_calendars_json(paginated_accounts, @current_user, session)
    end
  end

  # @API Get a single account calendar
  #
  # Get details about a specific account calendar.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/account_calendars/204 \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns AccountCalendar
  def show
    GuardRail.activate(:secondary) do
      account = api_find(Account.active, params[:account_id])
      return unless authorized_action(account, @current_user, :view_account_calendar_details)

      render json: account_calendar_json(account, @current_user, session)
    end
  end

  # @API Update a calendar's visibility
  #
  # Set an account calendar as hidden or visible. Requires the
  # `manage_account_calendar_visibility` permission on the account.
  #
  # @argument visible [Boolean]
  #   Allow administrators with `manage_account_calendar_events` permission
  #   to create events on this calendar, and allow users to view this
  #   calendar and its events.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/account_calendars/204 \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'visible=false'
  #
  # @returns AccountCalendar
  def update
    account = api_find(Account.active, params[:account_id])
    return unless authorized_action(account, @current_user, :manage_account_calendar_visibility)
    return render json: { errors: "Missing param: `visible`" }, status: :bad_request if params[:visible].nil?

    account.account_calendar_visible = value_to_boolean(params[:visible])
    account.save!
    render json: account_calendar_json(account, @current_user, session)
  end

  # @API List all account calendars
  #
  # Returns a paginated list of account calendars for the provided account and
  # its first level of sub-accounts. Includes hidden calendars in the response.
  # Requires the `manage_account_calendar_visibility` permission.
  #
  # @argument search_term [Optional, String]
  #   When included, searches all descendent accounts of provided account for the
  #   term. Returns matching results. Term must be at least 2 characters.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/accounts/1/account_calendars \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns [AccountCalendar]
  def all_calendars
    GuardRail.activate(:secondary) do
      account = api_find(Account.active, params[:account_id])
      search_term = params[:search_term]
      return unless authorized_action(account, @current_user, :manage_account_calendar_visibility)

      accounts = if search_term.present?
                   searchable_account_ids = [account.id] + Account.sub_account_ids_recursive(account.id)
                   Account.search_by_attribute(Account.active.where(id: searchable_account_ids), :name, params[:search_term]).order(Account.best_unicode_collation_key("name"), :id)
                 else
                   [account] + account.sub_accounts.order(Account.best_unicode_collation_key("name"), :id)
                 end

      paginated_accounts = Api.paginate(accounts, self, api_v1_all_account_calendars_url)
      render json: account_calendars_json(paginated_accounts, @current_user, session, include: ["has_subaccounts"])
    end
  end

  private

  def require_feature_flag
    not_found unless Account.site_admin.feature_enabled?(:account_calendar_events)
  end
end
