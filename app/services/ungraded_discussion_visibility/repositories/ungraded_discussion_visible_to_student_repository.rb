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

            /* join context modules */
            #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "DiscussionTopic")}

            /* join assignment overrides (assignment or related context module) for CourseSection */
            #{VisibilitySqlHelper.assignment_override_section_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.section_override_filter_sql(filter_condition_sql:)}

            EXCEPT

            /* remove students with unassigned section overrides */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment override for 'CourseSection' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_section_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_section_filter_sql(filter_condition_sql:)}

            UNION

            /* discussion topics with adhoc overrides */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join context modules */
            #{VisibilitySqlHelper.module_items_join_sql(content_tag_type: "DiscussionTopic")}

            /* join assignment override for 'ADHOC' */
            #{VisibilitySqlHelper.assignment_override_adhoc_join_sql(id_column_name: "discussion_topic_id")}

            /* join AssignmentOverrideStudent */
            #{VisibilitySqlHelper.assignment_override_student_join_sql}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.adhoc_override_filter_sql(filter_condition_sql:)}

            EXCEPT

            /* remove students with unassigned adhoc overrides */
            #{discussion_topic_select_sql}

            /* join active student enrollments */
            #{VisibilitySqlHelper.enrollment_join_sql}

            /* join assignment overrides for 'ADHOC' (no module check) */
            #{VisibilitySqlHelper.assignment_override_unassign_adhoc_join_sql(id_column_name: "discussion_topic_id")}

            /* filtered to course_id, user_id, discussion_topic_id, and additional conditions */
            #{VisibilitySqlHelper.assignment_override_unassign_adhoc_filter_sql(filter_condition_sql:)}

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

          if discussion_topic_ids
            query_conditions << if discussion_topic_ids.is_a?(Array)
                                  "o.id IN (:discussion_topic_id)"
                                else
                                  "o.id = :discussion_topic_id"
                                end
          end

          if user_ids
            query_conditions << if user_ids.is_a?(Array)
                                  "e.user_id IN (:user_id)"
                                else
                                  "e.user_id = :user_id"
                                end
          end

          if course_ids
            query_conditions << if course_ids.is_a?(Array)
                                  "e.course_id IN (:course_id)"
                                else
                                  "e.course_id = :course_id"
                                end
          end

          if query_conditions.empty?
            raise ArgumentError, "UngradedDiscussionsVisibleToStudents must have a limiting where clause of at least one course_id, user_id, or discussion_topic_id (for performance reasons)"
          end

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
      end
    end
  end
end
