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
        def visibility_query(course_ids:, user_ids:, assignment_ids:, include_concluded: true)
          filter_condition_sql = filter_condition_sql(course_ids:, user_ids:, assignment_ids:)
          query_sql = <<~SQL.squish
            WITH #{assignment_module_items_cte_sql(course_ids:, assignment_ids:)}

            /* assignments visible to everyone */
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql(include_concluded:)}

            /* (logical) join context modules */
            #{assignment_module_items_join_sql}

            /* join assignment override */
            #{VisibilitySqlHelper.assignment_override_everyone_join_sql}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_everyone_filter_sql(filter_condition_sql:)}

            UNION

            /* assignments visible to groups */
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql(include_concluded:)}

            /* join context modules */
            #{assignment_module_items_join_sql}

            /* join assignment group overrides */
            #{VisibilitySqlHelper.assign_to_differentiation_tags_enabled?(course_ids) ? assignment_group_override_join_sql : assignment_group_override_join_sql(collaborative_group_filter: "AND g.non_collaborative = FALSE")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{assignment_group_override_filter_sql(filter_condition_sql:)}

            UNION

            /* assignments visible to sections */
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql(include_concluded:)}

            #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                VisibilitySqlHelper.full_section_without_left_joins_sql(filter_condition_sql:, id_column_name: "assignment_id", table_name: Assignment)
              else
                section_overrides_with_left_joins_sql(filter_condition_sql:)
              end}

            EXCEPT

            /* remove assignments with unassigned section overrides */
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql(include_concluded:)}

            /* join assignment override for 'CourseSection' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_section_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

            UNION

            /* assignments visible to adhoc overrides */
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql(include_concluded:)}

            /* assignments visible to adhoc overrides */
            #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                VisibilitySqlHelper.full_adhoc_without_left_joins_sql(filter_condition_sql:, id_column_name: "assignment_id", table_name: Assignment)
              else
                adhoc_overrides_with_left_joins_sql(filter_condition_sql:)
              end}

            EXCEPT

            /* remove assignments with unassigned adhoc overrides */
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql(include_concluded:)}

            /* join assignment overrides for 'ADHOC' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_adhoc_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

            UNION

            /* assignments visible to course overrides */
            #{assignment_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql(include_concluded:)}

            /* join assignment override for 'Course' */
            #{VisibilitySqlHelper.assignment_override_course_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.course_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_ids:, user_ids:, assignment_ids:)
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

        def query_params(course_ids:, user_ids:, assignment_ids:)
          query_params = {}
          query_params[:course_id] = course_ids if course_ids
          query_params[:user_id] = user_ids if user_ids
          query_params[:assignment_id] = assignment_ids if assignment_ids
          query_params
        end

        # Create a filter clause SQL from the params - something like: e.user_id IN ['1', '2'] AND course_id = '20'
        # Note that at least one of the params must be non nil
        def filter_condition_sql(course_ids: nil, user_ids: nil, assignment_ids: nil)
          query_conditions = []
          query_conditions << "o.id IN (:assignment_id)" if assignment_ids
          query_conditions << "e.user_id IN (:user_id)" if user_ids
          query_conditions << "e.course_id IN (:course_id)" if course_ids
          query_conditions.join(" AND ")
        end

        # assignments utilize a CTE which gathers associated content tags since their tags can come directly
        # from the assignment or from the assignment's associated objects
        def assignment_module_items_cte_sql(course_ids: nil, assignment_ids: nil)
          <<~SQL.squish
            assignment_tags AS (
                     SELECT
                         t.content_id AS assignment_id,
                         t.context_module_id
                     FROM
                         #{ContentTag.quoted_table_name} AS t
                     WHERE
                         #{all_tags_filter_condition_sql(tag_type: "assignment", course_ids:, assignment_ids:)}
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
                         #{all_tags_filter_condition_sql(tag_type: "quiz", course_ids:, assignment_ids:)}
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
                         #{all_tags_filter_condition_sql(tag_type: "discussion", course_ids:, assignment_ids:)}
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
                         #{all_tags_filter_condition_sql(tag_type: "page", course_ids:, assignment_ids:)}
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

        def assignment_group_override_join_sql(collaborative_group_filter: nil)
          <<~SQL.squish
            INNER JOIN #{AssignmentOverride.quoted_table_name} ao
              ON (o.id = ao.assignment_id OR m.id = ao.context_module_id)
              AND ao.set_type = 'Group'
            INNER JOIN #{Group.quoted_table_name} g
              ON g.id = ao.set_id
              #{collaborative_group_filter unless collaborative_group_filter.nil?}
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

        def section_overrides_with_left_joins_sql(filter_condition_sql:)
          <<~SQL.squish
            /* (logical) join context modules */
            #{assignment_module_items_join_sql}

            /* join assignment overrides (assignment or related context module) for CourseSection */
            #{VisibilitySqlHelper.assignment_override_section_join_sql(id_column_name: "assignment_id")}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.section_override_filter_sql(filter_condition_sql:)}
          SQL
        end

        def adhoc_overrides_with_left_joins_sql(filter_condition_sql:)
          <<~SQL.squish
            /* (logical) join context modules */
            #{assignment_module_items_join_sql}

            /* join assignment override for 'ADHOC' */
            #{VisibilitySqlHelper.assignment_override_adhoc_join_sql(id_column_name: "assignment_id")}

            /* join AssignmentOverrideStudent */
            #{VisibilitySqlHelper.assignment_override_student_join_sql}

            /* filtered to course_id, user_id, assignment_id, and additional conditions */
            #{VisibilitySqlHelper.adhoc_override_filter_sql(filter_condition_sql:)}
          SQL
        end

        # create the right where filter for each type of content_tag based on given course_ids or assignment_ids
        def all_tags_filter_condition_sql(tag_type:, course_ids:, assignment_ids:)
          unless assignment_ids || course_ids
            raise ArgumentError, "AssignmentsVisibleToStudents must have a limiting where clause of at least one course_id or assignment_id (for performance reasons)"
          end

          query_conditions = []

          case tag_type
          when "assignment"
            query_conditions << "t.content_id IN (:assignment_id)" if assignment_ids
            query_conditions << "t.context_id IN (:course_id)" if course_ids
          when "quiz", "discussion", "page"
            query_conditions << "#{tag_type[0]}.assignment_id IN (:assignment_id)" if assignment_ids
            query_conditions << "#{tag_type[0]}t.context_id IN (:course_id)" if course_ids
          end

          query_conditions.join(" AND ")
        end
      end
    end
  end
end
