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

class CreateTriggerQuizSubmissionsUpdate < ActiveRecord::Migration[4.2]
  tag :predeploy

  def self.up
    create_trigger("quiz_submissions_after_update_row_when_new_submission_id_is__tr", :generated => true, :compatibility => 1).
        on("quiz_submissions").
        after(:update).
        where("NEW.submission_id IS NOT NULL AND OLD.workflow_state <> NEW.workflow_state AND NEW.workflow_state = 'complete'") do
      "UPDATE submissions SET workflow_state = 'graded' WHERE id = NEW.submission_id;"
    end
  end

  def self.down
    drop_trigger("quiz_submissions_after_update_row_when_new_submission_id_is__tr", "quiz_submissions")
  end
end
