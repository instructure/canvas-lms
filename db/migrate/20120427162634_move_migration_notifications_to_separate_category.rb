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

class MoveMigrationNotificationsToSeparateCategory < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    return unless Shard.current == Shard.default
    Notification.where(:name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed']).
        update_all(:category => 'Migration')
  end

  def self.down
    return unless Shard.current == Shard.default
    Notification.where(:name => ['Migration Export Ready', 'Migration Import Finished', 'Migration Import Failed']).
        update_all(:category => 'Other')
  end
end
