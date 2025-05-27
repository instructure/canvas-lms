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

  def self.validate_submission(submission:)
    submission_issues = []

    if submission.submission_type != "online_text_entry"
      submission_issues << I18n.t("Submission must be a text entry type.")
    elsif submission.blank? || submission.body.blank? || submission.attempt < 1 || (word_count = submission.word_count).nil?
      submission_issues << I18n.t("No essay submission found.")
    elsif word_count < 5
      submission_issues << I18n.t("Submission must be at least 5 words.")
    end

    unless submission.attachments.empty?
      submission_issues << I18n.t("Submission contains file attachments.")
    end

    submission_issues
  end

  def self.contains_rce_file_link?(html_body)
    return false if html_body.blank?

    doc = Nokogiri::HTML.fragment(html_body)
    doc.css("a.instructure_file_link").any? || doc.css("a[data-api-returntype=\"File\"]").any?
  end
end
