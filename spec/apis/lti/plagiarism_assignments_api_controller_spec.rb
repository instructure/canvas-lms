# frozen_string_literal: true

#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative "lti2_api_spec_helper"
require_relative "../api_spec_helper"

module Lti
  describe PlagiarismAssignmentsApiController, type: :request do
    include_context "lti2_api_spec_helper"

    before do
      message_handler.update(capabilities: [Lti::ResourcePlacement::SIMILARITY_DETECTION_LTI2])
      tool_proxy.raw_data["security_contract"]["tool_service"] = authorized_services
      tool_proxy.save!
      assignment.tool_settings_tool = message_handler
      assignment.save!
    end

    describe "#show" do
      let(:service_name) { PlagiarismAssignmentsApiController::ASSIGNMENT_SERVICE }
      let(:endpoint) { "/api/lti/assignments" }
      let(:authorized_services) do
        [{ "service" => "vnd.Canvas.Assignment", "action" => ["GET"], "@type" => "RestServiceProfile" }]
      end
      let(:student) do
        student = create_users_in_course(course, 2, return_type: :record).first
        student.update(lti_context_id: SecureRandom.uuid)
        student
      end
      let(:assignment) do
        a = course.assignments.new(title: "some assignment", points_possible: 10, description: "<p>Dude...</p>", due_at: DateTime.now)
        a.workflow_state = "published"
        a.tool_settings_tool = message_handler
        a.save!
        a
      end
      let(:expected_assignment) do
        {
          "id" => assignment.id,
          "name" => assignment.name,
          "description" => assignment.description,
          "due_at" => assignment.due_at.iso8601,
          "points_possible" => assignment.points_possible,
          "lti_id" => assignment.lti_context_id,
          "lti_course_id" => Lti::Asset.opaque_identifier_for(assignment.context),
          "course_id" => assignment.context.global_id
        }
      end

      it "verifies the tool has the required services" do
        tool_proxy.raw_data["security_contract"]["tool_service"] = []
        tool_proxy.save!
        get "#{endpoint}/#{assignment.id}", headers: request_headers
        expect(response).to be_unauthorized
      end

      it "verifies the tool is associated with the assignment" do
        unrelated_assignment = assignment_model(context: course)
        get "#{endpoint}/#{unrelated_assignment.id}", headers: request_headers
        expect(response).to be_unauthorized
      end

      it "verifies the user is associated with the assignment" do
        user = user_model
        get "#{endpoint}/#{assignment.id}", params: { user_id: user.id }, headers: request_headers
        expect(response).to be_unauthorized
      end

      it "returns 404 when the assignment cannot be found" do
        user_model
        get "#{endpoint}/blah", headers: request_headers
        expect(response).to be_not_found
      end

      it "returns 404 when the user cannot be found" do
        user_model
        get "#{endpoint}/#{assignment.id}", params: { user_id: "blah" }, headers: request_headers
        expect(response).to be_not_found
      end

      it "returns an assignment by Canvas id" do
        get "#{endpoint}/#{assignment.id}", headers: request_headers
        parsed_body = JSON.parse(response.body)
        expect(parsed_body).to eq expected_assignment
      end

      it "returns an assignment by lti assignment id" do
        get "#{endpoint}/#{assignment.lti_context_id}", headers: request_headers
        parsed_body = JSON.parse(response.body)
        expect(parsed_body).to eq expected_assignment
      end

      it "returns an assignment with user lti id" do
        get "#{endpoint}/#{assignment.id}", params: { user_id: student.lti_context_id }, headers: request_headers
        parsed_body = JSON.parse(response.body)
        expect(parsed_body).to eq expected_assignment
      end

      it "returns an assignment with an old user lti id" do
        UserPastLtiId.create!(user: student, context: course, user_lti_id: student.lti_id, user_lti_context_id: "old_lti_id", user_uuid: "old")
        get "#{endpoint}/#{assignment.id}", params: { user_id: "old_lti_id" }, headers: request_headers
        parsed_body = JSON.parse(response.body)
        expect(parsed_body).to eq expected_assignment
      end

      it "returns an assignment with user Canvas id" do
        get "#{endpoint}/#{assignment.id}", params: { user_id: student.id }, headers: request_headers
        parsed_body = JSON.parse(response.body)
        expect(parsed_body).to eq expected_assignment
      end

      it "returns an assignment that is differentiated by user" do
        due_at = CanvasTime.fancy_midnight(3.days.from_now.midnight)

        create_adhoc_override_for_assignment(assignment, student, due_at:)

        get "#{endpoint}/#{assignment.id}", params: { user_id: student.id }, headers: request_headers
        parsed_body = JSON.parse(response.body)
        expect(parsed_body).to eq expected_assignment.merge("due_at" => due_at.iso8601)
      end
    end
  end
end
