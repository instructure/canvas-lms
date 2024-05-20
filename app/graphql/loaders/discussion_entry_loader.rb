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
  def initialize(current_user:, search_term: nil, sort_order: :desc, filter: nil, root_entries: false, relative_entry_id: nil, before_relative_entry: true, include_relative_entry: true, user_search_id: nil, unread_before: nil)
    super()
    @current_user = current_user
    @search_term = search_term
    @sort_order = sort_order
    @filter = filter
    @root_entries = root_entries
    @user_search_id = user_search_id
    @relative_entry_id = relative_entry_id
    @before_entry = before_relative_entry
    @include_entry = include_relative_entry
    @unread_before = unread_before
  end

  def perform(objects)
    objects.each do |object|
      scope = scope_for(object)
      scope = scope.reorder("created_at #{@sort_order}")

      if @filter == "drafts"
        object.shard.activate do
          drafts = scope.map do |draft|
            de = DiscussionEntry.new(id: -draft.id,
                                     message: draft.message,
                                     root_entry_id: draft.root_entry_id,
                                     parent_id: draft.parent_id,
                                     discussion_topic_id: draft.discussion_topic_id,
                                     user_id: @current_user.id,
                                     created_at: draft.created_at,
                                     updated_at: draft.updated_at,
                                     workflow_state: "active")
            de.readonly!
            de
          end
          return fulfill(object, drafts)
        end
      end

      scope = scope.where(parent_id: nil) if @root_entries
      if @search_term.present?
        # search results cannot look at the messages from deleted
        # discussion_entries, so they need to be excluded.
        scope = if object.is_a?(DiscussionTopic) && object.anonymous_state != "full_anonymity" && object.anonymous_state != "partial_anonymity"
                  scope.active.joins(:user).where(UserSearch.like_condition("message"), pattern: UserSearch.like_string_for(@search_term))
                       .or(scope.joins(:user).where(UserSearch.like_condition("users.name"), pattern: UserSearch.like_string_for(@search_term)))
                else
                  scope.active.where(UserSearch.like_condition("message"), pattern: UserSearch.like_string_for(@search_term))
                end
      end

      if @root_entries
        sort_sql = ActiveRecord::Base.sanitize_sql("COALESCE(children.created_at, discussion_entries.created_at) #{@sort_order}")
        scope = scope
                .joins("LEFT OUTER JOIN #{DiscussionEntry.quoted_table_name} AS children
                  ON children.root_entry_id=discussion_entries.id
                  AND children.created_at = (SELECT MAX(children2.created_at)
                                             FROM #{DiscussionEntry.quoted_table_name} AS children2
                                             WHERE children2.root_entry_id=discussion_entries.id)")
                .reorder(Arel.sql(sort_sql))
      end

      if @relative_entry_id
        relative_entry = scope.find(@relative_entry_id)
        condition = @before_entry ? "<" : ">"
        condition += "=" if @include_entry
        scope = scope.where("created_at #{condition}?", relative_entry.created_at)
      end

      # unread filter is used like search results and need to exclude deleted entries
      scope = scope.active.unread_for_user_before(@current_user, @unread_before) if @filter == "unread"
      scope = scope.where(workflow_state: "deleted") if @filter == "deleted"
      scope = scope.where(user_id: @user_search_id) unless @user_search_id.nil?
      scope = scope.preload(:user, :editor)
      fulfill(object, scope)
    rescue ActiveRecord::RecordNotFound
      raise GraphQL::ExecutionError, "relative entry not found"
    end
  end

  def scope_for(object)
    if @filter == "drafts"
      object.discussion_entry_drafts.where(user: @current_user, discussion_entry_id: nil)
    elsif object.is_a?(DiscussionTopic)
      object.discussion_entries
    elsif object.is_a?(DiscussionEntry)
      if object.root_entry_id.nil?
        if @user_search_id
          object.flattened_discussion_subentries
        else
          object.root_discussion_replies
        end
      else
        object.discussion_subentries
      end
    end
  end
end
