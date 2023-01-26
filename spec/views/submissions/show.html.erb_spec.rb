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

require "spec_helper"
require_relative "../views_helper"
require_relative "../../selenium/helpers/groups_common"

describe "submissions/show" do
  include GroupsCommon

  before :once do
    course_with_student(active_all: true)
  end

  it "renders" do
    view_context
    a = @course.assignments.create!(title: "some assignment")
    assign(:assignment, a)
    assign(:submission, a.submit_homework(@user))
    render "submissions/show"
    expect(response).not_to be_nil
  end

  context "when assignment is a group assignment" do
    before :once do
      @group_category = @course.group_categories.create!(name: "Test Group Set")
      @group = @course.groups.create!(name: "a group", group_category: @group_category)
      add_user_to_group(@user, @group, true)
      @assignment =
        @course.assignments.create!(
          assignment_valid_attributes.merge(
            group_category: @group_category,
            grade_group_students_individually: true
          )
        )
      @submission = @assignment.submit_homework(@user)
    end

    before do
      view_context
      assign(:assignment, @assignment)
      assign(:submission, @submission)
    end

    it "shows radio buttons for an individually graded group assignment" do
      render "submissions/show"
      @html = Nokogiri::HTML5.fragment(response.body)
      expect(@html.css('input[type="radio"][name="submission[group_comment]"]').size).to eq 2
      expect(@html.css("#submission_group_comment").size).to eq 1
    end

    it "renders hidden checkbox for a group graded group assignment" do
      @assignment.grade_group_students_individually = false
      @assignment.save!
      render "submissions/show"
      @html = Nokogiri::HTML5.fragment(response.body)
      expect(@html.css('input[type="radio"][name="submission[group_comment]"]').size).to eq 0
      checkbox = @html.css("#submission_group_comment")
      expect(checkbox.attr("checked")).to_not be_nil
      expect(checkbox.attr("style").value).to include("display:none")
    end

    it "peer reviewers are allowed to make group comments" do
      @assignment.update!(grade_group_students_individually: false, peer_reviews: true)
      peer = @course.enroll_student(User.create, enrollment_state: "active").user
      peer_submission = @assignment.submissions.find_by(user: peer)
      AssessmentRequest.create!(
        assessor: peer,
        assessor_asset: peer_submission,
        asset: @submission,
        user: @user
      )
      view_context(@course, peer)
      assign(:assignment, @assignment)
      assign(:submission, @submission)
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("#submission_group_comment").attr("checked")).to_not be_nil
    end

    it "students that are not peer reviewers are not allowed to make group comments" do
      @assignment.update!(grade_group_students_individually: false, peer_reviews: true)
      student2 = @course.enroll_student(User.create, enrollment_state: "active").user
      view_context(@course, student2)
      assign(:assignment, @assignment)
      assign(:submission, @submission)
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      expect(html.css("#submission_group_comment")).to be_empty
    end
  end

  context "when submission is proxied" do
    it "renders the proxy submitter's name" do
      view_context(@course, @user)
      a =
        @course.assignments.create!(
          title: "some assignment",
          points_possible: 10,
          grading_type: "points"
        )
      assign(:assignment, a)
      @submission = a.submit_homework(@user)
      @submission.update!(proxy_submitter: @teacher)
      assign(:submission, @submission)
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)

      expect(html.css(".submission-details-header__info").text).to include @teacher.short_name
    end
  end

  context "when assignment has deducted points" do
    it 'shows the deduction and "grade" as final grade when current_user is teacher' do
      view_context(@course, @teacher)
      a =
        @course.assignments.create!(
          title: "some assignment",
          points_possible: 10,
          grading_type: "points"
        )
      assign(:assignment, a)
      @submission = a.submit_homework(@user)
      @submission.update(grade: 7, points_deducted: 2)
      assign(:submission, @submission)
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)

      expect(html.css(".late_penalty").text).to include("-2")
      expect(html.css(".published_grade").text).to include("7")
    end

    it 'shows the deduction and "published_grade" as final grade when current_user is submission user' do
      view_context(@course, @user)
      a =
        @course.assignments.create!(
          title: "some assignment",
          points_possible: 10,
          grading_type: "points"
        )
      assign(:assignment, a)
      @submission = a.submit_homework(@user)
      @submission.update(grade: "7", points_deducted: 2, published_grade: "6")
      assign(:submission, @submission)
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)

      expect(html.css(".late_penalty").text).to include("-2")
      expect(html.css(".grade").text).to include("6")
    end

    context "and is excused" do
      it "hides the deduction" do
        view_context(@course, @teacher)
        a =
          @course.assignments.create!(
            title: "some assignment",
            points_possible: 10,
            grading_type: "points"
          )
        assign(:assignment, a)
        @submission = a.submit_homework(@user)
        @submission.update(grade: 7, points_deducted: 2, excused: true)
        assign(:submission, @submission)
        render "submissions/show"
        html = Nokogiri::HTML5.fragment(response.body)

        deduction_elements = html.css(".late-penalty-display")

        expect(deduction_elements).not_to be_empty
        deduction_elements.each do |deduction_element|
          expect(deduction_element.attr("style")).to include("display: none;")
        end
      end
    end
  end

  describe "plagiarism report" do
    let(:teacher) do
      user = User.create
      @course.enroll_teacher(user)
      user
    end

    let(:html) do
      render "submissions/show"
      Nokogiri::HTML5.fragment(response.body)
    end

    before :once do
      @assignment =
        @course.assignments.create!(
          assignment_valid_attributes.merge(submission_types: "online_upload,online_text_entry")
        )
      @assignment.unmute!

      @submission =
        @assignment.submit_homework(
          @user,
          { body: "hello there", submission_type: "online_text_entry" }
        )
      @submission.turnitin_data = {
        "submission_#{@submission.id}" => {
          web_overlap: 92,
          error: true,
          publication_overlap: 0,
          state: "failure",
          status: "scored",
          object_id: "123456789",
          student_overlap: 90,
          similarity_score: 92
        }
      }
    end

    before do
      view_context(@course, teacher)
      assign(:assignment, @assignment)
      assign(:submission, @submission)
    end

    context "with new similarity icons enabled" do
      before { @course.root_account.enable_feature!(:new_gradebook_plagiarism_indicator) }

      let(:icon_css_query) { "i.icon-empty" }

      it "is present when the plagiarism report is from turnitin" do
        expect(html.css(icon_css_query).size).to eq 1
      end

      it "is present when the plagiarism report is from vericite" do
        @submission.turnitin_data[:provider] = "vericite"
        expect(html.css(icon_css_query).size).to eq 1
      end

      it "is not present when there is no plagiarism report" do
        @submission.turnitin_data = {}
        expect(html.css(icon_css_query).size).to eq 0
      end
    end

    context "with new similarity icons disabled" do
      context "for turnitin" do
        it "is present when the plagiarism report is from turnitin" do
          expect(html.css(".turnitin_score_container_caret").size).to eq 1
        end

        it "is present when the plagiarism report is blank (defaults to turnitin)" do
          @submission.turnitin_data.delete(:provider)
          expect(html.css(".turnitin_score_container_caret").size).to eq 1
        end

        it "is not present when the plagiarism report is from vericite" do
          @submission.turnitin_data[:provider] = "vericite"
          expect(html.css(".turnitin_score_container_caret").size).to eq 0
        end
      end

      context "for vericite" do
        before { @submission.turnitin_data[:provider] = "vericite" }

        it "is present when the plagiarism report is from vericite" do
          expect(html.css(".vericite_score_container_caret").size).to eq 1
        end

        it "is not present when the plagiarism report is from turnitin" do
          @submission.turnitin_data[:provider] = "turnitin"
          expect(html.css(".vericite_score_container_caret").size).to eq 0
        end

        it "is not present when the plagiarism report is blank (defaults to turnitin)" do
          @submission.turnitin_data.delete(:provider)
          expect(html.css(".vericite_score_container_caret").size).to eq 0
        end
      end
    end
  end

  describe "Grade" do
    let(:html) { Nokogiri::HTML5.fragment(response.body) }

    before(:once) do
      @course = Course.create!
      @student = @course.enroll_user(User.create!, "StudentEnrollment", active_all: true).user
      @assignment = @course.assignments.create!
      @submission = @assignment.submissions.find_by(user: @student)
      @submission.update!(score: 23.0)
    end

    before do
      assign(:assignment, @assignment)
      assign(:context, @course)
      assign(:current_user, @student)
      assign(:submission, @submission)
    end

    context "when assignment posts automatically" do
      before { @assignment.ensure_post_policy(post_manually: false) }

      it "does not display a message when submission is unposted and assignment posts automatically" do
        render "submissions/show"
        summary = html.css(".submission-details-header__grade-summary p").text
        expect(
          summary
        ).not_to include "Grades are unavailable because the instructor is working on them."
      end

      it "does not display a message when submission is posted and assignment posts automatically" do
        @submission.update!(posted_at: Time.zone.now)
        render "submissions/show"
        summary = html.css(".submission-details-header__grade-summary p").text
        expect(
          summary
        ).not_to include "Grades are unavailable because the instructor is working on them."
      end

      it "displays the grade when submission is posted and user can :read_grade" do
        @submission.update!(posted_at: Time.zone.now)
        render "submissions/show"
        grade = html.css(".entered_grade").text
        expect(grade).to include "23"
      end
    end

    context "when assignment posts manually" do
      before { @assignment.ensure_post_policy(post_manually: true) }

      it "displays a message when submission is unposted" do
        render "submissions/show"
        summary = html.css(".submission-details-header__grade-summary p").text
        expect(summary).to eql "Grades are unavailable because the instructor is working on them."
      end

      it "does not display a message when submission is posted" do
        @submission.update!(posted_at: Time.zone.now)
        render "submissions/show"
        summary = html.css(".submission-details-header__grade-summary p").text
        expect(
          summary
        ).not_to include "Grades are unavailable because the instructor is working on them."
      end

      it "does not display the grade when submission is unposted" do
        render "submissions/show"
        expect(html.css(".entered_grade")).to be_empty
      end

      it "displays the grade when submission is posted" do
        @submission.update!(posted_at: Time.zone.now)
        render "submissions/show"
        expect(html.css(".entered_grade").text).to include "23"
      end

      context "when the viewing user is a teacher" do
        let(:teacher) { @course.enroll_teacher(User.create!, enrollment_state: "active").user }

        before { assign(:current_user, teacher) }

        it "displays the current grade even when the submission is not posted" do
          render "submissions/show"
          expect(html.css(".grading_box").attr("value").value).to include("23")
        end

        it "displays the grade input fields even when the submission is not posted" do
          render "submissions/show"
          expect(html.css(".grade-values")).to be_present
        end
      end
    end
  end

  context "comments sidebar" do
    describe "non-owner comment visibility" do
      let(:student) { User.create! }
      let(:teacher) { User.create! }
      let(:course) { Course.create!(name: "a course") }

      let(:muted_assignment) do
        assignment = course.assignments.create!(title: "muted")
        assignment.ensure_post_policy(post_manually: true)
        assignment
      end
      let(:muted_submission) { muted_assignment.submission_for_student(student) }
      let(:unmuted_assignment) do
        assignment = course.assignments.create!(title: "not muted")
        assignment.unmute!
        assignment
      end
      let(:unmuted_submission) { unmuted_assignment.submission_for_student(student) }

      let(:comment_contents) do
        html = Nokogiri::HTML5.fragment(response.body)
        comment_list = html.css(".submission-details-comments .comment_list")

        # Comments are structured as:
        # <div class="comment">
        #   <div class="comment">the actual comment text</div>
        #   <div class="author">author name</div>
        #   ... and so on
        # </div>
        comment_list.css(".comment .comment").map { |comment| comment.text.strip }
      end

      before do
        assign(:context, course)

        course.enroll_teacher(teacher).accept(true)
        course.enroll_student(student).accept(true)

        muted_submission.add_comment(author: student, comment: "I did a great job!")
        muted_submission.add_comment(author: teacher, comment: "No, you did not", hidden: true)

        unmuted_submission.add_comment(author: student, comment: "I did a great job!")
        unmuted_submission.add_comment(author: teacher, comment: "No, you did not")
      end

      context "when a teacher is viewing" do
        before { assign(:current_user, teacher) }

        it "shows all comments when a teacher is viewing" do
          assign(:assignment, muted_assignment)
          assign(:submission, muted_submission)

          render "submissions/show"
          expect(comment_contents).to match_array ["I did a great job!", "No, you did not"]
        end

        it "shows all comments if the submission is posted" do
          unmuted_submission.update!(posted_at: Time.zone.now)
          unmuted_submission.limit_comments(student)

          assign(:assignment, unmuted_assignment)
          assign(:submission, unmuted_submission)

          render "submissions/show"
          expect(comment_contents).to match_array ["I did a great job!", "No, you did not"]
        end

        it "shows all comments even if the submission is unposted" do
          unmuted_submission.limit_comments(student)

          assign(:assignment, unmuted_assignment)
          assign(:submission, unmuted_submission)

          render "submissions/show"
          expect(comment_contents).to match_array ["I did a great job!", "No, you did not"]
        end
      end

      context "when a student is viewing" do
        before { assign(:current_user, student) }

        it "shows all comments if the submission is posted" do
          unmuted_submission.update!(posted_at: Time.zone.now)
          unmuted_submission.limit_comments(student)

          assign(:assignment, unmuted_assignment)
          assign(:submission, unmuted_submission)

          render "submissions/show"
          expect(comment_contents).to match_array ["I did a great job!", "No, you did not"]
        end

        it "shows only non-hidden comments if the submission is unposted" do
          muted_submission.limit_comments(student)

          assign(:assignment, muted_assignment)
          assign(:submission, muted_submission)

          render "submissions/show"
          expect(comment_contents).to match_array ["I did a great job!"]
        end

        context "for a moderated assignment" do
          let(:moderated_assignment) do
            course.assignments.create!(
              name: "moderated",
              moderated_grading: true,
              final_grader: teacher,
              grader_count: 2
            )
          end
          let(:moderated_submission) { moderated_assignment.submission_for_student(student) }
          let(:first_ta) { course_with_user("TaEnrollment", course: course, active_all: true).user }
          let(:second_ta) do
            course_with_user("TaEnrollment", course: course, active_all: true).user
          end

          before do
            moderated_submission.add_comment(author: student, comment: "I did a great job!")
            moderated_submission.add_comment(
              author: teacher,
              comment: "No, you did not.",
              provisional: true
            )
            moderated_submission.add_comment(
              author: first_ta,
              comment: "Maybe they did?",
              provisional: true
            )
            moderated_submission.add_comment(
              author: second_ta,
              comment: "Who cares?",
              provisional: true
            )
            moderated_assignment.grade_student(
              student,
              grade: 1,
              grader: second_ta,
              provisional: true
            )
            assign(:assignment, moderated_assignment)
            assign(:submission, moderated_submission)
          end

          it "shows only the student's comments while muted" do
            render "submissions/show"
            expect(comment_contents).to match_array(["I did a great job!"])
          end

          it "shows the student's, chosen grader's, and final grader's comments when unmuted" do
            ModeratedGrading::ProvisionalGrade.find_by(
              submission: moderated_submission,
              scorer: second_ta
            ).publish!
            moderated_assignment.update!(grades_published_at: Time.zone.now)
            moderated_assignment.unmute!
            moderated_submission.reload

            render "submissions/show"
            expect(comment_contents).to match_array(
              ["I did a great job!", "No, you did not.", "Who cares?"]
            )
          end
        end
      end
    end
  end

  context "when assignment has a rubric" do
    before :once do
      assignment_model(course: @course)
      rubric_association_model association_object: @assignment, purpose: "grading"
      @submission = @assignment.submit_homework(@user)
    end

    context "when current_user is submission user" do
      it "does not add assessing class to rendered rubric_container" do
        view_context(@course, @student)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        render "submissions/show"
        html = Nokogiri::HTML5.fragment(response.body)
        classes = html.css("div.rubric_container").attribute("class").value.split
        expect(classes).not_to include("assessing")
      end

      context "submission_feedback_indicators" do
        before :once do
          @course.root_account.enable_feature! :submission_feedback_indicators
        end

        it "adds an indicator if unread comments are present" do
          view_context(@course, @student)
          @student.mark_rubric_assessments_unread!(@submission)
          assign(:assignment, @assignment)
          assign(:submission, @submission)
          render "submissions/show"
          expect(response.body).to include '<span class="rubric_comment unread_indicator"'
        end

        it "does not show the indicator if unread comments aren't present" do
          view_context(@course, @student)
          @student.mark_rubric_assessments_read!(@submission)
          assign(:assignment, @assignment)
          assign(:submission, @submission)
          render "submissions/show"
          expect(response.body).not_to include '<span class="rubric_comment unread_indicator"'
        end
      end
    end

    context "when current_user is teacher" do
      it "adds assessing class to rubric_container" do
        view_context(@course, @teacher)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        render "submissions/show"
        html = Nokogiri::HTML5.fragment(response.body)
        classes = html.css("div.rubric_container").attribute("class").value.split
        expect(classes).to include("assessing")
      end
    end

    context "when current_user is an observer" do
      before :once do
        course_with_observer(course: @course)
      end

      it "does not add assessing class to the rendered rubric_container" do
        view_context(@course, @observer)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        render "submissions/show"
        html = Nokogiri::HTML5.fragment(response.body)
        classes = html.css("div.rubric_container").attribute("class").value.split
        expect(classes).not_to include("assessing")
      end
    end

    context "when current user is assessing student submission" do
      before :once do
        student_in_course(active_all: true)
        @course.workflow_state = "available"
        @course.save!
        @assessment_request =
          @submission.assessment_requests.create!(
            assessor: @student,
            assessor_asset: @submission,
            user: @submission.user
          )
      end

      it 'shows the "Show Rubric" link after request is complete' do
        @assessment_request.complete!

        view_context(@course, @student)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        assign(:rubric_association, @assignment.rubric_association)

        render "submissions/show"
        html = Nokogiri::HTML5.fragment(response.body)
        rubric_link_text = html.css(".assess_submission_link")[0].text
        expect(rubric_link_text).to match(/Show Rubric/)
      end

      it "shows a message when the request is complete" do
        @assessment_request.complete!

        view_context(@course, @student)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        assign(:assessment_request, @assessment_request)

        render "submissions/show"
        html = Nokogiri::HTML5.fragment(response.body)
        completed_message = html.css(".assessment_request_completed_message")
        expect(completed_message.attr("style").value).not_to match(/display:\s*none/)
      end

      it "adds assessing class to rubric_container" do
        view_context(@course, @student)
        assign(:assignment, @assignment)
        assign(:submission, @submission)
        assign(:assessment_request, @assessment_request)
        render "submissions/show"
        html = Nokogiri::HTML5.fragment(response.body)
        classes = html.css("div.rubric_container").attribute("class").value.split
        expect(classes).to include("assessing")
      end
    end
  end

  context "when an assignment is peer-reviewed" do
    let(:assignment) { @course.assignments.create!(peer_reviews: true) }
    let(:student_to_assess) do
      @course.enroll_student(User.create!, enrollment_state: "active").user
    end
    let(:submission) { assignment.submission_for_student(student_to_assess) }

    let(:assessment_request) do
      submission.assessment_requests.create!(
        assessor: @student,
        assessor_asset: assignment.submission_for_student(@student),
        user: submission.user
      )
    end

    before do
      view_context(@course, @student)
      assign(:assignment, assignment)
      assign(:submission, submission)
      assign(:assessment_request, assessment_request)
    end

    it "shows assessment instructions when the assignment does not have a rubric" do
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      message_container = html.at_css(".assessment_request_incomplete_message")
      expect(message_container.text).to include("This peer review is not finished yet.")
      expect(message_container.attr("style")).not_to match(/display:\s*none/)
    end

    it "does not show assessment instructions when the assignment has a rubric" do
      rubric_association =
        rubric_association_model(association_object: assignment, purpose: "grading")
      assessment_request.update!(rubric_association: rubric_association)

      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      message_container = html.at_css(".assessment_request_incomplete_message")
      expect(message_container.attr("style")).to match(/display:\s*none/)
    end
  end

  describe "media comments" do
    let_once(:assignment) { @course.assignments.create! }
    let_once(:student) do
      course_with_user("StudentEnrollment", course: @course, name: "Stu", active_all: true).user
    end
    let_once(:sub) { assignment.submit_homework(student, body: "i did a thing") }
    let_once(:teacher) do
      course_with_user("TeacherEnrollment", course: @course, name: "Tom", active_all: true).user
    end

    before(:once) do
      @comment =
        sub.add_comment(
          author: teacher,
          comment: "good job!",
          media_comment_id: 1,
          media_comment_type: "video"
        )
    end

    before do
      assign(:assignment, assignment)
      assign(:context, @course)
      assign(:current_user, teacher)
      assign(:submission, sub)
    end

    it "passes comment author for the thumbnail" do
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      anchor = html.at_css("div#submission_comment_#{@comment.id} div.comment_media a")
      author = anchor.attributes.fetch("data-author").value
      expect(author).to eq "Tom"
    end

    it "passes comment creation time for the thumbnail" do
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      anchor = html.at_css("div#submission_comment_#{@comment.id} div.comment_media a")
      created_at = anchor.attributes.fetch("data-created_at").value
      expect(created_at).to eq datetime_string(@comment.created_at)
    end

    it "renders the comment text" do
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      comment_list = html.css(".submission-details-comments .comment_list")
      comment_contents = comment_list.css(".comment .comment").map { |comment| comment.text.strip }
      expect(comment_contents.find { |c| c.include?("good job!") }).not_to be nil
    end

    it "comment text includes boilerplate about being a media comment" do
      render "submissions/show"
      html = Nokogiri::HTML5.fragment(response.body)
      comment_list = html.css(".submission-details-comments .comment_list")
      comment_contents = comment_list.css(".comment .comment").map { |comment| comment.text.strip }
      comment = comment_contents.find { |c| c.include?("good job!") }
      expect(comment.include?("This is a media comment")).to be true
    end
  end
end
