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

def delayed_message_model(opts={})
  @delayed_message = factory_with_protected_attributes(DelayedMessage, delayed_message_valid_attributes(opts).merge(opts))
end

def delayed_message_valid_attributes(opts={})
  opts[:notification] ||= @notification
  opts[:notification] ||= notification_model
  user = opts[:user] || @user || User.create!
  cc = opts.delete(:cc) || user.communication_channels.first || user.communication_channels.create!(:path => "delayed_message@example.com")
  np = cc.notification_policies.where(:notification_id => opts[:notification].id, :frequency => Notification::FREQ_IMMEDIATELY).first_or_create!
  {
    :notification_id => opts[:notification].id,
    :notification_policy_id => np.id,
    :context_id => cc.id,
    :context_type => "CommunicationChannel",
    :communication_channel_id => cc.id
  }
end
