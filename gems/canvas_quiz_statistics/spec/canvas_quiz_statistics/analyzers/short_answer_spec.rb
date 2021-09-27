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

describe CanvasQuizStatistics::Analyzers::ShortAnswer do
  let(:question_data) { QuestionHelpers.fixture('short_answer_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect { expect(subject.run([])).to be_present }.to_not raise_error
  end

  it_behaves_like '[:correct]'

  describe '[:responses]' do
    it 'should count those who wrote a correct answer' do
      expect(subject.run([{ answer_id: 4684 }])[:responses]).to eq(1)
      expect(subject.run([{ answer_id: 1797 }])[:responses]).to eq(1)
    end

    it 'should count those who wrote an incorrect answer' do
      expect(subject.run([{ text: 'foobar' }])[:responses]).to eq(1)
    end

    it 'should not count those who wrote nothing' do
      expect(subject.run([{}])[:responses]).to eq(0)
      expect(subject.run([{ text: '' }])[:responses]).to eq(0)
    end

    it 'should not get confused by some non-existing answer' do
      expect(subject.run([{ answer_id: 'asdf' }])[:responses]).to eq(0)
      expect(subject.run([{ answer_id: nil }])[:responses]).to eq(0)
      expect(subject.run([{ answer_id: true }])[:responses]).to eq(0)
    end
  end

  describe '[:answers]' do
    it 'generates the "other" answer for incorrect answers' do
      stats = subject.run([{ text: '12345' }])
      answer = stats[:answers].detect do |answer|
        answer[:id] == CanvasQuizStatistics::Analyzers::Base::Constants::UnknownAnswerKey
      end

      expect(answer).to be_present
      expect(answer[:responses]).to eq(1)
    end
  end
end
