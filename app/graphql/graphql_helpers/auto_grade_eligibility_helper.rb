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
#

module GraphQLHelpers::AutoGradeEligibilityHelper
  ALLOWED_UPLOAD_MIME_TYPES = [
    "application/pdf",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "application/x-docx"
  ].freeze

  NO_SUBMISSION_MSG       = I18n.t("No essay submission found.")
  IMAGE_UPLOAD_MSG        = I18n.t("There are images embedded in the file that can not be parsed.")
  INVALID_FILE_MSG        = I18n.t("Only PDF and DOCX files are supported.")
  INVALID_TYPE_MSG        = I18n.t("Submission must be a text entry type or file upload.")
  SHORT_ESSAY_MSG         = I18n.t("Submission must be at least 5 words.")
  MISSING_RATING_MSG      = I18n.t("Rubric is missing rating description.")
  FILE_UPLOADS_DISABLED_MSG = I18n.t("Grading assistance is disabled for file uploads.")

  def self.validate_assignment(assignment:)
    assignment_issues = []
    rubric = assignment&.rubric_association&.rubric

    unless CedarClient.enabled?
      assignment_issues << I18n.t("Grading Assistance is not available right now.")
    end

    if rubric.nil?
      assignment_issues << I18n.t("No rubric is attached to this assignment.")
    else
      all_present = rubric.data.all? do |data_entry|
        data_entry[:ratings].all? do |rating|
          rating[:long_description].present?
        end
      end
      unless all_present
        assignment_issues << I18n.t("Rubric is missing rating description.")
      end
    end

    assignment_issues
  end

  def self.no_submission?(submission)
    submission.blank? ||
      submission.attempt.to_i < 1 ||
      (submission.submission_type == "online_text_entry" && submission.body.blank?) ||
      (submission.submission_type == "online_upload" && submission.attachments.none?)
  end

  def self.contains_images?(submission)
    submission.submission_type == "online_upload" && submission.attachment_contains_images
  end

  def self.invalid_file?(submission)
    return false if submission.submission_type != "online_upload"
    return false if submission.attachments.blank?

    submission.attachments.reject { |at| ALLOWED_UPLOAD_MIME_TYPES.include?(at.mimetype) }.any?
  end

  def self.invalid_type?(submission)
    !["online_text_entry", "online_upload"].include?(submission.submission_type)
  end

  def self.short_essay?(submission)
    submission.word_count.nil? || submission.word_count < 5
  end

  def self.file_uploads_feature_disabled?(submission)
    submission.submission_type == "online_upload" &&
      !Account.site_admin.feature_enabled?(:grading_assistance_file_uploads)
  end

  CHECKS = {
    NO_SUBMISSION_MSG => ->(s) { no_submission?(s) },
    INVALID_TYPE_MSG => ->(s) { invalid_type?(s) },
    FILE_UPLOADS_DISABLED_MSG => ->(s) { file_uploads_feature_disabled?(s) },
    INVALID_FILE_MSG => ->(s) { invalid_file?(s) },
    IMAGE_UPLOAD_MSG => ->(s) { contains_images?(s) },
    SHORT_ESSAY_MSG => ->(s) { short_essay?(s) }
  }.freeze

  def self.validate_submission(submission:)
    CHECKS.each do |msg, check|
      return [msg] if check.call(submission)
    end
    []
  end

  def self.contains_rce_file_link?(html_body)
    return false if html_body.blank?

    doc = Nokogiri::HTML.fragment(html_body)
    doc.css("a.instructure_file_link").any? || doc.css("a[data-api-returntype=\"File\"]").any?
  end
end
