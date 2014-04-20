require 'spec_helper'

describe CanvasQuizStatistics::AnswerAnalyzers::Essay do
  let(:question_data) { QuestionHelpers.fixture('essay_question') }

  it 'should not blow up when no responses are provided' do
    expect {
      subject.run(question_data, []).should be_present
    }.to_not raise_error
  end

  it "should not consider an answer to be present if it's empty" do
    subject.answer_present?({ text: nil }).should be_false
    subject.answer_present?({ text: '' }).should be_false
  end

  describe 'output [#run]' do
    describe ':full_credit' do
      it 'should count all students who received full credit' do
        output = subject.run(question_data, [
          { points: 3 }, { points: 2 }, { points: 3 }
        ])

        output[:full_credit].should == 2
      end

      it 'should be 0 otherwise' do
        output = subject.run(question_data, [
          { points: 1 }
        ])

        output[:full_credit].should == 0
      end
    end

    it ':graded - should reflect the number of graded answers' do
      output = subject.run(question_data, [
        { correct: 'defined' }, { correct: 'undefined' }
      ])

      output[:graded].should == 1
    end

    describe ':point_distribution' do
      it 'should map each score to the number of receivers' do
        output = subject.run(question_data, [
          { points: 1, user_id: 1 },
          { points: 3, user_id: 2 }, { points: 3, user_id: 3 },
          { points: nil, user_id: 5 }
        ])

        output[:point_distribution].should include({ score: nil, count: 1 })
        output[:point_distribution].should include({ score: 1, count: 1 })
        output[:point_distribution].should include({ score: 3, count: 2 })
      end

      it 'should sort them in score ascending mode' do
        output = subject.run(question_data, [
          { points: 3, user_id: 2 }, { points: 3, user_id: 3 },
          { points: 1, user_id: 1 },
          { points: nil, user_id: 5 }
        ])

        output[:point_distribution].map { |v| v[:score] }.should == [ nil, 1, 3 ]
      end
    end
  end
end
