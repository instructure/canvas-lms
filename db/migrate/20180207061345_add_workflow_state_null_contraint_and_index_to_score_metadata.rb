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

class AddWorkflowStateNullContraintAndIndexToScoreMetadata < ActiveRecord::Migration[5.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    # prime the database cache so that the entire table is
    # in memory by using  the index on id
    ScoreMetadata.count
    change_column_null :score_metadata, :workflow_state, false
  end
end
