# This migration was auto-generated via `rake db:generate_trigger_migration'.
# While you can edit this file, any changes you make to the definitions here
# will be undone by the next auto-generated trigger migration.

class DropTriggerQuizSubmissions < ActiveRecord::Migration[4.2]
  tag :postdeploy

  def up
    drop_trigger("quiz_submissions_after_update_row_when_new_submission_id_is__tr", "quiz_submissions", :generated => true)
  end

  def down
    create_trigger("quiz_submissions_after_update_row_when_new_submission_id_is__tr", :generated => true, :compatibility => 1).
        on("quiz_submissions").
        after(:update).
        where("NEW.submission_id IS NOT NULL AND OLD.workflow_state <> NEW.workflow_state AND NEW.workflow_state = 'complete'") do
      "UPDATE submissions SET workflow_state = 'graded' WHERE id = NEW.submission_id;"
    end
  end
end
