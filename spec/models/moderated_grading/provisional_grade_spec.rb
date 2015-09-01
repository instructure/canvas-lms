require 'spec_helper'

describe ModeratedGrading::ProvisionalGrade do
  subject(:provisional_grade) do
    submission.provisional_grades.new(grade: 'A', score: 100.0, scorer: user).tap do |grade|
      grade.scorer = user
    end
  end
  let(:submission) { assignment.submissions.create!(user: user) }
  let(:assignment) { course.assignments.create! submission_types: 'online_text_entry' }
  let(:course) { Course.create! }
  let(:user) { User.create! }
  let(:student) { u = User.create!; course.enroll_student(u); u }
  let(:now) { Time.zone.now }

  it { is_expected.to be_valid }
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
                           'grade_matches_current_submission' => true
                         })
    end
  end

  describe "grade_matches_current_submission" do
    it "returns true if the grade is newer than the submission" do
      sub = nil
      Timecop.freeze(10.minutes.ago) do
        sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      end
      pg = sub.find_or_create_provisional_grade! scorer: user, score: 1
      expect(pg.reload.grade_matches_current_submission).to eq true
    end

    it "returns false if the submission is newer than the grade" do
      sub = nil
      pg = nil
      Timecop.freeze(10.minutes.ago) do
        sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
        pg = sub.find_or_create_provisional_grade! scorer: user, score: 1
      end
      assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'resubmit')
      expect(pg.reload.grade_matches_current_submission).to eq false
    end
  end

  describe 'unique constraint' do
    it "disallows multiple provisional grades from the same user" do
      pg1 = submission.provisional_grades.build(score: 75)
      pg1.scorer = user
      pg1.save!
      pg2 = submission.provisional_grades.build(score: 80)
      pg2.scorer = user
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

  describe "publish_rubric_assessments!" do
    it "publishes rubric assessments to the submission" do
      @course = course
      outcome_with_rubric
      association = @rubric.associate_with(assignment, course, :purpose => 'grading', :use_for_grading => true)

      sub = assignment.submit_homework(student, :submission_type => 'online_text_entry', :body => 'hallo')
      pg = sub.find_or_create_provisional_grade! scorer: user, score: 1

      prov_assmt = association.assess(:user => student, :assessor => user, :artifact => pg,
        :assessment => { :assessment_type => 'grading',
          :"criterion_#{@rubric.criteria_object.first.id}" => { :points => 3, :comments => "good 4 u" } })

      expect(prov_assmt.score).to eq 3

      pg.publish_rubric_assessments!

      real_assmt = sub.rubric_assessments.first
      expect(real_assmt.score).to eq 3
      expect(real_assmt.assessor).to eq user
      expect(real_assmt.rubric_association).to eq association
      expect(real_assmt.data).to eq prov_assmt.data
    end

  end
end

describe ModeratedGrading::NullProvisionalGrade do
  describe 'grade_attributes' do
    it "returns the proper format" do
      expect(ModeratedGrading::NullProvisionalGrade.new(1).grade_attributes).to eq({
          'provisional_grade_id' => nil,
          'grade' => nil,
          'score' => nil,
          'graded_at' => nil,
          'scorer_id' => 1,
          'grade_matches_current_submission' => true
        })
    end
  end
end