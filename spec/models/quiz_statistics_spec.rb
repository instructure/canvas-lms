#
# Copyright (C) 2011 - 2012 Instructure, Inc.
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

describe QuizStatistics do
  before { course }

  def csv(opts = {}, quiz = @quiz)
    attachment = quiz.statistics_csv(opts)
    attachment.open.read
  end


  it 'should calculate mean/stddev as expected with no submissions' do
    q = @course.quizzes.create!
    stats = q.statistics
    stats[:submission_score_average].should be_nil
    stats[:submission_score_high].should be_nil
    stats[:submission_score_low].should be_nil
    stats[:submission_score_stdev].should be_nil
  end

  it 'should calculate mean/stddev as expected with a few submissions' do
    q = @course.quizzes.create!
    q.save!
    @user1 = User.create! :name => "some_user 1"
    @user2 = User.create! :name => "some_user 2"
    @user3 = User.create! :name => "some_user 2"
    student_in_course :course => @course, :user => @user1
    student_in_course :course => @course, :user => @user2
    student_in_course :course => @course, :user => @user3
    sub = q.generate_submission(@user1)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 15, :text => "", :correct => "undefined", :question_id => -1 }]
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should == 15
    stats[:submission_score_high].should == 15
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should == 0
    sub = q.generate_submission(@user2)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 17, :text => "", :correct => "undefined", :question_id => -1 }]
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should == 16
    stats[:submission_score_high].should == 17
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should == 1
    sub = q.generate_submission(@user3)
    sub.workflow_state = 'complete'
    sub.submission_data = [{ :points => 20, :text => "", :correct => "undefined", :question_id => -1 }]
    sub.with_versioning(true, &:save!)
    stats = q.statistics
    stats[:submission_score_average].should be_close(17 + 1.0/3, 0.0000000001)
    stats[:submission_score_high].should == 20
    stats[:submission_score_low].should == 15
    stats[:submission_score_stdev].should be_close(Math::sqrt(4 + 2.0/9), 0.0000000001)
  end

  it "should use the last completed submission, even if the current submission is in progress" do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!
    q.quiz_questions.create!(:question_data => { :name => "test 1" })
    q.generate_quiz_data
    q.save!

    # one complete submission
    qs = q.generate_submission(@student)
    qs.grade_submission

    # and one in progress
    qs = q.generate_submission(@student)

    stats = q.statistics(false)
    stats[:multiple_attempts_exist].should be_false
  end


  context 'csv' do
    before(:each) do
      student_in_course(:active_all => true)
      @quiz = @course.quizzes.create!
      @quiz.quiz_questions.create!(:question_data => { :name => "test 1" })
      @quiz.generate_quiz_data
      @quiz.published_at = Time.now
      @quiz.save!
    end

    it 'should include previous versions even if the current version is incomplete' do
      # one complete submission
      qs = @quiz.generate_submission(@student)
      qs.grade_submission

      # and one in progress
      @quiz.generate_submission(@student)

      stats = FasterCSV.parse(csv(:include_all_versions => true))
      # format for row is row_name, '', data1, data2, ...
      stats.first.length.should == 3
    end

    it 'should not include user data for anonymous surveys' do
      # one complete submission
      qs = @quiz.generate_submission(@student)
      qs.grade_submission

      # and one in progress
      @quiz.generate_submission(@student)

      stats = FasterCSV.parse(csv(:include_all_versions => true, :anonymous => true))
      # format for row is row_name, '', data1, data2, ...
      stats.first.length.should == 3
      stats[0][0].should == "section"
    end

    it 'should have sections in quiz statistics_csv' do
      #enroll user in multiple sections
      pseudonym = pseudonym(@student)
      @student.pseudonym.sis_user_id = "user_sis_id_01"
      @student.pseudonym.save!
      section1 = @course.course_sections.first
      section1.sis_source_id = 'SISSection01'
      section1.save!
      section2 = CourseSection.new(:course => @course, :name => "section2")
      section2.sis_source_id = 'SISSection02'
      section2.save!
      @course.enroll_user(@student, "StudentEnrollment", :enrollment_state => 'active', :allow_multiple_enrollments => true, :section => section2)
      # one complete submission
      qs = @quiz.generate_submission(@student)
      qs.grade_submission

      stats = FasterCSV.parse(csv(:include_all_versions => true))
      # format for row is row_name, '', data1, data2, ...
      stats[0].should == ["name", "", "nobody@example.com"]
      stats[1].should == ["id", "", @student.id.to_s]
      stats[2].should == ["sis_id", "", "user_sis_id_01"]
      expect_multi_value_row(stats[3], "section", ["section2", "Unnamed Course"])
      expect_multi_value_row(stats[4], "section_id", [section1.id, section2.id])
      expect_multi_value_row(stats[5], "section_sis_id", ["SISSection02", "SISSection01"])
      stats.first.length.should == 3
    end

    def expect_multi_value_row(row, expected_name, expected_values)
      row[0..1].should == [expected_name, ""]
      row[2].split(', ').sort.should == expected_values.map(&:to_s).sort
    end

    it 'should not include previous versions by default' do
      # two complete submissions
      qs = @quiz.generate_submission(@student)
      qs.grade_submission
      qs = @quiz.generate_submission(@student)
      qs.grade_submission

      stats = FasterCSV.parse(csv)
      # format for row is row_name, '', data1, data2, ...
      stats.first.length.should == 3
    end

    it 'should deal with incomplete fill-in-multiple-blanks questions' do
      @quiz.quiz_questions.create!(:question_data => { :name => "test 2",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0]",
        :answers =>
          {'answer_0' => {'answer_text' => 'foo', 'blank_id' => 'ans0', 'answer_weight' => '100'}}})
      @quiz.quiz_questions.create!(:question_data => { :name => "test 3",
        :question_type => 'fill_in_multiple_blanks_question',
        :question_text => "[ans0] [ans1]",
        :answers =>
           {'answer_0' => {'answer_text' => 'bar', 'blank_id' => 'ans0', 'answer_weight' => '100'},
            'answer_1' => {'answer_text' => 'baz', 'blank_id' => 'ans1', 'answer_weight' => '100'}}})
      @quiz.generate_quiz_data
      @quiz.save!
      @quiz.quiz_questions.size.should == 3
      qs = @quiz.generate_submission(@student)
      # submission will not answer question 2 and will partially answer question 3
      qs.submission_data = {
          "question_#{@quiz.quiz_questions[2].id}_#{AssessmentQuestion.variable_id('ans1')}" => 'baz'
      }
      qs.grade_submission
      stats = FasterCSV.parse(csv)
      stats.size.should == 16 # 3 questions * 2 lines + ten more (name, id, sis_id, section, section_id, section_sis_id, submitted, correct, incorrect, score)
      stats[11].size.should == 3
      stats[11][2].should == ',baz'
    end

    it 'should contain answers to numerical questions' do
      @quiz.quiz_questions.create!(:question_data => { :name => "numerical_question",
        :question_type => 'numerical_question',
        :question_text => "[num1]",
        :answers => {'answer_0' => {:numerical_answer_type => 'exact_answer'}}})

      @quiz.quiz_questions.last.question_data[:answers].first[:exact] = 5

      @quiz.generate_quiz_data
      @quiz.save!

      qs = @quiz.generate_submission(@student)
      qs.submission_data = {
        "question_#{@quiz.quiz_questions[1].id}" => 5
      }
      qs.grade_submission

      stats = FasterCSV.parse(csv)
      stats[9][2].should == '5'
    end

    context 'generating quiz_statistics' do
      before { @quiz.update_attribute :published_at, Time.now }

      it 'uses the previously generated quiz_statistics if possible' do
        qs = @quiz.quiz_statistics.create!
        a = qs.csv_attachment

        @quiz.statistics_csv.should == a
      end

      it 'generates a new quiz_statistics if none exist' do
        QuizStatistics.any_instance.expects(:to_csv).once.returns("")
        @quiz.statistics_csv
        @quiz.statistics_csv
      end

      it 'generates a new quiz_statistics if the quiz changed' do
        QuizStatistics.any_instance.expects(:to_csv).twice.returns("")
        @quiz.statistics_csv # once
        @quiz.one_question_at_a_time = true
        @quiz.published_at = Time.now
        @quiz.save!
        @quiz.statistics_csv # twice
        @quiz.update_attribute(:one_question_at_a_time, false)
        @quiz.statistics_csv # unpublished changes don't matter
      end

      it 'generates a new quiz_statistics if new submissions are in' do
        QuizStatistics.any_instance.expects(:to_csv).twice.returns("")
        @quiz.statistics_csv
        qs = @quiz.quiz_submissions.build
        qs.save!
        qs.mark_completed
        @quiz.statistics_csv
      end

      it 'provides progress updates' do
        @quiz.statistics_csv
        progress = @quiz.quiz_statistics.first.progress
        progress.completion.should == 100
        progress.should be_completed
      end
    end
  end

  it 'should strip tags from html multiple-choice/multiple-answers' do
    student_in_course(:active_all => true)
    q = @course.quizzes.create!(:title => "new quiz")
    q.update_attribute(:published_at, Time.now)
    q.quiz_questions.create!(:question_data => {:name => 'q1', :points_possible => 1, 'question_type' => 'multiple_choice_question', 'answers' => {'answer_0' => {'answer_text' => '', 'answer_html' => '<em>zero</em>', 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => "", 'answer_html' => "<p>one</p>", 'answer_weight' => '0'}}})
    q.quiz_questions.create!(:question_data => {:name => 'q2', :points_possible => 1, 'question_type' => 'multiple_answers_question', 'answers' => {'answer_0' => {'answer_text' => '', 'answer_html' => "<a href='http://example.com/caturday.gif'>lolcats</a>", 'answer_weight' => '100'}, 'answer_1' => {'answer_text' => 'lolrus', 'answer_weight' => '100'}}})
    q.generate_quiz_data
    q.save
    qs = q.generate_submission(@student)
    qs.submission_data = {
        "question_#{q.quiz_data[0][:id]}" => "#{q.quiz_data[0][:answers][0][:id]}",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][0][:id]}" => "1",
        "question_#{q.quiz_data[1][:id]}_answer_#{q.quiz_data[1][:answers][1][:id]}" => "1"
    }
    qs.grade_submission

    # visual statistics
    stats = q.statistics
    stats[:questions].length.should == 2
    stats[:questions][0].length.should == 2
    stats[:questions][0][0].should == "question"
    stats[:questions][0][1][:answers].length.should == 2
    stats[:questions][0][1][:answers][0][:responses].should == 1
    stats[:questions][0][1][:answers][0][:text].should == "zero"
    stats[:questions][0][1][:answers][1][:responses].should == 0
    stats[:questions][0][1][:answers][1][:text].should == "one"
    stats[:questions][1].length.should == 2
    stats[:questions][1][0].should == "question"
    stats[:questions][1][1][:answers].length.should == 2
    stats[:questions][1][1][:answers][0][:responses].should == 1
    stats[:questions][1][1][:answers][0][:text].should == "lolcats"
    stats[:questions][1][1][:answers][1][:responses].should == 1
    stats[:questions][1][1][:answers][1][:text].should == "lolrus"

    # csv statistics
    stats = FasterCSV.parse(csv({}, q))
    stats[7][2].should == "zero"
    stats[9][2].should == "lolcats,lolrus"
  end
end
