#
# Copyright (C) 2017 - present Instructure, Inc.
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

module DataFixup::PopulateContextOnWikiPages
  def self.run
    WikiPage.find_ids_in_ranges do |min_id, max_id|
      WikiPage.where(:id => min_id..max_id, :context_id => nil).joins(:wiki => :course).update_all("context_type='Course', context_id=courses.id")
      WikiPage.where(:id => min_id..max_id, :context_id => nil).joins(:wiki => :group).update_all("context_type='Group', context_id=groups.id")
    end
  end
end
