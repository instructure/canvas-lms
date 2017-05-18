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

class AddGroupReviewSettingToAssignment < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :assignments, :intra_group_peer_reviews, :boolean
    change_column_default :assignments, :intra_group_peer_reviews, false
  end

  def self.down
    remove_column :assignments, :intra_group_peer_reviews
  end
end
