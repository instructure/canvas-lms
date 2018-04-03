# coding: utf-8
#
# Copyright (C) 2017 - present Instructure, Inc.
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

require 'spec_helper'

describe "ZipPackage" do
  def add_file(fixture, context, name, folder = Folder.root_folders(context).first)
    context.attachments.create! do |attachment|
      attachment.uploaded_data = fixture
      attachment.filename = name
      attachment.folder = folder
    end
  end

  before :once do
    course_with_student(active_all: true)
    @cartridge_path = 'spec/fixtures/migration/unicode-filename-test-export.imscc'
    @cache_key = 'cache_key'
  end

  before do
    @module = @course.context_modules.create!(name: 'first_module')
    @exporter = CC::Exporter::WebZip::Exporter.new(File.open(@cartridge_path), false, :web_zip)
  end

  context "parse_module_data" do
    it "should map context module data from Canvas" do
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_data = zip_package.parse_module_data
      expect(module_data).to eq [{id: @module.id, name: 'first_module', status: 'completed',
        unlockDate: nil, prereqs: [], requirement: nil, sequential: false,
        exportId: CC::CCHelper.create_key(@module), items: []}]
    end

    it "should show modules locked by prerequisites with status of locked" do
      assign = @course.assignments.create!(title: 'Assignment 1')
      assign_item = @module.content_tags.create!(content: assign, context: @course)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!
      module2 = @course.context_modules.create!(name: 'second_module')
      quiz = @course.quizzes.create!(title: 'Quiz 1')
      quiz_item = module2.content_tags.create!(content: quiz, context: @course, indent: 1)
      module2.prerequisites = [{id: @module.id, type: "context_module", name: 'first_module'}]
      module2.completion_requirements = [{id: quiz_item.id, type: 'must_submit'}]
      module2.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module2_data = zip_package.parse_module_data.last
      expect(module2_data[:status]).to eq 'locked'
      expect(module2_data[:prereqs]).to eq [@module.id]
    end

    it "should show modules locked by date with status of locked" do
      lock_date = 1.day.from_now.iso8601
      @module.unlock_at = lock_date
      @module.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_data = zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'locked'
      expect(module_data[:unlockDate]).to eq lock_date
    end

    it "should not export module lock dates that are in the past" do
      lock_date = 5.minutes.ago.iso8601
      assign = @course.assignments.create!(title: 'Assignment 1')
      assign_item = @module.content_tags.create!(content: assign, context: @course)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.unlock_at = lock_date
      @module.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_data = zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'unlocked'
      expect(module_data[:unlockDate]).to be_nil
    end

    it "should not show module status as locked if it only has require sequential progress set to true" do
      assign = @course.assignments.create!(title: 'Assignment 1')
      assign_item = @module.content_tags.create!(content: assign, context: @course)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!
      @module.require_sequential_progress = true
      @module.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_data = zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'unlocked'
      expect(module_data[:sequential]).to be true
    end

    it "should show module status as completed if there are no further module items to complete" do
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_data = zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'completed'
    end

    it "should show module status of started if only some items are completed" do
      assign = @course.assignments.create!(title: 'Assignment 1')
      assign_item = @module.content_tags.create!(content: assign, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1')
      quiz_item = @module.content_tags.create!(content: quiz, context: @course, indent: 1)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'},
                                         {id: quiz_item.id, type: 'must_submit'}]
      @module.save!
      bare_submission_model(assign, @student)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_data = zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'started'
    end

    it "should not export unpublished context modules" do
      module2 = @course.context_modules.create!(name: 'second_module')
      module2.workflow_state = 'unpublished'
      module2.save!
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      expect(zip_package.parse_module_data.length).to eq 1
    end

    it "does not include unpublished prerequisites" do
      module2 = @course.context_modules.create(name: 'second_module')
      module2.prerequisites = "module_#{@module.id}"
      module2.save!
      @module.unpublish
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      data = zip_package.parse_module_data
      expect(data.length).to eq 1
      expect(data[0][:id]).to eq module2.id
      expect(data[0][:prereqs]).to eq []
    end

    it "should parse module completion requirements settings" do
      assign = @course.assignments.create!(title: 'Assignment 1')
      assign_item = @module.content_tags.create!(content: assign, context: @course)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!
      module2 = @course.context_modules.create!(name: 'second_module')
      quiz = @course.quizzes.create!(title: 'Quiz 1')
      quiz_item = module2.content_tags.create!(content: quiz, context: @course, indent: 1)
      module2.completion_requirements = [{id: quiz_item.id, type: 'must_view'}]
      module2.requirement_count = 1
      module2.save!
      @course.context_modules.create!(name: 'third_module')

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      expect(zip_package.parse_module_data[0][:requirement]).to eq :all
      expect(zip_package.parse_module_data[1][:requirement]).to eq :one
      expect(zip_package.parse_module_data[2][:requirement]).to be_nil
    end
  end

  context "with cached progress data" do
    before do
      enable_cache
      Rails.cache.write(@cache_key, {@module.id => {status: 'started'}}, expires_in: 30.minutes)
      @zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
    end

    it "should use cached module status" do
      module_data = @zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'started'
    end

    it "should not show module as locked if it is not locked at time of export" do
      Rails.cache.write(@cache_key, {@module.id => {status: 'locked'}}, expires_in: 30.minutes)
      module_data = @zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'started'
    end

    it "should show module as locked if it is locked at time of export" do
      module2 = @course.context_modules.create!(name: 'second_module')
      module2.unlock_at = 1.day.from_now
      module2.save!
      Rails.cache.write(@cache_key, {@module.id => {status: 'locked'}}, expires_in: 30.minutes)
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)

      module_data = zip_package.parse_module_data.last
      expect(module_data[:status]).to eq 'locked'
    end

    it "should use cached module item data" do
      url_item = @module.content_tags.create!(content_type: 'ExternalUrl', context: @course,
        title: 'url', url: 'https://www.google.com')
      @module.completion_requirements = [{id: url_item.id, type: 'must_view'}]
      Rails.cache.write(@cache_key, {@module.id => {items: {url_item.id => true}}}, expires_in: 30.minutes)
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)

      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:completed]).to be true
    end

    it "should calculate module state for modules created after current_progress" do
      module2 = @course.context_modules.create!(name: 'second_module')
      url_item = module2.content_tags.create!(content_type: 'ExternalUrl', context: @course,
        title: 'url', url: 'https://www.google.com')
      module2.completion_requirements = [{id: url_item.id, type: 'must_view'}]
      module2.prerequisites = [{id: @module.id, type: 'context_module', name: 'first_module'}]
      module2.save!

      module_data = @zip_package.parse_module_data[1]
      expect(module_data[:status]).to eq 'unlocked'
    end

    it "should calculate module item state as false for module items created after current_progress" do
      module2 = @course.context_modules.create!(name: 'second_module')
      url_item = module2.content_tags.create!(content_type: 'ExternalUrl', context: @course,
        title: 'url', url: 'https://www.google.com')
      module2.completion_requirements = [{id: url_item.id, type: 'must_view'}]
      module2.prerequisites = [{id: @module.id, type: 'context_module', name: 'first_module'}]
      module2.save!

      module_item_data = @zip_package.parse_module_item_data(module2).first
      expect(module_item_data[:completed]).to be false
    end
  end

  context "parse_module_item_data" do
    it "should parse id, type, title and indent for items in the module" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: "<p>Hi</p>")
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 3)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:id]).to eq assign_item.id
      expect(module_item_data[:title]).to eq 'Assignment 1'
      expect(module_item_data[:type]).to eq 'Assignment'
      expect(module_item_data[:indent]).to eq 3
    end

    it "should parse external tool items" do
      tool = @course.context_external_tools.create!(url: "https://example.com", shared_secret: "secret",
        consumer_key: "key", name: "tool")
      @module.content_tags.create!(content: tool, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:title]).to eq 'tool'
      expect(module_item_data[:type]).to eq 'ContextExternalTool'
    end

    it "should parse locked and completed status" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: "<p>Hi</p>")
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 3)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!
      bare_submission_model(assign, @student)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:locked]).to be false
      expect(module_item_data[:completed]).to be true
    end

    it "should parse points possible for assignments, quizzes and graded discussions" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10)
      @module.content_tags.create!(content: assign, context: @course)
      graded_discussion = @course.assignments.create!(title: 'Disc 2', points_possible: 3,
        submission_types: 'discussion_topic')
      @module.content_tags.create!(content: graded_discussion, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1')
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:pointsPossible]).to eq 10.0
      expect(module_item_data[1][:pointsPossible]).to eq 3.0
      expect(module_item_data[2][:pointsPossible]).to eq 0.0
    end

    it "should parse graded status for assignments, quizzes and graded discussions" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10)
      @module.content_tags.create!(content: assign, context: @course)
      graded_discussion = @course.assignments.create!(title: 'Disc 2', points_possible: 3,
        submission_types: 'discussion_topic')
      @module.content_tags.create!(content: graded_discussion, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1')
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:graded]).to be true
      expect(module_item_data[1][:graded]).to be true
      expect(module_item_data[2][:graded]).to be true
    end

    it "should parse assignmentExportId for quizzes and graded discussions" do
      graded_discussion = @course.discussion_topics.build(title: 'Disc 2')
      graded_discussion_assignment = @course.assignments.build({
        submission_types: 'discussion_topic',
        title: graded_discussion.title,
      })
      graded_discussion.assignment = graded_discussion_assignment
      graded_discussion.save!

      @module.content_tags.create!(content: graded_discussion, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1')
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)

      expect(module_item_data[0][:assignmentExportId]).to eq CC::CCHelper.create_key(graded_discussion_assignment)
      expect(module_item_data[1][:assignmentExportId]).to eq CC::CCHelper.create_key(quiz.assignment)
    end

    it "should parse graded status for not graded assignments, quizzes and discussions" do
      assign = @course.assignments.create!(title: 'Assignment 1', grading_type: 'not_graded')
      @module.content_tags.create!(content: assign, context: @course)
      discussion = @course.discussion_topics.create!(title: 'Disc 2')
      @module.content_tags.create!(content: discussion, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1', quiz_type: 'survey')
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:graded]).to be false
      expect(module_item_data[1][:graded]).to be false
      expect(module_item_data[2][:graded]).to be false
    end

    it "should parse due dates for assignments, quizzes and graded discussions" do
      due = 1.day.from_now
      unlock = 1.day.ago
      lock = 2.days.from_now
      assign = @course.assignments.create!(title: 'Assignment 1', due_at: due,
        unlock_at: unlock, lock_at: lock)
      @module.content_tags.create!(content: assign, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:dueAt]).to eq due.iso8601
      expect(module_item_data[:unlockAt]).to eq unlock.iso8601
      expect(module_item_data[:lockAt]).to eq lock.iso8601
    end

    it "should parse lock dates for ungraded discussions" do
      unlock = 1.day.ago
      lock = 2.days.from_now
      dt = @course.discussion_topics.create!(title: 'DT', lock_at: lock, unlock_at: unlock)
      @module.content_tags.create!(content: dt, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:unlockAt]).to eq unlock.iso8601
      expect(module_item_data[:lockAt]).to eq lock.iso8601
    end

    it "should parse submission types for assignments" do
      assign = @course.assignments.create!(title: 'Assignment 1',
        submission_types: 'online_text_entry,online_upload')
      @module.content_tags.create!(content: assign, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:submissionTypes]).to eq 'a text entry box or a file upload'
    end

    it "should parse question count, time limit and allowed attempts for quizzes" do
      quiz = @course.quizzes.create!(title: 'Quiz 1', time_limit: 5, allowed_attempts: 2)
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:questionCount]).to eq 0
      expect(module_item_data[:timeLimit]).to eq 5
      expect(module_item_data[:attempts]).to eq 2
    end

    it "should parse module item requirements" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10)
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 0)
      @module.content_tags.create!(content: assign, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1')
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:requirement]).to eq 'must_submit'
      expect(module_item_data[1][:requirement]).to be_nil
    end

    it "should parse required points if module item requirement is min_score" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10)
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 0)
      @module.content_tags.create!(content: assign, context: @course)
      @module.completion_requirements = [{id: assign_item.id, type: 'min_score', min_score: 7}]
      @module.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:requiredPoints]).to eq 7
    end

    it "should parse export id for assignments, quizzes, discussions and wiki pages" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10)
      @module.content_tags.create!(content: assign, context: @course)
      wiki = @course.wiki_pages.create!(title: 'Wiki Page 1', url: 'wiki-page-1', wiki: @course.wiki)
      @module.content_tags.create!(content: wiki, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:exportId]).to eq CC::CCHelper.create_key(assign)
      expect(module_item_data[1][:exportId]).to eq 'wiki-page-1'
    end

    it "should parse content for assignments and quizzes" do
      assign = @course.assignments.create!(title: 'Assignment 1', description: '<p>Assignment</p>')
      @module.content_tags.create!(content: assign, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1', description: '<p>Quiz</p>')
      @module.content_tags.create!(content: quiz, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq '<p>Assignment</p>'
      expect(module_item_data[1][:content]).to eq '<p>Quiz</p>'
    end

    it "should parse content for discussions" do
      discussion = @course.discussion_topics.create!(title: 'Discussion 1', message: "<h1>Discussion</h1>")
      graded_discussion = @course.assignments.create!(title: 'Disc 2', description: '<p>Graded Discussion</p>',
        submission_types: 'discussion_topic')
      @module.content_tags.create!(content: discussion, context: @course)
      @module.content_tags.create!(content: graded_discussion, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq '<h1>Discussion</h1>'
      expect(module_item_data[1][:content]).to eq '<p>Graded Discussion</p>'
    end

    it "should parse content for wiki pages" do
      wiki = @course.wiki_pages.create!(title: 'Wiki Page 1', body: "<h2>Wiki Page</h2>", wiki: @course.wiki)
      @module.content_tags.create!(content: wiki, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq '<h2>Wiki Page</h2>'
    end

    it "should parse URL for url items" do
      @module.content_tags.create!(content_type: 'ExternalUrl', context: @course,
        title: 'url', url: 'https://www.google.com')

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq 'https://www.google.com'
    end

    it "should parse file data for attachments" do
      file = attachment_model(context: @course, display_name: 'file1.jpg', filename: '1234__file1.jpg')
      @module.content_tags.create!(content: file, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      file_data = zip_package.parse_module_item_data(@module).first
      expect(file_data[:content]).to eq "viewer/files/file1.jpg"
    end

    it "should not export item content for items in locked modules" do
      assign1 = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: "<p>Yo</p>")
      assign_item1 = @module.content_tags.create!(content: assign1, context: @course, indent: 0)
      @module.completion_requirements = [{id: assign_item1.id, type: 'must_submit'}]
      @module.save!
      module2 = @course.context_modules.create!(name: 'second_module')
      module2.prerequisites = [{id: @module.id, type: 'context_module', name: 'first_module'}]
      module2.save!
      assign2 = @course.assignments.create!(title: 'Assignment 2', points_possible: 10, description: "<p>Hi</p>")
      module2.content_tags.create!(content: assign2, context: @course, indent: 0)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(module2)
      expect(module_item_data.first.values.include?('<p>Hi</p>')).to be false
    end

    it "should not export item content for items locked by prerequisites" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>')
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 0)
      @module.content_tags.create!(content: assign, context: @course, indent: 0)
      wiki = @course.wiki_pages.create!(title: 'Wiki Page 1', body: '<p>Yo</p>', wiki: @course.wiki)
      @module.content_tags.create!(content: wiki, context: @course, indent: 4)
      @module.require_sequential_progress = true
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data.first[:content]).to eq '<p>Hi</p>'
      expect(module_item_data.last[:locked]).to be true
      expect(module_item_data.last.values.include?('<p>Yo</p>')).to be false
    end

    it "should not export items contents for items locked by content dates" do
      assign = @course.assignments.create!(title: 'Assignment 1', description: '<p>Hi</p>', lock_at: 1.day.ago)
      @module.content_tags.create!(content: assign, context: @course, indent: 0)
      @module.content_tags.create!(content: assign, context: @course, indent: 0)
      file = attachment_model(context: @course, filename: '1234__file1.jpg', lock_at: 1.day.ago)
      @module.content_tags.create!(content: file, context: @course)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to be nil
      expect(module_item_data[0][:locked]).to be true
      expect(module_item_data[1][:content]).to be nil
      expect(module_item_data[1][:locked]).to be true
    end

    it "should not export unpublished module items" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>')
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 0)
      assign_item.workflow_state = 'unpublished'
      assign_item.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data.length).to eq 0
    end

    it "should not export items not visible to the user" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>')
      create_adhoc_override_for_assignment(assign, [@student])
      student_in_course(active_all: true, user_name: '2-student')
      assign.only_visible_to_overrides = true
      assign.save!
      @module.content_tags.create!(content: assign, context: @course, indent: 0)

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module)
      expect(module_item_data.length).to eq 0
    end

    it "should export correct dates for assignments with due date overrides" do
      due = 1.hour.from_now
      lock = 2.hours.from_now
      unlock = 1.hour.ago
      assign = @course.assignments.create!(title: 'Assignment 1', due_at: 1.day.from_now, lock_at: 2.days.from_now,
        unlock_at: 1.day.ago)
      @module.content_tags.create!(content: assign, context: @course, indent: 0)
      assignment_override_model(assignment: assign, due_at: due, lock_at: lock, unlock_at: unlock)
      @override.set_type = "ADHOC"
      override_student = @override.assignment_override_students.build
      override_student.user = @student
      override_student.save!

      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:dueAt]).to eq due.iso8601
      expect(module_item_data[:lockAt]).to eq lock.iso8601
      expect(module_item_data[:unlockAt]).to eq unlock.iso8601
    end
  end

  context "non module items" do
    def create_zip_package
      export = @course.content_exports.build
      export.export_type = ContentExport::COMMON_CARTRIDGE
      export.user = @student
      export.save
      export.export_course
      exporter = CC::Exporter::WebZip::Exporter.new(export.attachment.open, false, :web_zip)
      CC::Exporter::WebZip::ZipPackage.new(exporter, @course, @student, @cache_key)
    end

    context "with course navigation tabs enabled" do
      before :once do
        @course.tab_configuration = [
          {'id' => Course::TAB_ASSIGNMENTS},
          {'id' => Course::TAB_PAGES},
          {'id' => Course::TAB_QUIZZES},
          {'id' => Course::TAB_DISCUSSIONS},
          {'id' => Course::TAB_FILES}
        ]
      end

      it "should parse non-module assignments" do
        due = 1.day.from_now
        lock = 2.days.from_now
        unlock = 1.day.ago
        assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>',
          submission_types: 'online_text_entry,online_upload', due_at: due, lock_at: lock,
          unlock_at: unlock)
        zip_package = create_zip_package
        assignment_data = zip_package.parse_non_module_items(:assignments)
        expect(assignment_data).to eq [{
          exportId: CC::CCHelper.create_key(assign), title: 'Assignment 1', type: 'Assignment',
          content: '<p>Hi</p>', submissionTypes: "a text entry box or a file upload", graded: true,
          pointsPossible: 10.0, dueAt: due.in_time_zone(@student.time_zone).iso8601,
          lockAt: lock.in_time_zone(@student.time_zone).iso8601,
          unlockAt: unlock.in_time_zone(@student.time_zone).iso8601
        }]
      end

      it "should parse non-module discussions" do
        disc = @course.discussion_topics.create!(title: 'Discussion 1', message: "<h1>Discussion</h1>")
        zip_package = create_zip_package
        disc_data = zip_package.parse_non_module_items(:discussion_topics)
        expect(disc_data).to eq [{
            exportId: CC::CCHelper.create_key(disc), title: 'Discussion 1', type: 'DiscussionTopic',
            graded: false, content: "<h1>Discussion</h1>", lockAt: nil, unlockAt: nil
          }]
      end

      it "should parse non-module quizzes" do
        quiz = @course.quizzes.create!(title: 'Quiz 1', time_limit: 5, allowed_attempts: 2)
        quiz.publish!
        zip_package = create_zip_package
        quiz_data = zip_package.parse_non_module_items(:quizzes)
        expect(quiz_data).to eq [{
            exportId: CC::CCHelper.create_key(quiz), title: 'Quiz 1', type: 'Quizzes::Quiz', questionCount: 0,
            timeLimit: 5, attempts: 2, graded: true, pointsPossible: 0.0, dueAt: nil, lockAt: nil,
            unlockAt: nil, content: nil, assignmentExportId: CC::CCHelper.create_key(quiz.assignment)
          }]
      end

      it "should parse non-module wiki pages" do
        @course.wiki_pages.create!(title: 'Page 1', url: 'page-1', wiki: @course.wiki)
        zip_package = create_zip_package
        wiki_data = zip_package.parse_non_module_items(:wiki_pages)
        expect(wiki_data).to eq [{exportId: 'page-1', title: 'Page 1', type: 'WikiPage', content: '', frontPage: false}]
      end

      it "should parse front page" do
        wiki_page = @course.wiki_pages.create!(title: 'Page 1', url: 'page-1', wiki: @course.wiki)
        @course.wiki.set_front_page_url!(wiki_page.url)
        zip_package = create_zip_package
        wiki_data = zip_package.parse_non_module_items(:wiki_pages)
        expect(wiki_data).to eq [{exportId: 'page-1', title: 'Page 1', type: 'WikiPage', content: '', frontPage: true}]
      end

      it "should not fail on missing items" do
        wiki = @course.wiki_pages.create!(title: 'Page 1', url: 'page-1', wiki: @course.wiki, body: '<p>Hi</p>')
        zip_package = create_zip_package
        wiki.title = 'Wiki Page 2'
        wiki.save!
        wiki_data = zip_package.parse_non_module_items(:wiki_pages)
        expect(wiki_data).to eq [{exportId: 'page-1', title: 'Page 1', type: 'WikiPage', content: '<p>Hi</p>',
          frontPage: false}]
      end

      it "should export files" do
        add_file(fixture_file_upload('files/amazing_file.txt', 'plain/txt'), @course, "amazing_file.txt")
        zip_package = create_zip_package
        course_data = zip_package.parse_course_data
        expect(course_data[:files]).to eq [{type: "file", name: "amazing_file.txt", size: 26, files: nil}]
      end
    end

    context "with course navigation tabs disabled" do
      before :once do
        @course.tab_configuration = [
          {'id' => Course::TAB_ASSIGNMENTS, 'hidden' => true},
          {'id' => Course::TAB_PAGES, 'hidden' => true},
          {'id' => Course::TAB_QUIZZES, 'hidden' => true},
          {'id' => Course::TAB_DISCUSSIONS, 'hidden' => true},
          {'id' => Course::TAB_FILES, 'hidden' => true}
        ]
      end

      it "should not export items not linked elsewhere" do
        @course.assignments.create!(title: 'Assignment 1')
        add_file(fixture_file_upload('files/amazing_file.txt', 'plain/txt'), @course, "amazing_file.txt")
        file = add_file(fixture_file_upload('files/cn_image.jpg', 'image/jpg'), @course, "cn_image.jpg")
        @module.content_tags.create!(content: file, context: @course, indent: 0)
        zip_package = create_zip_package
        course_data = zip_package.parse_course_data
        expect(course_data[:assignments]).to eq []
        expect(course_data[:files]).to eq [{type: "file", name: "cn_image.jpg", size: 30339, files: nil}]
      end

      it "should export items that are module items" do
        assign = @course.assignments.create!(title: 'Assignment 1', description: '<p>Hi</p>')
        file = add_file(fixture_file_upload('files/amazing_file.txt', 'plain/txt'), @course, "amazing_file.txt")
        @module.content_tags.create!(content: assign, context: @course, indent: 0)
        @module.content_tags.create!(content: file, context: @course, indent: 0)
        zip_package = create_zip_package
        course_data = zip_package.parse_course_data
        expect(course_data[:assignments]).to eq [{
            exportId: CC::CCHelper.create_key(assign), title: 'Assignment 1', type: 'Assignment',
            content: '<p>Hi</p>', submissionTypes: nil, graded: true,
            pointsPossible: nil, dueAt: nil, lockAt: nil, unlockAt: nil
          }]
        expect(course_data[:files]).to eq [{type: "file", name: "amazing_file.txt", size: 26, files: nil}]
      end

      it "should export assignments linked from module items" do
        assign = @course.assignments.create!(title: 'Assignment 1', description: '<p>Hi</p>')
        quiz_body = "<a href=\"/courses/#{@course.id}/assignments/#{assign.id}\">Link</a>"
        quiz = @course.quizzes.create!(title: 'Quiz 1', description: quiz_body)
        quiz.publish!
        @module.content_tags.create!(content: quiz, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments][0][:exportId]).to eq CC::CCHelper.create_key(assign)
        expect(course_data[:assignments].length).to eq 1
        expect(course_data[:quizzes][0][:exportId]).to eq CC::CCHelper.create_key(quiz)
        expected = "<a href=\"assignments/#{CC::CCHelper.create_key(assign)}\">Link</a>"
        expect(course_data[:quizzes][0][:content]).to eq expected
        expect(course_data[:quizzes][0][:assignmentExportId]).to eq CC::CCHelper.create_key(quiz.assignment)
      end

      it "should export quizzes linked from module items" do
        quiz = @course.quizzes.create!(title: 'Quiz 1', description: "<p>Hi</p>")
        quiz.publish!
        assign = @course.assignments.create!(title: 'Assignment 1',
          description: "<a href=\"/courses/#{@course.id}/quizzes/#{quiz.id}\">Link</a>")
        @module.content_tags.create!(content: assign, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        quiz_key = CC::CCHelper.create_key(quiz)
        expect(course_data[:assignments][0][:exportId]).to eq CC::CCHelper.create_key(assign)
        expect(course_data[:assignments][0][:content]).to eq "<a href=\"quizzes/#{quiz_key}\">Link</a>"
        expect(course_data[:assignments].length).to eq 1
        expect(course_data[:quizzes][0][:exportId]).to eq quiz_key
        expect(course_data[:quizzes].length).to eq 1
        expect(course_data[:quizzes][0][:assignmentExportId]).to eq CC::CCHelper.create_key(quiz.assignment)
      end

      it "should export pages linked from module items" do
        page = @course.wiki_pages.create!(title: 'Page 1', body: "<p>Hi</p>", wiki: @course.wiki)
        assign = @course.assignments.create!(title: 'Assignment 1',
          description: "<a href=\"/courses/#{@course.id}/pages/#{page.id}\">Link</a>")
        @module.content_tags.create!(content: assign, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments][0][:exportId]).to eq CC::CCHelper.create_key(assign)
        expect(course_data[:assignments][0][:content]).to eq "<a href=\"pages/#{page.url}\">Link</a>"
        expect(course_data[:assignments].length).to eq 1
        expect(course_data[:pages][0][:exportId]).to eq page.url
        expect(course_data[:pages].length).to eq 1
      end

      it "should export discussion topics linked from module items" do
        discussion = @course.discussion_topics.create!(title: 'Discussion 1', message: "<p>Hi</p>")
        assign = @course.assignments.create!(title: 'Assignment 1',
          description: "<a href=\"/courses/#{@course.id}/discussion_topics/#{discussion.id}\">Link</a>")
        @module.content_tags.create!(content: assign, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments][0][:exportId]).to eq CC::CCHelper.create_key(assign)
        expected = "<a href=\"discussion_topics/#{CC::CCHelper.create_key(discussion)}\">Link</a>"
        expect(course_data[:assignments][0][:content]).to eq expected
        expect(course_data[:assignments].length).to eq 1
        expect(course_data[:discussion_topics][0][:exportId]).to eq CC::CCHelper.create_key(discussion)
        expect(course_data[:discussion_topics].length).to eq 1
      end

      it "should export files linked from module items" do
        file = add_file(fixture_file_upload('files/amazing_file.txt', 'plain/txt'), @course, "amazing_file.txt")
        assign = @course.assignments.create!(title: 'Assignment 1',
          description: "<a href=\"/courses/#{@course.id}/files/#{file.id}/download?wrap=1\">Link</a>")
        @module.content_tags.create!(content: assign, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments][0][:exportId]).to eq CC::CCHelper.create_key(assign)
        expected = "<a href=\"viewer/files/amazing_file.txt?canvas_download=1&amp;canvas_qs_wrap=1\">Link</a>"
        expect(course_data[:assignments][0][:content]).to eq expected
        expect(course_data[:assignments].length).to eq 1
        expect(course_data[:files]).to eq [{type: "file", name: "amazing_file.txt", size: 26, files: nil}]
      end

      it "should export items linked from other linked items" do
        file = add_file(fixture_file_upload('files/amazing_file.txt', 'plain/txt'), @course, "amazing_file.txt")
        assign = @course.assignments.create!(title: 'Assignment 1',
          description: "<a href=\"/courses/#{@course.id}/files/#{file.id}\">Link</a>")
        page = @course.wiki_pages.create!(title: 'Page 1', wiki: @course.wiki,
          body: "<a href=\"/courses/#{@course.id}/assignments/#{assign.id}\">Link</a>")
        @module.content_tags.create!(content: page, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments][0][:exportId]).to eq CC::CCHelper.create_key(assign)
        expect(course_data[:assignments][0][:content]).to eq "<a href=\"viewer/files/amazing_file.txt\">Link</a>"
        expect(course_data[:assignments].length).to eq 1
        page_data = course_data[:pages][0]
        expect(page_data[:exportId]).to eq page.url
        expect(page_data[:content]).to eq "<a href=\"assignments/#{CC::CCHelper.create_key(assign)}\">Link</a>"
        expect(course_data[:pages].length).to eq 1
        expect(course_data[:files]).to eq [{type: "file", name: "amazing_file.txt", size: 26, files: nil}]
      end

      it "should handle circle-linked items" do
        assign = @course.assignments.create!(title: 'Assignment 1',
          description: "<a href=\"/courses/#{@course.id}/pages/page-1\">Link</a>")
        page = @course.wiki_pages.create!(title: 'Page 1', wiki: @course.wiki,
          body: "<a href=\"/courses/#{@course.id}/assignments/#{assign.id}\">Link</a>")
        @module.content_tags.create!(content: page, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments]).to eq [{
            exportId: CC::CCHelper.create_key(assign), title: 'Assignment 1', type: 'Assignment',
            content: "<a href=\"pages/page-1\">Link</a>", submissionTypes: nil, graded: true,
            pointsPossible: nil, dueAt: nil, lockAt: nil, unlockAt: nil
          }]
        expect(course_data[:pages]).to eq [{exportId: 'page-1', title: 'Page 1', type: 'WikiPage',
          content: "<a href=\"assignments/#{CC::CCHelper.create_key(assign)}\">Link</a>", frontPage: false}]
      end

      it "should export items linked as images" do
        due_at = 1.day.ago
        file = add_file(fixture_file_upload('files/cn_image.jpg', 'image/jpg'), @course, "cn_image.jpg")
        survey = @course.quizzes.create!(title: 'Survey 1', due_at: due_at, quiz_type: 'survey',
          description: "<img src=\"/courses/#{@course.id}/files/#{file.id}\" />")
        survey.publish!
        @module.content_tags.create!(content: survey, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:quizzes]).to eq [{
            exportId: CC::CCHelper.create_key(survey), title: 'Survey 1', type: 'Quizzes::Quiz',
            content: "<img src=\"viewer/files/cn_image.jpg\">",
            assignmentExportId: CC::CCHelper.create_key(survey.assignment), questionCount: 0, timeLimit: nil,
            attempts: 1, graded: false, dueAt: due_at.iso8601, lockAt: nil, unlockAt: nil
          }]
        expect(course_data[:files]).to eq [{type: "file", name: "cn_image.jpg", size: 30339, files: nil}]
      end

      it "should export quizzes and discussions that are linked as assignments" do
        quiz = @course.quizzes.create!(title: 'Quiz 1')
        quiz.publish!
        assign = @course.assignments.create!(title: 'Assignment 1',
          description: "<a href=\"/courses/#{@course.id}/assignments/#{quiz.assignment.id}\">Link</a>")
        @module.content_tags.create!(content: assign, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments]).to eq [{
            exportId: CC::CCHelper.create_key(assign), title: 'Assignment 1', type: 'Assignment',
            content: "<a href=\"assignments/#{CC::CCHelper.create_key(quiz.assignment)}\">Link</a>",
            submissionTypes: nil, graded: true, pointsPossible: nil, dueAt: nil, lockAt: nil, unlockAt: nil
          }]
        expect(course_data[:quizzes]).to eq [{
            exportId: CC::CCHelper.create_key(quiz), title: 'Quiz 1', type: 'Quizzes::Quiz',
            content: nil, assignmentExportId: CC::CCHelper.create_key(quiz.assignment), questionCount: 0,
            timeLimit: nil, attempts: 1, graded: true, pointsPossible: 0.0, dueAt: nil, lockAt: nil, unlockAt: nil
          }]
      end

      it "should not export quizzes when locked by date" do
        quiz = @course.quizzes.create!(title: 'Quiz 1', description: "stuff",
          workflow_state: "available", unlock_at: 3.days.from_now)
        @module.content_tags.create!(content: quiz, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:quizzes]).to be_empty
      end

      it "should export linked file items in sub-folders" do
        folder = @course.folders.create!(name: 'folder#1', parent_folder: Folder.root_folders(@course).first)
        file = add_file(fixture_file_upload('files/cn_image.jpg', 'image/jpg'), @course, "cn_image.jpg", folder)
        disc = @course.discussion_topics.create!(title: 'Discussion 1',
          message: "<img src=\"/courses/#{@course.id}/files/#{file.id}\" />")
        @module.content_tags.create!(content: disc, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:discussion_topics]).to eq [{
            exportId: CC::CCHelper.create_key(disc), title: 'Discussion 1', type: 'DiscussionTopic',
            content: "<img src=\"viewer/files/folder%231/cn_image.jpg\">",
            lockAt: nil, unlockAt: nil, graded: false
          }]
        expect(course_data[:files]).to eq [{type: "folder", name: "folder#1", size: nil, files:
          [{type: "file", name: "cn_image.jpg", size: 30339, files: nil}]}]
      end

      it "should not crash on index links" do
        page = @course.wiki_pages.create!(title: 'Page 1', wiki: @course.wiki,
          body: "<a href=\"/courses/#{@course.id}/announcements\">Link</a>" \
          "<a href=\"/courses/#{@course.id}/wiki\">Link</a>")
        @module.content_tags.create!(content: page, context: @course, indent: 0)
        course_data = create_zip_package.parse_course_data
        expect(course_data[:pages]).to eq [{exportId: 'page-1', title: 'Page 1', type: 'WikiPage',
          content: "<a href=\"announcements\">Link</a><a href=\"wiki/\">Link</a>", frontPage: false}]
      end

      it "should not mark locked items as exported" do
        file = add_file(fixture_file_upload('files/amazing_file.txt', 'plain/txt'), @course, "amazing_file.txt")
        file2 = add_file(fixture_file_upload('files/cn_image.jpg', 'image/jpg'), @course, "cn_image.jpg")
        page = @course.wiki_pages.create!(title: 'Page 1', wiki: @course.wiki,
          body: "<p>stuff</p>")
        @module.content_tags.create!(content: file2, context: @course)
        module2 = @course.context_modules.create!(name: 'module 2')
        module2.content_tags.create!(content: file, context: @course)
        module2.content_tags.create!(content: page, context: @course)
        module2.unlock_at = 1.day.from_now
        module2.save!
        course_data = create_zip_package.parse_course_data
        expect(course_data[:files]).to eq [{type: "file", name: "cn_image.jpg", size: 30339, files: nil}]
        expect(course_data[:pages]).to eq []
      end
    end

    context "with assignment tab enabled, but quizzes/discussion tab disabled" do
      before :once do
        @course.tab_configuration = [
          {'id' => Course::TAB_ASSIGNMENTS},
          {'id' => Course::TAB_PAGES, 'hidden' => true},
          {'id' => Course::TAB_QUIZZES, 'hidden' => true},
          {'id' => Course::TAB_DISCUSSIONS, 'hidden' => true},
          {'id' => Course::TAB_FILES, 'hidden' => true}
        ]
      end

      it "should export linked graded quizzes/discussions if item tab is hidden but assignments tab is available" do
        survey = @course.quizzes.create!(title: 'Survey 1', quiz_type: 'survey')
        survey.publish!
        quiz = @course.quizzes.create!(title: 'Quiz 1')
        quiz.publish!
        course_data = create_zip_package.parse_course_data
        expect(course_data[:assignments]).to eq []
        expect(course_data[:quizzes]).to eq [{
            exportId: CC::CCHelper.create_key(quiz), title: 'Quiz 1', type: 'Quizzes::Quiz',
            content: nil, assignmentExportId: CC::CCHelper.create_key(quiz.assignment), questionCount: 0,
            timeLimit: nil, attempts: 1, graded: true, pointsPossible: 0.0, dueAt: nil, lockAt: nil, unlockAt: nil
          }]
      end
    end
  end

  context "convert_html_to_local" do
    before do
      @zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, 'key')
    end

    it "should export html file links as local file links" do
      attachment_model(context: @course, display_name: 'file1.jpg', filename: 'file1.jpg')
      html = %(<a href="/courses/#{@course.id}/files/#{@attachment.id}/download") +
             %( data-api-returntype="File">file1.jpg</a>)
      expected_html = %(<a href="viewer/files/file1.jpg?canvas_download=1") +
                      %( data-api-returntype="File">file1.jpg</a>)
      converted_html = @zip_package.convert_html_to_local(html)
      expect(converted_html).to eq expected_html
    end

    it "should export html content links as local content links" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>')
      html = %(<a title="Assignment 1" href="/courses/#{@course.id}/assignments/#{assign.id}") +
             %( data-api-returntype="Assignment">Assignment 1</a>)
      expected_html = %(<a title="Assignment 1" href="assignments/#{CC::CCHelper.create_key(assign)}") +
                    %( data-api-returntype="Assignment">Assignment 1</a>)
      converted_html = @zip_package.convert_html_to_local(html)
      expect(converted_html).to eq expected_html
    end

    it "should convert html content links that are locked" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10,
        description: '<p>Hi</p>', unlock_at: 5.days.from_now)
      html = %(<a title="Assignment 1" href="/courses/#{@course.id}/assignments/#{assign.id}") +
             %( data-api-returntype="Assignment">Assignment 1</a>)
      expected_html = %(<a title="Assignment 1" href="assignments/#{CC::CCHelper.create_key(assign)}") +
                    %( data-api-returntype="Assignment">Assignment 1</a>)
      converted_html = @zip_package.convert_html_to_local(html)
      expect(converted_html).to eq expected_html
    end
  end
end
