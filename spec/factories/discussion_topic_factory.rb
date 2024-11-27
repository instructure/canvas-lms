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

module Factories
  def discussion_topic_model(opts = {})
    @context = opts[:context] || @context || course_model(reusable: true)
    @topic = @context.discussion_topics.create!(valid_discussion_topic_attributes.merge(opts))
  end

  def valid_discussion_topic_attributes
    {
      title: "value for title",
      message: "value for message"
    }
  end

  def group_assignment_discussion(opts = {})
    course = opts[:course] || course_model(reusable: true)
    assignment_model(course:, submission_types: "discussion_topic", title: "Group Assignment Discussion")

    @root_topic = DiscussionTopic.where(assignment_id: @assignment).first
    @group_category = course.group_categories.create(name: "Project Group")
    group_model(name: "Project Group 1", group_category: @group_category, context: course)
    @root_topic.group_category = @group_category
    @root_topic.save!

    @root_topic.refresh_subtopics
    @topic = @group.discussion_topics.where(root_topic_id: @root_topic).first
  end

  def topic_with_nested_replies
    course_with_teacher(active_all: true)
    student_in_course(course: @course, active_all: true)
    @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher, discussion_type: "threaded")
    @root1 = @topic.reply_from(user: @student, html: "root1")
    @root2 = @topic.reply_from(user: @student, html: "root2")
    @reply1 = @root1.reply_from(user: @teacher, html: "reply1")
    @reply2_attachment = attachment_model(context: @course)
    @reply2 = @root1.reply_from(user: @teacher, html: <<~HTML)
      <p><a href="/courses/#{@course.id}/files/#{@reply2_attachment.id}/download">This is a file link</a></p>
      <p>This is a video:
        <a class='instructure_inline_media_comment' id='media_comment_0_abcde' href='#'>link</a>
      </p>
    HTML
    @reply_reply1 = @reply2.reply_from(user: @student, html: "reply_reply1")
    @reply_reply1.update_attribute(:attachment, attachment_model)
    @reply_reply2 = @reply1.reply_from(user: @student, html: "reply_reply2")
    @reply3 = @root2.reply_from(user: @student, html: "reply3")
    @reply1.destroy
    @all_entries = [@root1, @root2, @reply1, @reply2, @reply_reply1, @reply_reply2, @reply3]
    @all_entries.each(&:reload)
    @topic.reload
  end

  def create_valid_discussion_entry
    course_with_teacher(active_all: true)
    @topic = @course.discussion_topics.create!(title: "title", message: "message", user: @teacher, discussion_type: "threaded")
    @topic.discussion_entries.create!(message: "Hello!", user: @teacher, editor: @teacher)
  end

  def group_discussion_assignment
    course = @course || course_factory(active_all: true)
    group_category = course.group_categories.create!(name: "category")
    @group1 = course.groups.create!(name: "group 1", group_category:)
    @group2 = course.groups.create!(name: "group 2", group_category:)

    @topic = course.discussion_topics.build(title: "topic")
    @topic.group_category = group_category
    @assignment = course.assignments.build(submission_types: "discussion_topic", title: @topic.title)
    @assignment.infer_times
    @assignment.saved_by = :discussion_topic
    @topic.assignment = @assignment
    @topic.save!
    @assignment.reload
    @topic
  end

  def group_discussion_with_deleted_group
    course = @course || course_factory(active_all: true)
    group_category = course.group_categories.create!(name: "category")
    @group1 = course.groups.create!(name: "group 1", group_category:)
    @group2 = course.groups.create!(name: "group 2", group_category:)
    @group3 = course.groups.create!(name: "group 3", group_category:)

    @topic = course.discussion_topics.build(title: "topic")
    @topic.group_category = group_category

    @assignment = course.assignments.build(submission_types: "discussion_topic", title: @topic.title)
    @assignment.infer_times
    @assignment.saved_by = :discussion_topic
    @topic.assignment = @assignment

    @topic.save!
    @assignment.reload

    @group3.destroy
    @topic.reload

    @topic
  end

  def group_discussion_topic_model(opts = {})
    @context = opts[:context] || @context || course_factory(active_all: true)
    @group_category = @context.group_categories.create(name: "Project Group")
    group_model(name: "Project Group 1", group_category: @group_category, context: @context)
    opts[:group_category] = @group_category
    @group_topic = @context.discussion_topics.create!(valid_discussion_topic_attributes.merge(opts))
  end

  def graded_discussion_topic(opts = {})
    @context = opts[:context] || @context || course_factory(active_all: true)
    @topic = discussion_topic_model(opts)
    @assignment = @topic.context.assignments.build(submission_types: "discussion_topic", title: @topic.title)
    @assignment.infer_times
    @assignment.saved_by = :discussion_topic
    @topic.assignment = @assignment
    @topic.save
    @topic
  end

  def graded_discussion_topic_with_checkpoints(opts = {})
    @context = opts[:context] || @context || course_factory(active_all: true)
    topic_opts = {}
    topic_opts.merge!(opts)
    topic_opts[:title] = opts[:title] || "graded discussion with checkpoints"
    # options below are not valid for the discussion_topic_model
    topic_opts.reject! { |k| %i[due_date_reply_to_topic due_date_reply_to_entry points_possible_reply_to_topic points_possible_reply_to_entry].include?(k) }
    @topic = discussion_topic_model(topic_opts)
    @assignment = @topic.context.assignments.build(submission_types: "discussion_topic", title: @topic.title)
    @assignment.infer_times
    @assignment.saved_by = :discussion_topic
    @topic.assignment = @assignment
    @topic.save
    due_date_reply_to_topic = [{ type: "everyone", due_at: opts[:due_date_reply_to_topic] || 1.day.from_now }]
    due_date_reply_to_entry = [{ type: "everyone", due_at: opts[:due_date_reply_to_entry] || 3.days.from_now }]
    reply_to_topic = Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: @topic,
      checkpoint_label: CheckpointLabels::REPLY_TO_TOPIC,
      dates: due_date_reply_to_topic,
      points_possible: opts[:points_possible_reply_to_topic] || 5
    )
    reply_to_entry = Checkpoints::DiscussionCheckpointCreatorService.call(
      discussion_topic: @topic,
      checkpoint_label: CheckpointLabels::REPLY_TO_ENTRY,
      dates: due_date_reply_to_entry,
      points_possible: opts[:points_possible_reply_to_entry] || 5,
      replies_required: opts[:reply_to_entry_required_count] || 3
    )
    [reply_to_topic, reply_to_entry, @topic]
  end
end
