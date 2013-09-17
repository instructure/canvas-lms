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
# For each endpoint, a compound document is returned. The primary collection of
# event objects is paginated, ordered by date descending. Secondary collections
# of pseudonyms (logins), accounts, and users related to the returned events
# are also included. Refer to the Logins, Accounts, and Users APIs for
# descriptions of the objects in those collections.
#
# @object AuthenticationEvent
#     {
#       // timestamp of the event
#       "created_at": "2012-07-19T15:00:00-06:00",
#
#       // authentication event type ('login' or 'logout')
#       "event_type": "login",
#
#       // ID of the pseudonym (login) associated with the event
#       "pseudonym_id": 9478,
#
#       // ID of the account associated with the event. will match the
#       // account_id in the associated pseudonym.
#       "account_id": 2319,
#
#       // ID of the user associated with the event will match the user_id in
#       // the associated pseudonym.
#       "user_id": 362
#     }
#
class AuthenticationAuditApiController < ApplicationController
  include Api::V1::AuthenticationEvent

  # @API Query by pseudonym.
  #
  # List authentication events for a given pseudonym.
  #
  # @argument start_time [Optional, DateTime]
  #   The beginning of the time range from which you want events.
  #
  # @argument end_time [Optional, Datetime]
  #   The end of the time range from which you want events.
  #
  def for_pseudonym
    @pseudonym = Pseudonym.active.find(params[:pseudonym_id])
    if account_visible(@pseudonym.account) || account_visible(Account.site_admin)
      events = Auditors::Authentication.for_pseudonym(@pseudonym, date_options)
      render_events(events, @pseudonym)
    else
      render_unauthorized_action(@pseudonym)
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
      events = Auditors::Authentication.for_account(@account, date_options)
      render_events(events, @account)
    else
      render_unauthorized_action(@account)
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
      events = Auditors::Authentication.for_user(@user, date_options)
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
        events = Auditors::Authentication.for_user(@user, date_options)
        render_events(events, @user)
      elsif visible_accounts.present?
        pseudonyms = Shard.partition_by_shard(visible_accounts) do |shard_accounts|
          Pseudonym.active.where(user_id: @user, account_id: shard_accounts).all
        end
        events = Auditors::Authentication.for_pseudonyms(pseudonyms, date_options)
        render_events(events, @user)
      else
        render_unauthorized_action(@user)
      end
    end
  end

  private

  def account_visible(account)
    account.grants_rights?(@current_user, nil, :view_statistics, :manage_user_logins).values.any?
  end

  def render_events(events, context)
    route = polymorphic_url([:api_v1, :audit_authentication, context])
    events = Api.paginate(events, self, route)
    render :json => authentication_events_compound_json(events, @current_user, session)
  end

  def date_options
    start_time = TimeHelper.try_parse(params[:start_time])
    end_time = TimeHelper.try_parse(params[:end_time])

    options = {}
    options[:oldest] = start_time if start_time
    options[:newest] = end_time if end_time
    options
  end
end
