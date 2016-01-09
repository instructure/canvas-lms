require_relative '../common'
require_relative '../helpers/quizzes_common'

describe 'taking a quiz' do
  include_context 'in-process server selenium tests'
  include QuizzesCommon

  context 'as a student' do
    before(:once) do
      course_with_teacher(active_all: 1)
      course_with_student(course: @course, active_all: 1)
    end

    before(:each) { user_session(@student) }

    def auto_submit_quiz(quiz)
      take_and_answer_quiz(submit: false, quiz: quiz)
      verify_times_up_dialog
      expect_new_page_load { close_times_up_dialog }
    end

    def verify_times_up_dialog
      keep_trying_until(10) { expect(fj('#times_up_dialog:visible')).to include_text 'Time\'s Up!' }
    end

    def verify_no_times_up_dialog
      expect(fj('#times_up_dialog:visible').nil?).to be_truthy
    end

    context 'when the quiz has a lock date' do
      let(:quiz_with_lock_date) { quiz_create(course: @course, lock_at: Time.zone.now.utc + 10.seconds) }

      it 'automatically submits the quiz once the quiz is locked', priority: "1", test_id: 209407 do
        auto_submit_quiz(quiz_with_lock_date)

        verify_quiz_is_locked
        verify_quiz_is_submitted
        verify_quiz_submission_is_not_late
      end

      it 'doesn\'t mark the quiz submission as "late"', priority: "1", test_id: 552276 do
        auto_submit_quiz(quiz_with_lock_date)
        verify_quiz_submission_is_not_late_in_speedgrader
      end

      context 'when the quiz is past due' do
        let(:quiz_past_due) do
          quiz_past_due = quiz_with_lock_date
          quiz_past_due.due_at = default_time_for_due_date(Time.zone.now - 2.days)
          quiz_past_due.save!
          quiz_past_due.reload
        end

        it 'automatically submits the quiz once the quiz is locked', priority: "1", test_id: 553506 do
          auto_submit_quiz(quiz_past_due)

          verify_quiz_is_locked
          verify_quiz_is_submitted
          verify_quiz_submission_is_late
        end

        it 'marks the quiz submission as "late"', priority: "1", test_id: 553015 do
          auto_submit_quiz(quiz_past_due)
          verify_quiz_submission_is_late_in_speedgrader
        end
      end

      context 'when the quiz has a future due date' do
        let(:quiz_due_in_future) do
          quiz_due_in_future = quiz_with_lock_date
          quiz_due_in_future.due_at = default_time_for_due_date(Time.zone.now + 2.days)
          quiz_due_in_future.save!
          quiz_due_in_future.reload
        end

        it 'automatically submits the quiz once the quiz is locked', priority: "1", test_id: 553013 do
          auto_submit_quiz(quiz_due_in_future)

          verify_quiz_is_locked
          verify_quiz_is_submitted
          verify_quiz_submission_is_not_late
        end

        it 'doesn\'t mark the quiz submission as "late"', priority: "1", test_id: 553507 do
          auto_submit_quiz(quiz_due_in_future)
          verify_quiz_submission_is_not_late_in_speedgrader
        end
      end
    end

    context 'when the quiz doesn\'t have a lock date' do
      context 'when the quiz is nearly due' do
        let(:quiz_nearly_due) { quiz_create(course: @course, due_at: Time.zone.now + 2.seconds) }

        it 'doesn\'t automatically submit once the due date passes', priority: "1", test_id: 551293 do
          skip('This spec takes too long to execute')

          take_and_answer_quiz(submit: false, quiz: quiz_nearly_due)

          # wait at least one minute for the due date to pass
          sleep(65)

          verify_no_times_up_dialog
          submit_quiz

          verify_quiz_submission_is_late
        end

        it 'marks the quiz submission as "late"', priority: "1", test_id: 551785 do
          skip('This spec takes too long to execute')

          take_and_answer_quiz(submit: false, quiz: quiz_nearly_due)

          # wait at least one minute for the due date to pass
          sleep(65)

          verify_no_times_up_dialog
          submit_quiz

          verify_quiz_submission_is_late_in_speedgrader
        end
      end
    end
  end
end
