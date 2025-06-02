# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

# A report created by an Lti::AssetProcessor, under the 1EdTech Asset
# Processor spec.
class Lti::AssetReport < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable
  self.ignored_columns += %i[score_given score_maximum]

  resolves_root_account through: :asset_processor

  # For now, there is no dependent: destroy from asset to report,
  # so we should check the assignment is not (soft-)deleted when using
  # the report, if we care in the scenario.
  belongs_to :asset,
             inverse_of: :asset_reports,
             class_name: "Lti::Asset",
             foreign_key: :lti_asset_id,
             optional: false

  belongs_to :asset_processor,
             inverse_of: :asset_reports,
             class_name: "Lti::AssetProcessor",
             foreign_key: :lti_asset_processor_id,
             optional: false

  PROGRESSES = [
    PROGRESS_PROCESSED = "Processed",
    PROGRESS_PROCESSING = "Processing",
    PROGRESS_PENDING = "Pending",
    PROGRESS_PENDING_MANUAL = "PendingManual",
    PROGRESS_FAILED = "Failed",
    PROGRESS_NOT_PROCESSED = "NotProcessed",
    PROGRESS_NOT_READY = "NotReady"
  ].freeze

  STANDARD_ERROR_CODES = [
    ERROR_CODE_UNSUPPORTED_ASSET_TYPE = "UNSUPPORTED_ASSET_TYPE",
    ERROR_CODE_ASSET_TOO_LARGE = "ASSET_TOO_LARGE",
    ERROR_CODE_ASSET_TOO_SMALL = "ASSET_TOO_SMALL",
    ERROR_CODE_EULA_NOT_ACCEPTED = "EULA_NOT_ACCEPTED",
    ERROR_CODE_DOWNLOAD_FAILED = "DOWNLOAD_FAILED"
  ].freeze

  PRIORITIES = [
    PRIORITY_GOOD = 0,
    PRIORITY_NOT_TIME_CRITICAL = 1,
    PRIORITY_PARTIALLY_TIME_CRITICAL = 2,
    PRIORITY_SEMI_TIME_CRITICAL = 3,
    PRIORITY_MOSTLY_TIME_CRITICAL = 4,
    PRIORITY_TIME_CRITICAL = 5
  ].freeze

  before_validation :filter_non_namespaced_extension_keys

  validates :timestamp, presence: true
  # report_type is "type" from the 1EdTech spec (Rails prevents us from naming column 'type')
  validates :report_type,
            presence: true,
            length: { maximum: 1024 },
            uniqueness: {
              scope: %i[lti_asset_id lti_asset_processor_id],
              conditions: -> { active },
            },
            if: -> { !deleted? }
  validates :title, length: { minimum: 1, maximum: 1.kilobyte }, allow_nil: true
  validates :result, length: { maximum: 255 }, allow_nil: true
  validates :comment, length: { minimum: 1, maximum: 64.kilobytes }, allow_nil: true
  # For now, spec implies must be a hex code if present
  validates :indication_color,
            format: { with: /\A#[0-9a-fA-F]{6}\z/, message: I18n.t("Indication color must be a valid hex code") },
            allow_nil: true
  validates :indication_alt, length: { minimum: 1, maximum: 1024 }, allow_nil: true
  validates :error_code, length: { minimum: 1, maximum: 1024 }, allow_nil: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :processing_progress, presence: true
  validates :visible_to_owner, inclusion: { in: [true, false] }

  validate :validate_extensions
  validate :validate_asset_compatible_with_processor

  scope :for_active_processors, lambda {
    joins(:asset_processor)
      .where(lti_asset_processors: { workflow_state: :active })
  }

  scope :for_submissions, lambda { |submission_ids|
    joins(:asset)
      .where(lti_assets: { submission_id: submission_ids })
  }

  def validate_asset_compatible_with_processor
    unless asset&.compatible_with_processor?(asset_processor)
      errors.add(:asset, "internal error, asset (e.g. asset's submission) not compatible with processor")
    end
  end

  def filter_non_namespaced_extension_keys
    return if extensions.blank?

    self.extensions = extensions.select do |key, _value|
      key.is_a?(String) && key.start_with?("http://", "https://")
    end
  end

  MAX_EXTENSIONS_SIZE = 1.megabyte

  def validate_extensions
    return if extensions.nil?

    # rough size limit just to keep things reasonable
    if extensions.inspect.length > MAX_EXTENSIONS_SIZE
      errors.add(:extensions, "size limit exceeded")
    end
  end

  # See also fields in graphql/types/lti_asset_report_type.rb (used
  # in New Speedgrader)
  def info_for_display
    {
      _id: id,
      title:,
      comment:,
      result:,
      resultTruncated: result_truncated,
      indicationColor: indication_color,
      indicationAlt: indication_alt,
      errorCode: error_code,
      processingProgress: effective_processing_progress,
      priority:,
      launchUrlPath: launch_url_path,
      resubmitAvailable: resubmit_available?,
    }.compact
  end

  def effective_processing_progress
    if PROGRESSES.include?(processing_progress)
      processing_progress
    else
      # Per spec
      PROGRESS_NOT_READY
    end
  end

  def launch_url_path
    return nil unless processing_progress == PROGRESS_PROCESSED

    Rails.application.routes.url_helpers.asset_report_launch_path(
      asset_processor_id: lti_asset_processor_id,
      report_id: id
    )
  end

  def resubmit_available?
    processing_progress == PROGRESS_PENDING_MANUAL ||
      (processing_progress == PROGRESS_FAILED && [ERROR_CODE_EULA_NOT_ACCEPTED, ERROR_CODE_DOWNLOAD_FAILED].include?(error_code))
  end

  def result_truncated
    return nil unless result.is_a?(String) && result.present?
    return nil if result.length <= 16

    "#{result.first(15)}…"
  end

  def visible_to_user?(user)
    (visible_to_owner && asset.submission.user_id == user.id) ||
      asset.submission.assignment.context.grants_any_right?(user, :manage_grades, :view_all_grades)
  end

  # Returns all reports for the given asset processor and submission IDs.
  # Returns reports by submission, hash of form:
  #   submission_id => {
  #     by_attachment: {
  #       attachment_id => {
  #         lti_asset_processor_id => [
  #           { id: report1.id, title: report1.title, ... },
  #           { id: report2.id, title: report2.title, ... },
  #         ],
  # ...
  def self.info_for_display_by_submission(submission_ids:, for_student: false)
    reports_by_submission = {}

    if submission_ids.present?
      scope =
        active
        .for_active_processors
        .for_submissions(submission_ids)
        .select("lti_asset_reports.*, lti_assets.submission_id as asset_sub_id, lti_assets.attachment_id as asset_att_id")

      scope = scope.where(visible_to_owner: true) if for_student

      scope.find_each do |report|
        sub_reports = (reports_by_submission[report.asset_sub_id] ||= {})

        if report.asset_att_id
          by_attachment = (sub_reports[:by_attachment] ||= {})
          by_processor = (by_attachment[report.asset_att_id] ||= {})
          report_list = (by_processor[report.lti_asset_processor_id] ||= [])
          report_list << report.info_for_display
        end
        # else if submission version (RCE content) -- TODO
      end
    end

    reports_by_submission
  end
end
