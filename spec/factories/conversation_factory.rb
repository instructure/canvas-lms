#
# Copyright (C) 2015 - present Instructure, Inc.
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

module Factories
  def conversation(*users)
    options = users.last.is_a?(Hash) ? users.pop : {}
    @conversation = (options.delete(:sender) || @me || users.shift).initiate_conversation(users, options.delete(:private), options)

    # if the "body" hash is passed in, use that for the message body
    if !options[:body].nil?
      @message = @conversation.add_message(options[:body].to_s)
    else
      @message = @conversation.add_message('test')
    end

    @conversation.update(options.slice(:subscribed, :starred, :workflow_state, :user))
    @conversation.reload
  end
end
