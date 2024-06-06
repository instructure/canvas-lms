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

module ModuleVisibility
  module Repositories
    class ModuleVisibleToStudentRepository
      class << self
        # NOTE: context module has a pretty different function for a few of the functions implemented here

        # if only_visible_to_overrides is false, or there's related modules with no overrides, then everyone can see it
        def find_modules_visible_to_everyone(course_id_params:, user_id_params:, context_module_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, context_module_id_params:)
          query_sql = <<~SQL.squish

            #{context_module_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override */
            #{context_module_assignment_override_everyone_join_sql}

            /* filtered to course_id, user_id, context_module_id, and additional conditions */
            #{context_module_assignment_override_everyone_filter_sql(filter_condition_sql:)}

          SQL

          query_params = query_params(course_id_params:, user_id_params:, context_module_id_params:)
          exec_find_module_visibility_query(query_sql:, query_params:)
        end

        # section overrides and related module section overrides
        def find_modules_visible_to_sections(course_id_params:, user_id_params:, context_module_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, context_module_id_params:)
          query_sql = <<~SQL.squish
            #{context_module_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment overrides (assignment or related context module) for CourseSection */
            #{context_module_assignment_override_section_join_sql}

            /* filtered to course_id, user_id, context_module_id, and additional conditions */
            #{context_module_assignment_override_section_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_id_params:, user_id_params:, context_module_id_params:)
          exec_find_module_visibility_query(query_sql:, query_params:)
        end

        # ADHOC overrides and related module ADHOC overrides
        def find_modules_visible_to_adhoc_overrides(course_id_params:, user_id_params:, context_module_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, context_module_id_params:)
          query_sql = <<~SQL.squish
            #{context_module_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'ADHOC' */
            #{context_module_assignment_override_adhoc_join_sql}

            /* join AssignmentOverrideStudent */
            #{VisibilitySqlHelper.assignment_override_student_join_sql}

            /* filtered to course_id, user_id, context_module_id, and additional conditions */
            #{context_module_adhoc_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_id_params:, user_id_params:, context_module_id_params:)
          exec_find_module_visibility_query(query_sql:, query_params:)
        end

        private

        def exec_find_module_visibility_query(query_sql:, query_params:)
          # safely replace parameters in the filter clause
          sanitized_sql = ActiveRecord::Base.sanitize_sql_array([query_sql, query_params])

          # Execute the query
          query_results = ActiveRecord::Base.connection.exec_query(sanitized_sql)

          # map the results to an array of AssignmentVisibleToStudent (DTO / PORO) and return it
          query_results.map do |row|
            ModuleVisibility::Entities::ModuleVisibleToStudent.new(course_id: row["course_id"], context_module_id: row["context_module_id"], user_id: row["user_id"])
          end
        end

        def query_params(course_id_params:, user_id_params:, context_module_id_params:)
          query_params = {}
          query_params[:course_id] = course_id_params unless course_id_params.nil?
          query_params[:user_id] = user_id_params unless user_id_params.nil?
          query_params[:context_module_id] = context_module_id_params unless context_module_id_params.nil?
          query_params
        end

        # Create a filter clause SQL from the params - something like: e.user_id IN ['1', '2'] AND course_id = '20'
        # Note that at least one of the params must be non nil
        def filter_condition_sql(course_id_params: nil, user_id_params: nil, context_module_id_params: nil)
          query_conditions = []

          if context_module_id_params
            query_conditions << if context_module_id_params.is_a?(Array)
                                  "o.id IN (:context_module_id)"
                                else
                                  "o.id = :context_module_id"
                                end
          end

          if user_id_params
            query_conditions << if user_id_params.is_a?(Array)
                                  "e.user_id IN (:user_id)"
                                else
                                  "e.user_id = :user_id"
                                end
          end

          if course_id_params
            query_conditions << if course_id_params.is_a?(Array)
                                  "e.course_id IN (:course_id)"
                                else
                                  "e.course_id = :course_id"
                                end
          end

          if query_conditions.empty?
            raise ArgumentError, "ModulesVisibleToStudents must have a limiting where clause of at least one course_id, user_id, or context_module_id (for performance reasons)"
          end

          query_conditions.join(" AND ")
        end

        def context_module_select_sql
          <<~SQL.squish
            SELECT DISTINCT o.id as context_module_id,
            e.user_id as user_id,
            e.course_id as course_id
            FROM #{ContextModule.quoted_table_name} o
          SQL
        end

        def context_module_assignment_override_everyone_join_sql
          <<~SQL.squish
            LEFT JOIN #{AssignmentOverride.quoted_table_name} ao
            ON ao.context_module_id = o.id
            AND ao.workflow_state = 'active'
          SQL
        end

        def context_module_assignment_override_everyone_filter_sql(filter_condition_sql:)
          <<~SQL.squish
            WHERE #{filter_condition_sql}
              AND o.workflow_state NOT IN ('deleted','unpublished')
              AND (o.id IS NULL OR (ao.context_module_id IS NULL AND o.workflow_state <> 'deleted'))
          SQL
        end

        def context_module_assignment_override_section_join_sql
          <<~SQL.squish
            INNER JOIN #{AssignmentOverride.quoted_table_name} ao
            ON e.course_section_id = ao.set_id
            AND ao.set_type = 'CourseSection'
            AND ao.context_module_id = o.id
            AND ao.workflow_state = 'active'
          SQL
        end

        def context_module_assignment_override_section_filter_sql(filter_condition_sql:)
          <<~SQL.squish
            WHERE #{filter_condition_sql}
              AND o.workflow_state NOT IN ('deleted','unpublished')
              AND ao.unassign_item = FALSE
          SQL
        end

        def context_module_assignment_override_adhoc_join_sql
          <<~SQL.squish
            INNER JOIN #{AssignmentOverride.quoted_table_name} ao
              ON ao.context_module_id = o.id
              AND ao.set_type = 'ADHOC'
              AND ao.workflow_state = 'active'
          SQL
        end

        def context_module_adhoc_override_filter_sql(filter_condition_sql:)
          <<~SQL.squish
            WHERE #{filter_condition_sql}
              AND o.workflow_state NOT IN ('deleted','unpublished')
              AND ao.unassign_item = FALSE
          SQL
        end
      end
    end
  end
end
