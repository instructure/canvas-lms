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

describe ModeratedGrading::ProvisionalGrade do
  subject(:provisional_grade) { submission.provisional_grades.build(scorer:) }

  let(:account) { Account.default }
  let(:course) { account.courses.create! }
  let(:assignment) { course.assignments.create!(submission_types: "online_text_entry", moderated_grading: true, grader_count: 2) }
  let(:submission) { assignment.submissions.find_by!(user: student) }
  let(:scorer) { user_factory(active_user: true).tap { |u| course.enroll_teacher(u, enrollment_state: "active") } }
  let(:student) { user_factory(active_user: true).tap { |u| course.enroll_student(u, enrollment_state: "active") } }

  before(:once) do
    @graded_at = @now = Time.zone.now.change(usec: 0)
  end

  around(:all) { |example| Timecop.freeze(@graded_at, &example) }

  it { is_expected.to be_valid }

  it do
    expect(subject).to have_one(:selection)
      .with_foreign_key(:selected_provisional_grade_id)
      .class_name("ModeratedGrading::Selection")
  end

  it { is_expected.to belong_to(:submission).required }
  it { is_expected.to belong_to(:scorer).required.class_name("User") }
  it { is_expected.to have_many(:rubric_assessments) }

  it { is_expected.to validate_presence_of(:scorer) }
  it { is_expected.to validate_presence_of(:submission) }

  describe "#auditable?" do
    subject(:provisional_grade) { submission.provisional_grades.build(valid_params) }

    let(:valid_params) { { scorer:, current_user: scorer } }

    context "new object" do
      it { is_expected.to be_auditable }

      context "given no changes" do
        subject(:provisional_grade) { submission.provisional_grades.build(valid_params.except(:scorer)) }

        it { is_expected.not_to be_auditable }
      end

      context "given no current_user" do
        subject(:provisional_grade) { submission.provisional_grades.build(valid_params.except(:current_user)) }

        it { is_expected.not_to be_auditable }
      end

      context "given a submission that is not auditable" do
        before { allow(submission).to receive(:assignment_auditable?).and_return(false) }

        it { is_expected.not_to be_auditable }
      end
    end

    context "created object" do
      # `reload` to simulate a fresh object that would normally be fetch
      # through an association or `find` with no saved_change_attributes
      subject(:provisional_grade) { submission.provisional_grades.create!(scorer:).reload }

      context "given auditable changes" do
        before { provisional_grade.assign_attributes(score: 10, current_user: scorer) }

        it { is_expected.to be_auditable }
      end

      context "given no auditable changes" do
        before { provisional_grade.current_user = scorer }

        it { is_expected.not_to be_auditable }
      end

      context "given no current_user" do
        before { provisional_grade.score = 10 }

        it { is_expected.not_to be_auditable }
      end
    end

    context "destroyed object" do
      subject(:provisional_grade) { created_provisional_grade.destroy! }

      let(:created_provisional_grade) { submission.provisional_grades.create!(scorer:, current_user: scorer).reload }

      it { is_expected.to be_auditable }
    end
  end

  describe "Auditing" do
    subject(:event) { AnonymousOrModerationEvent.last }

    before(:once) do
      student = User.create!
      @teacher = User.create!.tap do |teacher|
        teacher.accept_terms
        teacher.register!
      end
      course = Course.create!
      course.enroll_student(student, enrollment_state: "active")
      course.enroll_teacher(@teacher, enrollment_state: "active")
      assignment = course.assignments.create!(moderated_grading: true, grader_count: 2, final_grader: @teacher)
      @submission = assignment.submissions.find_by!(user: student)
      @provisional_grade = @submission.provisional_grades.build(scorer: @teacher, current_user: @teacher)
    end

    let(:score) { 90 }
    let(:grade) { "A" }
    let(:final) { false }
    let(:source_provisional_grade_id) { nil }
    let(:graded_anonymously) { false }

    it { expect(@provisional_grade).to be_auditable }

    describe "created event" do
      let(:event_type) { "provisional_grade_created" }

      it "creates a provisional_grade_created audit event on creation" do
        expect { @provisional_grade.save! }.to change {
          AnonymousOrModerationEvent.where(event_type:, submission: @submission).count
        }.by(1)
      end

      context "given a persisted provisional grade" do
        before(:once) do
          @provisional_grade.assign_attributes(
            scorer: @teacher,
            score:,
            grade:,
            final:,
            source_provisional_grade_id:,
            graded_anonymously:
          )
          @provisional_grade.save!
        end

        it { is_expected.to have_attributes(assignment: @submission.assignment) }
        it { is_expected.to have_attributes(submission: @submission) }
        it { is_expected.to have_attributes(user: @teacher) }
        it { is_expected.to have_attributes(event_type:) }
        it { expect(event.payload.fetch("id")).to be_present }
        it { expect(event.payload).to include("score" => score) }
        it { expect(event.payload).to include("grade" => grade) }
        it { expect(event.payload).to include("graded_at" => @graded_at.iso8601) }
        it { expect(event.payload).to include("final" => final) }
        it { expect(event.payload).to include("source_provisional_grade_id" => source_provisional_grade_id) }
        it { expect(event.payload).to include("graded_anonymously" => graded_anonymously) }
        it { expect(event.payload).to include("scorer_id" => @teacher.id) }
      end
    end

    describe "Updated event" do
      let(:event_type) { "provisional_grade_updated" }

      it "creates a provisional_grade_updated audit event on update" do
        @provisional_grade.save!
        expect { @provisional_grade.update!(score: 1) }.to change {
          AnonymousOrModerationEvent.where(event_type:, submission: @submission).count
        }.by(1)
      end

      context "given a persisted and then upated provisional grade" do
        before(:once) do
          @updated_scorer = user_factory
          @provisional_grade.assign_attributes(
            scorer: @teacher,
            score:,
            grade:,
            final:,
            source_provisional_grade_id:,
            graded_anonymously:
          )
          @provisional_grade.save!
          Timecop.freeze(updated_graded_at) do
            @provisional_grade.update!(
              score: updated_score,
              grade: updated_grade,
              final: updated_final,
              source_provisional_grade_id: updated_source_provisional_grade_id,
              graded_anonymously: updated_graded_anonymously,
              scorer: @updated_scorer,
              current_user: @teacher
            )
          end
        end

        let(:updated_graded_at) { 36.hours.from_now(@graded_at) }
        let(:updated_score) { score.next }
        let(:updated_grade) { grade.next }
        let(:updated_final) { !final }
        let(:updated_source_provisional_grade_id) { @provisional_grade.id }
        let(:updated_graded_anonymously) { !graded_anonymously }

        it { is_expected.to have_attributes(assignment: @submission.assignment) }
        it { is_expected.to have_attributes(submission: @submission) }
        it { is_expected.to have_attributes(user: @teacher) }
        it { is_expected.to have_attributes(event_type:) }
        it { expect(event.payload.fetch("id")).to be_present }
        it { expect(event.payload).to include("score" => [score, updated_score]) }
        it { expect(event.payload).to include("grade" => [grade, updated_grade]) }
        it { expect(event.payload).to include("graded_at" => [@graded_at.iso8601, updated_graded_at.iso8601]) }
        it { expect(event.payload).to include("final" => [final, updated_final]) }
        it { expect(event.payload).to include("source_provisional_grade_id" => [source_provisional_grade_id, updated_source_provisional_grade_id]) }
        it { expect(event.payload).to include("graded_anonymously" => [graded_anonymously, updated_graded_anonymously]) }
        it { expect(event.payload).to include("scorer_id" => [@teacher.id, @updated_scorer.id]) }
      end
    end
  end

  describe "grade_attributes" do
    subject(:provisional_grade) { submission.provisional_grades.build(score: 100.0, grade: "A", scorer:) }

    it "returns the proper format" do
      json = provisional_grade.grade_attributes
      expect(json).to eq({
                           "provisional_grade_id" => provisional_grade.id,
                           "grade" => "A",
                           "score" => 100.0,
                           "graded_at" => nil,
                           "scorer_id" => provisional_grade.scorer_id,
                           "graded_anonymously" => nil,
                           "entered_grade" => "A",
                           "entered_score" => 100.0,
                           "final" => false,
                           "grade_matches_current_submission" => true
                         })
    end
  end

  describe "final" do
    before do
      @admin1 = account_admin_user(account: course.root_account)
      @admin2 = account_admin_user(account: course.root_account)
      ta = ta_in_course(course:, active_all: true).user
      submission.find_or_create_provisional_grade!(ta)
    end

    it "shares the final provisional grade among moderators" do
      admin1_provisional_grade = submission.find_or_create_provisional_grade!(@admin1, final: true)
      admin2_provisional_grade = submission.provisional_grade(@admin2, final: true)
      expect(admin2_provisional_grade).to eq admin1_provisional_grade
    end

    it "does not create a new final provisional grade if a shared one already exists" do
      admin1_provisional_grade = submission.find_or_create_provisional_grade!(@admin1, final: true)
      expect(admin1_provisional_grade).to eq submission.find_or_create_provisional_grade!(@admin2, final: true)
    end
  end

  describe "grade_matches_current_submission" do
    it "returns true if the grade is newer than the submission" do
      submission = nil
      Timecop.freeze(10.minutes.ago) do
        submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      end
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      expect(provisional_grade.reload.grade_matches_current_submission).to be true
    end

    it "returns false if the submission is newer than the grade" do
      submission = nil
      provisional_grade = nil
      Timecop.freeze(10.minutes.ago) do
        submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
        provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      end
      assignment.submit_homework(student, submission_type: "online_text_entry", body: "resubmit")
      expect(provisional_grade.reload.grade_matches_current_submission).to be false
    end
  end

  describe "unique constraint" do
    it "disallows multiple provisional grades from the same user" do
      first_provisional_grade = submission.provisional_grades.build(score: 75)
      first_provisional_grade.scorer = scorer
      first_provisional_grade.save!
      second_provisional_grade = submission.provisional_grades.build(score: 80)
      second_provisional_grade.scorer = scorer
      expect { second_provisional_grade.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "disallows multiple final provisional grades" do
      first_provisional_grade = submission.provisional_grades.build(score: 75, final: false)
      first_provisional_grade.scorer = scorer
      first_provisional_grade.save!
      second_provisional_grade = submission.provisional_grades.build(score: 75, final: true)
      second_provisional_grade.scorer = scorer
      second_provisional_grade.save!
      third_provisional_grade = submission.provisional_grades.build(score: 80, final: true)
      third_provisional_grade.scorer = User.create!
      expect { third_provisional_grade.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe "#graded_at when a grade changes" do
    it { expect(provisional_grade.graded_at).to be_nil }

    it "updates the graded_at timestamp when changing grade" do
      Timecop.freeze(@now) do
        provisional_grade.update(grade: "B")
        expect(provisional_grade.graded_at).to eql @now
      end
    end

    it "updates the graded_at timestamp when changing score" do
      Timecop.freeze(@now) do
        provisional_grade.update(score: 80)
        expect(provisional_grade.graded_at).to eql @now
      end
    end

    it "updated graded_at when force_save is set, regardless of whether the grade actually changed" do
      Timecop.freeze(@now) do
        provisional_grade.force_save = true
        provisional_grade.save!
        expect(provisional_grade.graded_at).to eql @now
      end
    end
  end

  describe "infer_grade" do
    it "infers a grade if only score is given" do
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 0)
      expect(provisional_grade.grade).not_to be_nil
    end

    it "leaves grade nil if score is nil" do
      provisional_grade = submission.find_or_create_provisional_grade! scorer
      expect(provisional_grade.grade).to be_nil
    end
  end

  describe "publish_rubric_assessments!" do
    it "publishes rubric assessments to the submission" do
      outcome_with_rubric(course:)
      association = @rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)

      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)

      provisional_assessment = association.assess(
        user: student,
        assessor: scorer,
        artifact: provisional_grade,
        assessment: {
          assessment_type: "grading",
          "criterion_#{@rubric.criteria_object.first.id}": {
            points: 3,
            comments: "good 4 u"
          }
        }
      )

      expect(provisional_assessment.score).to eq 3

      provisional_grade.publish!
      real_assessment = submission.rubric_assessments.first
      expect(real_assessment.score).to eq 3
      expect(real_assessment.assessor).to eq scorer
      expect(real_assessment.rubric_association).to eq association
      expect(real_assessment.data).to eq provisional_assessment.data
    end

    it "does not publish rubric assessments when the rubric association is soft-deleted" do
      outcome_with_rubric(course:)
      association = @rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)
      association.destroy

      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)

      association.assess(
        user: student,
        assessor: scorer,
        artifact: provisional_grade,
        assessment: {
          assessment_type: "grading",
          "criterion_#{@rubric.criteria_object.first.id}": {
            points: 3,
            comments: "good 4 u"
          }
        }
      )

      expect(submission.rubric_assessments.first).to be_nil
    end

    it "does not error when a rubric has been deleted after an assessment took place" do
      outcome_with_rubric(course:)
      association = @rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)

      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)

      association.assess(
        user: student,
        assessor: scorer,
        artifact: provisional_grade,
        assessment: {
          assessment_type: "grading",
          "criterion_#{@rubric.criteria_object.first.id}": {
            points: 3,
            comments: "good 4 u"
          }
        }
      )

      @rubric.destroy!
      expect { provisional_grade.publish! }.not_to raise_error
    end

    it "posts learning outcome results" do
      outcome_with_rubric(course:)
      association = @rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)

      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)

      expect do
        association.assess(
          user: student,
          assessor: scorer,
          artifact: provisional_grade,
          assessment: {
            assessment_type: "grading",
            "criterion_#{@rubric.criteria_object.first.id}": {
              points: 3,
              comments: "good 4 u"
            }
          }
        )
      end.not_to change { LearningOutcomeResult.count }

      expect { provisional_grade.publish! }.to change { LearningOutcomeResult.count }.by(1)
    end

    it "sets grade_posting_in_progress on the rubric_assessment's submission" do
      outcome_with_rubric(course:)
      association = @rubric.associate_with(assignment, course, purpose: "grading", use_for_grading: true)
      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      provisional_grade.submission.grade_posting_in_progress = true

      association.assess(
        user: student,
        assessor: scorer,
        artifact: provisional_grade,
        assessment: {
          assessment_type: :grading,
          "criterion_#{@rubric.criteria_object.first.id}": {
            points: 3,
            comments: "good 4 u"
          }
        }
      )
      provisional_grade.publish!
      expect(submission.reload.score).to eq 3
    end
  end

  describe "publish!" do
    it "sets the submission as 'graded'" do
      assignment.update!(moderated_grading: true, grader_count: 2)
      submission = submission_model(assignment:, user: student)
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 80, graded_anonymously: true)
      provisional_grade.publish!
      submission.reload

      expect(submission.workflow_state).to eq "graded"
    end

    it "updates the submission with provisional grade attributes" do
      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 80, graded_anonymously: true)
      submission.reload

      expect(provisional_grade).to receive(:publish_rubric_assessments!).once
      provisional_grade.publish!
      submission.reload

      expect(submission.grade_matches_current_submission).to be true
      expect(submission.graded_at).not_to be_nil
      expect(submission.grader_id).to eq scorer.id
      expect(submission.score).to eq 80
      expect(submission.grade).not_to be_nil
      expect(submission.graded_anonymously).to be true
    end

    it "duplicates submission comments from the provisional grade to the submission" do
      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      provisional_comment = submission.add_comment(commenter: scorer, comment: "blah", provisional: true)

      provisional_grade.publish!
      submission.reload

      real_comment = submission.submission_comments.first
      expect(real_comment.provisional_grade_id).to be_nil
      expect(real_comment.author).to eq scorer
      expect(real_comment.comment).to eq provisional_comment.comment
      expect(real_comment.attachments.first).to eq provisional_comment.attachments.first
    end

    it "shares attachments between duplicated submission comments" do
      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      file = assignment.attachments.create! uploaded_data: default_uploaded_data
      provisional_comment = submission.add_comment(commenter: scorer, comment: "blah", provisional: true, attachments: [file])

      provisional_grade.publish!
      submission.reload

      real_comment = submission.submission_comments.first
      expect(real_comment.attachments).to eq provisional_comment.attachments
    end

    it "does not duplicate submission comments not associated with the provisional grade" do
      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hallo")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      submission.add_comment(commenter: scorer, comment: "provisional", provisional: true)
      submission.add_comment(commenter: scorer, comment: "normal", provisional: false)

      provisional_grade.publish!
      submission.reload

      expect(submission.submission_comments.map(&:comment)).to match_array(["provisional", "normal"])
    end

    it "triggers GradeCalculator#recompute_final_score by default" do
      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hello")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      expect(GradeCalculator).to receive(:recompute_final_score).once
      provisional_grade.publish!
    end

    it "does not triggers GradeCalculator#recompute_final_score if passed skip_grade_calc true" do
      submission = assignment.submit_homework(student, submission_type: "online_text_entry", body: "hello")
      provisional_grade = submission.find_or_create_provisional_grade!(scorer, score: 1)
      expect(GradeCalculator).not_to receive(:recompute_final_score)
      provisional_grade.publish!(skip_grade_calc: true)
    end

    it "does not create a duplicate submission comment created event when a provisional grade is published" do
      assignment.update!(moderated_grading: true, final_grader: scorer, grader_count: 1)
      provisional_grade = submission.find_or_create_provisional_grade!(scorer)
      submission.add_comment(comment: "provisional comment", provisional: true, author: scorer)

      expect { provisional_grade.publish!(skip_grade_calc: true) }.not_to change {
        AnonymousOrModerationEvent.where(assignment:, submission:)
                                  .submission_comment_created.count
      }
    end
  end
end
