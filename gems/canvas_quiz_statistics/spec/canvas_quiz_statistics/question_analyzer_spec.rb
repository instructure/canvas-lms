require 'spec_helper'

describe CanvasQuizStatistics::QuestionAnalyzer do
  subject do
    described_class.new(@question_data || { })
  end

  it 'should not break with no responses' do
    expect { subject.run([]) }.to_not raise_error
  end

  it 'should embed the output of the answer analyzer' do
    @question_data = {
      question_type: 'stubbed_question'
    }
    responses = [{ user_id: 1, text: 'foobar' }]
    answer_analysis = { some_metric: 12 }

    analyzer = double
    analyzer.should_receive(:run).with(@question_data, responses).and_return(answer_analysis)
    analyzer.should_receive(:answer_present?).and_return(true)

    analyzer_generator = double
    analyzer_generator.should_receive(:new).and_return(analyzer)
    CanvasQuizStatistics::AnswerAnalyzers.stub :[] => analyzer_generator

    output = subject.run(responses)
    output[:some_metric].should == 12
  end

  describe ':answered' do
    it ':count - the number of students who provided an answer' do
      output = subject.run([
        { text: 'hi', user_id: 1 },
        { text: 'hello', user_id: 3 }
      ])

      # answer_analyzer.stub(:answer_present?).and_return(true)
      output[:responses].should == 2
      output[:user_ids].should == [1,3]
    end
  end
end
