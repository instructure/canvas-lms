# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

describe "assignments" do
  include_context "in-process server selenium tests"

  context "peer reviews" do
    it "allows deleting a peer review", priority: "2" do
      skip_if_safari(:alert)
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

      hover_and_click(".student_reviews:first .delete_review_link")
      accept_alert
      wait_for_ajaximations

      expect(fj(".student_reviews:first .peer_reviews").text).to match(/None Assigned/)
      keep_trying_until do
        expect(@assignment.reload.submissions.map(&:assessment_requests).flatten.length).to eq 1
      end
    end

    it "renders only 10 students on each peer review page" do
      course_with_teacher_logged_in
      create_users_in_course(@course, 11)

      @assignment = assignment_model({
                                       course: @course,
                                       peer_reviews: true,
                                       automatic_peer_reviews: false,
                                     })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"

      list_items = driver.find_elements(class: "student_reviews")
      expect(list_items.count).to eq(10)
    end

    it "renders the remaining students on another page if total number of students exceeds the limit of 10 students per page" do
      course_with_teacher_logged_in
      create_users_in_course(@course, 11)

      @assignment = assignment_model({
                                       course: @course,
                                       peer_reviews: true,
                                       automatic_peer_reviews: false,
                                     })

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews?page=2"

      list_items = driver.find_elements(class: "student_reviews")
      expect(list_items.count).to eq(1)
    end

    describe "validations" do
      it "renders validation seleect a student" do
        course_with_teacher_logged_in
        create_users_in_course(@course, 11)
        @assignment = assignment_model({
                                         course: @course,
                                         peer_reviews: true,
                                         automatic_peer_reviews: false,
                                       })

        get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews?page=2"

        f(".assign_peer_review_link").click
        find_button("Add").click
        expect(f("#reviewee_errors")).to be_displayed
        expect(f("#reviewee_id").attribute("class")).to include("error-outline")
        input = driver.find_element(:css, "select[name='reviewee_id']")
        expect(input.attribute("aria-label")).to eq("Please select a student")
      end
    end

    it "displays the intra-group review toggle for group assignments" do
      course_with_teacher_logged_in
      student = student_in_course.user

      gc = GroupCategory.create(name: "Inconceivable", context: @course)
      @course.groups.create!(group_category: gc)
      @assignment = assignment_model({
                                       course: @course,
                                       peer_reviews: true,
                                       automatic_peer_reviews: true,
                                       group_category_id: gc.id
                                     })

      submission = @assignment.submit_homework(student)
      submission.submission_type = "online_text_entry"
      submission.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"

      expect(f("#intra_group_peer_reviews")).to be_displayed
    end

    it "student list appears when the assignment is assigned to a subset of students and the assignment is unpublished" do
      course_with_teacher_logged_in
      @student1 = student_in_course.user
      @student2 = student_in_course.user

      @assignment = assignment_model({
                                       course: @course,
                                       peer_reviews: true,
                                       workflow_state: "unpublished"
                                     })

      @assignment.only_visible_to_overrides = true
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      expect(f(".no_students_message")).to_not be_displayed
    end

    context "rubric assessments" do
      before :once do
        course_factory(active_course: true)
        user_factory(active_all: true)
        @student1 = @user
        student_in_course(user: @student1, active_all: true)
        @student2 = student_in_course(active_all: true).user

        @assignment = assignment_model({ course: @course, peer_reviews: true, automatic_peer_reviews: false })
      end

      before do
        user_session(@student1)
      end

      it "does not let a student submit a rubric review if the request is completed" do
        rubric_association_model(purpose: "grading", association_object: @assignment)
        req = @assignment.assign_peer_review(@student1, @student2)
        req.complete!

        get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student2.id}"

        f(".assess_submission_link").click
        wait_for_animations
        expect(f("#rubric_holder")).to_not contain_css(".save_rubric_button")
      end

      it "lets a student submit a rubric review even if already completed if a rubric is added afterwards" do
        req = @assignment.assign_peer_review(@student1, @student2)
        req.complete!
        rubric_association_model(purpose: "grading", association_object: @assignment)
        expect(req.reload.rubric_association).to eq @rubric_association # set it after the fact
        expect(req).to be_assigned

        get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student2.id}"

        f(".assess_submission_link").click
        wait_for_animations
        f(".rating-description").click
        f("#rubric_holder .save_rubric_button").click
        wait_for_ajaximations

        expect(req.reload).to be_completed
        assessment = @assignment.submissions.where(user_id: @student).first.rubric_assessments.first
        expect(assessment.assessment_type).to eq "peer_review"
      end
    end

    it "allows an account admin who is also a student to submit a peer review", priority: "2" do
      course_factory(active_course: true)
      admin_logged_in(account: @course.root_account)
      student_in_course(user: @admin)
      @student = student_in_course.user

      @assignment = assignment_model({
                                       course: @course,
                                       peer_reviews: true,
                                       automatic_peer_reviews: false,
                                     })
      rubric_association_model(purpose: "grading", association_object: @assignment)
      @assignment.assign_peer_review(@admin, @student)

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@student.id}"

      f(".assess_submission_link").click
      wait_for_animations
      f(".rating-description").click
      f(".save_rubric_button").click
      wait_for_ajaximations

      assessment = @assignment.submissions.where(user_id: @student).first.rubric_assessments.first
      expect(assessment.assessment_type).to eq "peer_review"
    end
  end

  describe "auto assign" do
    before do
      course_with_teacher_logged_in
      @assignment = assignment_model({
                                       course: @course,
                                       peer_reviews: true,
                                       automatic_peer_reviews: false,
                                     })
    end

    it "displays auto assign section if the assignment is assigned to at least one user" do
      student_in_course(active_all: true)
      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      expect(f("#automatically_assign_reviews")).to be_displayed
    end

    it "displays auto assign input if there are submissions" do
      student1 = student_in_course(active_all: true).user
      student_in_course(active_all: true).user
      submission = @assignment.submit_homework(student1)
      submission.submission_type = "online_text_entry"
      submission.save!

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      expect(f("#reviews_per_user_container")).to be_displayed
    end

    it "displays redirect to edit assignment button if there are no submissions" do
      student_in_course(active_all: true).user
      student_in_course(active_all: true).user

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      expect(f("#redirect_to_edit_button")).to be_displayed
    end

    it "automatically assigns peer reviews if both students have submissions" do
      student1 = student_in_course(active_all: true).user
      student2 = student_in_course(active_all: true).user
      submission1 = @assignment.submit_homework(student1)
      submission2 = @assignment.submit_homework(student2)
      [submission1, submission2].each do |s|
        s.submission_type = "online_text_entry"
        s.save!
      end

      get "/courses/#{@course.id}/assignments/#{@assignment.id}/peer_reviews"
      f("#reviews_per_user_input").send_keys("1")
      f("#submit_assign_peer_reviews").click

      wait_for_ajaximations
      expect(submission1.assigned_assessments.size).to eq(1)
      expect(submission2.assigned_assessments.size).to eq(1)
    end
  end

  describe "with anonymous peer reviews" do
    let!(:review_course) { course_factory(active_all: true) }
    let!(:teacher) { review_course.teachers.first }
    let!(:reviewed) { student_in_course(active_all: true).user }
    let!(:reviewer) { student_in_course(active_all: true).user }
    let!(:assignment) do
      @assignment = assignment_model({
                                       course: review_course,
                                       peer_reviews: true,
                                       anonymous_peer_reviews: true
                                     })
      @assignment.unmute!
      @assignment
    end
    let!(:submission) do
      submission_model({
                         assignment:,
                         body: "submission body",
                         course: review_course,
                         grade: "5",
                         score: "5",
                         submission_type: "online_text_entry",
                         user: reviewed
                       })
    end
    let!(:submissionReviewer) do
      submission_model({
                         assignment:,
                         body: "submission body reviewer",
                         course: review_course,
                         grade: "5",
                         score: "5",
                         submission_type: "online_text_entry",
                         user: reviewer
                       })
    end
    let!(:comment) do
      submission_comment_model({
                                 author: reviewer,
                                 submission:
                               })
    end
    let!(:rubric) { rubric_model }
    let!(:association) do
      rubric.associate_with(assignment, review_course, {
                              purpose: "grading", use_for_grading: true
                            })
    end
    let!(:assessment) do
      association.assess({
                           user: reviewed,
                           assessor: reviewer,
                           artifact: submission,
                           assessment: {
                             assessment_type: "peer_review",
                             criterion_crit1: {
                               points: 5,
                               comments: "Hey, it's a comment."
                             }
                           }
                         })
    end
    let!(:anonymous_submission_page) { "/courses/#{review_course.id}/assignments/#{assignment.id}/anonymous_submissions/#{submission.anonymous_id}" }

    before { assignment.assign_peer_review(reviewer, reviewed) }

    context "when reviewed is logged in" do
      before { user_logged_in(user: reviewed) }

      it "blocks reviewer name on assignments page", priority: "1" do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}"
        expect(f("#comment-#{comment.id} .signature")).to include_text("Anonymous User")
      end

      it "hides comment reviewer name on submission page", priority: "1" do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        expect(f("#submission_comment_#{comment.id} .author_name")).to include_text("Anonymous User")
      end

      it "hides comment reviewer name on rubric popup", priority: "1" do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        f(".assess_submission_link").click
        wait_for_animations
        expect(f("#rubric_assessment_option_#{assessment.id}")).to include_text("Anonymous User")
      end
    end

    context "when reviewer is logged in" do
      before { user_logged_in(user: reviewer) }

      it "shows comment reviewer name on submission page", priority: "1" do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/anonymous_submissions/#{submission.anonymous_id}"
        expect(f("#submission_comment_#{comment.id} .author_name")).to include_text(comment.author_name)
      end

      it "allows reviewer to access the anonymous submission page" do
        get anonymous_submission_page
        expect(driver.current_url).to include(anonymous_submission_page)
        expect(f("h1.submission_header")).to include_text("Peer Review")
      end
    end

    context "when teacher is logged in" do
      before { user_logged_in(user: teacher) }

      it "shows comment reviewer name on submission page", priority: "1" do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        expect(f("#submission_comment_#{comment.id} .author_name")).to include_text(comment.author_name)
      end

      it "shows comment reviewer name on rubric popup", priority: "1" do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/submissions/#{reviewed.id}"
        f(".assess_submission_link").click
        wait_for_animations
        expect(f("#rubric_assessment_option_#{assessment.id}")).to include_text(assessment.assessor_name)
      end

      it "allows teacher to access the anonymous submission page" do
        get anonymous_submission_page
        expect(driver.current_url).to include(anonymous_submission_page)
        expect(f("h1.submission_header")).to include_text("Submission Details")
      end
    end

    context "when peer review and plagiarism are enabled" do
      before do
        user_logged_in(user: reviewer)
        # assignment settings
        assignment.vericite_enabled = true
        turnitin_settings = {}
        turnitin_settings[:originality_report_visibility] = "immediate"
        turnitin_settings[:exclude_quoted] = "1"
        turnitin_settings[:created] = true
        turnitin_settings[:s_view_report] = "1"
        turnitin_settings[:s_paper_check] = "1"
        turnitin_settings[:internet_check] = "1"
        turnitin_settings[:current] = true
        turnitin_settings[:vericite] = true
        assignment.turnitin_settings = turnitin_settings
        # submission settings
        turnitin_data = {}
        turnitin_data[:provider] = :vericite
        turnitin_data[:last_processed_attempt] = 1
        submission_data = {}
        submission_data[:status] = "scored"
        submission_data[:object_id] = "canvas/1/25/5/ee0486b43afa304201c1d8dd44ec2da3d76dd86c"
        submission_data[:submit_time] = Time.now.to_i
        submission_data[:similarity_score_check_time] = 1_481_569_668
        submission_data[:similarity_score_time] = Time.now.to_i
        submission_data[:similarity_score] = Time.now.to_i
        submission_data[:similarity_score] = 100
        submission_data[:state] = "none"
        turnitin_data["submission_" + submission.id.to_s] = submission_data
        submission.turnitin_data = turnitin_data
        submission.turnitin_data_changed!
        submission.save!
      end

      it "shows the plagiarism report link for reviewer", priority: "1" do
        get "/courses/#{review_course.id}/assignments/#{assignment.id}/anonymous_submissions/#{submission.anonymous_id}"
        expect(f(".turnitin_similarity_score")).to be_displayed
      end
    end
  end
end
