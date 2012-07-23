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

  def open_media_comment_dialog
    f('.media_comment_link').click
    # swf and stuff loads, give it a sec to do its thing
    sleep 0.5
  end

  def submit_media_comment_1
    open_media_comment_dialog
    # pretend like we are flash sending data to the JS
    driver.execute_script <<-JS
      var entries1 = [{"duration":1.664,"thumbnailUrl":"http://www.instructuremedia.com/p/100/sp/10000/thumbnail/entry_id/0_jd6ger47/version/0","numComments":-1,"status":1,"rank":-1,"userScreenName":"_100_1_1","displayCredit":"_100_1_1","partnerLandingPage":null,"dataUrl":"http://www.instructuremedia.com/p/100/sp/10000/flvclipper/entry_id/0_jd6ger47/version/100000","sourceLink":"","subpId":10000,"puserId":"1_1","views":0,"height":0,"description":null,"hasThumbnail":false,"width":0,"kshowId":"0_pb7id2lf","kuserId":"","userLandingPage":"","mediaType":2,"plays":0,"partnerId":100,"adminTags":"","entryVersion":"","downloadUrl":"http://www.instructuremedia.com/p/100/sp/10000/raw/entry_id/0_jd6ger47/version/100000","createdAtDate":"1970-01-16T09:24:02.931Z","votes":-1,"uploaderName":null,"tags":"","entryName":"ryanf@instructure.com 2012-02-21T16:48:37.729Z","entryType":1,"entryId":"0_jd6ger47","createdAtAsInt":1329842931,"uid":"E78A81CC-D03D-CD10-B449-A0D0D172EF38"}]
      addEntryComplete(entries1);
    JS
    wait_for_ajax_requests
  end

  def submit_media_comment_2
    open_media_comment_dialog
    driver.execute_script <<-JS
      var entries2 = [{"duration":1.829,"thumbnailUrl":"http://www.instructuremedia.com/p/100/sp/10000/thumbnail/entry_id/0_5hcd9mro/version/0","numComments":-1,"status":1,"rank":-1,"userScreenName":"_100_1_1","displayCredit":"_100_1_1","partnerLandingPage":null,"dataUrl":"http://www.instructuremedia.com/p/100/sp/10000/flvclipper/entry_id/0_5hcd9mro/version/100000","sourceLink":"","subpId":10000,"puserId":"1_1","views":0,"height":0,"description":null,"hasThumbnail":false,"width":0,"kshowId":"0_pb7id2lf","kuserId":"","userLandingPage":"","mediaType":2,"plays":0,"partnerId":100,"adminTags":"","entryVersion":"","downloadUrl":"http://www.instructuremedia.com/p/100/sp/10000/raw/entry_id/0_5hcd9mro/version/100000","createdAtDate":"1970-01-16T09:24:03.563Z","votes":-1,"uploaderName":null,"tags":"","entryName":"ryanf@instructure.com 2012-02-21T16:59:11.249Z","entryType":1,"entryId":"0_5hcd9mro","createdAtAsInt":1329843563,"uid":"22A2C625-5FAB-AF3A-1A76-A0DA7572BFE4"}]
      addEntryComplete(entries2);
    JS
    wait_for_ajax_requests
  end

  context 'as a teacher' do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow media comments" do
      stub_kaltura
      student_in_course
      assignment = create_assignment
      assignment.submissions.create(:user => @student)
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"

      # make sure the JS didn't burn any bridges, and submit two
      submit_media_comment_1
      submit_media_comment_2

      # check that the thumbnails show up on the right sidebar
      number_of_comments = driver.execute_script "return $('.comment_list').children().length"
      number_of_comments.should == 2
    end

    it "should display the grade in grade field" do
      student_in_course
      assignment = create_assignment
      assignment.submissions.create(:user => @student)
      assignment.grade_student @student, :grade => 2
      get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
      f('.grading_value')[:value].should == '2'
    end
  end

  context "student view" do

    before (:each) do
      course_with_teacher_logged_in
    end

    it "should allow a student view student to view/submit assignments" do
      @assignment = @course.assignments.create(
          :title => 'Cool Assignment',
          :points_possible => 10,
          :submission_types => "online_text_entry",
          :due_at => Time.now.utc + 2.days)

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.assignment .title').should include_text @assignment.title
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)

      type_in_tiny('#submission_body', 'my assigment submission')
      expect_new_page_load { submit_form(assignment_form) }

      @course.student_view_student.submissions.count.should == 1
      f('#sidebar_content .details').should include_text "Turned In!"
    end

    it "should allow a student view student to submit file upload assignments" do
      @assignment = @course.assignments.create(
          :title => 'Cool Assignment',
          :points_possible => 10,
          :submission_types => "online_upload",
          :due_at => Time.now.utc + 2.days)

      enter_student_view
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click

      filename, fullpath, data = get_file("testfile1.txt")
      f('.submission_attachment input').send_keys(fullpath)
      expect_new_page_load { f('#submit_file_button').click }

      keep_trying_until {
        f('.details .header').should include_text "Turned In!"
        f('.details .file-big').should include_text "testfile1"
      }
    end
  end

  context 'as a student' do
    DUE_DATE = Time.now.utc + 2.days
    before (:each) do
      course_with_student_logged_in
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => DUE_DATE)
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => DUE_DATE - 1.day)
    end

    it "should not break when you open and close the media comment dialog" do
      stub_kaltura
      create_assignment_and_go_to_page 'media_recording'

      f(".submit_assignment_link").click
      open_button = f(".record_media_comment_link")

      # open it twice
      open_button.click
      # swf and other stuff load, give it half a second before it starts trying to click
      sleep 0.5
      close_visible_dialog
      open_button.click
      sleep 0.5
      close_visible_dialog

      # fire the callback that the flash object fires
      driver.execute_script "window.mediaCommentCallback([{entryId:1, entryType:1}]);"

      # see if the confirmation element shows up
      f('#media_media_recording_ready').should be_displayed

      # submit the assignment so the "are you sure?!" message doesn't freeze up selenium
      submit_form('#submit_media_recording_form')
    end

    it "should allow you to submit a file" do
      @assignment.submission_types = 'online_upload'
      @assignment.save!
      filename, fullpath, data = get_file("testfile1.txt")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      f('.submission_attachment input').send_keys(fullpath)
      f('#submission_comment').send_keys("hello comment")
      expect_new_page_load { f('#submit_file_button').click }

      keep_trying_until {
        f('#sidebar_content .header').should include_text "Turned In!"
        f('.details .file-big').should include_text "testfile1"
      }
      @submission = @assignment.reload.submissions.find_by_user_id(@student.id)
      @submission.submission_type.should == 'online_upload'
      @submission.attachments.length.should == 1
      @submission.workflow_state.should == 'submitted'
    end

    it "should not allow a user to submit a file-submission assignment without attaching a file" do
      @assignment.submission_types = 'online_upload'
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click
      wait_for_ajaximations
      f('#submit_file_button').click
      wait_for_ajaximations
      f('#flash_error_message').should be_displayed

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should show as not turned in when submission was auto created in speedgrader" do
      # given
      @assignment.update_attributes(:submission_types => "online_text_entry")
      @assignment.grade_student(@student, :grade => "0")
      # when
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      # expect
      f('#sidebar_content .details').should include_text "Not Turned In!"
      f('#sidebar_content a.submit_assignment_link').text.should == "Submit Assignment"
    end

    it "should not show as turned in or not turned in when assignment doesn't expect a submission" do
      # given
      @assignment.update_attributes(:submission_types => "on_paper")
      @assignment.grade_student(@student, :grade => "0")
      # when
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      # expect
      f('#sidebar_content .details').should_not include_text "Turned In!"
      f('#sidebar_content .details').should_not include_text "Not Turned In!"
      f('#sidebar_content a.submit_assignment_link').should be_nil
    end

    it "should not allow blank submissions for text entry" do
      @assignment.update_attributes(:submission_types => "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)
      submit_form(assignment_form)

      # it should not actually submit and pop up an error message
      f('.error_box').should be_displayed
      Submission.count.should == 0

      # now make sure it works
      expect {
        type_in_tiny('#submission_body', 'now it is not blank')
        submit_form(assignment_form)
      }.to change(Submission, :count).by(1)
    end

    it "should not allow a submission with only comments" do
      @assignment.update_attributes(:submission_types => "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      replace_content(assignment_form.find_element(:id, 'submission_comment'), 'this should not be able to be submitted for grading')
      submit_form("#submit_online_text_entry_form")

      # it should not actually submit and pop up an error message
      f('.error_box').should be_displayed
      Submission.count.should == 0

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should not allow peer reviewers to see turnitin scores/reports" do
      @student1 = @user
      @assignment.submission_types = 'online_upload'
      @assignment.save!
      filename, fullpath, data = get_file("testfile1.txt")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      f('.submission_attachment input').send_keys(fullpath)
      f('#submission_comment').send_keys("hello comment")
      expect_new_page_load { f('#submit_file_button').click }
      @submission = @assignment.reload.submissions.last

      user_logged_in(:username => "assessor@example.com")
      @student2 = @user
      student_in_course(:active_enrollment => true, :user => @student2)

      @assignment.peer_reviews = true
      @assignment.assign_peer_review(@student2, @student1)
      @assignment.turnitin_enabled = true
      @assignment.due_at = 1.day.ago
      @assignment.save!

      asset = @submission.turnitin_assets.first.asset_string
      @submission.turnitin_data = {
        "#{asset}" => {
          :object_id => "123456",
          :publication_overlap => 5,
          :similarity_score => 100,
          :state => "failure",
          :status => "scored",
          :student_overlap => 44,
          :web_overlap => 100
        },
        :last_processed_attempt => 1
      }
      @submission.turnitin_data_changed!
      @submission.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student1.id}"
      in_frame('preview_frame') do
        ff('.turnitin_score_container').should be_empty
      end
    end

    it "should submit an assignment and validate confirmation information" do
      pending "BUG 6783 - Coming Up assignments update error" do
        @assignment.update_attributes(:submission_types => 'online_url')
        @submission = @assignment.submit_homework(@student)
        @submission.submission_type = "online_url"
        @submission.save!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}"
        f('.details .header').should include_text('Turned In!')
        get "/courses/#{@course.id}"
        driver.execute_script("$('.tooltip_text').css('visibility', 'visible')")
        tooltip_text_elements = ff('.tooltip_text > span')
        f('.tooltip_text').should be_displayed
        tooltip_text_elements[1].text.should == 'submitted'
      end
    end
  end
end
