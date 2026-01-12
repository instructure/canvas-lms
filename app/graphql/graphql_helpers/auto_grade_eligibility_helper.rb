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

  MAX_ASSIGNMENT_DESCRIPTION_LENGTH = 13_500
  MAX_ESSAY_LENGTH = 13_500
  MAX_RUBRIC_CRITERION_DESCRIPTION_LENGTH = 1_000
  MAX_RUBRIC_CATEGORY_NAME_LENGTH = 1_000

  NO_SUBMISSION_MSG               = -> { I18n.t("No essay submission found.") }
  IMAGE_UPLOAD_MSG                = -> { I18n.t("Please note that AI Grading Assistance for this submission will ignore any embedded images and only evaluate the text portion of the submission.") }
  INVALID_FILE_MSG                = -> { I18n.t("Only PDF and DOCX files are supported.") }
  INVALID_TYPE_MSG                = -> { I18n.t("Submission must be a text entry type or file upload.") }
  SHORT_ESSAY_MSG                 = -> { I18n.t("Submission must be at least 5 words.") }
  MISSING_RATING_MSG              = -> { I18n.t("Rubric is missing rating description.") }
  FILE_UPLOADS_DISABLED_MSG       = -> { I18n.t("Grading assistance is disabled for file uploads.") }
  GRADING_ASSISTANCE_DISABLED_MSG = -> { I18n.t("Grading assistance is not available right now.") }
  NO_RUBRIC_MSG                   = -> { I18n.t("No rubric is attached to this assignment.") }
  RATING_DESCRIPTION_MISSING_MSG  = -> { I18n.t("Rubric is missing rating description.") }
  ASSIGNMENT_DESCRIPTION_TOO_LONG_MSG = -> { I18n.t("Assignment description exceeds maximum length of %{max} characters.", max: MAX_ASSIGNMENT_DESCRIPTION_LENGTH) }
  RUBRIC_CATEGORY_NAME_TOO_LONG_MSG = -> { I18n.t("Rubric category name exceeds maximum length of %{max} characters.", max: MAX_RUBRIC_CATEGORY_NAME_LENGTH) }
  RUBRIC_CRITERION_DESCRIPTION_TOO_LONG_MSG = -> { I18n.t("Rubric criterion description exceeds maximum length of %{max} characters.", max: MAX_RUBRIC_CRITERION_DESCRIPTION_LENGTH) }
  ESSAY_TOO_LONG_MSG = -> { I18n.t("Submission text exceeds maximum length of %{max} characters.", max: MAX_ESSAY_LENGTH) }

  def self.missing_rubric?(assignment)
    assignment&.rubric.nil?
  end

  def self.rubric_missing_ratings?(assignment)
    rubric = assignment&.rubric
    return false unless rubric

    rubric.data.any? do |data_entry|
      data_entry[:ratings].any? { |rating| rating[:long_description].blank? }
    end
  end

  def self.grading_assistance_disabled?
    !CedarClient.enabled?
  end

  def self.assignment_description_too_long?(assignment)
    return false if assignment&.description.blank?

    assignment.description.length > MAX_ASSIGNMENT_DESCRIPTION_LENGTH
  end

  def self.rubric_category_name_too_long?(assignment)
    rubric = assignment&.rubric
    return false unless rubric

    rubric.data.any? do |criterion|
      criterion[:description].to_s.length > MAX_RUBRIC_CATEGORY_NAME_LENGTH
    end
  end

  def self.rubric_criterion_description_too_long?(assignment)
    rubric = assignment&.rubric
    return false unless rubric

    rubric.data.any? do |criterion|
      criterion[:ratings]&.any? { |rating| rating[:long_description].to_s.length > MAX_RUBRIC_CRITERION_DESCRIPTION_LENGTH }
    end
  end

  ASSIGNMENT_CHECKS = [
    { level: "error", message: GRADING_ASSISTANCE_DISABLED_MSG,                 check: ->(_) { grading_assistance_disabled? } },
    { level: "error", message: NO_RUBRIC_MSG,                                   check: ->(a) { missing_rubric?(a) } },
    { level: "error", message: RATING_DESCRIPTION_MISSING_MSG,                  check: ->(a) { rubric_missing_ratings?(a) } },
    { level: "error", message: ASSIGNMENT_DESCRIPTION_TOO_LONG_MSG,             check: ->(a) { assignment_description_too_long?(a) } },
    { level: "error", message: RUBRIC_CATEGORY_NAME_TOO_LONG_MSG,               check: ->(a) { rubric_category_name_too_long?(a) } },
    { level: "error", message: RUBRIC_CRITERION_DESCRIPTION_TOO_LONG_MSG,       check: ->(a) { rubric_criterion_description_too_long?(a) } }
  ].freeze

  def self.validate_assignment(assignment:)
    ASSIGNMENT_CHECKS.each do |entry|
      if entry[:check].call(assignment)
        return { level: entry[:level], message: entry[:message].call }
      end
    end
    nil
  end

  def self.no_submission?(submission)
    submission.blank? ||
      submission.attempt.to_i < 1 ||
      (submission.submission_type == "online_text_entry" && submission.body.blank?) ||
      (submission.submission_type == "online_upload" && submission.attachments.none?)
  end

  def self.contains_images?(submission)
    extracted_text = submission.read_extracted_text
    extracted_text.fetch(:contains_images, false)
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

  def self.essay_too_long?(submission)
    return false if submission.blank?

    text = AutoGradeOrchestrationService.extract_essay_text(submission)
    text.length > MAX_ESSAY_LENGTH
  end

  SUBMISSION_CHECKS = [
    { level: "error", message: NO_SUBMISSION_MSG,          check: ->(s) { no_submission?(s) } },
    { level: "error", message: INVALID_TYPE_MSG,           check: ->(s) { invalid_type?(s) } },
    { level: "error", message: FILE_UPLOADS_DISABLED_MSG,  check: ->(s) { file_uploads_feature_disabled?(s) } },
    { level: "error", message: INVALID_FILE_MSG,           check: ->(s) { invalid_file?(s) } },
    { level: "warning", message: IMAGE_UPLOAD_MSG,         check: ->(s) { contains_images?(s) } },
    { level: "error", message: SHORT_ESSAY_MSG,            check: ->(s) { short_essay?(s) } },
    { level: "error", message: ESSAY_TOO_LONG_MSG,         check: ->(s) { essay_too_long?(s) } }
  ].freeze

  def self.validate_submission(submission:)
    SUBMISSION_CHECKS.each do |entry|
      if entry[:check].call(submission)
        return { level: entry[:level], message: entry[:message].call }
      end
    end
    nil
  end
end
