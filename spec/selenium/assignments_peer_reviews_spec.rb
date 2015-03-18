require File.expand_path(File.dirname(__FILE__) + '/common')

describe "assignments" do
  include_examples "in-process server selenium tests"

  context "peer reviews" do

    it "allows deleting a peer review" do
      course_with_teacher_logged_in
      @student1 = student_in_course.user
      @student2 = student_in_course.user

      @assignment = assignment_model({
        course: @course,
        peer_reviews: true,
        automatic_peer_reviews: false,
      })

      @assignment.assign_peer_review(@student1, @student2)
      @assignment.assign_peer_review(@student2, @student1)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"

      hover_and_click('.student_reviews:first .delete_review_link')
      accept_alert
      wait_for_ajaximations

      expect(fj('.student_reviews:first .peer_reviews').text()).to match /None Assigned/
      expect(@assignment.submissions.map(&:assessment_requests).flatten.length).to eq 1
    end

    it "allows an account admin who is also a student to submit a peer review" do
      course(active_course: true)
      admin_logged_in(account: @course.root_account)
      student_in_course(user: @admin)
      @student = student_in_course.user

      @assignment = assignment_model({
        course: @course,
        peer_reviews: true,
        automatic_peer_reviews: false,
      })
      rubric_association_model(purpose: 'grading', association_object: @assignment)
      @assignment.assign_peer_review(@admin, @student)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"

      f('.assess_submission_link').click
      wait_for_animations
      f('.rubric_table .criterion .rating').click
      f('.save_rubric_button').click
      wait_for_ajaximations

      assessment = @assignment.submissions.where(user_id: @student).first.rubric_assessments.first
      expect(assessment.assessment_type).to eq 'peer_review'
    end
  end
end
