#
# Copyright (C) 2020 - present Instructure, Inc.
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

class NotificationPolicyOverride < ActiveRecord::Base

  # NotificationPolicyOverride(id: integer,
  #                            context_id: integer,
  #                            context_type: string,
  #                            communication_channel_id: integer,
  #                            notification_id: integer,
  #                            workflow_state: boolean,
  #                            frequency: string,
  #                            created_at: datetime,
  #                            updated_at: datetime)

  include NotificationPreloader

  belongs_to :communication_channel, inverse_of: :notification_policy_overrides
  belongs_to :context, polymorphic: [:course]
  belongs_to :notification, inverse_of: :notification_policy_overrides

end

