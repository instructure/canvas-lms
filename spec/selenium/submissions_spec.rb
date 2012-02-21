require File.expand_path(File.dirname(__FILE__) + '/common')

describe "submissions" do
  it_should_behave_like "in-process server selenium tests"

  def create_assignment(type = 'online_text_entry')
    assignment = @course.assignments.build({
      :name => 'media assignment',
      :submission_types => type
    })
    assignment.workflow_state = 'published'
    assignment.save!
    assignment
  end

  def create_assignment_and_go_to_page(type = 'online_text_entry')
    assignment = create_assignment type
    get "/courses/#{@course.id}/assignments/#{assignment.id}"
    assignment
  end

  def close_dialog
    keep_trying_until { driver.find_element(:css, '.ui-dialog-titlebar-close').click; true }
  end

  it "should not break when you open and close the media comment dialog" do
    stub_kaltura
    course_with_student_logged_in
    create_assignment_and_go_to_page 'media_recording'

    driver.find_element(:css, ".submit_assignment_link").click
    open_button = driver.find_element(:css, ".record_media_comment_link")

    # open it twice
    open_button.click
    # swf and other stuff load, give it half a second before it starts trying to click
    sleep 0.5
    close_dialog
    open_button.click
    sleep 0.5
    close_dialog

    # fire the callback that the flash object fires
    driver.execute_script "window.mediaCommentCallback([{entryId:1, entryType:1}]);"

    # see if the confirmation element shows up
    driver.find_element(:id, 'media_media_recording_ready').should be_displayed

    # submit the assignment so the "are you sure?!" message doesn't freeze up selenium
    driver.find_element(:css, '#submit_media_recording_form button[type=submit]').click
  end


  it "should allow media comments without making the page go blank" do
    stub_kaltura
    course_with_teacher_logged_in
    student_in_course
    assignment = create_assignment
    assignment.submissions.create :user => @student
    get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
    driver.find_element(:css, '.media_comment_link').click
    # swf and stuff loads, give it a sec before we go polling for the dialog
    sleep 0.5
    close_dialog

    # manually trigger the line of code that previously made the page go blank
    driver.execute_script "$(document).triggerHandler('media_comment_created', {id: 1, mediaType: 1});"
    find_with_jquery('body').should be_displayed
  end

  it "should allow media comments"

end

