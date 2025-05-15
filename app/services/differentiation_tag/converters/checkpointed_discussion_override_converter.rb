# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

module DifferentiationTag
  module Converters
    class CheckpointedDiscussionOverrideConverter < TagOverrideConverter
      class << self
        def convert_tags_to_adhoc_overrides(checkpointed_discussion, course)
          @parent_assignment = checkpointed_discussion
          @course = course
          @prepared_overrides = nil
          @reply_to_topic = checkpointed_discussion.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_TOPIC)
          @reply_to_entry = checkpointed_discussion.sub_assignments.find_by(sub_assignment_tag: CheckpointLabels::REPLY_TO_ENTRY)

          begin
            prepare_overrides
            convert_overrides
          rescue DifferentiationTagServiceError => e
            return e.message
          end

          # no errors
          nil
        end

        private

        def prepare_overrides
          tag_overrides = differentiation_tag_overrides_for(@parent_assignment)
          return unless tag_overrides.present?

          tags = tag_overrides.map(&:set)
          students_to_override = find_students_to_override(tags)
          return if students_to_override.empty?

          @prepared_overrides = build_overrides(students_to_override, tag_overrides, tags)
        end

        def convert_overrides
          ActiveRecord::Base.transaction do
            @prepared_overrides&.each do |override_data|
              topic_override = override_data[:topic_override]
              entry_override = override_data[:entry_override]

              # Use Checkpoints::AdhocOverrideCreatorService to create the overrides
              Checkpoints::AdhocOverrideCreatorService.call(checkpoint: @reply_to_topic, override: topic_override)
              Checkpoints::AdhocOverrideCreatorService.call(checkpoint: @reply_to_entry, override: entry_override)
            end

            # Destroy all tag overrides for the parent assignment, topic, and entry
            destroy_checkpointed_discussion_tag_overrides
          end
        end

        def build_overrides(students_to_override, tag_overrides, tags)
          overrides = []

          students_in_multiple_tags = find_students_in_multiple_tags(students_to_override, tags)

          # Build overrides for students in ONE tag only
          overrides += build_single_tag_overrides(students_to_override, students_in_multiple_tags, tag_overrides)

          # Build overrides for students in MULTIPLE tags
          overrides += build_multiple_tag_overrides(students_in_multiple_tags)

          overrides
        end

        def find_students_to_override(tags)
          students = find_students_in_tags(tags)
          students_with_adhoc_override = find_students_with_adhoc_override(students)

          students.reject! { |student| students_with_adhoc_override.include?(student) }

          return [] if students.empty?

          students
        end

        def build_single_tag_overrides(students_to_override, students_in_multiple_tags, tag_overrides)
          overrides = []

          tag_overrides.each do |tag_override|
            tag = tag_override.set
            students_in_tag = find_students_in_tags([tag])

            students_in_tag.reject! { |student| students_in_multiple_tags.key?(student) || !students_to_override.include?(student) }
            next if students_in_tag.empty?

            # Grab dates from tag overrides for ADHOC overrides
            overrides_for_tag = checkpoint_tag_overrides(tag)
            topic_override = build_adhoc_override(overrides_for_tag[:topic], students_in_tag.to_a)
            entry_override = build_adhoc_override(overrides_for_tag[:entry], students_in_tag.to_a)

            overrides.push({ topic_override:, entry_override: })
          end

          overrides
        end

        def build_multiple_tag_overrides(students_in_multiple_tags)
          overrides = []

          students_in_multiple_tags.each_key do |student_id|
            tag_ids = students_in_multiple_tags[student_id]

            latest_topic_due_at = get_latest_due_date(tag_ids, :topic)
            latest_entry_due_at = get_latest_due_date(tag_ids, :entry)
            unlock_at = get_availablity_date(tag_ids, :unlock_at)
            lock_at = get_availablity_date(tag_ids, :lock_at)

            topic_override_dates = { due_at: latest_topic_due_at, unlock_at:, lock_at: }
            entry_override_dates = { due_at: latest_entry_due_at, unlock_at:, lock_at: }

            # check if there already exists an override for these exact dates
            existing_override = overrides.find do |override|
              override[:topic_override][:due_at] == latest_topic_due_at &&
                override[:entry_override][:due_at] == latest_entry_due_at &&
                override[:topic_override][:unlock_at] == unlock_at &&
                override[:topic_override][:lock_at] == lock_at
            end

            if existing_override
              existing_override[:topic_override][:student_ids] << student_id
              existing_override[:entry_override][:student_ids] << student_id
            else
              topic_override = build_adhoc_override(topic_override_dates, [student_id])
              entry_override = build_adhoc_override(entry_override_dates, [student_id])

              overrides.push({ topic_override:, entry_override: })
            end
          end

          overrides
        end

        def build_adhoc_override(tag_override, students)
          {
            type: "override",
            unlock_at: tag_override[:unlock_at],
            lock_at: tag_override[:lock_at],
            unassign_item: tag_override[:unassign_item] || false,
            set_type: "ADHOC",
            student_ids: students,
            due_at: tag_override[:due_at],
          }
        end

        def find_students_with_adhoc_override(students)
          adhoc_overrides = @parent_assignment.assignment_overrides.active.adhoc

          students.select do |student|
            adhoc_overrides.any? do |override|
              override.assignment_override_students.map(&:user_id).include?(student)
            end
          end
        end

        def find_students_in_multiple_tags(students, tags)
          tag_ids = tags.map(&:id)

          # This query finds all tags that a user belongs to.
          # The user must be a member of more than one tag to appear in the results.
          query = <<~SQL.squish
            SELECT user_id, array_agg(group_id) as tag_ids
            FROM #{GroupMembership.quoted_table_name} AS gm
            WHERE gm.workflow_state = 'accepted'
              AND gm.user_id IN (
                SELECT user_id
                FROM #{GroupMembership.quoted_table_name}
                WHERE workflow_state = 'accepted'
                  AND group_id IN (#{tag_ids.join(",")})
                  AND user_id IN (#{students.join(",")})
                GROUP BY user_id
                HAVING COUNT(group_id) > 1
              )
            GROUP BY user_id
          SQL

          students_in_multiple_tags = {}

          GroupMembership.connection.execute(query).to_a.each do |row|
            user_id = row["user_id"].to_i

            # Skip if the user is not in the provided students list
            next unless students.include?(user_id)

            # Convert the tag_ids from a string to an array of integers
            # Assuming tag_ids are stored as a string like "{1,2,3}"
            tag_ids = tag_ids = row["tag_ids"].tr("{}", "").split(",").map(&:to_i)

            students_in_multiple_tags[user_id] ||= tag_ids
          end

          students_in_multiple_tags
        end

        def checkpoint_tag_overrides(tag)
          topic_tag_override = @reply_to_topic.assignment_overrides.active.find_by(set_type: "Group", set_id: tag.id)
          entry_tag_override = @reply_to_entry.assignment_overrides.active.find_by(set_type: "Group", set_id: tag.id)

          {
            topic: topic_tag_override,
            entry: entry_tag_override
          }
        end

        def get_latest_due_date(tag_ids, checkpoint)
          overrides = if checkpoint == :topic
                        @reply_to_topic.assignment_overrides.active.where(set_type: "Group", set_id: tag_ids)
                      else
                        @reply_to_entry.assignment_overrides.active.where(set_type: "Group", set_id: tag_ids)
                      end

          overrides = sort_overrides(overrides:, sort_by: :due_at)

          # latest due date is the first one in the sorted list
          overrides.first.due_at
        end

        def get_availablity_date(tag_ids, date_type)
          overrides = @parent_assignment.assignment_overrides.active.where(set_type: "Group", set_id: tag_ids)

          overrides = sort_overrides(overrides:, sort_by: date_type)
          overrides.first.send(date_type)
        end

        def destroy_checkpointed_discussion_tag_overrides
          parent_assignment_tag_overrides = differentiation_tag_overrides_for(@parent_assignment)
          topic_tag_overrides = differentiation_tag_overrides_for(@reply_to_topic)
          entry_tag_overrides = differentiation_tag_overrides_for(@reply_to_entry)

          # Destroy all tag overrides for the parent assignment, topic, and entry
          destroy_differentiation_tag_overrides(parent_assignment_tag_overrides)
          destroy_differentiation_tag_overrides(topic_tag_overrides)
          destroy_differentiation_tag_overrides(entry_tag_overrides)
        end
      end
    end
  end
end
