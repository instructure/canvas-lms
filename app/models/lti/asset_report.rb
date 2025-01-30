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

class Lti::AssetReport < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

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
  validates :comment, length: { minimum: 1, maximum: 64.kilobytes }, allow_nil: true
  validates :score_given, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :score_maximum, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :score_maximum,
            presence: { message: I18n.t("must be present if score_given is present") },
            if: -> { score_given.present? }
  # For now, spec implies must be a hex code if present
  validates :indication_color,
            format: { with: /\A#[0-9a-fA-F]{6}\z/, message: I18n.t("Indication color must be a valid hex code") },
            allow_nil: true
  validates :indication_alt, length: { minimum: 1, maximum: 1024 }, allow_nil: true
  validates :error_code, length: { minimum: 1, maximum: 1024 }, allow_nil: true
  validates :priority, inclusion: { in: PRIORITIES }

  validate :validate_extensions
  validate :validate_asset_compatible_with_processor
  before_save :set_default_processing_progress_if_unrecognized

  def validate_asset_compatible_with_processor
    unless asset&.compatible_with_processor?(asset_processor)
      errors.add(:asset, "internal error, asset (e.g. asset's submission) not compatible with processor")
    end
  end

  MAX_EXTENSIONS_SIZE = 1.megabyte

  def validate_extensions
    return if extensions.nil?

    # rough size limit just to keep things reasonable
    if extensions.inspect.length > MAX_EXTENSIONS_SIZE
      errors.add(:extensions, "size limit exceeded")
    end

    bad_extensions = extensions.keys.reject { |k| k.start_with?("http://", "https://") }
    if bad_extensions.present?
      errors.add(:extensions, "unrecognized fields #{bad_extensions.to_json} -- extensions property keys must be namespaced (URIs)")
    end
  end

  def set_default_processing_progress_if_unrecognized
    # Per spec.
    self.processing_progress = PROGRESS_NOT_READY unless PROGRESSES.include?(processing_progress)
  end
end
