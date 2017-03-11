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

    it "should not export item content for locked items" do
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

  context "parse_non_module_items" do
    def create_zip_package
      export = @course.content_exports.build
      export.export_type = ContentExport::COMMON_CARTRIDGE
      export.user = @student
      export.save
      export.export_course
      exporter = CC::Exporter::WebZip::Exporter.new(export.attachment.open, false, :web_zip)
      CC::Exporter::WebZip::ZipPackage.new(exporter, @course, @student, @cache_key)
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
      expect(assignment_data).to eq [{exportId: CC::CCHelper.create_key(assign), title: 'Assignment 1',
        content: '<p>Hi</p>', submissionTypes: "a text entry box or a file upload", graded: true,
        pointsPossible: 10.0, dueAt: due.in_time_zone(@student.time_zone).iso8601,
        lockAt: lock.in_time_zone(@student.time_zone).iso8601,
        unlockAt: unlock.in_time_zone(@student.time_zone).iso8601}]
    end

    it "should parse non-module discussions" do
      disc = @course.discussion_topics.create!(title: 'Discussion 1', message: "<h1>Discussion</h1>")
      zip_package = create_zip_package
      disc_data = zip_package.parse_non_module_items(:discussion_topics)
      expect(disc_data).to eq [{exportId: CC::CCHelper.create_key(disc), title: 'Discussion 1',
        graded: false, content: "<h1>Discussion</h1>"}]
    end

    it "should parse non-module quizzes" do
      quiz = @course.quizzes.create!(title: 'Quiz 1', time_limit: 5, allowed_attempts: 2)
      quiz.publish!
      zip_package = create_zip_package
      quiz_data = zip_package.parse_non_module_items(:quizzes)
      expect(quiz_data).to eq [{exportId: CC::CCHelper.create_key(quiz), title: 'Quiz 1', questionCount: 0,
        timeLimit: 5, attempts: 2, graded: true, pointsPossible: 0.0, dueAt: nil, lockAt: nil,
        unlockAt: nil, content: nil}]
    end

    it "should parse non-module wiki pages" do
      @course.wiki_pages.create!(title: 'Wiki Page 1', url: 'wiki-page-1', wiki: @course.wiki)
      zip_package = create_zip_package
      wiki_data = zip_package.parse_non_module_items(:wiki_pages)
      expect(wiki_data).to eq [{exportId: 'wiki-page-1', title: 'Wiki Page 1', content: ''}]
    end

    it "should not fail on missing items" do
      wiki = @course.wiki_pages.create!(title: 'Wiki Page 1', url: 'wiki-page-1', wiki: @course.wiki, body: '<p>Hi</p>')
      zip_package = create_zip_package
      wiki.title = 'Wiki Page 2'
      wiki.save!
      wiki_data = zip_package.parse_non_module_items(:wiki_pages)
      expect(wiki_data).to eq [{exportId: 'wiki-page-1', title: 'Wiki Page 1', content: '<p>Hi</p>'}]
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
  end
end
