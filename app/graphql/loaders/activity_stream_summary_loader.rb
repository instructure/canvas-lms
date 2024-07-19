# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
#

class Loaders::ActivityStreamSummaryLoader < GraphQL::Batch::Loader
  def initialize(current_user:)
    super()
    @current_user = current_user
  end

  def perform(objects)
    opts = { contexts: [objects] }
    items = calculate_stream_summaries(opts)

    objects.each do |object|
      # Only allow batch loading for Course objects
      if object.nil? || !object.is_a?(Course)
        fulfill(object, nil)
        return
      end
      current_summary = items[object.id.to_s] || []
      fulfill(object, current_summary)
    end
  end

  private

  # Calculates stream summaries for multiple contexts
  # This function is based on the calculate_stream_summary method in lib/v1/stream_item,
  # adapted to handle multiple contexts for batch loading
  def calculate_stream_summaries(opts)
    GuardRail.activate(:secondary) do
      @current_user.shard.activate do
        base_scope = @current_user.visible_stream_item_instances(opts).joins(:stream_item)

        full_counts = base_scope.except(:order).group("stream_items.asset_type",
                                                      "stream_items.notification_category",
                                                      "stream_item_instances.workflow_state",
                                                      "stream_item_instances.context_id").count
        # as far as I can tell, the 'type' column previously extracted by stream_item_json is identical to asset_type
        # oh wait, except for Announcements -_-
        if full_counts.keys.any? { |k| k[0] == "DiscussionTopic" }
          ann_counts = base_scope.where(stream_items: { asset_type: "DiscussionTopic" })
                                 .joins("INNER JOIN #{DiscussionTopic.quoted_table_name} ON discussion_topics.id=stream_items.asset_id")
                                 .where(discussion_topics: { type: "Announcement" }).except(:order).group("stream_item_instances.workflow_state", "stream_item_instances.context_id").count

          ann_counts.each do |(wf_state, context_id), ann_count|
            full_counts[["Announcement", nil, wf_state, context_id]] = ann_count
            full_counts[["DiscussionTopic", nil, wf_state, context_id]] -= ann_count # subtract the announcement count from the "true" discussion topics
          end
        end

        # Aggregate counts by context_id and type
        total_counts = {}
        unread_counts = {}
        full_counts.each do |k, count|
          type, category, wf_state, context_id = k
          context_id = context_id.to_s

          total_counts[context_id] ||= {}
          total_counts[context_id][type] ||= { count: 0, category: }
          total_counts[context_id][type][:count] += count

          next unless wf_state == "unread"

          unread_counts[context_id] ||= {}
          unread_counts[context_id][type] ||= 0
          unread_counts[context_id][type] += count
        end

        cross_shard_totals, cross_shard_unreads = calculate_cross_shard_stream_item_counts(opts)
        cross_shard_totals.each do |context_id, types|
          total_counts[context_id] ||= {}
          types.each do |type, data|
            total_counts[context_id][type] ||= { count: 0, category: data[:category] }
            total_counts[context_id][type][:count] += data[:count]
          end
        end
        cross_shard_unreads.each do |context_id, types|
          unread_counts[context_id] ||= {}
          types.each do |type, count|
            unread_counts[context_id][type] ||= 0
            unread_counts[context_id][type] += count
          end
        end

        items = {}
        total_counts.each do |context_id, types|
          items[context_id] = []
          types.each do |type, data|
            items[context_id] << { type:,
                                   notification_category: data[:category],
                                   count: data[:count],
                                   unread_count: (unread_counts[context_id] && unread_counts[context_id][type]) || 0 }
          end
          items[context_id].sort_by! { |i| i[:type] }
        end
        items
      end
    end
  end

  # Calculates cross-shard stream item counts for multiple contexts
  # This function is based on the cross_shard_stream_item_counts method in lib/v1/stream_item,
  # adapted to handle multiple contexts for batch loading
  def calculate_cross_shard_stream_item_counts(opts)
    total_counts = {}
    unread_counts = {}
    stream_item_ids = @current_user.visible_stream_item_instances(opts)
                                   .where("stream_item_id > ?", Shard::IDS_PER_SHARD).pluck(:stream_item_id, :context_id)
    if stream_item_ids.any?
      unread_stream_item_ids = @current_user.visible_stream_item_instances(opts)
                                            .where("stream_item_id > ?", Shard::IDS_PER_SHARD)
                                            .where(workflow_state: "unread").pluck(:stream_item_id, :context_id)

      grouped_stream_item_ids = stream_item_ids.group_by { |_, context_id| context_id.to_s }
      grouped_unread_stream_item_ids = unread_stream_item_ids.group_by { |_, context_id| context_id.to_s }

      grouped_stream_item_ids.each do |context_id, items|
        item_ids = items.map(&:first)
        context_total_counts = StreamItem.where(id: item_ids).except(:order).group(:asset_type, :notification_category).count
        total_counts[context_id] = {}
        context_total_counts.each do |(asset_type, category), count|
          total_counts[context_id][asset_type] = { count:, category: }
        end

        if grouped_unread_stream_item_ids[context_id]
          unread_item_ids = grouped_unread_stream_item_ids[context_id].map(&:first)
          context_unread_counts = StreamItem.where(id: unread_item_ids).except(:order).group(:asset_type).count
          unread_counts[context_id] = context_unread_counts
        end

        next unless context_total_counts.keys.any? { |k| k[0] == "DiscussionTopic" }

        ann_scope = StreamItem.where(stream_items: { asset_type: "DiscussionTopic" })
                              .joins(:discussion_topic)
                              .where(discussion_topics: { type: "Announcement" })
        ann_total = ann_scope.where(id: item_ids).count
        next unless ann_total > 0

        total_counts[context_id]["Announcement"] = { count: ann_total, category: nil }
        total_counts[context_id]["DiscussionTopic"][:count] -= ann_total

        next unless grouped_unread_stream_item_ids[context_id]

        ann_unread = ann_scope.where(id: unread_item_ids).count
        if ann_unread > 0
          unread_counts[context_id]["Announcement"] = ann_unread
          unread_counts[context_id]["DiscussionTopic"] -= ann_unread
        end
      end
    end
    [total_counts, unread_counts]
  end
end
