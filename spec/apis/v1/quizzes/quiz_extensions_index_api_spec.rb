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
require_relative "../../api_spec_helper"

describe Quizzes::QuizExtensionsController, type: :request do
  before :once do
    course_factory
    @quiz = @course.quizzes.create!(title: "quiz")
    @quiz.published_at = Time.zone.now
    @quiz.workflow_state = "available"
    @quiz.save!
    @student1 = student_in_course(course: @course, active_all: true).user
    @student2 = student_in_course(course: @course, active_all: true).user
    @teacher = teacher_in_course(course: @course, active_all: true).user
  end

  describe "GET /api/v1/courses/:course_id/quizzes/:quiz_id/extensions (index)" do
    def api_list_quiz_extensions(opts = {})
      api_call(:get,
               "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/extensions",
               { controller: "quizzes/quiz_extensions",
                 action: "index",
                 format: "json",
                 course_id: @course.id.to_s,
                 quiz_id: @quiz.id.to_s },
               {},
               {},
               opts)
    end

    context "as a student" do
      it "is unauthorized" do
        @user = @student1
        raw_api_call(:get,
                     "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/extensions",
                     { controller: "quizzes/quiz_extensions",
                       action: "index",
                       format: "json",
                       course_id: @course.id.to_s,
                       quiz_id: @quiz.id.to_s })
        assert_status(403)
      end
    end

    context "as a teacher" do
      before :once do
        @user = @teacher
      end

      it "returns empty list when no extensions exist" do
        res = api_list_quiz_extensions
        expect(res["quiz_extensions"]).to eql([])
      end

      it "returns extensions for students with extra_attempts" do
        sub = @quiz.generate_submission(@student1)
        sub.extra_attempts = 3
        sub.save!

        res = api_list_quiz_extensions
        expect(res["quiz_extensions"].length).to be 1
        expect(res["quiz_extensions"][0]["user_id"]).to eql(@student1.id)
        expect(res["quiz_extensions"][0]["extra_attempts"]).to be 3
      end

      it "returns extensions for students with extra_time" do
        sub = @quiz.generate_submission(@student1)
        sub.extra_time = 30
        sub.save!

        res = api_list_quiz_extensions
        expect(res["quiz_extensions"].length).to be 1
        expect(res["quiz_extensions"][0]["user_id"]).to eql(@student1.id)
        expect(res["quiz_extensions"][0]["extra_time"]).to be 30
      end

      it "returns extensions for students with manually_unlocked" do
        sub = @quiz.generate_submission(@student1)
        sub.manually_unlocked = true
        sub.save!

        res = api_list_quiz_extensions
        expect(res["quiz_extensions"].length).to be 1
        expect(res["quiz_extensions"][0]["user_id"]).to eql(@student1.id)
        expect(res["quiz_extensions"][0]["manually_unlocked"]).to be true
      end

      it "returns extensions for multiple students" do
        sub1 = @quiz.generate_submission(@student1)
        sub1.extra_attempts = 2
        sub1.save!

        sub2 = @quiz.generate_submission(@student2)
        sub2.extra_time = 60
        sub2.save!

        res = api_list_quiz_extensions
        expect(res["quiz_extensions"].length).to be 2
      end

      it "does not return submissions without extensions" do
        @quiz.generate_submission(@student1)

        sub2 = @quiz.generate_submission(@student2)
        sub2.extra_attempts = 5
        sub2.save!

        res = api_list_quiz_extensions
        expect(res["quiz_extensions"].length).to be 1
        expect(res["quiz_extensions"][0]["user_id"]).to eql(@student2.id)
      end

      it "filters by user_id when provided" do
        sub1 = @quiz.generate_submission(@student1)
        sub1.extra_attempts = 2
        sub1.save!

        sub2 = @quiz.generate_submission(@student2)
        sub2.extra_time = 60
        sub2.save!

        res = api_call(:get,
                       "/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}/extensions",
                       { controller: "quizzes/quiz_extensions",
                         action: "index",
                         format: "json",
                         course_id: @course.id.to_s,
                         quiz_id: @quiz.id.to_s },
                       { user_id: @student1.id })
        expect(res["quiz_extensions"].length).to be 1
        expect(res["quiz_extensions"][0]["user_id"]).to eql(@student1.id)
      end
    end
  end
end
