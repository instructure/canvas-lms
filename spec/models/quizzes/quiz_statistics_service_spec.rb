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

describe Quizzes::QuizStatisticsService do

  let_once (:course) { Course.new.tap { |course| course.id = 1 } }
  let_once :quiz do
    Quizzes::Quiz.new.tap do |quiz|
      quiz.workflow_state = 'available'
      quiz.context = course
    end
  end

  subject { Quizzes::QuizStatisticsService.new quiz }

  describe '#generate_aggregate_statistics' do
    let :student_analysis do
      quiz.quiz_statistics.build({
        report_type: 'student_analysis',
        includes_all_versions: true,
        anonymous: false
      })
    end

    let :item_analysis do
      quiz.quiz_statistics.build({
        report_type: 'item_analysis',
        includes_all_versions: true,
        anonymous: false
      })
    end

    before do
      [ student_analysis, item_analysis ].each do |analysis|
        analysis.stubs(:save)
      end
    end

    after do
      Quizzes::QuizStatistics.unstub(:large_quiz?)
    end

    it 'should not generate for all versions of a large course' do
      Quizzes::QuizStatistics.stubs(:large_quiz?).returns true

      expect {
        subject.generate_aggregate_statistics(true)
      }.to raise_error(RequestError, 'operation not available for large quizzes')
    end

    it 'should generate for all quiz versions' do
      Quizzes::QuizStatistics.stubs(:large_quiz?).returns false

      quiz.expects(:current_statistics_for).with('student_analysis', {
        includes_all_versions: true
      }).returns(student_analysis)

      quiz.expects(:current_statistics_for).with('item_analysis').returns(item_analysis)

      subject.generate_aggregate_statistics(true)
    end

    it 'should generate for the latest quiz version' do
      Quizzes::QuizStatistics.stubs(:large_quiz?).returns false

      quiz.expects(:current_statistics_for).with('student_analysis', {
        includes_all_versions: false
      }).returns(student_analysis)

      quiz.expects(:current_statistics_for).with('item_analysis').returns(item_analysis)

      subject.generate_aggregate_statistics(false)
    end
  end
end
