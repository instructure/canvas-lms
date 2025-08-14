# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

require "nokogiri"
module DataFixup::AddAttachmentAssociationsToAllAssets
  CONTENT_MAP = {
    Assignment => [:description],
    DiscussionTopic => [:message],
    DiscussionEntry => [:message],
    Submission => [:body],
    WikiPage => [:body],
    TermsOfServiceContent => [:content],
    LearningOutcome => [:description],
    CalendarEvent => [:description],
    AccountNotification => [:message],
    LearningOutcomeGroup => [:description],
    Quizzes::Quiz => [:description],
    Quizzes::QuizQuestion => [:question_data],
    Quizzes::QuizSubmission => [:submission_data]
  }.freeze
  def self.copy_calendar_event_associations_to_children(series_head)
    return unless series_head.series_uuid.present? && series_head.series_head

    # only copy to child events with the same description as the parent
    child_events = CalendarEvent.where(
      series_uuid: series_head.series_uuid,
      series_head: false,
      description: series_head.description
    )
    return if child_events.empty?

    AttachmentAssociation.copy_associations(series_head, child_events.to_a)
  end

  def self.process_model_and_create_attachment_association(model, field, batch_ids)
    model.where(id: batch_ids).each do |object|
      next unless (field && object[field]) || object.is_a?(Quizzes::Quiz) || object.is_a?(Quizzes::QuizQuestion) || object.is_a?(Quizzes::QuizSubmission)

      if object.is_a?(Quizzes::QuizQuestion)
        object.update_attachment_associations(skip_user_verification: true)
      elsif object.is_a?(Quizzes::QuizSubmission)
        # for QuizSubmission, extract all :text fields from submission_data array
        all_html = []
        submission_data = object.submission_data
        unless submission_data.is_a?(Hash)
          submission_data&.each do |answer|
            all_html << answer[:text] if answer.is_a?(Hash) && answer.key?(:text) && answer[:text].present?
          end
        end
        object.associate_attachments_to_rce_object(all_html.compact.join("\n"), nil, skip_user_verification: true) unless all_html.empty?
      elsif object.is_a?(CalendarEvent)
        # for CalendarEvent, process series heads and standalone events only
        # child events with different descriptions are handled separately
        if object.series_head
          object.associate_attachments_to_rce_object(object[field], nil, skip_user_verification: true)
          copy_calendar_event_associations_to_children(object)
        elsif object.series_uuid.blank?
          # Process standalone events normally
          object.associate_attachments_to_rce_object(object[field], nil, skip_user_verification: true)
        end
        # skipping child events here -> they'll be processed in process_calendar_event_children
      else
        context_concern = (field == :syllabus_body) ? "syllabus_body" : nil
        object.associate_attachments_to_rce_object(object[field], nil, context_concern:, skip_user_verification: true)
      end
      sleep Setting.get("create_attachment_association_datafixup_sleep_cluster_#{Shard.current.database_server.id}", "0.5", set_if_nx: true).to_f
    end
  end

  def self.process_calendar_event_children(field)
    child_events = CalendarEvent
                   .where.not(series_uuid: nil)
                   .where(series_head: false)
                   .where("#{field} LIKE ? OR #{field} LIKE ?",
                          "%/media_attachments_iframe/%",
                          "%/files/%")
                   .pluck(:id, :series_uuid, field)

    return if child_events.empty?

    series_uuids = child_events.map { |_, uuid, _| uuid }.uniq
    series_heads = CalendarEvent
                   .where(series_head: true, series_uuid: series_uuids)
                   .pluck(:series_uuid, field)
                   .to_h

    # matching children are already handled by copy_calendar_event_associations_to_children
    # we only need to process the non-matching ones
    non_matching_child_ids = child_events.filter_map do |child_id, series_uuid, description|
      parent_description = series_heads[series_uuid]
      child_id if parent_description.nil? || description != parent_description
    end

    non_matching_child_ids.each_slice(1000) do |batch_ids|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::AddAttachmentAssociationsToAssets", Shard.current.database_server.id]
      ).process_calendar_event_children_batch(field, batch_ids)
    end
  end

  def self.process_calendar_event_children_batch(field, batch_ids)
    CalendarEvent.where(id: batch_ids).each do |child_event|
      child_event.associate_attachments_to_rce_object(child_event[field], nil, skip_user_verification: true)
      sleep Setting.get("create_attachment_association_datafixup_sleep_cluster_#{Shard.current.database_server.id}", "0.5", set_if_nx: true).to_f
    end
  end

  def self.process_discussion_topic_children(field)
    child_topics = DiscussionTopic
                   .where.not(root_topic_id: nil)
                   .where("#{field} LIKE ? OR #{field} LIKE ?",
                          "%/media_attachments_iframe/%",
                          "%/files/%")
                   .pluck(:id, :root_topic_id, field)

    return if child_topics.empty?

    # Get all parent topics for these children
    parent_ids = child_topics.map { |_, parent_id, _| parent_id }.uniq
    parent_topics = DiscussionTopic
                    .where(id: parent_ids)
                    .pluck(:id, field)
                    .to_h

    # Separate children based on whether messages match their parent
    # Child topics with same message should have been handled at creation
    # We only need to process the ones with different messages
    non_matching_child_ids = child_topics.filter_map do |child_id, parent_id, message|
      parent_message = parent_topics[parent_id]
      child_id if parent_message.nil? || message != parent_message
    end

    non_matching_child_ids.each_slice(1000) do |batch_ids|
      delay_if_production(
        priority: Delayed::LOW_PRIORITY,
        n_strand: ["DataFixup::AddAttachmentAssociationsToAssets", Shard.current.database_server.id]
      ).process_discussion_topic_children_batch(field, batch_ids)
    end
  end

  def self.process_discussion_topic_children_batch(field, batch_ids)
    DiscussionTopic.where(id: batch_ids).each do |child_topic|
      child_topic.associate_attachments_to_rce_object(child_topic[field], nil, skip_user_verification: true)
      sleep Setting.get("create_attachment_association_datafixup_sleep_cluster_#{Shard.current.database_server.id}", "0.5", set_if_nx: true).to_f
    end
  end

  def self.filter_data_and_process(min, max, model, field)
    scope = model.where(id: min..max)
    scope = scope.where(
      "#{field} LIKE ? OR #{field} LIKE ?",
      "%/media_attachments_iframe/%",
      "%/files/%"
    )

    # only process root topics for DiscussionTopic (not sub-topics)
    scope = scope.where(root_topic_id: nil) if model == DiscussionTopic

    # for CalendarEvent, exclude child events here as they're:
    #  1- the ones with same description are directly getting a copy of AA
    #  2- the ones that have a different description should be processed again
    #     but separately
    #  main reason for this is to optimize the process
    scope = scope.where("series_uuid IS NULL OR series_head = ?", true) if model == CalendarEvent

    scope.find_ids_in_batches(batch_size: 100_000) do |batch_ids|
      process_model_and_create_attachment_association(model, field, batch_ids)
    end
  end

  def self.run
    CONTENT_MAP.each do |model, fields|
      fields.each do |field|
        model.find_ids_in_ranges(batch_size: 100_000) do |min, max|
          delay_if_production(
            priority: Delayed::LOW_PRIORITY,
            n_strand: ["DataFixup::AddAttachmentAssociationsToAssets", Shard.current.database_server.id]
          ).filter_data_and_process(min, max, model, field)
        end

        # CalendarEvent children with different descriptions are handled here
        process_calendar_event_children(field) if model == CalendarEvent

        # DiscussionTopic children with different messages are handled here
        process_discussion_topic_children(field) if model == DiscussionTopic
      end
    end
  end
end
