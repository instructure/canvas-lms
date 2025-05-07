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

  def run
    assignment.root_account.shard.activate do
      job_started!
      error_data = process_assessments
      unless error_data.empty?
        update!(error_count: error_data.count, error_data:)
        job_completed_with_errors!
        track_error
        return
      end
      job_completed!
    rescue DataFormatError => e
      ErrorReport.log_exception("rubric_assessments_import_data_format", e)
      update!(error_count: 1, error_data: [{ message: e.message }])
      track_error
      job_failed!
    rescue CSV::MalformedCSVError => e
      ErrorReport.log_exception("rubric_assessments_import_csv", e)
      update!(error_count: 1, error_data: [{ message: I18n.t("The file is not a valid CSV file."), exception: e.message }])
      track_error
    rescue => e
      ErrorReport.log_exception("rubric_assessments_import", e)
      update!(error_count: 1, error_data: [{ message: I18n.t("An error occurred while importing rubrics."), exception: e.message }])
      track_error
      job_failed!
    end
  end

  def track_error
    InstStatsd::Statsd.distributed_increment("#{assignment.class.to_s.downcase}.rubrics.csv_imported_with_error")
  end

  def process_assessments
    error_data = []

    rubric_association = assignment.rubric_association
    rubric = rubric_association.rubric
    assessments_by_student = RubricAssessmentCSVImporter.new(attachment, rubric, rubric_association).parse
    raise DataFormatError, I18n.t("The file is empty or does not contain valid assessment data.") if assessments_by_student.empty?

    total_assessments = assessments_by_student.keys.count

    students = User.where(id: assessments_by_student.keys).index_by(&:id)
    student_submissions = assignment.submissions.where(user_id: students.keys).index_by(&:user_id)

    assessments_by_student.each_with_index do |(student_id, assessment), student_index|
      student_to_assess = students[student_id.to_i]

      raise DataFormatError, I18n.t("Student with ID %{student_id} not found.", student_id:) unless student_to_assess
      raise UnauthorizedError unless rubric_association.user_can_assess_for?(assessor: user, assessee: student_to_assess)

      assessment = assessment.each_with_object({}) do |criterion, hash|
        hash[:"criterion_#{criterion[:id]}"] = {
          points: criterion[:points],
          comments: criterion[:comments],
          description: criterion[:rating]
        }
      end
      assessment[:assessment_type] = "grading"

      rubric_association.assess(
        assessor: user,
        user: student_to_assess,
        artifact: student_submissions[student_id.to_i],
        assessment:,
        graded_anonymously: false,
        get_score_from_rating: !rubric_association.hide_points
      )
      update!(progress: ((student_index + 1) * 100 / total_assessments))
    rescue DataFormatError => e
      error_data << { message: e.message }
    rescue UnauthorizedError => e
      error_data << { message: I18n.t("Student ID %{student_id} unauthorized for assessment", student_id:), exception: e.message }
    rescue ActiveRecord::StatementInvalid => e
      error_data << { message: I18n.t("Student ID %{student_id} could not be assessed", student_id:), exception: e.message }
    end
    error_data
  end
end
