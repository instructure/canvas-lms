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

  it "should not allow updating scores on an uncompleted submission" do
    q = @quiz.quiz_submissions.create!
    q.state.should eql(:untaken)
    res = q.update_scores rescue false
    res.should eql(false)
  end

  it "should allow updating scores on a completed version of a submission while the current version is in progress" do
    course_with_student(:active_all => true)
    @quiz = @course.quizzes.create!
    qs = @quiz.generate_submission(@user)
    qs.workflow_state = 'complete'
    qs.submission_data = [{ :points => 0, :text => "", :correct => "undefined", :question_id => -1 }]
    qs.with_versioning(true, &:save)

    qs = @quiz.generate_submission(@user)
    qs.submission_data = { "foo" => "bar" } # simulate k/v pairs we store for quizzes in progress
    qs.save
    lambda {qs.update_scores}.should raise_error
    lambda {qs.update_scores(:submission_version_number => 1) }.should_not raise_error
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

    it "should tally up fill in multiple blanks" do
      course_with_student(:active_all => true)
      # @quiz = @course.quizzes.create!(:title => "new quiz", :shuffle_answers => true)
      q = {:position=>1, :name=>"Question 1", :correct_comments=>"", :question_type=>"fill_in_multiple_blanks_question", :assessment_question_id=>7903, :incorrect_comments=>"", :neutral_comments=>"", :id=>1, :points_possible=>50, :question_name=>"Question 1", :answers=>[{:comments=>"", :text=>"control", :weight=>100, :id=>3950, :blank_id=>"answer1"}, {:comments=>"", :text=>"controll", :weight=>100, :id=>9177, :blank_id=>"answer1"}, {:comments=>"", :text=>"patrol", :weight=>100, :id=>9181, :blank_id=>"answer2"}, {:comments=>"", :text=>"soul", :weight=>100, :id=>3733, :blank_id=>"answer3"}, {:comments=>"", :text=>"tolls", :weight=>100, :id=>9756, :blank_id=>"answer4"}, {:comments=>"", :text=>"toll", :weight=>100, :id=>7829, :blank_id=>"answer4"}, {:comments=>"", :text=>"explode", :weight=>100, :id=>3046, :blank_id=>"answer5"}, {:comments=>"", :text=>"assplode", :weight=>100, :id=>5301, :blank_id=>"answer5"}, {:comments=>"", :text=>"old", :weight=>100, :id=>3367, :blank_id=>"answer6"}], :question_text=>"<p><span>Ayo my quality [answer1], captivates your party [answer2]. </span>Your mind, body, and [answer3]. For whom the bell [answer4], let the rhythm [answer5]. Big, bad, and bold b-boys of [answer6].</p>"}
      user_answer = QuizSubmission.score_question(q, {
        "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "control",
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "patrol",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "soul",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "toll",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "assplode",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "old",
      })
      user_answer[:correct].should be_true
      user_answer[:points].should == 50.0

      user_answer = QuizSubmission.score_question(q, {
        "question_1_8238a0de6965e6b81a8b9bba5eacd3e2" => "control",
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "patrol",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "soul",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "toll",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "wut",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "old",
      })
      user_answer[:correct].should == "partial"
      user_answer[:points].should be_close(41.6, 0.1)

      user_answer = QuizSubmission.score_question(q, {
        "question_1_a95fbffb573485f87b8c8aca541f5d4e" => "0",
        "question_1_3112b644eec409c20c346d2a393bd45e" => "fail",
        "question_1_fb1b03eb201132f7c1a5824cf9ebecb7" => "wrong",
        "question_1_90811a00aaf122ea20ab5c28be681ac9" => "wut",
        "question_1_ce36b05cfdedbc990a188907fc29d37b" => "oh well",
      })
      user_answer[:correct].should be_false
      user_answer[:points].should == 0
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
end
