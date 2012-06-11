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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe QuizSubmission do
  before(:each) do
    course
    @quiz = @course.quizzes.create!
  end

  it "should copy the quiz's points_possible whenever it's saved" do
    Quiz.update_all("points_possible = 1.1", "id = #{@quiz.id}")
    q = @quiz.quiz_submissions.create!
    q.reload.quiz_points_possible.should eql 1.1

    Quiz.update_all("points_possible = 1.9", "id = #{@quiz.id}")
    q.reload.quiz_points_possible.should eql 1.1

    q.save!
    q.reload.quiz_points_possible.should eql 1.9
  end

  it "should not lose time" do
    @quiz.update_attribute(:time_limit, 10)
    q = @quiz.quiz_submissions.create!
    q.update_attribute(:started_at, Time.now)
    original_end_at = q.end_at

    @quiz.update_attribute(:time_limit, 5)
    @quiz.update_quiz_submission_end_at_times

    q.reload
    q.end_at.should eql original_end_at
  end

  describe "#update_scores" do
    before(:each) do
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
      qs.grade_submission

      # sanity check
      qs.reload
      qs.score.should == 50
      qs.kept_score.should == 50

      qs.update_scores({:fudge_points => -5, :question_score_1 => 50})
      qs.score.should == 45
      qs.fudge_points.should == -5
      qs.kept_score.should == 45
      v = qs.versions.current.model
      v.score.should == 45
      v.fudge_points.should == -5
    end

    it "should not allow updating scores on an uncompleted submission" do
      qs = @quiz.generate_submission(@student)
      qs.should be_untaken
      lambda { qs.update_scores }.should raise_error
    end

    it "should update scores for a previous submission" do
      qs = @quiz.generate_submission(@student)
      qs.submission_data = { "question_1" => "2405" }
      qs.grade_submission

      qs = @quiz.generate_submission(@student)
      qs.submission_data = { "question_1" => "8544" }
      qs.grade_submission

      # sanity check
      qs.score.should == 0
      qs.kept_score.should == 0
      qs.versions.count.should == 2

      qs.update_scores({:submission_version_number => 1, :fudge_points => 10, :question_score_1 => 0})
      qs.score.should == 0
      qs.kept_score.should == 10
      qs.versions.get(1).model.score.should == 10
      qs.versions.current.model.score.should == 0
    end

    it "should allow updating scores on a completed version of a submission while the current version is in progress" do
      qs = @quiz.generate_submission(@student)
      qs.submission_data = { "question_1" => "2405" }
      qs.grade_submission

      qs = @quiz.generate_submission(@student)
      qs.backup_submission_data({ "question_1" => "" }) # simulate k/v pairs we store for quizzes in progress
      qs.reload.attempt.should == 2

      lambda { qs.update_scores }.should raise_error
      lambda { qs.update_scores(:submission_version_number => 1, :fudge_points => 1, :question_score_1 => 0) }.should_not raise_error

      qs.should be_untaken
      qs.score.should be_nil
      qs.kept_score.should == 1

      v = qs.versions.current.model
      v.score.should == 1
      v.fudge_points.should == 1
    end

    it "should keep kept_score up-to-date when score changes while quiz is being re-taken" do
      qs = @quiz.generate_submission(@user)
      qs.submission_data = { "question_1" => "2405" }
      qs.grade_submission
      qs.kept_score.should == 0

      qs = @quiz.generate_submission(@user)
      qs.backup_submission_data({ "foo" => "bar2" }) # simulate k/v pairs we store for quizzes in progress
      qs.reload

      qs.update_scores(:submission_version_number => 1, :fudge_points => 3)
      qs.reload

      qs.should be_untaken
      # score is nil because the current attempt is still in progress
      # but kept_score is 3 because that's the higher score of the previous attempt
      qs.score.should be_nil
      qs.kept_score.should == 3
    end
  end

  it "should not allowed grading on an already-graded submission" do
    q = @quiz.quiz_submissions.create!
    q.workflow_state = "complete"
    q.save!

    q.workflow_state.should eql("complete")
    q.state.should eql(:complete)
    q.write_attribute(:submission_data, [])
    res = false
    begin
      res = q.grade_submission
      0.should eql(1)
    rescue => e
      e.to_s.should match(Regexp.new("Can't grade an already-submitted submission"))
    end
    res.should eql(false)
  end
  
  context "explicitly setting grade" do
    
    before(:each) do
      course_with_student
      @quiz = @course.quizzes.create!
      @quiz.generate_quiz_data
      @quiz.published_at = Time.now
      @quiz.workflow_state = 'available'
      @quiz.scoring_policy == "keep_highest"
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
      @quiz_sub.score.should == 3
      @quiz_sub.kept_score.should == 3
      @quiz_sub.fudge_points.should == -2
      @quiz_sub.manually_scored.should_not be_true
      
      @submission.reload
      @submission.score.should == 3
      @submission.grade.should == "3"
    end
    
    it "should use the explicit grade even if it isn't the highest score" do
      @quiz_sub.score = 4.0
      @quiz_sub.attempt = 2
      @quiz_sub.with_versioning(true, &:save!)
      
      @quiz_sub.reload
      @quiz_sub.score.should == 4
      @quiz_sub.kept_score.should == 5
      @quiz_sub.manually_scored.should_not be_true
      @submission.reload
      @submission.score.should == 5
      @submission.grade.should == "5"
      
      @assignment.grade_student(@user, {:grade => 3})
      @quiz_sub.reload
      @quiz_sub.score.should == 3
      @quiz_sub.kept_score.should == 3
      @quiz_sub.fudge_points.should == -1
      @quiz_sub.manually_scored.should be_true
      @submission.reload
      @submission.score.should == 3
      @submission.grade.should == "3"
    end
    
    it "should not have manually_scored set when updated normally" do
      @quiz_sub.score = 4.0
      @quiz_sub.attempt = 2
      @quiz_sub.with_versioning(true, &:save!)
      @assignment.grade_student(@user, {:grade => 3})
      @quiz_sub.reload
      @quiz_sub.manually_scored.should be_true
      
      @quiz_sub.update_scores(:fudge_points => 2)
      
      @quiz_sub.reload
      @quiz_sub.score.should == 2
      @quiz_sub.kept_score.should == 5
      @quiz_sub.manually_scored.should_not be_true
      @submission.reload
      @submission.score.should == 5
      @submission.grade.should == "5"
    end
    
    it "should add a version to the submission" do
      @assignment.grade_student(@user, {:grade => 3})
      @submission.reload
      @submission.versions.count.should == 2
      @submission.score.should == 3
      @assignment.grade_student(@user, {:grade => 6})
      @submission.reload
      @submission.versions.count.should == 3
      @submission.score.should == 6
    end

    it "should only update the last completed quiz submission" do
      @quiz_sub.score = 4.0
      @quiz_sub.attempt = 2
      @quiz_sub.with_versioning(true, &:save!)
      @quiz.generate_submission(@user)
      @assignment.grade_student(@user, {:grade => 3})

      @quiz_sub.reload.score.should be_nil
      @quiz_sub.kept_score.should == 3
      @quiz_sub.manually_scored.should be_false

      last_version = @quiz_sub.versions.current.reload.model
      last_version.score.should == 3
      last_version.manually_scored.should be_true
    end
  end

  it "should know if it is overdue" do
    now = Time.now
    q = @quiz.quiz_submissions.new
    q.end_at = now
    q.save!

    q.overdue?.should eql(false)
    q.end_at = now - (3 * 60)
    q.save!
    q.overdue?.should eql(false)

    q.overdue?(true).should eql(true)
    q.end_at = now - (6 * 60)
    q.save!
    q.overdue?.should eql(true)
    q.overdue?(true).should eql(true)
  end

  it "should know if it is extendable" do
    @quiz.update_attribute(:time_limit, 10)
    now = Time.now.utc
    q = @quiz.quiz_submissions.new
    q.end_at = now

    q.extendable?.should be_true
    q.end_at = now - 1.minute
    q.extendable?.should be_true
    q.end_at = now - 30.minutes
    q.extendable?.should be_true
    q.end_at = now - 90.minutes
    q.extendable?.should be_false
  end

  it "should calculate score based on quiz scoring policy" do
    q = @course.quizzes.create!(:scoring_policy => "keep_latest")
    s = q.quiz_submissions.new
    s.workflow_state = "complete"
    s.score = 5.0
    s.attempt = 1
    s.with_versioning(true, &:save!)
    s.score.should eql(5.0)
    s.kept_score.should eql(5.0)

    s.score = 4.0
    s.attempt = 2
    s.with_versioning(true, &:save!)
    s.version_number.should eql(2)
    s.kept_score.should eql(4.0)

    q.update_attributes!(:scoring_policy => "keep_highest")
    s.reload
    s.score = 3.0
    s.attempt = 3
    s.with_versioning(true, &:save!)
    s.kept_score.should eql(5.0)

    s.update_scores(:submission_version_number => 2, :fudge_points => 6.0)
    s.kept_score.should eql(6.0)
  end

  describe "with an essay question" do
    before(:each) do
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
      @quiz_submission.submission.workflow_state.should eql 'pending_review'
    end

    it "should mark a submission as complete once an essay question has been graded" do
      @quiz_submission.update_scores({
        'context_id' => @course.id,
        'override_scores' => true,
        'context_type' => 'Course',
        'submission_version_number' => '1',
        "question_score_#{@questions[0].id}" => '1'
      })
      @quiz_submission.submission.workflow_state.should eql 'graded'
    end

    it "should increment the assignment needs_grading_count for pending_review state" do
      @quiz.assignment.reload.needs_grading_count.should == 1
    end
  end

  describe "with multiple essay questions" do
    before(:each) do
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
      @quiz_submission.submission.workflow_state.should eql 'pending_review'
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
      @quiz_submission.submission.workflow_state.should eql 'graded'
    end
  end

  describe "formula questions" do
    before do
      @quiz = @course.quizzes.create!(:title => "formula quiz")
      @quiz.quiz_questions.create! :question_data => {
        :name => "Question",
        :question_type => "calculated_question",
        :answer_tolerance => 2.0,
        :formulas => [[0, "2*z"]],
        :variables => [["variable_0", {:scale => 0, :min => 1.0, :max => 10.0, :name => 'z'}]],
        :answers => [["answer_0", {
          :weight => 100,
          :variables => [["variable_0", {:value => 2.0, :name => 'z'}]],
          :answer_text => "4.0"
        }]],
        :question_text => "2 * [z] is ?"
      }
      @quiz.generate_quiz_data(:persist => true)
    end

    it "should respect the answer_tolerance" do
      submission = @quiz.generate_submission(@user)
      submission.submission_data = {
        "question_#{@quiz.quiz_questions.first.id}" => 3.0, # off by 1
      }
      submission.grade_submission
      submission.instance_variable_get(:@user_answers).first[:correct].should be_true
    end
  end

  it "should update associated submission" do
    c = factory_with_protected_attributes(Course, :workflow_state => "active")
    a = c.assignments.new(:title => "some assignment")
    a.workflow_state = "available"
    a.save!
    u = User.new
    u.workflow_state = "registered"
    u.save!
    c.enroll_student(u)
    s = a.submit_homework(u)
    quiz = c.quizzes.create!
    q = quiz.quiz_submissions.new
    q.submission_id = s.id
    q.user_id = u.id
    q.workflow_state = "complete"
    q.score = 5.0
    q.save!
    q.kept_score.should eql(5.0)
    s.reload

    s.score.should eql(5.0)
  end

  describe "learning outcomes" do
    it "should create learning outcome results when aligned to assessment questions" do
      course_with_student(:active_all => true)
      @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      @q1 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '1', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => '2'}, 'answer_2' => {'answer_text' => '3'},'answer_3' => {'answer_text' => '4'}}})
      @q2 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '1', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => '2'}, 'answer_2' => {'answer_text' => '3'},'answer_3' => {'answer_text' => '4'}}})
      @outcome = @course.created_learning_outcomes.create!(:short_description => 'new outcome')
      @bank = @q1.assessment_question.assessment_question_bank
      @bank.outcomes = {@outcome.id => 0.7}
      @bank.save!
      @bank.learning_outcome_tags.length.should eql(1)
      @q2.assessment_question.assessment_question_bank.should eql(@bank)
      answer_1 = @q1.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      answer_2 = @q2.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      @quiz.generate_quiz_data(:persist => true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      question_1 = @q1.question_data[:id]
      question_2 = @q2.question_data[:id]
      @sub.submission_data["question_#{question_1}"] = answer_1
      @sub.submission_data["question_#{question_2}"] = answer_2 + 1
      @sub.grade_submission
      @sub.score.should eql(1.0)
      @outcome.reload
      @results = @outcome.learning_outcome_results.find_all_by_user_id(@user.id)
      @results.length.should eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      @results.first.associated_asset.should eql(@q1.assessment_question)
      @results.first.mastery.should eql(true)
      @results.last.associated_asset.should eql(@q2.assessment_question)
      @results.last.mastery.should eql(false)
    end

    it "should update learning outcome results when aligned to assessment questions" do
      course_with_student(:active_all => true)
      @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      @q1 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '1', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => '2'}, 'answer_2' => {'answer_text' => '3'},'answer_3' => {'answer_text' => '4'}}})
      @q2 = @quiz.quiz_questions.create!(:question_data => {:name => 'question 2', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '1', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => '2'}, 'answer_2' => {'answer_text' => '3'},'answer_3' => {'answer_text' => '4'}}})
      @outcome = @course.created_learning_outcomes.create!(:short_description => 'new outcome')
      @bank = @q1.assessment_question.assessment_question_bank
      @bank.outcomes = {@outcome.id => 0.7}
      @bank.save!
      @bank.learning_outcome_tags.length.should eql(1)
      @q2.assessment_question.assessment_question_bank.should eql(@bank)
      answer_1 = @q1.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      answer_2 = @q2.question_data[:answers].detect{|a| a[:weight] == 100 }[:id]
      @quiz.generate_quiz_data(:persist => true)
      @sub = @quiz.generate_submission(@user)
      @sub.submission_data = {}
      question_1 = @q1.question_data[:id]
      question_2 = @q2.question_data[:id]
      @sub.submission_data["question_#{question_1}"] = answer_1
      @sub.submission_data["question_#{question_2}"] = answer_2 + 1
      @sub.grade_submission
      @sub.score.should eql(1.0)
      @outcome.reload
      @results = @outcome.learning_outcome_results.find_all_by_user_id(@user.id)
      @results.length.should eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      @results.first.associated_asset.should eql(@q1.assessment_question)
      @results.first.mastery.should eql(true)
      @results.last.associated_asset.should eql(@q2.assessment_question)
      @results.last.mastery.should eql(false)

      @sub = @quiz.generate_submission(@user)
      @sub.attempt.should eql(2)
      @sub.submission_data = {}
      question_1 = @q1.question_data[:id]
      question_2 = @q2.question_data[:id]
      @sub.submission_data["question_#{question_1}"] = answer_1 + 1
      @sub.submission_data["question_#{question_2}"] = answer_2
      @sub.grade_submission
      @sub.score.should eql(1.0)
      @outcome.reload
      @results = @outcome.learning_outcome_results.find_all_by_user_id(@user.id)
      @results.length.should eql(2)
      @results = @results.sort_by(&:associated_asset_id)
      @results.first.associated_asset.should eql(@q1.assessment_question)
      @results.first.mastery.should eql(false)
      @results.first.original_mastery.should eql(true)
      @results.last.associated_asset.should eql(@q2.assessment_question)
      @results.last.mastery.should eql(true)
      @results.last.original_mastery.should eql(false)
    end
  end

  describe ".score_question" do
    it "should score a multiple_choice_question" do
      qd = multiple_choice_question_data
      QuizSubmission.score_question(qd, { "question_1" => "1658" }).should ==
        { :question_id => 1, :correct => true, :points => 50, :answer_id => 1658, :text => "1658" }

      QuizSubmission.score_question(qd, { "question_1" => "8544" }).should ==
        { :question_id => 1, :correct => false, :points => 0, :answer_id => 8544, :text => "8544" }

      QuizSubmission.score_question(qd, { "question_1" => "5" }).should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "5" }

      QuizSubmission.score_question(qd, {}).should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "" }

      QuizSubmission.score_question(qd, { "undefined_if_blank" => "1" }).should ==
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
    end

    it "should score a true_false_question" do
      qd = true_false_question_data
      QuizSubmission.score_question(qd, { "question_1" => "8950" }).should ==
        { :question_id => 1, :correct => true, :points => 45, :answer_id => 8950, :text => "8950" }

      QuizSubmission.score_question(qd, { "question_1" => "8403" }).should ==
        { :question_id => 1, :correct => false, :points => 0, :answer_id => 8403, :text => "8403" }

      QuizSubmission.score_question(qd, { "question_1" => "5" }).should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "5" }

      QuizSubmission.score_question(qd, {}).should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "" }

      QuizSubmission.score_question(qd, { "undefined_if_blank" => "1" }).should ==
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
    end

    it "should score a short_answer_question (Fill In The Blank)" do
      qd = short_answer_question_data
      QuizSubmission.score_question(qd, { "question_1" => "stupid" }).should ==
        { :question_id => 1, :correct => true, :points => 16.5, :answer_id => 7100, :text => "stupid" }
      QuizSubmission.score_question(qd, { "question_1" => "   DUmB\n " }).should ==
        { :question_id => 1, :correct => true, :points => 16.5, :answer_id => 2159, :text => "   DUmB\n " }

      QuizSubmission.score_question(qd, { "question_1" => "short" }).should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "short" }

      # Blank answer from quiz taker should not match even if blank answer is on quiz (blanks created by default)
      qd_with_blank = short_answer_question_data_one_blank
      QuizSubmission.score_question(qd_with_blank, { "question_1" => "" }).should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "" }

      QuizSubmission.score_question(qd, {}).should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "" }

      # Preserve idea of "undefined" for when student wasn't asked the question (ie no response) as separate from
      # student was asked but didn't answer. Can happen when instructor adds question to a quiz that a student has
      # already started or completed.
      QuizSubmission.score_question(qd, { "undefined_if_blank" => "1" }).should ==
        { :question_id => 1, :correct => 'undefined', :points => 0, :text => "" }
    end

    it "should score an essay_question" do
      qd = essay_question_data
      text = "that's too <b>dang</b> hard! <script>alert(1)</script>"
      sanitized = "that's too <b>dang</b> hard! alert(1)"
      QuizSubmission.score_question(qd, { "question_1" => text }).should ==
        { :question_id => 1, :correct => "undefined", :points => 0, :text => sanitized }

      QuizSubmission.score_question(qd, {}).should ==
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
    end

    it "should score a text_only_question" do
      QuizSubmission.score_question(text_only_question_data, {}).should ==
        { :question_id => 3, :correct => "no_score", :points => 0, :text => "" }
    end

    it "should score a matching_question" do
      q = matching_question_data

      # 1 wrong answer
      user_answer = QuizSubmission.score_question(q, {
        "question_1_answer_7396" => "3562",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
      })
      user_answer.delete(:points).should be_close(41.67, 0.01)
      user_answer.should == {
        :question_id => 1, :correct => "partial", :text => "",
        :answer_7396 => "3562",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      }

      # 1 wrong answer but no partial credit allowed
      user_answer = QuizSubmission.score_question(q.merge(:allow_partial_credit => false), {
        "question_1_answer_7396" => "3562",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
      })
      user_answer.should == {
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_7396 => "3562",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      }

      # all wrong answers
      user_answer = QuizSubmission.score_question(q, {
        "question_1_answer_7396" => "3562",
        "question_1_answer_6081" => "1500",
        "question_1_answer_4224" => "8513",
      })
      user_answer.should == {
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_7396 => "3562",
        :answer_6081 => "1500",
        :answer_4224 => "8513",
        :answer_7397 => "",
        :answer_7398 => "",
        :answer_7399 => "",
      }

      user_answer = QuizSubmission.score_question(q, {
        "question_1_answer_7396" => "6061",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
      })
      user_answer.should == {
        :question_id => 1, :correct => true, :points => 50, :text => "",
        :answer_7396 => "6061",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      }

      # selected a different answer but the text of that answer was the same
      user_answer = QuizSubmission.score_question(q, {
        "question_1_answer_7396" => "1397",
        "question_1_answer_6081" => "3855",
        "question_1_answer_4224" => "1397",
        "question_1_answer_7397" => "6067",
        "question_1_answer_7398" => "6068",
        "question_1_answer_7399" => "6069",
      })
      user_answer.should == {
        :question_id => 1, :correct => true, :points => 50, :text => "",
        :answer_7396 => "6061",
        :answer_6081 => "3855",
        :answer_4224 => "1397",
        :answer_7397 => "6067",
        :answer_7398 => "6068",
        :answer_7399 => "6069",
      }

      # no answer shouldn't be treated as a blank string, breaking undefined_if_blank
      QuizSubmission.score_question(q, { "undefined_if_blank" => "1" }).should == {
        :question_id => 1, :correct => "undefined", :points => 0, :text => "",
        :answer_7396 => "",
        :answer_6081 => "",
        :answer_4224 => "",
        :answer_7397 => "",
        :answer_7398 => "",
        :answer_7399 => "",
      }
    end

    it "should score a numerical_question" do
      qd = numerical_question_data

      QuizSubmission.score_question(qd, { "question_1" => "3.2" }).should == {
        :question_id => 1, :correct => false, :points => 0, :text => "3.2" }

      QuizSubmission.score_question(qd, { "question_1" => "4" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "4", :answer_id => 9222 }

      QuizSubmission.score_question(qd, { "question_1" => "-4" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "-4", :answer_id => 997 }

      QuizSubmission.score_question(qd, { "question_1" => "4.05" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "4.05", :answer_id => 9370 }
      QuizSubmission.score_question(qd, { "question_1" => "4.10" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "4.10", :answer_id => 9370 }
      QuizSubmission.score_question(qd, { "question_1" => "3.90" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "3.90", :answer_id => 9370 }

      QuizSubmission.score_question(qd, { "question_1" => "-4.1" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "-4.1", :answer_id => 5450 }
      QuizSubmission.score_question(qd, { "question_1" => "-3.9" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "-3.9", :answer_id => 5450 }
      QuizSubmission.score_question(qd, { "question_1" => "-4.05" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "-4.05", :answer_id => 5450 }

      QuizSubmission.score_question(qd, { "question_1" => "" }).should == {
        :question_id => 1, :correct => false, :points => 0, :text => "" }

      QuizSubmission.score_question(qd, { :undefined_if_blank => "1" }).should == {
        :question_id => 1, :correct => "undefined", :points => 0, :text => "" }

      # blank answer should not be treated as 0.0
      qd2 = qd.dup
      qd2["answers"] << { "exact" => 0, "numerical_answer_type" => "exact_answer", "margin" => 0, "weight" => 100, "id" => 1234 }
      QuizSubmission.score_question(qd2, { "question_1" => "" }).should == {
        :question_id => 1, :correct => false, :points => 0, :text => "" }
    end

    it "should score a calculated_question" do
      qd = calculated_question_data

      QuizSubmission.score_question(qd, { "question_1" => "-11.7" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "-11.7", :answer_id => 6396 }

      QuizSubmission.score_question(qd, { "question_1" => "-11.68" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "-11.68", :answer_id => 6396 }

      QuizSubmission.score_question(qd, { "question_1" => "-11.675" }).should == {
        :question_id => 1, :correct => false, :points => 0, :text => "-11.675" }

      QuizSubmission.score_question(qd, {}).should == {
        :question_id => 1, :correct => false, :points => 0, :text => "" }

      QuizSubmission.score_question(qd, { "question_1" => "-11.72" }).should == {
        :question_id => 1, :correct => true, :points => 26.2, :text => "-11.72", :answer_id => 6396 }
    end

    it "should score a multiple_answers_question" do
      qd = multiple_answers_question_data

      QuizSubmission.score_question(qd, {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "1",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "0",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "1",
        "question_1_answer_7381" => "0",
      }).should == {
        :question_id => 1, :correct => true, :points => 50, :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "1",
        :answer_166  => "1",
        :answer_4739 => "0",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "1",
        :answer_7381 => "0",
      }

      # partial credit
      user_answer = QuizSubmission.score_question(qd, {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "1",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "1",
        "question_1_answer_7381" => "0",
      })
      user_answer.delete(:points).should be_close(41.67, 0.01)
      user_answer.should == {
        :question_id => 1, :correct => "partial", :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "1",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "1",
        :answer_7381 => "0",
      }

      user_answer = QuizSubmission.score_question(qd.merge(:allow_partial_credit => false), {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "1",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "1",
        "question_1_answer_7381" => "0",
      })
      user_answer.should == {
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "1",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "1",
        :answer_7381 => "0",
      }

      # checking one that shouldn't be checked, subtracts one correct answer's worth of points
      user_answer = QuizSubmission.score_question(qd, {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "0",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "0",
        "question_1_answer_7381" => "0",
      })
      user_answer.delete(:points).should be_close(25.0, 0.01)
      user_answer.should == {
        :question_id => 1, :correct => "partial", :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "0",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "0",
        :answer_7381 => "0",
      }

      # can't get less than 0
      user_answer = QuizSubmission.score_question(qd, {
        "question_1_answer_9761" => "0",
        "question_1_answer_3079" => "1",
        "question_1_answer_5194" => "0",
        "question_1_answer_166"  => "0",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "0",
        "question_1_answer_7381" => "1",
      })
      user_answer.should == {
        :question_id => 1, :correct => false, :points => 0, :text => "",
        :answer_9761 => "0",
        :answer_3079 => "1",
        :answer_5194 => "0",
        :answer_166  => "0",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "0",
        :answer_7381 => "1",
      }

      # incorrect_dock allows a different value to be subtracted on incorrect answer
      # this isn't exposed in the UI anywhere yet, but the code supports it
      user_answer = QuizSubmission.score_question(qd.merge(:incorrect_dock => 1.5), {
        "question_1_answer_9761" => "1",
        "question_1_answer_3079" => "0",
        "question_1_answer_5194" => "0",
        "question_1_answer_166"  => "1",
        "question_1_answer_4739" => "1",
        "question_1_answer_2196" => "1",
        "question_1_answer_8982" => "1",
        "question_1_answer_9701" => "0",
        "question_1_answer_7381" => "0",
      })
      user_answer.delete(:points).should be_close(31.83, 0.01)
      user_answer.should == {
        :question_id => 1, :correct => "partial", :text => "",
        :answer_9761 => "1",
        :answer_3079 => "0",
        :answer_5194 => "0",
        :answer_166  => "1",
        :answer_4739 => "1",
        :answer_2196 => "1",
        :answer_8982 => "1",
        :answer_9701 => "0",
        :answer_7381 => "0",
      }

      QuizSubmission.score_question(qd, { "undefined_if_blank" => "1" }).should ==
        { :question_id => 1, :correct => "undefined", :points => 0, :text => "" }
    end

    it "should score a multiple_dropdowns_question" do
      q = multiple_dropdowns_question_data

      user_answer = QuizSubmission.score_question(q, { "question_1630873_4e6185159bea49c4d29047379b400ad5"=>"6994", "question_1630873_3f507e80e33ef092a02948a064433ec5"=>"5988", "question_1630873_78635a3709b540a59678c806b102d038"=>"9908", "question_1630873_657b11f1c17376f178c4d80c4c25d0ab"=>"1121", "question_1630873_02c8346333761ffe9bbddee7b1c5a537"=>"4390", "question_1630873_1865cbc77c83d7571ed8b3a108d11d3d"=>"7604", "question_1630873_94239fc44b4f8aaf36bd3596768f4816"=>"6955", "question_1630873_cd073d17d0d9558fb2be7d7bf9a1c840"=>"3353", "question_1630873_69d0969351d989767d7096f28daf7461"=>"3390"})
      user_answer.delete(:points).should be_close(0.44, 0.01)
      user_answer.should == {
        :question_id => 1630873, :correct => "partial", :text => "",
        :answer_for_structure1 => 4390,
        :answer_id_for_structure1 => 4390,
        :answer_for_event1 => 3390,
        :answer_id_for_event1 => 3390,
        :answer_for_structure2 => 6955,
        :answer_id_for_structure2 => 6955,
        :answer_for_structure3 => 5988,
        :answer_id_for_structure3 => 5988,
        :answer_for_structure4 => 7604,
        :answer_id_for_structure4 => 7604,
        :answer_for_event2 => 3353,
        :answer_id_for_event2 => 3353,
        :answer_for_structure5 => 9908,
        :answer_id_for_structure5 => 9908,
        :answer_for_structure6 => 6994,
        :answer_id_for_structure6 => 6994,
        :answer_for_structure7 => 1121,
        :answer_id_for_structure7 => 1121,
      }

      user_answer = QuizSubmission.score_question(q, { "question_1630873_4e6185159bea49c4d29047379b400ad5"=>"1883", "question_1630873_3f507e80e33ef092a02948a064433ec5"=>"5988", "question_1630873_78635a3709b540a59678c806b102d038"=>"878", "question_1630873_657b11f1c17376f178c4d80c4c25d0ab"=>"9570", "question_1630873_02c8346333761ffe9bbddee7b1c5a537"=>"1522", "question_1630873_1865cbc77c83d7571ed8b3a108d11d3d"=>"9532", "question_1630873_94239fc44b4f8aaf36bd3596768f4816"=>"1228", "question_1630873_cd073d17d0d9558fb2be7d7bf9a1c840"=>"599", "question_1630873_69d0969351d989767d7096f28daf7461"=>"5498"})
      user_answer.should == {
        :question_id => 1630873, :correct => false, :points => 0, :text => "",
        :answer_for_structure1 => 1522,
        :answer_id_for_structure1 => 1522,
        :answer_for_event1 => 5498,
        :answer_id_for_event1 => 5498,
        :answer_for_structure2 => 1228,
        :answer_id_for_structure2 => 1228,
        :answer_for_structure3 => 5988,
        :answer_id_for_structure3 => 5988,
        :answer_for_structure4 => 9532,
        :answer_id_for_structure4 => 9532,
        :answer_for_event2 => 599,
        :answer_id_for_event2 => 599,
        :answer_for_structure5 => 878,
        :answer_id_for_structure5 => 878,
        :answer_for_structure6 => 1883,
        :answer_id_for_structure6 => 1883,
        :answer_for_structure7 => 9570,
        :answer_id_for_structure7 => 9570,
      }

      user_answer = QuizSubmission.score_question(q, { "question_1630873_4e6185159bea49c4d29047379b400ad5"=>"6994", "question_1630873_3f507e80e33ef092a02948a064433ec5"=>"7676", "question_1630873_78635a3709b540a59678c806b102d038"=>"9908", "question_1630873_657b11f1c17376f178c4d80c4c25d0ab"=>"1121", "question_1630873_02c8346333761ffe9bbddee7b1c5a537"=>"4390", "question_1630873_1865cbc77c83d7571ed8b3a108d11d3d"=>"7604", "question_1630873_94239fc44b4f8aaf36bd3596768f4816"=>"6955", "question_1630873_cd073d17d0d9558fb2be7d7bf9a1c840"=>"3353", "question_1630873_69d0969351d989767d7096f28daf7461"=>"3390"})
      user_answer.should == {
        :question_id => 1630873, :correct => true, :points => 0.5, :text => "",
        :answer_for_structure1 => 4390,
        :answer_id_for_structure1 => 4390,
        :answer_for_event1 => 3390,
        :answer_id_for_event1 => 3390,
        :answer_for_structure2 => 6955,
        :answer_id_for_structure2 => 6955,
        :answer_for_structure3 => 7676,
        :answer_id_for_structure3 => 7676,
        :answer_for_structure4 => 7604,
        :answer_id_for_structure4 => 7604,
        :answer_for_event2 => 3353,
        :answer_id_for_event2 => 3353,
        :answer_for_structure5 => 9908,
        :answer_id_for_structure5 => 9908,
        :answer_for_structure6 => 6994,
        :answer_id_for_structure6 => 6994,
        :answer_for_structure7 => 1121,
        :answer_id_for_structure7 => 1121,
      }
    end

    it "should score a fill_in_multiple_blanks_question" do
      q = fill_in_multiple_blanks_question_data
      user_answer = QuizSubmission.score_question(q, {
        "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "control",
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "patrol",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "soul",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "toll",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "assplode",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "old",
      })
      user_answer.should ==
        { :question_id => 1, :correct => true, :points => 50.0, :text => "",
          :answer_for_answer1 => "control",
          :answer_id_for_answer1 => 3950,
          :answer_for_answer2 => "patrol",
          :answer_id_for_answer2 => 9181,
          :answer_for_answer3 => "soul",
          :answer_id_for_answer3 => 3733,
          :answer_for_answer4 => "toll",
          :answer_id_for_answer4 => 7829,
          :answer_for_answer5 => "assplode",
          :answer_id_for_answer5 => 5301,
          :answer_for_answer6 => "old",
          :answer_id_for_answer6 => 3367,
        }

      user_answer = QuizSubmission.score_question(q, {
        "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "control",
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "patrol",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "soul",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "toll",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "wut",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "old",
      })
      user_answer.delete(:points).should be_close(41.6, 0.1)
      user_answer.should ==
        { :question_id => 1, :correct => "partial", :text => "",
          :answer_for_answer1 => "control",
          :answer_id_for_answer1 => 3950,
          :answer_for_answer2 => "patrol",
          :answer_id_for_answer2 => 9181,
          :answer_for_answer3 => "soul",
          :answer_id_for_answer3 => 3733,
          :answer_for_answer4 => "toll",
          :answer_id_for_answer4 => 7829,
          :answer_for_answer5 => "wut",
          :answer_id_for_answer5 => nil,
          :answer_for_answer6 => "old",
          :answer_id_for_answer6 => 3367,
        }

      user_answer = QuizSubmission.score_question(q, {
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "0",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "fail",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "wrong",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "wut",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "oh well",
      })
      user_answer.should ==
        { :question_id => 1, :correct => false, :points => 0, :text => "",
          :answer_for_answer1 => "",
          :answer_id_for_answer1 => nil,
          :answer_for_answer2 => "0",
          :answer_id_for_answer2 => nil,
          :answer_for_answer3 => "fail",
          :answer_id_for_answer3 => nil,
          :answer_for_answer4 => "wrong",
          :answer_id_for_answer4 => nil,
          :answer_for_answer5 => "wut",
          :answer_id_for_answer5 => nil,
          :answer_for_answer6 => "oh well",
          :answer_id_for_answer6 => nil,
        }

      # one blank to fill in
      user_answer = QuizSubmission.score_question(fill_in_multiple_blanks_question_one_blank_data, { "question_2_10ca8479f89652b254a5c6ec90ab9ab8" => " DUmB \n " })
      user_answer.should ==
        { :question_id => 2, :correct => true, :points => 3.75, :text => "",
          :answer_for_myblank => "dumb",
          :answer_id_for_myblank => 1235, }

      user_answer = QuizSubmission.score_question(fill_in_multiple_blanks_question_one_blank_data, { "question_2_10ca8479f89652b254a5c6ec90ab9ab8" => "wut" })
      user_answer.should ==
        { :question_id => 2, :correct => false, :points => 0, :text => "",
          :answer_for_myblank => "wut",
          :answer_id_for_myblank => nil, }
    end

    it "should score an unknown question type" do
      # if a question with an invalid type makes it into the quiz data, we
      # score it as always 0 out of points_possible, rather than raise an error
      qd = {"name"=>"Question 1", "question_type"=>"Error", "assessment_question_id"=>nil, "migration_id"=>"i1234", "id"=>2, "points_possible"=>5.35, "question_name"=>"Question 1", "qti_error"=>"There was an error exporting an assessment question - No question type used when trying to parse a qti question", "question_text"=>"test1", "answers"=>[], "assessment_question_migration_id"=>"i1234"}.with_indifferent_access
      user_answer = QuizSubmission.score_question(qd, {})
      user_answer.should ==
        { :question_id => 2, :correct => false, :points => 0, :text => "", }
    end

    it "should not escape user responses in fimb questions" do
      course_with_student(:active_all => true)
      q = {:neutral_comments=>"",
       :position=>1,
       :question_name=>"Question 1",
       :correct_comments=>"",
       :answers=>
        [{:comments=>"",
          :blank_id=>"answer1",
          :weight=>100,
          :text=>"control",
          :id=>3950},
         {:comments=>"",
          :blank_id=>"answer1",
          :weight=>100,
          :text=>"controll",
          :id=>9177}],
       :points_possible=>50,
       :question_type=>"fill_in_multiple_blanks_question",
       :assessment_question_id=>7903,
       :name=>"Question 1",
       :question_text=>
        "<p><span>Ayo my quality [answer1]</p>",
       :id=>1,
       :incorrect_comments=>""}

       user_answer = QuizSubmission.score_question(q, {
         "question_1_#{AssessmentQuestion.variable_id("answer1")}" => "<>&\""
       })
       user_answer[:answer_for_answer1].should == "<>&\""
    end

    it "should not fail if fimb question doesn't have any answers" do
      course_with_student(:active_all => true)
      # @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      q = {:position=>1, :name=>"Question 1", :correct_comments=>"", :question_type=>"fill_in_multiple_blanks_question", :assessment_question_id=>7903, :incorrect_comments=>"", :neutral_comments=>"", :id=>1, :points_possible=>50, :question_name=>"Question 1", :answers=>[], :question_text=>"<p><span>Ayo my quality [answer1].</p>"}
      lambda {
        QuizSubmission.score_question(q, { "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "bleh" })
      }.should_not raise_error
    end
  end

  describe "#score_to_keep" do
    before(:each) do
      student_in_course
      assignment_quiz([])
      qd = multiple_choice_question_data
      @quiz.quiz_data = [qd]
      @quiz.points_possible = qd[:points_possible]
      @quiz.save!
    end

    context "keep_highest" do
      before(:each) do
        @quiz.scoring_policy = "keep_highest"
        @quiz.save!
      end

      it "should be nil during first in-progress submission" do
        qs = @quiz.generate_submission(@student)
        qs.score_to_keep.should be_nil
      end

      it "should be the submission score for one complete submission" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        qs.grade_submission
        qs.score_to_keep.should == @quiz.points_possible
      end

      it "should be correct for multiple complete versions" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        qs.grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        qs.grade_submission
        qs.score_to_keep.should == @quiz.points_possible
      end

      it "should be correct for multiple versions, current version in progress" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        qs.grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        qs.grade_submission
        qs = @quiz.generate_submission(@student)
        qs.score_to_keep.should == @quiz.points_possible
      end
    end

    context "keep_latest" do
      before(:each) do
        @quiz.scoring_policy = "keep_latest"
        @quiz.save!
      end

      it "should be nil during first in-progress submission" do
        qs = @quiz.generate_submission(@student)
        qs.score_to_keep.should be_nil
      end

      it "should be the submission score for one complete submission" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        qs.grade_submission
        qs.score_to_keep.should == @quiz.points_possible
      end

      it "should be correct for multiple complete versions" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        qs.grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        qs.grade_submission
        qs.score_to_keep.should == 0
      end

      it "should be correct for multiple versions, current version in progress" do
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "1658" }
        qs.grade_submission
        qs = @quiz.generate_submission(@student)
        qs.submission_data = { "question_1" => "2405" }
        qs.grade_submission
        qs = @quiz.generate_submission(@student)
        qs.score_to_keep.should == 0
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
      qs.grants_right?(@observer, nil, :read).should be_true
    end
  end
end
