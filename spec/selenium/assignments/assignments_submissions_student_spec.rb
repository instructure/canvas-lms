#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../common'
require_relative '../helpers/files_common'
require_relative '../helpers/submissions_common'
require_relative '../helpers/gradebook_common'

describe "submissions" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include GradebookCommon
  include SubmissionsCommon

  context 'as a student' do

    before(:once) do
      @due_date = Time.now.utc + 2.days
      course_with_student(active_all: true)
      @assignment = @course.assignments.create!(:title => 'assignment 1', :name => 'assignment 1', :due_at => @due_date)
      @second_assignment = @course.assignments.create!(:title => 'assignment 2', :name => 'assignment 2', :due_at => nil)
      @third_assignment = @course.assignments.create!(:title => 'assignment 3', :name => 'assignment 3', :due_at => nil)
      @fourth_assignment = @course.assignments.create!(:title => 'assignment 4', :name => 'assignment 4', :due_at => @due_date - 1.day)
    end

    before(:each) do
      user_session(@student)
    end

    it "should let a student submit a text entry", priority: "1", test_id: 56015 do
      @assignment.update_attributes(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click
      type_in_tiny("#submission_body", 'text')
      f('button[type="submit"]').click

      expect(f("#sidebar_content")).to include_text("Turned In!")
      expect(f("#content")).not_to contain_css(".error_text")
    end

    it "should not let a student submit a text entry with no text entered", priority: "2", test_id: 238143 do
      @assignment.update_attributes(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click
      f('button[type="submit"]').click

      expect(fj(".error_text")).to be
    end

    it "should not break when you open and close the media comment dialog", priority: "1", test_id: 237020 do
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
      expect(f('#media_media_recording_ready')).to be_displayed

      # submit the assignment so the "are you sure?!" message doesn't freeze up selenium
      submit_form('#submit_media_recording_form')
    end

    it "should not allow blank media submission", priority: "1", test_id: 237021 do
      stub_kaltura
      #pending("failing because it is dependant on an external kaltura system")

      create_assignment_and_go_to_page 'media_recording'
      f(".submit_assignment_link").click
      expect(f('#media_comment_submit_button')).to be_disabled
      # leave so the "are you sure?!" message doesn't freeze up selenium
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
    end

    it "should allow you to submit a file", priority: "1", test_id: 237022 do
      @assignment.submission_types = 'online_upload'
      @assignment.save!
      filename, fullpath, data = get_file("testfile1.txt")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      f('.submission_attachment input').send_keys(fullpath)
      f('#submission_comment').send_keys("hello comment")
      expect_new_page_load { f('#submit_file_button').click }

      expect(f('#sidebar_content .header')).to include_text "Turned In!"
      expect(f('.details')).to include_text "testfile1"
      @submission = @assignment.reload.submissions.where(user_id: @student).first
      expect(@submission.submission_type).to eq 'online_upload'
      expect(@submission.attachments.length).to eq 1
      expect(@submission.workflow_state).to eq 'submitted'
    end

    it "should not allow a user to submit a file-submission assignment without attaching a file", priority: "1", test_id: 237023 do
      @assignment.submission_types = 'online_upload'
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click
      f('#submit_file_button').click
      expect_flash_message :error

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end


    it "should not allow a user to submit a file-submission assignment with an empty file", priority: "1" do
      @assignment.submission_types = 'online_upload'
      @assignment.save!
      filename, fullpath, data = get_file("empty_file.txt")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click
      f('.submission_attachment input').send_keys(fullpath)
      f('#submit_file_button').click
      expect_flash_message :error

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should not allow a user to submit a file-submission assignment with an illegal file extension", priority: "1", test_id: 237024 do
      @assignment.submission_types = 'online_upload'
      @assignment.allowed_extensions = ['bash']
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f('.submit_assignment_link').click

      # Select an assignment that has a wrong file extension
      filename, fullpath, data = get_file("testfile1.txt")
      f('.submission_attachment input').send_keys(fullpath)

      # Check that the error is being reported
      expect(f('.bad_ext_msg')).to include_text("This file type is not allowed")

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should show as not turned in when submission was auto created in speedgrader", priority: "1", test_id: 237025 do
      # given
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.update_attributes(:submission_types => "online_text_entry")
      @assignment.grade_student(@student, grade: "0", grader: @teacher)
      # when
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      # expect
      expect(f('#sidebar_content .details')).to include_text "Not Turned In!"
      expect(f('.submit_assignment_link')).to include_text "Submit Assignment"
    end

    it "should not show as turned in or not turned in when assignment doesn't expect a submission", priority: "1", test_id: 237025 do
      # given
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.update_attributes(:submission_types => "on_paper")
      @assignment.grade_student(@student, grade: "0", grader: @teacher)
      # when
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      # expect
      expect(f('#sidebar_content .details')).not_to include_text "Turned In!"
      expect(f('#sidebar_content .details')).not_to include_text "Not Turned In!"
      expect(f("#content")).not_to contain_css('.submit_assignment_link')
    end

    it "should show not graded anonymously" do
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.grade_student(@student, grade: "0", grader: @teacher, graded_anonymously: false)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f('#sidebar_content .details')).to include_text "Graded Anonymously: no"
    end

    it "should show graded anonymously" do
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.grade_student(@student, grade: "0", grader: @teacher, graded_anonymously: true)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f('#sidebar_content .details')).to include_text "Graded Anonymously: yes"
    end

    it "should not allow blank submissions for text entry", priority: "1", test_id: 237026 do
      @assignment.update_attributes(:submission_types => "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click
      assignment_form = f('#submit_online_text_entry_form')
      wait_for_tiny(assignment_form)
      submission = @assignment.submissions.find_by!(user_id: @student)

      # it should not actually submit and pop up an error message
      expect { submit_form(assignment_form) }.not_to change { submission.reload.updated_at }
      expect(submission.reload.body).to be nil
      expect(ff('.error_box')[1]).to include_text('Required')

      # now make sure it works
      body_text = 'now it is not blank'
      type_in_tiny('#submission_body', body_text)
      expect { submit_form(assignment_form) }.to change { submission.reload.updated_at }
      expect(submission.reload.body).to eq "<p>#{body_text}</p>"
    end

    it "should not allow a submission with only comments", priority: "1", test_id: 237027 do
      @assignment.update_attributes(:submission_types => "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f('.submit_assignment_link').click

      expect(f('#submission_body_ifr')).to be_displayed
      replace_content(f('#submit_online_text_entry_form').find_element(:id, 'submission_comment'), 'this should not be able to be submitted for grading')
      submission = @assignment.submissions.find_by!(user_id: @student)

      # it should not actually submit and pop up an error message
      expect { submit_form("#submit_online_text_entry_form") }.not_to change { submission.reload.updated_at }
      expect(ff('.error_box')[1]).to include_text('Required')

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f('#section-tabs .home').click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "should not allow peer reviewers to see turnitin scores/reports", priority: "1", test_id: 237028 do
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
        expect(f("body")).not_to contain_css('.turnitin_score_container')
      end
    end


    it "should submit an assignment and validate confirmation information", priority: "1", test_id: 237029

    context 'with Canvadocs enabled' do
      before(:once) do
        PluginSetting.create! name: 'canvadocs',
                              settings: {"api_key" => "blahblahblahblahblah",
                                            "base_url" => "http://example.com",
                                            "disabled" => false}
      end

      it "should show preview link after submitting a canvadocable file type", priority: "1", test_id: 587302 do
        @assignment.submission_types = 'online_upload'
        @assignment.save!

        # Add a fake pdf, which is a canvadocable file type
        file_attachment = attachment_model(content_type: 'application/pdf', context: @student)
        @assignment.submit_homework(@student, submission_type: 'online_upload', attachments: [file_attachment])

        # Open assignment
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        # Enter Submission Details page
        fj("a:contains('Submission Details')").click

        # Expect preview link to exist
        driver.switch_to.frame(f('#preview_frame'))
        expect(f('.modal_preview_link')).to be
      end
    end

    describe 'uploaded files for submission' do
      def fixture_file_path(file)
        path = ActionController::TestCase.respond_to?(:fixture_path) ? ActionController::TestCase.send(:fixture_path) : nil
        return "#{path}#{file}"
      end

      def make_folder_actions_visible
        driver.execute_script("$('.folder_item').addClass('folder_item_hover')")
      end

      it "should allow uploaded files to be used for submission", priority: "1", test_id: 237030 do
        local_storage!

        add_file(fixture_file_upload('files/html-editing-test.html', 'text/html'),
                 @student, "html-editing-test.html")
        File.read(fixture_file_path("files/html-editing-test.html"))
        assignment = @course.assignments.create!(:title => 'assignment 1',
                                                 :name => 'assignment 1',
                                                 :submission_types => "online_upload",
                                                 :allowed_extensions => '.html')
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        f('.submit_assignment_link').click
        f('.toggle_uploaded_files_link').click
        wait_for_animations

        # traverse the tree
        f('#uploaded_files > ul > li.folder > .sign').click
        expect(f('#uploaded_files > ul > li.folder .file .name')).to be_displayed
        f('#uploaded_files > ul > li.folder .file .name').click

        expect_new_page_load { f('#submit_file_button').click }

        expect(f('.details .header')).to include_text "Turned In!"
        expect(f('.details')).to include_text "html-editing-test.html"
      end

      it "should not allow a user to submit a file-submission assignment from previously uploaded files with an illegal file extension", priority: "1", test_id: 237031 do
        FILENAME = "hello-world.sh"
        FIXTURE_FN = "files/#{FILENAME}"

        local_storage!

        add_file(fixture_file_upload(FIXTURE_FN, 'application/x-sh'),
                 @student, FILENAME)
        File.read(fixture_file_path(FIXTURE_FN))
        assignment = @course.assignments.create!(:title => 'assignment 1',
                                                 :name => 'assignment 1',
                                                 :submission_types => "online_upload",
                                                 :allowed_extensions => ['txt'])
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        f('.submit_assignment_link').click
        f('.toggle_uploaded_files_link').click
        wait_for_animations

        # traverse the tree
        f('#uploaded_files > ul > li.folder > .sign').click
        expect(f('#uploaded_files > ul > li.folder .file .name')).to be_displayed
        f('#uploaded_files > ul > li.folder .file .name').click
        f('#submit_file_button').click

        # Make sure the flash message is being displayed
        expect_flash_message :error

        # navigate off the page and dismiss the alert box to avoid problems
        # with other selenium tests
        f('#section-tabs .home').click
        driver.switch_to.alert.accept
        driver.switch_to.default_content
      end
    end
  end

  context 'Excused assignment' do
    before :once do
      course_with_student(active_all: true)
    end

    before :each do
      user_session @student
    end

    shared_examples "shows as excused" do
      before :each do
        assignment.grade_student @student, excuse: true, grader: @teacher
      end

      it 'indicates as excused on the assignment page', priority: "1", test_id: 201937 do
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        expect(f("#sidebar_content .header")).to include_text 'Excused!'
      end

      it 'indicates as excused on the submission details page', priority: "1", test_id: 201937 do
         get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
        expect(f("#content .submission_details .published_grade")).to include_text 'Excused'
      end
    end

    context "an ungraded online assignment" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: 'online_text_entry', points_possible: 20)
      end

      before(:once) do
        assignment.submit_homework(@student, {submission_type: 'online_text_entry'})
        assignment.grade_student @student, excuse: true, grader: @teacher
      end

      include_examples "shows as excused"
    end

    context "a previously graded online assignment" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: 'online_text_entry', points_possible: 20)
      end

      before(:once) do
        assignment.submit_homework(@student, {submission_type: 'online_text_entry'})
        assignment.grade_student @student, excuse: true, grader: @teacher
      end

      include_examples "shows as excused"
    end

    context "an unsubmitted online assignment" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: 'online_text_entry', points_possible: 20)
      end

      include_examples "shows as excused"
    end

    context "an assignment with no submission type" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: 'none', points_possible: 20)
      end

      include_examples "shows as excused"
    end

    context "an on_paper assignment" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: 'on_paper', points_possible: 20)
      end

      include_examples "shows as excused"
    end

    it 'does not allow submissions', priority: "1", test_id: 197048 do
      @assignment = @course.assignments.create!(
        title: 'assignment 1',
        submission_types: 'online_text_entry'
      )

      @assignment.grade_student @student, excuse: 1, grader: @teacher
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#content")).not_to contain_css('a.submit_assignment_link')
      expect(f('#assignment_show .assignment-title')).to include_text 'assignment 1'
    end
  end
end
