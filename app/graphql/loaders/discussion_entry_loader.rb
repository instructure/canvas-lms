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
  def initialize(current_user:, search_term: nil, sort_order: :desc, filter: nil, root_entries: false, relative_entry_id: nil)
    @current_user = current_user
    @search_term = search_term
    @sort_order = sort_order
    @filter = filter
    @root_entries = root_entries
    @relative_entry_id = relative_entry_id
  end

  def perform(objects)
    objects.each do |object|
      scope = scope_for(object)
      scope = scope.reorder("created_at #{@sort_order}")
      scope = scope.where(parent_id: nil) if @root_entries
      if @search_term.present?
        scope = scope.where.not(:workflow_state => 'deleted')
        scope = scope.joins(:user).where("message ILIKE '#{UserSearch.like_string_for(@search_term)}'")
          .or(scope.joins(:user).where("users.name ILIKE '#{UserSearch.like_string_for(@search_term)}'"))
      end

      if @relative_entry_id
        relative_entry = scope.find(@relative_entry_id)
        condition = @sort_order == :desc ? ">=" : "<"
        scope = scope.where("created_at #{condition}?", relative_entry.created_at)
      end

      scope = scope.joins(:discussion_entry_participants).where(discussion_entry_participants: {user_id: @current_user, workflow_state: 'unread'}) if @filter == 'unread'
      scope = scope.where(workflow_state: 'deleted') if @filter == 'deleted'
      fulfill(object, scope)
    end
  end

  def scope_for(object)
    if object.is_a?(DiscussionTopic)
      object.discussion_entries
    elsif object.is_a?(DiscussionEntry)
      if object.root_entry_id.nil?
        object.root_discussion_replies
      elsif object.legacy?
        object.legacy_subentries
      else
        DiscussionEntry.none
      end
    end
  end

end
