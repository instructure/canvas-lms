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

module StreamItemsHelper
  include TextHelper

  class StreamItemPresenter
    attr_accessor :stream_item_id, :updated_at, :unread, :path, :context, :state, :summary
  end

  class ContextPresenter
    attr_accessor :id, :type, :name, :linked_to, :time_zone
  end

  def categorize_stream_items(stream_items, user = @user || @current_user)
    categorized_items = {}
    return categorized_items unless stream_items.present? # if we have no items (possibly because we have no user), don't try to activate the user's shard

    supported_categories = %w[Announcement Conversation Assignment DiscussionTopic DiscussionEntry AssessmentRequest]
    supported_categories.each { |category| categorized_items[category] = [] }

    topic_types = %w[DiscussionTopic Announcement]
    ActiveRecord::Associations.preload(
      stream_items.select { |i| topic_types.include?(i.asset_type) }.map(&:data), :context
    )

    ActiveRecord::Associations.preload(
      stream_items.select { |i| i.asset_type == "DiscussionEntry" }.map(&:data), discussion_topic: :context
    )
    topic_types << "DiscussionEntry"

    stream_items.each do |item|
      category = item.data.class.name
      category = category_for_message(item.data.notification_name) if category == "Message"

      next unless supported_categories.include?(category)

      case category
      when "Conversation"
        participant = user.conversation_participant(item.asset_id)

        next if participant.nil? || participant.last_message.nil? || participant.last_author?

        item.participant = participant

        # because we're cheating and just checking unread here instead of using
        # the workflow_state on the stream_item_instance, that workflow_state
        # may be out of sync with the underlying conversation.
        item.unread = participant.unread?
      when "AssessmentRequest"
        next unless item.data.asset.grants_right?(user, :read)
      end

      next if topic_types.include?(category) && item.data.try(:visible_for?, user) == false

      categorized_items[category] << generate_presenter(category, item, user)
    end
    categorized_items
  end

  def generate_presenter(category, item, user = @current_user)
    presenter = StreamItemPresenter.new
    # need to store stream item id relative to the user's shard, since we'll
    # use it later to look up the user's StreamItemInstances for deletion
    presenter.stream_item_id = user.shard.activate { item.id }
    presenter.updated_at = extract_updated_at(category, item, user)
    presenter.updated_at ||= item.updated_at
    presenter.unread = item.unread
    presenter.path = extract_path(category, item, user)
    presenter.context = extract_context(category, item)
    presenter.summary = extract_summary(category, item, user)
    presenter
  end

  def extract_updated_at(category, item, user)
    case category
    when "Conversation"
      item.data.conversation_participants.find_by(user:)&.last_message_at
    else
      item.data.respond_to?(:updated_at) ? item.data.updated_at : nil
    end
  end

  def extract_path(category, item, user)
    case category
    when "Announcement", "DiscussionTopic"
      polymorphic_path([item.context_type.underscore.to_sym, category.underscore.to_sym],
                       "#{item.context_type.underscore}_id": Shard.short_id_for(item.context_id),
                       id: Shard.short_id_for(item.asset_id))
    when "DiscussionEntry"
      polymorphic_path([item.context_type.underscore.to_sym, :discussion_topic],
                       "#{item.context_type.underscore}_id": Shard.short_id_for(item.context_id),
                       id: Shard.short_id_for(item.data["discussion_topic_id"]),
                       entry_id: Shard.short_id_for(item.data["id"]))
    when "Conversation"
      conversation_path(Shard.short_id_for(item.asset_id))
    when "Assignment"
      polymorphic_path([item.context_type.underscore.to_sym, category.underscore.to_sym],
                       "#{item.context_type.underscore}_id": Shard.short_id_for(item.context_id),
                       id: Shard.short_id_for(item.data.context_id))
    when "AssessmentRequest"
      submission = item.data.asset
      Submission::ShowPresenter.new(
        submission:,
        current_user: user,
        assessment_request: item.data
      ).submission_data_url
    end
  end

  def extract_context(category, item)
    context = ContextPresenter.new
    asset = item.data
    case category
    when "Announcement", "DiscussionEntry", "DiscussionTopic", "Assignment"
      context.type = item.context_type
      context.id = item.context_id
      context.name = asset.context_short_name
      context.linked_to = polymorphic_path([context.type.underscore.to_sym, category.underscore.pluralize.to_sym], "#{context.type.underscore}_id": Shard.short_id_for(context.id))
    when "Conversation"
      context.type = "User"
      last_author = item.participant.last_message.author
      context.id = last_author.id
      context.name = last_author.short_name
      context.linked_to = user_path(last_author)
    when "AssessmentRequest"
      context.type = item.context_type
      context.id = item.context_id
      context.name = asset.context_short_name
    end
    context.time_zone = item.context.try(:time_zone)
    context
  end

  def extract_summary(category, item, user = @current_user)
    asset = item.data
    case category
    when "Announcement", "DiscussionTopic"
      asset.title
    when "Conversation"
      CanvasTextHelper.truncate_text(item.participant.last_message.body, max_length: 250)
    when "Assignment"
      asset.subject
    when "AssessmentRequest"
      # TODO: I18N should use placeholders, not concatenation
      asset.asset.assignment.title + " " + I18n.t("for", "for") + " " + assessment_author_name(asset, user)
    when "DiscussionEntry"
      I18n.t("%{user_name} mentioned you in %{title}.", { user_name: asset.user.short_name, title: item.data["title"] })
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

  def assessment_author_name(asset, user = @current_user)
    if can_do(asset, user, :read_assessment_user)
      asset.asset.user.name
    else
      I18n.t(:anonymous_user, "Anonymous User")
    end
  end

  private :category_for_message, :assessment_author_name
end
