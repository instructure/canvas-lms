# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
module CC
  module TopicResources
    def add_topics
      scope = @course.discussion_topics.active
      # @user is nil if it's kicked off by the system, like a course template
      scope = DiscussionTopic::ScopedToUser.new(@course, @user, scope).scope if @user
      scope.each do |topic|
        next unless export_object?(topic) || export_object?(topic.assignment)

        lock_info = topic.locked_for?(@user, check_policies: true)
        next if @user && lock_info && !lock_info[:can_view]

        title = topic.title || I18n.t("course_exports.unknown_titles.topic", "Unknown topic")

        if topic.assignment && !topic.assignment.can_copy?(@user)
          add_error(I18n.t("course_exports.errors.topic_is_locked", "The topic \"%{title}\" could not be copied because it is locked.", title:))
          next
        end
        begin
          add_topic(topic)
        rescue
          add_error(I18n.t("course_exports.errors.topic", "The discussion topic \"%{title}\" failed to export", title:), $!)
        end
      end
    end

    def add_topic(topic)
      add_exported_asset(topic)
      add_item_to_export(topic.attachment) if topic.attachment

      migration_id = create_key(topic)

      # the CC Discussion Topic
      topic_file_name = "#{migration_id}.xml"
      topic_path = File.join(@export_dir, topic_file_name)
      topic_file = File.new(topic_path, "w")
      topic_doc = Builder::XmlMarkup.new(target: topic_file, indent: 2)
      topic_doc.instruct!

      topic_doc.topic("xmlns" => "http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1",
                      "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                      "xsi:schemaLocation" => "http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1  http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imsdt_v1p1.xsd") do |t|
        create_cc_topic(t, topic)
      end
      topic_file.close

      # Save all the meta-data into a canvas-specific xml schema
      meta_migration_id = create_key(topic, "meta")
      meta_file_name = "#{meta_migration_id}.xml"
      meta_path = File.join(@export_dir, meta_file_name)
      meta_file = File.new(meta_path, "w")
      meta_doc = Builder::XmlMarkup.new(target: meta_file, indent: 2)
      meta_doc.instruct!
      meta_doc.topicMeta("identifier" => meta_migration_id,
                         "xmlns" => CCHelper::CANVAS_NAMESPACE,
                         "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                         "xsi:schemaLocation" => "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}") do |t|
        create_canvas_topic(t, topic)
      end
      meta_file.close

      @resources.resource(
        :identifier => migration_id,
        "type" => CCHelper::DISCUSSION_TOPIC
      ) do |res|
        res.file(href: topic_file_name)
        res.dependency(identifierref: meta_migration_id)
      end
      @resources.resource(
        identifier: meta_migration_id,
        type: CCHelper::LOR,
        href: meta_file_name
      ) do |res|
        res.file(href: meta_file_name)
      end
    end

    def create_cc_topic(doc, topic)
      doc.title topic.title
      html = @html_exporter.html_content(topic.message || "")
      doc.text(html, texttype: "text/html")
      if topic.attachment
        doc.attachments do |atts|
          folder = topic.attachment.folder.full_name.sub("course files", CCHelper::WEB_CONTENT_TOKEN)
          path = "#{folder}/#{topic.attachment.unencoded_filename}"
          atts.attachment(href: path)
        end
      end
    end

    def create_canvas_topic(doc, topic)
      doc.topic_id create_key(topic)
      doc.title topic.title
      doc.delayed_post_at ims_datetime(topic.delayed_post_at) if topic.delayed_post_at
      doc.lock_at ims_datetime(topic.lock_at) if topic.lock_at
      doc.position topic.position
      doc.external_feed_identifierref create_key(topic.external_feed) if topic.external_feed
      doc.attachment_identifierref create_key(topic.attachment) if topic.attachment
      if topic.is_announcement
        doc.tag!("type", "announcement")
      else
        doc.tag!("type", "topic")
      end
      doc.discussion_type topic.discussion_type
      doc.pinned "true" if topic.pinned
      doc.require_initial_post "true" if topic.require_initial_post
      doc.has_group_category topic.has_group_category?
      doc.group_category topic.group_category.name if topic.group_category
      doc.workflow_state topic.workflow_state
      doc.module_locked topic.locked_by_module_item?(@user, deep_check_if_needed: true).present?
      doc.allow_rating topic.allow_rating
      doc.only_graders_can_rate topic.only_graders_can_rate
      doc.sort_by_rating topic.sort_by_rating
      doc.sort_order topic.sort_order
      doc.sort_order_locked topic.sort_order_locked
      doc.expanded topic.expanded
      doc.expanded_locked topic.expanded_locked
      doc.todo_date topic.todo_date
      doc.locked "true" if topic.locked
      if topic.assignment && !topic.assignment.deleted?
        assignment_migration_id = create_key(topic.assignment)
        doc.assignment(identifier: assignment_migration_id) do |a|
          AssignmentResources.create_canvas_assignment(a, topic.assignment, @manifest)
          create_sub_assignments(doc, topic) if discussion_checkpoints?(topic)
        end
      end
      doc.anonymous_state topic.anonymous_state unless topic.anonymous_state.nil?
      doc.is_anonymous_author "true" if topic.is_anonymous_author
      if discussion_checkpoints?(topic) && topic.reply_to_entry_required_count
        doc.reply_to_entry_required_count topic.reply_to_entry_required_count
      end
    end

    def create_sub_assignments(doc, topic)
      unless topic.sub_assignments.empty?
        doc.sub_assignments do
          topic.sub_assignments.each do |sub_assignment|
            add_exported_asset(sub_assignment)

            identifier = create_key(sub_assignment)
            tag = sub_assignment.sub_assignment_tag
            doc.sub_assignment(identifier:, tag:) do |sub_assignment_doc|
              AssignmentResources.create_canvas_assignment(sub_assignment_doc, sub_assignment, @manifest)
            end
          end
        end
      end
    end

    def discussion_checkpoints?(topic)
      @course.discussion_checkpoints_enabled? && topic&.assignment&.has_sub_assignments
    end
  end
end
