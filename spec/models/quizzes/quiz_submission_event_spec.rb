require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizSubmissionEvent do
  describe '#empty?' do
    context Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED do
      before do
        subject.event_type = Quizzes::QuizSubmissionEvent::EVT_QUESTION_ANSWERED
      end

      it 'should be true if it has no answer records' do
        expect(subject).to be_empty
      end

      it 'should not be true if it has any answer record' do
        subject.answers = [{}]
        expect(subject).not_to be_empty
      end
    end
  end
end
