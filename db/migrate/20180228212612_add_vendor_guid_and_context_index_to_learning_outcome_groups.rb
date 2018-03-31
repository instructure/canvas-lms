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

class AddVendorGuidAndContextIndexToLearningOutcomeGroups < ActiveRecord::Migration[5.0]
  tag :predeploy

  disable_ddl_transaction!

  def change
    add_index :learning_outcome_groups,
      %i[context_type context_id vendor_guid_2],
      name: "index_learning_outcome_groups_on_context_and_vendor_guid",
      algorithm: :concurrently
  end
end
