require File.expand_path(File.dirname(__FILE__) + '/common')

describe "submissions" do
  it_should_behave_like "in-process server selenium tests"

  def create_media_assignment_and_go_to_page
    assignment = @course.assignments.build({
      :name => 'media assignment',
      :submission_types => 'media_recording'
    })
    assignment.workflow_state = 'published'
    assignment.save!
    get "/courses/#{@course.id}/assignments/#{assignment.id}"
    assignment
  end

  def close_dialog
    keep_trying_until { driver.find_element(:css, '.ui-dialog-titlebar-close').click; true }
  end

  it "should not break when you open and close the media comment dialog" do
    stub_kaltura
    course_with_student_logged_in
    create_media_assignment_and_go_to_page

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
end

