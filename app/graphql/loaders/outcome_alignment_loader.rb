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

  VALID_CONTEXT_TYPES = ["Course", "Account"].freeze

  def initialize(context_id, context_type)
    super()
    @context_id = context_id
    @context_type = context_type
    @context = VALID_CONTEXT_TYPES.include?(context_type) ? context_type.constantize.active.find_by(id: context_id) : nil
  end

  def perform(outcomes)
    if @context.nil? || !outcome_alignment_summary_enabled?(@context)
      fulfill_nil(outcomes)
      return
    end

    outcomes.each do |outcome|
      # map assignment id to quiz and discussion ids
      assignments_sub = Assignment
                        .active
                        .select("assignments.id as assignment_id, discussion_topics.id as discussion_id, quizzes.id as quizzes_id")
                        .where(context: @context)
                        .left_joins(:discussion_topic)
                        .left_joins(:quiz)

      # map assignment id to module id
      modules_sub = ContextModule
                    .not_deleted
                    .select("context_modules.id as module_id, context_modules.name as module_name, context_modules.workflow_state as module_workflow_state, content_tags.content_id as assignment_content_id, content_tags.content_type as assignment_content_type")
                    .where(context: @context)
                    .left_joins(:content_tags)
                    .where(content_tags: { workflow_state: "active" })

      # map alignment id to assignment, quiz and discussion ids
      alignments_sub = outcome
                       .alignments
                       .select("content_tags.id, content_tags.content_id, content_tags.content_type, content_tags.context_id, content_tags.context_type, content_tags.title, content_tags.learning_outcome_id, content_tags.created_at, content_tags.updated_at, assignments.assignment_id, assignments.discussion_id, assignments.quizzes_id")
                       .where(context: @context, content_type: %w[Rubric Assignment AssessmentQuestionBank])
                       .joins("LEFT OUTER JOIN (#{assignments_sub.to_sql}) AS assignments ON content_tags.content_id = assignments.assignment_id AND content_tags.content_type = 'Assignment'")

      alignments = ContentTag
                   .select("alignments.*, modules.module_id, modules.module_name, modules.module_workflow_state")
                   .from("(#{alignments_sub.to_sql}) AS alignments")
                   .joins("LEFT OUTER JOIN (#{modules_sub.to_sql}) AS modules
                      ON (alignments.quizzes_id = modules.assignment_content_id AND modules.assignment_content_type = 'Quizzes::Quiz')
                      OR (alignments.discussion_id = modules.assignment_content_id AND modules.assignment_content_type = 'DiscussionTopic')
                      OR (alignments.assignment_id = modules.assignment_content_id AND modules.assignment_content_type = 'Assignment')
                    ")
                   .order("title ASC")
                   .to_a

      fulfill(outcome, alignments)
    end
  end

  def fulfill_nil(outcomes)
    outcomes.each do |outcome|
      fulfill(outcome, nil) unless fulfilled?(outcome)
    end
  end
end
