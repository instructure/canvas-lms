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

# rubocop:disable Migration/Predeploy

class AddGinIndexToPseudonymsIntegrationId < ActiveRecord::Migration[8.0]
  tag :postdeploy
  disable_ddl_transaction!

  def up
    if (trgm = connection.extension(:pg_trgm)&.schema)
      add_index :pseudonyms,
                "lower(integration_id) #{trgm}.gin_trgm_ops",
                name: "index_gin_trgm_pseudonyms_integration_id",
                using: :gin,
                algorithm: :concurrently,
                if_not_exists: true
    end
  end

  def down
    remove_index :pseudonyms,
                 name: "index_gin_trgm_pseudonyms_integration_id",
                 if_exists: true,
                 algorithm: :concurrently
  end
end

# rubocop:enable Migration/Predeploy
