# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

class RenameAssetReportsCheckConstraint < ActiveRecord::Migration[7.1]
  tag :postdeploy

  def rename_check_constraint(table, from:, to:)
    reversible do |dir|
      dir.up do
        execute("ALTER TABLE #{connection.quote_table_name(table)} RENAME CONSTRAINT #{from} TO #{to}")
      end
      dir.down do
        execute("ALTER TABLE #{connection.quote_table_name(table)} RENAME CONSTRAINT #{to} TO #{from}")
      end
    end
  end

  def change
    rename_check_constraint :lti_asset_reports,
                            from: "score_maximum_present_if_score_given_present",
                            to: "chk_score_maximum_present_if_score_given_present"
  end
end
