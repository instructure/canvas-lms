# coding: utf-8
require 'spec_helper'

describe "ZipPackage" do
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

    before do
      @zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
    end

    it "should map context module data from Canvas" do
      module_data = @zip_package.parse_module_data
      expect(module_data).to eq [{id: @module.id, name: 'first_module', status: 'completed',
        unlockDate: nil, prereqs: [], requirement: nil, sequential: false, items: []}]
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

      module2_data = @zip_package.parse_module_data.last
      expect(module2_data[:status]).to eq 'locked'
      expect(module2_data[:prereqs]).to eq [@module.id]
    end

    it "should show modules locked by date with status of locked" do
      lock_date = 1.day.from_now.iso8601
      @module.unlock_at = lock_date
      @module.save!

      module_data = @zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'locked'
      expect(module_data[:unlockDate]).to eq lock_date
    end

    it "should not show module status as locked if it only has require sequential progress set to true" do
      assign = @course.assignments.create!(title: 'Assignment 1')
      assign_item = @module.content_tags.create!(content: assign, context: @course)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!
      @module.require_sequential_progress = true
      @module.save!

      module_data = @zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'unlocked'
      expect(module_data[:sequential]).to be true
    end

    it "should show module status as completed if there are no further module items to complete" do
      module_data = @zip_package.parse_module_data.first
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

      module_data = @zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'started'
    end

    it "should not export unpublished context modules" do
      module2 = @course.context_modules.create!(name: 'second_module')
      module2.workflow_state = 'unpublished'
      module2.save!
      expect(@zip_package.parse_module_data.length).to eq 1
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

      expect(@zip_package.parse_module_data[0][:requirement]).to eq :all
      expect(@zip_package.parse_module_data[1][:requirement]).to eq :one
      expect(@zip_package.parse_module_data[2][:requirement]).to be_nil
    end
  end

  context "with_cached_progress_data" do
    before do
      enable_cache
    end

    it "should use cached module status" do
      Rails.cache.fetch(@cache_key, expires_in: 30.minutes){ {@module.id => {status: 'started'}} }
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)

      module_data = zip_package.parse_module_data.first
      expect(module_data[:status]).to eq 'started'
    end

    it "should use cached module item data" do
      url_item = @module.content_tags.create!(content_type: 'ExternalUrl', context: @course,
        title: 'url', url: 'https://www.google.com')
      @module.completion_requirements = [{id: url_item.id, type: 'must_view'}]
      @module.save!
      Rails.cache.fetch(@cache_key, expires_in: 30.minutes){ {@module.id => {items: {url_item.id => true}}} }
      zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)

      module_item_data = zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:completed]).to be true
    end
  end

  context "parse_module_item_data" do
    before do
      @zip_package = CC::Exporter::WebZip::ZipPackage.new(@exporter, @course, @student, @cache_key)
    end

    it "should parse id, type, title and indent for items in the module" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: "<p>Hi</p>")
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 3)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!

      module_item_data = @zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:id]).to eq assign_item.id
      expect(module_item_data[:title]).to eq 'Assignment 1'
      expect(module_item_data[:type]).to eq 'Assignment'
      expect(module_item_data[:indent]).to eq 3
    end

    it "should parse locked and completed status" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: "<p>Hi</p>")
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 3)
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!
      bare_submission_model(assign, @student)

      module_item_data = @zip_package.parse_module_item_data(@module).first
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

      module_item_data = @zip_package.parse_module_item_data(@module)
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

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:graded]).to be true
      expect(module_item_data[1][:graded]).to be true
      expect(module_item_data[2][:graded]).to be true
    end

    it "should parse graded status for not graded assignments, quizzes and discussions" do
      assign = @course.assignments.create!(title: 'Assignment 1', grading_type: 'not_graded')
      @module.content_tags.create!(content: assign, context: @course)
      discussion = @course.discussion_topics.create!(title: 'Disc 2')
      @module.content_tags.create!(content: discussion, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1', quiz_type: 'survey')
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)

      module_item_data = @zip_package.parse_module_item_data(@module)
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

      module_item_data = @zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:dueAt]).to eq due.iso8601
      expect(module_item_data[:unlockAt]).to eq unlock.iso8601
      expect(module_item_data[:lockAt]).to eq lock.iso8601
    end

    it "should parse submission types for assignments" do
      assign = @course.assignments.create!(title: 'Assignment 1',
        submission_types: 'online_text_entry,online_upload')
      @module.content_tags.create!(content: assign, context: @course)

      module_item_data = @zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:submissionTypes]).to eq 'a text entry box or a file upload'
    end

    it "should parse question count, time limit and allowed attempts for quizzes" do
      quiz = @course.quizzes.create!(title: 'Quiz 1', time_limit: 5, allowed_attempts: 2)
      @module.content_tags.create!(content: quiz, context: @course, indent: 1)

      module_item_data = @zip_package.parse_module_item_data(@module).first
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

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:requirement]).to eq 'must_submit'
      expect(module_item_data[1][:requirement]).to be_nil
    end

    it "should parse required points if module item requirement is min_score" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10)
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 0)
      @module.content_tags.create!(content: assign, context: @course)
      @module.completion_requirements = [{id: assign_item.id, type: 'min_score', min_score: 7}]
      @module.save!

      module_item_data = @zip_package.parse_module_item_data(@module).first
      expect(module_item_data[:requiredPoints]).to eq 7
    end

    it "should parse content for assignments and quizzes" do
      assign = @course.assignments.create!(title: 'Assignment 1', description: '<p>Assignment</p>')
      @module.content_tags.create!(content: assign, context: @course)
      quiz = @course.quizzes.create!(title: 'Quiz 1', description: '<p>Quiz</p>')
      @module.content_tags.create!(content: quiz, context: @course)

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq '<p>Assignment</p>'
      expect(module_item_data[1][:content]).to eq '<p>Quiz</p>'
    end

    it "should parse content for discussions" do
      discussion = @course.discussion_topics.create!(title: 'Discussion 1', message: "<h1>Discussion</h1>")
      graded_discussion = @course.assignments.create!(title: 'Disc 2', description: '<p>Graded Discussion</p>',
        submission_types: 'discussion_topic')
      @module.content_tags.create!(content: discussion, context: @course)
      @module.content_tags.create!(content: graded_discussion, context: @course)

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq '<h1>Discussion</h1>'
      expect(module_item_data[1][:content]).to eq '<p>Graded Discussion</p>'
    end

    it "should parse content for wiki pages" do
      wiki = @course.wiki_pages.create!(title: 'Wiki Page 1', body: "<h2>Wiki Page</h2>", wiki: @course.wiki)
      @module.content_tags.create!(content: wiki, context: @course)

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq '<h2>Wiki Page</h2>'
    end

    it "should parse URL for url items" do
      @module.content_tags.create!(content_type: 'ExternalUrl', context: @course,
        title: 'url', url: 'https://www.google.com')

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data[0][:content]).to eq 'https://www.google.com'
    end

    it "should parse file data for attachments" do
      file = attachment_model(context: @course, display_name: 'file1.jpg', filename: 'file1.jpg')
      @module.content_tags.create!(content: file, context: @course)

      file_data = @zip_package.parse_module_item_data(@module).first
      filename_prefix = @zip_package.instance_variable_get(:@filename_prefix)
      expect(file_data[:content]).to eq "#{filename_prefix}/viewer/files/file1.jpg"
    end

    it "should not export item content for items in locked modules" do
      module2 = @course.context_modules.create!(name: 'second_module')
      module2.prerequisites = [{id: @module.id, type: 'context_module', name: 'first_module'}]
      module2.save!
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: "<p>Hi</p>")
      module2.content_tags.create!(content: assign, context: @course, indent: 0)

      module_item_data = @zip_package.parse_module_item_data(module2)
      expect(module_item_data.first.values.include?('<p>Hi</p>')).to be false
    end

    it "should not export item content for locked items" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>')
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 0)
      @module.content_tags.create!(content: assign, context: @course, indent: 0)
      wiki = @course.wiki_pages.create!(title: 'Wiki Page 1', body: '<p>Yo</p>', wiki: @course.wiki)
      @module.content_tags.create!(content: wiki, context: @course, indent: 4)
      @module.require_sequential_progress = true
      @module.completion_requirements = [{id: assign_item.id, type: 'must_submit'}]
      @module.save!

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data.first[:content]).to eq '<p>Hi</p>'
      expect(module_item_data.last[:locked]).to be true
      expect(module_item_data.last.values.include?('<p>Yo</p>')).to be false
    end

    it "should not export unpublished module items" do
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>')
      assign_item = @module.content_tags.create!(content: assign, context: @course, indent: 0)
      assign_item.workflow_state = 'unpublished'
      assign_item.save!

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data.length).to eq 0
    end

    it "should not export items not visible to the user" do
      student_in_course(active_all: true, user_name: '2-student')
      assign = @course.assignments.create!(title: 'Assignment 1', points_possible: 10, description: '<p>Hi</p>')
      create_adhoc_override_for_assignment(assign, [@student])
      assign.only_visible_to_overrides = true
      assign.save!
      @module.content_tags.create!(content: assign, context: @course, indent: 0)

      module_item_data = @zip_package.parse_module_item_data(@module)
      expect(module_item_data.length).to eq 0
    end
  end
end
