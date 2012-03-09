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
  include ActionController::UrlWriter

  attr_accessible :discussion_topic

  serialize :participants_array, Array
  serialize :entry_ids_array, Array

  belongs_to :discussion_topic

  def self.primary_key
    :discussion_topic_id
  end

  def self.default_url_options(options = nil)
    { :only_path => false, :host => HostUrl.context_host(discussion_topic.context) }
  end

  def self.materialized_view_for(discussion_topic)
    view = self.find_by_discussion_topic_id(discussion_topic.id) ||
           self.create!(:discussion_topic => discussion_topic)
    view.materialized_view_json
  end

  def up_to_date?
    updated_at.present? && updated_at >= discussion_topic.updated_at && json_structure.present?
  end

  # this view is eventually consistent -- once we've generated the view, we
  # continue serving the view to clients even once it's become outdated, while
  # the background job runs to generate the new view. this is preferred over
  # serving a 503 and making the user check back later in the split second
  # between the discussion changing, and the view getting updated.
  def materialized_view_json
    if !up_to_date?
      self.send_later_enqueue_args :update_materialized_view,
        { :singleton => "materialized_discussion:#{discussion_topic_id}" }
    end

    if json_structure.present?
      return self.json_structure, self.participants_array, self.entry_ids_array
    else
      return nil
    end
  end

  def update_materialized_view
    view_json, user_ids, entry_lookup =
      self.build_materialized_view
    self.json_structure = view_json
    self.participants_array = user_ids
    self.entry_ids_array = entry_lookup
    self.save!
  end

  def build_materialized_view
    entry_lookup = {}
    view = []
    user_ids = Set.new
    discussion_entries = self.discussion_topic.discussion_entries
    discussion_entries.find_each do |entry|
      json = discussion_entry_api_json([entry], @context, nil, nil, false).first
      json.delete(:user_name) # this can get out of date in the cached view
      json[:summary] = entry.summary unless entry.deleted?
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
    return view.to_json, user_ids.to_a, entry_lookup.keys
  end
end

