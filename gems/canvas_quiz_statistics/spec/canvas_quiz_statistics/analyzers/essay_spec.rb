require 'spec_helper'

describe CanvasQuizStatistics::Analyzers::Essay do
  let(:question_data) { QuestionHelpers.fixture('essay_question') }
  subject { described_class.new(question_data) }

  it 'should not blow up when no responses are provided' do
    expect {
      subject.run([]).should be_present
    }.to_not raise_error
  end

  it_behaves_like 'essay [:responses]'

  describe 'output [#run]' do
    describe '[:responses]' do
      it 'should count students who have written anything' do
        subject.run([{ text: 'foo' }])[:responses].should == 1
      end

      it 'should not count students who have written a blank response' do
        subject.run([{ }])[:responses].should == 0
        subject.run([{ text: nil }])[:responses].should == 0
        subject.run([{ text: '' }])[:responses].should == 0
      end
    end

    it ':graded - should reflect the number of graded answers' do
      output = subject.run([
        { correct: 'defined' }, { correct: 'undefined' }
      ])

      output[:graded].should == 1
    end

    describe ':full_credit' do
      let :question_data do
        { points_possible: 3 }
      end

      it 'should count all students who received full credit' do
        output = subject.run([
          { points: 3 }, { points: 2 }, { points: 3 }
        ])

        output[:full_credit].should == 2
      end

      it 'should count students who received more than full credit' do
        output = subject.run([
          { points: 3 }, { points: 2 }, { points: 5 }
        ])

        output[:full_credit].should == 2
      end

      it 'should be 0 otherwise' do
        output = subject.run([
          { points: 1 }
        ])

        output[:full_credit].should == 0
      end

      it 'should count those who exceed the maximum points possible' do
        output = subject.run([{ points: 5 }])
        output[:full_credit].should == 1
      end
    end

    describe ':answers' do
      let :question_data do
        { points_possible: 10 }
      end

      it 'should group items into answer type buckets with appropriate data' do
        output = subject.run([
          { points: 0, correct: 'undefined', user_name: 'Joe0'},
          { points: 0, correct: 'undefined', user_name: 'Joe0'},
          { points: 0, correct: 'undefined', user_name: 'Joe0'},
          { points: 1, correct: 'defined', user_name: 'Joe1'},
          { points: 2, correct: 'defined', user_name: 'Joe2'},
          { points: 3, correct: 'defined', user_name: 'Joe3'},
          { points: 4, correct: 'defined', user_name: 'Joe4'},
          { points: 6, correct: 'defined', user_name: 'Joe6'},
          { points: 7, correct: 'defined', user_name: 'Joe7'},
          { points: 8, correct: 'defined', user_name: 'Joe8'},
          { points: 9, correct: 'defined', user_name: 'Joe9'},
          { points: 10, correct: 'defined', user_name: 'Joe10'},
        ])
        answers = output[:answers]

        bottom = answers[2]
        expect(bottom[:responses]).to eq 2
        expect(bottom[:user_names]).to include('Joe1')
        expect(bottom[:full_credit]).to be_false

        middle = answers[1]
        expect(middle[:responses]).to eq 5
        expect(middle[:user_names]).to include('Joe6')
        expect(middle[:full_credit]).to be_false

        top = answers[0]
        expect(top[:responses]).to eq 2
        expect(top[:user_names]).to include('Joe10')
        expect(top[:full_credit]).to be_true

        undefined = answers[3]
        expect(undefined[:responses]).to eq 3
        expect(undefined[:user_names].uniq).to eq ['Joe0']
        expect(undefined[:full_credit]).to be_false
      end
    end

    describe ':point_distribution' do
      it 'should map each score to the number of receivers' do
        output = subject.run([
          { points: 1, user_id: 1 },
          { points: 3, user_id: 2 }, { points: 3, user_id: 3 },
          { points: nil, user_id: 5 }
        ])

        output[:point_distribution].should include({ score: nil, count: 1 })
        output[:point_distribution].should include({ score: 1, count: 1 })
        output[:point_distribution].should include({ score: 3, count: 2 })
      end

      it 'should sort them in score ascending mode' do
        output = subject.run([
          { points: 3, user_id: 2 }, { points: 3, user_id: 3 },
          { points: 1, user_id: 1 },
          { points: nil, user_id: 5 }
        ])

        output[:point_distribution].map { |v| v[:score] }.should == [ nil, 1, 3 ]
      end
    end
  end
end
