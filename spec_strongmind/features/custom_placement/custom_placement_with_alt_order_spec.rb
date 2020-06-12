
require_relative '../../rails_helper'

RSpec.describe 'As a Teacher I can force advance student module progress', type: :feature, js: true do

  include_context 'stubbed_network'

  before(:each) do
    allow_any_instance_of(TeacherEnrollment).to receive(:has_permission_to?).and_return(true)
    allow_any_instance_of(TaEnrollment).to receive(:has_permission_to?).and_return(true)

    course_with_teacher_logged_in()

  # Module 1 -------

    @module1 = @course.context_modules.create!(:name => "Module 1")

  # Assignment 1
    @assignment1 = @course.assignments.create!(:name => "Assignment 1: pls submit", :submission_types => ["online_text_entry"], :points_possible => 42)
    @assignment1.publish
    @assignment_tag = @module1.add_item(:id => @assignment1.id, :type => 'assignment', :title => 'Assignment: requires submission')

  # Assignment 3
    @assignment3 = @course.assignments.create!(:name => "Assignment 3: min score", :submission_types => ["online_text_entry"], :points_possible => 42)
    @assignment3.publish
    @assignment3_tag = @module1.add_item(:id => @assignment3.id, :type => 'assignment', :title => 'Assignment 2: min score')

  # External Url
    @external_url_tag = @module1.add_item(type: 'external_url', url: 'http://example.com/lolcats', title: 'External Url: requires viewing')
    @external_url_tag.publish

  # Group Discussion with Assignment
    @group_discussion = group_assignment_discussion(course: @course)

    @group_discussion_tag = @module1.add_item(type: 'discussion_topic', id: @root_topic.id, title: 'Group Assignment Discussion: requires contribution')
    @group.add_user @student, 'accepted'

  # Context Module Sub Header
    @header_tag = @module1.add_item(:type => "sub_header", :title => "Context Module Sub Header")

  # Assignment: must_mark_done
    @assignment2 = @course.assignments.create!(:name => "Assignment: Must Mark Done", :submission_types => ["online_text_entry"])
    @assignment2.publish
    @assignment2_tag = @module1.add_item(:id => @assignment2.id, :type => 'assignment', :title => 'Assignment: requires mark done')

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
      @assignment_tag.id        => { type: 'must_submit' },
      @assignment3_tag.id       => { type: 'min_score', min_score: 70 },
      @external_url_tag.id      => { type: 'must_view' },
      @group_discussion_tag.id  => { type: 'must_contribute' },
      wiki_tag.id               => { type: 'must_view' },
      @attachment_tag.id        => { type: 'must_view' },
      @topic_tag.id             => { type: 'must_contribute' },
      @quiz_tag.id              => { type: 'min_score', min_score: 90 },
      @external_tool_tag.id     => { type: 'must_view' },
      @assignment2_tag.id       => { type: 'must_mark_done' }
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

  # External Url
    @external_url_tag2 = @module2.add_item(type: 'external_url', url: 'http://example.com/loldogs', title: 'External Url Two: requires viewing')
    @external_url_tag2.publish


    @module2.completion_requirements = {
      @m2_assignment_tag.id  => { type: 'must_submit' },
      @m2_topic_tag.id       => { type: 'must_contribute' }, # Gonna drop them here
      @external_url_tag2.id  => { type: 'must_view' },
    }

    @module2.save!

    student_in_course(course: @course, active_all: true)

    Delayed::Testing.drain
  end

  it "[Alternate requirements ordering] by selecting a unit in a upcoming module bypassing all the requirements of the units & modules" do
    visit "/courses/#{@course.id}"

    expect(page).to have_selector('a.home.active')

    click_link 'People'

    within find("#user_#{@student.id}") do
      find('.al-trigger').click()
      sleep 1
      click_link 'Custom Placement'
    end

    expect(page).to have_selector('.ui-dialog', visible: true)

    # select "Module 2 Discussion Topic: requires contribution", from: 'Unit to start'
    # select "Discussion Topic: requires contribution", from: 'Unit to start'
    select "Context External Tool", from: 'Unit to start'

    within '.ui-dialog' do
      click_button 'Update'
    end

    accept_confirm

    sleep 2

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
      expect(page).to have_content('Progress: 90%')
    end

    within("#context_module_content_#{@module1.id}") do
      expect(page).to have_selector('.icon-check[title=Completed]', count: 9, visible: false)
      expect(page).to have_selector('.unstarted-icon', count: 1, visible: false)
    end

    within "#context_module_#{@module2.id} .ig-header" do
      expect(page).to have_content('Progress: 0%')
    end

    within("#context_module_content_#{@module2.id}") do
      expect(page).to have_selector('.unstarted-icon[title="This assignment has not been started"]', count: 3)
    end

    Capybara.ignore_hidden_elements = true
  end
end
