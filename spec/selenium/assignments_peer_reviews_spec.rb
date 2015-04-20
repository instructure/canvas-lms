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

  describe 'with anonymous peer reviews' do
    let!(:review_course) { course(active_all: true) }
    let!(:teacher) { review_course.teachers.first }
    let!(:reviewed) { student_in_course(active_all: true).user }
    let!(:reviewer) { student_in_course(active_all: true).user }
    let!(:assignment) {
      assignment_model({
        course: review_course,
        peer_reviews: true,
        anonymous_peer_reviews: true
      })
    }
    let!(:submission) {
      submission_model({
        assignment: assignment,
        body: 'submission body',
        course: review_course,
        grade: "5",
        score: "5",
        submission_type: 'online_text_entry',
        user: reviewed
      })
    }
    let!(:comment) {
      submission_comment_model({
        author: reviewer,
        recipient: reviewed
      })
    }
    let!(:rubric) { rubric_model }
    let!(:association) {
      rubric.associate_with(assignment, review_course, {
        :purpose => 'grading', :use_for_grading => true
      })
    }
    let!(:assessment) {
      association.assess({
        :user => reviewed,
        :assessor => reviewer,
        :artifact => submission,
        :assessment => {
          :assessment_type => 'peer_review',
          :criterion_crit1 => {
            :points => 5,
            :comments => "Hey, it's a comment."
          }
        }
      })
    }
    before(:each) { assignment.assign_peer_review(reviewer, reviewed) }

    context 'when reviewed is logged in' do
      before(:each) { user_logged_in(user: reviewed) }

      it 'should block reviewer name on assignments page' do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}"
        expect(f("#comment-#{comment.id} .signature")).to include_text(t("Anonymous User"))
      end

      it 'should hide comment reviewer name on submission page' do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        expect(f("#submission_comment_#{comment.id} .author_name")).to include_text(t("Anonymous User"))
      end

      it 'should hide comment reviewer name on rubric popup' do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        f('.assess_submission_link').click
        wait_for_animations
        expect(f("#rubric_assessment_option_#{assessment.id}")).to include_text(t("Anonymous User"))
      end
    end

    context 'when reviewer is logged in' do
      before(:each) { user_logged_in(user: reviewer) }

      it 'should show comment reviewer name on submission page' do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        expect(f("#submission_comment_#{comment.id} .author_name")).to include_text(comment.author_name)
      end

      it 'should show comment reviewer name on rubric popup' do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        f('.assess_submission_link').click
        wait_for_animations
        expect(f("#rubric_assessment_option_#{assessment.id}")).to include_text(reviewer.email)
      end
    end

    context 'when teacher is logged in' do
      before(:each) { user_logged_in(user: teacher) }

      it 'should show comment reviewer name on submission page' do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        expect(f("#submission_comment_#{comment.id} .author_name")).to include_text(comment.author_name)
      end

      it 'should show comment reviewer name on rubric popup' do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        f('.assess_submission_link').click
        wait_for_animations
        expect(f("#rubric_assessment_option_#{assessment.id}")).to include_text(assessment.assessor_name)
      end
    end
  end
end
