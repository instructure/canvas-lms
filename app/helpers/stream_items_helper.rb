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

module StreamItemsHelper
  include TextHelper

  class StreamItemPresenter
    attr_accessor :stream_item_id, :updated_at, :unread, :path, :context, :state, :summary
  end

  class ContextPresenter
    attr_accessor :id, :type, :name, :linked_to, :time_zone
  end

  def categorize_stream_items(stream_items, user = @current_user)
    supported_categories = %w(Announcement Conversation Assignment DiscussionTopic)
    categorized_items = {}
    return categorized_items unless stream_items.present? # if we have no items (possibly because we have no user), don't try to activate the user's shard
    supported_categories.each { |category| categorized_items[category] = [] }

    # need to query relative to the user's shard for
    # 1. conversations
    # 2. the StreamItem#id that gets returned, since we'll use it later to
    #    look up the user's StreamItemInstances for deletion
    user.shard.activate do
      stream_items.each do |item|
        category = item.data.class.name
        category = category_for_message(item.data.notification_name) if category == "Message"

        next unless supported_categories.include?(category)

        if category == "Conversation"
          participant = user.conversation_participant(item.asset_id)

          next if participant.nil? || participant.last_message.nil? || participant.last_author?
          item.data.write_attribute(:last_message, participant.last_message)
          item.data.write_attribute(:last_author, participant.last_message.author)

          # because we're cheating and just checking unread here instead of using
          # the workflow_state on the stream_item_instance, that workflow_state
          # may be out of sync with the underlying conversation.
          item.data.write_attribute(:unread, participant.unread?)
        elsif category == "Assignment"
          # TODO: this handles an edge case for old stream items where their
          # context code was getting set to "assignment_x" instead of "course_y".
          # Can be removed when either:
          # - we switch to direct send_to_stream for assignments
          # - no more stream items have this bad data in production
          next if item.context_type == "Assignment"
        end

        if ["DiscussionTopic","Announcement"].include? category
          item.data.reload
          next if item.data.try(:visible_for?, user) == false
        end

        categorized_items[category] << generate_presenter(category, item)
      end
    end
    categorized_items
  end

  def generate_presenter(category, item)
    presenter = StreamItemPresenter.new
    presenter.stream_item_id = item.id
    presenter.updated_at = item.data.respond_to?(:updated_at) ? item.data.updated_at : nil
    presenter.updated_at ||= item.updated_at
    presenter.unread = item.data.unread
    presenter.path = extract_path(category, item)
    presenter.context = extract_context(category, item)
    presenter.summary = extract_summary(category, item)
    presenter
  end

  def extract_path(category, item)
    case category
    when "Announcement", "DiscussionTopic"
      polymorphic_path([item.context_type.underscore, category.underscore], "#{item.context_type.underscore}_id" => item.context_id, :id => item.asset_id)
    when "Conversation"
      conversation_path(item.asset_id)
    when "Assignment"
      polymorphic_path([item.context_type.underscore, category.underscore], "#{item.context_type.underscore}_id" => item.context_id, :id => item.data.asset_context_id)
    else
      nil
    end
  end

  def extract_context(category, item)
    context = ContextPresenter.new
    asset = item.data
    case category
    when "Announcement", "DiscussionTopic", "Assignment"
      context.type = item.context_type
      context.id = item.context_id
      context.name = asset.context_short_name
      context.linked_to = polymorphic_path([context.type.underscore, category.underscore.pluralize], "#{context.type.underscore}_id" => context.id)
    when "Conversation"
      context.type = "User"
      context.id = asset.last_author.id
      context.name = asset.last_author.short_name
      context.linked_to = user_path(asset.last_author.id)
    end
    context.time_zone = item.context.try(:time_zone)
    context
  end

  def extract_summary(category, item)
    asset = item.data
    case category
    when "Announcement", "DiscussionTopic"
      asset.title
    when "Conversation"
      CanvasTextHelper.truncate_text(asset.last_message.body, :max_length => 250)
    when "Assignment"
      asset.subject
    else
      nil
    end
  end

  def category_for_message(name)
    case name
    when "Assignment Created",
         "Assignment Changed",
         "Assignment Due Date Changed"
      "Assignment"

    when "Assignment Graded",
         "Assignment Submitted Late",
         "Grade Weight Changed",
         "Group Assignment Submitted Late"
      "Submission"

    else
      "Ignore"
    end
  end
  private :category_for_message
end
