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

module DataFixup::RemoveDuplicateGroupMemberships
  def self.run
    rank_sql = GroupMembership.rank_sql(["accepted", "invited", "requested", "rejected"], "workflow_state")
    while (dups = GroupMembership.where.not(:workflow_state => "deleted").group(:group_id, :user_id).having("COUNT(*) > 1").pluck(:group_id, :user_id)) && dups.any?
      dups.each do |group_id, user_id|
        GroupMembership.where(:group_id => group_id, :user_id => user_id).order(rank_sql).offset(1).delete_all
      end
    end
  end
end
