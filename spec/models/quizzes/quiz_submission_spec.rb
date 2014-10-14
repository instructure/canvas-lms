# encoding: UTF-8
#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizSubmission do
  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  context 'with course and quiz' do
  before(:once) do
    course
    @quiz = @course.quizzes.create!
  end

  context "saving a quiz submission" do
    it "should validate numericality of extra time" do
      qs = Quizzes::QuizSubmission.new
      qs.extra_time = 'asdf'
      expect(qs.valid?).to eq false
      expect(Array(qs.errors[:extra_time])).to eq ["is not a number"]
    end

    it "should validate extra time is not too long" do
      qs = Quizzes::QuizSubmission.new
      qs.extra_time = 10081
      expect(qs.valid?).to eq false
      expect(Array(qs.errors[:extra_time])).to eq ["must be less than or equal to 10080"]
    end

    it "should validate numericality of extra attempts" do
      qs = Quizzes::QuizSubmission.new
      qs.extra_attempts = 'asdf'
      expect(qs.valid?).to eq false
      expect(Array(qs.errors[:extra_attempts])).to eq ["is not a number"]
    end

    it "should validate extra attempts is not too long" do
      qs = Quizzes::QuizSubmission.new
      qs.extra_attempts = 1001
      expect(qs.valid?).to eq false
      expect(Array(qs.errors[:extra_attempts])).to eq ["must be less than or equal to 1000"]
    end

    it "should validate quiz points possible is not too long" do
      qs = Quizzes::QuizSubmission.new
      qs.quiz = Quizzes::Quiz.new(:points_possible => 2000000001)
      expect(qs.valid?).to eq false
      expect(Array(qs.errors[:quiz_points_possible])).to eq ["must be less than or equal to 2000000000"]
    end
  end

  describe '#finished_at' do
    it 'should rectify small amounts of drift (could be caused by JS stalling)' do
      anchor = Time.now

      # subject.stubs(:end_at?).returns(true)
      subject.started_at = anchor
      subject.end_at = anchor + 5.minutes
      subject.finished_at = anchor + 6.minutes
      subject.save
      expect(subject.finished_at).to eq subject.end_at
    end
  end

  it "should copy the quiz's points_possible whenever it's saved" do
    Quizzes::Quiz.where(:id => @quiz).update_all(:points_possible => 1.1)
    q = @quiz.quiz_submissions.create!
    expect(q.reload.quiz_points_possible).to eql 1.1

    Quizzes::Quiz.where(:id => @quiz).update_all(:points_possible => 1.9)
    expect(q.reload.quiz_points_possible).to eql 1.1

    q.save!
    expect(q.reload.quiz_points_possible).to eql 1.9
  end

  it "should not lose time" do
    @quiz.update_attribute(:time_limit, 10)
    q = @quiz.quiz_submissions.create!
    q.update_attribute(:started_at, Time.now)
    original_end_at = q.end_at

    @quiz.update_attribute(:time_limit, 5)
    @quiz.update_quiz_submission_end_at_times

    q.reload
    expect(q.end_at).to eql original_end_at
  end

  describe "#update_scores" do
    before(:once) do
      student_in_course
      assignment_quiz([])
      qd = multiple_choice_question_data
      @quiz.quiz_data = [qd]
      @quiz.points_possible = qd[:points_possible]
      @quiz.save!
    end

    it "should update scores for a completed submission" do
      qs = @quiz.generate_submission(@student)
      qs.submission_data = { "question_1" => "1658" }
      Quizzes::SubmissionGrader.new(qs).grade_submission

      # sanity check
      qs.reload
      expect(qs.score).to eq 50
      expect(qs.kept_score).to eq 50

      qs.update_scores({:fudge_points => -5, :question_score_1 => 50})
      expect(qs.score).to eq 45
      expect(qs.fudge_points).to eq -5
      expect(qs.kept_score).to eq 45
      v = qs.versions.current.model
      expect(v.score).to eq 45
      expect(v.fudge_points).to eq -5
    end

    it "should not allow updating scores on an uncompleted submission" do
      qs = @quiz.generate_submission(@student)
      expect(qs).to be_untaken
      expect { qs.update_scores }.to raise_error
    end

    it "should update scores for a previous submission" do
      qs = @quiz.generate_submission(@student)
      qs.submission_data = { "question_1" => "2405" }
      Quizzes::SubmissionGrader.new(qs).grade_submission

      qs = @quiz.generate_submission(@student)
      qs.submission_data = { "question_1" => "8544" }
      Quizzes::SubmissionGrader.new(qs).grade_submission

      # sanity check
      expect(qs.score).to eq 0
      expect(qs.kept_score).to eq 0
      expect(qs.versions.count).to eq 2

      qs.update_scores({:submission_version_number => 1, :fudge_points => 10, :question_score_1 => 0})
      expect(qs.score).to eq 0
      expect(qs.kept_score).to eq 10
      expect(qs.versions.get(1).model.score).to eq 10
      expect(qs.versions.current.model.score).to eq 0
    end

    it "should allow updating scores on a completed version of a submission while the current version is in progress" do
      qs = @quiz.generate_submission(@student)
      qs.submission_data = { "question_1" => "2405" }
      Quizzes::SubmissionGrader.new(qs).grade_submission

      qs = @quiz.generate_submission(@student)
      qs.backup_submission_data({ "question_1" => "" }) # simulate k/v pairs we store for quizzes in progress
      expect(qs.reload.attempt).to eq 2

      expect { qs.update_scores }.to raise_error
      expect { qs.update_scores(:submission_version_number => 1, :fudge_points => 1, :question_score_1 => 0) }.not_to raise_error

      expect(qs).to be_untaken
      expect(qs.score).to be_nil
      expect(qs.kept_score).to eq 1

      v = qs.versions.current.model
      expect(v.score).to eq 1
      expect(v.fudge_points).to eq 1
    end

    it "should keep kept_score up-to-date when score changes while quiz is being re-taken" do
      qs = @quiz.generate_submission(@user)
      qs.submission_data = { "question_1" => "2405" }
      Quizzes::SubmissionGrader.new(qs).grade_submission
      expect(qs.kept_score).to eq 0

      qs = @quiz.generate_submission(@user)
      qs.backup_submission_data({ "foo" => "bar2" }) # simulate k/v pairs we store for quizzes in progress
      qs.reload

      qs.update_scores(:submission_version_number => 1, :fudge_points => 3)
      qs.reload

      expect(qs).to be_untaken
      # score is nil because the current attempt is still in progress
      # but kept_score is 3 because that's the higher score of the previous attempt
      expect(qs.score).to be_nil
      expect(qs.kept_score).to eq 3
    end
  end

  it "should not allowed grading on an already-graded submission" do
    q = @quiz.quiz_submissions.create!
    q.workflow_state = "complete"
    q.save!

    expect(q.workflow_state).to eql("complete")
    expect(q.state).to eql(:complete)
    q.write_attribute(:submission_data, [])
    res = false
    begin
      res = Quizzes::SubmissionGrader.new(q).grade_submission
      expect(0).to eql(1)
    rescue => e
      expect(e.to_s).to match(Regexp.new("Can't grade an already-submitted submission"))
    end
    expect(res).to eql(false)
  end

  context "explicitly setting grade" do

    before(:once) do
      course_with_student
      @quiz = @course.quizzes.create!
      @quiz.generate_quiz_data
      @quiz.published_at = Time.now
      @quiz.workflow_state = 'available'
      @quiz.scoring_policy = "keep_highest"
      @quiz.save!
      @assignment = @quiz.assignment
      @quiz_sub = @quiz.generate_submission @user, false
      @quiz_sub.workflow_state = "complete"
      @quiz_sub.save!
      @quiz_sub.score = 5
      @quiz_sub.fudge_points = 0
      @quiz_sub.kept_score = 5
      @quiz_sub.with_versioning(true, &:save!)
      @submission = @quiz_sub.submission
    end

    it "it should adjust the fudge points" do
      @assignment.grade_student(@user, {:grade => 3})

      @quiz_sub.reload
      expect(@quiz_sub.score).to eq 3
      expect(@quiz_sub.kept_score).to eq 3
      expect(@quiz_sub.fudge_points).to eq -2
      expect(@quiz_sub.manually_scored).not_to be_truthy

      @submission.reload
      expect(@submission.score).to eq 3
      expect(@submission.grade).to eq "3"
    end

    it "should use the explicit grade even if it isn't the highest score" do
      @quiz_sub.score = 4.0
      @quiz_sub.attempt = 2
      @quiz_sub.with_versioning(true, &:save!)

      @quiz_sub.reload
      expect(@quiz_sub.score).to eq 4
      expect(@quiz_sub.kept_score).to eq 5
      expect(@quiz_sub.manually_scored).not_to be_truthy
      @submission.reload
      expect(@submission.score).to eq 5
      expect(@submission.grade).to eq "5"

      @assignment.grade_student(@user, {:grade => 3})
      @quiz_sub.reload
      expect(@quiz_sub.score).to eq 3
      expect(@quiz_sub.kept_score).to eq 3
      expect(@quiz_sub.fudge_points).to eq -1
      expect(@quiz_sub.manually_scored).to be_truthy
      @submission.reload
      expect(@submission.score).to eq 3
      expect(@submission.grade).to eq "3"
    end

    it "should not have manually_scored set when updated normally" do
      @quiz_sub.score = 4.0
      @quiz_sub.attempt = 2
      @quiz_sub.with_versioning(true, &:save!)
      @assignment.grade_student(@user, {:grade => 3})
      @quiz_sub.reload
      expect(@quiz_sub.manually_scored).to be_truthy

      @quiz_sub.update_scores(:fudge_points => 2)

      @quiz_sub.reload
      expect(@quiz_sub.score).to eq 2
      expect(@quiz_sub.kept_score).to eq 5
      expect(@quiz_sub.manually_scored).not_to be_truthy
      @submission.reload
      expect(@submission.score).to eq 5
      expect(@submission.grade).to eq "5"
    end

    it "should add a version to the submission" do
      @assignment.grade_student(@user, {:grade => 3})
      @submission.reload
      expect(@submission.versions.count).to eq 2
      expect(@submission.score).to eq 3
      @assignment.grade_student(@user, {:grade => 6})
      @submission.reload
      expect(@submission.versions.count).to eq 3
      expect(@submission.score).to eq 6
    end

    it "should only update the last completed quiz submission" do
      @quiz_sub.score = 4.0
      @quiz_sub.attempt = 2
      @quiz_sub.with_versioning(true, &:save!)
      @quiz.generate_submission(@user)
      @assignment.grade_student(@user, {:grade => 3})

      expect(@quiz_sub.reload.score).to be_nil
      expect(@quiz_sub.kept_score).to eq 3
      expect(@quiz_sub.manually_scored).to be_falsey

      last_version = @quiz_sub.versions.current.reload.model
      expect(last_version.score).to eq 3
      expect(last_version.manually_scored).to be_truthy
    end
  end

  it "should know if it is overdue" do
    now = Time.now
    q = @quiz.quiz_submissions.new
    q.end_at = now
    q.save!

    expect(q.overdue?).to eql(false)
    q.end_at = now - (3 * 60)
    q.save!
    expect(q.overdue?).to eql(false)

    expect(q.overdue?(true)).to eql(true)
    q.end_at = now - (6 * 60)
    q.save!
    expect(q.overdue?).to eql(true)
    expect(q.overdue?(true)).to eql(true)
  end

  it "should know if it is extendable" do
    @quiz.update_attribute(:time_limit, 10)
    now = Time.now.utc
    q = @quiz.quiz_submissions.new
    q.end_at = now

    expect(q.extendable?).to be_truthy
    q.end_at = now - 1.minute
    expect(q.extendable?).to be_truthy
    q.end_at = now - 30.minutes
    expect(q.extendable?).to be_truthy
    q.end_at = now - 90.minutes
    expect(q.extendable?).to be_falsey
  end

  it "should calculate score based on quiz scoring policy" do
    q = @course.quizzes.create!(:scoring_policy => "keep_latest")
    s = q.quiz_submissions.new
    s.workflow_state = "complete"
    s.score = 5.0
    s.attempt = 1
    s.with_versioning(true, &:save!)
    expect(s.score).to eql(5.0)
    expect(s.kept_score).to eql(5.0)

    s.score = 4.0
    s.attempt = 2
    s.with_versioning(true, &:save!)
    expect(s.version_number).to eql(2)
    expect(s.kept_score).to eql(4.0)

    q.update_attributes!(:scoring_policy => "keep_highest")
    s.reload
    s.score = 3.0
    s.attempt = 3
    s.with_versioning(true, &:save!)
    expect(s.kept_score).to eql(5.0)

    s.update_scores(:submission_version_number => 2, :fudge_points => 6.0)
    expect(s.kept_score).to eql(6.0)
  end

  it "should calculate highest score based on most recent version of an attempt" do
    q = @course.quizzes.create!(:scoring_policy => "keep_highest")
    s = q.quiz_submissions.new

    s.workflow_state = "complete"
    s.score = 5.0
    s.attempt = 1
    s.with_versioning(true, &:save!)
    expect(s.version_number).to eql(1)
    expect(s.score).to eql(5.0)
    expect(s.kept_score).to eql(5.0)

    # regrade
    s.score_before_regrade = 5.0
    s.score = 4.0
    s.attempt = 1
    s.with_versioning(true, &:save!)
    expect(s.version_number).to eql(2)
    expect(s.kept_score).to eql(4.0)

    # new attempt
    s.score = 3.0
    s.attempt = 2
    s.with_versioning(true, &:save!)
    expect(s.version_number).to eql(3)
    expect(s.kept_score).to eql(4.0)
  end

  describe "with an essay question" do
    before(:once) do
      quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}}]) do
        {
          "text_after_answers"            => "",
          "question_#{@questions[0].id}"  => "<p>Lorem ipsum answer.</p>",
          "context_id"                    => "#{@course.id}",
          "context_type"                  => "Course",
          "user_id"                       => "#{@user.id}",
          "quiz_id"                       => "#{@quiz.id}",
          "course_id"                     => "#{@course.id}",
          "question_text"                 => "Lorem ipsum question",
        }
      end
    end

    it "should leave a submission in pending_review state if there are essay questions" do
      expect(@quiz_submission.submission.workflow_state).to eql 'pending_review'
    end

    it "should mark a submission as complete once an essay question has been graded" do
      @quiz_submission.update_scores({
        'context_id' => @course.id,
        'override_scores' => true,
        'context_type' => 'Course',
        'submission_version_number' => '1',
        "question_score_#{@questions[0].id}" => '1'
      })
      expect(@quiz_submission.submission.workflow_state).to eql 'graded'
    end

    it "should increment the assignment needs_grading_count for pending_review state" do
      expect(@quiz.assignment.reload.needs_grading_count).to eq 1
    end

    it "should not increment the assignment needs_grading_count if graded when a second attempt starts" do
      @quiz_submission.update_scores({
        'context_id' => @course.id,
        'override_scores' => true,
        'context_type' => 'Course',
        'submission_version_number' => '1',
        "question_score_#{@questions[0].id}" => '1'
      })
      expect(@quiz.assignment.reload.needs_grading_count).to eq 0
      @quiz.generate_submission(@user)
      expect(@quiz_submission.reload).to be_untaken
      expect(@quiz_submission.submission).to be_graded
      expect(@quiz.assignment.reload.needs_grading_count).to eq 0
    end

    it "should not decrement the assignment needs_grading_count if pending_review when a second attempt starts" do
      expect(@quiz.assignment.reload.needs_grading_count).to eq 1
      @quiz.generate_submission(@user)
      expect(@quiz_submission.reload).to be_untaken
      expect(@quiz_submission.submission).to be_pending_review
      expect(@quiz.assignment.reload.needs_grading_count).to eq 1
    end
  end

  describe "with multiple essay questions" do
    before(:once) do
      quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}},
                                   {:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'essay_question'}}]) do
        {
          "text_after_answers"            => "",
          "question_#{@questions[0].id}"  => "<p>Lorem ipsum answer 1.</p>",
          "question_#{@questions[1].id}"  => "<p>Lorem ipsum answer 2.</p>",
          "context_id"                    => "#{@course.id}",
          "context_type"                  => "Course",
          "user_id"                       => "#{@user.id}",
          "quiz_id"                       => "#{@quiz.id}",
          "course_id"                     => "#{@course.id}",
          "question_text"                 => "Lorem ipsum question",
        }
      end
    end

    it "should not mark a submission complete if there are essay questions without grades" do
      @quiz_submission.update_scores({
        'context_id' => @course.id,
        'override_scores' => true,
        'context_type' => 'Course',
        'submission_version_number' => '1',
        "question_score_#{@questions[0].id}" => '1',
        "question_score_#{@questions[1].id}" => "--"
      })
      expect(@quiz_submission.submission.workflow_state).to eql 'pending_review'
    end

    it "should mark a submission complete if all essay questions have been graded" do
      @quiz_submission.update_scores({
        'context_id' => @course.id,
        'override_scores' => true,
        'context_type' => 'Course',
        'submission_version_number' => '1',
        "question_score_#{@questions[0].id}" => '1',
        "question_score_#{@questions[1].id}" => "0"
      })
      expect(@quiz_submission.submission.workflow_state).to eql 'graded'
    end
  end

  context "update_assignment_submission" do
    before(:once) do
      student_in_course
      @quiz.generate_quiz_data
      @quiz.published_at = Time.now
      @quiz.workflow_state = 'available'
      @quiz.scoring_policy = "keep_highest"
      @quiz.due_at = 5.days.from_now
      @quiz.save!
      @assignment = @quiz.assignment
      @quiz_sub = @quiz.generate_submission @user, false
      @quiz_sub.workflow_state = "complete"
      @quiz_sub.save!
      @quiz_sub.score = 5
      @quiz_sub.fudge_points = 0
      @quiz_sub.kept_score = 5
      @quiz_sub.with_versioning(true, &:save!)
      @submission = @quiz_sub.submission
    end

    it "should sync the score" do
      expect(@submission.score).to eql(5.0)
    end

    it "should not set graded_at to be in the future" do
      expect(@submission.graded_at.to_i).to be <= Time.zone.now.to_i
    end
  end

  describe "learning outcomes" do
    it "should create learning outcome results when aligned to assessment questions" do
      course_with_student(:active_all => true)
      @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      @q1 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '1', 'answer_weight' => '100'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'}]})
      @q2 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '1', 'answer_weight' => '100'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'}]})
      @outcome = @course.created_learning_outcomes.create!(:short_description => 'new outcome')
      @bank = @q1.assessment_question.assessment_question_bank
      @outcome.align(@bank, @bank.context, :mastery_score => 0.7)
      expect(@bank.learning_outcome_alignments.length).to eql(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      answer_1 = @q1.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      answer_2 = @q2.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      @quiz.generate_quiz_data(:persist => true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      question_1 = @q1.data[:id]
      question_2 = @q2.data[:id]
      @sub.submission_data["question_#{question_1}"] = answer_1
      @sub.submission_data["question_#{question_2}"] = answer_2 + 1
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to eql(1.0)
      @outcome.reload
      @results = @outcome.learning_outcome_results.where(user_id: @user).to_a
      expect(@results.length).to eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to eql(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to eql(false)
    end

    it "should update learning outcome results when aligned to assessment questions" do
      course_with_student(:active_all => true)
      @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      @q1 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '1', 'answer_weight' => '100'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'}]})
      @q2 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => [{'answer_text' => '1', 'answer_weight' => '100'}, {'answer_text' => '2'}, {'answer_text' => '3'}, {'answer_text' => '4'}]})
      @outcome = @course.created_learning_outcomes.create!(:short_description => 'new outcome')
      @bank = @q1.assessment_question.assessment_question_bank
      @outcome.align(@bank, @bank.context, :mastery_score => 0.7)
      expect(@bank.learning_outcome_alignments.length).to eql(1)
      expect(@q2.assessment_question.assessment_question_bank).to eql(@bank)
      answer_1 = @q1.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      answer_2 = @q2.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      @quiz.generate_quiz_data(:persist => true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      question_1 = @q1.data[:id]
      question_2 = @q2.data[:id]
      @sub.submission_data["question_#{question_1}"] = answer_1
      @sub.submission_data["question_#{question_2}"] = answer_2 + 1
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to eql(1.0)
      @outcome.reload
      @results = @outcome.learning_outcome_results.where(user_id: @user).to_a
      expect(@results.length).to eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to eql(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to eql(false)
      @sub = @quiz.generate_submission(@user)
      expect(@sub.attempt).to eql(2)
      @sub.submission_data = {}
      question_1 = @q1.data[:id]
      question_2 = @q2.data[:id]
      @sub.submission_data["question_#{question_1}"] = answer_1 + 1
      @sub.submission_data["question_#{question_2}"] = answer_2
      Quizzes::SubmissionGrader.new(@sub).grade_submission
      expect(@sub.score).to eql(1.0)
      @outcome.reload
      @results = @outcome.learning_outcome_results.where(user_id: @user).to_a
      expect(@results.length).to eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      expect(@results.first.associated_asset).to eql(@q1.assessment_question)
      expect(@results.first.mastery).to eql(false)
      expect(@results.first.original_mastery).to eql(true)
      expect(@results.last.associated_asset).to eql(@q2.assessment_question)
      expect(@results.last.mastery).to eql(true)
      expect(@results.last.original_mastery).to eql(false)
    end
  end


  describe "#score_to_keep" do
    before(:once) do
      student_in_course
      assignment_quiz([])
      qd = multiple_choice_question_data
      @quiz.quiz_data = [qd]
      @quiz.points_possible = qd[:points_possible]
      @quiz.save!
    end

    context "keep_highest" do
      before(:once) do
        @quiz.scoring_policy = "keep_highest"
        @quiz.save!
      end

      it "should be nil during first in-progress submission" do
        qs = @quiz.generate_submission(@student)
        expect(qs.score_to_keep).to be_nil
      end

      it "should be the submission score for one complete submission" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        expect(qs.score_to_keep).to eq @quiz.points_possible
      end

      it "should be correct for multiple complete versions" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        expect(qs.score_to_keep).to eq @quiz.points_possible
      end

      it "should be correct for multiple versions, current version in progress" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        qs = @quiz.generate_submission(@student)
        expect(qs.score_to_keep).to eq @quiz.points_possible
      end
    end

    context "keep_latest" do
      before(:once) do
        @quiz.scoring_policy = "keep_latest"
        @quiz.save!
      end

      it "should be nil during first in-progress submission" do
        qs = @quiz.generate_submission(@student)
        expect(qs.score_to_keep).to be_nil
      end

      it "should be the submission score for one complete submission" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        expect(qs.score_to_keep).to eq @quiz.points_possible
      end

      it "should be correct for multiple complete versions" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        expect(qs.score_to_keep).to eq 0
      end

      it "should be correct for multiple versions, current version in progress" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission
        qs = @quiz.generate_submission(@student)
        expect(qs.score_to_keep).to eq 0
      end
    end
  end

  context "permissions" do
    it "should allow read to observers" do
      course_with_student(:active_all => true)
      @observer = user
      oe = @course.enroll_user(@observer, 'ObserverEnrollment', :enrollment_state => 'active')
      oe.update_attribute(:associated_user, @user)
      @quiz = @course.quizzes.create!
      qs = @quiz.generate_submission(@user)
      expect(qs.grants_right?(@observer, :read)).to be_truthy
    end

    it "allows users with the manage_grades permission but not 'manage' permission to update scores and add attempts" do
      RoleOverride.create!(
        context: Account.default,
        enrollment_type: 'TeacherEnrollment',
        permission: 'manage_assignments',
        enabled: false
      )
      course_with_teacher(active_all: true)
      course_quiz(course: @course)
      student_in_course(course: @course)
      qs = @quiz.generate_submission(@student)
      expect(qs.grants_right?(@teacher, :update_scores)).to eq true
      expect(qs.grants_right?(@teacher, :add_attempts)).to eq true
    end
  end

  describe "#question" do
    let(:submission) { @quiz.quiz_submissions.build }
    let(:question1) { {:id => 1} }
    let(:question2) { {:id => 2} }
    let(:questions) { [question1, question2] }

    before do
      submission.stubs(:questions).returns(questions)
    end

    it "returns the question matching the passed in ID" do
      expect(submission.question(1)).to eq question1
    end

    it "casts the ID to an integer" do
      expect(submission.question('2')).to eq question2
    end

    it "returns nil when not found" do
      expect(submission.question(3)).to be_nil
    end

    describe "has_question?" do
      it "returns true when it has a question identified by the ID" do
        expect(submission.has_question?(1)).to be_truthy
      end

      it "returns false when the question cannot be found" do
        expect(submission.has_question?(3)).to be_falsey
      end
    end
  end

  describe "#question_answered?" do
    let(:submission) { @quiz.quiz_submissions.build }

    before do
      submission.stubs(:temporary_data).returns \
        'question_1' => 'A',
        'question_2' => '',
        'question_3_123456abcdefghijklmnopqrstuvwxyz' => 'A',
        'question_3_654321abcdefghijklmnopqrstuvwxyz' => 'B',
        'question_4_123456abcdefghijklmnopqrstuvwxyz' => 'A',
        'question_4_654321abcdefghijklmnopqrstuvwxyz' => '',
        'question_5_123456abcdefghijklmnopqrstuvwxyz' => '',
        'question_5_654321abcdefghijklmnopqrstuvwxyz' => '',
        'question_6_answer_5231'=>'7700',
        'question_6_answer_3055'=>'3037',
        'question_6_answer_7094'=>'9976',
        'question_6_answer_6346'=>'6392',
        'question_7_answer_5231'=>'7700',
        'question_7_answer_3055'=>'',
        'question_7_answer_7094'=>'9976',
        'question_7_answer_6346'=>'',
        'question_8_answer_123' => '0',
        'question_8_answer_234' => '0',
        'question_8_answer_345' => '0',
        'question_9_answer_123' => '0',
        'question_9_answer_234' => '1',
        'question_9_answer_345' => '1'
    end

    context "on a single answer question" do
      context "when answered" do
        it "returns true" do
          expect(submission.question_answered?(1)).to be_truthy
        end
      end

      context "when not answered" do
        it "returns false" do
          expect(submission.question_answered?(2)).to be_falsey
        end
      end
    end

    context "on a fill in multiple blanks question" do
      context "when all answered" do
        it "returns true" do
          expect(submission.question_answered?(3)).to be_truthy
        end
      end

      context "when some answered" do
        it "returns false" do
          expect(submission.question_answered?(4)).to be_falsey
        end
      end

      context "when none answered" do
        it "returns false" do
          expect(submission.question_answered?(5)).to be_falsey
        end
      end
    end

    context "on a matching question" do
      context "when all answered" do
        it "returns true" do
          expect(submission.question_answered?(6)).to be_truthy
        end
      end

      context "when some answered" do
        it "returns false" do
          expect(submission.question_answered?(7)).to be_falsey
        end
      end
    end

    context "on a multiple answers question" do
      context "when none answered" do
        it "returns false" do
          expect(submission.question_answered?(8)).to be_falsey
        end
      end

      context "when answers selected" do
        it "returns true" do
          expect(submission.question_answered?(9)).to be_truthy
        end
      end
    end

    context "with no response recorded yet" do
      it "returns false" do
        expect(submission.question_answered?(100)).to be_falsey
      end
    end
  end

  describe "#results_visible?" do
    it "return true if no quiz" do
      qs = Quizzes::QuizSubmission.new
      expect(qs.results_visible?).to be_truthy
    end

    it "returns false if quiz restricts answers for concluded courses" do
      quiz = Quizzes::Quiz.new
      quiz.stubs(:restrict_answers_for_concluded_course? => true)

      qs = Quizzes::QuizSubmission.new(:quiz => quiz)
      expect(qs.results_visible?).to be_falsey
    end

    it "returns true if quiz doesn't restrict answers for concluded courses" do
      quiz = Quizzes::Quiz.new
      quiz.stubs(:restrict_answers_for_concluded_course? => false)

      qs = Quizzes::QuizSubmission.new(:quiz => quiz)
      expect(qs.results_visible?).to be_truthy
    end

    it "returns false if results are locked down" do
      quiz = Quizzes::Quiz.new
      quiz.stubs(:restrict_answers_for_concluded_course? => false)
      quiz.stubs(:one_time_results => true)

      qs = Quizzes::QuizSubmission.new(:quiz => quiz)
      expect(qs.results_visible?).to be_truthy

      qs.stubs(:has_seen_results => true)
      expect(qs.results_visible?).to be_falsey
    end
  end

  describe "#update_submission_version" do
    let_once(:submission) { @quiz.quiz_submissions.create! }

    before do
      submission.with_versioning(true) do |s|
        s.score = 10
        s.save(:validate => false)
      end
      expect(submission.version_number).to eq 1

      submission.with_versioning(true) do |s|
        s.score = 15
        s.save(:validate => false)
      end
      expect(submission.version_number).to eq 2
    end

    it "updates a previous version given current attributes" do
      vs = submission.versions
      expect(vs.size).to eq 2

      submission.score = 25
      submission.update_submission_version(vs.last, [:score])
      expect(submission.versions.map{ |s| s.model.score }).to eq [15, 25]
    end

    context "when loading UTF-8 data" do
      it "should strip bad chars" do
        vs = submission.versions

        # inject bad byte into yaml
        submission.submission_data = ["bad\x81byte"]
        submission.update_submission_version(vs.last, [:submission_data])

        # reload yaml by setting a different column
        submission.score = 20
        submission.update_submission_version(vs.last, [:score])

        expect(submission.versions.map{ |s| s.model.submission_data }).to eq [nil, ["badbyte"]]
      end
    end

  end

  describe "#submitted_attempts" do
    let(:submission) { @quiz.quiz_submissions.build }

    before do
      Quizzes::SubmissionGrader.new(submission).grade_submission
    end

    it "should find regrade versions for a submission" do
      expect(submission.submitted_attempts.length).to eq 1
    end
  end

  describe "#attempts" do
    let(:quiz)       { @course.quizzes.create! }
    let(:submission) { quiz.quiz_submissions.new }

    it "should find attempt versions for a submission" do
      submission.workflow_state = "complete"
      submission.score = 5.0
      submission.attempt = 1
      submission.with_versioning(true, &:save!)
      expect(submission.version_number).to eql(1)
      expect(submission.score).to eql(5.0)

      # regrade
      submission.score_before_regrade = 5.0
      submission.score = 4.0
      submission.attempt = 1
      submission.with_versioning(true, &:save!)
      expect(submission.version_number).to eql(2)

      # new attempt
      submission.score = 3.0
      submission.attempt = 2
      submission.with_versioning(true, &:save!)
      expect(submission.version_number).to eql(3)

      attempts = submission.attempts
      expect(attempts).to be_a(Quizzes::QuizSubmissionHistory)
      expect(attempts.length).to eq 2

      first_attempt = attempts.first
      expect(first_attempt).to be_a(Quizzes::QuizSubmissionAttempt)

      expect(attempts.last_versions.map {|version| version.number }).to eq [2, 3]
    end
  end

  describe "#has_regrade?" do
    it "should be true if score before regrade is present" do
      expect(Quizzes::QuizSubmission.new(:score_before_regrade => 10).has_regrade?).to be_truthy
    end

    it "should be false if score before regrade is absent" do
      expect(Quizzes::QuizSubmission.new.has_regrade?).to be_falsey
    end
  end

  describe "#score_affected_by_regrade?" do
    it "should be true if score before regrade differs from current score" do
      submission = Quizzes::QuizSubmission.new(:score_before_regrade => 10)
      submission.kept_score = 5
      expect(submission.score_affected_by_regrade?).to be_truthy
    end

    it "should be false if score before regrade is the same as current score" do
      submission = Quizzes::QuizSubmission.new(:score_before_regrade => 10)
      submission.kept_score = 10
      expect(submission.score_affected_by_regrade?).to be_falsey
    end
  end

  describe "#needs_grading?" do
    before :once do
      student_in_course
      assignment_quiz([])
      qd = multiple_choice_question_data
      @quiz.quiz_data = [qd]
      @quiz.points_possible = qd[:points_possible]
      @quiz.save!
    end

    context "with strict passed as true" do
      it "returns true if it's overdue" do
        @quiz.due_at = 3.hours.ago
        @quiz.save!

        submission = @quiz.generate_submission(@student)
        submission.end_at = @quiz.due_at
        expect(submission.needs_grading?(true)).to be_truthy
      end

      it "returns false if it isn't overdue" do
        @quiz.due_at = Time.now + 1.hour
        @quiz.save!

        submission = @quiz.generate_submission(@student)
        expect(submission.needs_grading?(true)).to be_falsey
      end
    end

    context "with strict passed as false" do
      it "returns true if it's untaken and has passed its time limit" do
        @quiz.time_limit = 1
        @quiz.save!

        submission = nil
        Timecop.freeze(5.minutes.ago) do
          submission = @quiz.generate_submission(@student)
        end

        expect(submission.needs_grading?).to be_truthy
      end

      it "returns true if it's completed and has an ungraded submission_data" do
        submission = @quiz.generate_submission(@student)
        submission.stubs(:completed?).returns(true)
        expect(submission.needs_grading?).to be_truthy
      end

      it "returns false if it has already been graded" do
        submission = @quiz.generate_submission(@student)
        Quizzes::SubmissionGrader.new(submission).grade_submission
        submission.save!

        expect(submission.needs_grading?).to be_falsey
      end

      it "returns false if it's untaken and hasn't passed its time limit" do
        @quiz.time_limit = 60
        @quiz.save!

        submission = @quiz.generate_submission(@student)
        expect(submission.needs_grading?).to be_falsey
      end
    end

  end
  describe "#needs_grading" do
    before :once do
      student_in_course
      assignment_quiz([])
      qd = multiple_choice_question_data
      @quiz.quiz_data = [qd]
      @quiz.points_possible = qd[:points_possible]
      @quiz.due_at = 3.hours.ago
      @quiz.save!
    end
    before :each do
      @submission = @quiz.generate_submission(@student)
      @submission.end_at = @quiz.due_at
      @submission.save!
      @resp = Quizzes::QuizSubmission.needs_grading
    end
    it "finds an outstanding submissions" do
      expect(@resp.size).to eq 1
    end
    it "returns quiz_submission information" do
      expect(@resp.first).to be_a(Quizzes::QuizSubmission)
      expect(@resp.first.id).to eq @submission.id
    end
    it "returns user information" do
      expect(@resp.first.user).to be_a(User)
      expect(@resp.first.user.id).to eq @student.id
    end
    it "returns items which require grading" do
      expect(@resp.map(&:needs_grading?).all?).to be true
    end
  end

  describe "#questions_regraded_since_last_attempt" do
    before :once do
      @quiz = @course.quizzes.create! title: 'Test Quiz'
      course_with_teacher_logged_in(active_all: true, course: @course)

      @submission = @quiz.quiz_submissions.build
      @submission.workflow_state = "complete"
      @submission.score = 5.0
      @submission.attempt = 1
      @submission.with_versioning(true, &:save!)
      expect(@submission.version_number).to eql(1)
      expect(@submission.score).to eql(5.0)
      @submission.save
    end

    it "should pass the date from the first version of the most recent attempt to quiz#questions_regraded_since" do
      @submission.quiz.expects(:questions_regraded_since)
      @submission.questions_regraded_since_last_attempt
    end

  end

  it "does not put a graded survey submission in teacher's todos" do
    questions = [
      { question_data: { name: 'question 1', question_type: 'essay_question' } }
    ]
    submission_data = { 'question_1' => 'Hello' }
    survey_with_submission(questions) { submission_data }
    teacher_in_course(course: @course, active_all: true)
    @quiz.update_attributes(points_possible: 15, quiz_type: 'graded_survey')
    Quizzes::SubmissionGrader.new(@quiz_submission.reload).grade_submission

    expect(@quiz_submission).to be_completed
    expect(@quiz_submission.submission).to be_graded
    expect(@teacher.assignments_needing_grading).not_to include @quiz.assignment
  end

  describe 'broadcast policy' do
    before :once do
      Notification.create(:name => 'Submission Graded')
      Notification.create(:name => 'Submission Grade Changed')
      Notification.create(:name => 'Submission Needs Grading')
      student_in_course
      assignment_quiz([])
      @course.enroll_student(@student)
      @submission = @quiz.generate_submission(@student)
    end

    it 'sends a graded notification after grading the quiz submission' do
      expect(@submission.messages_sent).not_to include 'Submission Graded'
      Quizzes::SubmissionGrader.new(@submission).grade_submission
      expect(@submission.reload.messages_sent.keys).to include 'Submission Graded'
    end

    it 'sends a grade changed notification after re-grading the quiz submission' do
      Quizzes::SubmissionGrader.new(@submission).grade_submission
      @submission.score = @submission.score + 5
      @submission.save!
      expect(@submission.reload.messages_sent.keys).to include('Submission Grade Changed')
    end

    it 'does not send any "graded" or "grade changed" notifications for a submission with essay questions before they have been graded' do
      quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}}])
      expect(@quiz_submission.reload.messages_sent).not_to include 'Submission Graded'
      expect(@quiz_submission.reload.messages_sent).not_to include 'Submission Grade Changed'
    end

    it 'sends a notifications for a submission with essay questions before they have been graded if manually graded' do
      quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}}])
      @quiz_submission.set_final_score(2)
      expect(@quiz_submission.reload.messages_sent.keys).to include 'Submission Graded'
    end

    it 'sends a notification if the submission needs manual review' do
      teacher_in_course
      @course.enroll_teacher(@teacher)
      quiz_with_graded_submission([{:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'essay_question'}}])
      expect(@quiz_submission.reload.messages_sent.keys).to include 'Submission Needs Grading'
    end
    it 'does not send a notification if the submission does not need manual review' do
      teacher_in_course
      @course.enroll_teacher(@teacher)
      @submission.workflow_state = 'completed'; @submission.save!
      expect(@submission.reload.messages_sent.keys).not_to include 'Submission Needs Grading'
    end
  end
  end

  describe "#time_spent" do
    it "should return nil if there's no finished_at" do
      subject.finished_at = nil
      expect(subject.time_spent).to be_nil
    end

    it "should return the correct time spent in seconds" do
      anchor = Time.now

      subject.started_at = anchor
      subject.finished_at = anchor + 1.hour
      expect(subject.time_spent).to eql(1.hour.to_i)
    end

    it "should account for extra time" do
      anchor = Time.now

      subject.started_at = anchor
      subject.finished_at = anchor + 1.hour
      subject.extra_time = 5.minutes

      expect(subject.time_spent).to eql((1.hour + 5.minutes).to_i)
    end
  end

  describe "#time_left" do
    it "should return nil if there's no end_at" do
      subject.end_at = nil
      expect(subject.time_left).to be_nil
    end

    it "should return the correct time left in seconds" do
      subject.end_at = 1.hour.from_now
      expect(subject.time_left).to eql(60 * 60)
    end
  end

  describe '#retriable?' do
    it 'should not be retriable by default' do
      subject.stubs(:attempts_left).returns 0
      expect(subject.retriable?).to be_falsey
    end

    it 'should not be retriable unless it is complete' do
      subject.stubs(:attempts_left).returns 3
      expect(subject.retriable?).to be_falsey
    end

    it 'should be retriable if it is a preview QS' do
      subject.workflow_state = 'preview'
      expect(subject.retriable?).to be_truthy
    end

    it 'should be retriable if it is a settings only QS' do
      subject.workflow_state = 'settings_only'
      expect(subject.retriable?).to be_truthy
    end

    it 'should be retriable if it is complete and has attempts left to spare' do
      subject.workflow_state = 'complete'
      subject.stubs(:attempts_left).returns 3
      expect(subject.retriable?).to be_truthy
    end

    it 'should be retriable if it is complete and the quiz has unlimited attempts' do
      subject.workflow_state = 'complete'
      subject.stubs(:attempts_left).returns 0
      subject.quiz = Quizzes::Quiz.new
      subject.quiz.stubs(:unlimited_attempts?).returns true
      expect(subject.retriable?).to be_truthy
    end
  end

  describe '#snapshot!' do
    before :each do
      subject.quiz = Quizzes::Quiz.new
      subject.attempt = 1
    end

    it 'should generate a snapshot' do
      snapshot_data = { 'question_5_marked' => true }

      Quizzes::QuizSubmissionSnapshot.expects(:create).with({
        quiz_submission: subject,
        attempt: 1,
        data: snapshot_data.with_indifferent_access
      })

      subject.snapshot! snapshot_data
    end

    it 'should generate a full snapshot' do
      subject.stubs(:submission_data).returns({
        'question_5' => 100
      })

      snapshot_data = { 'question_5_marked' => true }

      Quizzes::QuizSubmissionSnapshot.expects(:create).with({
        quiz_submission: subject,
        attempt: 1,
        data: snapshot_data.merge(subject.submission_data).with_indifferent_access
      })

      subject.snapshot! snapshot_data, true
    end
  end

  context "with versioning" do
    before(:each) do
      student_in_course
      assignment_quiz([])
      qd = multiple_choice_question_data
      @quiz.quiz_data = [qd]
      @quiz.points_possible = qd[:points_possible]
      @quiz.save!
    end

    describe "#versions" do
      it "finds the versions with both namespaced and non-namespaced quizzes" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "8544" }
        Quizzes::SubmissionGrader.new(qs).grade_submission

        expect(qs.versions.count).to eq 2
        Version.update_all("versionable_type='QuizSubmission'","versionable_id=#{qs.id} AND versionable_type='Quizzes::QuizSubmission'")
        expect(Quizzes::QuizSubmission.find(qs).versions.count).to eq 2
      end
    end
  end

  context "with attachments" do
    before(:each) do
      course_with_student_logged_in :active_all => true
      course_quiz !!:active
      @qs = @quiz.generate_submission @user
      create_attachment_for_file_upload_submission!(@qs)
    end

    describe "#attachments" do
      it "finds the attachment with both namespaced and non-namespaced quizzes" do
        expect(Quizzes::QuizSubmission.find(@qs).attachments.count).to eq 1

        Attachment.update_all("context_type='QuizSubmission'","context_id=#{@qs.id} AND context_type='Quizzes::QuizSubmission'")
        expect(Quizzes::QuizSubmission.find(@qs).attachments.count).to eq 1
      end
    end
  end

  describe '#points_possible_at_submission_time' do
    it 'should work' do
      quiz_with_graded_submission([
        {
          question_data: {
            name: 'question 1',
            points_possible: 0.23,
            question_type: 'essay_question'
          }
        },
        {
          question_data: {
            name: 'question 2',
            points_possible: 0.42,
            question_type: 'essay_question'
          }
        }
      ])

      expect(@quiz_submission.points_possible_at_submission_time).to eq 0.65
    end
  end
end
