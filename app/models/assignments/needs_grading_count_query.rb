# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Assignments
  class NeedsGradingCountQuery
    # holds values so we don't have to recompute them over and over again
    class CourseProxy
      attr_reader :course, :user

      def initialize(course, user)
        @course = course
        @user = user
      end

      def section_visibilities
        @section_visibilities ||= course.section_visibilities_for(user)
      end

      def visibility_level
        @visibility_level ||= course.enrollment_visibility_level_for(user, section_visibilities)
      end

      def visible_section_ids
        @visible_section_ids ||= section_visibilities.pluck(:course_section_id)
      end
    end

    attr_reader :assignment, :user, :course_proxy

    delegate :course, :section_visibilities, :visibility_level, :visible_section_ids, to: :course_proxy

    def initialize(assignment, user = nil, course_proxy = nil)
      @assignment = assignment
      @user = user
      @course_proxy = course_proxy || CourseProxy.new(@assignment.context, @user)
    end

    def count
      assignment.shard.activate do
        # the needs_grading_count trigger should clear the assignment's needs_grading cache
        Rails.cache.fetch_with_batched_keys(["assignment_user_grading_count", assignment.cache_key(:needs_grading), user].cache_key,
                                            batch_object: user,
                                            batched_keys: :todo_list) do
          if assignment.moderated_grading? && !assignment.grades_published?
            needs_moderated_grading_count
          else
            case visibility_level
            when :full, :limited
              manual_count
            when :sections, :sections_limited
              section_filtered_submissions.distinct.count(:id)
            else
              0
            end
          end
        end
      end
    end

    def needs_moderated_grading_count
      level = visibility_level
      return 0 unless %i[full limited sections sections_limited].include?(level)

      # ignore submissions this user has graded
      graded_sub_ids = assignment.submissions.joins(:provisional_grades)
                                 .where(moderated_grading_provisional_grades: { final: false, scorer_id: user.id })
                                 .where.not(moderated_grading_provisional_grades: { score: nil }).pluck(:id)

      moderation_set_student_ids = assignment.moderated_grading_selections.pluck(:student_id)

      # ignore submissions that don't need any more provisional grades
      pg_scope = assignment.submissions.joins(:provisional_grades)
                           .where(moderated_grading_provisional_grades: { final: false })
                           .where.not(moderated_grading_provisional_grades: { scorer_id: user.id })
                           .group("submissions.id", "submissions.user_id")
      pg_scope = pg_scope.where.not(submissions: { id: graded_sub_ids }) if graded_sub_ids.any?
      pg_scope.count.each do |key, count|
        sub_id, user_id = key
        graded_sub_ids << sub_id if count >= (moderation_set_student_ids.include?(user_id) ? 2 : 1)
      end

      scope = (level == :sections) ? section_filtered_submissions : all_submissions
      if graded_sub_ids.any?
        scope.where.not(submissions: { id: graded_sub_ids }).distinct.count(:id)
      else
        scope.distinct.count(:id)
      end
    end

    def count_by_section
      assignment.shard.activate do
        Rails.cache.fetch(["assignment_user_grading_count_by_section", assignment.cache_key(:needs_grading), user].cache_key,
                          batch_object: user,
                          batched_keys: :todo_list) do
          submissions = if visibility_level == :sections
                          section_filtered_submissions
                        else
                          all_submissions
                        end

          submissions
            .group("e.course_section_id")
            .count
            .map { |k, v| { section_id: k.to_i, needs_grading_count: v } }
        end
      end
    end

    def manual_count
      assignment.shard.activate do
        all_submissions.distinct.count(:id)
      end
    end

    private

    def section_filtered_submissions
      all_submissions.where(e: { course_section_id: visible_section_ids })
    end

    def all_submissions
      string = <<~SQL.squish
        submissions.assignment_id = ?
          AND e.course_id = ?
          AND e.type IN ('StudentEnrollment', 'StudentViewEnrollment')
          AND e.workflow_state = 'active'
          AND #{Submission.needs_grading_conditions}
      SQL
      joined_submissions.where(string, assignment, course)
    end

    def joined_submissions
      assignment.submissions.joins("INNER JOIN #{Enrollment.quoted_table_name} e ON e.user_id = submissions.user_id")
    end
  end
end
