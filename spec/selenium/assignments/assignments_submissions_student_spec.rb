# frozen_string_literal: true

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

require_relative "../common"
require_relative "../helpers/files_common"
require_relative "../helpers/submissions_common"
require_relative "../helpers/gradebook_common"
require_relative "../../helpers/k5_common"

describe "submissions" do
  include_context "in-process server selenium tests"
  include FilesCommon
  include GradebookCommon
  include SubmissionsCommon
  include K5Common

  context "as a student" do
    before(:once) do
      @due_date = Time.now.utc + 2.days
      course_with_student(active_all: true)
      @assignment = @course.assignments.create!(title: "assignment 1", name: "assignment 1", due_at: @due_date)
      @second_assignment = @course.assignments.create!(title: "assignment 2", name: "assignment 2", due_at: nil)
      @third_assignment = @course.assignments.create!(title: "assignment 3", name: "assignment 3", due_at: nil)
      @fourth_assignment = @course.assignments.create!(title: "assignment 4", name: "assignment 4", due_at: @due_date - 1.day)
    end

    before do
      user_session(@student)
    end

    it "does not show score if RDQ" do
      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # enable RQD for course
      @course.settings = @course.settings.merge(restrict_quantitative_data: true)
      @course.save!

      @teacher = User.create!
      @course.enroll_teacher(@teacher)

      first_period_assignment = @course.assignments.create!(
        due_at: @due_date,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      first_period_assignment.grade_student(@student, grade: 8, grader: @teacher)

      get "/courses/#{@course.id}/assignments/#{first_period_assignment.id}"
      expect(f(".module")).to include_text "Grade: B−"

      get "/courses/#{@course.id}/assignments/#{first_period_assignment.id}/submissions/#{@student.id}"
      expect(f(".entered_grade")).to include_text "B−"
    end

    it "show score if not RDQ" do
      # truthy feature flag
      Account.default.enable_feature! :restrict_quantitative_data

      # disable RQD for course
      @course.settings = @course.settings.merge(restrict_quantitative_data: false)
      @course.save!

      @teacher = User.create!
      @course.enroll_teacher(@teacher)

      first_period_assignment = @course.assignments.create!(
        due_at: @due_date,
        points_possible: 10,
        submission_types: "online_text_entry"
      )

      first_period_assignment.grade_student(@student, grade: 8, grader: @teacher)

      get "/courses/#{@course.id}/assignments/#{first_period_assignment.id}"
      expect(f(".module")).to include_text "Grade: 8 (10 pts possible)"

      get "/courses/#{@course.id}/assignments/#{first_period_assignment.id}/submissions/#{@student.id}"

      expect(f(".entered_grade")).to include_text "8"
      expect(f(".grade-values")).to include_text "Grade: 8 / 10"
    end

    it "lets a student submit a text entry", :xbrowser, priority: "1" do
      @assignment.update(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      wait_for_new_page_load { f(".submit_assignment_link").click }
      type_in_tiny("#submission_body", "text")
      wait_for_new_page_load { f('button[type="submit"]').click }

      expect(f("#sidebar_content")).to include_text("Submitted!")
      expect(f("#content")).not_to contain_css(".error_text")
    end

    it "does not let a student submit a text entry with no text entered", priority: "2" do
      @assignment.update(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      wait_for_new_page_load { f(".submit_assignment_link").click }
      f('button[type="submit"]').click

      expect(f(".error_text")).to be
    end

    it "does not break when you open and close the media comment dialog", priority: "1" do
      stub_kaltura
      # pending("failing because it is dependant on an external kaltura system")

      create_assignment_and_go_to_page("media_recording")

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
      expect(f("#media_media_recording_ready")).to be_displayed

      # submit the assignment so the "are you sure?!" message doesn't freeze up selenium
      submit_form("#submit_media_recording_form")
    end

    it "does not allow blank media submission", priority: "1" do
      skip_if_safari(:alert)
      stub_kaltura
      # pending("failing because it is dependant on an external kaltura system")

      create_assignment_and_go_to_page "media_recording"
      f(".submit_assignment_link").click
      expect(f("#media_comment_submit_button")).to be_disabled
      # leave so the "are you sure?!" message doesn't freeze up selenium
      f("#section-tabs .home").click
      driver.switch_to.alert.accept
    end

    it "allows you to submit a file", priority: "1" do
      skip("investigate in EVAL-2966")
      @assignment.submission_types = "online_upload"
      @assignment.save!
      _filename, fullpath, _data = get_file("testfile1.txt")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click
      f(".submission_attachment input").send_keys(fullpath)
      f("#submission_comment").send_keys("hello comment")
      expect_new_page_load { f("#submit_file_button").click }

      expect(f("#sidebar_content .header")).to include_text "Submitted!"
      expect(f(".details")).to include_text "testfile1"
      @submission = @assignment.reload.submissions.where(user_id: @student).first
      expect(@submission.submission_type).to eq "online_upload"
      expect(@submission.attachments.length).to eq 1
      expect(@submission.workflow_state).to eq "submitted"
    end

    it "renders the webcam wraper", priority: "1" do
      @assignment.submission_types = "online_upload"
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click
      expect(f(".attachment_wrapper")).to be_displayed
    end

    it "renders the webcam wraper when allowed_extensions has png", priority: "1" do
      @assignment.submission_types = "online_upload"
      @assignment.allowed_extensions = ["png"]
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click
      expect(f(".attachment_wrapper")).to be_displayed
    end

    it "doesn't render the webcam wraper when allowed_extensions doens't have png", priority: "1" do
      @assignment.submission_types = "online_upload"
      @assignment.allowed_extensions = ["pdf"]
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click
      expect(element_exists?(".attachment_wrapper")).to be_falsy
    end

    it "does not allow a user to submit a file-submission assignment without attaching a file", priority: "1" do
      skip("investigate in LA-843")
      skip_if_safari(:alert)
      @assignment.submission_types = "online_upload"
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click
      f("#submit_file_button").click
      expect_flash_message :error

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f("#section-tabs .home").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "does not allow a user to submit a file-submission assignment with an empty file", priority: "1" do
      skip("flaky, will be fixed in ADMIN-3015")
      @assignment.submission_types = "online_upload"
      @assignment.save!
      _filename, fullpath, _data = get_file("empty_file.txt")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click
      f(".submission_attachment input").send_keys(fullpath)
      f("#submit_file_button").click
      expect_flash_message :error

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f("#section-tabs .home").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "does not allow a user to submit a file-submission assignment with an illegal file extension", priority: "1" do
      @assignment.submission_types = "online_upload"
      @assignment.allowed_extensions = ["bash"]
      @assignment.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"

      f(".submit_assignment_link").click

      # Select an assignment that has a wrong file extension
      _filename, fullpath, _data = get_file("testfile1.txt")
      f(".submission_attachment input").send_keys(fullpath)

      # Check that the error is being reported
      expect(f(".bad_ext_msg")).to include_text("This file type is not allowed")

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f("#section-tabs .home").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "shows as not turned in when submission was auto created in speedgrader", priority: "1" do
      # given
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.update(submission_types: "online_text_entry")
      @assignment.grade_student(@student, grade: "0", grader: @teacher)
      # when
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      # expect
      expect(f("#sidebar_content .details")).to include_text "Not Submitted!"
      expect(f(".submit_assignment_link")).to include_text "Start Assignment"
    end

    it "does not show as turned in or not turned in when assignment doesn't expect a submission", priority: "1" do
      # given
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.update(submission_types: "on_paper")
      @assignment.grade_student(@student, grade: "0", grader: @teacher)
      # when
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      # expect
      expect(f("#sidebar_content .details")).not_to include_text "Submitted!"
      expect(f("#sidebar_content .details")).not_to include_text "Not Submitted!"
      expect(f("#content")).not_to contain_css(".submit_assignment_link")
    end

    it "shows not graded anonymously" do
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.grade_student(@student, grade: "0", grader: @teacher, graded_anonymously: false)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#sidebar_content .details")).to include_text "Graded Anonymously: no"
    end

    it "shows graded anonymously" do
      @teacher = User.create!
      @course.enroll_teacher(@teacher)
      @assignment.grade_student(@student, grade: "0", grader: @teacher, graded_anonymously: true)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#sidebar_content .details")).to include_text "Graded Anonymously: yes"
    end

    it "does not allow blank submissions for text entry", priority: "1" do
      @assignment.update(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click
      assignment_form = f("#submit_online_text_entry_form")
      wait_for_tiny(assignment_form)
      submission = @assignment.submissions.find_by!(user_id: @student)

      # it should not actually submit and pop up an error message
      expect { submit_form(assignment_form) }.not_to change { submission.reload.updated_at }
      expect(submission.reload.body).to be_nil
      expect(ff(".error_box")[1]).to include_text("Required")

      # now make sure it works
      body_text = "now it is not blank"
      type_in_tiny("#submission_body", body_text)
      expect { submit_form(assignment_form) }.to change { submission.reload.updated_at }
      expect(submission.reload.body).to eq "<p>#{body_text}</p>"
    end

    it "does not allow submissions that contain placeholders for unfinished file uploads" do
      @assignment.update(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click
      body_html = '<span style="width: 18rem; height: 1rem; vertical-align: middle;" aria-label="Loading" data-placeholder-for="filename">  </span>'
      switch_editor_views # switch to html editor
      switch_to_raw_html_editor
      tinymce = f("#submission_body")
      tinymce.click
      tinymce.send_keys(body_html)
      assignment_form = f("#submit_online_text_entry_form")
      wait_for_tiny(assignment_form)
      submission = @assignment.submissions.find_by!(user_id: @student)
      # it should not actually submit and pop up an error message
      expect { submit_form(assignment_form) }.not_to change { submission.reload.updated_at }
      expect(ff(".error_box")[1]).to include_text("File has not finished uploading")

      # now make sure it works with finished upload
      tinymce.clear
      body_html = '<a title="filename" href="fileref" target="_blank" data-canvas-previewable="false">filename</a>&nbsp;'
      tinymce.click
      tinymce.send_keys(body_html)
      expect { submit_form(assignment_form) }.to change { submission.reload.updated_at }
      expect(submission.reload.body).to eq "<p>#{body_html}</p>"
    end

    it "does not allow a submission with only comments", priority: "1" do
      skip_if_safari(:alert)
      skip("flash alert is fragile, will be addressed in ADMIN-3015")
      @assignment.update(submission_types: "online_text_entry")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click

      expect(f("#submission_body_ifr")).to be_displayed
      replace_content(f("#submit_online_text_entry_form").find_element(:id, "submission_comment"), "this should not be able to be submitted for grading")
      submission = @assignment.submissions.find_by!(user_id: @student)

      # it should not actually submit and pop up an error message
      expect { submit_form("#submit_online_text_entry_form") }.not_to change { submission.reload.updated_at }
      expect(ff(".error_box")[1]).to include_text("Required")

      # navigate off the page and dismiss the alert box to avoid problems
      # with other selenium tests
      f("#section-tabs .home").click
      driver.switch_to.alert.accept
      driver.switch_to.default_content
    end

    it "does not allow peer reviewers to see turnitin scores/reports", priority: "1" do
      skip("investigate in EVAL-2966")
      @student1 = @user
      @assignment.submission_types = "online_upload,online_text_entry"
      @assignment.turnitin_enabled = true
      @assignment.save!
      _filename, fullpath, _data = get_file("testfile1.txt")

      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      f(".submit_assignment_link").click
      f(".submission_attachment input").send_keys(fullpath)
      f("#submission_comment").send_keys("hello comment")
      f(".turnitin_pledge").click
      expect_new_page_load { f("#submit_file_button").click }
      @submission = @assignment.reload.submissions.last

      user_logged_in(username: "assessor@example.com")
      @student2 = @user
      student_in_course(active_enrollment: true, user: @student2)

      @assignment.peer_reviews = true
      @assignment.assign_peer_review(@student2, @student1)
      @assignment.due_at = 1.day.ago
      @assignment.save!

      asset = @submission.turnitin_assets.first.asset_string
      @submission.turnitin_data = {
        asset.to_s => {
          object_id: "123456",
          publication_overlap: 5,
          similarity_score: 100,
          state: "failure",
          status: "scored",
          student_overlap: 44,
          web_overlap: 100
        },
        :last_processed_attempt => 1
      }
      @submission.turnitin_data_changed!
      @submission.save!
      @assignment.submit_homework(@student2, body: "hello")
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student1.id}"
      in_frame("preview_frame") do
        expect(f("body")).not_to contain_css(".turnitin_score_container")
      end
    end

    it "should submit an assignment and validate confirmation information", priority: "1"

    context "with Canvadocs enabled" do
      before(:once) do
        PluginSetting.create! name: "canvadocs",
                              settings: { "api_key" => "blahblahblahblahblah",
                                          "base_url" => "http://example.com",
                                          "disabled" => false }
      end

      it "shows preview link after submitting a canvadocable file type", priority: "1" do
        @assignment.submission_types = "online_upload"
        @assignment.save!

        # Add a fake pdf, which is a canvadocable file type
        file_attachment = attachment_model(content_type: "application/pdf", context: @student)
        @assignment.submit_homework(@student, submission_type: "online_upload", attachments: [file_attachment])

        # Open assignment
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        # Enter Submission Details page
        fj("a:contains('Submission Details')").click

        # Expect preview link to exist
        driver.switch_to.frame(f("#preview_frame"))
        expect(f(".modal_preview_link")).to be
      end
    end

    describe "uploaded files for submission" do
      def make_folder_actions_visible
        driver.execute_script("$('.folder_item').addClass('folder_item_hover')")
      end

      it "allows uploaded files to be used for submission", priority: "1" do
        local_storage!

        add_file(fixture_file_upload("html-editing-test.html", "text/html"),
                 @student,
                 "html-editing-test.html")
        assignment = @course.assignments.create!(title: "assignment 1",
                                                 name: "assignment 1",
                                                 submission_types: "online_upload",
                                                 allowed_extensions: ".html")
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        f(".submit_assignment_link").click
        f(".toggle_uploaded_files_link").click
        wait_for_animations

        # traverse the tree
        f('li[aria-label="My files"] button').click
        f('li[aria-label="html-editing-test.html"] button').click

        expect_new_page_load { f("#submit_file_button").click }

        expect(f(".details .header")).to include_text "Submitted!"
        expect(f(".details")).to include_text "html-editing-test.html"
      end

      it "does not allow a user to submit a file-submission assignment from previously uploaded files with an illegal file extension", priority: "1" do
        skip_if_safari(:alert)
        filename = "hello-world.sh"

        local_storage!

        add_file(fixture_file_upload(filename, "application/x-sh"),
                 @student,
                 filename)
        assignment = @course.assignments.create!(title: "assignment 1",
                                                 name: "assignment 1",
                                                 submission_types: "online_upload",
                                                 allowed_extensions: ["txt"])
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        f(".submit_assignment_link").click
        f(".toggle_uploaded_files_link").click
        wait_for_animations

        # traverse the tree
        f('li[aria-label="My files"] button').click
        f('li[aria-label="' + filename + '"] button').click

        f("#submit_file_button").click

        # Make sure the flash message is being displayed
        expect_flash_message :error

        # navigate off the page and dismiss the alert box to avoid problems
        # with other selenium tests
        f("#section-tabs .home").click
        driver.switch_to.alert.accept
        driver.switch_to.default_content
      end
    end

    describe "using lti tool for submission" do
      def create_submission_tool
        @course.context_external_tools.create!(
          name: "submission tool",
          url: "https://example.com/lti",
          consumer_key: "key",
          shared_secret: "secret",
          settings: {
            homework_submission: {
              enabled: true
            }
          }
        )
      end

      it "loads submission lti tool on clicking tab" do
        tool = create_submission_tool
        @assignment.update(submission_types: "online_upload")
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(".submit_assignment_link").click
        tool_tab = f("a[href='#submit_from_external_tool_form_#{tool.id}']")
        expect(tool_tab).to include_text("submission tool")
        tool_tab.click
        expect(f("iframe[src^='/courses/#{@course.id}/external_tools/#{tool.id}/resource_selection?launch_type=homework_submission']")).to be_displayed
      end

      it "loads submission lti tool on kb-nav to tab" do
        tool = create_submission_tool
        @assignment.update(submission_types: "online_upload")
        get "/courses/#{@course.id}/assignments/#{@assignment.id}"

        f(".submit_assignment_link").click
        f("a.submit_online_upload_option").send_keys :arrow_right
        expect(f("iframe[src^='/courses/#{@course.id}/external_tools/#{tool.id}/resource_selection?launch_type=homework_submission']")).to be_displayed
      end
    end

    it "does not show course nav on submissions detail page in k5 subject" do
      toggle_k5_setting(@course.account)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"
      expect(f("#back_to_subject")).to include_text "Back to Subject"
      expect(f("#main")).not_to contain_css("#left-side")
    end
  end

  context "Excused assignment" do
    before :once do
      course_with_student(active_all: true)
    end

    before do
      user_session @student
    end

    shared_examples "shows as excused" do
      before do
        assignment.grade_student @student, excuse: true, grader: @teacher
      end

      it "indicates as excused on the assignment page", priority: "1" do
        get "/courses/#{@course.id}/assignments/#{assignment.id}"
        expect(f("#sidebar_content .header")).to include_text "Excused!"
      end

      it "indicates as excused on the submission details page", priority: "1" do
        get "/courses/#{@course.id}/assignments/#{assignment.id}/submissions/#{@student.id}"
        expect(f("#content .submission_details .entered_grade")).to include_text "Excused"
      end
    end

    context "an ungraded online assignment" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: "online_text_entry", points_possible: 20)
      end

      before(:once) do
        assignment.submit_homework(@student, { submission_type: "online_text_entry" })
        assignment.grade_student @student, excuse: true, grader: @teacher
      end

      include_examples "shows as excused"
    end

    context "an unsubmitted online assignment" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: "online_text_entry", points_possible: 20)
      end

      include_examples "shows as excused"
    end

    context "an assignment with no submission type" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: "none", points_possible: 20)
      end

      include_examples "shows as excused"
    end

    context "an on_paper assignment" do
      let_once(:assignment) do
        @course.assignments.create!(title: "Assignment", submission_types: "on_paper", points_possible: 20)
      end

      include_examples "shows as excused"
    end

    it "does not allow submissions", priority: "1" do
      @assignment = @course.assignments.create!(
        title: "assignment 1",
        submission_types: "online_text_entry"
      )

      @assignment.grade_student @student, excuse: 1, grader: @teacher
      get "/courses/#{@course.id}/assignments/#{@assignment.id}"
      expect(f("#content")).not_to contain_css("a.submit_assignment_link")
      expect(f("#assignment_show .assignment-title")).to include_text "assignment 1"
    end
  end
end
