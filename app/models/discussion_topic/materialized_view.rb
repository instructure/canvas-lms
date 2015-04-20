#
# Copyright (C) 2012 Instructure, Inc.
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
  include Api::V1::DiscussionTopics
  include Api
  include Rails.application.routes.url_helpers
  def use_placeholder_host?; true; end

  attr_accessible :discussion_topic

  serialize :participants_array, Array
  serialize :entry_ids_array, Array

  belongs_to :discussion_topic

  def self.primary_key
    :discussion_topic_id
  end

  def self.for(discussion_topic)
    discussion_topic.shard.activate do
      # first try to pull the view from the slave. we can't just do this in the
      # unique_constraint_retry since it begins a transaction.
      view = Shackles.activate(:slave) { self.where(discussion_topic_id: discussion_topic).first }
      if !view
        # if the view wasn't found, drop into the unique_constraint_retry
        # transaction loop on master.
        unique_constraint_retry do
          view = self.where(discussion_topic_id: discussion_topic).first ||
            self.create!(:discussion_topic => discussion_topic)
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

  # this view is eventually consistent -- once we've generated the view, we
  # continue serving the view to clients even once it's become outdated, while
  # the background job runs to generate the new view. this is preferred over
  # serving a 503 and making the user check back later in the split second
  # between the discussion changing, and the view getting updated.
  #
  # if opts[:include_new_entries] is true, it will also return all the entries
  # that have been created or updated since the view was generated.
  def materialized_view_json(opts = {})
    if !up_to_date?
      update_materialized_view
    end

    if json_structure.present?
      participant_ids = self.participants_array
      entry_ids = self.entry_ids_array

      if opts[:include_new_entries]
        new_entries = discussion_topic.discussion_entries.where("updated_at >= ?", (self.generation_started_at || self.updated_at)).all
        participant_ids = (Set.new(participant_ids) + new_entries.map(&:user_id).compact + new_entries.map(&:editor_id).compact).to_a
        entry_ids = (Set.new(entry_ids) + new_entries.map(&:id)).to_a
        new_entries_json_structure = discussion_entry_api_json(new_entries, discussion_topic.context, nil, nil, [])
      else
        new_entries_json_structure = []
      end
      return self.json_structure, participant_ids, entry_ids, new_entries_json_structure
    else
      return nil
    end
  end

  def update_materialized_view
    self.generation_started_at = Time.zone.now
    view_json, user_ids, entry_lookup =
      self.build_materialized_view
    self.json_structure = view_json
    self.participants_array = user_ids
    self.entry_ids_array = entry_lookup
    self.save!
  end

  handle_asynchronously :update_materialized_view,
    :singleton => proc { |o| "materialized_discussion:#{ Shard.birth.activate { o.discussion_topic_id } }" },
    :run_at => proc { 10.seconds.from_now } # delay for replication to slave

  def build_materialized_view
    entry_lookup = {}
    view = []
    user_ids = Set.new
    Shackles.activate(:slave) do
      discussion_entries = self.discussion_topic.discussion_entries
      discussion_entries.find_each do |entry|
        json = discussion_entry_api_json([entry], discussion_topic.context, nil, nil, []).first
        entry_lookup[entry.id] = json
        user_ids << entry.user_id
        user_ids << entry.editor_id if entry.editor_id
        if parent = entry_lookup[entry.parent_id]
          parent['replies'] ||= []
          parent['replies'] << json
        else
          view << json
        end
      end
    end
    Api.recursively_stringify_json_ids(view)
    return view.to_json, user_ids.to_a, entry_lookup.keys
  end
end

