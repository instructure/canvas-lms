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

module DataFixup::RemoveDuplicateNotificationPolicies
  def self.run
    while true
      ccs = NotificationPolicy.connection.select_rows("
          SELECT communication_channel_id
          FROM #{NotificationPolicy.quoted_table_name}
          WHERE notification_id IS NULL
            AND frequency='daily'
          GROUP BY communication_channel_id
          HAVING count(*) > 1 LIMIT 50000")
      break if ccs.empty?
      ccs.each do |cc_id|
        scope = NotificationPolicy.where(:communication_channel_id => cc_id, :notification_id => nil, :frequency => 'daily')
        keeper = scope.limit(1).pluck(:id).first
        scope.where("id<>?", keeper).delete_all if keeper
      end
    end
  end
end
