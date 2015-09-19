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

require 'nokogiri'

describe GradebooksHelper do
  FakeAssignment = Struct.new(:grading_type, :quiz).freeze
  FakeSubmission = Struct.new(:assignment, :score, :grade, :submission_type,
                              :workflow_state, :excused?).freeze
  FakeQuiz = Struct.new(:survey, :anonymous_submissions) do
    def survey?
      survey
    end
  end.freeze

  let(:assignment) { FakeAssignment.new }
  let(:submission) { FakeSubmission.new(assignment) }
  let(:quiz) { assignment.quiz = FakeQuiz.new }

  describe '#force_anonymous_grading?' do
    it 'requires a quiz' do
      expect(helper.force_anonymous_grading?(assignment)).to eq false
    end

    it 'is falsy with just a survey' do
      quiz.survey = true
      expect(helper.force_anonymous_grading?(assignment)).to eq false
    end

    it 'is falsy with just anonymous_submissions' do
      quiz.anonymous_submissions = true
      expect(helper.force_anonymous_grading?(assignment)).to eq false
    end

    it 'is truthy with an anonymous survey' do
      quiz.survey = true
      quiz.anonymous_submissions = true
      expect(helper.force_anonymous_grading?(assignment)).to eq true
    end
  end

  describe '#student_score_display_for(submission, can_manage_grades)' do

    let(:score_display) { helper.student_score_display_for(submission) }
    let(:parsed_display) { Nokogiri::HTML.parse(score_display) }
    let(:score_icon) { parsed_display.at_css('i') }
    let(:score_screenreader_text) { parsed_display.at_css('.screenreader-only').text }

    context 'when the supplied submission is nil' do
      it 'must return a dash' do
        score = helper.student_score_display_for(nil)
        expect(score).to eq '-'
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
            expect(score_icon['class']).to include 'icon-check'
          end

          it 'must indicate the assignment is complete via alt text' do
            expect(score_screenreader_text).to include 'Complete'
          end
        end

        context 'with a faililng grade' do
          before do
            submission.grade = 'incomplete'
            submission.score = nil
          end

          it 'must give us a check icon' do
            expect(score_icon['class']).to include 'icon-x'
          end

          it 'must indicate the assignment is complete via alt text' do
            expect(score_screenreader_text).to include 'Incomplete'
          end
        end
      end

      context 'and the assignment is a percentage grade' do
        it 'must output the percentage' do
          assignment.grading_type = 'percent'
          submission.grade = '42.5%'
          expect(score_display).to eq '42.5%'
        end
      end

      context 'and the assignment is a point grade' do
        it 'must output the grade rounded to two decimal points' do
          assignment.grading_type = 'points'
          submission.grade = '42.3542'
          submission.score = 42.3542
          expect(score_display).to eq 42.35
        end
      end

      context 'and the assignment is a letter grade' do
        # clearly this code needs to change; just look at this nonsensical expectation:
        it 'has no score_display' do
          assignment.grading_type = 'letter_grade'
          submission.grade = 'B'
          submission.score = 83
          expect(score_display).to be_nil
        end
      end

      context 'and the assignment is a gpa scaled grade' do
        # clearly this code needs to change; just look at this nonsensical expectation:
        it 'has no score_display' do
          assignment.grading_type = 'gpa_scale'
          submission.grade = 'B'
          submission.score = 83
          expect(score_display).to be_nil
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
          expect(score_icon['class']).to include 'submission_icon'
        end
      end

      context 'and the submission is some unknown type' do
        it 'must output a dash' do
          submission.submission_type = 'bogus_type'
          expect(score_display).to eq '-'
        end
      end
    end
  end
end
