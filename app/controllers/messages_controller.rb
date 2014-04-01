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

class MessagesController < ApplicationController
  before_filter :require_read_messages, :get_context

  def require_read_messages
    require_site_admin_with_permission(:read_messages)
  end

  def index
    @messages = @context.messages.order('created_at DESC').paginate(:page => params[:page], :per_page => 20)
  end

  def create
    secure_id, message_id = [params[:secure_id], params[:message_id].to_i]

    message = Mail.new
    message['Content-Type'] = 'text/plain; charset="UTF-8"'
    message['Subject']      = params[:subject]
    message['From']         = params[:from]
    message.body            = params[:message]

    IncomingMailProcessor::IncomingMessageProcessor.new(IncomingMail::MessageHandler.new, ErrorReport::Reporter.new).process_single(message, "#{secure_id}-#{message_id}")
    render :nothing => true
  end

  def html_message
    message = @context.messages.find(params[:message_id])
    if message.html_body.present?
      render :inline => message.html_body, :layout => false
    else
      render :layout => false
    end
  end
end
