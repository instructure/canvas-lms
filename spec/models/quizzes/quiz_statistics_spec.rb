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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

require 'csv'

describe Quizzes::QuizStatistics do
  before(:each) do
    student_in_course(:active_all => true)
    @quiz = @course.quizzes.create!
    @quiz.quiz_questions.create!(:question_data => { :name => "test 1" })
    @quiz.generate_quiz_data
    @quiz.published_at = Time.now
    @quiz.save!
  end

  def csv(opts = {}, quiz = @quiz)
    stats = quiz.statistics_csv('student_analysis', opts)
    run_jobs
    stats.csv_attachment(true).open.read
  end

  it "should use the last completed submission, even if the current submission is in progress" do
    # one complete submission
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission

    # and one in progress
    qs = @quiz.generate_submission(@student)

    stats = @quiz.statistics(false)
    stats[:multiple_attempts_exist].should be_false
  end

  it 'should include previous versions even if the current version is incomplete' do
    # one complete submission
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission

    # and one in progress
    @quiz.generate_submission(@student)

    stats = CSV.parse(csv(:include_all_versions => true))
    stats.first.length.should == 12
  end

  it 'should not include previous versions by default' do
    # two complete submissions
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = CSV.parse(csv)
    stats.first.length.should == 12
  end

  it 'generates a new quiz_statistics if the quiz changed' do
    stats1 = @quiz.current_statistics_for('student_analysis') # once

    stats2 = Timecop.freeze(2.minutes.from_now) do
      @quiz.one_question_at_a_time = true
      @quiz.published_at = Time.now
      @quiz.save!
      @quiz.reload
      @quiz.current_statistics_for('student_analysis') # twice
    end

    stats3 = Timecop.freeze(5.minutes.from_now) do
      @quiz.update_attribute(:one_question_at_a_time, false)
      @quiz.current_statistics_for('student_analysis') # unpublished changes don't matter
    end

    stats2.should_not == stats1
    stats3.should == stats2
  end

  it 'generates a new quiz_statistics if new submissions are in' do
    stats = @quiz.current_statistics_for('student_analysis')

    @quiz.quiz_submissions.build.tap do |qs|
      qs.save!
      qs.mark_completed
    end

    @quiz.current_statistics_for('student_analysis').should_not == stats
  end

  it 'uses the previously generated quiz_statistics if possible' do
    stats = @quiz.current_statistics_for 'student_analysis'

    Timecop.freeze(5.minutes.from_now) do
      @quiz.current_statistics_for('student_analysis')
    end.should == stats
  end

  it 'does not generate its CSV attachment more than necessary' do
    stats = @quiz.current_statistics_for 'student_analysis'
    attachment = stats.generate_csv
    stats.reload
    stats.csv_attachment.should be_present

    stats.expects(:build_csv_attachment).never
    stats.generate_csv.should == attachment
  end
end
