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

class RubricAssessmentExport
  include ActiveModel::Model

  attr_accessor :rubric_association, :user, :options

  delegate :rubric, :context, to: :rubric_association
  delegate :association_object, to: :rubric_association

  def generate_file
    CSV.generate do |csv|
      csv << export_headers
      export_rows.each do |row|
        csv << row
      end
    end
  end

  private

  def export_headers
    headers = [
      "Student Id",
      "Student Name"
    ]

    rubric.criteria_object.each do |criteria|
      headers << "#{criteria.description} - Rating" if rating_visible?
      headers << "#{criteria.description} - Points" if points_visible?
      headers << "#{criteria.description} - Comments"
    end

    headers
  end

  def export_rows
    students.filter_map do |student|
      assessment = assessments[student.id]
      if assessment
        next (add_completed? ? row_with_assessment(student, assessment) : nil)
      end

      next empty_row(student) if add_non_completed?
    end
  end

  def row_with_assessment(student, assessment)
    row = []
    row << student.id
    row << student.name

    ratings = assessment.data.to_h do |r|
      [r[:criterion_id], { rating_id: r[:id] }.merge(r.slice(:comments, :points, :description))]
    end

    rubric.criteria_object.each do |criteria|
      rating = ratings[criteria.id]

      row << (rating&.dig(:description) || "") if rating_visible?
      row << (rating&.dig(:points) || "") if points_visible?
      row << (rating&.dig(:comments) || "")
    end

    row
  end

  def empty_row(student)
    row = []
    row << student.id
    row << student.name

    rubric.rubric_criteria.count.times do
      row << "" if rating_visible?
      row << "" if points_visible?
      row << ""
    end

    row
  end

  def assessments
    @assessments ||= RubricAssessment
                     .where(rubric_association:, user_id: students.pluck(:id))
                     .preload(:rubric_association, :user)
                     .index_by(&:user_id)
  end

  def students
    @students ||= User.where(id: Submission.where(assignment_id: association_object.id).select(:user_id))
  end

  def rating_visible?
    !rubric.free_form_criterion_comments
  end

  def points_visible?
    !rubric_association.hide_points
  end

  def filter
    @filter ||= (options && options[:filter]) || "all"
  end

  def add_completed?
    filter == "completed" || filter == "all"
  end

  def add_non_completed?
    filter == "non-completed" || filter == "all"
  end
end
