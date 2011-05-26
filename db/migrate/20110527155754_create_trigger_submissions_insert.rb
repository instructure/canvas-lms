# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class CreateTriggerSubmissionsInsert < ActiveRecord::Migration
  def self.up
    create_trigger("submissions_after_insert_row_tr", :generated => true, :compatibility => 1).
        on("submissions").
        after(:insert) do |t|
      t.where(" NEW.submission_type IS NOT NULL AND ( NEW.score IS NULL OR NOT NEW.grade_matches_current_submission OR NEW.workflow_state IN ('submitted', 'pending_review') ) ") do
        <<-SQL_ACTIONS
      UPDATE assignments
      SET needs_grading_count = needs_grading_count + 1
      WHERE id = NEW.assignment_id;
        SQL_ACTIONS
      end
    end
  end

  def self.down
    drop_trigger("submissions_after_insert_row_tr", "submissions")

    drop_trigger("submissions_after_insert_row_when_new_submission_type_is_not_tr", "submissions")
  end
end
