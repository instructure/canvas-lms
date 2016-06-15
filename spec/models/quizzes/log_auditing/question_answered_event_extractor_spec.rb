require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Quizzes::LogAuditing::QuestionAnsweredEventExtractor do
  require File.expand_path(File.dirname(__FILE__) + '/../../../quiz_spec_helper.rb')

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

  describe '#build_event' do
    it do
      quiz_submission = Quizzes::QuizSubmission.new
      quiz_submission.quiz_data = quiz_data

      event = subject.build_event({
        "attempt" => 1,
        "question_1" => "11" # choose the answer "A" in MC question
      }, quiz_submission)

      expect(event.attempt).to eq 1
      expect(event.event_type).to be_present
      expect(event.event_data).not_to be_empty
    end
  end

  describe '#create_event!' do
    before(:once) do
      course = Course.create

      quiz = course.quizzes.create

      @quiz_submission = quiz.generate_submission(user)
      @quiz_submission.quiz_data = quiz_data
      @quiz_submission.save!
    end

    before(:each) do
      @quiz_submission.events.destroy_all
    end

    def subject(submission_data)
      described_class.new.create_event!(submission_data.stringify_keys, @quiz_submission)
    end

    it 'should create an event' do
      event = subject({ "attempt" => 1, "question_1" => "11" })
      expect(event).to be_truthy
    end

    it 'should not save empty events' do
      event = subject({ "attempt" => 1 })
      expect(event).to be_nil
    end

    describe 'extracting answers' do
      it 'extracts from flat submission_data using AnswerSerializers' do
        event = subject({ "attempt" => 1, "question_1" => "11" })

        expect(event.answers.length).to eq 1
        expect(event.answers.first.as_json).to eq({
          quiz_question_id: "1",
          answer: "11"
        }.as_json)
      end
    end

    describe 'optimizing' do
      it 'should optimize against all previous events' do
        event1 = subject({
          "attempt" => 1,
          "question_1" => "11",
          "question_2" => "21"
        })

        event2 = subject({
          "attempt" => 1,
          "question_1" => "11",
          "question_2" => "22"
        })

        expect(event1.answers.length).to equal 2
        expect(event2.answers.length).to equal 1
      end

      it 'should not save redundant events' do
        event1 = subject({
          "attempt" => 1,
          "question_1" => "11"
        })

        event2 = subject({
          "attempt" => 1,
          "question_1" => "11"
        })

        expect(event1).to be_truthy
        expect(event2).to be_nil
      end

      it 'should not explode on unknown question types' do
        # This can happen on a failed QTI import
        @quiz_submission.quiz_data[0]["question_type"] = "Error"
        event1 = subject({
          "attempt" => 1,
          "question_1" => ""
        })
        expect(event1).to be_truthy
      end

      describe '[integration] a quiz-taking scenario' do
        def answer_and_generate_event(submission_data, created_at)
          submission_data['attempt'] = @quiz_submission.attempt

          Timecop.freeze(created_at) do
            subject(submission_data)
          end
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

          four = answer_and_generate_event({
            question_1: 12,
            question_2: 21
          }, 3.seconds.from_now)

          # first save, it keeps everything:
          expect(one.answers.as_json).to eq [{
            quiz_question_id: "1",
            answer: 11
          }].as_json

          # second save, it keeps the changed answer for question2:
          expect(two.answers.as_json).to eq [{
            quiz_question_id: "2",
            answer: 21
          }].as_json

          # third save, it keeps the changed answer for question1:
          expect(three.answers.as_json).to eq [{
            quiz_question_id: "1",
            answer: 12
          }].as_json

          # fourth save, nothing has changed, it keeps nothing:
          expect(four).to be_nil
        end
      end
    end # optimizing
  end # #create_event!
end
