require File.expand_path(File.dirname(__FILE__) + '/common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/files_common')
require File.expand_path(File.dirname(__FILE__) + '/helpers/submissions_common')


describe "submissions" do
  include_examples "in-process server selenium tests"

  context 'as a student' do

    before(:each) do
      @due_date = Time.now.utc + 2.days
      course_with_student_logged_in
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => @due_date)
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => @due_date - 1.day)
    end

    it "should not break when you open and close the media comment dialog" do
      stub_kaltura
      #pending("failing because it is dependant on an external kaltura system")

      create_assignment_and_go_to_page('media_recording')

      f(".submit_assignment_link").click
      open_button = f(".record_media_comment_link")

      # open it twice
      open_button.click
      # swf and other stuff load, give it half a second before it starts trying to click
      sleep 1
      close_visible_dialog
      open_button.click
      sleep 1
      close_visible_dialog

      # fire the callback that the flash object fires
      driver.execute_script("window.mediaCommentCallback([{entryId:1, entryType:1}]);")

      # see if the confirmation element shows up
      f('#media_media_recording_ready').should be_displayed

      # submit the assignment so the "are you sure?!" message doesn't freeze up selenium
      submit_form('#submit_media_recording_form')
    end

    it "should not allow blank media submission" do
      stub_kaltura
      #pending("failing because it is dependant on an external kaltura system")

      create_assignment_and_go_to_page 'media_recording'
      f(".submit_assignment_link").click
      f('#media_comment_submit_button').should have_attribute('disabled', 'true')
      # leave so the "are you sure?!" message doesn't freeze up selenium
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
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

      keep_trying_until do
        f('#sidebar_content .header').should include_text "Turned In!"
        f('.details .file-big').should include_text "testfile1"
      end
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
      flash_message_present?(:error).should be_true

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should not allow a user to submit a file-submission assignment with an illegal file extension" do
      @assignment.submission_types = 'online_upload'
      @assignment.allowed_extensions = ['bash']
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click
      wait_for_ajaximations

      # Select an assignment that has a wrong file extension
      filename, fullpath, data = get_file("testfile1.txt")
      f('.submission_attachment input').send_keys(fullpath)

      # Check that the error is being reported
      (f('.bad_ext_msg').text() =~ /This\sfile\stype\sis\snot\sallowed/).should be_truthy

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

    it "should not show as turned in or not turned in when assignment doesnt expect a submission" do
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
      wait_for_ajaximations
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)

      submit_form(assignment_form)
      wait_for_ajaximations

      # it should not actually submit and pop up an error message
      ff('.error_box')[1].should include_text('Required')

      Submission.count.should == 0

      # now make sure it works
      type_in_tiny('#submission_body', 'now it is not blank')
      submit_form(assignment_form)
      wait_for_ajaximations
      Submission.count.should == 1
    end

    it "should not allow a submission with only comments" do
      @assignment.update_attributes(:submission_types => "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      replace_content(assignment_form.find_element(:id, 'submission_comment'), 'this should not be able to be submitted for grading')
      submit_form("#submit_online_text_entry_form")

      # it should not actually submit and pop up an error message
      ff('.error_box')[1].should include_text('Required')
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

    describe 'uploaded files for submission' do
      include_examples "in-process server selenium tests"

      def fixture_file_path(file)
        path = ActionController::TestCase.respond_to?(:fixture_path) ? ActionController::TestCase.send(:fixture_path) : nil
        return "#{path}#{file}"
      end

      def add_file(fixture, context, name)
        context.attachments.create! do |attachment|
          attachment.uploaded_data = fixture
          attachment.filename = name
          attachment.folder = Folder.root_folders(context).first
        end
      end

      def make_folder_actions_visible
        driver.execute_script("$('.folder_item').addClass('folder_item_hover')")
      end

      it "should allow uploaded files to be used for submission" do
        local_storage!

        user_with_pseudonym :username => "nobody2@example.com",
                            :password => "asdfasdf2"
        course_with_student_logged_in :user => @user
        create_session @pseudonym, false
        add_file(fixture_file_upload('files/html-editing-test.html', 'text/html'),
                 @user, "html-editing-test.html")
        File.read(fixture_file_path("files/html-editing-test.html"))
        assignment = @course.assignments.create!(:title => 'assignment 1',
                                                 :name => 'assignment 1',
                                                 :submission_types => "online_upload")
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        f('.submit_assignment_link').click
        wait_for_ajaximations
        f('.toggle_uploaded_files_link').click
        wait_for_ajaximations

        # traverse the tree
        begin
          keep_trying_until do
            f('#uploaded_files > ul > li.folder > .sign').click
            wait_for_ajaximations
            f('#uploaded_files > ul > li.folder .file .name').should be_displayed
          end
          f('#uploaded_files > ul > li.folder .file .name').click
          wait_for_ajaximations
        rescue => err
          # prevent the confirm dialog that pops up when you navigate away
          # from the page from showing.
          # TODO: actually figure out why the spec intermittently fails.
          driver.execute_script "window.onbeforeunload = null;"
          raise err
        end

        expect_new_page_load { f('#submit_file_button').click }

        keep_trying_until do
          f('.details .header').should include_text "Turned In!"
          f('.details .file-big').should include_text "html-editing-test.html"
        end
      end

      it "should not allow a user to submit a file-submission assignment from previously uploaded files with an illegal file extension" do
        FILENAME = "hello-world.sh"
        FIXTURE_FN = "files/#{FILENAME}"

        local_storage!

        user_with_pseudonym :username => "nobody2@example.com",
                            :password => "asdfasdf2"
        course_with_student_logged_in :user => @user
        create_session @pseudonym, false
        add_file(fixture_file_upload(FIXTURE_FN, 'application/x-sh'),
                 @user, FILENAME)
        File.read(fixture_file_path(FIXTURE_FN))
        assignment = @course.assignments.create!(:title => 'assignment 1',
                                                 :name => 'assignment 1',
                                                 :submission_types => "online_upload",
                                                 :allowed_extensions => ['txt'])
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        f('.submit_assignment_link').click
        wait_for_ajaximations
        f('.toggle_uploaded_files_link').click
        wait_for_ajaximations

        # traverse the tree
        begin
          keep_trying_until do
            f('#uploaded_files > ul > li.folder > .sign').click
            wait_for_ajaximations
            # How does it know which name we're looking for?
            f('#uploaded_files > ul > li.folder .file .name').should be_displayed
          end
          f('#uploaded_files > ul > li.folder .file .name').click
          wait_for_ajaximations
          f('#submit_file_button').click
        rescue => err
          # prevent the confirm dialog that pops up when you navigate away
          # from the page from showing.
          # TODO: actually figure out why the spec intermittently fails.
          driver.execute_script "window.onbeforeunload = null;"
          raise err
        end

        # Make sure the flash message is being displayed
        flash_message_present?(:error).should be_truthy

        # navigate off the page and dismiss the alert box to avoid problems
        # with other selenium tests
        f('#section-tabs .home').click
        driver.switch_to.alert.accept
        driver.switch_to.default_content
      end
    end
  end
end
