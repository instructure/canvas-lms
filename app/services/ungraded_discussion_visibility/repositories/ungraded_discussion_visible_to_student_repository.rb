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

module UngradedDiscussionVisibility
  module Repositories
    class UngradedDiscussionVisibleToStudentRepository
      class << self
        def visibility_query(course_ids:, user_ids:, discussion_topic_ids:)
          filter_condition_sql = filter_condition_sql(course_ids:, user_ids:, discussion_topic_ids:)
          query_sql = <<~SQL.squish

            /* discussion topics visible to everyone */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join context modules */
            #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "DiscussionTopic")}

            /* join assignment override */
            #{VisibilitySqlHelper.assignment_override_everyone_join_sql}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_everyone_filter_sql(filter_condition_sql:)}

            UNION

            /* discussion topics visible to sections */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                VisibilitySqlHelper.full_section_without_left_joins_sql(filter_condition_sql:, id_column_name: "discussion_topic_id", table_name: DiscussionTopic)
              else
                VisibilitySqlHelper.full_section_with_left_joins_sql(filter_condition_sql:, id_column_name: "discussion_topic_id", content_tag_type: "DiscussionTopic")
              end}

            EXCEPT

            /* remove students with unassigned section overrides */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'CourseSection' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_section_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

            /* non collaborative groups */
            /* incorporate non_collaborative groups if account feature flag is enabled */
            #{non_collaborative_group_union_sql(filter_condition_sql) if VisibilitySqlHelper.assign_to_differentiation_tags_enabled?(course_ids)}

            UNION

            /* discussion topics with adhoc overrides */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            #{if Account.site_admin.feature_enabled?(:visibility_performance_improvements)
                VisibilitySqlHelper.full_adhoc_without_left_joins_sql(filter_condition_sql:, id_column_name: "discussion_topic_id", table_name: DiscussionTopic)
              else
                VisibilitySqlHelper.full_adhoc_with_left_joins_sql(filter_condition_sql:, id_column_name: "discussion_topic_id", content_tag_type: "DiscussionTopic")
              end}

            EXCEPT

            /* remove students with unassigned adhoc overrides */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment overrides for 'ADHOC' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_adhoc_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}

            UNION

            /* discussion topics with course overrides */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'Course' */
            #{VisibilitySqlHelper.assignment_override_course_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.course_override_filter_sql(filter_condition_sql:)}
          SQL

          query_params = query_params(course_ids:, user_ids:, discussion_topic_ids:)
          exec_find_discussion_topic_visibility_query(query_sql:, query_params:)
        end

        private

        def exec_find_discussion_topic_visibility_query(query_sql:, query_params:)
          # safely replace parameters in the filter clause
          sanitized_sql = ActiveRecord::Base.sanitize_sql_array([query_sql, query_params])
          # Execute the query
          query_results = ActiveRecord::Base.connection.exec_query(sanitized_sql)
          # map the results to an array of AssignmentVisibleToStudent (DTO / PORO) and return it
          query_results.map do |row|
            UngradedDiscussionVisibility::Entities::UngradedDiscussionVisibleToStudent.new(course_id: row["course_id"], discussion_topic_id: row["discussion_topic_id"], user_id: row["user_id"])
          end
        end

        def query_params(course_ids:, user_ids:, discussion_topic_ids:)
          query_params = {}
          query_params[:course_id] = course_ids unless course_ids.nil?
          query_params[:user_id] = user_ids unless user_ids.nil?
          query_params[:discussion_topic_id] = discussion_topic_ids unless discussion_topic_ids.nil?
          query_params
        end

        # Create a filter clause SQL from the params - something like: e.user_id IN ['1', '2'] AND course_id = '20'
        # Note that at least one of the params must be non nil
        def filter_condition_sql(course_ids: nil, user_ids: nil, discussion_topic_ids: nil)
          query_conditions = []
          query_conditions << "o.id IN (:discussion_topic_id)" if discussion_topic_ids
          query_conditions << "e.user_id IN (:user_id)" if user_ids
          query_conditions << "e.course_id IN (:course_id)" if course_ids
          query_conditions.join(" AND ")
        end

        def discussion_topic_select_sql
          <<~SQL.squish
            SELECT DISTINCT o.id as discussion_topic_id,
            e.user_id as user_id,
            e.course_id as course_id
            FROM #{DiscussionTopic.quoted_table_name} o
          SQL
        end

        def non_collaborative_group_union_sql(filter_condition_sql)
          <<~SQL.squish
            UNION

            /* discussion topics visible to non collaborative groups */
            /* selecting discussion topics */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join context modules */
            #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "DiscussionTopic")}

            /* join assignment overrides for non collaborative 'Group' */
            #{VisibilitySqlHelper.assignment_override_non_collaborative_group_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_non_collaborative_group_filter_sql(filter_condition_sql:)}

            EXCEPT

            /* remove students with unassigned non collaborative groups overrides */
            /* selecting discussion topics */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for non collaborative 'Group' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_non_collaborative_group_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_filter_sql(filter_condition_sql:)}
          SQL
        end
      end
    end
  end
end
