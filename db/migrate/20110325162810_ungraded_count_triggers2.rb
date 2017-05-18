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

class UngradedCountTriggers2 < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    drop_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", "enrollments", :generated => true)

    drop_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", "enrollments", :generated => true)

    drop_trigger("submissions_after_update_row_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_update_row_when_old_submission_type_is_not_tr", "submissions", :generated => true)

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

    create_trigger("submissions_after_update_row_tr", :generated => true, :compatibility => 1).
        on("submissions").
        after(:update) do |t|
      t.where("( OLD.submission_type IS NOT NULL AND ( OLD.score IS NULL OR NOT OLD.grade_matches_current_submission OR OLD.workflow_state IN ('submitted', 'pending_review') ) ) <> ( NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) )") do
        <<-SQL_ACTIONS
      UPDATE assignments
      SET needs_grading_count = needs_grading_count + CASE WHEN ( NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) ) THEN 1 ELSE -1 END
      WHERE id = NEW.assignment_id;
        SQL_ACTIONS
      end
    end
  end

  def self.down
    drop_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", "enrollments", :generated => true)

    drop_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", "enrollments", :generated => true)

    drop_trigger("submissions_after_update_row_tr", "submissions", :generated => true)

    drop_trigger("submissions_after_update_row_when_old_submission_type_is_not_tr", "submissions", :generated => true)

    create_trigger("enrollments_after_insert_row_when_new_workflow_state_active__tr", :generated => true, :compatibility => 0).
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

    create_trigger("enrollments_after_update_row_when_new_workflow_state_old_wor_tr", :generated => true, :compatibility => 0).
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

    create_trigger("submissions_after_update_row_tr", :generated => true, :compatibility => 0).
        on("submissions").
        after(:update) do |t|
      t.where("( OLD.submission_type IS NOT NULL AND ( OLD.score IS NULL OR NOT OLD.grade_matches_current_submission OR OLD.workflow_state IN ('submitted', 'pending_review') ) ) <> ( NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) )") do
        <<-SQL_ACTIONS
      UPDATE assignments
      SET needs_grading_count = needs_grading_count + CASE WHEN ( NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) ) THEN 1 ELSE -1 END
      WHERE id = NEW.assignment_id;
        SQL_ACTIONS
      end
    end
  end
end
