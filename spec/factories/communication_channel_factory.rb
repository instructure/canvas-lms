#
# Copyright (C) 2011 Instructure, Inc.
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

def communication_channel_model(opts={})
  @cc = factory_with_protected_attributes(CommunicationChannel, communication_channel_valid_attributes.merge(opts))
  @communication_channel = @cc
end

def communication_channel_valid_attributes
  user = @user || User.create!
  {
    :path => "value for path",
    :user => user,
    :pseudonym_id => "1"
  }
end

def communication_channel(user, opts={})
  username = opts[:username] || "nobody@example.com"
  @cc = user.communication_channels.create!(:path_type => 'email', :path => username) do |cc|
    cc.workflow_state = 'active' if opts[:active_cc] || opts[:active_all]
    cc.workflow_state = opts[:cc_state] if opts[:cc_state]
  end
  @cc
end
