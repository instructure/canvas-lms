# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

module ImprovedOutcomeReportsSpecHelpers
  def verify_all(report, all_values)
    expect(report.length).to eq all_values.length
    report.each.with_index { |row, i| verify(row, all_values[i], row_index: i) }
  end

  def verify(row, values, row_index: nil)
    user, assignment, outcome, outcome_group, outcome_result, course, section, submission, quiz, question, quiz_outcome_result, quiz_submission, pseudonym =
      values.values_at(:user,
                       :assignment,
                       :outcome,
                       :outcome_group,
                       :outcome_result,
                       :course,
                       :section,
                       :submission,
                       :quiz,
                       :question,
                       :quiz_outcome_result,
                       :quiz_submission,
                       :pseudonym)
    result = quiz.nil? ? outcome_result : quiz_outcome_result
    rating = if outcome.present? && result&.score.present?
               outcome.rubric_criterion&.[](:ratings)&.select do |r|
                 score = if quiz.nil?
                           result.score
                         else
                           result.percent * outcome.points_possible
                         end
                 r[:points].present? && r[:points] <= score
               end&.first
             end
    rating ||= {}

    hide_points = outcome_result&.hide_points
    hide = ->(v) { hide_points ? nil : v }

    expectations = {
      "student name" => user.sortable_name,
      "student id" => user.id,
      "student sis id" => pseudonym&.sis_user_id || user.pseudonym.sis_user_id,
      "assignment title" => assignment&.title,
      "assignment id" => assignment&.id,
      "assignment url" => "https://#{HostUrl.context_host(course)}/courses/#{course.id}/assignments/#{assignment.id}",
      "course id" => course&.id,
      "course name" => course&.name,
      "course sis id" => course&.sis_source_id,
      "section id" => section&.id,
      "section name" => section&.name,
      "section sis id" => section&.sis_source_id,
      "submission date" => quiz_submission&.finished_at&.iso8601 || submission&.submitted_at&.iso8601,
      "submission score" => quiz_submission&.score || submission&.grade&.to_f,
      "learning outcome group title" => outcome_group&.title,
      "learning outcome group id" => outcome_group&.id,
      "learning outcome name" => outcome&.short_description,
      "learning outcome friendly name" => outcome&.display_name,
      "learning outcome id" => outcome&.id,
      "learning outcome mastery score" => hide.call(outcome&.mastery_points),
      "learning outcome points possible" => hide.call(outcome_result&.possible),
      "learning outcome mastered" => unless outcome_result&.mastery.nil?
                                       outcome_result.mastery? ? 1 : 0
                                     end,
      "learning outcome rating" => rating[:description],
      "learning outcome rating points" => hide.call(rating[:points]),
      "attempt" => outcome_result&.attempt,
      "outcome score" => hide.call(outcome_result&.score),
      "account id" => course&.account&.id,
      "account name" => course&.account&.name,
      "assessment title" => quiz&.title || assignment&.title,
      "assessment id" => quiz&.id || assignment&.id,
      "assessment type" => quiz.nil? ? "assignment" : "quiz",
      "assessment question" => question&.name,
      "assessment question id" => question&.id,
      "enrollment state" => user&.enrollments&.find_by(course:, course_section: section)&.workflow_state
    }
    expect(row.headers).to eq row.headers & expectations.keys
    row.headers.each do |key|
      expect(row[key].to_s).to eq(expectations[key].to_s),
                               (row_index.present? ? "for row #{row_index}, " : "") +
                               "for column '#{key}': expected '#{expectations[key]}', received '#{row[key]}'"
    end
  end
end
