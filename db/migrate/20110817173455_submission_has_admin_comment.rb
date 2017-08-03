#
# Copyright (C) 2011 - present Instructure, Inc.
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

class SubmissionHasAdminComment < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    add_column :submissions, :has_admin_comment, :boolean, :default => false, :null => false
    update <<-SQL
      UPDATE #{Submission.quoted_table_name} SET has_admin_comment=EXISTS(
        SELECT 1 FROM #{SubmissionComment.quoted_table_name} AS sc, #{Assignment.quoted_table_name} AS a, #{Course.quoted_table_name} AS c, #{Enrollment.quoted_table_name} AS e
        WHERE sc.submission_id=submissions.id AND a.id = submissions.assignment_id
          AND submissions.workflow_state <> 'deleted'
          AND c.id = a.context_id AND a.context_type = 'Course' AND e.course_id = c.id
          AND e.user_id = sc.author_id AND e.workflow_state = 'active'
          AND e.type IN ('TeacherEnrollment', 'TaEnrollment'))
    SQL
  end

  def self.down
    remove_column :submissions, :has_admin_comment
  end
end
