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
# - RCE content submitted by a student as part of a submission
# - discussion entry (comment) submitted by a student
# - submission_id is always present, except when the submission is deleted. In that case,
#   the submission_id is set to null to not break the foreign key constraint.
# - when attachment id deleted, the asset is soft-deleted. There is no foreign key constraint for attachment,
#   because it can be on a different shard. So the attachment_id remains set, but the attachment may not exist anymore.
#   This helps up to satisfy the asset locator constraint below.
# - asset locator constraint: exactly one of attachment_id, submission_attempt or discussion_entry_version_id must be present
# - if submission_attempt is set, it's RCE content
# - if attachment_id is set, it's a file attachment of a submission
# - if discussion_entry_version_id is set, it's a discussion entry (comment)
# - uuid is generated on creation and never changes
class Lti::Asset < ApplicationRecord
  extend RootAccountResolver
  include Canvas::SoftDeletable

  # Raised when we cannot determine the asset type from the locator columns.
  class UnknownTypeError < StandardError; end

  resolves_root_account through: :submission

  has_many :asset_reports, class_name: "Lti::AssetReport", inverse_of: :asset, foreign_key: :lti_asset_id, dependent: :destroy

  belongs_to :attachment,
             inverse_of: :lti_assets,
             class_name: "Attachment",
             optional: true

  belongs_to :submission,
             inverse_of: :lti_assets,
             class_name: "Submission",
             optional: false

  belongs_to :discussion_entry_version,
             inverse_of: :lti_asset,
             class_name: "DiscussionEntryVersion",
             optional: true

  validate :exactly_one_locator_present

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
    elsif discussion_entry?
      digester << discussion_entry_version.message
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

  def asset_type
    unless submission_id.present?
      # In theory, submissions can be deleted, to not break the foreign key constraint we set the submission_id to null
      # when the submission is hard deleted with dependent: :nullify in the Submission model.
      return "deleted"
    end

    # if submission_attempt is set, it's RCE content
    if submission_attempt.present?
      "text_entry"
    # if attachment_id is set, it's a file attachment of a submission
    elsif attachment_id.present?
      "attachment"
    # if discussion_entry_version_id is set, it's a discussion entry (comment)
    elsif discussion_entry_version_id.present?
      "discussion_entry"
    else
      Rails.logger.error(
        "Lti::Asset unknown type id=#{id}, submission_id=#{submission_id}, attachment_id=#{attachment_id}, submission_attempt=#{submission_attempt}, discussion_entry_version_id=#{discussion_entry_version_id}"
      )
      raise UnknownTypeError, "Unable to determine asset type for Lti::Asset id=#{id}. The referred discussion_entry_version or the submission has been probably deleted."
    end
  end

  def text_entry?
    asset_type == "text_entry"
  end

  def discussion_entry?
    asset_type == "discussion_entry"
  end

  def content_type
    if text_entry? || discussion_entry?
      "text/html"
    else
      attachment.content_type
    end
  end

  def content_size
    if text_entry?
      submission.body_for_attempt(submission_attempt).bytesize
    elsif discussion_entry?
      discussion_entry_version.message.bytesize
    else
      attachment.size
    end
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def exactly_one_locator_present
    present = [attachment_id.present?, submission_attempt.present?, discussion_entry_version_id.present?]
    return if present.count(true) == 1

    errors.add(:base, "Exactly one of attachment_id, submission_attempt or discussion_entry_version_id must be present")
  end
end
