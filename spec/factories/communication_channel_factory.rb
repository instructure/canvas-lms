# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

module Factories
  def communication_channel_model(opts = {})
    @cc = factory_with_protected_attributes(CommunicationChannel, communication_channel_valid_attributes.merge(opts))
    @communication_channel = @cc
  end

  def communication_channel_valid_attributes
    user = @user || User.create!
    {
      path: "valid@example.com",
      user:,
      pseudonym_id: "1"
    }
  end

  def communication_channel(user, opts = {})
    username = opts[:username] || "nobody-#{user.id}@example.com"
    @cc = user.communication_channels.create!(path_type: opts[:path_type] || "email", path: username) do |cc|
      cc.workflow_state = "active" if opts[:active_cc] || opts[:active_all]
      cc.workflow_state = opts[:cc_state] if opts[:cc_state]
      cc.pseudonym = opts[:pseudonym] if opts[:pseudonym]
      cc.bounce_count = opts[:bounce_count] if opts[:bounce_count]
      cc.last_bounce_details = opts[:last_bounce_details] if opts[:last_bounce_details]
      cc.last_transient_bounce_details = opts[:last_transient_bounce_details] if opts[:last_transient_bounce_details]
    end
    @cc
  end
end
