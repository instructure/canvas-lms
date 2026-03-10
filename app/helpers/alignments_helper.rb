# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

module AlignmentsHelper
  include OutcomesServiceAlignmentsHelper

  def link_to_outcome_alignment(context, outcome, alignment = nil)
    html_class = [
      "title"
    ]
    html_class << "icon-#{alignment.content_type.downcase}" if alignment
    link_to(alignment.try(:title) || nbsp, outcome_alignment_url(context, outcome, alignment), {
              class: html_class
            })
  end

  def outcome_alignment_tag(context, outcome, alignment = nil, &)
    options = {
      id: "alignment_#{alignment.try(:id) || "blank"}",
      class: [
        "alignment",
        alignment.try(:content_type_class),
        alignment.try(:graded?) ? "also_assignment" : nil
      ].compact,
      data: {
        id: alignment.try(:id),
        has_rubric_association: alignment.try(:has_rubric_association?),
        url: outcome_alignment_url(
          context, outcome, alignment
        )
      }.compact_blank!
    }
    options[:style] = hidden unless alignment

    content_tag(:li, options, &)
  end

  def outcome_alignment_url(context, outcome, alignment = nil)
    if alignment.present?
      [
        context_prefix(alignment.context_code),
        "outcomes",
        outcome.id,
        "alignments",
        alignment.id
      ].join("/")
    elsif !context.is_a?(Account)
      context_url(
        context,
        :context_outcome_alignment_redirect_url,
        outcome.id,
        "{{ id }}"
      )
    else
      nil
    end
  end

  # Finds all alignments for an outcome (direct, indirect, and external)
  #
  # outcome - The LearningOutcome to find alignments for
  # context - The Course context
  #
  # Returns an array of AlignmentWithMetadata objects representing all alignments
  def find_all_outcome_alignments(outcome, context)
    direct_alignments = find_direct_alignments(outcome, context)
    indirect_alignments = find_indirect_quiz_alignments(outcome, context)
    external_alignments = find_external_quiz_alignments(outcome, context)

    (direct_alignments + indirect_alignments + external_alignments).uniq
  end

  # Finds direct alignments for an outcome
  #
  # outcome - The LearningOutcome to find alignments for
  # context - The Course context
  #
  # Returns an array of AlignmentWithMetadata objects for direct alignments
  def find_direct_alignments(outcome, context)
    outcome.alignments
           .where(context:, content_type: %w[Rubric Assignment AssessmentQuestionBank])
           .preload(:content)
           .map { |tag| ::AlignmentWithMetadata.new(content_tag: tag, alignment_type: ::AlignmentWithMetadata::AlignmentTypes::DIRECT) }
  end

  # Finds Classic Quizzes indirectly aligned to an outcome via question banks
  #
  # outcome - The LearningOutcome to find indirect alignments for
  # context - The Course context
  #
  # Returns an array of AlignmentWithMetadata objects for quiz assignments
  def find_indirect_quiz_alignments(outcome, context)
    # Get question bank alignments
    bank_ids = outcome.alignments
                      .where(context:, content_type: "AssessmentQuestionBank")
                      .pluck(:content_id)

    return [] if bank_ids.empty?

    # Find quizzes that use these question banks
    quiz_ids = AssessmentQuestionBank
               .where(id: bank_ids, context:)
               .joins(:assessment_questions)
               .joins("INNER JOIN #{Quizzes::QuizQuestion.quoted_table_name}
                       ON assessment_questions.id = quiz_questions.assessment_question_id")
               .where.not(assessment_questions: { workflow_state: "deleted" })
               .where.not(quiz_questions: { workflow_state: "deleted" })
               .distinct
               .pluck("quiz_questions.quiz_id")

    return [] if quiz_ids.empty?

    # Get assignments for these quizzes
    Assignment.active
              .where(context:)
              .joins(:quiz)
              .where(quizzes: { id: quiz_ids })
              .map do |assignment|
      ::AlignmentWithMetadata.for_assignment(
        assignment:,
        alignment_type: ::AlignmentWithMetadata::AlignmentTypes::INDIRECT,
        outcome_id: outcome.id,
        context:
      )
    end
  end

  # Finds New Quizzes aligned to an outcome via the Outcome Service
  #
  # outcome - The LearningOutcome to find external alignments for
  # context - The Course context
  #
  # Returns an array of AlignmentWithMetadata objects for New Quiz assignments
  def find_external_quiz_alignments(outcome, context)
    return [] unless context.root_account.feature_enabled?(:outcome_alignment_summary_with_new_quizzes)

    active_os_alignments = get_active_os_alignments(context)
    return [] if active_os_alignments.blank?

    # Get alignments for this specific outcome
    outcome_os_alignments = active_os_alignments[outcome.id.to_s]
    return [] if outcome_os_alignments.blank?

    supported_os_alignments = %w[quizzes.quiz quizzes.item]

    os_aligned_new_quiz_ids = outcome_os_alignments
                              .filter_map do |alignment|
                                alignment[:associated_asset_id].to_i if supported_os_alignments.include?(alignment[:artifact_type]) &&
                                                                        alignment[:associated_asset_type] == "canvas.assignment.quizzes"
                              end
                              .uniq

    return [] if os_aligned_new_quiz_ids.empty?

    Assignment.active
              .where(context:, id: os_aligned_new_quiz_ids)
              .map do |assignment|
      ::AlignmentWithMetadata.for_assignment(
        assignment:,
        alignment_type: ::AlignmentWithMetadata::AlignmentTypes::EXTERNAL,
        outcome_id: outcome.id,
        context:
      )
    end
  end

  # Generates a prefixed alignment ID matching GraphQL OutcomeAlignmentLoader format
  #
  # alignment - The AlignmentWithMetadata representing the alignment
  #
  # Returns a string in the format: "D_<id>", "I_<id>", or "E_<id>"
  # where the prefix indicates:
  #   D = Direct alignment
  #   I = Indirect alignment (via question bank)
  #   E = External alignment (via Outcome Service)
  def alignment_id_for(alignment)
    alignment.prefixed_id
  end
end
