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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe GradebooksHelper do
  describe '#student_score_display_for(submission, can_manage_grades)' do
    FakeSubmission = Struct.new(:assignment, :score, :grade, :submission_type)
    FakeAssignment = Struct.new(:grading_type)

    let(:submission) { FakeSubmission.new(assignment) }
    let(:assignment) { FakeAssignment.new }

    let(:score_display) { helper.student_score_display_for(submission) }
    let(:parsed_display) { Nokogiri::HTML.parse(score_display) }
    let(:score_icon) { parsed_display.at_css('i') }
    let(:score_screenreader_text) { parsed_display.at_css('.screenreader-only').text }

    context 'when the supplied submission is nil' do
      it 'must return a dash' do
        score = helper.student_score_display_for(nil)
        score.should == '-'
      end
    end

    context 'when the submission has been graded' do
      before do
        submission.score = 1
        submission.grade = 1
      end

      context 'and the assignment is graded pass-fail' do
        before do
          assignment.grading_type = 'pass_fail'
        end

        context 'with a passing grade' do
          before do
            submission.score = 1
          end

          it 'must give us a check icon' do
            score_icon['class'].should include 'icon-check'
          end

          it 'must indicate the assignment is complete via alt text' do
            score_screenreader_text.should include 'Complete'
          end
        end

        context 'with a faililng grade' do
          before do
            submission.grade = 'incomplete'
            submission.score = nil
          end

          it 'must give us a check icon' do
            score_icon['class'].should include 'icon-x'
          end

          it 'must indicate the assignment is complete via alt text' do
            score_screenreader_text.should include 'Incomplete'
          end
        end
      end

      context 'and the assignment is a percentage grade' do
        it 'must output the percentage' do
          assignment.grading_type = 'percent'
          submission.grade = '42.5%'
          score_display.should == '42.5%'
        end
      end

      context 'and the grade field matches the score field' do
        it 'must output the grade rounded to two decimal points' do
          submission.grade = '42.3542'
          submission.score = 42.3542
          score_display.should == 42.35
        end
      end
    end

    context 'when the submission is ungraded' do
      before do
        submission.score = nil
        submission.grade = nil
      end

      context 'and the submission is an online submission type' do
        it 'must output an appropriate icon' do
          submission.submission_type = 'online_quiz'
          score_icon['class'].should include 'submission_icon'
        end
      end

      context 'and the submission is some unknown type' do
        it 'must output a dash' do
          submission.submission_type = 'bogus_type'
          score_display.should == '-'
        end
      end
    end
  end
end
