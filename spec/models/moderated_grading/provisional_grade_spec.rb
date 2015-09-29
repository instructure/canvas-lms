require 'spec_helper'

describe ModeratedGrading::ProvisionalGrade do
  subject(:provisional_grade) do
    submission.provisional_grades.new(grade: 'A', score: 100.0, scorer: scorer).tap do |grade|
      grade.scorer = scorer
    end
  end
  let(:submission) { assignment.submissions.create!(user: student) }
  let(:assignment) { course.assignments.create! submission_types: 'online_text_entry' }
  let(:account) { a = account_model; a.allow_feature!(:moderated_grading); a}
  let(:course) { c = account.courses.create!; c.enable_feature!(:moderated_grading); c  }
  let(:scorer) { user }
  let(:student) { u = user(:active_user => true); course.enroll_student(u); u }
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
        'final' => false,
        'grade_matches_current_submission' => true
      })
    end
  end

  describe "final" do
    it "shares the final provisional grade among moderators" do
      teacher1 = teacher_in_course(:course => course, :active_all => true).user
      teacher2 = teacher_in_course(:course => course, :active_all => true).user
      ta = ta_in_course(:course => course, :active_all => true).user

      teacher1_pg = submission.find_or_create_provisional_grade!(scorer: teacher1, final: true)
      expect(teacher1_pg.final).to be_truthy
      teacher2_pg = submission.provisional_grade(teacher2, final: true)
      expect(teacher2_pg).to eq teacher1_pg
      expect(teacher1_pg).to eq submission.find_or_create_provisional_grade!(scorer: teacher2, final: true)
    end
  end

  describe "grade_matches_current_submission" do
    it "returns true if the grade is newer than the submission" do
      sub = nil
      Timecop.freeze(10.minutes.ago) do
        sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      end
      pg = sub.find_or_create_provisional_grade! scorer: scorer, score: 1
      expect(pg.reload.grade_matches_current_submission).to eq true
    end

    it "returns false if the submission is newer than the grade" do
      sub = nil
      pg = nil
      Timecop.freeze(10.minutes.ago) do
        sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
        pg = sub.find_or_create_provisional_grade! scorer: scorer, score: 1
      end
      assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'resubmit')
      expect(pg.reload.grade_matches_current_submission).to eq false
    end
  end

  describe 'unique constraint' do
    it "disallows multiple provisional grades from the same user" do
      pg1 = submission.provisional_grades.build(score: 75)
      pg1.scorer = scorer
      pg1.save!
      pg2 = submission.provisional_grades.build(score: 80)
      pg2.scorer = scorer
      expect { pg2.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it "disallows multiple final provisional grades" do
      pg1 = submission.provisional_grades.build(score: 75, final: true)
      pg1.scorer = scorer
      pg1.save!
      pg2 = submission.provisional_grades.build(score: 80, final: true)
      pg2.scorer = User.create!
      expect { pg2.save! }.to raise_error(ActiveRecord::RecordNotUnique)
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
      pg = submission.find_or_create_provisional_grade! scorer: scorer, score: 0
      expect(pg.grade).not_to be_nil
    end

    it 'leaves grade nil if score is nil' do
      pg = submission.find_or_create_provisional_grade! scorer: scorer
      expect(pg.grade).to be_nil
    end
  end

  describe "publish_rubric_assessments!" do
    it "publishes rubric assessments to the submission" do
      @course = course
      outcome_with_rubric
      association = @rubric.associate_with(assignment, course, :purpose => 'grading', :use_for_grading => true)

      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade! scorer: scorer, score: 1

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

  describe "publish_submission_comments!" do
    it "publishes comments to the submission" do
      @course = course
      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade! scorer: scorer, score: 1
      file = assignment.attachments.create! uploaded_data: default_uploaded_data
      prov_comment = sub.add_comment(commenter: scorer, message: 'blah', provisional: true, attachments: [file])

      pg.send :publish_submission_comments!

      real_comment = sub.submission_comments.first
      expect(real_comment.provisional_grade_id).to be_nil
      expect(real_comment.author).to eq scorer
      expect(real_comment.comment).to eq prov_comment.comment
      expect(real_comment.attachments.first).to eq prov_comment.attachments.first
    end
  end

  describe "publish!" do
    it "publishes a provisional grade" do
      @course = course
      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade! scorer: scorer, score: 80
      sub.reload
      expect(sub.workflow_state).to eq 'submitted'
      expect(sub.graded_at).to be_nil
      expect(sub.grader_id).to be_nil
      expect(sub.score).to be_nil
      expect(sub.grade).to be_nil

      pg.expects(:publish_submission_comments!).once
      pg.expects(:publish_rubric_assessments!).once
      pg.publish!

      sub.reload
      expect(sub.grade_matches_current_submission).to eq true
      expect(sub.workflow_state).to eq 'graded'
      expect(sub.graded_at).not_to be_nil
      expect(sub.grader_id).to eq scorer.id
      expect(sub.score).to eq 80
      expect(sub.grade).not_to be_nil
    end
  end
end

describe ModeratedGrading::NullProvisionalGrade do
  describe 'grade_attributes' do
    it "returns the proper format" do
      expect(ModeratedGrading::NullProvisionalGrade.new(1, false).grade_attributes).to eq({
        'provisional_grade_id' => nil,
        'grade' => nil,
        'score' => nil,
        'graded_at' => nil,
        'scorer_id' => 1,
        'final' => false,
        'grade_matches_current_submission' => true
      })

      expect(ModeratedGrading::NullProvisionalGrade.new(2, true).grade_attributes).to eq({
        'provisional_grade_id' => nil,
        'grade' => nil,
        'score' => nil,
        'graded_at' => nil,
        'scorer_id' => 2,
        'final' => true,
        'grade_matches_current_submission' => true
      })
    end
  end
end
