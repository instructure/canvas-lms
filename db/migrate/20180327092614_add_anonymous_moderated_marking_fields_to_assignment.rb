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

class AddAnonymousModeratedMarkingFieldsToAssignment < ActiveRecord::Migration[5.1]
  tag :predeploy

  def change
    # Graders cannot view each other's names
    add_column :assignments, :graders_anonymous_to_graders, :boolean
    change_column_default :assignments, :graders_anonymous_to_graders, from: nil, to: false

    # For the "Moderated Grading" checkbox we're reusing the existing field

    # Number of Graders
    add_column :assignments, :grader_count, :integer
    change_column_default :assignments, :grader_count, from: nil, to: 0

    # Graders can view each other's comments
    add_column :assignments, :grader_comments_visible_to_graders, :boolean
    change_column_default :assignments, :grader_comments_visible_to_graders, from: nil, to: false

    # Graders from (section, or "all sections" if not set)
    execute("ALTER TABLE #{Assignment.quoted_table_name} ADD COLUMN grader_section_id bigint CONSTRAINT fk_rails_b035441827 REFERENCES #{CourseSection.quoted_table_name}(id)")
    # Grader that determines final grade
    execute("ALTER TABLE #{Assignment.quoted_table_name} ADD COLUMN final_grader_id bigint CONSTRAINT fk_rails_efc38ac892 REFERENCES #{User.quoted_table_name}(id)")

    # Final grader can view other grader names
    add_column :assignments, :grader_names_visible_to_final_grader, :boolean
    change_column_default :assignments, :grader_names_visible_to_final_grader, from: nil, to: false
  end
end
