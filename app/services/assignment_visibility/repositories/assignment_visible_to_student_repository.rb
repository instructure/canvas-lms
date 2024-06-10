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

module AssignmentVisibility
  module Repositories
    class AssignmentVisibleToStudentRepository
      class << self
        # if only_visible_to_overrides is false, or there's related modules with no overrides, then everyone can see it
        def find_assignments_visible_to_everyone(course_id_params:, user_id_params:, assignment_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, assignment_id_params:)
          query_sql = <<~SQL.squish
            WITH #{assignment_module_items_cte_sql(course_id_params:, assignment_id_params:)}

            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* (logical) join context modules */
            #{assignment_module_items_join_sql}

            /* join assignment override */
            #{VisibilitySqlHelper.assignment_override_everyone_join_sql}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_everyone_filter_sql(filter_condition_sql:)}

          SQL

          query_params = query_params(course_id_params:, user_id_params:, assignment_id_params:)
          exec_find_assignment_visibility_query(query_sql:, query_params:)
        end

        # section overrides and related module section overrides
        def find_assignments_visible_to_sections(course_id_params:, user_id_params:, assignment_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, assignment_id_params:)
          query_sql = <<~SQL.squish
            WITH #{assignment_module_items_cte_sql(course_id_params:, assignment_id_params:)}

            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* (logical) join context modules */
            #{assignment_module_items_join_sql}

            /* join assignment overrides (assignment or related context module) for CourseSection */
            #{VisibilitySqlHelper.assignment_override_section_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.section_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_id_params:, user_id_params:, assignment_id_params:)
          exec_find_assignment_visibility_query(query_sql:, query_params:)
        end

        # students with unassigned section overrides
        def find_assignments_with_unassigned_section_overrides(course_id_params:, user_id_params:, assignment_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, assignment_id_params:)
          query_sql = <<~SQL.squish
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'CourseSection' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_section_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_section_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_id_params:, user_id_params:, assignment_id_params:)
          exec_find_assignment_visibility_query(query_sql:, query_params:)
        end

        # students with unassigned adhoc overrides
        def find_assignments_with_unassigned_adhoc_overrides(course_id_params:, user_id_params:, assignment_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, assignment_id_params:)
          query_sql = <<~SQL.squish
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment overrides for 'ADHOC' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_adhoc_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_adhoc_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_id_params:, user_id_params:, assignment_id_params:)
          exec_find_assignment_visibility_query(query_sql:, query_params:)
        end

        # ADHOC overrides and related module ADHOC overrides
        def find_assignments_visible_to_adhoc_overrides(course_id_params:, user_id_params:, assignment_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, assignment_id_params:)
          query_sql = <<~SQL.squish
            WITH #{assignment_module_items_cte_sql(course_id_params:, assignment_id_params:)}

            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* (logical) join context modules */
            #{assignment_module_items_join_sql}

            /* join assignment override for 'ADHOC' */
            #{VisibilitySqlHelper.assignment_override_adhoc_join_sql(id_column_name: "assignment_id")}

            /* join AssignmentOverrideStudent */
            #{VisibilitySqlHelper.assignment_override_student_join_sql}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.adhoc_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_id_params:, user_id_params:, assignment_id_params:)
          exec_find_assignment_visibility_query(query_sql:, query_params:)
        end

        # course overrides
        def find_assignments_visible_to_course_overrides(course_id_params:, user_id_params:, assignment_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, assignment_id_params:)
          query_sql = <<~SQL.squish
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'Course' */
            #{VisibilitySqlHelper.assignment_override_course_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.course_override_filter_sql(filter_condition_sql:)}

          SQL
          query_params = query_params(course_id_params:, user_id_params:, assignment_id_params:)
          exec_find_assignment_visibility_query(query_sql:, query_params:)
        end

        # only assignments can have group overrides
        def find_assignments_visible_to_groups(course_id_params:, user_id_params:, assignment_id_params:)
          filter_condition_sql = filter_condition_sql(course_id_params:, user_id_params:, assignment_id_params:)
          query_sql = <<~SQL.squish

            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment group overrides */
            #{assignment_group_override_join_sql}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{assignment_group_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_id_params:, user_id_params:, assignment_id_params:)
          exec_find_assignment_visibility_query(query_sql:, query_params:)
        end

        private

        def exec_find_assignment_visibility_query(query_sql:, query_params:)
          # safely replace parameters in the filter clause
          sanitized_sql = ActiveRecord::Base.sanitize_sql_array([query_sql, query_params])

          # Execute the query
          query_results = ActiveRecord::Base.connection.exec_query(sanitized_sql)

          # map the results to an array of AssignmentVisibleToStudent (DTO / PORO) and return it
          query_results.map do |row|
            AssignmentVisibility::Entities::AssignmentVisibleToStudent.new(course_id: row["course_id"], assignment_id: row["assignment_id"], user_id: row["user_id"])
          end
        end

        def query_params(course_id_params:, user_id_params:, assignment_id_params:)
          query_params = {}
          query_params[:course_id] = course_id_params unless course_id_params.nil?
          query_params[:user_id] = user_id_params unless user_id_params.nil?
          query_params[:assignment_id] = assignment_id_params unless assignment_id_params.nil?
          query_params
        end

        # Create a filter clause SQL from the params - something like: e.user_id IN ['1', '2'] AND course_id = '20'
        # Note that at least one of the params must be non nil
        def filter_condition_sql(course_id_params: nil, user_id_params: nil, assignment_id_params: nil)
          unless assignment_id_params || course_id_params
            raise ArgumentError, "AssignmentsVisibleToStudents must have a limiting where clause of at least one course_id or assignment_id (for performance reasons)"
          end

          query_conditions = []

          if assignment_id_params
            query_conditions << if assignment_id_params.is_a?(Array)
                                  "o.id IN (:assignment_id)"
                                else
                                  "o.id = :assignment_id"
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

          query_conditions.join(" AND ")
        end

        # assignments utilize a CTE which gathers associated content tags since their tags can come directly
        # from the assignment or from the assignment's associated objects
        def assignment_module_items_cte_sql(course_id_params: nil, assignment_id_params: nil)
          <<~SQL.squish
            assignment_tags AS (
                     SELECT
                         t.content_id AS assignment_id,
                         t.context_module_id
                     FROM
                         #{ContentTag.quoted_table_name} AS t
                     WHERE
                         #{all_tags_filter_condition_sql(tag_type: "assignment", course_id_params:, assignment_id_params:)}
                         AND t.content_type = 'Assignment'
                         AND t.tag_type = 'context_module'
                         AND t.workflow_state <> 'deleted'
                 ), quiz_tags AS (
                     SELECT
                         q.assignment_id,
                         qt.context_module_id
                     FROM
                         #{Quizzes::Quiz.quoted_table_name} AS q
                         JOIN #{ContentTag.quoted_table_name} AS qt ON qt.content_id = q.id AND
                         qt.content_type = 'Quizzes::Quiz'
                     WHERE
                         #{all_tags_filter_condition_sql(tag_type: "quiz", course_id_params:, assignment_id_params:)}
                         AND qt.tag_type = 'context_module'
                         AND qt.workflow_state <> 'deleted'
                         AND q.assignment_id IS NOT NULL
                 ), discussion_topic_tags AS (
                     SELECT
                         d.assignment_id,
                         dt.context_module_id
                     FROM
                         #{DiscussionTopic.quoted_table_name} AS d
                         JOIN #{ContentTag.quoted_table_name} AS dt ON dt.content_id = d.id AND
                         dt.content_type = 'DiscussionTopic'
                     WHERE
                         #{all_tags_filter_condition_sql(tag_type: "discussion", course_id_params:, assignment_id_params:)}
                         AND dt.tag_type = 'context_module'
                         AND dt.workflow_state <> 'deleted'
                         AND d.assignment_id IS NOT NULL
                 ), wiki_pages_tags AS (
                     SELECT
                         p.assignment_id,
                         pt.context_module_id
                     FROM
                         #{WikiPage.quoted_table_name} AS p
                         JOIN #{ContentTag.quoted_table_name} AS pt ON pt.content_id = p.id AND
                         pt.content_type = 'WikiPage'
                     WHERE
                         #{all_tags_filter_condition_sql(tag_type: "page", course_id_params:, assignment_id_params:)}
                         AND pt.tag_type = 'context_module'
                         AND pt.workflow_state <> 'deleted'
                         AND p.assignment_id IS NOT NULL
                 ), all_tags AS (
                     ( SELECT * FROM assignment_tags)
                     UNION
                     ( SELECT * FROM quiz_tags)
                     UNION
                     ( SELECT * FROM discussion_topic_tags)
                     UNION
                     ( SELECT * FROM wiki_pages_tags)
                 )
          SQL
        end

        def assignment_select_sql
          <<~SQL.squish
            SELECT DISTINCT o.id as assignment_id,
                                    e.user_id as user_id,
                                                 e.course_id as course_id
            FROM #{Assignment.quoted_table_name} o
          SQL
        end

        # assignments utilize a CTE which gathers associated content tags since their tags can come directly
        # from the assignment or from the assignment's associated objects
        # note: requires inclusion of the all_tags CTE definition : WITH #{assignment_module_items_cte_sql}
        # in the calling SQL statement
        def assignment_module_items_join_sql
          <<~SQL.squish
            LEFT JOIN all_tags t
              ON o.id = t.assignment_id
            LEFT JOIN #{ContextModule.quoted_table_name} m
              ON m.id = t.context_module_id
              AND m.workflow_state<>'deleted'
          SQL
        end

        def assignment_group_override_join_sql
          <<~SQL.squish
            INNER JOIN #{AssignmentOverride.quoted_table_name} ao
              ON o.id = ao.assignment_id
              AND ao.set_type = 'Group'
            INNER JOIN #{Group.quoted_table_name} g
              ON g.id = ao.set_id
            INNER JOIN #{GroupMembership.quoted_table_name} gm
              ON gm.group_id = g.id
              AND gm.user_id = e.user_id
          SQL
        end

        def assignment_group_override_filter_sql(filter_condition_sql:)
          <<~SQL.squish
            WHERE #{filter_condition_sql}
            AND gm.workflow_state <> 'deleted'
            AND g.workflow_state <> 'deleted'
            AND ao.workflow_state = 'active'
            AND o.workflow_state NOT IN ('deleted','unpublished')
            AND o.only_visible_to_overrides = 'true'
          SQL
        end

        # create the right where filter for each type of content_tag based on given course_ids or assignment_ids
        def all_tags_filter_condition_sql(tag_type:, course_id_params:, assignment_id_params:)
          unless assignment_id_params || course_id_params
            raise ArgumentError, "AssignmentsVisibleToStudents must have a limiting where clause of at least one course_id or assignment_id (for performance reasons)"
          end

          query_conditions = []

          case tag_type
          when "assignment"
            content_id_field = assignment_id_params.is_a?(Array) ? "IN (:assignment_id)" : "= :assignment_id"
            context_id_field = course_id_params.is_a?(Array) ? "IN (:course_id)" : "= :course_id"
            query_conditions << "t.content_id #{content_id_field}" if assignment_id_params
            query_conditions << "t.context_id #{context_id_field}" if course_id_params
          when "quiz", "discussion", "page"
            assignment_id_field = "#{tag_type[0]}." + (assignment_id_params.is_a?(Array) ? "assignment_id IN (:assignment_id)" : "assignment_id = :assignment_id")
            context_id_field = "#{tag_type[0]}t.context_id " + (course_id_params.is_a?(Array) ? "IN (:course_id)" : "= :course_id")
            query_conditions << assignment_id_field if assignment_id_params
            query_conditions << context_id_field if course_id_params
          end

          query_conditions.join(" AND ")
        end
      end
    end
  end
end
