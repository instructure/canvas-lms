#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Importers::CalendarEvent do

  let(:migration_course) { course(active_all: true) }

  let(:migration_assignment) do
    assignment = migration_course.assignments.build(title: 'migration assignment')
    assignment.workflow_state = 'active'
    assignment.migration_id = 42
    assignment.save!
    assignment
  end

  let(:migration_quiz) do
    assignment_quiz([], course: migration_course)
    @quiz.migration_id = 42
    @quiz.save!
    @quiz
  end

  let(:migration_attachment) do
    attachment_with_context(migration_course)
    @attachment.migration_id = 42
    @attachment.save!
    @attachment
  end

  let(:migration_topic) do
    topic = migration_course.discussion_topics.build(title: 'migration topic')
    topic.workflow_state = 'active'
    topic.migration_id = 42
    topic.save!
    topic
  end

  def attachment_suffix(type, value)
    Importers::CalendarEvent.import_migration_attachment_suffix(
      {
        attachment_type: type,
        attachment_value: value,
      },
      migration_course)
  end

  def check_paragraph_link(s, type = nil)
    md = s.match %r(^<p><a href=['"]([^'"]*)['"])
    md.should_not be_nil
    md[1].should match %r(courses/\d+/#{type}/\d+) if type
  end

  describe '.import_from_migration' do
    it 'initializes a calendar event based on hash data' do
      event = migration_course.calendar_events.build
      hash = {
        migration_id: 42,
        title: 'event title',
        description: 'the event description',
        start_at: Time.now,
        end_at: Time.now + 2.hours,
        attachment_type: 'external_url',
        attachment_value: 'http://example.com'
      }
      Importers::CalendarEvent.import_from_migration(hash, migration_course, event)
      event.should_not be_new_record
      event.imported.should be_true
      event.migration_id.should == 42
      event.title.should == 'event title'
      event.description.should match('the event description')
      event.description.should match('example.com')
    end
  end

  describe '.import_migration_attachment_suffix' do
    it "handles external_url" do
      result = attachment_suffix('external_url', 'http://example.com')
      result.should include 'http://example.com'
      check_paragraph_link(result)
    end

    it "handles assignments" do
      result = attachment_suffix('assignment', migration_assignment.migration_id.to_s)
      result.should include migration_assignment.id.to_s
      check_paragraph_link(result, 'assignments')
    end

    it "handles assessments" do
      result = attachment_suffix('assessment', migration_quiz.migration_id.to_s)
      result.should include migration_quiz.id.to_s
      check_paragraph_link(result, 'quizzes')
    end

    it "handles files" do
      result = attachment_suffix('file', migration_attachment.migration_id.to_s)
      result.should include migration_attachment.id.to_s
      check_paragraph_link(result)
      # Attachment doesn't follow the typical url pattern
      result.should include "/files/#{migration_attachment.id}/download"
    end

    it "handles web_links" do
      migration_course.expects(:external_url_hash).returns('value' => {'url' => 'http://example.com', 'name' => 'example link'})
      result = attachment_suffix('web_link', 'value')
      result.should include 'example link'
      result.should include 'http://example.com'
      check_paragraph_link(result)
    end

    it "handles discussion topics" do
      result = attachment_suffix('topic', migration_topic.migration_id.to_s)
      result.should include migration_topic.id.to_s
      check_paragraph_link(result, 'discussion_topics')
    end

    it "returns empty string on unrecognized types" do
      result = attachment_suffix('invalid', '42')
      result.should be_empty
    end

  end
end
