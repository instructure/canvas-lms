
require_relative '../../rails_helper'

RSpec.describe 'As a Teacher I can force advance student module progress', type: :feature, js: true do

  include_context 'stubbed_network'

  before(:each) do
    # enable feature flags
    allow_any_instance_of(TeacherEnrollment).to receive(:has_permission_to?).and_return(true)
    allow_any_instance_of(TaEnrollment).to receive(:has_permission_to?).and_return(true)
    allow(SettingsService).to receive(:get_settings).and_return({
      "auto_due_dates" => "on",
      "auto_enrollment_due_dates" => "on",
    })

    course_with_teacher_logged_in
    @course.update_attribute :start_at, 1.month.ago
    @course.update_attribute :conclude_at, 1.month.from_now

  # Module 1 -------

    @module1 = @course.context_modules.create!(:name => "Module 1")

  # Assignment 1
    @assignment1 = @course.assignments.create!(:name => "Assignment 1: pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
    @assignment1.publish
    @assignment_tag = @module1.add_item(:id => @assignment1.id, :type => 'assignment', :title => 'Assignment: requires submission')

  # External Url
    @external_url_tag = @module1.add_item(type: 'external_url', url: 'http://example.com/lolcats', title: 'External Url: requires viewing')
    @external_url_tag.publish

  # Context Module Sub Header
    @header_tag = @module1.add_item(:type => "sub_header", :title => "Context Module Sub Header")

  # Assignment 2: must_mark_done
    @assignment2 = @course.assignments.create!(:name => "Assignment 2: Must Mark Done", :submission_types => ["online_text_entry"])
    @assignment2.publish
    @assignment2_tag = @module1.add_item(:id => @assignment2.id, :type => 'assignment', :title => 'Assignment 2: requires mark done')

  # Wiki Page or Page
    wiki     = @course.wiki_pages.create! :title => "Wiki Page"
    wiki_tag = @module1.add_item(:id => wiki.id, :type => 'wiki_page', :title => 'Wiki Page: requires viewing')

  # Attachment or File
    @attachment     = attachment_model(:context => @course, display_name: 'Attachment')
    @attachment_tag = @module1.add_item(:id => @attachment.id, :type => 'attachment', :title => 'Attachment: requires viewing')

  # Discussion Topic with Assignment
    @topic     = @course.discussion_topics.create!(title: 'Discussion Topic with Assignment')
    @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title, :points_possible => 100)
    @topic.assignment.infer_times
    @topic.assignment.saved_by = :discussion_topic
    @topic.save
    expect(@topic).to be_for_assignment
    @topic_tag = @module1.add_item({:id => @topic.id, :type => 'discussion_topic', :title => 'Discussion Topic: requires contribution'})

  # Group Discussion with Assignment
    @group_discussion = group_assignment_discussion(course: @course)
    @assignment.update_attribute :due_at, nil # rm default due date from factory

    @group_discussion_tag = @module1.add_item(type: 'discussion_topic', id: @root_topic.id, title: 'Group Assignment Discussion: requires contribution')
    @group.add_user @student, 'accepted'

  # Quiz
    # quiz_type can be assignment or survey
    @quiz = @course.quizzes.build(:title => "Some Quiz", :quiz_type => "assignment",
                                  :scoring_policy => 'keep_highest')
    @quiz.workflow_state = 'available'
    @quiz.save!

    @quiz_tag = @module1.add_item({:id => @quiz.id, :type => 'quiz', :title => 'Quiz: min score 90'})

  # Context External Tool
    tool = @course.context_external_tools.create!(:name => "Context External Tool", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
    @external_tool_tag = @module1.add_item(:id => tool.id, :type => 'context_external_tool', :url => tool.url, :new_tab => false, :indent => 0)
    @external_tool_tag.publish!

    @module1.completion_requirements = {
      @assignment_tag.id       => { type: 'must_submit' },
      @external_url_tag.id     => { type: 'must_view' },
      wiki_tag.id              => { type: 'must_view' },
      @attachment_tag.id       => { type: 'must_view' },
      @topic_tag.id            => { type: 'must_contribute' },
      @group_discussion_tag.id => { type: 'must_contribute' },
      @quiz_tag.id             => { type: 'min_score', min_score: 90 },
      @external_tool_tag.id     => { type: 'must_view' },
      @assignment2_tag.id      => { type: 'must_mark_done' }
    }

    @module1.save!

  # Module 2 -------

    @module2 = @course.context_modules.create!(:name => "Module 2", :require_sequential_progress => true)

    @module2.prerequisites = "module_#{@module1.id}"

  # Module 2 Assignment
    @m2_assignment = @course.assignments.create!(:name => "Module 2 Assignment: pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
    @m2_assignment.publish
    @m2_assignment_tag = @module2.add_item(:id => @m2_assignment.id, :type => 'assignment', :title => 'Module 2 Assignment: requires submission')

  # Discussion Topic
    @m2_topic     = @course.discussion_topics.create!
    @m2_topic_tag = @module2.add_item({:id => @m2_topic.id, :type => 'discussion_topic', :title => 'Module 2 Discussion Topic: requires contribution'})


    @module2.completion_requirements = {
      @m2_assignment_tag.id => { type: 'must_submit' },
      @m2_topic_tag.id      => { type: 'must_contribute' }
    }

    @module2.save!

    student_in_course(course: @course, active_all: true)

    Delayed::Testing.drain

  # set up distributed due dates

    expect(Assignment.order(:id).pluck(:due_at).compact).to be_empty
    late_enrollment_date = 2.weeks.from_now

    service = AssignmentsService::Commands::DistributeDueDates.new(course: @course)
    service.call

    # no overrides yet
    expect(AssignmentOverride.count).to be_zero

    # make enrollment date in future
    @student.enrollments.update_all(created_at: late_enrollment_date)

    service = AssignmentsService::Commands::SetEnrollmentAssignmentDueDates.new(enrollment: @student.enrollments.first)
    service.call

    expect(AssignmentOverride.count).to eq(5)

    # make sure all due dates were shifted forward
    Assignment.order(:id).each do |as|
      assignment_overrides = as.overrides_for(@student)

      # Quiz - skip for now, possible bug in auto due dates for quizzes
      next if assignment_overrides.first.nil? || assignment_overrides.first&.quiz?

      # there should be overrides
      expect(assignment_overrides).to_not be_empty

      # due dates should be after late enrollment start
      expect(assignment_overrides.first.due_at).to be > late_enrollment_date.beginning_of_day
    end

    Delayed::Testing.drain
  end

  it "should delete all due date overrides for student and push them forward" do
    visit "/courses/#{@course.id}"

    expect(page).to have_selector('a.home.active')

    click_link 'People'

    within find("#user_#{@student.id}") do
      find('.al-trigger').click()
      sleep 1
      click_link 'Custom Placement'
    end

    expect(page).to have_selector('.ui-dialog', visible: true)

    select "Module 2 Discussion Topic: requires contribution", from: 'Unit to start'

    within '.ui-dialog' do
      click_button 'Update'
    end

    accept_confirm

    sleep 2

    page.find('.ic-flash-success')
    expect(page).to have_selector('.ic-flash-success', text: 'Custom placement process started. You can check progress by viewing the course as the student.')

    # switch to student check course progress indicators
    destroy_session
    user_session(@student)

    Capybara.ignore_hidden_elements = false

    Delayed::Testing.drain # run all queued jobs

    visit "/courses/#{@course.id}"

    expect(page).to have_selector('a.home.active')
    expect(page).to have_selector('.icon-check', visible: false)

    within "#context_module_#{@module1.id} .ig-header" do
      expect(page).to have_content('Progress: 100%')
    end

    within("#context_module_content_#{@module1.id}") do
      expect(page).to have_selector('.icon-check[title=Completed]', count: 9, visible: false)
      expect(page).not_to have_selector('.unstarted-icon', visible: false)
    end

    within "#context_module_#{@module2.id} .ig-header" do
      expect(page).to have_content('Progress: 50%')
    end

    within("#context_module_content_#{@module2.id}") do
      expect(page).to have_selector('.icon-check[title=Completed]', count: 1)
      expect(page).to have_selector('.unstarted-icon[title="This assignment has not been started"]', count: 1)
    end

    Capybara.ignore_hidden_elements = true

    # An AssignmentOverride is auto deleted when no more students associated
    expect(AssignmentOverrideStudent.count).to be_zero

    # 5 not 6 because quizzes are currently not auto due dated!
    expect(AssignmentOverride.where(workflow_state: 'deleted').count).to eq(5)
  end
end
