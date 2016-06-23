require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../views_helper')

describe "courses/_to_do_list.html.erb" do
  include AssignmentsHelper

  context "as a student" do
    describe "assignments due" do
      it "shows assignment data" do
        course_with_student(active_all: true)
        @user.course_nicknames[@course.id] = "My Awesome Course"
        @user.save!
        due_date = 2.days.from_now
        assignment_model(course: @course,
                         due_at: due_date,
                         submission_types: "online_text_entry",
                         points_possible: 15,
                         title: "SubmitMe")
        view_context
        # title, course nickname, points, due date
        render partial: "courses/to_do_list", locals: {contexts: nil}
        expect(response).to include "Turn in SubmitMe"
        expect(response).to include "15 points"
        expect(response).to include "My Awesome Course"
        expect(response).to include due_at(@assignment, @user)
      end
    end
    describe "submissions to review" do
      it "shows peer reviews" do
        course(active_all: true)
        due_date = 2.days.from_now
        assignment_model(course: @course,
                         due_at: due_date,
                         submission_types: "online_text_entry",
                         points_possible: 15,
                         title: "ReviewMe",
                         peer_reviews: true)
        @submission = submission_model(assignment: @assignment, body: "my submission")
        @submitter = @user
        @assessor_submission = submission_model(assignment: @assignment, user: @user, body: "my other submission")
        @assessor = @user
        @assessor.course_nicknames[@course.id] = "My Awesome Course"
        @assessor.save!
        @assessment_request = AssessmentRequest.create!(assessor: @assessor, asset: @submission, user: @submitter, assessor_asset: @assessor_submission)
        @assessment_request.workflow_state = "assigned"
        @assessment_request.save!
        view_context
        render partial: "courses/to_do_list", locals: {contexts: nil}
        expect(response).to include "Peer Review for ReviewMe"
      end
    end
  end

  context "as a teacher" do
    describe "assignments to grade" do
      it "shows assignment data" do
        course(active_all: true)
        due_date = 2.days.from_now
        assignment_model(course: @course,
                         due_at: due_date,
                         submission_types: "online_text_entry",
                         points_possible: 15,
                         title: "GradeMe")

        2.times do
          @course.enroll_student(user).accept!
          @assignment.submit_homework(@user, {:submission_type => 'online_text_entry', :body => 'blah'})
        end

        @user = @teacher
        @user.course_nicknames[@course.id] = "My Awesome Course"
        @user.save!
        view_context
        # title, course nickname, points, due date, number of submissions to grade
        render partial: "courses/to_do_list", locals: {contexts: nil}
        expect(response).to include "Grade GradeMe"
        expect(response).to include "15 points"
        expect(response).to include "My Awesome Course"
        expect(response).to include due_at(@assignment, @user)
        expect(response).to include "2"
        expect(response).to include "2 submissions need grading"
      end

      it "shows 999+ when there are more than 999 to grade" do
        course_with_student(active_all: true)
        due_date = 2.days.from_now
        assignment_model(course: @course,
                         due_at: due_date,
                         submission_types: "online_text_entry",
                         points_possible: 15,
                         title: "GradeMe",
                         needs_grading_count: 1000)
        Assignments::NeedsGradingCountQuery.any_instance.stubs(:count).returns(1000)
        @user = @teacher
        @user.course_nicknames[@course.id] = "My Awesome Course"
        @user.save!
        view_context
        # title, course nickname, points, due date, number of submissions to grade
        render partial: "courses/to_do_list", locals: {contexts: nil}
        expect(response).to include "Grade GradeMe"
        expect(response).to include "15 points"
        expect(response).to include "My Awesome Course"
        expect(response).to include due_at(@assignment, @user)
        expect(response).to include "999+"
        expect(response).to include "More than 999 submissions need grading"
      end
    end

    describe "assignments to moderate" do
      it "shows assignment data" do
        course_with_student(active_all: true)
        due_date = 2.days.from_now
        assignment_model(course: @course,
                         due_at: due_date,
                         submission_types: "online_text_entry",
                         points_possible: 15,
                         title: "ModerateMe",
                         moderated_grading: true,
                         needs_grading_count: 1)
        @submission = submission_model(assignment: @assignment, body: "my submission")
        @submission.find_or_create_provisional_grade!(@teacher, grade: 5)
        @user = @teacher
        @user.course_nicknames[@course.id] = "My Awesome Course"
        @user.save!
        view_context
        render partial: "courses/to_do_list", locals: {contexts: nil}
        expect(response).to include "Moderate ModerateMe"
      end
    end
  end
end
