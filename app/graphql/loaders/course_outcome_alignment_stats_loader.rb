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
  include OutcomesServiceAlignmentsHelper

  SUPPORTED_OS_ALIGNMENTS = %w[quizzes.quiz quizzes.item].freeze

  def perform(courses)
    courses.each do |course|
      unless course_valid?(course) && improved_outcomes_management_enabled?(course)
        fulfill(course, nil) unless fulfilled?(course)
        return
      end

      course_tags = ContentTag.not_deleted.where(context: course)

      total_outcomes = course_tags.learning_outcome_links

      total_outcomes_sub = ContentTag
                           .select("COUNT(*) as total_outcomes")
                           .from("(#{total_outcomes.to_sql}) AS s1")

      all_outcome_alignments = course_tags.learning_outcome_alignments.where(content_type: %w[Rubric Assignment AssessmentQuestionBank])

      all_outcome_alignments_sub = ContentTag
                                   .select("COUNT(*) as total_alignments, COUNT(DISTINCT s2.learning_outcome_id) as aligned_outcomes")
                                   .from("(#{all_outcome_alignments.to_sql}) AS s2")

      total_artifacts = Assignment.active.where(context: course)

      total_artifacts_sub = AbstractAssignment
                            .select("COUNT(*) as total_artifacts")
                            .from("(#{total_artifacts.to_sql}) AS s3")

      outcome_alignments_to_artifacts = course_tags.learning_outcome_alignments.where(content_type: "Assignment")

      outcome_alignments_to_artifacts_sub = ContentTag
                                            .select("COUNT(*) as artifact_alignments, COUNT(DISTINCT s4.content_id) as aligned_artifacts")
                                            .from("(#{outcome_alignments_to_artifacts.to_sql}) AS s4")

      alignment_summary_stats = ContentTag
                                .select("sub1.total_outcomes, sub2.aligned_outcomes, sub2.total_alignments, sub3.total_artifacts, sub4.aligned_artifacts, sub4.artifact_alignments")
                                .from("
                                  (#{total_outcomes_sub.to_sql}) AS sub1,
                                  (#{all_outcome_alignments_sub.to_sql}) AS sub2,
                                  (#{total_artifacts_sub.to_sql}) AS sub3,
                                  (#{outcome_alignments_to_artifacts_sub.to_sql}) AS sub4
                                ")

      indirect_alignments = AssessmentQuestionBank.preload(:assessment_questions).where(id: all_outcome_alignments.where(content_type: "AssessmentQuestionBank").pluck(:content_id))
      @artifacts_with_alignments_ids = Set.new(outcome_alignments_to_artifacts.pluck(:content_id))
      indirect_artifact_alignments_count = indirect_alignments.reduce(0) { |acc, bank| acc + (get_indirect_artifact_alignments(bank, course) * bank.learning_outcome_alignments.count) }

      alignment_summary_stats = alignment_summary_stats[0]
      alignment_summary_stats[:total_alignments] += indirect_artifact_alignments_count
      alignment_summary_stats[:aligned_artifacts] = @artifacts_with_alignments_ids.length
      alignment_summary_stats[:artifact_alignments] += indirect_artifact_alignments_count

      if outcome_alignment_summary_with_new_quizzes_enabled?(course)
        active_os_alignments = get_active_os_alignments(course)

        if active_os_alignments.present?
          all_supported_os_alignments = active_os_alignments
                                        .values
                                        .flatten
                                        .filter { |a| SUPPORTED_OS_ALIGNMENTS.include?(a[:artifact_type]) }

          os_aligned_new_quiz_ids = all_supported_os_alignments
                                    .filter_map { |a| a[:associated_asset_id].to_i if a[:associated_asset_type] == "canvas.assignment.quizzes" }

          canvas_aligned_outcome_ids = Set.new(all_outcome_alignments.pluck(:learning_outcome_id))

          os_aligned_outcome_ids = active_os_alignments.keys.map(&:to_i)

          alignment_summary_stats[:aligned_outcomes] = canvas_aligned_outcome_ids
                                                       .merge(os_aligned_outcome_ids)
                                                       .size
          alignment_summary_stats[:aligned_artifacts] = @artifacts_with_alignments_ids
                                                        .merge(os_aligned_new_quiz_ids)
                                                        .size

          # OS API returns alignments to new quizzes and questions (which belong to a quiz) and since new quizzes are
          # artifacts, the total number of alignments returned by OS API is equal to the number of artifact alignments
          alignment_summary_stats[:total_alignments] += all_supported_os_alignments.size
          alignment_summary_stats[:artifact_alignments] += all_supported_os_alignments.size
        end
      end

      fulfill(course, alignment_summary_stats)
    end
  end

  private

  def course_valid?(course)
    !Course.find(course.id).nil? if course&.id
  end

  def get_indirect_artifact_alignments(bank, context)
    aligned_quiz_ids = Set.new
    bank.assessment_questions.preload(:quiz_questions).reduce(0) do |acc, q|
      quiz_ids, artifact_assignment_ids = Quizzes::Quiz
                                          .active
                                          .where(context:, id: q.quiz_questions.active.pluck(:quiz_id))
                                          .pluck(:id, :assignment_id)
                                          .reduce([[], []]) { |(acc1, acc2), (val1, val2)| [acc1 << val1, acc2 << val2] }
      @artifacts_with_alignments_ids.merge(artifact_assignment_ids)
      quiz_ids.each do |qid|
        unless aligned_quiz_ids.include?(qid)
          acc += 1
          aligned_quiz_ids.add(qid)
        end
      end
      acc
    end
  end
end
