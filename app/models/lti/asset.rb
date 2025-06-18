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

# An Lti::Asset is something an AssetProcessor can create a report for. It is a
# generalization of an attachment. Examples include:
# - an attachment used in a submission
# - (future) RCE content submitted by a student as part of a submission
# - (future) possibly RCE content or attachments used other places, e.g. discussions
class Lti::Asset < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  resolves_root_account through: :submission

  # For now, there is no dependent: destroy from attachment to report,
  # so we should check the assignment is not (soft-)deleted when using
  # the report, if we care in the scenario.

  has_many :asset_reports, class_name: "Lti::AssetReport", inverse_of: :asset, foreign_key: :lti_asset_id

  # In the future, we'll support other types of assets,
  # for instance RCE content stored in a Submission version,
  # and attachment can be made optional
  belongs_to :attachment,
             inverse_of: :lti_assets,
             class_name: "Attachment"

  belongs_to :submission,
             inverse_of: :lti_assets,
             class_name: "Submission",
             optional: false

  validate :attachment_id_or_submission_attempt_present

  before_validation :generate_uuid, on: :create

  def compatible_with_processor?(processor)
    !!submission&.assignment && submission.assignment == processor&.assignment
  end

  # The AP specification requires the SHA256 checksum of the asset in the LtiAssetProcessorSubmissionNotice.
  # Since the underlying storage might not provide this, we must download and calculate it.
  # Run this function in a background job to avoid blocking the request.
  def calculate_sha256_checksum!
    return if sha256_checksum

    timing_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    digester = Digest::SHA256.new
    if text_entry?
      digester << submission.body_for_attempt(submission_attempt)
    else
      attachment.open do |chunk|
        digester << chunk
      end
    end
    digest = digester.base64digest
    timing_end = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    InstStatsd::Statsd.timing("lti.asset_processor_asset_sha256_calculation", timing_end - timing_start)
    InstStatsd::Statsd.gauge("lti.asset_processor_asset_size", content_size)

    update(sha256_checksum: digest)
  end

  def text_entry?
    attachment_id.blank?
  end

  def content_type
    if text_entry?
      "text/html"
    else
      attachment.content_type
    end
  end

  def content_size
    if text_entry?
      submission.body_for_attempt(submission_attempt).bytesize
    else
      attachment.size
    end
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def attachment_id_or_submission_attempt_present
    if attachment_id.present? == submission_attempt.present?
      errors.add(:base, "Exactly one of attachment_id or submission_attempt must be present")
    end
  end
end
