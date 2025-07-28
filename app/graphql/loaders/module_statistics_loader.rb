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

##
# Loader for calculating statistics about a module, such as overdue assignments and
# assignments due in the near future for the current user.
#
module Loaders
  class ModuleStatisticsLoader < GraphQL::Batch::Loader
    ASSIGNMENT = "Assignment"
    DISCUSSION_TOPIC = "DiscussionTopic"
    CLASSIC_QUIZ = "Quizzes::Quiz"

    def initialize(current_user:)
      super()
      @current_user = current_user
    end

    def perform(context_modules)
      return if context_modules.empty? || @current_user.nil?

      submissions_by_modules = query_submissions_by_modules(context_modules)

      context_modules.each do |context_module|
        fulfill(context_module, submissions_by_modules[context_module.id] || [])
      end
    end

    private

    def query_submissions_by_modules(context_modules)
      module_ids = context_modules.map(&:id)

      content_type_groups = ContentTag.not_deleted
                                      .where(context_module_id: module_ids)
                                      .where.not(content_id: nil)
                                      .pluck(:content_type, :content_id, :context_module_id)
                                      .group_by { |arr| arr[0] }
                                      .transform_values do |items|
        items.group_by { |i| i[1] }.transform_values { |group| group.to_set { |i| i[2] } }
      end

      # {"Assignment"=>{content_id_1=>#<Set: {context_module_id_1, context_module_id_2}>, "Quizzes::Quiz"=>{content_id_1=>#<Set: {context_module_id_1}>}

      assignment_ids_by_modules = content_type_groups.each_with_object({}) do |(content_type, content_and_modules_pair), result|
        case content_type
        when ASSIGNMENT # New Quizzes are included here
          result.merge!(content_and_modules_pair)
        when DISCUSSION_TOPIC
          DiscussionTopic.find(content_and_modules_pair.keys).each do |discussion|
            result[discussion.assignment_id] = content_and_modules_pair[discussion.id] if discussion.assignment_id
          end
        when CLASSIC_QUIZ
          Quizzes::Quiz.find(content_and_modules_pair.keys).each do |quiz|
            result[quiz.assignment_id] = content_and_modules_pair[quiz.id] if quiz.assignment_id
          end
        end
      end

      # Transform every content_id to assignment_id
      # {assignment_id_1=>context_module_id_1, assignment_id_2=>context_module_id_1, assignment_id_3=>context_module_id_2}

      # Remove parent assignments from discussion checkpoints
      assignments_ids = Assignment.where(id: assignment_ids_by_modules.keys, has_sub_assignments: false).pluck(:id)
      # Load sub assignments from discussion checkpoints
      sub_assignments = SubAssignment.where(parent_assignment_id: assignment_ids_by_modules.keys)
      merged_assignment_ids = assignments_ids + sub_assignments.map(&:id)

      # Generate mapping for sub_assignments because they are directly not attached to module items
      sub_assignment_ids_by_modules = sub_assignments.to_h do |sub_assignment|
        module_id = assignment_ids_by_modules[sub_assignment.parent_assignment_id]
        [sub_assignment.id, module_id]
      end

      merged_assignment_ids_by_modules = assignment_ids_by_modules.merge(sub_assignment_ids_by_modules)

      @current_user
        .submissions
        .where(assignment_id: merged_assignment_ids)
        .joins(:assignment)
        .merge(AbstractAssignment.published)
        .each_with_object(Hash.new { |h, k| h[k] = [] }) do |submission, grouped|
          merged_assignment_ids_by_modules[submission.assignment_id].each do |module_id|
            grouped[module_id] << submission
          end
        end
    end
  end
end
