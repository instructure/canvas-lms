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

module DataFixup
  module PopulateStreamItemNotificationCategory
    def self.run
      categories_to_ids = {}
      StreamItem.where(:asset_type => "Message", :notification_category => nil).find_each do |item|
        category = item.get_notification_category
        categories_to_ids[category] ||= []
        categories_to_ids[category] << item.id
      end
      categories_to_ids.each do |category, all_ids|
        all_ids.each_slice(1000) do |item_ids|
          StreamItem.where(:id => item_ids).update_all(:notification_category => category)
        end
      end
    end
  end
end
