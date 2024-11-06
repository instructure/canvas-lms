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

module QuizVisibility
  class QuizVisibilityService
    extend VisibilityHelpers::Common
    class << self
      def visible_quiz_ids_in_course_by_user(user_ids:, course_ids:, use_global_id: false)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        vis_hash = {}
        quizzes_visible_to_students(user_id_params: user_ids, course_id_params: course_ids).each do |quiz_visible_to_student|
          user_id = quiz_visible_to_student.user_id
          user_id = Shard.global_id_for(user_id) if use_global_id
          vis_hash[user_id] ||= []
          vis_hash[user_id] << quiz_visible_to_student.quiz_id
        end
        # if users have no visibilities add their keys to the hash with an empty array
        vis_hash.reverse_merge!(user_ids.index_with { [] })
      end

      def quizzes_visible_to_student(course_id:, user_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        quizzes_visible_to_students(course_id_params: course_id, user_id_params: user_id)
      end

      def quizzes_visible_to_students_in_courses(course_ids:, user_ids:)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        quizzes_visible_to_students(course_id_params: course_ids, user_id_params: user_ids)
      end

      def quiz_visible_to_student(quiz_id:, user_id:)
        raise ArgumentError, "quiz_id cannot be nil" if quiz_id.nil?
        raise ArgumentError, "quiz_id must not be an array" if quiz_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        quizzes_visible_to_students(quiz_id_params: quiz_id, user_id_params: user_id)
      end

      def quiz_visible_to_students(quiz_id:, user_ids:)
        raise ArgumentError, "quiz_id cannot be nil" if quiz_id.nil?
        raise ArgumentError, "quiz_id must not be an array" if quiz_id.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        quizzes_visible_to_students(quiz_id_params: quiz_id, user_id_params: user_ids)
      end

      def quiz_visible_in_course(quiz_id:, course_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "quiz_id cannot be nil" if quiz_id.nil?
        raise ArgumentError, "quiz_id must not be an array" if quiz_id.is_a?(Array)

        quizzes_visible_to_students(course_id_params: course_id, quiz_id_params: quiz_id)
      end

      private

      def quizzes_visible_to_students(course_id_params: nil, user_id_params: nil, quiz_id_params: nil)
        if course_id_params.nil? && user_id_params.nil? && quiz_id_params.nil?
          raise ArgumentError, "at least one non nil course_id, user_id, or quiz_id_params is required (for query performance reasons)"
        end

        service_cache_fetch(service: name, course_id_params:, user_id_params:, additional_id_params: quiz_id_params) do
          if Account.site_admin.feature_enabled?(:selective_release_optimized_services_v3)
            QuizVisibility::Repositories::QuizVisibleToStudentRepository.full_quiz_visibility_query(course_id_params:, user_id_params:, quiz_id_params:)
          elsif Account.site_admin.feature_enabled?(:selective_release_optimized_services_v2)
            visible_quizzes = []

            # add quizzes visible to everyone
            quizzes_visible_to_all = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                     .find_quizzes_visible_to_everyone(course_id_params:, user_id_params:, quiz_id_params:)
            visible_quizzes |= quizzes_visible_to_all

            # add quizzes assigned to sections, students, or the course
            quizzes_assigned_to_others = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                         .find_quizzes_assigned_to_others(course_id_params:, user_id_params:, quiz_id_params:)

            visible_quizzes | quizzes_assigned_to_others
          else
            visible_quizzes = []

            # add quizzes visible to everyone
            quizzes_visible_to_all = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                     .find_quizzes_visible_to_everyone(course_id_params:, user_id_params:, quiz_id_params:)
            visible_quizzes |= quizzes_visible_to_all

            if Account.site_admin.feature_enabled?(:selective_release_optimized_services)
              # add quizzes visible to sections (and related module section overrides) without unassign overrides
              quizzes_assigned_to_sections = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                             .find_quizzes_assigned_to_sections(course_id_params:, user_id_params:, quiz_id_params:)
              visible_quizzes |= quizzes_assigned_to_sections
            else
              # add quizzes visible to sections (and related module section overrides)
              quizzes_visible_to_sections = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                            .find_quizzes_visible_to_sections(course_id_params:, user_id_params:, quiz_id_params:)
              visible_quizzes |= quizzes_visible_to_sections

              # remove quizzes for students with unassigned section overrides
              quizzes_with_unassigned_section_overrides = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                                          .find_quizzes_with_unassigned_section_overrides(course_id_params:, user_id_params:, quiz_id_params:)
              visible_quizzes -= quizzes_with_unassigned_section_overrides
            end

            if Account.site_admin.feature_enabled?(:selective_release_optimized_services)
              # add quizzes visible due to ADHOC overrides (and related module ADHOC overrides) without unassign overrides
              quizzes_assigned_to_adhoc_overrides = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                                    .find_quizzes_assigned_to_adhoc_overrides(course_id_params:, user_id_params:, quiz_id_params:)
              visible_quizzes |= quizzes_assigned_to_adhoc_overrides
            else
              # add quizzes visible due to ADHOC overrides (and related module ADHOC overrides)
              quizzes_visible_to_adhoc_overrides = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                                   .find_quizzes_visible_to_adhoc_overrides(course_id_params:, user_id_params:, quiz_id_params:)
              visible_quizzes |= quizzes_visible_to_adhoc_overrides

              # remove quizzes for students with unassigned ADHOC overrides
              quizzes_with_unassigned_adhoc_overrides = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                                        .find_quizzes_with_unassigned_adhoc_overrides(course_id_params:, user_id_params:, quiz_id_params:)
              visible_quizzes -= quizzes_with_unassigned_adhoc_overrides
            end

            # add quizzes visible due to course overrides
            quizzes_visible_to_course_overrides = QuizVisibility::Repositories::QuizVisibleToStudentRepository
                                                  .find_quizzes_visible_to_course_overrides(course_id_params:, user_id_params:, quiz_id_params:)

            visible_quizzes | quizzes_visible_to_course_overrides
          end
        end
      end
    end
  end
end
