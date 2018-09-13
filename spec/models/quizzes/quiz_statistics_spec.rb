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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

require 'csv'

describe Quizzes::QuizStatistics do

  before(:once) do
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
    stats.reload_csv_attachment.open.read
  end

  it "should use the last completed submission, even if the current submission is in progress" do
    # one complete submission
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission

    # and one in progress
    qs = @quiz.generate_submission(@student)

    stats = @quiz.statistics(false)
    expect(stats[:multiple_attempts_exist]).to be_falsey
  end

  it 'should include previous versions even if the current version is incomplete' do
    # one complete submission
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission

    # and one in progress
    @quiz.generate_submission(@student)

    stats = CSV.parse(csv(:include_all_versions => true))
    expect(stats.first.length).to eq 10
  end

  it 'should not include previous versions by default' do
    # two complete submissions
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission
    qs = @quiz.generate_submission(@student)
    Quizzes::SubmissionGrader.new(qs).grade_submission

    stats = CSV.parse(csv)
    expect(stats.first.length).to eq 10
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

    expect(stats2).not_to eq stats1
    expect(stats3).to eq stats2
  end

  it 'generates a new quiz_statistics if new submissions are in' do
    stats = @quiz.current_statistics_for('student_analysis')

    @quiz.quiz_submissions.build.tap do |qs|
      qs.save!
      qs.mark_completed
    end

    expect(@quiz.current_statistics_for('student_analysis')).not_to eq stats
  end

  it 'uses the previously generated quiz_statistics if possible' do
    stats = @quiz.current_statistics_for 'student_analysis'

    expect(Timecop.freeze(5.minutes.from_now) do
      @quiz.current_statistics_for('student_analysis')
    end).to eq stats
  end

  it 'does not generate its CSV attachment more than necessary' do
    stats = @quiz.current_statistics_for 'student_analysis'
    attachment = stats.generate_csv
    stats.reload
    expect(stats.csv_attachment).to be_present

    expect(stats).to receive(:build_csv_attachment).never
    expect(stats.generate_csv).to eq attachment
  end

  it 'could possibly tell whether CSV generation has gone bananas' do
    stats = @quiz.current_statistics_for 'student_analysis'

    allow_any_instance_of(Quizzes::QuizStatistics::StudentAnalysis).to receive(:to_csv) {
      throw 'totally bananas'
    }

    stats.generate_csv_in_background
    run_jobs
    stats.reload

    expect(stats.csv_generation_failed?).to be_truthy
  end

  it "uses inst-fs to store attachment when enabled" do
    allow(InstFS).to receive(:enabled?).and_return(true)
    @uuid = "1234-abcd"
    allow(InstFS).to receive(:direct_upload).and_return(@uuid)

    stats = @quiz.current_statistics_for 'student_analysis'
    attachment = stats.generate_csv
    expect(attachment.instfs_uuid).to eq(@uuid)
  end

  it "doesn't use inst-fs if not enabled" do
    allow(InstFS).to receive(:enabled?).and_return(false)
    stats = @quiz.current_statistics_for 'student_analysis'
    attachment = stats.generate_csv
    expect(attachment.instfs_uuid).to eq(nil)
  end

  describe 'self#large_quiz?' do
    let :active_quiz_questions do
      double(size: 50)
    end

    let :quiz_submissions do
      double(size: 15)
    end

    let :quiz do
      Quizzes::Quiz.new.tap do |quiz|
        allow(quiz).to receive(:active_quiz_questions).and_return(active_quiz_questions)
        allow(quiz).to receive(:quiz_submissions).and_return(quiz_submissions)
      end
    end

    context 'quiz_statistics_max_questions' do
      it 'should be true when there are too many questions' do
        expect(Setting).to receive(:get).with('quiz_statistics_max_questions',
          Quizzes::QuizStatistics::DefaultMaxQuestions).and_return 25

        expect(Quizzes::QuizStatistics.large_quiz?(quiz)).to be_truthy
      end

      it 'should be false otherwise' do
        expect(Setting).to receive(:get).with('quiz_statistics_max_questions',
          Quizzes::QuizStatistics::DefaultMaxQuestions).and_return 100

        expect(Setting).to receive(:get).with('quiz_statistics_max_submissions',
          Quizzes::QuizStatistics::DefaultMaxSubmissions).and_return 25

        expect(Quizzes::QuizStatistics.large_quiz?(quiz)).to be_falsey
      end
    end

    context 'quiz_statistics_max_submissions' do
      it 'should be true when there are too many submissions' do
        expect(Setting).to receive(:get).with('quiz_statistics_max_questions',
          Quizzes::QuizStatistics::DefaultMaxQuestions).and_return 100
        expect(Setting).to receive(:get).with('quiz_statistics_max_submissions',
          Quizzes::QuizStatistics::DefaultMaxSubmissions).and_return 5

        expect(Quizzes::QuizStatistics.large_quiz?(quiz)).to be_truthy
      end

      it 'should be false otherwise' do
        expect(Setting).to receive(:get).with('quiz_statistics_max_questions',
          Quizzes::QuizStatistics::DefaultMaxQuestions).and_return 100
        expect(Setting).to receive(:get).with('quiz_statistics_max_submissions',
          Quizzes::QuizStatistics::DefaultMaxSubmissions).and_return 25

        expect(Quizzes::QuizStatistics.large_quiz?(quiz)).to be_falsey
      end
    end
  end
end
