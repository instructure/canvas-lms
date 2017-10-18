#
# Copyright (C) 2017 - present Instructure, Inc.
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
#
class MarkAssignmentAnonymousInstructorAnnotationsNotNullable < ActiveRecord::Migration[5.0]
  tag :postdeploy

  def up
    # In case we missed something in 20170824064214_backfill_assignment_anonymous_instructor_annotations.rb
    DataFixup::BackfillNulls.run(Assignment, :anonymous_instructor_annotations, default_value: false)

    change_column_null :assignments, :anonymous_instructor_annotations, false
  end

  def down
    change_column_null :assignments, :anonymous_instructor_annotations, true
  end
end
