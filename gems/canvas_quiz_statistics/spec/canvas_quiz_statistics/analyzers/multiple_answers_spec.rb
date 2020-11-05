# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::MultipleAnswers do
  let(:question_data) { QuestionHelpers.fixture('multiple_answers_question') }

  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { expect(subject.run([])).to be_present }.to_not raise_error
  end

  describe '[:responses]' do
    it 'should count students who picked any answer' do
      expect(subject.run([{ answer_5514: '1' }])[:responses]).to eq(1)
    end

    it 'should not count those who did not' do
      expect(subject.run([{}])[:responses]).to eq(0)
      expect(subject.run([{ answer_5514: '0' }])[:responses]).to eq(0)
    end

    it 'should not get confused by an imaginary answer' do
      expect(subject.run([{ answer_1234: '1' }])[:responses]).to eq(0)
    end
  end

  it_behaves_like '[:correct]'
  it_behaves_like '[:partially_correct]'

  describe '[:answers][]' do
    it 'generate "none" answer for those who picked no choice at all' do
      stats = subject.run([{}])

      answer = stats[:answers].detect do |answer|
        answer[:id] == Constants::MissingAnswerKey
      end

      expect(answer).to be_present
      expect(answer[:responses]).to eq(1)
    end
  end

  describe '[:answers][]' do
    describe '[:responses]' do
      it 'should count students who picked this answer' do
        stats = subject.run([{ answer_5514: '1' }])
        expect(stats[:answers].detect { |a| a[:id] == '5514' }[:responses]).to eq(1)
      end

      it 'should not count those who did not' do
        stats = subject.run([{ answer_5514: '1', answer_4261: '0' }])
        expect(stats[:answers].detect { |a| a[:id] == '4261' }[:responses]).to eq(0)
      end
    end
  end
end
