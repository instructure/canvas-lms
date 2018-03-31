#
# Copyright (C) 2018 - present Instructure, Inc.
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

class AddImportIdToOutcomesAndOutcomeGroups < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    add_column :learning_outcomes, :outcome_import_id, :integer, limit: 8
    add_column :learning_outcome_groups, :outcome_import_id, :integer, limit: 8
  end
end
