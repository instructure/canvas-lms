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

class Loaders::DiscussionEntryLoader < GraphQL::Batch::Loader
  def initialize(current_user:, search_term: nil, sort_order: :desc, filter: nil, root_entries: false)
    @current_user = current_user
    @search_term = search_term
    @sort_order = sort_order
    @filter = filter
    @root_entries = root_entries
  end

  def perform(discussion_topics)
    discussion_topics.each do |discussion_topic|
      scope = discussion_topic.discussion_entries
      scope = @sort_order == :asc ? scope.order(:created_at) : scope
      scope = scope.where(parent_id: nil) if @root_entries
      if @search_term
        scope = scope.joins(:user).where("message ILIKE '#{UserSearch.like_string_for(@search_term)}'")
          .or(scope.joins(:user).where("users.name ILIKE '#{UserSearch.like_string_for(@search_term)}'"))
      end
      scope = scope.joins(:discussion_entry_participants).where(discussion_entry_participants: {user_id: @current_user, workflow_state: 'unread'}) if @filter == 'Unread'
      scope = scope.where(workflow_state: 'deleted') if @filter == 'Deleted'
      ActiveRecord::Associations::Preloader.new.preload(scope, :user)
      fulfill(discussion_topic, scope)
    end
  end
end
