require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::LogAuditing::QuestionAnsweredEventOptimizer do
  describe '#run!' do
    def build_event(answers)
      Quizzes::QuizSubmissionEvent.new.tap do |event|
        event.answers = answers.as_json
      end
    end

    def run(event, predecessors)
      subject.run!(event.answers, predecessors)
    end

    it 'should be a noop if there are no previous events' do
      event = build_event [{ quiz_question_id: 1, answer: '11' }]

      expect(run(event, [])).to eq false
    end

    it 'should include newly recorded answers' do
      event1 = build_event [{ quiz_question_id: '1', answer: '11' }]
      event2 = build_event [{ quiz_question_id: '2', answer: '21' }]

      expect(run(event2, [ event1 ])).to eq false
      expect(event2.answers.length).to eq 1
    end

    it 'should include answers that have changed' do
      event1 = build_event [{ quiz_question_id: '1', answer: '11' }]
      event2 = build_event [{ quiz_question_id: '1', answer: '12' }]

      expect(run(event2, [ event1 ])).to eq false
      expect(event2.answers.length).to eq 1
    end

    it 'should not include answers otherwise' do
      event1 = build_event [
        { quiz_question_id: '1', answer: '11' },
        { quiz_question_id: '2', answer: '21' }
      ]

      event2 = build_event [
        { quiz_question_id: '1', answer: '11' },
        { quiz_question_id: '2', answer: '21' }
      ]

      expect(event2.answers.length).to eq 2

      expect(run(event2, [ event1 ])).to eq true

      expect(event2.answers.length).to eq 0
    end
  end
end
