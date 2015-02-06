require File.expand_path(File.dirname(__FILE__) + '/helpers/quizzes_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/assignment_overrides.rb')

describe "quizzes with draft state" do

  include AssignmentOverridesSeleniumHelper
  include_examples "quizzes selenium tests"

  before(:each) do
    course_with_teacher_logged_in
    @course.update_attributes(:name => 'teacher course')
    @course.save!
    @course.reload
  end

  it "should click the publish button to publish a quiz" do
    @context = @course
    q = quiz_model
    q.unpublish!

    get "/courses/#{@course.id}/quizzes/#{q.id}"
    expect(f('#quiz-publish-link')).not_to include_text("Published")
    expect(f('#quiz-publish-link')).to include_text("Publish")

    expect_new_page_load do
      f('.quiz-publish-button').click
      wait_for_ajaximations
    end

    # move mouse to not be hover over the button
    driver.mouse.move_to f('#footer')
    keep_trying_until {
      expect(f('#quiz-publish-link')).to include_text("Published")
    }
  end

  it "should click the unpublish button to unpublish a quiz" do
    @context = @course
    q = quiz_model
    q.publish!

    get "/courses/#{@course.id}/quizzes/#{q.id}"
    expect(f('#quiz-publish-link')).to include_text("Published")

    expect_new_page_load do
      f('.quiz-publish-button').click
      wait_for_ajaximations
    end

    # move mouse to not be hover over the button
    driver.mouse.move_to f('#footer')

    keep_trying_until {
      expect(f('#quiz-publish-link')).not_to include_text("Published")
      expect(f('#quiz-publish-link')).to include_text("Publish")
    }
  end

  it "should show a summary of due dates if there are multiple" do
    create_quiz_with_default_due_dates
    get "/courses/#{@course.id}/quizzes"
    expect(f('.ig-details .date-due')).not_to include_text "Multiple Dates"
    expect(f('.ig-details .date-available')).not_to include_text "Multiple Dates"

    add_due_date_override(@quiz)

    get "/courses/#{@course.id}/quizzes"
    expect(f('.ig-details .date-due')).to include_text "Multiple Dates"
    driver.mouse.move_to f('.ig-details .date-due a')
    wait_for_ajaximations
    tooltip = fj('.ui-tooltip:visible')
    expect(tooltip).to include_text 'New Section'
    expect(tooltip).to include_text 'Everyone else'

    expect(f('.ig-details .date-available')).to include_text "Multiple Dates"
    driver.mouse.move_to f('.ig-details .date-available a')
    wait_for_ajaximations
    tooltip = fj('.ui-tooltip:visible')
    expect(tooltip).to include_text 'New Section'
    expect(tooltip).to include_text 'Everyone else'
  end

end
