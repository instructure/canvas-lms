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

class AddFileNotifications < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    # (shard check added later; dupes removed in AddUniqueIndexOnNotifications)
    return unless Shard.current.default?
    Notification.create!(:name => "New File Added", :category => "Files")
    Notification.create!(:name => "New Files Added", :category => "Files")
  end

  def self.down
    # (try on each shard, because there may be duplicates due to the above)
    Notification.where(name: "New File Added").delete_all
    Notification.where(name: "New Files Added").delete_all
  end
end
