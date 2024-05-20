# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe LearningOutcomeResult do
  before :once do
    @account = Account.default
  end

  let_once(:course) do
    Course.create!
  end

  let_once(:student) do
    course.enroll_student(User.create!, active_all: true).user
  end

  let_once :quiz do
    quiz_model(assignment: course.assignments.create!)
  end

  let_once :learning_outcome_result do
    create_and_associate_lor(quiz)
  end

  def create_and_associate_lor(association_object, associated_asset = nil)
    outcome = course.created_learning_outcomes.create!(title: "outcome")

    LearningOutcomeResult.new(
      alignment: ContentTag.create!({
                                      title: "content",
                                      context: course,
                                      learning_outcome: outcome
                                    }),
      user: student
    ).tap do |lor|
      lor.association_object = association_object
      lor.context = course
      lor.associated_asset = associated_asset || association_object
      lor.save!
    end
  end

  it_behaves_like "soft deletion" do
    subject { LearningOutcomeResult.all }

    let(:first) { learning_outcome_result }
    let(:second) { create_and_associate_lor(course.assignments.create!) }
  end

  describe "#submitted_or_assessed_at" do
    let_once(:submitted_at) { 1.month.ago }
    let_once(:assessed_at) { 2.weeks.ago }

    it "returns #submitted_at when present" do
      learning_outcome_result.update(submitted_at:)
      expect(learning_outcome_result.submitted_or_assessed_at).to eq(submitted_at)
    end

    it "returns #assessed_at when #submitted_at is not present" do
      learning_outcome_result.assign_attributes({
                                                  assessed_at:,
                                                  submitted_at: nil
                                                })
      expect(learning_outcome_result.submitted_or_assessed_at).to eq(assessed_at)
    end
  end

  describe "exclude_muted_associations scope" do
    shared_examples_for "muting assignment" do
      let(:outcome_result_scope) do
        LearningOutcomeResult.where(
          association_type: outcome_result_association_object.class,
          association_id: outcome_result_association_object.id
        )
      end

      context "assignment with posted submissions" do
        it "includes assignment result" do
          assignment.submission_for_student(student).update!(posted_at: Time.zone.now)
          expect(outcome_result_scope.exclude_muted_associations.count).to eq 1
        end
      end

      context "assignment with unposted submissions with default posting policy" do
        it "includes assignment result" do
          # By default, an automatic post policy (post_manually: false) is associated to
          # an assignment.  Now that post policy is included in exclude_muted_associations
          # the outcome result will appear in LMGB/SLMGB.  It will not appear for manual
          # post policy assignment until the submission is posted.  See "manual posting
          # policy" test cases below.
          expect(outcome_result_scope.exclude_muted_associations.count).to eq 1
        end
      end

      context "not graded assignment with unposted submissions with default posting policy" do
        it "includes assignment result" do
          assignment.update!(grading_type: "not_graded")
          expect(outcome_result_scope.exclude_muted_associations.count).to eq 1
        end
      end

      context "graded assignment with unposted submissions with manual posting policy" do
        it "excludes assignment results" do
          assignment.post_policy.update!(post_manually: true)
          expect(outcome_result_scope.exclude_muted_associations.count).to eq 0
        end
      end

      context "not graded assignment with unposted submissions with manual posting policy" do
        it "includes assignment results" do
          assignment.post_policy.update!(post_manually: true)
          assignment.update!(grading_type: "not_graded")
          expect(outcome_result_scope.exclude_muted_associations.count).to eq 1
        end
      end
    end

    context "with quiz assignment" do
      let_once(:assignment) { quiz.assignment }
      let_once(:outcome_result_association_object) { quiz }

      include_examples "muting assignment"
    end

    context "with assignment result" do
      let_once(:assignment) { course.assignments.create! }
      let_once(:outcome_result_association_object) { assignment }

      before(:once) do
        create_and_associate_lor(assignment)
      end

      include_examples "muting assignment"
    end

    context "with rubric association result" do
      let_once(:assignment) { course.assignments.create! }
      let_once(:rubric_association) do
        rubric_assessment_model(user: student, context: course, association_object: assignment, purpose: "grading")
        @rubric_association
      end
      let_once(:outcome_result_association_object) { rubric_association }

      before(:once) do
        create_and_associate_lor(rubric_association, assignment)
      end

      include_examples "muting assignment"
    end
  end

  describe "with_active_link scope" do
    it "doesn't return deleted outcomes" do
      expect(LearningOutcomeResult.with_active_link.count).to eq(1), "precondition"
      learning_outcome_result.alignment.workflow_state = "deleted"
      learning_outcome_result.alignment.save!
      expect(LearningOutcomeResult.with_active_link.count).to eq 0
    end
  end

  describe "#calculate percent!" do
    it "properly calculates percent" do
      learning_outcome_result.update(score: 6)
      learning_outcome_result.update(possible: 10)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 0.60
    end

    it "returns accurate results" do
      points_possible = 5.5
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible:, mastery_points: 3.5
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.6)
      learning_outcome_result.update(score: 6)
      learning_outcome_result.update(possible: 10)
      learning_outcome_result.calculate_percent!
      mastery_score = (learning_outcome_result.percent * points_possible).round(2)
      expect(mastery_score).to eq 3.5
    end

    it "properly scales score to parent outcome's mastery level" do
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible: 5.0, mastery_points: 3.0
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
      learning_outcome_result.update(score: 6)
      learning_outcome_result.update(possible: 10)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 0.5143
    end

    it "properly scales score to parent outcome's mastery level with extra credit" do
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible: 5.0, mastery_points: 3.0
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 1.0)
      learning_outcome_result.update(score: 5)
      learning_outcome_result.update(possible: 0.5)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 6.0
    end

    it "properly scales score to parent outcome's mastery level with extra credit and points possible is 0" do
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible: 0.0, mastery_points: 3.0
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 1.0)
      learning_outcome_result.update(score: 5)
      learning_outcome_result.update(possible: 0.5)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 10.0
    end

    it "does not fail if parent outcome has integers instead of floats" do
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible: 5, mastery_points: 3
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
      learning_outcome_result.update(score: 6)
      learning_outcome_result.update(possible: 10)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 0.5143
    end

    it "does not use a scale if outcome has 0 mastery points" do
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible: 5, mastery_points: 0
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
      learning_outcome_result.update(score: 6)
      learning_outcome_result.update(possible: 10)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 0.60
    end

    it "does not use a scale if outcome has 0 points possible" do
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible: 0, mastery_points: 3
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
      learning_outcome_result.update(score: 6)
      learning_outcome_result.update(possible: 10)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 0.60
    end

    it "does not use a scale if outcome has nil points possible" do
      allow(learning_outcome_result.learning_outcome).to receive_messages({
                                                                            points_possible: nil, mastery_points: 3
                                                                          })
      allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
      learning_outcome_result.update(score: 6)
      learning_outcome_result.update(possible: 10)
      learning_outcome_result.calculate_percent!

      expect(learning_outcome_result.percent).to eq 0.60
    end

    describe "with account_level_mastery_scales FF enabled" do
      before do
        course.root_account.enable_feature!(:account_level_mastery_scales)
        @proficiency = outcome_proficiency_model(course)
      end

      it "properly calculates percent based on result.possible, if it exists" do
        learning_outcome_result.update(score: 6, possible: 12)
        learning_outcome_result.calculate_percent!
        expect(learning_outcome_result.percent).to eq 0.50
      end

      it "properly calculates percent based on resolved_outcome_proficiency if there is no result.possible value" do
        learning_outcome_result.update(score: 6, possible: nil)
        learning_outcome_result.calculate_percent!
        expect(learning_outcome_result.percent).to eq 6.to_f / @proficiency.points_possible.to_f
      end

      it "properly scales score to outcome_proficiency mastery level" do
        allow(course.resolved_outcome_proficiency).to receive_messages({
                                                                         points_possible: 5.0, mastery_points: 3.0
                                                                       })
        allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
        learning_outcome_result.update(score: 6, possible: 10)
        learning_outcome_result.calculate_percent!
        expect(learning_outcome_result.percent).to eq 0.5143
      end

      it "properly scales score to outcome_proficiency.mastery_points with extra credit and when proficiency.points_possible is 0" do
        allow(course.resolved_outcome_proficiency).to receive_messages({
                                                                         mastery_points: 3.0, points_possible: 0.0
                                                                       })

        allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 1.0)
        learning_outcome_result.update(score: 5, possible: 0.5)
        learning_outcome_result.calculate_percent!

        expect(learning_outcome_result.percent).to eq 10.0
      end

      it "does not use a scale if the outcome proficiency has 0 points possible" do
        allow(course.resolved_outcome_proficiency).to receive_messages({
                                                                         mastery_points: 3.0, points_possible: 0.0
                                                                       })
        allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
        learning_outcome_result.update(score: 6, possible: 10)
        learning_outcome_result.calculate_percent!
        expect(learning_outcome_result.percent).to eq 0.60
      end

      it "does not use a scale if the outcome proficiency has 0 mastery points" do
        allow(course.resolved_outcome_proficiency).to receive_messages({
                                                                         points_possible: 5, mastery_points: 0
                                                                       })
        allow(learning_outcome_result.alignment).to receive_messages(mastery_score: 0.7)
        learning_outcome_result.update(score: 6, possible: 10)
        learning_outcome_result.calculate_percent!
        expect(learning_outcome_result.percent).to eq 0.60
      end
    end

    describe "with account_level_mastery_scales FF disabled" do
      before do
        course.root_account.disable_feature!(:account_level_mastery_scales)
        outcome_proficiency_model(course)
      end

      it "properly calculates percent based on result.possible, if it exists" do
        learning_outcome_result.update(score: 6, possible: 12)
        learning_outcome_result.calculate_percent!
        expect(learning_outcome_result.percent).to eq 0.50
      end

      it "properly calculates percent based on outcome.mastery_points even if an outcome proficiency object exists" do
        learning_outcome_result.update(score: 1, possible: nil)
        learning_outcome_result.calculate_percent!
        expect(learning_outcome_result.percent).to eq(1.to_f / learning_outcome_result.learning_outcome.mastery_points.to_f)
      end
    end
  end

  describe "#assignment" do
    it "returns the Assignment if association object is Assignment" do
      assignment = assignment_model
      lor = create_and_associate_lor(assignment)

      expect(lor.assignment).to eq(assignment)
    end

    it "returns the Assignment from the artifact if one doesnt explicitly exist" do
      lor = create_and_associate_lor(nil)
      lor.artifact = rubric_assessment_model(user: student, context: course)
      expect(lor.assignment).to eq(lor.artifact.submission.assignment)
    end

    it "returns nil if no explicit assignment or artifact exists" do
      lor = create_and_associate_lor(nil)

      expect(lor.assignment).to be_nil
    end
  end

  describe "before create" do
    describe "check_for_existing_result" do
      before :once do
        @assignment = assignment_model
        @outcome = course.created_learning_outcomes.create!(title: "outcome")
        @lor = LearningOutcomeResult.create(
          alignment: ContentTag.create!({
                                          title: "content",
                                          context: course,
                                          learning_outcome: @outcome,
                                          content_id: @assignment.id
                                        }),
          user: student,
          score: 2,
          possible: 9,
          learning_outcome_id: @outcome.id
        )
      end

      it "deletes result if there is a previous one for the same user, learning outcome, and alignment" do
        same_lor = @lor.clone
        same_lor.save!
        expect(LearningOutcomeResult.find(@lor.id).workflow_state).to eq("active")
        expect(LearningOutcomeResult.find(same_lor.id).workflow_state).to eq("deleted")
      end

      it "updates score and possible if there is a previous one for the same user, learning outcome, and alignment" do
        same_lor = @lor.clone
        same_lor.score = 3
        same_lor.possible = 10
        same_lor.save!
        @lor.reload
        expect(@lor.score).to eq(3)
        expect(@lor.possible).to eq(10)
      end

      it "creates a LearningOutcomeResult for the same user and learning outcome if there is none for the alignment" do
        assignment_2 = assignment_model
        new_lor = LearningOutcomeResult.create(
          alignment: ContentTag.create!({
                                          title: "content",
                                          context: course,
                                          learning_outcome: @outcome,
                                          content_id: assignment_2.id
                                        }),
          user: student,
          score: 2,
          learning_outcome_id: @outcome.id
        )
        expect(LearningOutcomeResult.find(@lor.id).workflow_state).to eq("active")
        expect(LearningOutcomeResult.find(new_lor.id).workflow_state).to eq("active")
      end

      describe "for QuestionBanks with questions used in multiple quizzes" do
        before :once do
          assessment_question_bank_with_questions
          @outcome.align(@bank, course, mastery_score: 0.7)
          @quiz1 = course.quizzes.create!(title: "new quiz", shuffle_answers: true, quiz_type: "assignment", scoring_policy: "keep_highest")
          @quiz1.add_assessment_questions [@q1]
          @quiz2 = course.quizzes.create!(title: "new quiz 2", shuffle_answers: true, quiz_type: "assignment", scoring_policy: "keep_highest")
          @quiz2.add_assessment_questions [@q1]
          @qb_alignment = ContentTag.find_by(content_type: "AssessmentQuestionBank")
        end

        it "creates a LearningOutcomeResult for the same user and learning outcome for different quizzes" do
          lor1 = LearningOutcomeResult.create(
            alignment: @qb_alignment,
            user: student,
            score: 2,
            learning_outcome_id: @outcome.id,
            associated_asset_id: @quiz1.id,
            associated_asset_type: "Quizzes::Quiz"
          )
          lor2 = LearningOutcomeResult.create(
            alignment: @qb_alignment,
            user: student,
            score: 2,
            learning_outcome_id: @outcome.id,
            associated_asset_id: @quiz2.id,
            associated_asset_type: "Quizzes::Quiz"
          )
          expect(LearningOutcomeResult.find(lor1.id).workflow_state).to eq("active")
          expect(LearningOutcomeResult.find(lor2.id).workflow_state).to eq("active")
        end

        it "deletes result if there is a previous one for the same user, learning outcome, and associated asset" do
          lor1 = LearningOutcomeResult.create(
            alignment: @qb_alignment,
            user: student,
            score: 2,
            learning_outcome_id: @outcome.id,
            associated_asset_id: @quiz1.id,
            associated_asset_type: "Quizzes::Quiz"
          )
          same_lor = lor1.clone
          same_lor.save!
          expect(LearningOutcomeResult.find(lor1.id).workflow_state).to eq("active")
          expect(LearningOutcomeResult.find(same_lor.id).workflow_state).to eq("deleted")
        end

        it "updates score and possible if there is a previous one for the same user, learning outcome, and associated asset" do
          lor1 = LearningOutcomeResult.create(
            alignment: @qb_alignment,
            user: student,
            score: 2,
            possible: 9,
            learning_outcome_id: @outcome.id,
            associated_asset_id: @quiz1.id,
            associated_asset_type: "Quizzes::Quiz"
          )
          same_lor = lor1.clone
          same_lor.score = 3
          same_lor.possible = 10
          same_lor.save!
          lor1.reload
          expect(lor1.score).to eq(3)
          expect(lor1.possible).to eq(10)
        end
      end

      describe "for multiple QuestionBanks with questions used in same quizzes" do
        def create_bank(title, course, quiz, outcome)
          bank = course.assessment_question_banks.create!(title:)
          q = bank.assessment_questions.create!(
            question_data: {
              "name" => "#{title} question 1",
              "points_possible" => 10,
              "answers" => [{ "id" => 1 }, { "id" => 2 }]
            }
          )
          outcome.align(bank, course, mastery_score: 0.7)
          quiz.add_assessment_questions [q]
          tag = ContentTag.find_by(content_type: "AssessmentQuestionBank", content_id: bank.id)
          [bank, tag]
        end

        before :once do
          @quiz = course.quizzes.create!(title: "new quiz", shuffle_answers: true, quiz_type: "assignment", scoring_policy: "keep_highest")
          @bank1, @qb_alignment1 = create_bank("Test Bank1", course, @quiz, @outcome)
          @bank2, @qb_alignment2 = create_bank("Test Bank2", course, @quiz, @outcome)
        end

        it "store one result per alignment" do
          lor1 = LearningOutcomeResult.create(
            alignment: @qb_alignment1,
            user: student,
            score: 2,
            learning_outcome_id: @outcome.id,
            associated_asset_id: @quiz.id,
            associated_asset_type: "Quizzes::Quiz"
          )
          lor2 = LearningOutcomeResult.create(
            alignment: @qb_alignment2,
            user: student,
            score: 2,
            learning_outcome_id: @outcome.id,
            associated_asset_id: @quiz.id,
            associated_asset_type: "Quizzes::Quiz"
          )
          expect(LearningOutcomeResult.find(lor1.id).workflow_state).to eq("active")
          expect(LearningOutcomeResult.find(lor2.id).workflow_state).to eq("active")
        end
      end
    end
  end

  describe "before save" do
    describe "#ensure_user_uuid" do
      it "sets user uuid if one is not present" do
        learning_outcome_result.save!
        expect(learning_outcome_result.user_uuid).to eq(student.uuid)
      end
    end

    describe "set_root_account_id" do
      it "sets root_account_id using course" do
        learning_outcome_result.save!
        expect(learning_outcome_result.root_account_id).to be_present
        expect(learning_outcome_result.root_account_id).to eq(course.root_account_id)
      end
    end
  end

  describe "#save_to_version" do
    it "updates the attempt version with the current model state" do
      learning_outcome_result.attempt = 1
      learning_outcome_result.save!
      attempt1_version = learning_outcome_result.versions.current

      attributes = {
        score: 20,
        mastery: true,
        possible: 20,
        attempt: 2,
        title: "Foobar"
      }

      attributes.each do |method_name, value|
        learning_outcome_result.send(:"#{method_name}=", value)
      end
      learning_outcome_result.save!

      updated_version = learning_outcome_result.versions.where(id: attempt1_version.id).first
      version_model = updated_version.model

      expect(version_model).not_to have_attributes(attributes)

      learning_outcome_result.save_to_version(1)
      updated_version = learning_outcome_result.versions.where(id: attempt1_version.id).first
      version_model = updated_version.model

      expect(version_model).to have_attributes(attributes)
    end
  end
end
