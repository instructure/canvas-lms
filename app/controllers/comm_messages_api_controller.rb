#
# Copyright (C) 2011-12 Instructure, Inc.
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

# @API CommMessages
# @beta
# 
# API for accessing the messages (emails, sms, facebook, twitter, etc) that have 
# been sent to a user. 
#
# @object CommMessage
#     {
#       // The ID of the CommMessage.
#       id: 42,
#
#       // The date and time this message was created
#       created_at: "2013-03-19T21:00:00Z"
#
#       // The date and time this message was sent
#       sent_at: "2013-03-20T22:42:00Z"
#
#       // The workflow state of the message.
#       // One of "created", "staged", "sending", "sent", "bounced",
#       // "dashboard", "cancelled", or "closed"
#       workflow_state: "sent"
#
#       // The address that was put in the "from" field of the message
#       from: "notifications@example.com"
#
#       // The address the message was sent to:
#       to: "someone@example.com"
#
#       // The reply_to header of the message
#       reply_to: "notifications+specialdata@example.com"
#
#       // The message subject
#       subject: "example subject line"
#
#       // The plain text body of the message
#       body: "This is the body of the message"
#
#       // The HTML body of the message.
#       html_body: "<html><body>This is the body of the message</body></html>"
#     }
class CommMessagesApiController < ApplicationController
  include Api::V1::CommMessage

  before_filter :require_user

  # @API List of CommMessages for a user
  # 
  # Retrieve messages sent to a user.
  # 
  # @argument user_id The user id for whom you want to retrieve CommMessages
  #
  # @argument start_time [optional] The beginning of the time range you want to
  #   retrieve meesage from.
  #
  # @argument end_time [optional] The end of the time range you want to retrieve
  #   messages for.
  #
  # @returns [CommMessage]
  def index
    user = api_find(User, params[:user_id])
    start_time = TimeHelper.try_parse(params[:start_time])
    end_time = TimeHelper.try_parse(params[:end_time])

    conditions = case
      when Account.site_admin.grants_right?(@current_user, :read_messages)
        {} # No further restrictions, site admins see all
      when @domain_root_account.grants_right?(@current_user, :read_messages)
        { :root_account_id => @domain_root_account.id }
      else
        return render_unauthorized_action
    end

    query = user.messages.scoped(:order => 'created_at DESC')
    query = query.scoped(:conditions => conditions) unless conditions.empty?
    query = query.scoped(:conditions => ['created_at >= ?', start_time]) if start_time
    query = query.scoped(:conditions => ['created_at <= ?', end_time]) if end_time
    messages = Api.paginate(query, self, api_v1_comm_messages_url)

    messages_json = messages.map { |m| comm_message_json(m) }
    render :json => messages_json
  end  
end
