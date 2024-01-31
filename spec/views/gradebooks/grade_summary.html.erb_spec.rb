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
#

require_relative "../views_helper"

describe "gradebooks/grade_summary" do
  it "renders" do
    course_with_student
    view_context
    @course.assignments.create!(title: "some assignment")
    assign(:presenter, GradeSummaryPresenter.new(@course, @user, nil))
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
  end

  it "does not show totals if configured so" do
    course_with_student
    @course.hide_final_grades = true
    view_context
    @course.assignments.create!(title: "some assignment")
    assign(:presenter, GradeSummaryPresenter.new(@course, @user, nil))
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
    page = Nokogiri("<document>" + response.body + "</document>")
    expect(page.css(".final_grade").length).to eq 0
  end

  it "does not show 'what if' if not the student" do
    course_with_teacher
    student_in_course(active_all: true)
    @student = @user
    @user = @teacher
    view_context
    @course.assignments.create!(title: "some assignment")
    presenter = assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
    expect(presenter.student_enrollment).not_to be_nil
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
    expect(response.body).not_to match(/Click any score/)
  end

  it "knows the types of media comments" do
    stub_kaltura
    course_with_teacher
    student_in_course(active_all: true)
    view_context
    a = @course.assignments.create!(title: "some assignment", submission_types: ["online_text_entry"])
    sub = a.submit_homework @student, submission_type: "online_text_entry", body: "o hai"
    sub.add_comment author: @teacher, media_comment_id: "0_abcdefgh", media_comment_type: "audio"
    sub.add_comment author: @teacher, media_comment_id: "0_ijklmnop", media_comment_type: "video"
    assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
    render "gradebooks/grade_summary"
    doc = Nokogiri::HTML5.fragment response.body
    expect(doc.at_css(".audio_comment ~ span.media_comment_id").text).to eql "0_abcdefgh"
    expect(doc.at_css(".video_comment ~ span.media_comment_id").text).to eql "0_ijklmnop"
  end

  it "shows media comments with text included" do
    stub_kaltura
    course_with_teacher
    student_in_course(active_all: true)
    view_context
    a = @course.assignments.create!(title: "some assignment", submission_types: ["online_text_entry"])
    sub = a.submit_homework(@student, submission_type: "online_text_entry", body: "o hai")
    sub.add_comment(author: @teacher,
                    media_comment_id: "0_ijklmnop",
                    media_comment_type: "video",
                    comment: "hello")
    assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
    render("gradebooks/grade_summary")
    doc = Nokogiri::HTML5.fragment response.body
    expect(doc.at_css(".comment_media > span:first-child").text).to eql "hello"
    expect(doc.at_css(".video_comment ~ span.media_comment_id").text).to eql "0_ijklmnop"
  end

  it "shows a disabled message for grade stats for the test student" do
    course_with_teacher(active_all: true)
    @student = @course.student_view_student
    @user = @teacher
    view_context
    a = @course.assignments.create!(title: "some assignment", points_possible: 10)
    a.grade_student(@student, grade: "10", grader: @teacher)
    assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
    render "gradebooks/grade_summary"
    expect(response).not_to be_nil
    expect(response.body).to match(/Test Student scores are not included in grade statistics./)
  end

  describe "submission details link" do
    before do
      course_with_teacher
      student_in_course(active_all: true)
      observer_in_course(course: @course, associated_user_id: @student, active_all: true)

      @assignment = @course.assignments.create!(title: "Random Assignment")
      @assignment.ensure_post_policy(post_manually: true)
      @assignment.submit_homework @student, submission_type: "online_text_entry", body: "o hai there"
      @assignment.grade_student(@student, score: 10, grader: @teacher)

      @assignment_url = context_url(@course, :context_assignment_url, @assignment)
      @speed_grader_url = speed_grader_course_gradebook_url({ course_id: @assignment.context_id, assignment_id: @assignment }.merge({ student_id: @student.id, only_path: true }))
      @submission_details_url = context_url(@course, :context_assignment_submission_url, @assignment, @student.id)
    end

    context "when the assignment enhancements flag is enabled" do
      before do
        @course.enable_feature!(:assignments_2_student)
      end

      it "takes the submitting student to A2 flow" do
        @user = @student
        assign(:presenter, GradeSummaryPresenter.new(@course, @student, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@assignment_url}']")
      end

      it "takes the observer to A2 flow" do
        @user = @observer
        assign(:presenter, GradeSummaryPresenter.new(@course, @observer, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@assignment_url}']")
      end

      it "takes the teacher to Speedgrader link" do
        @user = @teacher
        assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@speed_grader_url}']")
      end

      it "takes the admin to Speedgrader link" do
        @user = account_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@speed_grader_url}']")
      end

      it "takes the site admin to Speedgrader link" do
        @user = site_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@speed_grader_url}']")
      end
    end

    context "when the assignment enhancements flag is disabled" do
      it "takes the submitting student to submission details page" do
        @user = @student
        assign(:presenter, GradeSummaryPresenter.new(@course, @student, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@submission_details_url}']")
      end

      it "takes the teacher to submission details page" do
        @user = @teacher
        assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@submission_details_url}']")
      end

      it "takes the admin to submission details page" do
        @user = account_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@submission_details_url}']")
      end

      it "takes the site admin to submission details page" do
        @user = site_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@submission_details_url}']")
      end
    end
  end

  describe "submission details link for anonymous moderated assignment" do
    before do
      course_with_teacher
      student_in_course(active_all: true)

      @assignment = @course.assignments.create!(title: "Moderated Assignment", anonymous_grading: true)
      @assignment.ensure_post_policy(post_manually: true)
      @assignment.submit_homework @student, submission_type: "online_text_entry", body: "o hai"
      @assignment.grade_student(@student, score: 10, grader: @teacher)

      @assignment_url = context_url(@course, :context_assignment_url, @assignment)
      @speed_grader_url = speed_grader_course_gradebook_url({ course_id: @assignment.context_id, assignment_id: @assignment }.merge({ student_id: @student.id, only_path: true }))
      @submission_details_url = context_url(@course, :context_assignment_submission_url, @assignment, @student.id)
    end

    context "when the assignment enhancements flag is enabled" do
      before do
        @course.enable_feature!(:assignments_2_student)
      end

      it "takes the submitting student to A2 flow" do
        @user = @student
        assign(:presenter, GradeSummaryPresenter.new(@course, @student, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@assignment_url}']")
      end

      it "is hidden for a teacher" do
        @user = @teacher
        assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).not_to have_tag("a[href='#{@speed_grader_url}']")
      end

      it "is hidden for an admin" do
        @user = account_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).not_to have_tag("a[href='#{@speed_grader_url}']")
      end

      it "takes the site admin to Speedgrader link" do
        @user = site_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@speed_grader_url}']")
      end
    end

    context "when the assignment enhancements flag is disabled" do
      it "is shown for the submitting student" do
        @user = @student
        assign(:presenter, GradeSummaryPresenter.new(@course, @student, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@submission_details_url}']")
      end

      it "is hidden for a non-submitting student" do
        view_context
        new_student = User.create!
        @course.enroll_student(new_student, enrollment_state: "active")
        assign(:presenter, GradeSummaryPresenter.new(@course, new_student, @student.id))
        user_session(new_student)
        render "gradebooks/grade_summary"
        expect(response).not_to have_tag("a[href='#{@submission_details_url}']")
      end

      it "is hidden for a teacher" do
        @user = @teacher
        assign(:presenter, GradeSummaryPresenter.new(@course, @teacher, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).not_to have_tag("a[href='#{@submission_details_url}']")
      end

      it "is hidden for an admin" do
        @user = account_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).not_to have_tag("a[href='#{@submission_details_url}']")
      end

      it "is shown for a site admin" do
        @user = site_admin_user
        assign(:presenter, GradeSummaryPresenter.new(@course, @user, @student.id))
        view_context
        render "gradebooks/grade_summary"
        expect(response).to have_tag("a[href='#{@submission_details_url}']")
      end
    end
  end

  describe "plagiarism info" do
    let(:course) { Course.create! }
    let(:site_admin) { site_admin_user }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:student) { student_in_course(course:, active_all: true).user }
    let(:attachment) { attachment_model(context: student, content_type: "text/plain") }
    let(:state) { "acceptable" }

    before do
      assign(:context, course)
      assign(:domain_root_account, Account.default)
    end

    context "when there is no turnitin_data" do
      context "when an assignment is not anonymous" do
        let(:assignment) { course.assignments.create!(submission_types: "online_upload") }

        before { assignment.submit_homework(student, submission_type: "online_upload", attachments: [attachment]) }

        context "when viewed by the submitting student" do
          let(:presenter) { GradeSummaryPresenter.new(course, student, student.id) }

          before do
            assign(:presenter, presenter)
            assign(:current_user, student)
            render "gradebooks/grade_summary"
          end

          it "does not show turnitin plagiarism image" do
            expect(response).not_to have_tag("img[src*=turnitin_#{state}_score][alt='See Turnitin results']")
          end

          it "does not show turnitin plagiarism tooltip" do
            expect(response).not_to have_tag('.tooltip_text:contains("See Turnitin results")')
          end
        end
      end
    end

    context "when turnitin_data is present" do
      let(:turnitin_data) do
        {
          "attachment_#{attachment.id}" => {
            similarity_score: 1.0,
            web_overlap: 5.0,
            publication_overlap: 0.0,
            student_overlap: 0.0,
            state:
          }
        }
      end

      let(:assignment) { course.assignments.create!(submission_types: "online_upload") }

      before do
        submission = assignment.submit_homework(student, submission_type: "online_upload", attachments: [attachment])
        submission.update_attribute :turnitin_data, turnitin_data
      end

      context "when viewed by the submitting student" do
        let(:presenter) { GradeSummaryPresenter.new(course, student, student.id) }

        before do
          assign(:presenter, presenter)
          assign(:current_user, student)
          render "gradebooks/grade_summary"
        end

        it "shows turnitin plagiarism image" do
          expect(response).to have_tag("img[src*=turnitin_#{state}_score][alt='See Turnitin results']")
        end

        it "shows turnitin plagiarism tooltip" do
          expect(response).to have_tag("a[data-tooltip='left'][title='Similarity score -- more information']")
        end
      end

      context "when viewed by a teacher" do
        let(:presenter) { GradeSummaryPresenter.new(course, teacher, student.id) }

        before do
          assign(:presenter, presenter)
          assign(:current_user, teacher)
          render "gradebooks/grade_summary"
        end

        it "shows turnitin plagiarism image" do
          expect(response).to have_tag("img[src*=turnitin_#{state}_score][alt='See Turnitin results']")
        end

        it "shows turnitin plagiarism tooltip" do
          expect(response).to have_tag("a[data-tooltip='left'][title='Similarity score -- more information']")
        end
      end

      context "when viewed by an admin" do
        let(:presenter) { GradeSummaryPresenter.new(course, site_admin, student.id) }

        before do
          assign(:presenter, presenter)
          assign(:current_user, site_admin)
          render "gradebooks/grade_summary"
        end

        it "shows turnitin plagiarism image" do
          expect(response).to have_tag("img[src*=turnitin_#{state}_score][alt='See Turnitin results']")
        end

        it "shows turnitin plagiarism tooltip" do
          expect(response).to have_tag("a[data-tooltip='left'][title='Similarity score -- more information']")
        end
      end
    end

    context "when an assignment is anonymous" do
      let(:assignment) do
        course.assignments.create!(title: "hi", submission_types: "online_upload", anonymous_grading: true)
      end

      before do
        assignment.ensure_post_policy(post_manually: true)
        assignment.submit_homework(student, submission_type: "online_text_entry", body: "hello")
        assignment.grade_student(student, score: 10, grader: teacher)
      end

      context "when viewed by a teacher" do
        let(:presenter) { GradeSummaryPresenter.new(course, teacher, student.id) }

        before do
          assign(:presenter, presenter)
          assign(:current_user, teacher)
        end

        it "calls turnitin_enabled? and returns false" do
          expect(presenter).to receive(:turnitin_enabled?).at_least(1).time.and_return(false)
          render "gradebooks/grade_summary"
        end

        context "when the assignment uses Turnitin" do
          before { allow(presenter).to receive(:turnitin_enabled?).and_return(true) }

          it "does not show plagiarism info when students are anonymized" do
            render "gradebooks/grade_summary"
            expect(response).not_to have_tag("a[@title='Similarity score -- more information']")
          end

          it "shows plagiarism info when students are not anonymized" do
            assignment.unmute!

            render "gradebooks/grade_summary"
            expect(response).to have_tag("a[@title='Similarity score -- more information']")
          end
        end

        context "when the submission has an associated originality report" do
          before do
            assignment.submission_for_student(student).originality_reports.create!(
              workflow_state: "scored",
              originality_score: 88
            )
          end

          it "does not show plagiarism info when students are anonymized" do
            render "gradebooks/grade_summary"
            expect(response).not_to have_tag("a[@title='Originality Report']")
          end

          it "shows plagiarism info when students are not anonymized" do
            assignment.unmute!

            render "gradebooks/grade_summary"
            expect(response).to have_tag("a[@title='Originality Report']")
          end
        end

        context "when the assignment uses Vericite" do
          before { allow(presenter).to receive(:vericite_enabled?).and_return(true) }

          it "does not show plagiarism info when students are anonymized" do
            render "gradebooks/grade_summary"
            expect(response).not_to have_tag("a[@title='VeriCite similarity score -- more information']")
          end

          it "shows plagiarism info when students are not anonymized" do
            assignment.unmute!

            render "gradebooks/grade_summary"
            expect(response).to have_tag("a[@title='VeriCite similarity score -- more information']")
          end
        end
      end

      context "for an anonymized assignment viewed by a site administrator" do
        let(:site_admin) { site_admin_user }
        let(:presenter) { GradeSummaryPresenter.new(course, site_admin, student.id) }

        before do
          assign(:presenter, presenter)
          assign(:current_user, site_admin)
        end

        it "always shows plagiarism info when the assignment uses Turnitin" do
          allow(presenter).to receive(:turnitin_enabled?).and_return(true)

          render "gradebooks/grade_summary"
          expect(response).to have_tag("a[@title='Similarity score -- more information']")
        end

        it "always shows plagiarism info when the submission has an originality report" do
          assignment.submission_for_student(student).originality_reports.create!(
            workflow_state: "scored",
            originality_score: 88
          )

          render "gradebooks/grade_summary"
          expect(response).to have_tag("a[@title='Originality Report']")
        end

        it "always shows plagiarism info when the assignment uses Vericite" do
          allow(presenter).to receive(:vericite_enabled?).and_return(true)

          render "gradebooks/grade_summary"
          expect(response).to have_tag("a[@title='VeriCite similarity score -- more information']")
        end
      end
    end

    context "when the New Gradebook Plagiarism Indicator feature is enabled" do
      before do
        course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator)
        assignment.submit_homework(student, submission_type: "online_text_entry", body: "hi")

        assign(:presenter, presenter)
        assign(:current_user, teacher)
      end

      let(:assignment) { course.assignments.create!(submission_types: "online_upload") }
      let(:submission) { assignment.submission_for_student(student) }
      let(:presenter) { GradeSummaryPresenter.new(course, teacher, student.id) }
      let(:icon_css_query) { "i.icon-empty" }

      let(:turnitin_data) do
        {
          "submission_#{submission.id}" => {
            similarity_score: 80.0,
            web_overlap: 5.0,
            publication_overlap: 0.0,
            student_overlap: 0.0,
            state: "failure",
            status: "scored"
          }
        }
      end

      it "displays an updated plagiarism indicator when the assignment uses Turnitin" do
        allow(presenter).to receive(:turnitin_enabled?).and_return(true)
        submission.update!(turnitin_data:)

        render "gradebooks/grade_summary"
        expect(response).to have_tag(icon_css_query)
      end

      it "displays an updated plagiarism indicator when the assignment uses Vericite" do
        allow(presenter).to receive(:vericite_enabled?).and_return(true)
        submission.update!(turnitin_data: turnitin_data.merge({ provider: "vericite" }))

        render "gradebooks/grade_summary"
        expect(response).to have_tag(icon_css_query)
      end

      it "displays an updated plagiarism indicator when the assignment has an originality report" do
        submission.originality_reports.create!(
          workflow_state: "scored",
          originality_score: 80
        )

        render "gradebooks/grade_summary"
        expect(response).to have_tag(icon_css_query)
      end
    end
  end

  describe "hidden indicator" do
    let_once(:course) { Course.create! }
    let_once(:student) { course.enroll_student(User.create!, active_all: true).user }
    let_once(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let_once(:assignment) { course.assignments.create!(title: "hi") }
    let_once(:submission) { assignment.submissions.find_by!(user: student) }

    before(:once) do
      assign(:presenter, GradeSummaryPresenter.new(course, student, student.id))
      assign(:current_user, student)
      assign(:context, course)
      assign(:domain_root_account, Account.default)
    end

    context "when post policy is set to manual" do
      before(:once) do
        assignment.ensure_post_policy(post_manually: true)
      end

      it "displays the 'hidden' icon" do
        render "gradebooks/grade_summary"
        expect(response).to have_tag(".assignment_score i[@class='icon-off']")
      end

      it 'adds the "hidden" title to the icon' do
        render "gradebooks/grade_summary"
        expect(response).to have_tag(".assignment_score i[@title='Instructor has not posted this grade']")
      end

      context "when submissions are posted" do
        before { assignment.post_submissions(submission_ids: submission.id) }

        it 'does not add the "hidden" title to the icon' do
          render "gradebooks/grade_summary"
          expect(response).not_to have_tag(".assignment_score i[@title='Instructor has not posted this grade']")
        end

        it "does not display the 'hidden' icon" do
          render "gradebooks/grade_summary"
          expect(response).not_to have_tag(".assignment_score i[@class='icon-off']")
        end
      end
    end

    context "when post policy is set to automatic" do
      before(:once) do
        assignment.ensure_post_policy(post_manually: false)
      end

      it 'does not add the "hidden" title to the icon' do
        render "gradebooks/grade_summary"
        expect(response).not_to have_tag(".assignment_score i[@title='Instructor has not posted this grade']")
      end

      it "does not display the 'hidden' icon" do
        render "gradebooks/grade_summary"
        expect(response).not_to have_tag(".assignment_score i[@class='icon-off']")
      end

      context "when submissions are graded and unposted" do
        before do
          assignment.grade_student(student, score: 10, grader: teacher)
          assignment.hide_submissions(submission_ids: submission.id)
        end

        it 'adds the "hidden" title to the icon' do
          render "gradebooks/grade_summary"
          expect(response).to have_tag(".assignment_score i[@title='Instructor has not posted this grade']")
        end

        it "displays the 'hidden' icon" do
          render "gradebooks/grade_summary"
          expect(response).to have_tag(".assignment_score i[@class='icon-off']")
        end
      end
    end
  end

  describe "comments toggle button" do
    let(:course) { Course.create! }
    let(:student) { course.enroll_student(User.create!, active_all: true).user }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:assignment) { course.assignments.create! }

    before do
      view_context(course, student)
      assign(:presenter, GradeSummaryPresenter.new(course, student, nil))
    end

    context "when comments exist" do
      before do
        submission = assignment.submission_for_student(student)
        submission.add_comment(author: teacher, comment: "hello")
      end

      it "is visible when assignment not muted" do
        render "gradebooks/grade_summary"
        expect(response).to have_tag(".toggle_comments_link[@role='button']")
      end

      it "is not visible when assignment is muted" do
        assignment.mute!
        render "gradebooks/grade_summary"
        expect(response).to have_tag(".toggle_comments_link[@aria-hidden='true']")
      end
    end

    context "when no comments exist" do
      it "not visible" do
        course.assignments.create!
        render "gradebooks/grade_summary"
        expect(response).to have_tag(".toggle_comments_link[@aria-hidden='true']")
      end
    end
  end

  describe "display due value" do
    let(:course) { Course.create! }
    let(:student) { course.enroll_student(User.create!, active_all: true).user }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:presenter) { GradeSummaryPresenter.new(course, student, student.id) }

    before do
      view_context(course, student)
      assign(:presenter, presenter)
    end

    it "due is not shown" do
      render "gradebooks/grade_summary"
      expect(response).not_to have_tag("#grades_summary .due")
    end

    it "renders \"due\" when there is a submission" do
      assignment1 = course.assignments.create!(points_possible: 10)
      assignment1.submit_homework student, submission_type: "online_text_entry", body: "hey"
      assignment1.grade_student(student, score: 10, grader: teacher)

      render "gradebooks/grade_summary"
      expect(response).to have_tag("#grades_summary .due")
    end
  end

  describe "display submitted value" do
    let(:course) { Course.create! }
    let(:student) { course.enroll_student(User.create!, active_all: true).user }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:presenter) { GradeSummaryPresenter.new(course, student, student.id) }

    before do
      view_context(course, student)
      assign(:presenter, presenter)
    end

    it "submitted is not shown" do
      render "gradebooks/grade_summary"
      expect(response).not_to have_tag("#grades_summary .submitted")
    end

    it "renders \"submitted\" when there is a submission" do
      assignment1 = course.assignments.create!(points_possible: 10)
      assignment1.submit_homework student, submission_type: "online_text_entry", body: "hey"
      assignment1.grade_student(student, score: 10, grader: teacher)

      render "gradebooks/grade_summary"
      expect(response).to have_tag("#grades_summary .submitted")
    end
  end

  describe "display out of value" do
    let(:course) { Course.create! }
    let(:student) { course.enroll_student(User.create!, active_all: true).user }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:presenter) { GradeSummaryPresenter.new(course, student, student.id) }

    before do
      view_context(course, student)
      assign(:presenter, presenter)
    end

    it "out of value is shown in the score column" do
      render "gradebooks/grade_summary"
      expect(response).not_to have_tag("#grades_summary th.possible")
    end

    it "renders \"out of\" with new format" do
      assignment1 = course.assignments.create!(points_possible: 10)
      assignment1.submit_homework student, submission_type: "online_text_entry", body: "hey"
      assignment1.grade_student(student, score: 10, grader: teacher)

      render "gradebooks/grade_summary"
      expect(response).to match(%r{10\s+</span>\s+<span>/ 10</span>})
    end

    it "renders letter for letter graded" do
      assignment1 = course.assignments.create!(grading_type: "letter_grade", points_possible: 10)
      assignment1.submit_homework student, submission_type: "online_text_entry", body: "hey 1"
      assignment1.grade_student(student, grade: "A", grader: teacher)

      render "gradebooks/grade_summary"
      expect(response).to match(%r{<span class="score_value">\s+10 \(A\)\s+</span>}mi)
    end

    it "renders percentage for \"percent\" grade" do
      assignment1 = course.assignments.create!(grading_type: "percent", points_possible: 10)
      assignment1.submit_homework student, submission_type: "online_text_entry", body: "hey 2"
      assignment1.grade_student(student, grade: "90%", grader: teacher)

      render "gradebooks/grade_summary"
      expect(response).to match(%r{</span>\s+90%\s+</span>}mi)
    end

    it "renders out of for assignment groups" do
      assignment1 = course.assignments.create!(grading_type: "percent", points_possible: 10)
      assignment1.submit_homework student, submission_type: "online_text_entry", body: "hey 2"
      assignment1.grade_student(student, grade: "90%", grader: teacher)

      group = course.assignment_groups.create!(name: "a group")
      group_assignment = OpenObject.build("assignment",
                                          id: "group-#{group.id}",
                                          rules: group.rules,
                                          title: group.name,
                                          points_possible: 10,
                                          hard_coded: true,
                                          special_class: "group_total",
                                          assignment_group_id: group.id,
                                          group_weight: group.group_weight,
                                          asset_string: "group_total_#{group.id}")
      presenter.groups_assignments = [group_assignment]

      render "gradebooks/grade_summary"
      expect(response).to match(%r{</span>\s+90%\s+</span>}mi)
      expect(response).to have_tag("span.points_possible")
    end
  end

  describe "visibility feedback student grades page" do
    before(:once) do
      course_with_student({ active_all: true })
      @a1 = @course.assignments.create!(submission_types: "online_text_entry")
      @a2 = @course.assignments.create!(submission_types: "online_text_entry")

      view_context(@course, @student)
      assign(:presenter, GradeSummaryPresenter.new(@course, @student, nil))

      @a1.submit_homework(@student, body: "done!")
      @a2.submit_homework(@student, body: "done!")
    end

    it "has no blue dot if no comment, grade or rubric" do
      render "gradebooks/grade_summary"

      expect(response).not_to have_tag("#submission_#{@a1.id} td .grade_dot")
      expect(response).not_to have_tag("#submission_#{@a1.id} td .comment_dot")
      expect(response).not_to have_tag("#submission_#{@a1.id} td .rubric_dot")
    end

    it "has a blue dot on unread grade" do
      @a1.grade_student(@student, grader: @teacher, grade: 1)

      render "gradebooks/grade_summary"

      expect(response).to have_tag("#submission_#{@a1.id} td .grade_dot")
    end

    it "has a blue dot on unread grade and comments" do
      @a1.grade_student(@student, grader: @teacher, grade: 1)
      @a1.submissions.first.add_comment(author: @teacher, comment: "Good!")

      render "gradebooks/grade_summary"

      expect(response).to have_tag("#submission_#{@a1.id} td .grade_dot")
      expect(response).to have_tag("#submission_#{@a1.id} td .comment_dot")
    end

    it "has a blue dot on unread grade, comments and rubric" do
      submission = @a1.grade_student(@student, grader: @teacher, grade: 1).first
      @a1.submissions.first.add_comment(author: @teacher, comment: "Good!")

      rubric_model
      association = @rubric.associate_with(@a1, @course, purpose: "grading", use_for_grading: true)
      association.assess({
                           user: @student,
                           assessor: @teacher,
                           artifact: submission,
                           assessment: {
                             assessment_type: "grading",
                             criterion_crit1: {
                               points: 5,
                               comments: "comments"
                             }
                           }
                         })

      render "gradebooks/grade_summary"

      expect(response).to have_tag("#submission_#{@a1.id} td .grade_dot")
      expect(response).to have_tag("#submission_#{@a1.id} td .comment_dot")
      expect(response).to have_tag("#submission_#{@a1.id} td .rubric_dot")
    end

    it "doesn't have blue dot on grade after it has been read" do
      submission = @a1.grade_student(@student, grader: @teacher, grade: 1).first

      submission.mark_item_read("grade")

      render "gradebooks/grade_summary"

      expect(response).not_to have_tag("#submission_#{@a1.id} td .grade_dot")
    end

    it "has a blue dot on comment if only grade is marked as read" do
      submission = @a1.grade_student(@student, grader: @teacher, grade: 1).first
      submission.add_comment(author: @teacher, comment: "Good!")
      submission.mark_item_read("grade")

      render "gradebooks/grade_summary"

      expect(response).not_to have_tag("#submission_#{@a1.id} td .grade_dot")
      expect(response).to have_tag("#submission_#{@a1.id} td .comment_dot")
    end

    it "has a blue dot for unread grades on each submission" do
      @a1.grade_student(@student, grader: @teacher, grade: 1)
      @a2.grade_student(@student, grader: @teacher, grade: 1)

      render "gradebooks/grade_summary"

      expect(response).to have_tag("#submission_#{@a1.id} td .grade_dot")
      expect(response).to have_tag("#submission_#{@a2.id} td .grade_dot")
    end

    context "when the feature flag is disabled" do
      before(:once) do
        course_with_student({ active_all: true })

        view_context(@course, @student)
        assign(:presenter, GradeSummaryPresenter.new(@course, @student, nil))
      end

      it "does not have the visibility_feedback_ff class" do
        expect(response).not_to have_tag("#grades_summary .visibility_feedback_ff")
      end
    end
  end
end
