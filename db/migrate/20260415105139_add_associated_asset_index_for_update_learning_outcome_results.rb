# frozen_string_literal: true

# Copyright (C) 2026 - present Instructure, Inc.
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

class AddAssociatedAssetIndexForUpdateLearningOutcomeResults < ActiveRecord::Migration[8.0]
  tag :postdeploy
  disable_ddl_transaction!

  def change
    add_index :learning_outcome_results, # rubocop:disable Migration/Predeploy -- this index is not needed for a new feature. it's an optimization for existing queries on a large table, hence postdeploy.
              %i[associated_asset_id associated_asset_type],
              where: "associated_asset_id IS NOT NULL",
              name: "lor_associated_asset_idx",
              algorithm: :concurrently,
              if_not_exists: true
  end
end
