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

module WikiPageVisibility
  module Repositories
    class WikiPageVisibleToStudentRepository
      class << self
        def visibility_query(course_ids:, user_ids:, wiki_page_ids:)
          filter_condition_sql = filter_condition_sql(course_ids:, user_ids:, wiki_page_ids:)

          query_sql = <<~SQL.squish
            /* wiki pages visible to everyone */
              #{wiki_page_select_sql}

              /* join active student enrollments */
              #{VisibilitySqlHelper.enrollment_join_sql}

              /* join context modules */
              #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "WikiPage")}

              /* join assignment override */
              #{VisibilitySqlHelper.assignment_override_everyone_join_sql}

              /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
              #{VisibilitySqlHelper.assignment_override_everyone_filter_sql(filter_condition_sql:)}

              UNION

              /* wiki pages visible to sections */
              #{wiki_page_select_sql}

              /* join active student enrollments */
              #{VisibilitySqlHelper.enrollment_join_sql}

              #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                  VisibilitySqlHelper.full_section_without_left_joins_sql(filter_condition_sql:, id_column_name: "wiki_page_id", table_name: WikiPage)
                else
                  VisibilitySqlHelper.full_section_with_left_joins_sql(filter_condition_sql:, id_column_name: "wiki_page_id", content_tag_type: "WikiPage")
                end}

              EXCEPT

              /* remove students with unassigned section overrides */
              #{wiki_page_select_sql}

              /* join active student enrollments */
              #{VisibilitySqlHelper.enrollment_join_sql}

              /* join assignment override for 'CourseSection' (no module check) */
              #{VisibilitySqlHelper.assignment_override_unassign_section_join_sql(id_column_name: "wiki_page_id")}

              /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
              #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

              UNION

              /* wiki pages with adhoc overrides */
              #{wiki_page_select_sql}

              /* join active student enrollments */
              #{VisibilitySqlHelper.enrollment_join_sql}

              #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                  VisibilitySqlHelper.full_adhoc_without_left_joins_sql(filter_condition_sql:, id_column_name: "wiki_page_id", table_name: WikiPage)
                else
                  VisibilitySqlHelper.full_adhoc_with_left_joins_sql(filter_condition_sql:, id_column_name: "wiki_page_id", content_tag_type: "WikiPage")
                end}

              EXCEPT

              /* remove students with unassigned adhoc overrides */
              #{wiki_page_select_sql}

              /* join active student enrollments */
              #{VisibilitySqlHelper.enrollment_join_sql}

              /* join assignment overrides for 'ADHOC' (no module check) */
              #{VisibilitySqlHelper.assignment_override_unassign_adhoc_join_sql(id_column_name: "wiki_page_id")}

              /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
              #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

              /* non collaborative groups */
              /* incorporate non_collaborative groups if account feature flag is enabled */
              #{non_collaborative_group_union_sql(filter_condition_sql) if VisibilitySqlHelper.assign_to_differentiation_tags_enabled?(course_ids)}

              UNION

              /* wiki pages with course overrides */
              #{wiki_page_select_sql}

              /* join active student enrollments */
              #{VisibilitySqlHelper.enrollment_join_sql}

              /* join assignment override for 'Course' */
              #{VisibilitySqlHelper.assignment_override_course_join_sql(id_column_name: "wiki_page_id")}

              /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
              #{VisibilitySqlHelper.course_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_ids:, user_ids:, wiki_page_ids:)
          exec_find_wiki_page_visibility_query(query_sql:, query_params:)
        end

        private

        def exec_find_wiki_page_visibility_query(query_sql:, query_params:)
          # safely replace parameters in the filter clause
          sanitized_sql = ActiveRecord::Base.sanitize_sql_array([query_sql, query_params])

          # Execute the query
          query_results = ActiveRecord::Base.connection.exec_query(sanitized_sql)

          # map the results to an array of AssignmentVisibleToStudent (DTO / PORO) and return it
          query_results.map do |row|
            WikiPageVisibility::Entities::WikiPageVisibleToStudent.new(course_id: row["course_id"], wiki_page_id: row["wiki_page_id"], user_id: row["user_id"])
          end
        end

        def query_params(course_ids:, user_ids:, wiki_page_ids:)
          query_params = {}
          query_params[:course_id] = course_ids unless course_ids.nil?
          query_params[:user_id] = user_ids unless user_ids.nil?
          query_params[:wiki_page_id] = wiki_page_ids unless wiki_page_ids.nil?
          query_params
        end

        # Create a filter clause SQL from the params - something like: e.user_id IN ['1', '2'] AND course_id = '20'
        # Note that at least one of the params must be non nil
        def filter_condition_sql(course_ids: nil, user_ids: nil, wiki_page_ids: nil)
          query_conditions = []
          query_conditions << "o.id IN (:wiki_page_id)" if wiki_page_ids
          query_conditions << "e.user_id IN (:user_id)" if user_ids
          query_conditions << "e.course_id IN (:course_id)" if course_ids
          query_conditions.join(" AND ")
        end

        def wiki_page_select_sql
          <<~SQL.squish
            SELECT DISTINCT o.id as wiki_page_id,
            e.user_id as user_id,
            e.course_id as course_id
            FROM #{WikiPage.quoted_table_name} o
          SQL
        end

        def non_collaborative_group_union_sql(filter_condition_sql)
          <<~SQL.squish
            UNION

            /* wiki pages visible to non collaborative groups */
            /* selecting wiki pages */
            #{wiki_page_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join context modules */
            #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "WikiPage")}

            /* join assignment overrides for non collaborative 'Group' */
            #{VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "wiki_page_id")}

            /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_non_collaborative_group_filter_sql(filter_condition_sql:)}

            EXCEPT

            /* remove students with unassigned non collaborative groups overrides */
            /* selecting wiki pages */
            #{wiki_page_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for non collaborative 'Group' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_non_collaborative_group_join_sql(id_column_name: "wiki_page_id")}

            /* filtered to course_id, user_id, wiki_page_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}
          SQL
        end
      end
    end
  end
end
