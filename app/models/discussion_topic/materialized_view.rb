# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

# This model is used internally by DiscussionTopic, it's not intended to be
# queried directly by other code.
class DiscussionTopic::MaterializedView < ActiveRecord::Base
  class ReplicationTimeoutError < StandardError; end

  include Api::V1::DiscussionTopics
  include Api
  include Rails.application.routes.url_helpers
  def use_placeholder_host?
    true
  end

  serialize :participants_array, type: Array
  serialize :entry_ids_array, type: Array

  belongs_to :discussion_topic

  self.primary_key = :discussion_topic_id

  def self.for(discussion_topic)
    discussion_topic.shard.activate do
      # first try to pull the view from the secondary. we can't just do this in the
      # unique_constraint_retry since it begins a transaction.
      view = GuardRail.activate(:secondary) { where(discussion_topic_id: discussion_topic).first }
      unless view
        # if the view wasn't found, drop into the unique_constraint_retry
        # transaction loop on master.
        unique_constraint_retry do
          view = where(discussion_topic_id: discussion_topic).first ||
                 create!(discussion_topic:)
        end
      end
      view
    end
  end

  def self.materialized_view_for(discussion_topic, opts = {})
    view = self.for(discussion_topic)
    view.materialized_view_json(opts)
  end

  def up_to_date?
    updated_at.present? && updated_at >= discussion_topic.updated_at && json_structure.present?
  end

  def all_entries
    if discussion_topic.sort_by_rating
      discussion_topic.rated_discussion_entries
    else
      discussion_topic.discussion_entries
    end
  end

  def relativize_ids(ids)
    if shard.id == Shard.current.id
      ids
    else
      ids.map { |id| Shard.relative_id_for(id, shard, Shard.current) }
    end
  end

  def recursively_relativize_json_ids(data)
    data.map do |entry|
      entry["id"] = Shard.relative_id_for(entry["id"], shard, Shard.current).to_s
      if entry.key? "user_id"
        entry["user_id"] = Shard.relative_id_for(entry["user_id"], shard, Shard.current).to_s
      end
      if entry["replies"]
        entry["replies"] = recursively_relativize_json_ids(entry["replies"])
      end
      entry
    end
  end

  def relativize_json_structure_ids
    if shard.id == Shard.current.id
      json_structure
    else
      data = JSON.parse(json_structure)
      relativized = recursively_relativize_json_ids(data)
      JSON.dump(relativized)
    end
  end

  # this view is eventually consistent -- once we've generated the view, we
  # continue serving the view to clients even once it's become outdated, while
  # the background job runs to generate the new view. this is preferred over
  # serving a 503 and making the user check back later in the split second
  # between the discussion changing, and the view getting updated.
  #
  # if opts[:include_new_entries] is true, it will also return all the entries
  # that have been created or updated since the view was generated.
  def materialized_view_json(opts = {})
    unless up_to_date?
      update_materialized_view(xlog_location: self.class.current_xlog_location)
    end

    if json_structure.present?
      json_structure = relativize_json_structure_ids
      participant_ids = relativize_ids(participants_array)
      entry_ids = relativize_ids(entry_ids_array)

      if opts[:include_new_entries]
        @for_mobile = true if opts[:include_mobile_overrides]

        new_entries = (all_entries.count == entry_ids.count) ? [] : all_entries.where.not(id: entry_ids).to_a
        participant_ids = (Set.new(participant_ids) + new_entries.filter_map(&:user_id) + new_entries.filter_map(&:editor_id)).to_a
        entry_ids = (Set.new(entry_ids) + new_entries.map(&:id)).to_a
        new_entries_json_structure = discussion_entry_api_json(new_entries, discussion_topic.context, nil, nil, [])
      else
        new_entries_json_structure = []
      end

      [json_structure, participant_ids, entry_ids, new_entries_json_structure]
    else
      nil
    end
  end

  def update_materialized_view(xlog_location: nil, use_master: false)
    unless use_master
      timeout = Setting.get("discussion_materialized_view_replication_timeout", "60").to_i.seconds
      unless self.class.wait_for_replication(start: xlog_location, timeout:)
        # failed to replicate - requeue later
        run_at = Setting.get("discussion_materialized_view_replication_failure_retry", "300").to_i.seconds.from_now
        delay(singleton: "materialized_discussion:#{Shard.birth.activate { discussion_topic_id }}", run_at:)
          .update_materialized_view(synchronous: true, xlog_location:, use_master:)
        raise ReplicationTimeoutError, "timed out waiting for replication"
      end
    end
    self.generation_started_at = Time.zone.now
    view_json, user_ids, entry_lookup =
      build_materialized_view(use_master:)
    self.json_structure = view_json
    self.participants_array = user_ids
    self.entry_ids_array = entry_lookup
    save!
  rescue ReplicationTimeoutError => e
    Canvas::Errors.capture_exception(:discussion_materialization, e, :warn)
    raise Delayed::RetriableError, e.message
  end

  handle_asynchronously :update_materialized_view,
                        singleton: proc { |o| "materialized_discussion:#{Shard.birth.activate { o.discussion_topic_id }}" }

  def build_materialized_view(use_master: false)
    entry_lookup = {}
    view = []
    user_ids = Set.new
    GuardRail.activate(use_master ? :primary : :secondary) do
      # this process can take some time, and doing the "find_each"
      # approach holds the connection open the whole time, which
      # is a problem if the bouncer pool is small.  By grabbing
      # ids and querying in batches with the ":pluck_ids" strategy,
      # the connection gets recycled properly in between postgres queries.
      all_entries.find_in_batches(strategy: :pluck_ids) do |entry_batch|
        entry_batch.each do |entry|
          json = discussion_entry_api_json([entry], discussion_topic.context, nil, nil, []).first
          entry_lookup[entry.id] = json
          user_ids << entry.user_id
          user_ids << entry.editor_id if entry.editor_id
          if (parent = entry_lookup[entry.parent_id])
            parent["replies"] ||= []
            parent["replies"] << json
          else
            view << json
          end
        end
      end
    end
    StringifyIds.recursively_stringify_ids(view)
    [view.to_json, user_ids.to_a, entry_lookup.keys]
  end

  def in_app?
    !@for_mobile # default to non-mobileapp mode
  end

  def self.include_mobile_overrides(entries, overrides)
    entries.each do |entry|
      if entry["message"]
        parsed_html = Nokogiri::HTML5.fragment(entry["message"])
        Api::Html::Content.add_overrides_to_html(parsed_html, overrides)
        entry["message"] = parsed_html.to_s
      end
      if entry["replies"]
        include_mobile_overrides(entry["replies"], overrides)
      end
    end
  end
end
