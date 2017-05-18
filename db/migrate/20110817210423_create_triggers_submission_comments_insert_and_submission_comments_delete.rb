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

# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggersSubmissionCommentsInsertAndSubmissionCommentsDelete < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_trigger("submission_comments_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("submission_comments").
        after(:insert) do
      <<-SQL_ACTIONS
    UPDATE submissions
    SET has_admin_comment=EXISTS(
      SELECT 1 FROM submission_comments AS sc, assignments AS a, courses AS c, enrollments AS e
      WHERE sc.submission_id = submissions.id AND a.id = submissions.assignment_id
        AND c.id = a.context_id AND a.context_type = 'Course' AND e.course_id = c.id
        AND e.user_id = sc.author_id AND e.workflow_state = 'active'
        AND e.type IN ('TeacherEnrollment', 'TaEnrollment'))
    WHERE id = NEW.submission_id;
      SQL_ACTIONS
    end

    create_trigger("submission_comments_after_delete_row_tr", :generated => true, :compatibility => 1).
        on("submission_comments").
        after(:delete) do
      <<-SQL_ACTIONS
    UPDATE submissions
    SET has_admin_comment=EXISTS(
      SELECT 1 FROM submission_comments AS sc, assignments AS a, courses AS c, enrollments AS e
      WHERE sc.submission_id = submissions.id AND a.id = submissions.assignment_id
        AND c.id = a.context_id AND a.context_type = 'Course' AND e.course_id = c.id
        AND e.user_id = sc.author_id AND e.workflow_state = 'active'
        AND e.type IN ('TeacherEnrollment', 'TaEnrollment'))
    WHERE id = OLD.submission_id;
      SQL_ACTIONS
    end
  end

  def self.down
    drop_trigger("submission_comments_after_insert_row_tr", "submission_comments")

    drop_trigger("submission_comments_after_delete_row_tr", "submission_comments")
  end
end
