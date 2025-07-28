# frozen_string_literal: true

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

class GuardAgainstUntransformedToolConfigurations < ActiveRecord::Migration[7.1]
  tag :postdeploy

  def up
    # rubocop:disable Rails/WhereNot
    # `settings` was moved to ignored_columns in this commit, so this does need a raw SQL query
    if Lti::ToolConfiguration.where("settings != ?", "{}").exists?
      message = <<~TEXT
        ** WARNING: DATA LOSS POSSIBLE **

        You have Lti::ToolConfigurations that have not been transformed to the new
        format which will suffer data loss if migrations continue. LTI 1.3 tool JSON
        config has been moved from the `settings` column to be stored in all other
        columns on the `lti_tool_configurations` table.

        To remedy this:
        Please first check out any version of Canvas older than Jan 1, 2025 (the stable/2024-12-18 branch,
        or commit 37178bb68d74e5a454f9f956e2380a9953104d2b), and run migrations from there or
        the DataFixup::Lti::TransformToolConfigurations data fixup, then return to the
        latest version of Canvas.

        Failing to do so before continuing with migrations will drop all data in the
        `settings` column of all Lti::ToolConfigurations.

      TEXT
      raise message
    end
    # rubocop:enable Rails/WhereNot
  end
end
