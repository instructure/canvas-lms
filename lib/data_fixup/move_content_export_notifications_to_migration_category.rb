#
# Copyright (C) 2012 - present Instructure, Inc.
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

module DataFixup::MoveContentExportNotificationsToMigrationCategory
  def self.run
    Notification.where(:name => ['Content Export Finished', 'Content Export Failed']).
        update_all(:category => 'Migration') if Shard.current.default?

    # send immediate notifications only work if you DON'T have a policy for that notification
    notification_ids_to_remove = Notification.where(:category => 'Migration').pluck(:id)
    if notification_ids_to_remove.present?
      NotificationPolicy.find_ids_in_ranges do |first_id, last_id|
        NotificationPolicy.where(:id => first_id..last_id, :notification_id => notification_ids_to_remove).delete_all
      end
    end
  end
end
