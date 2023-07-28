# frozen_string_literal: true

#
# Copyright (C) 2018 - present Instructure, Inc.
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

require "lti_advantage"

require_relative "message_claims_examples"

module LtiAdvantage::Messages
  RSpec.describe ResourceLinkRequest do
    let(:message) { ResourceLinkRequest.new }
    let(:valid_message) do
      ResourceLinkRequest.new(
        aud: ["129aeb8c-a267-4551-bb5f-e6fc308fcecf"],
        azp: "163440e5-1c75-4c28-a07c-43e8a9cd3110",
        sub: "7da708b6-b6cf-483b-b899-11831c685b6f",
        deployment_id: "ee493d2e-9f2e-4eca-b2a0-122413887caa",
        iat: 1_529_681_618,
        exp: 1_529_681_634,
        iss: "https://platform.example.edu",
        nonce: "5a234202-6f0e-413d-8793-809db7a95930",
        resource_link: LtiAdvantage::Claims::ResourceLink.new(id: 1),
        roles: ["foo"],
        target_link_uri: "https://www.example.com",
        lti11_legacy_user_id: "bcf1466791073638f61073818abf1d32331fc893"
      )
    end

    describe "initializer" do
      it 'defaults "message_type" to "LtiResourceLinkRequest' do
        expect(message.message_type).to eq "LtiResourceLinkRequest"
      end

      it 'defaults "version" to "1.3.0' do
        expect(message.version).to eq "1.3.0"
      end
    end

    describe "attributes" do
      it "initializes the context when it is referenced" do
        message.context.id = 23
        expect(message.context.id).to eq 23
      end

      it 'initializes "resource_link" when it is referenced' do
        message.resource_link.id = 23
        expect(message.resource_link.id).to eq 23
      end

      it 'initalizes "launch_presentation" when it is referenced' do
        message.launch_presentation.width = 100
        expect(message.launch_presentation.width).to eq 100
      end

      it 'initalizes "tool_platform" when it is referenced' do
        message.tool_platform.name = "foo"
        expect(message.tool_platform.name).to eq "foo"
      end

      it 'initializes "names_and_roles_service" when it is referenced' do
        message.names_and_roles_service.context_memberships_url = "http://some.meaningless.url.com"
        expect(message.names_and_roles_service.context_memberships_url).to eq "http://some.meaningless.url.com"
      end

      it 'initializes "assignment_and_grade_service" when it is referenced' do
        message.assignment_and_grade_service.lineitems = "http://some.meaningless.url.com"
        expect(message.assignment_and_grade_service.lineitems).to eq "http://some.meaningless.url.com"
      end
    end

    describe "validations" do
      include_context "message_claims_examples"

      it_behaves_like "validations for claims types"

      it_behaves_like "validations for optional claims"

      it "is not valid if required claims are missing" do
        expect(message).not_to be_valid
      end

      it "is valid if all required claims are present" do
        expect(valid_message).to be_valid
      end

      it "validates sub claims" do
        message = ResourceLinkRequest.new(
          aud: ["129aeb8c-a267-4551-bb5f-e6fc308fcecf"],
          azp: "163440e5-1c75-4c28-a07c-43e8a9cd3110",
          sub: "7da708b6-b6cf-483b-b899-11831c685b6f",
          deployment_id: "ee493d2e-9f2e-4eca-b2a0-122413887caa",
          iat: 1_529_681_618,
          exp: 1_529_681_634,
          iss: "https://platform.example.edu",
          nonce: "5a234202-6f0e-413d-8793-809db7a95930",
          resource_link: LtiAdvantage::Claims::ResourceLink.new(id: 1),
          roles: ["foo"],
          context: LtiAdvantage::Claims::Context.new
        )
        message.validate
        expect(message.errors.messages.keys).to include(:context)
      end

      it 'verifies that "resource_link" is an Platform' do
        message.resource_link = "foo"
        message.validate
        expect(message.errors.messages[:resource_link]).to match_array [
          "resource_link must be an instance of LtiAdvantage::Claims::ResourceLink"
        ]
      end

      it 'verifies that "names_and_roles_service" is a NamesAndRolesService' do
        message.names_and_roles_service = "foo"
        message.validate
        expect(message.errors.messages[:names_and_roles_service]).to match_array [
          "names_and_roles_service must be an instance of LtiAdvantage::Claims::NamesAndRolesService"
        ]
      end

      it 'verifies that "assignment_and_grade_service" is an AssignmentAndGradeService' do
        message.assignment_and_grade_service = "foo"
        message.validate
        expect(message.errors.messages[:assignment_and_grade_service]).to match_array [
          "assignment_and_grade_service must be an instance of LtiAdvantage::Claims::AssignmentAndGradeService"
        ]
      end
    end
  end
end
