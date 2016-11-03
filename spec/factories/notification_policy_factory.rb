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

module Factories
  def notification_policy_model(opts={})
    opts = opts.dup
    opts[:notification] ||= @notification
    opts[:notification] ||= notification_model
    opts[:frequency] ||= Notification::FREQ_IMMEDIATELY
    opts[:communication_channel] ||= CommunicationChannel.create!(:path => 'notification_policy@example.com', :user => opts[:user] || @user || User.create!)
    @notification_policy = factory_with_protected_attributes(NotificationPolicy,
      opts)
  end
end
