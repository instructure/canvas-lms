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

class RenameCheckConstraints < ActiveRecord::Migration[7.1]
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
    rename_check_constraint :feature_flags, from: "feature_flags_context_type_check", to: "chk_context_type_enum"
    rename_check_constraint :assignment_overrides, from: "require_association", to: "chk_require_context"
    rename_check_constraint :discussion_topic_summary_feedback, from: "chk_rails_83acfc39f9", to: "chk_liked_disliked_disjunction"
    rename_check_constraint :pseudonyms, from: "check_login_attribute_authentication_provider_id", to: "chk_login_attribute_authentication_provider_id"
    rename_check_constraint :rubrics, from: "check_rating_order", to: "chk_rating_order_enum"
    rename_check_constraint :rubrics, from: "check_button_display", to: "chk_button_display_enum"
    rename_check_constraint :rubric_imports, from: "require_context", to: "chk_require_association"
  end
end
