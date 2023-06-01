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
#

describe RubricAssociation do
  def rubric_association_params_for_assignment(assign, override = {})
    ActiveSupport::HashWithIndifferentAccess.new({
      hide_score_total: "0",
      purpose: "grading",
      skip_updating_points_possible: false,
      update_if_existing: true,
      use_for_grading: "1",
      association_object: assign
    }.merge(override))
  end

  context "assignment rubrics" do
    before :once do
      # Create a course, 2 students and enroll them
      course_with_teacher(active_course: true, active_user: true)
      @student_1 = student_in_course(active_user: true).user
      @student_2 = student_in_course(active_user: true).user

      # Create the assignment
      @assignment = @course.assignments.create!(
        title: "Test Assignment",
        peer_reviews: true,
        submission_types: "online_text_entry"
      )
    end

    it "re-aligns peer review assessments to use the new rubric when the rubric is changed on the assignment" do
      @assignment.assign_peer_review(@student_1, @student_2)
      @assignment.assign_peer_review(@student_2, @student_1)
      original_rubric = @course.rubrics.create! { |r| r.user = @teacher }
      ra_params = rubric_association_params_for_assignment(@assignment, use_for_grading: "1")
      RubricAssociation.generate(@teacher, original_rubric, @course, ra_params.dup)
      new_rubric = @course.rubrics.create! { |r| r.user = @teacher }
      rubric_association = RubricAssociation.generate(@teacher, new_rubric, @course, ra_params.dup)
      assessment_request = Submission.find_by(user: @student_1, assignment: @assignment).assessment_requests.first
      expect(assessment_request.rubric_association_id).to eq rubric_association.id
    end

    it "disable use_for_grading if hide_points enabled" do
      # Create the rubric
      @rubric = @course.rubrics.create! { |r| r.user = @teacher }

      ra_params = rubric_association_params_for_assignment(@assignment, use_for_grading: "1")
      rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)
      expect(rubric_assoc.use_for_grading).to be true

      ra_params = rubric_association_params_for_assignment(@assignment, hide_points: "1")
      rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)

      expect(rubric_assoc.use_for_grading).to be false
    end

    it "disable hide_score_total if hide_points enabled" do
      # Create the rubric
      @rubric = @course.rubrics.create! { |r| r.user = @teacher }

      ra_params = rubric_association_params_for_assignment(@assignment, hide_score_total: "1")
      rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)
      expect(rubric_assoc.hide_score_total).to be true

      ra_params = rubric_association_params_for_assignment(@assignment, hide_points: "1")
      rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)

      expect(rubric_assoc.hide_score_total).to be false
    end

    context "when a peer-review assignment has been completed AFTER rubric created" do
      before do
        # Create the rubric
        @rubric = @course.rubrics.create! { |r| r.user = @teacher }

        ra_params = rubric_association_params_for_assignment(@assignment)
        @rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)

        # students complete it
        @assignment.submit_homework(@student_1, submission_type: "online_text_entry", body: "Finished first")
        @assignment.submit_homework(@student_2, submission_type: "online_text_entry", body: "Finished second")
      end

      context "and students are assigned to peer review" do
        before do
          # Assign students to peer review
          @assignment.assign_peer_review(@student_1, @student_2)
          @assignment.assign_peer_review(@student_2, @student_1)
        end

        it "has 2 assessment_requests" do
          expect(@rubric_assoc.assessment_requests.count).to eq 2
        end
      end
    end

    context "when a peer-review assignment has been completed BEFORE rubric created" do
      before do
        # students complete it
        @assignment.submit_homework(@student_1, submission_type: "online_text_entry", body: "Finished first")
        @assignment.submit_homework(@student_2, submission_type: "online_text_entry", body: "Finished second")
      end

      context "and students are assigned to peer review" do
        before do
          # Assign students to peer review
          @assignment.assign_peer_review(@student_1, @student_2)
          @assignment.assign_peer_review(@student_2, @student_1)
        end

        context "and a rubric is created" do
          before do
            @rubric = @course.rubrics.create! { |r| r.user = @teacher }
            ra_params = rubric_association_params_for_assignment(@assignment)
            @rubric_assoc = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)
          end

          it "has 2 assessment_requests" do
            expect(@rubric_assoc.assessment_requests.count).to eq 2
          end
        end
      end
    end

    context "#update_alignments" do
      it "does nothing if it is not associated to an assignment" do
        rubric = @course.rubrics.create!
        ra = RubricAssociation.create!(
          rubric:,
          association_object: @course,
          context: @course,
          purpose: "bookmark"
        )
        expect(LearningOutcome).not_to receive(:update_alignments)
        ra.update_alignments
      end

      it "aligns the outcome to the assignment when created and remove when destroyed" do
        assignment = @course.assignments.create!(
          title: "Test Assignment",
          peer_reviews: true,
          submission_types: "online_text_entry"
        )
        outcome_with_rubric
        ra = @rubric.rubric_associations.create!(
          association_object: assignment,
          context: @course,
          purpose: "grading"
        )
        expect(assignment.reload.learning_outcome_alignments.count).to eq 1

        ra.destroy
        expect(assignment.reload.learning_outcome_alignments.count).to eq 0
      end
    end

    it "does not delete assessments when an association is destroyed" do
      assignment = @course.assignments.create!(
        title: "Test Assignment",
        peer_reviews: true,
        submission_types: "online_text_entry"
      )
      outcome_with_rubric
      ra = @rubric.rubric_associations.create!(
        association_object: assignment,
        context: @course,
        purpose: "grading"
      )
      assess = ra.assess({
                           user: @student_1,
                           assessor: @teacher,
                           artifact: assignment.find_or_create_submission(@student_1),
                           assessment: {
                             assessment_type: "grading",
                             criterion_crit1: {
                               points: 5
                             }
                           }
                         })

      expect(assess).not_to be_nil
      ra.destroy
      expect(assess.reload).not_to be_nil
    end

    it "does not delete assessment requests when an association is destroyed" do
      submission_student = student_in_course(active_all: true, course: @course).user
      review_student = student_in_course(active_all: true, course: @course).user
      assignment = @course.assignments.create!
      submission = assignment.find_or_create_submission(submission_student)
      assessor_submission = assignment.find_or_create_submission(review_student)
      outcome_with_rubric
      ra = @rubric.rubric_associations.create!(
        association_object: assignment,
        context: @course,
        purpose: "grading"
      )
      request = AssessmentRequest.create!(user: submission_student,
                                          asset: submission,
                                          assessor_asset: assessor_submission,
                                          assessor: review_student,
                                          rubric_association: ra)
      expect(request).not_to be_nil
      ra.destroy
      expect(request.reload).not_to be_nil
    end

    it "softs delete learning outcome results when an association is replaced" do
      student_in_course(active_all: true)
      outcome_with_rubric
      assessment = rubric_assessment_model(purpose: "grading", rubric: @rubric, user: @student)
      expect(assessment.learning_outcome_results.length).to eq 1

      result = assessment.learning_outcome_results.first
      expect(result).to be_active

      # associate copy
      rubric_association_model(purpose: "grading", rubric: @rubric, association_object: @rubric_association.association_object)
      expect(result.reload).to be_deleted
    end

    it "lets account admins without manage_courses do things" do
      @course.root_account.disable_feature!(:granular_permissions_manage_courses)
      @rubric = @course.rubrics.create! { |r| r.user = @teacher }
      ra_params = rubric_association_params_for_assignment(@assignment)
      ra = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)

      admin =
        account_admin_user_with_role_changes(
          active_all: true,
          role_changes: {
            manage_courses: false
          }
        )

      %i[manage delete].each do |permission|
        expect(ra.grants_right?(admin, permission)).to be_truthy
      end
    end

    it "lets account admins without manage_courses_admin do things (granular permissions)" do
      @course.root_account.enable_feature!(:granular_permissions_manage_courses)
      @rubric = @course.rubrics.create! { |r| r.user = @teacher }
      ra_params = rubric_association_params_for_assignment(@assignment)
      ra = RubricAssociation.generate(@teacher, @rubric, @course, ra_params)

      admin =
        account_admin_user_with_role_changes(
          active_all: true,
          role_changes: {
            manage_courses_admin: false
          }
        )

      %i[manage delete].each do |permission|
        expect(ra.grants_right?(admin, permission)).to be_truthy
      end
    end
  end

  context "when a rubric is associated with an account" do
    it "does not try to link to assessments" do
      site_admin_user
      user_session(@user)
      @account = @user.account
      @rubric = @account.rubrics.build
      rubric_params = ActiveSupport::HashWithIndifferentAccess.new({ "title" => "Some Rubric", "criteria" => { "0" => { "learning_outcome_id" => "", "ratings" => { "0" => { "points" => "5", "id" => "blank", "description" => "Full Marks" }, "1" => { "points" => "0", "id" => "blank_2", "description" => "No Marks" } }, "points" => "5", "long_description" => "", "id" => "", "description" => "Description of criterion" } }, "points_possible" => "5", "free_form_criterion_comments" => "0" })
      rubric_association_params = ActiveSupport::HashWithIndifferentAccess.new({ association_object: @account, hide_score_total: "0", use_for_grading: "0", purpose: "bookmark" })
      # 8864: the below raised a MethodNotFound error by trying to call @account.submissions
      expect { @rubric.update_with_association(@user, rubric_params, @account, rubric_association_params) }.not_to raise_error
    end
  end

  context "when a rubric is associated with a course" do
    it "does not try to link to assessments" do
      course_with_teacher(active_all: true)
      @rubric = @course.rubrics.build
      rubric_params = ActiveSupport::HashWithIndifferentAccess.new({ "title" => "Some Rubric", "criteria" => { "0" => { "learning_outcome_id" => "", "ratings" => { "0" => { "points" => "5", "id" => "blank", "description" => "Full Marks" }, "1" => { "points" => "0", "id" => "blank_2", "description" => "No Marks" } }, "points" => "5", "long_description" => "", "id" => "", "description" => "Description of criterion" } }, "points_possible" => "5", "free_form_criterion_comments" => "0" })
      rubric_association_params = ActiveSupport::HashWithIndifferentAccess.new({ association_object: @course, hide_score_total: "0", use_for_grading: "0", purpose: "bookmark" })
      expect_any_instantiation_of(@course).not_to receive(:submissions)
      @rubric.update_with_association(@user, rubric_params, @course, rubric_association_params)
    end
  end

  describe "#assess" do
    let(:course) { Course.create! }
    let!(:first_teacher) { course_with_teacher(course:, active_all: true).user }
    let!(:second_teacher) { course_with_teacher(course:, active_all: true).user }
    let(:student) { student_in_course(course:, active_all: true).user }
    let(:assignment) { course.assignments.create!(submission_types: "online_text_entry") }
    let(:rubric) do
      course.rubrics.create! do |r|
        r.title = "rubric"
        r.user = first_teacher
        r.data = [{
          id: "stuff",
          description: "stuff",
          long_description: "",
          points: 1.0,
          ratings: [
            { description: "Full Marks", points: 1.0, id: "blank" },
            { description: "No Marks", points: 0.0, id: "blank_2" }
          ]
        }]
      end
    end
    let!(:rubric_association) do
      params = rubric_association_params_for_assignment(assignment)
      RubricAssociation.generate(first_teacher, rubric, course, params)
    end
    let(:submission) { assignment.submit_homework(student) }
    let(:assessment_params) { { assessment_type: "grading", criterion_stuff: { points: 1 } } }

    it "updates the assessor/grader if the second assessor is different than the first" do
      rubric_association.assess(user: student,
                                assessor: first_teacher,
                                artifact: submission,
                                assessment: assessment_params)

      assessment_params[:criterion_stuff][:points] = 0
      assessment = rubric_association.assess(user: student,
                                             assessor: second_teacher,
                                             artifact: submission,
                                             assessment: assessment_params)
      submission.reload

      expect(assessment.assessor).to eq(second_teacher)
      expect(submission.grader).to eq(second_teacher)
    end

    it "propagated hide_points value" do
      rubric_association.update!(hide_points: true)
      assessment = rubric_association.assess(user: student,
                                             assessor: first_teacher,
                                             artifact: submission,
                                             assessment: assessment_params)
      expect(assessment.hide_points).to be true
    end

    it "updates the rating description and id if not present in passed params" do
      assessment = rubric_association.assess(user: student,
                                             assessor: first_teacher,
                                             artifact: submission,
                                             assessment: assessment_params)
      expect(assessment.data[0][:id]).to eq "blank"
      expect(assessment.data[0][:description]).to eq "Full Marks"
    end
  end

  describe "#generate" do
    let(:course) { Course.create! }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:assignment) { course.assignments.create!(anonymous_grading: true) }
    let(:rubric) { Rubric.create!(title: "hi", context: course) }

    describe "AnonymousOrModerationEvent creation for auditable assignments" do
      context "when the assignment has a prior grading rubric" do
        let(:old_rubric) { Rubric.create!(title: "zzz", context: course) }
        let(:last_updated_event) { AnonymousOrModerationEvent.where(event_type: "rubric_updated").last }

        before do
          RubricAssociation.generate(
            teacher,
            old_rubric,
            course,
            association_object: assignment,
            purpose: "grading"
          )
          assignment.reload
        end

        it "does not record a rubric_updated event when no updating_user present" do
          ra = old_rubric.rubric_associations.last
          ra.update!(updating_user: nil)
          expect { ra.update!(skip_updating_points_possible: true) }.not_to change { AnonymousOrModerationEvent.count }
        end

        it "records a rubric_updated event for the assignment" do
          expect do
            RubricAssociation.generate(teacher, rubric, course, association_object: assignment, purpose: "grading")
          end.to change {
            AnonymousOrModerationEvent.where(event_type: "rubric_updated", assignment:).count
          }.by(1)
        end

        it "includes the ID of the removed rubric in the payload" do
          RubricAssociation.generate(teacher, rubric, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.payload["id"].first).to eq old_rubric.id
        end

        it "includes the ID of the added rubric in the payload" do
          RubricAssociation.generate(teacher, rubric, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.payload["id"].second).to eq rubric.id
        end

        it "includes the updating user on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.user_id).to eq teacher.id
        end

        it "includes the associated assignment on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_updated_event.assignment_id).to eq assignment.id
        end
      end

      context "when the assignment has no prior grading rubric" do
        let(:last_created_event) { AnonymousOrModerationEvent.where(event_type: "rubric_created").last }

        it "records a rubric_created event for the assignment" do
          expect do
            rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          end.to change {
            AnonymousOrModerationEvent.where(event_type: "rubric_created", assignment:).count
          }.by(1)
        end

        it "includes the ID of the added rubric in the payload" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_created_event.payload["id"]).to eq rubric.id
        end

        it "includes the updating user on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_created_event.user_id).to eq teacher.id
        end

        it "includes the associated assignment on the event" do
          rubric.update_with_association(teacher, {}, course, association_object: assignment, purpose: "grading")
          expect(last_created_event.assignment_id).to eq assignment.id
        end
      end
    end
  end

  describe "#auditable?" do
    let(:course) { Course.create! }
    let(:teacher) { course.enroll_teacher(User.create!, active_all: true).user }
    let(:rubric) { Rubric.create!(title: "hi", context: course) }

    it "is auditable when assignment is auditable" do
      assignment = course.assignments.create!(name: "anonymous", anonymous_grading: true)
      ra = RubricAssociation.generate(
        teacher,
        rubric,
        course,
        association_object: assignment,
        purpose: "grading"
      )
      expect(ra).to be_auditable
    end

    it "is not auditable when assignment is not auditable" do
      assignment = course.assignments.create!(name: "plain")
      ra = RubricAssociation.generate(
        teacher,
        rubric,
        course,
        association_object: assignment,
        purpose: "grading"
      )
      expect(ra).not_to be_auditable
    end
  end

  describe "create" do
    let(:root_account) { Account.default }

    it "sets the root_account_id using course context" do
      rubric_association_model
      expect(@rubric_association.root_account_id).to eq @course.root_account_id
    end

    it "sets the root_account_id using root account" do
      rubric_association_model({ context: root_account })
      expect(@rubric_association.root_account_id).to eq root_account.id
    end

    it "sets the root_account_id using sub account" do
      sub_account = root_account.sub_accounts.create!
      rubric_association_model({ context: sub_account })
      expect(@rubric_association.root_account_id).to eq sub_account.root_account_id
    end
  end

  describe "workflow_state" do
    before(:once) do
      @course = Course.create!
      @rubric = @course.rubrics.create!
      @association = RubricAssociation.create!(
        rubric: @rubric,
        association_object: @course,
        context: @course,
        purpose: "bookmark"
      )
    end

    it "is set to 'active' by default" do
      expect(@association).to be_active
    end

    it "gets set to 'deleted' when soft-deleted" do
      expect { @association.destroy }.to change {
        @association.workflow_state
      }.from("active").to("deleted")
    end
  end

  describe "#restore" do
    it "sets the workflow_state to 'active'" do
      course = Course.create!
      rubric = course.rubrics.create!
      association = RubricAssociation.create!(
        rubric:,
        association_object: course,
        context: course,
        purpose: "bookmark"
      )
      association.destroy
      expect { association.restore }.to change { association.workflow_state }.from("deleted").to("active")
    end
  end

  describe "restrict_quantitative_data" do
    before do
      course_with_teacher(active_course: true, active_user: true)
      @student = student_in_course(active_user: true).user

      assignment = @course.assignments.create!(
        title: "Test Assignment",
        submission_types: "online_text_entry"
      )

      rubric = @course.rubrics.create!
      @course_rubric_association = RubricAssociation.create!(
        rubric:,
        association_object: @course,
        context: @course,
        purpose: "bookmark"
      )
      @assignment_rubric_association = RubricAssociation.generate(@teacher, rubric, @course, rubric_association_params_for_assignment(assignment))
    end

    describe "is off" do
      it "with course_rubric_association to be false" do
        expect(@course_rubric_association.restrict_quantitative_data?(@teacher)).to be false
        expect(@course_rubric_association.restrict_quantitative_data?(@student)).to be false
        expect(@course_rubric_association.restrict_quantitative_data?).to be false
      end

      it "with assignment_rubric_association to be false" do
        expect(@assignment_rubric_association.restrict_quantitative_data?(@teacher)).to be false
        expect(@assignment_rubric_association.restrict_quantitative_data?(@student)).to be false
        expect(@assignment_rubric_association.restrict_quantitative_data?).to be false
      end
    end

    describe "is on" do
      before do
        @course.root_account.enable_feature!(:restrict_quantitative_data)
        @course.settings = @course.settings.merge(restrict_quantitative_data: true)
        @course.save!
      end

      it "with course_rubric_association to be false" do
        expect(@course_rubric_association.restrict_quantitative_data?(@teacher)).to be false
        expect(@course_rubric_association.restrict_quantitative_data?(@student)).to be false
        expect(@course_rubric_association.restrict_quantitative_data?).to be false
      end

      it "with assignment_rubric_association to be true" do
        expect(@assignment_rubric_association.restrict_quantitative_data?(@teacher)).to be true
        expect(@assignment_rubric_association.restrict_quantitative_data?(@student)).to be true
      end
    end
  end
end
