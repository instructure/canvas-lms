# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class Loaders::CourseOutcomeAlignmentStatsLoader < GraphQL::Batch::Loader
  include OutcomesFeaturesHelper

  def perform(courses)
    courses.each do |course|
      unless course_valid?(course) && outcome_alignment_summary_enabled?(course)
        fulfill(course, nil) unless fulfilled?(course)
        return
      end

      course_tags = ContentTag.active.where(context: course)
      outcome_alignments = course_tags.learning_outcome_alignments

      total_outcomes = course_tags.learning_outcome_links.count
      aligned_outcomes = outcome_alignments.pluck(:learning_outcome_id).uniq.count
      total_alignments = outcome_alignments.count

      total_assignments = Assignment.active.where(context: course).count
      total_rubrics = Rubric.active.where(context: course).count

      aligned_assignments = outcome_alignments.where(content_type: "Assignment").pluck(:content_id).uniq.count
      aligned_rubrics = outcome_alignments.where(content_type: "Rubric").pluck(:content_id).uniq.count

      fulfill(course, {
                total_outcomes: total_outcomes,
                aligned_outcomes: aligned_outcomes,
                total_alignments: total_alignments,
                total_artifacts: total_assignments + total_rubrics,
                aligned_artifacts: aligned_assignments + aligned_rubrics
              })
    end
  end

  private

  def course_valid?(course)
    !Course.find(course.id).nil? if course&.id
  end
end
