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

class Loaders::OutcomeAlignmentLoader < GraphQL::Batch::Loader
  include OutcomesFeaturesHelper
  include OutcomesServiceAlignmentsHelper
  SUPPORTED_OS_ALIGNMENTS = %w[quizzes.quiz quizzes.item].freeze

  def initialize(context)
    super()
    @context = context
  end

  def perform(outcomes)
    if @context.nil? || !improved_outcomes_management_enabled?(@context)
      fulfill_nil(outcomes)
      return
    end

    active_os_alignments = outcome_alignment_summary_with_new_quizzes_enabled?(@context) ? get_active_os_alignments(@context) : {}

    outcomes.each do |outcome|
      all_fields = %w[id alignment_type content_id content_type context_id context_type title learning_outcome_id created_at updated_at assignment_id assignment_submission_types assignment_workflow_state discussion_id quiz_id module_id module_name module_workflow_state]
      # direct outcome alignments to rubric, assignment, quiz, and graded discussions
      # map assignment id to quiz/discussion id
      assignments_sub = Assignment
                        .active
                        .select("assignments.id as assignment_id, assignments.submission_types as assignment_submission_types, assignments.workflow_state as assignment_workflow_state, discussion_topics.id as discussion_id, quizzes.id as quiz_id")
                        .where(context: @context)
                        .left_joins(:discussion_topic)
                        .left_joins(:quiz)

      # map assignment id to module id
      modules_sub = ContextModule
                    .not_deleted
                    .select("context_modules.id as module_id, context_modules.name as module_name, context_modules.workflow_state as module_workflow_state, content_tags.content_id as assignment_content_id, content_tags.content_type as assignment_content_type")
                    .where(context: @context)
                    .left_joins(:content_tags)
                    .where.not(content_tags: { workflow_state: "deleted" })

      # map alignment id to assignment/quiz/discussion ids
      alignments_sub = outcome
                       .alignments
                       .select("
                         content_tags.id, 'direct' as alignment_type, content_tags.content_id, content_tags.content_type, content_tags.context_id, content_tags.context_type,
                           CASE
                             WHEN content_tags.content_type = 'AssessmentQuestionBank' THEN question_banks.title
                             WHEN content_tags.content_type = 'Rubric' THEN rubrics.title
                             ELSE content_tags.title
                           END AS title,
                         content_tags.learning_outcome_id, content_tags.created_at, content_tags.updated_at, assignments.assignment_id, assignments.assignment_submission_types, assignments.assignment_workflow_state, assignments.discussion_id, assignments.quiz_id
                       ")
                       .where(context: @context, content_type: %w[Rubric Assignment AssessmentQuestionBank])
                       .joins("LEFT OUTER JOIN (#{assignments_sub.to_sql}) AS assignments ON content_tags.content_id = assignments.assignment_id AND content_tags.content_type = 'Assignment'")
                       .joins("LEFT OUTER JOIN #{AssessmentQuestionBank.quoted_table_name} AS question_banks ON content_tags.content_id = question_banks.id AND content_tags.content_type = 'AssessmentQuestionBank'")
                       .joins("LEFT OUTER JOIN #{Rubric.quoted_table_name} AS rubrics ON content_tags.content_id = rubrics.id AND content_tags.content_type = 'Rubric'")

      direct_alignments = ContentTag
                          .select("alignments.*, modules.module_id, modules.module_name, modules.module_workflow_state")
                          .from("(#{alignments_sub.to_sql}) AS alignments")
                          .joins("LEFT OUTER JOIN (#{modules_sub.to_sql}) AS modules
                            ON (alignments.quiz_id = modules.assignment_content_id AND modules.assignment_content_type = 'Quizzes::Quiz')
                            OR (alignments.discussion_id = modules.assignment_content_id AND modules.assignment_content_type = 'DiscussionTopic')
                            OR (alignments.assignment_id = modules.assignment_content_id AND modules.assignment_content_type = 'Assignment')
                          ")

      # indirect outcome alignments to quizzes via question banks
      # map question banks to questions
      question_banks_to_questions_sub = AssessmentQuestionBank
                                        .active
                                        .select("assessment_question_banks.id as bank_id, assessment_questions.id as question_id")
                                        .where(context: @context)
                                        .left_joins(:assessment_questions)
                                        .where("assessment_questions.workflow_state<>'deleted'")

      # map question banks to quizzes via questions
      question_banks_to_quizzes_sub = AssessmentQuestionBank
                                      .select("banks.bank_id, quiz_questions.quiz_id")
                                      .from("(#{question_banks_to_questions_sub.to_sql}) AS banks")
                                      .joins("INNER JOIN #{Quizzes::QuizQuestion.quoted_table_name} AS quiz_questions
                                    ON banks.question_id = quiz_questions.assessment_question_id
                                    WHERE quiz_questions.workflow_state <> 'deleted'
                                  ")

      # quizzes which are indirectly aligned to outcome via question banks
      quizzes_to_outcome_indirect = outcome.alignments
                                           .select("question_bank.quiz_id as id")
                                           .where(context: @context, content_type: "AssessmentQuestionBank")
                                           .joins("LEFT OUTER JOIN (#{question_banks_to_quizzes_sub.to_sql}) AS question_bank
                                              ON content_tags.content_id = question_bank.bank_id
                                            ")
                                           .distinct

      indirect_alignments = Assignment
                            .active
                            .select("assignments.id, 'indirect' as alignment_type, assignments.id as content_id, 'Assignment' as content_type, assignments.context_id, assignments.context_type, quizzes.title as title, #{outcome.id} as learning_outcome_id, assignments.created_at, assignments.updated_at, assignments.id as assignment_id, assignments.submission_types as assignment_submission_types, assignments.workflow_state as assignment_workflow_state, null::bigint as discussion_id, quizzes.id as quiz_id, modules.module_id, modules.module_name, modules.module_workflow_state")
                            .where(context: @context)
                            .left_joins(:quiz)
                            .where(quizzes: { id: quizzes_to_outcome_indirect })
                            .joins("LEFT OUTER JOIN (#{modules_sub.to_sql}) AS modules
                              ON (quizzes.id = modules.assignment_content_id
                              AND modules.assignment_content_type = 'Quizzes::Quiz')
                            ")
                            .distinct

      # outcome-service alignments
      outcome_os_alignments = active_os_alignments[outcome.id.to_s]
      if outcome_os_alignments.present?

        os_aligned_new_quiz_ids = outcome_os_alignments
                                  .filter_map { |a| a[:associated_asset_id].to_i if SUPPORTED_OS_ALIGNMENTS.include?(a[:artifact_type]) && a[:associated_asset_type] == "canvas.assignment.quizzes" }
                                  .uniq

        external_alignments = Assignment
                              .active
                              .select("assignments.id, 'external' as alignment_type, assignments.id as content_id, 'Assignment' as content_type, assignments.context_id, assignments.context_type, assignments.title as title, #{outcome.id} as learning_outcome_id, assignments.created_at, assignments.updated_at, assignments.id as assignment_id, assignments.submission_types as assignment_submission_types, assignments.workflow_state as assignment_workflow_state, null::bigint as discussion_id, null::bigint as quiz_id, modules.module_id, modules.module_name, modules.module_workflow_state")
                              .where(context: @context, id: os_aligned_new_quiz_ids)
                              .joins("LEFT OUTER JOIN (#{modules_sub.to_sql}) AS modules
                                ON (assignments.id = modules.assignment_content_id
                                AND modules.assignment_content_type = 'Assignment')
                              ")
                              .distinct

        all_alignments = ContentTag.select(all_fields).from("(#{direct_alignments.to_sql} UNION #{indirect_alignments.to_sql} UNION #{external_alignments.to_sql}) AS content_tags")
      else
        all_alignments = ContentTag.select(all_fields).from("(#{direct_alignments.to_sql} UNION #{indirect_alignments.to_sql}) AS content_tags")
      end

      # deduplicate and sort alignments
      alignments = []
      uniq_alignments = Set.new
      all_alignments_sorted = all_alignments.sort_by { |a| a[:alignment_type] }

      all_alignments_sorted.each do |a|
        quiz_items, alignments_count = get_quiz_items_and_alignments_count(a, outcome_os_alignments) if outcome_os_alignments.present? && a[:alignment_type] == "external"
        align = alignment_hash(a, quiz_items, alignments_count)
        art_id = artifact_id(a)
        unless uniq_alignments.include?(art_id)
          alignments.push(align)
          uniq_alignments.add(art_id)
        end
      end

      sorted_alignments = alignments.sort_by { |a| a[:title] }

      fulfill(outcome, sorted_alignments)
    end
  end

  def fulfill_nil(outcomes)
    outcomes.each do |outcome|
      fulfill(outcome, nil) unless fulfilled?(outcome)
    end
  end

  private

  def alignment_hash(alignment, quiz_items = nil, alignments_count = nil)
    {
      _id: id(alignment, quiz_items),
      title: alignment[:title],
      content_id: alignment[:content_id],
      content_type: alignment[:content_type],
      context_id: alignment[:context_id],
      context_type: alignment[:context_type],
      learning_outcome_id: alignment[:learning_outcome_id],
      url: url(alignment),
      module_id: alignment[:module_id],
      module_name: alignment[:module_name],
      module_url: module_url(alignment),
      module_workflow_state: alignment[:module_workflow_state],
      assignment_content_type: assignment_content_type(alignment),
      assignment_workflow_state: alignment[:assignment_workflow_state],
      quiz_items:,
      alignments_count: alignments_count || 1,
      created_at: alignment[:created_at],
      updated_at: alignment[:updated_at]
    }
  end

  def id(alignment, quiz_items = nil)
    # prepend id with alignment type to make it unique
    alignment_types = {
      "direct" => "D",
      "indirect" => "I",
      "external" => "E"
    }

    alignment_id = alignment[:id]
    # for new quizzes, append quiz id with the hash of quiz item ids to make it unique
    if alignment[:alignment_type] == "external" && quiz_items.present?
      item_ids_hash = quiz_items.pluck(:_id).join("_").hash
      alignment_id = [alignment_id, "IH", item_ids_hash].join("_")
    end

    base_id = [alignment_types[alignment[:alignment_type]], alignment_id].join("_")

    # append id with module id to ensure unique alignment id when artifact is included in multiple modules
    return [base_id, alignment[:module_id]].join("_") if alignment[:module_id]

    base_id
  end

  def assignment_content_type(alignment)
    return "quiz" unless alignment[:quiz_id].nil?
    return "discussion" unless alignment[:discussion_id].nil?
    return "new_quiz" if alignment[:assignment_id].present? && alignment[:assignment_submission_types] == "external_tool"

    "assignment" unless alignment[:assignment_id].nil?
  end

  def base_url(alignment)
    ["/#{alignment[:context_type].downcase.pluralize}", alignment[:context_id]].join("/")
  end

  def url(alignment)
    return [base_url(alignment), "rubrics", alignment[:content_id]].join("/") if alignment[:content_type] == "Rubric"
    return [base_url(alignment), "question_banks", alignment[:content_id]].join("/") if alignment[:content_type] == "AssessmentQuestionBank"
    return [base_url(alignment), "assignments", alignment[:content_id]].join("/") if alignment[:content_type] == "Assignment"

    base_url(alignment)
  end

  def module_url(alignment)
    [base_url(alignment), "modules", alignment[:module_id]].join("/") if alignment[:module_id]
  end

  def artifact_id(alignment)
    base_art_id = [alignment[:content_type], alignment[:content_id], (alignment[:alignment_type] == "external") ? "EXT" : "INT"].join("_")
    return [base_art_id, alignment[:module_id]].join("_") if alignment[:module_id]

    base_art_id
  end

  def get_quiz_items_and_alignments_count(alignment, os_alignments)
    count = 0
    items = []
    os_alignments.each do |a|
      next unless a[:associated_asset_type] == "canvas.assignment.quizzes" && a[:associated_asset_id] == alignment[:content_id].to_s

      items << { _id: a[:artifact_id], title: a[:title] } if a[:artifact_type] == "quizzes.item"
      count += 1 if SUPPORTED_OS_ALIGNMENTS.include?(a[:artifact_type])
    end
    [items, count]
  end
end
