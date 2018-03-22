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

class AddLatestOutcomeImportToContexts < ActiveRecord::Migration[5.0]
  tag :predeploy

  def change
    add_column :accounts, :latest_outcome_import_id, :integer, limit: 8
    add_foreign_key :accounts, :outcome_imports, column: 'latest_outcome_import_id'
    add_column :courses, :latest_outcome_import_id, :integer, limit: 8
    add_foreign_key :courses, :outcome_imports, column: 'latest_outcome_import_id'
  end
end
