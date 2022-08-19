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
#         "sub_account_count": {
#           "description": "number of this account's direct sub-accounts",
#           "example": 0,
#           "type": "integer"
#         },
#         "asset_string": {
#           "description": "Asset string of the account",
#           "example": "account_4",
#           "type": "string"
#         },
#         "type": {
#           "description": "Object type",
#           "example": "account",
#           "type": "string"
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
  # @returns { "account_calendars": [AccountCalendar], "total_results": "integer"}
  def index
    GuardRail.activate(:secondary) do
      search_term = params[:search_term]
      InstStatsd::Statsd.increment("account_calendars.available_calendars_requested") if search_term.blank? && params[:page].nil?
      accounts = @current_user.associated_accounts.active.where(account_calendar_visible: true)
      accounts = Account.search_by_attribute(accounts, :name, search_term) if search_term.present?
      paginated_accounts = Api.paginate(accounts.reorder(Account.best_unicode_collation_key("name"), :id), self, api_v1_account_calendars_url, total_entries: accounts.count)
      json = {
        account_calendars: account_calendars_json(paginated_accounts, @current_user, session),
        total_results: accounts.count
      }
      render json: json
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
    return render json: { errors: t("Missing param: `%{param}`", { param: "visible" }) }, status: :bad_request if params[:visible].nil?

    account.account_calendar_visible = value_to_boolean(params[:visible])
    account.save!
    render json: account_calendar_json(account, @current_user, session)
  end

  # @API Update many calendars' visibility
  #
  # Set visibility on many calendars simultaneously. Requires the
  # `manage_account_calendar_visibility` permission on the account.
  #
  # Accepts a JSON array of objects containing 2 keys each: `id`
  # (the account's id), and `visible` (a boolean indicating whether
  # the account calendar is visible).
  #
  # @example_request
  #   curl https://<canvas>/api/v1/accounts/1/account_calendars \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     --data '[{"id": 1, "visible": true}, {"id": 13, "visible": false}]'
  #
  # @returns AccountCalendar
  def bulk_update
    account = api_find(Account.active, params[:account_id])
    return unless authorized_action(account, @current_user, :manage_account_calendar_visibility)

    data = params.permit(_json: [:id, :visible]).to_h[:_json]
    return render json: { errors: t("Expected array of objects") }, status: :bad_request unless data.is_a?(Array) && !data.empty?
    return render json: { errors: t("Missing key(s)") }, status: :bad_request unless data.all? { |c| c.key?("id") && c.key?("visible") }

    account_ids = data.map { |c| c["id"].to_i }
    allowed_account_ids = [account.id] + Account.sub_account_ids_recursive(account.id)
    return render_unauthorized_action unless (account_ids - allowed_account_ids).empty?

    account_ids_to_enable = data.select { |c| value_to_boolean(c["visible"]) }.map { |c| c["id"] }
    account_ids_to_disable = data.reject { |c| value_to_boolean(c["visible"]) }.map { |c| c["id"] }
    return render json: { errors: t("Unexpected value") }, status: :bad_request unless account_ids_to_enable.length + account_ids_to_disable.length == data.length && account_ids_to_enable.intersection(account_ids_to_disable).empty?

    updated_accounts = Account.active.where(id: account_ids_to_enable).update_all(account_calendar_visible: true)
    updated_accounts += Account.active.where(id: account_ids_to_disable).update_all(account_calendar_visible: false)
    render json: { message: t({ one: "Updated 1 account", other: "Updated %{count} accounts" }, { count: updated_accounts }) }
  end

  # @API List all account calendars
  #
  # Returns a paginated list of account calendars for the provided account and
  # its first level of sub-accounts. Includes hidden calendars in the response.
  # Requires the `manage_account_calendar_visibility` permission.
  #
  # @argument search_term [Optional, String]
  #   When included, searches all descendent accounts of provided account for the
  #   term. Returns matching results. Term must be at least 2 characters. Can be
  #   combined with a filter value.
  #
  # @argument filter [Optional, String, "visible"|"hidden"]
  #   When included, only returns calendars that are either visible or hidden. Can
  #   be combined with a search term.
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

      filter = params[:filter]
      if filter.present? && !%w[visible hidden].include?(filter)
        return render json: { errors: t("Expected %{filter} param to be one of: %{visible}, %{hidden}", filter: "filter", visible: "visible", hidden: "hidden") }, status: :bad_request
      end

      accounts = if search_term.present? || filter.present?
                   # search all descendants of account
                   searchable_account_ids = [account.id] + Account.sub_account_ids_recursive(account.id)
                   scope = Account.active.where(id: searchable_account_ids)
                   scope = scope.where(account_calendar_visible: filter == "visible") if filter.present?
                   scope = Account.search_by_attribute(scope, :name, params[:search_term]) if search_term.present?
                   scope.order(Account.best_unicode_collation_key("name"), :id)
                 else
                   # include only first-level sub-accounts of account
                   [account] + account.sub_accounts.order(Account.best_unicode_collation_key("name"), :id)
                 end

      paginated_accounts = Api.paginate(accounts, self, api_v1_all_account_calendars_url)
      render json: account_calendars_json(paginated_accounts, @current_user, session, include: ["sub_account_count"])
    end
  end

  # @API Count of all visible account calendars
  #
  # Returns the number of visible account calendars.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/accounts/1/visible_calendars_count \
  #     -H 'Authorization: Bearer <token>'
  #
  # @returns { "count": "integer" }
  def visible_calendars_count
    GuardRail.activate(:secondary) do
      account = api_find(Account.active, params[:account_id])
      return unless authorized_action(account, @current_user, :manage_account_calendar_visibility)

      count = Account.active.where(id: [account.id] + Account.sub_account_ids_recursive(account.id)).where(account_calendar_visible: true).count
      render json: { count: count }
    end
  end

  private

  def require_feature_flag
    not_found unless Account.site_admin.feature_enabled?(:account_calendar_events)
  end
end
