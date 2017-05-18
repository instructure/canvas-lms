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

class CreateTriggersEnrollmentsInsertAndEnrollmentsUpdate < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    drop_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", "enrollments")

    drop_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", "enrollments")

    create_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:insert).
        where("NEW.workflow_state = 'active'") do
      {:default=>"    UPDATE assignments SET needs_grading_count = needs_grading_count + 1\n    WHERE context_id = NEW.course_id\n      AND context_type = 'Course'\n      AND EXISTS (\n        SELECT 1\n        FROM submissions\n        WHERE user_id = NEW.user_id\n          AND assignment_id = assignments.id\n          AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) )\n        LIMIT 1\n      )\n      AND NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1);"}
    end

    create_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:update).
        where("NEW.workflow_state <> OLD.workflow_state AND (NEW.workflow_state = 'active' OR OLD.workflow_state = 'active')") do
      {:default=>"    UPDATE assignments SET needs_grading_count = needs_grading_count + CASE WHEN NEW.workflow_state = 'active' THEN 1 ELSE -1 END\n    WHERE context_id = NEW.course_id\n      AND context_type = 'Course'\n      AND EXISTS (\n        SELECT 1\n        FROM submissions\n        WHERE user_id = NEW.user_id\n          AND assignment_id = assignments.id\n          AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) )\n        LIMIT 1\n      )\n      AND NOT EXISTS (SELECT 1 FROM enrollments WHERE workflow_state = 'active' AND user_id = NEW.user_id AND course_id = NEW.course_id AND id <> NEW.id LIMIT 1);"}
    end
  end

  def self.down
    drop_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", "enrollments")

    drop_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", "enrollments")

    create_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:insert).
        where("NEW.workflow_state = 'active'") do
      <<-SQL_ACTIONS
    UPDATE assignments
    SET needs_grading_count = needs_grading_count + 1
    WHERE id IN (SELECT assignment_id
                 FROM submissions
                 WHERE user_id = NEW.user_id
                   AND context_code = 'course_' || NEW.course_id
                   AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) )
                );
      SQL_ACTIONS
    end

    create_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", :generated => true, :compatibility => 1).
        on("enrollments").
        after(:update).
        where("NEW.workflow_state <> OLD.workflow_state AND (NEW.workflow_state = 'active' OR OLD.workflow_state = 'active')") do
      <<-SQL_ACTIONS
    UPDATE assignments
    SET needs_grading_count = needs_grading_count + CASE WHEN NEW.workflow_state = 'active' THEN 1 ELSE -1 END
    WHERE id IN (SELECT assignment_id
                 FROM submissions
                 WHERE user_id = NEW.user_id
                   AND context_code = 'course_' || NEW.course_id
                   AND ( submissions.submission_type IS NOT NULL AND ( submissions.score IS NULL OR NOT submissions.grade_matches_current_submission OR submissions.workflow_state IN ('submitted', 'pending_review') ) )
                );
      SQL_ACTIONS
    end
  end
end
