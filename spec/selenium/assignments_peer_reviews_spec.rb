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
  end
end
