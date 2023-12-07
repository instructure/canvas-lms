# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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
require_relative "../helpers/quizzes_common"
require_relative "../helpers/assignment_overrides"
require_relative "../helpers/files_common"

describe "quizzes" do
  include_context "in-process server selenium tests"
  include QuizzesCommon
  include AssignmentOverridesSeleniumHelper
  include FilesCommon

  def add_question_to_group
    f(".add_question_link").click
    wait_for_ajaximations
    question_form = f(".question_form")
    submit_form(question_form)
    wait_for_ajaximations
  end

  context "as a teacher" do
    before(:once) do
      course_with_teacher(active_all: true)
      course_with_student(course: @course, active_enrollment: true)
      @course.update(name: "teacher course")
      @course.save!
      @course.reload
    end

    before do
      user_session(@teacher)
    end

    it "shows a summary of due dates if there are multiple", priority: "1" do
      create_quiz_with_due_date
      get "/courses/#{@course.id}/quizzes"
      expect(f(".item-group-container .date-available")).not_to include_text "Multiple Dates"
      add_due_date_override(@quiz)

      get "/courses/#{@course.id}/quizzes"
      expect(f(".item-group-container .date-available")).to include_text "Multiple Dates"
      driver.action.move_to(f(".item-group-container .date-available")).perform
      wait_for_ajaximations
      tooltip = fj(".ui-tooltip:visible")
      expect(tooltip).to include_text "New Section"
      expect(tooltip).to include_text "Everyone else"
    end

    it "asynchronously loads student quiz results", priority: "2" do
      @context = @course
      q = quiz_model
      q.generate_quiz_data
      q.save!

      get "/courses/#{@course.id}/quizzes/#{q.id}"
      f(".al-trigger").click
      f(".quiz_details_link").click
      wait_for_ajaximations
      expect(f("#quiz_details")).to be_displayed
    end

    it "opens and close the send to dialog" do
      @context = @course
      quiz_model
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      f(".al-trigger").click
      f(".direct-share-send-to-menu-item").click
      expect(fj("h2:contains(Send To...)")).to be_displayed
      fj("button:contains(Cancel)").click
      expect(f("body")).not_to contain_jqcss("h2:contains(Send To...)")
      check_element_has_focus(f(".al-trigger"))
    end

    it "opens and close the copy to tray" do
      @context = @course
      quiz_model
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
      f(".al-trigger").click
      f(".direct-share-copy-to-menu-item").click
      expect(fj("h2:contains(Copy To...)")).to be_displayed
      fj("button:contains(Cancel)").click
      expect(f("body")).not_to contain_jqcss("h2:contains(Copy To...)")
      check_element_has_focus(f(".al-trigger"))
    end

    it "creates a new question group", priority: "1" do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button

      click_questions_tab
      f(".add_question_group_link").click
      group_form = f("#questions .quiz_group_form")
      group_form.find_element(:name, "quiz_group[name]").send_keys("new group")
      replace_content(group_form.find_element(:name, "quiz_group[question_points]"), "3")
      submit_form(group_form)
      expect(group_form.find_element(:css, ".group_display.name")).to include_text("new group")
    end

    it "should update a question group", priority: "1"

    it "does not let you exceed the question limit", priority: "2" do
      get "/courses/#{@course.id}/quizzes"
      click_new_quiz_button

      click_questions_tab
      f(".add_question_group_link").click
      group_form = f("#questions .quiz_group_form")
      pick_count_field = group_form.find_element(:name, "quiz_group[pick_count]")
      pick_count = lambda do |count|
        driver.execute_script <<~JS
          var $pickCount = $('#questions .group_top input[name="quiz_group[pick_count]"]');
          $pickCount.focus();
          $pickCount[0].value = #{count.to_s.inspect};
          $pickCount.change();
        JS
      end

      pick_count.call("1001")
      dismiss_alert
      expect(pick_count_field).to have_attribute(:value, "1")

      click_new_question_button # 1 total, ok
      wait_for_ajaximations
      group_form.find_element(:css, ".edit_group_link").click
      pick_count.call("999") # 1000 total, ok

      click_new_question_button # 1001 total, bad
      dismiss_alert

      pick_count.call("1000") # 1001 total, bad
      dismiss_alert
      expect(pick_count_field).to have_attribute(:value, "999")
    end

    describe "insufficient count warnings" do
      it "shows a warning for groups picking too many questions", priority: "2" do
        get "/courses/#{@course.id}/quizzes"
        click_new_quiz_button
        click_questions_tab
        f(".add_question_group_link").click
        submit_form(".quiz_group_form")
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to be_displayed

        add_question_to_group
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to_not be_displayed

        f("#questions .edit_group_link").click
        replace_content(f('#questions .group_top input[name="quiz_group[pick_count]"]'), "2")
        submit_form(".quiz_group_form")
        wait_for_ajaximations
        expect(f(".insufficient_count_warning")).to be_displayed

        # save and reload
        expect_new_page_load { f(".save_quiz_button").click }
        quiz = @course.quizzes.last
        get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

        click_questions_tab
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to be_displayed

        add_question_to_group
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to_not be_displayed
      end

      it "shows a warning for groups picking too many questions from a bank", priority: "2" do
        bank = @course.assessment_question_banks.create!
        assessment_question_model(bank:)

        get "/courses/#{@course.id}/quizzes"
        click_new_quiz_button
        click_questions_tab
        f(".add_question_group_link").click

        f(".find_bank_link").click
        fj("#find_bank_dialog .bank:visible").click
        submit_dialog("#find_bank_dialog", ".submit_button")
        submit_form(".quiz_group_form")
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to_not be_displayed

        f("#questions .edit_group_link").click
        replace_content(f('#questions .group_top input[name="quiz_group[pick_count]"]'), "2")
        submit_form(".quiz_group_form")
        wait_for_ajaximations
        expect(f(".insufficient_count_warning")).to be_displayed

        # save and reload
        expect_new_page_load { f(".save_quiz_button").click }
        quiz = @course.quizzes.last
        get "/courses/#{@course.id}/quizzes/#{quiz.id}/edit"

        click_questions_tab
        wait_for_ajaximations

        expect(f(".insufficient_count_warning")).to be_displayed

        f("#questions .edit_group_link").click
        replace_content(f('#questions .group_top input[name="quiz_group[pick_count]"]'), "1")
        submit_form(".quiz_group_form")
        wait_for_ajaximations
        expect(f(".insufficient_count_warning")).to_not be_displayed
      end
    end

    describe "moderation" do
      before :once do
        @student = user_with_pseudonym(active_user: true, username: "student@example.com", password: "qwertyuiop")
        @course.enroll_user(@student, "StudentEnrollment", enrollment_state: "active")
        @context = @course
        @quiz = quiz_model
        @quiz.time_limit = 20
        @quiz.generate_quiz_data
        @quiz.save!
      end

      it "moderates quiz", priority: "1" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/moderate"
        f(".moderate_student_link").click

        # validates data
        f("#extension_extra_attempts").send_keys("asdf")
        submit_dialog_form("#moderate_student_form")
        expect(f(".attempts_left").text).to eq "1"

        # valid values
        f("#extension_extra_attempts").clear
        f("#extension_extra_attempts").send_keys("2")
        submit_dialog_form("#moderate_student_form")
        wait_for_ajax_requests
        expect(f(".attempts_left").text).to eq "3"
      end

      it "preserves extra time values", priority: "2" do
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}/moderate"
        f(".moderate_student_link").click

        # initial data entry
        f("#extension_extra_time").send_keys("13")
        submit_dialog_form("#moderate_student_form")
        wait_for_ajax_requests

        # preserve values between moderation invocations
        expect(f(".extra_time_allowed").text).to eq "gets 13 extra minutes on each attempt"
        f(".moderate_student_link").click
        expect(f("#extension_extra_time")).to have_value "13"
      end
    end

    it "validates numerical input data", priority: "1" do
      skip_if_safari(:alert)
      @quiz = quiz_with_new_questions do |bank, quiz|
        aq = bank.assessment_questions.create!
        quiz.quiz_questions.create!(question_data: { :name => "numerical", "question_type" => "numerical_question", "answers" => [], :points_possible => 1 }, assessment_question: aq)
      end
      user_session(@student)
      take_quiz do
        input = f(".numerical_question_input")

        input.click
        input.send_keys("asdf")
        wait_for_ajaximations
        expect(error_displayed?).to be_truthy
        driver.execute_script('$(".numerical_question_input").change()')
        wait_for_ajaximations
        expect(input[:value]).to be_blank

        input.click
        input.send_keys("1")
        wait_for_ajaximations
        expect(error_displayed?).to be_falsey
        driver.execute_script('$(".numerical_question_input").change()')
        wait_for_ajaximations
        expect(input).to have_attribute(:value, "1")
      end
      user_session(@user)
    end

    it "should mark dropdown questions as answered", priority: "2"

    it "gives a student extra time if the time limit is extended", priority: "2" do
      skip "Failing Crystalball DEMO-212"
      @context = @course
      bank = @course.assessment_question_banks.create!(title: "Test Bank")
      q = quiz_model
      a = bank.assessment_questions.create!
      answers = [{ id: 1, answer_text: "A", weight: 100 }, { id: 2, answer_text: "B", weight: 0 }]
      question = q.quiz_questions.create!(question_data: {
                                            :name => "first question",
                                            "question_type" => "multiple_choice_question",
                                            "answers" => answers,
                                            :points_possible => 1
                                          },
                                          assessment_question: a)

      q.generate_quiz_data
      q.time_limit = 10
      q.save!

      user_session(@student)
      get "/courses/#{@course.id}/quizzes/#{q.id}/take"
      f("#take_quiz_link").click
      sleep 1

      answer_one = f("#question_#{question.id}_answer_1")

      # force a save to create a submission
      answer_one.click
      wait_for_ajaximations

      # add time. this code replicates what happens in
      # QuizSubmissions#extensions when a moderator extends a student's
      # quiz time.

      quiz_original_end_time = Quizzes::QuizSubmission.last.end_at
      submission = Quizzes::QuizSubmission.last
      submission.end_at = 20.minutes.from_now
      submission.save!
      expect(quiz_original_end_time).to be < Quizzes::QuizSubmission.last.end_at

      # answer a question to force a quicker UI sync (so we don't have to
      # wait ~15 seconds). need to wait 1 sec cuz updateSubmission :'(
      sleep 1
      f("#question_#{question.id}_answer_2").click

      expect(f(".time_running")).to include_text "19 Minutes"
    end

    def upload_attachment_answer
      f("input[type=file]").send_keys @fullpath
      wait_for_ajaximations
      expect(f(".file-uploaded").text).to be
      expect(f(".list_question, .answered").text).to be
      f(".upload-label").click
      wait_for_ajaximations
    end

    def file_upload_submission_data
      @quiz.reload.quiz_submissions.first
           .submission_data[:"question_#{@question.id}"]
    end

    def file_upload_attachment
      @quiz.reload.quiz_submissions.first.attachments.first
    end

    it "works with file upload questions", priority: "1" do
      skip_if_chrome("issue with upload_attachment_answer")
      @context = @course
      bank = @course.assessment_question_banks.create!(title: "Test Bank")
      q = quiz_model
      a = bank.assessment_questions.create!
      answers = { "answer_0" => { "id" => 1 }, "answer_1" => { "id" => 2 } }
      @question = q.quiz_questions.create!(question_data: {
                                             :name => "first question",
                                             "question_type" => "file_upload_question",
                                             "question_text" => "file upload question maaaan",
                                             "answers" => answers,
                                             :points_possible => 1
                                           },
                                           assessment_question: a)
      q.generate_quiz_data
      q.save!
      _filename, @fullpath, _data = get_file "testfile1.txt"

      Setting.set("context_default_quota", "1") # shouldn't check quota

      user_session(@student)
      begin_quiz

      # so we can .send_keys to the input, can't if it's invisible to the browser
      driver.execute_script "$('.file-upload').removeClass('hidden')"
      upload_attachment_answer
      expect(file_upload_submission_data).to eq [file_upload_attachment.id.to_s]

      expect_new_page_load do
        driver.get driver.current_url
        driver.switch_to.alert.accept
      end

      wait_for_ajaximations
      attachment = file_upload_attachment
      expect(f(".file-upload-box")).to include_text attachment.display_name
      f("#submit_quiz_button").click
      expect(f(".selected_answer")).to include_text attachment.display_name
    end

    it "should notify a student of extra time given by a moderator", priority: "2"

    it "displays a link to quiz statistics for a MOOC", priority: "2" do
      quiz_with_submission
      @course.large_roster = true
      @course.save!
      get "/courses/#{@course.id}/quizzes/#{@quiz.id}"

      expect(f("#right-side")).to include_text("Quiz Statistics")
    end

    it "does not allow a teacher to take a quiz" do
      @quiz = quiz_model({ course: @course, time_limit: 5 })
      @quiz.quiz_questions.create!(question_data: multiple_choice_question_data)
      @quiz.generate_quiz_data
      @quiz.save!

      get "/courses/#{@course.id}/quizzes/#{@quiz.id}/take"
      expect(f("#content")).not_to contain_css("#take_quiz_link")
    end

    context "in a paced course" do
      before do
        @course_paces_enabled = @course.enable_course_paces?
        @course.enable_course_paces = true
        @course.save!
      end

      after do
        @course.enable_course_paces = @course_pacing_enabled
        @course.save!
      end

      it "shows the course pacing notice" do
        create_quiz_with_due_date
        add_quiz_to_module
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f("[data-testid='CoursePacingNotice']")).to be_displayed
        expect(f("#content")).not_to contain_css("table.assignment_dates")
      end

      it "does not show course pacing notice if quiz is not a module item" do
        create_quiz_with_due_date
        get "/courses/#{@course.id}/quizzes/#{@quiz.id}"
        expect(f("#content")).not_to contain_css("[data-testid='CoursePacingNotice']")
        expect(f("table.assignment_dates")).to be_displayed
      end
    end
  end
end
