#
# Copyright (C) 2013 Instructure, Inc.
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

# @API Authentications Log
#
# Query audit log of authentication events (logins and logouts).
#
# Only available if the server has configured audit logs; will return 404 Not
# Found response otherwise.
#
# For each endpoint, a compound document is returned. The primary collection of
# event objects is paginated, ordered by date descending. Secondary collections
# of logins, accounts, page views, and users related to the returned events
# are also included. Refer to the Logins, Accounts, Page Views, and Users APIs
# for descriptions of the objects in those collections.
#
# @object AuthenticationEvent
#     {
#       // ID of the event.
#       "id": "e2b76430-27a5-0131-3ca1-48e0eb13f29b",
#
#       // timestamp of the event
#       "created_at": "2012-07-19T15:00:00-06:00",
#
#       // authentication event type ('login' or 'logout')
#       "event_type": "login",
#
#       "links": {
#          // ID of the login associated with the event
#          "login_id": 9478,
#
#          // ID of the account associated with the event. will match the
#          // account_id in the associated login.
#          "account_id": 2319,
#
#          // ID of the user associated with the event will match the user_id in
#          // the associated login.
#          "user_id": 362,
#
#          // ID of the page view during the event if it exists.
#          "page_view_id": "e2b76430-27a5-0131-3ca1-48e0eb13f29b"
#       }
#     }
#
class AuthenticationAuditApiController < AuditorApiController
  include Api::V1::AuthenticationEvent

  # @API Query by login.
  #
  # List authentication events for a given login.
  #
  # @argument start_time [Optional, DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  def for_login
    @pseudonym = Pseudonym.active.find(params[:login_id])
    if account_visible(@pseudonym.account) || account_visible(Account.site_admin)
      events = Auditors::Authentication.for_pseudonym(@pseudonym, query_options)
      render_events(events, @pseudonym, api_v1_audit_authentication_login_url(@pseudonym))
    else
      render_unauthorized_action
    end
  end

  # @API Query by account.
  #
  # List authentication events for a given account.
  #
  # @argument start_time [Optional, Datetime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  def for_account
    @account = api_find(Account.active, params[:account_id])
    if account_visible(@account) || account_visible(Account.site_admin)
      events = Auditors::Authentication.for_account(@account, query_options)
      render_events(events, @account)
    else
      render_unauthorized_action
    end
  end

  # @API Query by user.
  #
  # List authentication events for a given user.
  #
  # @argument start_time [Optional, Datetime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  def for_user
    @user = api_find(User.active, params[:user_id])
    if @user == @current_user || account_visible(Account.site_admin)
      events = Auditors::Authentication.for_user(@user, query_options)
      render_events(events, @user)
    else
      accounts = Shard.with_each_shard(@user.associated_shards) do
        Account.joins(:pseudonyms).where(:pseudonyms => {
          :user_id => @user,
          :workflow_state => 'active'
        }).all
      end
      visible_accounts = accounts.select{ |a| account_visible(a) }
      if visible_accounts == accounts
        events = Auditors::Authentication.for_user(@user, query_options)
        render_events(events, @user)
      elsif visible_accounts.present?
        pseudonyms = Shard.partition_by_shard(visible_accounts) do |shard_accounts|
          Pseudonym.active.where(user_id: @user, account_id: shard_accounts).all
        end
        events = Auditors::Authentication.for_pseudonyms(pseudonyms, query_options)
        render_events(events, @user)
      else
        render_unauthorized_action
      end
    end
  end

  private

  def account_visible(account)
    account.grants_rights?(@current_user, nil, :view_statistics, :manage_user_logins).values.any?
  end

  def render_events(events, context, route=nil)
    route ||= polymorphic_url([:api_v1, :audit_authentication, context])
    events = Api.paginate(events, self, route)
    render :json => authentication_events_compound_json(events, @current_user, session)
  end
end
