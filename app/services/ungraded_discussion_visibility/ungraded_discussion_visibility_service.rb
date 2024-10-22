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
  class UngradedDiscussionVisibilityService
    extend VisibilityHelpers::Common
    class << self
      def discussion_topics_visible_to_student_in_course(course_id:, user_id:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        discussion_topics_visible(course_id_params: course_id, user_id_params: user_id)
      end

      def discussion_topics_visible_to_students(user_ids:)
        raise ArgumentError, "user_id cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_id must be an array" unless user_ids.is_a?(Array)

        discussion_topics_visible(user_id_params: user_ids)
      end

      def discussion_topics_visible_to_students_in_courses(course_ids:, user_ids:)
        raise ArgumentError, "course_ids cannot be nil" if course_ids.nil?
        raise ArgumentError, "course_ids must be an array" unless course_ids.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        discussion_topics_visible(course_id_params: course_ids, user_id_params: user_ids)
      end

      def discussion_topics_visible_to_students_in_course(course_id:, user_ids:)
        raise ArgumentError, "course_id cannot be nil" if course_id.nil?
        raise ArgumentError, "course_id must not be an array" if course_id.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        discussion_topics_visible(course_id_params: course_id, user_id_params: user_ids)
      end

      def discussion_topic_visible_to_student(discussion_topic_id:, user_id:)
        raise ArgumentError, "discussion_topic_id cannot be nil" if discussion_topic_id.nil?
        raise ArgumentError, "discussion_topic_id must not be an array" if discussion_topic_id.is_a?(Array)
        raise ArgumentError, "user_id cannot be nil" if user_id.nil?
        raise ArgumentError, "user_id must not be an array" if user_id.is_a?(Array)

        discussion_topics_visible(discussion_topic_id_params: discussion_topic_id, user_id_params: user_id)
      end

      def discussion_topic_visible_to_students(discussion_topic_id:, user_ids:)
        raise ArgumentError, "discussion_topic_id cannot be nil" if discussion_topic_id.nil?
        raise ArgumentError, "discussion_topic_id must not be an array" if discussion_topic_id.is_a?(Array)
        raise ArgumentError, "user_ids cannot be nil" if user_ids.nil?
        raise ArgumentError, "user_ids must be an array" unless user_ids.is_a?(Array)

        discussion_topics_visible(discussion_topic_id_params: discussion_topic_id, user_id_params: user_ids)
      end

      private

      def discussion_topics_visible(course_id_params: nil, user_id_params: nil, discussion_topic_id_params: nil)
        if course_id_params.nil? && user_id_params.nil? && discussion_topic_id_params.nil?
          raise ArgumentError, "at least one non nil course_id, user_id, or discussion_topic_id_params is required (for query performance reasons)"
        end

        service_cache_fetch(service: name,
                            course_id_params:,
                            user_id_params:,
                            additional_id_params: discussion_topic_id_params) do
          if Account.site_admin.feature_enabled?(:selective_release_optimized_services_v3)
            UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository.full_discussion_topic_visibility_query(course_id_params:, user_id_params:, discussion_topic_id_params:)
          elsif Account.site_admin.feature_enabled?(:selective_release_optimized_services_v2)
            visible_discussion_topics = []

            # add discussion topics visible to everyone
            discussion_topics_visible_to_all = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                               .find_discussion_topics_visible_to_everyone(course_id_params:, user_id_params:, discussion_topic_id_params:)
            visible_discussion_topics |= discussion_topics_visible_to_all

            # add discussion topics assigned to sections, students, or the course
            discussion_topics_assigned_to_others = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                   .find_discussion_topics_assigned_to_others(course_id_params:, user_id_params:, discussion_topic_id_params:)

            visible_discussion_topics | discussion_topics_assigned_to_others
          else
            visible_discussion_topics = []

            # add discussion topics visible to everyone
            discussion_topics_visible_to_all = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                               .find_discussion_topics_visible_to_everyone(course_id_params:, user_id_params:, discussion_topic_id_params:)
            visible_discussion_topics |= discussion_topics_visible_to_all

            if Account.site_admin.feature_enabled?(:selective_release_optimized_services)
              # add discussion topics visible to sections (and related module section overrides) without unassign overrides
              discussion_topics_assigned_to_sections = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                       .find_discussion_topics_assigned_to_sections(course_id_params:, user_id_params:, discussion_topic_id_params:)
              visible_discussion_topics |= discussion_topics_assigned_to_sections
            else
              # add discussion topics visible to sections (and related module section overrides)
              discussion_topics_visible_to_sections = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                      .find_discussion_topics_visible_to_sections(course_id_params:, user_id_params:, discussion_topic_id_params:)
              visible_discussion_topics |= discussion_topics_visible_to_sections

              # remove discussion topics for students with unassigned section overrides
              discussion_topics_with_unassigned_section_overrides = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                                    .find_discussion_topics_with_unassigned_section_overrides(course_id_params:, user_id_params:, discussion_topic_id_params:)
              visible_discussion_topics -= discussion_topics_with_unassigned_section_overrides
            end

            if Account.site_admin.feature_enabled?(:selective_release_optimized_services)
              # add discussion topics visible due to ADHOC overrides (and related module ADHOC overrides) without unassign overrides
              discussion_topics_assigned_to_adhoc_overrides = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                              .find_discussion_topics_assigned_to_adhoc_overrides(course_id_params:, user_id_params:, discussion_topic_id_params:)
              visible_discussion_topics |= discussion_topics_assigned_to_adhoc_overrides
            else
              # add discussion topics visible due to ADHOC overrides (and related module ADHOC overrides)
              discussion_topics_visible_to_adhoc_overrides = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                             .find_discussion_topics_visible_to_adhoc_overrides(course_id_params:, user_id_params:, discussion_topic_id_params:)
              visible_discussion_topics |= discussion_topics_visible_to_adhoc_overrides

              # remove discussion topics for students with unassigned ADHOC overrides
              discussion_topics_with_unassigned_adhoc_overrides = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                                  .find_discussion_topics_with_unassigned_adhoc_overrides(course_id_params:, user_id_params:, discussion_topic_id_params:)
              visible_discussion_topics -= discussion_topics_with_unassigned_adhoc_overrides
            end

            # add discussion topics visible due to course overrides
            discussion_topics_visible_to_course_overrides = UngradedDiscussionVisibility::Repositories::UngradedDiscussionVisibleToStudentRepository
                                                            .find_discussion_topics_visible_to_course_overrides(course_id_params:, user_id_params:, discussion_topic_id_params:)

            visible_discussion_topics | discussion_topics_visible_to_course_overrides
          end
        end
      end
    end
  end
end
