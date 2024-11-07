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

class RubricAssessmentImport < ApplicationRecord
  include Workflow
  include RubricImporterErrors
  belongs_to :course
  belongs_to :assignment
  belongs_to :attachment
  belongs_to :root_account, class_name: "Account", inverse_of: :rubric_assessment_imports
  belongs_to :user

  workflow do
    state :initializing
    state :created do
      event :job_started, transitions_to: :importing
    end
    state :importing do
      event :job_completed, transitions_to: :succeeded do
        update!(progress: 100)
      end
      event :job_completed_with_errors, transitions_to: :succeeded_with_errors do
        update!(progress: 100)
      end
      event :job_failed, transitions_to: :failed
    end
    state :succeeded
    state :succeeded_with_errors
    state :failed
  end

  def self.create_with_attachment(assignment, attachment, user = nil)
    import = RubricAssessmentImport.create!(
      root_account: assignment.root_account,
      progress: 0,
      workflow_state: :initializing,
      user:,
      error_count: 0,
      error_data: [],
      assignment:,
      course: assignment.course
    )

    att = Attachment.create_data_attachment(import, attachment, "rubric_assessment_upload_#{import.global_id}.csv")
    import.attachment = att

    yield import if block_given?
    import.workflow_state = :created
    import.save!

    import
  end

  def schedule
    delay(
      n_strand: "RubricAssessmentImport::run::#{course.root_account.global_id}",
      singleton: ["RubricAssessmentImport::run", assignment.global_id, attachment.global_id]
    ).run
  end
end
