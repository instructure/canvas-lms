# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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
#

describe Canvas::LiveEvents do
  before do
    LiveEvents.stream_client = Class.new do
      attr_accessor :data, :stream, :stream_name

      def initialize(stream_name = "stream")
        @stream_name = stream_name
      end

      def put_records(stream_name:, records:)
        @data = records
        @stream = stream_name
      end

      def valid?
        true
      end

      def stream_name
        @stream_name
      end
    end.new
  end

  def expect_event(event_name, event_body, event_context = nil)
    expect(LiveEvents).to receive(:post_event).with(
      event_name:,
      payload: event_body,
      time: anything,
      context: event_context
    )
  end

  describe ".quiz_extension_created" do
    before :once do
      course_factory
      @quiz = @course.quizzes.create!(title: "test quiz")
      @quiz.published_at = Time.zone.now
      @quiz.workflow_state = "available"
      @quiz.save!
      @student = student_in_course(course: @course, active_all: true).user
    end

    it "emits a quiz_extension_created event with extension data" do
      quiz_submission = @quiz.generate_submission(@student)
      quiz_submission.extra_attempts = 3
      quiz_submission.extra_time = 30
      quiz_submission.manually_unlocked = true
      quiz_submission.save!

      extension = Quizzes::QuizExtension.new(quiz_submission, {})

      expect_event("quiz_extension_created", {
                     quiz_id: quiz_submission.global_quiz_id.to_s,
                     user_id: quiz_submission.global_user_id.to_s,
                     extra_attempts: 3,
                     extra_time: 30,
                     manually_unlocked: true
                   })

      Canvas::LiveEvents.quiz_extension_created(extension)
    end

    it "emits event omitting nil fields via compact" do
      quiz_submission = @quiz.generate_submission(@student)
      quiz_submission.extra_attempts = 2
      quiz_submission.save!

      extension = Quizzes::QuizExtension.new(quiz_submission, {})

      expect_event("quiz_extension_created", {
                     quiz_id: quiz_submission.global_quiz_id.to_s,
                     user_id: quiz_submission.global_user_id.to_s,
                     extra_attempts: 2
                   })

      Canvas::LiveEvents.quiz_extension_created(extension)
    end
  end

end
