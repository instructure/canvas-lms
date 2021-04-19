# frozen_string_literal: true

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

shared_examples_for "Quizzes::QuizStatistics::Report" do
  # let(:report_type) - report_type to test

  before(:once) do
    student_in_course(:active_all => true)
    @quiz = @course.quizzes.create!
    @quiz.quiz_questions.create!(:question_data => { :name => "test 1" })
    @quiz.generate_quiz_data
    @quiz.published_at = Time.now
    @quiz.save!
  end

  it 'provides progress updates' do
    @quiz.statistics_csv(report_type, :async => true)
    run_jobs
    progress = @quiz.quiz_statistics.first.progress
    expect(progress.completion).to eq 100
    expect(progress).to be_completed
  end

end
