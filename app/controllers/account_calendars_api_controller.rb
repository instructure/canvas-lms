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
# API for viewing and toggling settings of account calendars.
#
# An account calendar is available for each account in Canvas. All account calendars
# are hidden by default, but administrators with the `manage_account_calendar_visibility`
# permission may set calendars as visible. Administrators with the
# `manage_account_calendar_events` permission can create events in visible account
# calendars, and users associated with an account can add the calendar and see its
# events (if the calendar is visible). Events on calendars set as `auto_subscribe`
# calendars will appear on users' calendars even if they do not manually add it.
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
#         "auto_subscribe": {
#           "description": "whether users see this calendar's events without needing to manually add it",
#           "example": false,
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
#         },
#         "calendar_event_url": {
#           "description": "url to get full detailed events",
#           "example": "/accounts/2/calendar_events/%7B%7B%20id%20%7D%7D",
#           "type": "string"
#         },
#         "can_create_calendar_events": {
#           "description": "whether the user can create calendar events",
#           "example": true,
#           "type": "boolean"
#         },
#         "create_calendar_event_url": {
#           "description": "API path to create events for the account",
#           "example": "/accounts/2/calendar_events",
#           "type": "string"
#         },
#         "new_calendar_event_url": {
#           "description": "url to open the more options event editor",
#           "example": "/accounts/6/calendar_events/new",
#           "type": "string"
#         }
#       }
#     }
class AccountCalendarsApiController < ApplicationController
  include Api::V1::AccountCalendar

  before_action :require_user

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
      accounts = @current_user.all_account_calendars
      accounts = Account.search_by_attribute(accounts, :name, search_term) if search_term.present?
      paginated_accounts = Api.paginate(accounts.sort_by { |a| Canvas::ICU.collation_key(a.name.to_s) }, self, api_v1_account_calendars_url, total_entries: accounts.count)
      json = {
        account_calendars: account_calendars_json(paginated_accounts, @current_user, session),
        total_results: accounts.count
      }
      render json:
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

  # @API Update a calendar
  #
  # Set an account calendar's visibility and auto_subscribe values. Requires the
  # `manage_account_calendar_visibility` permission on the account.
  #
  # @argument visible [Boolean]
  #   Allow administrators with `manage_account_calendar_events` permission
  #   to create events on this calendar, and allow users to view this
  #   calendar and its events.
  #
  # @argument auto_subscribe [Boolean]
  #   When true, users will automatically see events from this account in their
  #   calendar, even if they haven't manually added that calendar.
  #
  # @example_request
  #   curl https://<canvas>/api/v1/account_calendars/204 \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     -d 'visible=false' \
  #     -d 'auto_subscribe=false'
  #
  # @returns AccountCalendar
  def update
    account = api_find(Account.active, params[:account_id])
    return unless authorized_action(account, @current_user, :manage_account_calendar_visibility)

    account.account_calendar_visible = value_to_boolean(params[:visible]) if params.include?(:visible)
    if params.include?(:auto_subscribe)
      auto_subscribe = value_to_boolean(params[:auto_subscribe])
      account.account_calendar_subscription_type = auto_subscribe ? "auto" : "manual"
      if auto_subscribe
        InstStatsd::Statsd.gauge("account_calendars.auto_subscribing", 1)
      else
        InstStatsd::Statsd.gauge("account_calendars.manual_subscribing", 1)
      end
    end
    account.save! if account.changed?
    render json: account_calendar_json(account, @current_user, session)
  end

  # @API Update several calendars
  #
  # Set visibility and/or auto_subscribe on many calendars simultaneously. Requires
  # the `manage_account_calendar_visibility` permission on the account.
  #
  # Accepts a JSON array of objects containing 2-3 keys each: `id`
  # (the account's id, required), `visible` (a boolean indicating whether
  # the account calendar is visible), and `auto_subscribe` (a boolean indicating
  # whether users should see these events in their calendar without manually
  # subscribing).
  #
  # @example_request
  #   curl https://<canvas>/api/v1/accounts/1/account_calendars \
  #     -X PUT \
  #     -H 'Authorization: Bearer <token>' \
  #     --data '[{"id": 1, "visible": true, "auto_subscribe": false}, {"id": 13, "visible": false, "auto_subscribe": true}]'
  #
  # Returns the count of updated accounts.
  def bulk_update
    account = api_find(Account.active, params[:account_id])
    return unless authorized_action(account, @current_user, :manage_account_calendar_visibility)

    data = params.permit(_json: %i[id visible auto_subscribe]).to_h[:_json]
    return render json: { errors: t("Expected array of objects") }, status: :bad_request unless data.is_a?(Array) && !data.empty?
    return render json: { errors: t("Missing key(s)") }, status: :bad_request unless data.all? { |c| c.key?("id") }
    return render json: { errors: t("Duplicate IDs") }, status: :bad_request unless data.pluck("id").uniq.count == data.pluck("id").count

    account_ids = data.map { |c| c["id"].to_i }
    allowed_account_ids = [account.id] + Account.sub_account_ids_recursive(account.id)
    return render_unauthorized_action unless (account_ids - allowed_account_ids).empty?

    account_scope = Account.active

    ids_to_enable_visible = data.select { |c| value_to_boolean(c["visible"]) }.pluck("id")
    ids_to_disable_visible = data.select { |c| !value_to_boolean(c["visible"]) && !c["visible"].nil? }.pluck("id")
    account_scope.where(id: ids_to_enable_visible).update_all(account_calendar_visible: true)
    account_scope.where(id: ids_to_disable_visible).update_all(account_calendar_visible: false)

    ids_to_enable_auto_subscribe = data.select { |c| value_to_boolean(c["auto_subscribe"]) }.pluck("id")
    ids_to_disable_auto_subscribe = data.select { |c| !value_to_boolean(c["auto_subscribe"]) && !c["auto_subscribe"].nil? }.pluck("id")
    account_scope.where(id: ids_to_enable_auto_subscribe).update_all(account_calendar_subscription_type: "auto")
    account_scope.where(id: ids_to_disable_auto_subscribe).update_all(account_calendar_subscription_type: "manual")

    InstStatsd::Statsd.gauge("account_calendars.auto_subscribing", ids_to_enable_auto_subscribe.length)
    InstStatsd::Statsd.gauge("account_calendars.manual_subscribing", ids_to_disable_auto_subscribe.length)

    render json: { message: t({ one: "Updated 1 account", other: "Updated %{count} accounts" }, { count: account_ids.uniq.count }) }
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
      render json: { count: }
    end
  end
end
