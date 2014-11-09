require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Quizzes::QuizSubmissionEvent do
  require File.expand_path(File.dirname(__FILE__) + '/../../quiz_spec_helper.rb')

  before :once do
    Account.default.enable_feature!(:draft_state)
  end

  def build_event(submission_data, quiz_data)
    described_class.build_from_submission_data(submission_data, quiz_data)
  end

  def multiple_choice_question_data
    JSON.parse <<-JSON
    {
      "id": 1,
      "points_possible": 1,
      "name": "MC Question",
      "question_name": "MC Question",
      "question_type": "multiple_choice_question",
      "question_text": "A (hint: choose it!!), B, C, or D?",
      "answers": [
        {
          "id": 11,
          "text": "A",
          "weight": 100
        },
        {
          "id": 12,
          "text": "B",
          "weight": 0
        },
        {
          "id": 13,
          "text": "C",
          "weight": 0
        },
        {
          "id": 14,
          "text": "D",
          "weight": 0
        }
      ]
    }
    JSON
  end

  def true_false_question_data
    JSON.parse <<-JSON
    {
      "id": 2,
      "points_possible": 1,
      "name": "T/F Question",
      "question_name": "T/F Question",
      "question_type": "true_false_question",
      "question_text": "Yes (hint: probably!!!), or no?",
      "answers": [
        {
          "id": 21,
          "text": "Yes",
          "weight": 100
        },
        {
          "id": 22,
          "text": "No",
          "weight": 0
        }
      ]
    }
    JSON
  end

  def quiz_data
    [ multiple_choice_question_data, true_false_question_data ]
  end

  def submission_data_sample_one
    JSON.parse <<-JSON
      {
        "attempt": 1,
        "question_1": "11" // choose the answer "A" in MC question
      }
      JSON
  end

  describe '#self.build_from_submission_data' do
    it do
      submission_data = submission_data_sample_one

      event = build_event(submission_data, quiz_data)
      expect(event.attempt).to eq 1
      expect(event.event_type).to be_present
      expect(event.answers).not_to be_empty
    end
  end

  describe '#self.infer_event_type' do
    it do
      expect(described_class.infer_event_type({})).to eq Quizzes::QuizSubmissionEvent::EVT_ANSWERED
    end
  end

  describe '#self.extract_answers' do
    it do
      submission_data = submission_data_sample_one

      answers = described_class.extract_answers(submission_data, quiz_data)
      expect(answers.length).to eq 1
      expect(answers.first.as_json).to eq({
        quiz_question_id: "1",
        answer: 11
      }.as_json)
    end
  end

  describe '#optimize_answers' do
    let :event do
      event = build_event(submission_data_sample_one, quiz_data)
      event.created_at = 5.minutes.ago
      event
    end

    it 'should be a noop if there are no previous events' do
      expect(event.optimize_answers).to be false
    end

    it 'should not include answers recorded in a previous event' do
      second_event_data = JSON.parse <<-JSON
      {
        "question_1": 11, // should not be included
        "question_2": 21  // should be
      }
      JSON

      next_event = build_event(second_event_data, quiz_data)
      expect(next_event.answers.length).to eq 2
      expect(next_event.optimize_answers(event)).to be true
      expect(next_event.answers.length).to eq 1
      expect(next_event.answers.first.as_json).to eq({
        quiz_question_id: "2",
        answer: 21
      }.as_json)
    end
  end

  describe '[scope] self.predecessor_of' do
    let(:quiz) { quiz_model }
    let(:quiz_submission) { quiz.generate_submission(student_in_course.user) }

    it 'should work' do
      event_one = build_event({ attempt: 1 }, {})
      event_one.quiz_submission = quiz_submission
      event_one.save!

      event_two = build_event({ attempt: 1 }, {})
      event_two.quiz_submission = quiz_submission
      event_two.save!

      expect(event_one.predecessor).to eq nil
      expect(event_two.predecessor).to eq event_one
    end

    it 'is aware of attempts' do
      event_one = build_event({ attempt: 1 }, {})
      event_one.quiz_submission = quiz_submission
      event_one.save!

      event_two = build_event({ attempt: 2 }, {})
      event_two.quiz_submission = quiz_submission
      event_two.save!

      expect(event_one.predecessor).to eq nil
      expect(event_two.predecessor).to eq nil
    end
  end

  describe '[integration] a typical quiz-taking scenario' do
    def answer_and_generate_event(submission_data, created_at)
      params = {
        cnt: 4, # skip snapshot generation for speed
        attempt: @quiz_submission.attempt,
      }.merge(submission_data.with_indifferent_access)

      new_submission_data = @quiz_submission.backup_submission_data(params)

      build_event(new_submission_data, @quiz_submission.quiz_data).tap do |event|
        event.quiz_submission = @quiz_submission
        event.created_at = created_at
        event.optimize_answers
        event.save!
      end
    end

    before do
      @quiz = quiz_model.tap do |quiz|
        quiz.quiz_data = quiz_data
        quiz.workflow_state = 'published'
        quiz.published_at = Time.now
        quiz.save!
      end

      @quiz_submission = @quiz.generate_submission(student_in_course.user)
    end

    it 'should track only the things i did just now' do
      one = answer_and_generate_event({
        question_1: 11
      }, Time.now)

      two = answer_and_generate_event({
        question_1: 11,
        question_2: 21
      }, 1.second.from_now)

      three = answer_and_generate_event({
        question_1: 12,
        question_2: 21
      }, 2.seconds.from_now)

      expect(one.answers.as_json).to eq [{
        quiz_question_id: "1",
        answer: 11
      }].as_json

      expect(two.answers.as_json).to eq [{
        quiz_question_id: "2",
        answer: 21
      }].as_json

      expect(three.answers.as_json).to eq [{
        quiz_question_id: "1",
        answer: 12
      }].as_json
    end
  end

  describe '#empty?' do
    context Quizzes::QuizSubmissionEvent::EVT_ANSWERED do
      before do
        subject.event_type = Quizzes::QuizSubmissionEvent::EVT_ANSWERED
      end

      it 'should be true if it has no answer records' do
        expect(subject).to be_empty
      end

      it 'should not be true if it has any answer record' do
        subject.answers = [{}]
        expect(subject).not_to be_empty
      end

      it 'should be true after optimizing against a similar event' do
        one = build_event(submission_data_sample_one, quiz_data)
        two = build_event(submission_data_sample_one, quiz_data)

        expect(two).not_to be_empty

        two.optimize_answers(one)
        expect(two).to be_empty
      end
    end
  end

  describe '#==' do
    let(:one) { subject }
    let(:two) { subject.clone }

    it 'should never be true for two events of different types' do
      one.event_type = 'foo'
      two.event_type = 'bar'

      expect(one).not_to eq two
    end

    context Quizzes::QuizSubmissionEvent::EVT_ANSWERED do
      before do
        one.event_type = Quizzes::QuizSubmissionEvent::EVT_ANSWERED
        two.event_type = Quizzes::QuizSubmissionEvent::EVT_ANSWERED
      end

      it 'should be true if both events have no answers' do
        expect(one).to eq two
      end

      it 'should be true if both events have the same answers' do
        one.answers = [{ quiz_question_id: "1", answer: 11 }]
        two.answers = [{ quiz_question_id: "1", answer: 11 }]

        expect(one).to eq two
      end

      it 'should be false if answer record counts differ' do
        one.answers = [{}]
        two.answers = []

        expect(one).not_to eq two
      end

      it 'should be false if answer records differ' do
        one.answers = [{ quiz_question_id: "1", answer: 11 }]
        two.answers = [{ quiz_question_id: "1", answer: 12 }]

        expect(one).not_to eq two
      end
    end
  end
end
