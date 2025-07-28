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
  module Repositories
    class QuizVisibleToStudentRepository
      class << self
        def visibility_query(course_ids:, user_ids:, quiz_ids:)
          filter_condition_sql = filter_condition_sql(course_ids:, user_ids:, quiz_ids:)
          query_sql = <<~SQL.squish

            /* quizzes visible to everyone */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join context modules */
            #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "Quizzes::Quiz")}

            /* join assignment override */
            #{VisibilitySqlHelper.assignment_override_everyone_join_sql}

            /* filtered to course_id, user_id, quiz_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_everyone_filter_sql(filter_condition_sql:)}

            UNION

            /* quizzes visible to sections */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                VisibilitySqlHelper.full_section_without_left_joins_sql(filter_condition_sql:, id_column_name: "quiz_id", table_name: Quizzes::Quiz)
              else
                VisibilitySqlHelper.full_section_with_left_joins_sql(filter_condition_sql:, id_column_name: "quiz_id", content_tag_type: "Quizzes::Quiz")
              end}

            EXCEPT

            /* remove quizzes with unassigned section overrides */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'CourseSection' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_section_join_sql(id_column_name: "quiz_id")}

            /* filtered to course_id, user_id, quiz_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

            /* non collaborative groups */
            /* incorporate non_collaborative groups if account feature flag is enabled */
            #{non_collaborative_group_union_sql(filter_condition_sql) if VisibilitySqlHelper.assign_to_differentiation_tags_enabled?(course_ids)}

            UNION

            /* quizzes with adhoc overrides */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                VisibilitySqlHelper.full_adhoc_without_left_joins_sql(filter_condition_sql:, id_column_name: "quiz_id", table_name: Quizzes::Quiz)
              else
                VisibilitySqlHelper.full_adhoc_with_left_joins_sql(filter_condition_sql:, id_column_name: "quiz_id", content_tag_type: "Quizzes::Quiz")
              end}

            EXCEPT

            /* remove quizzes with unassigned adhoc overrides */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment overrides for 'ADHOC' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_adhoc_join_sql(id_column_name: "quiz_id")}

            /* filtered to course_id, user_id, quiz_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

            UNION

            /* quizzes with course overrides */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'Course' */
            #{VisibilitySqlHelper.assignment_override_course_join_sql(id_column_name: "quiz_id")}

            /* filtered to course_id, user_id, quiz_id, and additional conditions */
            #{VisibilitySqlHelper.course_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_ids:, user_ids:, quiz_ids:)
          exec_find_quiz_visibility_query(query_sql:, query_params:)
        end

        private

        def exec_find_quiz_visibility_query(query_sql:, query_params:)
          # safely replace parameters in the filter clause
          sanitized_sql = ActiveRecord::Base.sanitize_sql_array([query_sql, query_params])

          # Execute the query
          query_results = ActiveRecord::Base.connection.exec_query(sanitized_sql)

          # map the results to an array of AssignmentVisibleToStudent (DTO / PORO) and return it
          query_results.map do |row|
            QuizVisibility::Entities::QuizVisibleToStudent.new(course_id: row["course_id"], quiz_id: row["quiz_id"], user_id: row["user_id"])
          end
        end

        def query_params(course_ids:, user_ids:, quiz_ids:)
          query_params = {}
          query_params[:course_id] = course_ids if course_ids
          query_params[:user_id] = user_ids if user_ids
          query_params[:quiz_id] = quiz_ids if quiz_ids
          query_params
        end

        # Create a filter clause SQL from the params - something like: e.user_id IN ['1', '2'] AND course_id = '20'
        # Note that at least one of the params must be non nil
        def filter_condition_sql(course_ids: nil, user_ids: nil, quiz_ids: nil)
          query_conditions = []
          query_conditions << "o.id IN (:quiz_id)" if quiz_ids
          query_conditions << "e.user_id IN (:user_id)" if user_ids
          query_conditions << "e.course_id IN (:course_id)" if course_ids
          query_conditions.join(" AND ")
        end

        def quiz_select_sql
          <<~SQL.squish
            SELECT DISTINCT o.id as quiz_id,
            e.user_id as user_id,
            e.course_id as course_id
            FROM #{Quizzes::Quiz.quoted_table_name} o
          SQL
        end

        def non_collaborative_group_union_sql(filter_condition_sql)
          <<~SQL.squish
            UNION

            /* quizzes visible to non collaborative groups */
            /* selecting quizzes */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join context modules */
            #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "Quizzes::Quiz")}

            /* join assignment overrides for non collaborative 'Group' */
            #{VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "quiz_id")}

            /* filtered to course_id, user_id, quiz_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_non_collaborative_group_filter_sql(filter_condition_sql:)}

            EXCEPT

            /* remove students with unassigned non collaborative groups overrides */
            /* selecting quizzes */
            #{quiz_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for non collaborative 'Group' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_non_collaborative_group_join_sql(id_column_name: "quiz_id")}

            /* filtered to course_id, user_id, quiz_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}
          SQL
        end
      end
    end
  end
end
