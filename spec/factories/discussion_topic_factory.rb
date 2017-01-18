#
# Copyright (C) 2011 Instructure, Inc.
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

def discussion_topic_model(opts={})
  @context = opts[:context] || @context || course_model(:reusable => true)
  @topic = @context.discussion_topics.create!(valid_discussion_topic_attributes.merge(opts))
end

def valid_discussion_topic_attributes
  {
    :title => "value for title",
    :message => "value for message"
  }
end

def group_assignment_discussion(opts = {})
  course = opts[:course] || course_model(:reusable => true)
  assignment_model(:course => course, :submission_types => 'discussion_topic', :title => 'Group Assignment Discussion')

  @root_topic = DiscussionTopic.where(assignment_id: @assignment).first
  @group_category = course.group_categories.create(:name => 'Project Group')
  group_model(:name => 'Project Group 1', :group_category => @group_category, :context => course)
  @root_topic.group_category = @group_category
  @root_topic.save!

  @root_topic.refresh_subtopics
  @topic = @group.discussion_topics.where(root_topic_id: @root_topic).first
end

def topic_with_nested_replies(opts = {})
  course_with_teacher(:active_all => true)
  student_in_course(:course => @course, :active_all => true)
  @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher, :discussion_type => 'threaded')
  @root1 = @topic.reply_from(:user => @student, :html => "root1")
  @root2 = @topic.reply_from(:user => @student, :html => "root2")
  @reply1 = @root1.reply_from(:user => @teacher, :html => "reply1")
  @reply2_attachment = attachment_model(:context => @course)
  @reply2 = @root1.reply_from(:user => @teacher, :html => <<-HTML)
    <p><a href="/courses/#{@course.id}/files/#{@reply2_attachment.id}/download">This is a file link</a></p>
    <p>This is a video:
      <a class='instructure_inline_media_comment' id='media_comment_0_abcde' href='#'>link</a>
    </p>
  HTML
  @reply_reply1 = @reply2.reply_from(:user => @student, :html => "reply_reply1")
  @reply_reply1.update_attribute(:attachment, attachment_model)
  @reply_reply2 = @reply1.reply_from(:user => @student, :html => "reply_reply2")
  @reply3 = @root2.reply_from(:user => @student, :html => "reply3")
  @reply1.destroy
  @all_entries = [@root1, @root2, @reply1, @reply2, @reply_reply1, @reply_reply2, @reply3]
  @all_entries.each &:reload
  @topic.reload
end

def group_discussion_assignment
  course = @course || course(:active_all => true)
  group_category = course.group_categories.create!(:name => "category")
  @group1 = course.groups.create!(:name => "group 1", :group_category => group_category)
  @group2 = course.groups.create!(:name => "group 2", :group_category => group_category)

  @topic = course.discussion_topics.build(:title => "topic")
  @topic.group_category = group_category
  @assignment = course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
  @assignment.infer_times
  @assignment.saved_by = :discussion_topic
  @topic.assignment = @assignment
  @topic.save!
end
