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

module SupportHelpers
  class AssetProcessorDiscussionNoticeResubmission < Fixer
    def initialize(email, after_time, context, tool_id = nil)
      if context.is_a?(DiscussionTopic) || context.is_a?(Course)
        @context = context
      else
        raise ArgumentError, "context must be a DiscussionTopic or Course"
      end
      @tool_id = tool_id
      super(email, after_time)
    end

    def fix
      if @context.is_a?(DiscussionTopic)
        process_discussion_topic(@context)
      else
        # Get all discussion topics for the course that have assignments with asset processors
        discussion_topic_ids = @context.discussion_topics
                                       .where.not(assignment_id: nil)
                                       .pluck(:id, :assignment_id)

        return if discussion_topic_ids.empty?

        # Filter to only assignments that have asset processors
        assignment_ids = discussion_topic_ids.map(&:last).uniq
        asset_processor_assignment_ids = Lti::AssetProcessor.active
                                                            .where(assignment_id: assignment_ids)
                                                            .distinct
                                                            .pluck(:assignment_id)

        return if asset_processor_assignment_ids.empty?

        # Get discussion topics with asset processors, in batches
        DiscussionTopic.where(assignment_id: asset_processor_assignment_ids)
                       .preload(assignment: :lti_asset_processors)
                       .find_each do |topic|
                         process_discussion_topic(topic)
        end
      end
    end

    private

    def process_discussion_topic(topic)
      return unless topic.assignment&.discussion_topic?

      asset_processors = topic.assignment.lti_asset_processors.active
      asset_processors = asset_processors.where(context_external_tool_id: @tool_id) if @tool_id.present?
      return if asset_processors.empty?

      discussion_entry_ids = topic.discussion_entries.active.pluck(:id)
      return if discussion_entry_ids.empty?

      latest_version_ids = DiscussionEntryVersion
                           .where(discussion_entry_id: discussion_entry_ids)
                           .select("DISTINCT ON (discussion_entry_id) id")
                           .order(:discussion_entry_id, version: :desc)
                           .map(&:id)

      return if latest_version_ids.empty?

      user_ids = DiscussionEntryVersion.where(id: latest_version_ids).distinct.pluck(:user_id).compact
      submissions_by_user_id = topic.assignment.submissions.active
                                    .where(user_id: user_ids)
                                    .index_by(&:user_id)

      DiscussionEntryVersion
        .where(id: latest_version_ids)
        .preload(:discussion_entry, :user, :root_account)
        .find_each do |discussion_entry_version|
          next unless discussion_entry_version.discussion_entry
          next unless discussion_entry_version.user

          # Get submission - may be nil for teacher comments
          submission = submissions_by_user_id[discussion_entry_version.user_id]

          Lti::AssetProcessorDiscussionNotifier.notify_asset_processors_of_discussion(
            assignment: topic.assignment,
            submission:,
            discussion_entry_versions: [discussion_entry_version],
            contribution_status: Lti::Pns::LtiAssetProcessorContributionNoticeBuilder::SUBMITTED,
            current_user: discussion_entry_version.user,
            asset_processor: nil,
            tool_id: @tool_id
          )
      end
    end
  end
end
