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

class RubricImport < ApplicationRecord
  include Workflow
  include RubricImporterErrors
  belongs_to :account, optional: true
  belongs_to :course, optional: true
  belongs_to :attachment
  belongs_to :root_account, class_name: "Account", inverse_of: :rubric_imports
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

  def context
    account || course
  end

  def context=(val)
    case val
    when Account
      self.account = val
    when Course
      self.course = val
    end
  end

  def self.create_with_attachment(rubric_context, attachment, user = nil)
    import = RubricImport.create!(
      root_account: rubric_context.root_account,
      progress: 0,
      workflow_state: :initializing,
      user:,
      error_count: 0,
      error_data: [],
      context: rubric_context
    )

    att = Attachment.create_data_attachment(import, attachment, "rubric_upload_#{import.global_id}.csv")
    import.attachment = att

    yield import if block_given?
    import.workflow_state = :created
    import.save!

    import
  end

  def schedule
    delay(strand: "RubricImport::run::#{context.root_account.global_id}").run
  end

  def run
    context.root_account.shard.activate do
      job_started!
      error_data = process_rubrics
      unless error_data.empty?
        update!(error_count: error_data.count, error_data:)
        job_completed_with_errors!
        track_error
        return
      end
      job_completed!
    rescue DataFormatError => e
      ErrorReport.log_exception("rubrics_import_data_format", e)
      update!(error_count: 1, error_data: [{ message: e.message }])
      track_error
      job_failed!
    rescue CSV::MalformedCSVError => e
      ErrorReport.log_exception("rubrics_import_csv", e)
      update!(error_count: 1, error_data: [{ message: I18n.t("The file is not a valid CSV file."), exception: e.message }])
      track_error
    rescue => e
      ErrorReport.log_exception("rubrics_import", e)
      update!(error_count: 1, error_data: [{ message: I18n.t("An error occurred while importing rubrics."), exception: e.message }])
      track_error
      job_failed!
    end
  end

  def process_rubrics
    rubrics_by_name = RubricCSVImporter.new(attachment).parse
    raise DataFormatError, I18n.t("The file is empty or does not contain valid rubric data.") if rubrics_by_name.empty?

    total_rubrics = rubrics_by_name.keys.count
    error_data = []

    rubrics_by_name.each_with_index do |(rubric_name, rubric_data), rubric_index|
      raise DataFormatError, I18n.t("Missing 'Rubric Name' in some rows.") if rubric_name.blank?

      rubric = context.rubrics.build(rubric_imports_id: id)
      criteria_hash = {}
      rubric_data.each_with_index do |criterion, criterion_index|
        raise DataFormatError, "Missing 'Criteria Name' for #{rubric_name}" if criterion[:description].blank?
        raise DataFormatError, "Missing ratings for #{criterion[:description]}" if criterion[:ratings].empty?

        ratings_hash = {}
        criterion[:ratings].each_with_index do |rating, rating_index|
          ratings_hash[rating_index.to_s] = {
            "description" => rating[:description],
            "long_description" => rating[:long_description],
            "points" => rating[:points]
          }
        end
        criteria_hash[criterion_index.to_s] = {
          "description" => criterion[:description],
          "long_description" => criterion[:long_description],
          "ratings" => ratings_hash
        }
        if context.root_account.feature_enabled?(:rubric_criterion_range)
          criteria_hash[criterion_index.to_s]["criterion_use_range"] = criterion[:criterion_use_range]
        end
      end
      rubric_params = {
        title: rubric_name,
        criteria: criteria_hash.with_indifferent_access,
        workflow_state: "draft"
      }
      association_params = { association_object: context }
      rubric.update_with_association(user, rubric_params, context, association_params)
      update!(progress: ((rubric_index + 1) * 100 / total_rubrics))
    rescue DataFormatError => e
      error_data << { message: e.message }
    rescue ActiveRecord::StatementInvalid => e
      error_data << { message: I18n.t("The rubric '%{rubric_name}' could not be saved.", rubric_name:), exception: e.message }
    end
    error_data
  end

  def self.find_latest_rubric_import(context)
    if context.is_a?(Account)
      RubricImport.where(account: context).last
    else
      RubricImport.where(course: context).last
    end
  end

  def self.find_specific_rubric_import(context, id)
    if context.is_a?(Account)
      RubricImport.find_by(account: context, id:)
    else
      RubricImport.find_by(course: context, id:)
    end
  end

  def self.template_file
    column_headers = [
      "Rubric Name",
      "Criteria Name",
      "Criteria Description",
      "Criteria Enable Range",
      "Rating Name",
      "Rating Description",
      "Rating Points",
      "Rating Name",
      "Rating Description",
      "Rating Points",
      "Rating Name",
      "Rating Description",
      "Rating Points"
    ]

    rubric_data = [
      ["Rubric 1", "Criteria 1", "Criteria 1 Description", "false", "Rating 1", "Rating 1 Description", "2", "Rating 2", "Rating 2 Description", "1", "Rating 3", "Rating 3 Description", "0"],
      ["Rubric 1", "Criteria 2", "Criteria 2 Description", "false", "Criteria 2 Rating 1", "Rating Description", "1", "Criteria 2 Rating 2", "Rating 2 Description", "1"],
    ]

    CSV.generate do |csv|
      csv << column_headers
      rubric_data.each do |rubric|
        csv << rubric
      end
    end
  end

  def track_error
    InstStatsd::Statsd.distributed_increment("#{context.class.to_s.downcase}.rubrics.csv_imported_with_error")
  end
end
