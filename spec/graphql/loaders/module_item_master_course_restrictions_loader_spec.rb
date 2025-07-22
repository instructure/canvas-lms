# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Loaders::ModuleItemMasterCourseRestrictionsLoader do
  def run_master_course_migration(master)
    template = master.master_course_templates.first
    master_teacher = master.teachers.first
    @migration = MasterCourses::MasterMigration.start_new_migration!(template, master_teacher)
    run_jobs
    @migration.reload
  end

  before(:once) do
    @master_account = Account.create!
    @master_course = course_factory(account: @master_account, active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master_course)
    @master_module = @master_course.context_modules.create!(name: "Master Module")

    @original_assignment = @master_course.assignments.create!(title: "normal assignment")
    @assignment_tag = @template.create_content_tag_for!(@original_assignment)
    @assignment_tag.update(restrictions: { content: true })
    @master_assignment_tag = @master_module.add_item(type: "assignment", id: @original_assignment.id)

    @original_page = @master_course.wiki_pages.create!(title: "blah", body: "bloo")
    @page_tag = @template.create_content_tag_for!(@original_page)
    @page_tag.update(restrictions: { content: true })
    @master_page_tag = @master_module.add_item(type: "page", id: @original_page.id)

    @original_discussion = @master_course.discussion_topics.create!(title: "blah", message: "bloo")
    @discussion_tag = @template.create_content_tag_for!(@original_discussion)
    @discussion_tag.update(restrictions: { settings: true })
    @master_discussion_tag = @master_module.add_item(type: "discussion", id: @original_discussion.id)

    @original_quiz = @master_course.quizzes.create!(title: "blah")
    @quiz_tag = @template.create_content_tag_for!(@original_quiz)
    @quiz_tag.update(restrictions: { content: true })
    @master_quiz_tag = @master_module.add_item(type: "quiz", id: @original_quiz.id)

    @original_attachment = @master_course.attachments.create!(filename: "test.txt", uploaded_data: StringIO.new("test file"))
    @attachment_tag = @template.create_content_tag_for!(@original_attachment)
    @attachment_tag.update(restrictions: { content: true })
    @master_attachment_tag = @master_module.add_item(type: "attachment", id: @original_attachment.id)

    course_with_teacher(account: @master_account, active_all: true)
    @child_course = @course
    @sub = @template.add_child_course!(@child_course)

    run_master_course_migration(@master_course)
    @child_course.reload

    @child_module = @child_course.context_modules.first
    @child_content_tags = @child_module.content_tags
    @child_assignment_tag = @child_content_tags.find { |tag| tag.content_type == @assignment_tag.content_type }
    @child_page_tag = @child_content_tags.find { |tag| tag.content_type == @page_tag.content_type }
    @child_discussion_tag = @child_content_tags.find { |tag| tag.content_type == @discussion_tag.content_type }
    @child_quiz_tag = @child_content_tags.find { |tag| tag.content_type == @quiz_tag.content_type }
    @child_attachment_tag = @child_content_tags.find { |tag| tag.content_type == @attachment_tag.content_type }
  end

  def with_query_counter
    query_count = 0
    original_method = ActiveRecord::Base.connection.method(:execute)

    allow(ActiveRecord::Base.connection).to receive(:execute) do |sql|
      query_count += 1 unless sql.match?(/^(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/)
      original_method.call(sql)
    end

    yield query_count
  ensure
    RSpec::Mocks.space.reset_all
  end

  context "in a child course" do
    it "loads restrictions for module items in a child course" do
      loader = Loaders::ModuleItemMasterCourseRestrictionsLoader.new(@teacher)

      results = {}
      promises = {}
      GraphQL::Batch.batch do
        [@child_assignment_tag, @child_page_tag, @child_discussion_tag, @child_quiz_tag, @child_attachment_tag].each do |tag|
          promises[tag.id] = loader.load(tag)
        end
      end

      promises.each do |tag_id, promise|
        results[tag_id] = promise.sync
      end

      expect(results[@child_assignment_tag.id]).to eq({ content: true })
      expect(results[@child_page_tag.id]).to eq({ content: true })
      expect(results[@child_discussion_tag.id]).to eq({ settings: true })
      expect(results[@child_quiz_tag.id]).to eq({ content: true })
      expect(results[@child_attachment_tag.id]).to eq({ content: true })
    end

    it "batches queries efficiently" do
      loader = Loaders::ModuleItemMasterCourseRestrictionsLoader.new(@user)

      with_query_counter do |query_count|
        before_count = query_count
        GraphQL::Batch.batch do
          [@child_assignment_tag, @child_quiz_tag, @child_attachment_tag].each do |tag|
            loader.load(tag)
          end
        end
        expect(query_count - before_count).to be <= 3 # Should use a small number of batched queries
      end
    end

    it "returns nil for unsupported content types" do
      # Create an unsupported content type
      @child_url = @child_course.context_external_tools.create!(
        name: "External URL",
        consumer_key: "test",
        shared_secret: "secret",
        url: "http://example.com"
      )
      @child_url_tag = @child_module.add_item(type: "external_url", url: "http://example.com")

      loader = Loaders::ModuleItemMasterCourseRestrictionsLoader.new(@user)

      result = nil
      GraphQL::Batch.batch do
        loader.load(@child_url_tag).then { |r| result = r }
      end

      expect(result).to be_nil
    end
  end

  context "in a master course" do
    it "loads restrictions for module items in a master course" do
      loader = Loaders::ModuleItemMasterCourseRestrictionsLoader.new(@teacher)

      results = {}
      promises = {}
      GraphQL::Batch.batch do
        [@master_assignment_tag, @master_page_tag, @master_discussion_tag, @master_quiz_tag, @master_attachment_tag].each do |tag|
          promises[tag.id] = loader.load(tag)
        end
      end

      promises.each do |tag_id, promise|
        results[tag_id] = promise.sync
      end

      expect(results[@master_assignment_tag.id]).to eq({ content: true })
      expect(results[@master_page_tag.id]).to eq({ content: true })
      expect(results[@master_discussion_tag.id]).to eq({ settings: true })
      expect(results[@master_quiz_tag.id]).to eq({ content: true })
      expect(results[@master_attachment_tag.id]).to eq({ content: true })
    end
  end

  context "in a non-blueprint course" do
    it "returns nil for all module items" do
      regular_course = course_factory(active_all: true)
      regular_module = regular_course.context_modules.create!(name: "Regular Module")
      regular_assignment = regular_course.assignments.create!(title: "Regular Assignment")
      regular_tag = regular_module.add_item(type: "assignment", id: regular_assignment.id)

      loader = Loaders::ModuleItemMasterCourseRestrictionsLoader.new(@user)

      result = nil
      GraphQL::Batch.batch do
        loader.load(regular_tag).then { |r| result = r }
      end

      expect(result).to be_nil
    end
  end

  context "with mixed course types" do
    it "handles module items from different courses correctly" do
      regular_course = course_factory(active_all: true)
      regular_module = regular_course.context_modules.create!(name: "Regular Module")
      regular_assignment = regular_course.assignments.create!(title: "Regular Assignment")
      regular_tag = regular_module.add_item(type: "assignment", id: regular_assignment.id)

      loader = Loaders::ModuleItemMasterCourseRestrictionsLoader.new(@user)

      results = {}
      promises = {}
      GraphQL::Batch.batch do
        promises[regular_tag.id] = loader.load(regular_tag)
        promises[@child_assignment_tag.id] = loader.load(@child_assignment_tag)
      end

      promises.each do |tag_id, promise|
        results[tag_id] = promise.sync
      end

      expect(results[regular_tag.id]).to be_nil
      expect(results[@child_assignment_tag.id]).to eq({ content: true })
    end

    it "batches queries efficiently across different courses" do
      regular_course = course_factory(active_all: true)
      regular_module = regular_course.context_modules.create!(name: "Regular Module")
      regular_assignment = regular_course.assignments.create!(title: "Regular Assignment")
      regular_tag = regular_module.add_item(type: "assignment", id: regular_assignment.id)

      loader = Loaders::ModuleItemMasterCourseRestrictionsLoader.new(@user)

      with_query_counter do |query_count|
        before_count = query_count
        GraphQL::Batch.batch do
          [regular_tag, @child_assignment_tag].each do |tag|
            loader.load(tag)
          end
        end
        expect(query_count - before_count).to be <= 5 # Should use a small number of batched queries
      end
    end
  end
end
