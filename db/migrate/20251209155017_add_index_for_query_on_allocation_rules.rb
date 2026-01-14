# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class AddIndexForQueryOnAllocationRules < ActiveRecord::Migration[7.2]
  tag :predeploy
  disable_ddl_transaction!

  def change
    add_index :allocation_rules,
              %i[assignment_id assessor_id must_review review_permitted],
              name: "index_allocation_rules_on_asgnt_assr_must_review_permitted",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
