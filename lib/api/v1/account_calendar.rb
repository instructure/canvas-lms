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

module Api::V1::AccountCalendar
  include Api::V1::Json

  ACCOUNT_ATTRIBUTES = %w[id name parent_account_id root_account_id].freeze

  def account_calendars_json(accounts, user, session, include: [])
    accounts.map { |account| account_calendar_json(account, user, session, include:) }
  end

  def account_calendar_json(account, user, session, include: [])
    json = api_json(account, user, session, only: ACCOUNT_ATTRIBUTES)
    json["visible"] = account.account_calendar_visible
    json["auto_subscribe"] = account.account_calendar_subscription_type == "auto"
    json["asset_string"] = account.asset_string
    json["type"] = account.class.to_s.downcase
    json["sub_account_count"] = account.sub_accounts.count if include.include? "sub_account_count"
    json["calendar_event_url"] = account.respond_to?(:calendar_events) ? named_context_url(account, :context_calendar_event_url, "{{ id }}") : ""
    json["can_create_calendar_events"] = account.respond_to?(:calendar_events) && CalendarEvent.new.tap { |e| e.context = account }.grants_right?(user, session, :create)
    json["create_calendar_event_url"] = account.respond_to?(:calendar_events) ? named_context_url(account, :context_calendar_events_url) : ""
    json["new_calendar_event_url"] = account.respond_to?(:calendar_events) ? named_context_url(account, :new_context_calendar_event_url) : ""
    json
  end
end
