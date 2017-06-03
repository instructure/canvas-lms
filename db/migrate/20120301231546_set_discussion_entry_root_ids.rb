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

class SetDiscussionEntryRootIds < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def self.up
    # fix up parent_id, which was getting set to 0 for root-level entries
    # also set root_entry_id to parent_id for all existing entries
    DiscussionEntry.update_all("parent_id = CASE parent_id WHEN 0 THEN NULL ELSE parent_id END, root_entry_id = CASE parent_id WHEN 0 THEN NULL ELSE parent_id END")
  end

  def self.down
    DiscussionEntry.where(:parent_id => nil).update_all(:parent_id => 0)
    # previous migration drops the root_entry_id column here
  end
end
