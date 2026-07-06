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

describe Quizzes::NewQuizAccommodationsController, type: :request do
  include WebMock::API

  before :once do
    course_factory
    @teacher = teacher_in_course(course: @course, active_all: true).user
    @student = student_in_course(course: @course, active_all: true).user
    @assignment = @course.assignments.create!(title: "New Quiz", submission_types: "external_tool")
    tool = @course.context_external_tools.create!(
      name: "Quizzes.Next",
      url: "http://example.com/launch",
      consumer_key: "key",
      shared_secret: "secret",
      tool_id: "Quizzes 2"
    )
    tag = @assignment.build_external_tool_tag(url: tool.url)
    tag.content_type = "ContextExternalTool"
    tag.content_id = tool.id
    tag.save!
    @assignment.external_tool_tag = tag
    @assignment.save!
  end

  describe "GET /api/v1/courses/:course_id/new_quizzes/:assignment_id/accommodations (index)" do
    let(:nq_api_host) { "https://quiz-lti.example.com" }

    before do
      allow(Services::NewQuizzes).to receive(:api_gateway_host).and_return(nq_api_host)
    end

    context "as a student" do
      it "is unauthorized" do
        @user = @student
        raw_api_call(:get,
                     "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations",
                     { controller: "quizzes/new_quiz_accommodations",
                       action: "index",
                       format: "json",
                       course_id: @course.id.to_s,
                       assignment_id: @assignment.id.to_s })
        assert_status(403)
      end
    end

    context "as a teacher" do
      before do
        @user = @teacher
      end

      it "returns accommodations from the New Quizzes service" do
        stub_request(:get, "#{nq_api_host}/api/assignments/#{@assignment.id}/participants")
          .to_return(
            status: 200,
            body: [
              { "user_id" => @student.id, "extra_time" => 30, "extra_attempts" => 2, "reduce_choices_enabled" => true }
            ].to_json,
            headers: { "Content-Type" => "application/json" }
          )

        res = api_call(:get,
                       "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations",
                       { controller: "quizzes/new_quiz_accommodations",
                         action: "index",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: @assignment.id.to_s })

        expect(res["accommodations"].length).to be 1
        expect(res["accommodations"][0]["user_id"]).to eql(@student.id)
        expect(res["accommodations"][0]["extra_time"]).to be 30
        expect(res["accommodations"][0]["extra_attempts"]).to be 2
        expect(res["accommodations"][0]["reduce_choices_enabled"]).to be true
      end

      it "returns empty list when no accommodations are set" do
        stub_request(:get, "#{nq_api_host}/api/assignments/#{@assignment.id}/participants")
          .to_return(
            status: 200,
            body: [
              { "user_id" => @student.id }
            ].to_json,
            headers: { "Content-Type" => "application/json" }
          )

        res = api_call(:get,
                       "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations",
                       { controller: "quizzes/new_quiz_accommodations",
                         action: "index",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: @assignment.id.to_s })

        expect(res["accommodations"]).to eql([])
      end

      it "returns 422 if assignment is not a New Quiz" do
        regular_assignment = @course.assignments.create!(title: "Regular", submission_types: "online_text_entry")
        raw_api_call(:get,
                     "/api/v1/courses/#{@course.id}/new_quizzes/#{regular_assignment.id}/accommodations",
                     { controller: "quizzes/new_quiz_accommodations",
                       action: "index",
                       format: "json",
                       course_id: @course.id.to_s,
                       assignment_id: regular_assignment.id.to_s })
        assert_status(422)
      end

      it "returns 503 if New Quizzes service is not configured" do
        allow(Services::NewQuizzes).to receive(:api_gateway_host).and_return(nil)
        raw_api_call(:get,
                     "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations",
                     { controller: "quizzes/new_quiz_accommodations",
                       action: "index",
                       format: "json",
                       course_id: @course.id.to_s,
                       assignment_id: @assignment.id.to_s })
        assert_status(503)
      end

      it "returns 502 when service communication fails" do
        stub_request(:get, "#{nq_api_host}/api/assignments/#{@assignment.id}/participants")
          .to_raise(Timeout::Error)

        res = api_call(:get,
                       "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations",
                       { controller: "quizzes/new_quiz_accommodations",
                         action: "index",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: @assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 502 })

        expect(res["errors"][0]["message"]).to eql("Unable to communicate with New Quizzes service")
      end

      it "returns 502 when service returns non-200 status" do
        stub_request(:get, "#{nq_api_host}/api/assignments/#{@assignment.id}/participants")
          .to_return(status: 500, body: "Internal Server Error")

        res = api_call(:get,
                       "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations",
                       { controller: "quizzes/new_quiz_accommodations",
                         action: "index",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: @assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 502 })

        expect(res["errors"][0]["message"]).to eql("New Quizzes service error")
      end

      it "returns 502 when service returns invalid JSON" do
        stub_request(:get, "#{nq_api_host}/api/assignments/#{@assignment.id}/participants")
          .to_return(status: 200, body: "<html>Error</html>")

        res = api_call(:get,
                       "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations",
                       { controller: "quizzes/new_quiz_accommodations",
                         action: "index",
                         format: "json",
                         course_id: @course.id.to_s,
                         assignment_id: @assignment.id.to_s },
                       {},
                       {},
                       { expected_status: 502 })

        expect(res["errors"][0]["message"]).to eql("New Quizzes service error")
      end
    end
  end

  describe "GET /api/v1/courses/:course_id/new_quizzes/:assignment_id/accommodations/:user_id (show)" do
    let(:nq_api_host) { "https://quiz-lti.example.com" }

    before do
      allow(Services::NewQuizzes).to receive(:api_gateway_host).and_return(nq_api_host)
      @user = @teacher
    end

    it "returns the accommodation for a specific user" do
      stub_request(:get, "#{nq_api_host}/api/assignments/#{@assignment.id}/participants")
        .to_return(
          status: 200,
          body: [
            { "user_id" => @student.id, "extra_time" => 45, "extra_attempts" => 1 }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      res = api_call(:get,
                     "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations/#{@student.id}",
                     { controller: "quizzes/new_quiz_accommodations",
                       action: "show",
                       format: "json",
                       course_id: @course.id.to_s,
                       assignment_id: @assignment.id.to_s,
                       user_id: @student.id.to_s })

      expect(res["accommodation"]["user_id"]).to eql(@student.id)
      expect(res["accommodation"]["extra_time"]).to be 45
      expect(res["accommodation"]["extra_attempts"]).to be 1
    end

    it "returns 404 when no accommodation exists for user" do
      original_student = @student
      other_student = student_in_course(course: @course, active_all: true).user
      @user = @teacher
      stub_request(:get, "#{nq_api_host}/api/assignments/#{@assignment.id}/participants")
        .to_return(
          status: 200,
          body: [
            { "user_id" => original_student.id, "extra_time" => 45 }
          ].to_json,
          headers: { "Content-Type" => "application/json" }
        )

      api_call(:get,
               "/api/v1/courses/#{@course.id}/new_quizzes/#{@assignment.id}/accommodations/#{other_student.id}",
               { controller: "quizzes/new_quiz_accommodations",
                 action: "show",
                 format: "json",
                 course_id: @course.id.to_s,
                 assignment_id: @assignment.id.to_s,
                 user_id: other_student.id.to_s },
               {},
               {},
               { expected_status: 404 })
    end
  end
end
