#
# Copyright (C) 2016 - present Instructure, Inc.
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

module DataFixup::RemoveDuplicateStreamItemInstances
  def self.run
    while (dups = ActiveRecord::Base.connection.select_rows(%Q(SELECT stream_item_id, user_id FROM #{StreamItemInstance.quoted_table_name} GROUP BY stream_item_id, user_id HAVING COUNT(*) > 1))) && dups.any?
      dups.each do |stream_item_id, user_id|
        StreamItemInstance.where(:stream_item_id => stream_item_id, :user_id => user_id).offset(1).delete_all
      end
    end
  end
end
