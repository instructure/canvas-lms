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

require 'spec_helper'

describe ModeratedGrading::ProvisionalGrade do
  subject(:provisional_grade) do
    submission.provisional_grades.new(grade: 'A', score: 100.0, scorer: scorer).tap do |grade|
      grade.scorer = scorer
    end
  end
  let(:submission) { assignment.submissions.find_by!(user: student) }
  let(:assignment) { course.assignments.create! submission_types: 'online_text_entry' }
  let(:account) { a = account_model; a}
  let(:course) { c = account.courses.create!; c  }
  let(:scorer) { u = user_factory(active_user: true); course.enroll_teacher(u, :enrollment_state => 'active'); u }
  let(:student) { u = user_factory(active_user: true); course.enroll_student(u, :enrollment_state => 'active'); u }
  let(:now) { Time.zone.now }

  it { is_expected.to be_valid }

  it do
    is_expected.to have_one(:selection).
      with_foreign_key(:selected_provisional_grade_id).
      class_name('ModeratedGrading::Selection')
  end
  it { is_expected.to belong_to(:submission) }
  it { is_expected.to belong_to(:scorer).class_name('User') }
  it { is_expected.to have_many(:rubric_assessments) }

  it { is_expected.to validate_presence_of(:scorer) }
  it { is_expected.to validate_presence_of(:submission) }

  describe 'grade_attributes' do
    it "returns the proper format" do
      json = provisional_grade.grade_attributes
      expect(json).to eq({
        'provisional_grade_id' => provisional_grade.id,
        'grade' => 'A',
        'score' => 100.0,
        'graded_at' => nil,
        'scorer_id' => provisional_grade.scorer_id,
        'graded_anonymously' => nil,
        'entered_grade' => 'A',
        'entered_score' => 100.0,
        'final' => false,
        'grade_matches_current_submission' => true
      })
    end
  end

  describe 'final' do
    before(:each) do
      @admin1 = account_admin_user(account: course.root_account)
      @admin2 = account_admin_user(account: course.root_account)
      ta = ta_in_course(course: course, active_all: true).user
      submission.find_or_create_provisional_grade!(ta)
    end

    it 'shares the final provisional grade among moderators' do
      admin1_provisional_grade = submission.find_or_create_provisional_grade!(@admin1, final: true)
      admin2_provisional_grade = submission.provisional_grade(@admin2, final: true)
      expect(admin2_provisional_grade).to eq admin1_provisional_grade
    end

    it 'does not create a new final provisional grade if a shared one already exists' do
      admin1_provisional_grade = submission.find_or_create_provisional_grade!(@admin1, final: true)
      expect(admin1_provisional_grade).to eq submission.find_or_create_provisional_grade!(@admin2, final: true)
    end
  end

  describe "grade_matches_current_submission" do
    it "returns true if the grade is newer than the submission" do
      sub = nil
      Timecop.freeze(10.minutes.ago) do
        sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      end
      pg = sub.find_or_create_provisional_grade!(scorer, score: 1)
      expect(pg.reload.grade_matches_current_submission).to eq true
    end

    it "returns false if the submission is newer than the grade" do
      sub = nil
      pg = nil
      Timecop.freeze(10.minutes.ago) do
        sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
        pg = sub.find_or_create_provisional_grade!(scorer, score: 1)
      end
      assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'resubmit')
      expect(pg.reload.grade_matches_current_submission).to eq false
    end
  end

  describe 'unique constraint' do
    it "disallows multiple provisional grades from the same user" do
      mgs = ModeratedGrading::Selection.new
      mgs.student = submission.user
      mgs.assignment = assignment
      mgs.save!

      pg1 = submission.provisional_grades.build(score: 75)
      pg1.scorer = scorer
      pg1.save!
      pg2 = submission.provisional_grades.build(score: 80)
      pg2.scorer = scorer
      expect { pg2.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "disallows multiple final provisional grades" do
      mgs = ModeratedGrading::Selection.new
      mgs.student = submission.user
      mgs.assignment = assignment
      mgs.save!

      pg1 = submission.provisional_grades.build(score: 75, final: false)
      pg1.scorer = scorer
      pg1.save!
      pg2 = submission.provisional_grades.build(score: 75, final: true)
      pg2.scorer = scorer
      pg2.save!
      pg3 = submission.provisional_grades.build(score: 80, final: true)
      pg3.scorer = User.create!
      expect { pg3.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe '#graded_at when a grade changes' do
    it { expect(provisional_grade.graded_at).to be_nil }
    it 'updates the graded_at timestamp when changing grade' do
      Timecop.freeze(now) do
        provisional_grade.update_attributes(grade: 'B')
        expect(provisional_grade.graded_at).to eql now
      end
    end
    it 'updates the graded_at timestamp when changing score' do
      Timecop.freeze(now) do
        provisional_grade.update_attributes(score: 80)
        expect(provisional_grade.graded_at).to eql now
      end
    end
    it 'updated graded_at when force_save is set, regardless of whether the grade actually changed' do
      Timecop.freeze(now) do
        provisional_grade.force_save = true
        provisional_grade.save!
        expect(provisional_grade.graded_at).to eql now
      end
    end
  end

  describe 'infer_grade' do
    it 'infers a grade if only score is given' do
      pg = submission.find_or_create_provisional_grade!(scorer, score: 0)
      expect(pg.grade).not_to be_nil
    end

    it 'leaves grade nil if score is nil' do
      pg = submission.find_or_create_provisional_grade! scorer
      expect(pg.grade).to be_nil
    end
  end

  describe "publish_rubric_assessments!" do
    it "publishes rubric assessments to the submission" do
      @course = course
      outcome_with_rubric
      association = @rubric.associate_with(assignment, course, :purpose => 'grading', :use_for_grading => true)

      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade!(scorer, score: 1)

      prov_assmt = association.assess(:user => student, :assessor => scorer, :artifact => pg,
        :assessment => { :assessment_type => 'grading',
          :"criterion_#{@rubric.criteria_object.first.id}" => { :points => 3, :comments => "good 4 u" } })


      expect(prov_assmt.score).to eq 3

      pg.send :publish_rubric_assessments!

      real_assmt = sub.rubric_assessments.first
      expect(real_assmt.score).to eq 3
      expect(real_assmt.assessor).to eq scorer
      expect(real_assmt.rubric_association).to eq association
      expect(real_assmt.data).to eq prov_assmt.data
    end

  end

  describe "publish!" do
    it "sets the submission as 'graded'" do
      assignment.update!(moderated_grading: true, grader_count: 2)
      sub = submission_model(assignment: assignment, user: student)
      provisional_grade = sub.find_or_create_provisional_grade!(scorer, score: 80, graded_anonymously: true)

      provisional_grade.publish!
      sub.reload

      expect(sub.workflow_state).to eq 'graded'
    end

    it "updates the submission with provisional grade attributes" do
      @course = course
      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade!(scorer, score: 80, graded_anonymously: true)
      sub.reload

      expect(pg).to receive(:publish_rubric_assessments!).once
      pg.publish!
      sub.reload

      expect(sub.grade_matches_current_submission).to eq true
      expect(sub.graded_at).not_to be_nil
      expect(sub.grader_id).to eq scorer.id
      expect(sub.score).to eq 80
      expect(sub.grade).not_to be_nil
      expect(sub.graded_anonymously).to eq true
    end

    it "duplicates submission comments from the provisional grade to the submission" do
      @course = course
      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade!(scorer, score: 1)
      provisional_comment = sub.add_comment(commenter: scorer, comment: 'blah', provisional: true)

      pg.publish!
      sub.reload

      real_comment = sub.submission_comments.first
      expect(real_comment.provisional_grade_id).to be_nil
      expect(real_comment.author).to eq scorer
      expect(real_comment.comment).to eq provisional_comment.comment
      expect(real_comment.attachments.first).to eq provisional_comment.attachments.first
    end

    it "shares attachments between duplicated submission comments" do
      @course = course
      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade!(scorer, score: 1)
      file = assignment.attachments.create! uploaded_data: default_uploaded_data
      provisional_comment = sub.add_comment(commenter: scorer, comment: 'blah', provisional: true, attachments: [file])

      pg.publish!
      sub.reload

      real_comment = sub.submission_comments.first
      expect(real_comment.attachments).to eq provisional_comment.attachments
    end

    it "does not duplicate submission comments not associated with the provisional grade" do
      @course = course
      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade!(scorer, score: 1)
      sub.add_comment(commenter: scorer, comment: 'provisional', provisional: true)
      sub.add_comment(commenter: scorer, comment: 'normal', provisional: false)

      pg.publish!
      sub.reload

      expect(sub.submission_comments.map(&:comment)).to match_array(['provisional', 'normal'])
    end
  end

  describe "copy_to_final_mark!" do
    before(:once) do
      @course = course
      @scorer = scorer
      @moderator = teacher_in_course(:course => @course, :active_all => true).user
      assignment.update!(moderated_grading: true, grader_count: 2, final_grader: @moderator)
      outcome_with_rubric
      @association = @rubric.associate_with(assignment, course, :purpose => 'grading', :use_for_grading => true)
      @sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      @pg = @sub.find_or_create_provisional_grade!(@scorer, score: 80)
      @prov_assmt = @association.assess(:user => student, :assessor => @scorer, :artifact => @pg,
        :assessment => { :assessment_type => 'grading',
                         :"criterion_#{@rubric.criteria_object.first.id}" => { :points => 3, :comments => "wat" } })
      @prov_comment = @sub.add_comment(:commenter => @scorer, :comment => 'blah', :provisional => true)
    end

    def test_copy_to_final_mark
      final_mark = @pg.copy_to_final_mark!(@moderator)
      expect(final_mark.id).not_to eq @pg.id
      expect(final_mark.source_provisional_grade_id).to eq @pg.id

      expect(final_mark.grade).to eq @pg.grade
      expect(final_mark.score).to eq @pg.score
      expect(final_mark.scorer).to eq @moderator
      expect(final_mark.final).to eq true

      expect(@sub.submission_comments.count).to eq 0
      expect(final_mark.submission_comments.count).to eq 1
      final_comment = final_mark.submission_comments.first
      expect(final_comment.id).not_to eq @prov_comment.id
      expect(final_comment.author).to eq @scorer
      expect(final_comment.comment).to eq @prov_comment.comment

      expect(@sub.rubric_assessments.count).to eq 0
      expect(final_mark.rubric_assessments.count).to eq 1
      final_assmt = final_mark.rubric_assessments.first
      expect(final_assmt.score).to eq 3
      expect(final_assmt.assessor).to eq @scorer
      expect(final_assmt.rubric_association).to eq @association
      expect(final_assmt.data).to eq @prov_assmt.data
    end

    it "copies grade, score, comments, and rubric assessments to a final mark" do
      test_copy_to_final_mark
    end

    it "overwrites an existing final mark (including comments and rubric assessments)" do
      final_mark = @sub.find_or_create_provisional_grade!(@moderator, score: 90, final: true)
      fa = @association.assess(:user => student, :assessor => @moderator, :artifact => final_mark,
         :assessment => { :assessment_type => 'grading',
                          :"criterion_#{@rubric.criteria_object.first.id}" => { :points => 4, :comments => "srsly" } })
      fc = @sub.add_comment(:commenter => @moderator, :comment => 'no rly deleteme', :provisional => true, :final => true)
      expect(fc.provisional_grade_id).to eq final_mark.id

      test_copy_to_final_mark

      expect(RubricAssessment.find_by(id: fa.id)).to be_nil
      expect(SubmissionComment.find_by(id: fc.id)).to be_nil
    end

    it "generates attachment_info with all participants" do
      att = double(:id => 100, :crocodoc_available? => true, :canvadoc_available? => true)
      whitelist = [@sub.user, @moderator, @scorer].map { |u| u.moderated_grading_ids(true) }
      url_opts = {enable_annotations: true, moderated_grading_whitelist: whitelist}
      expect(att).to receive(:crocodoc_url).with(@moderator, url_opts).and_return('fake_url')
      expect(att).to receive(:canvadoc_url).with(@moderator, url_opts).and_return('fake_canvadoc_url')
      final_mark = @pg.copy_to_final_mark!(@moderator)
      expect(final_mark.attachment_info(@moderator, att)).to eq({
        attachment_id: 100,
        crocodoc_url: 'fake_url',
        canvadoc_url: 'fake_canvadoc_url'
      })
    end
  end
end

describe ModeratedGrading::NullProvisionalGrade do
  describe 'grade_attributes' do
    it "returns the proper format" do
      expect(ModeratedGrading::NullProvisionalGrade.new(nil, 1, false).grade_attributes).to eq({
        'provisional_grade_id' => nil,
        'grade' => nil,
        'score' => nil,
        'graded_at' => nil,
        'scorer_id' => 1,
        'graded_anonymously' => nil,
        'final' => false,
        'grade_matches_current_submission' => true
      })

      expect(ModeratedGrading::NullProvisionalGrade.new(nil, 2, true).grade_attributes).to eq({
        'provisional_grade_id' => nil,
        'grade' => nil,
        'score' => nil,
        'graded_at' => nil,
        'scorer_id' => 2,
        'graded_anonymously' => nil,
        'final' => true,
        'grade_matches_current_submission' => true
      })
    end
  end

  it "should return the original submission's submission comments" do
    sub = double
    comments = double
    expect(sub).to receive(:submission_comments).and_return(comments)
    expect(ModeratedGrading::NullProvisionalGrade.new(sub, 1, false).submission_comments).to eq(comments)
  end

  describe 'scorer' do
    it 'returns the associated scorer if scorer_id is present' do
      scorer = user_factory(active_user: true)
      scored_grade = ModeratedGrading::NullProvisionalGrade.new(nil, scorer.id, true)
      expect(scored_grade.scorer).to eq scorer
    end

    it 'returns nil if scorer_id is nil' do
      scored_grade = ModeratedGrading::NullProvisionalGrade.new(nil, nil, true)
      expect(scored_grade.scorer).to be nil
    end
  end
end
