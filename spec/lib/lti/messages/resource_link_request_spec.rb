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

require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../../lti_1_3_spec_helper')

describe Lti::Messages::ResourceLinkRequest do
  include_context 'lti_1_3_spec_helper'

  let(:return_url) { 'http://www.platform.com/return_url' }
  let(:opts) { { resource_type: 'course_navigation' } }
  let(:lti_assignment) { Lti::LtiAssignmentCreator.new(assignment).convert }
  let(:expander) do
    Lti::VariableExpander.new(
      course.root_account,
      course,
      nil,
      {
        current_user: user,
        tool: tool,
        assignment: assignment
      }
    )
  end
  let(:assignment) do
    assignment_model(
      course: course,
      submission_types: 'external_tool',
      external_tool_tag_attributes: { content: tool }
    )
  end
  let_once(:user) { user_model(email: 'banana@test.com') }
  let_once(:course) do
    course_with_student
    @course
  end
  let(:tool) do
    tool = course.context_external_tools.new(
      name: 'bob',
      consumer_key: 'key',
      shared_secret: 'secret',
      url: 'http://www.example.com/basic_lti'
    )
    tool.course_navigation = {
      enabled: true,
      message_type: 'ResourceLinkRequest',
      selection_width: '500',
      selection_height: '400',
      custom_fields: {
        has_expansion: '$User.id',
        no_expansion: 'foo'
      }
    }
    tool.use_1_3 = true
    tool.developer_key = DeveloperKey.create!
    tool.save!
    tool
  end

  shared_examples 'disabled rlid claim group check' do
    let(:opts) { super().merge({claim_group_blacklist: [:rlid]}) }

    it 'does not set the resource link id' do
      expect(jws).not_to include('https://purl.imsglobal.org/spec/lti/claim/resource_link')
    end
  end

  describe '#initialize' do
    let(:jws) { jwt_message.generate_post_payload }

    it 'adds public claims if the tool is public' do
      tool.update!(workflow_state: 'public')
      expect(jws['picture']).to eq user.avatar_url
    end

    it 'does not add public claims if the tool is not public' do
      tool.update!(workflow_state: 'private')
      expect(jws).not_to include 'picture'
    end

    it 'adds include email claims if the tool is include email' do
      tool.update!(workflow_state: 'email_only')
      expect(jws['email']).to eq user.email
    end

    it 'does not add include email claims if the tool is not include email' do
      user.update!(email: 'banana@test.com')
      tool.update!(workflow_state: 'private')
      expect(jws).not_to include 'email'
    end

    it 'adds include name claims if the tool is include name' do
      tool.update!(workflow_state: 'name_only')
      expect(jws['name']).to eq user.name
    end

    it 'does not add include name claims if the tool is not include name' do
      tool.update!(workflow_state: 'private')
      expect(jws).not_to include 'name'
    end

    it 'adds private claims' do
      allow(I18n).to receive(:locale).and_return('en')
      expect(jws['locale']).to eq 'en'
    end

    it 'adds security claims' do
      expected_sub = Lti::Asset.opaque_identifier_for(user)
      expect(jws['sub']).to eq expected_sub
    end

    it 'sets the resource link id' do
      expect_course_resource_link_id(jws)
    end

    it_behaves_like 'disabled rlid claim group check'
  end

  shared_examples 'assignment resource link id check' do
    let(:launch_error) { Lti::Ims::AdvantageErrors::InvalidLaunchError }
    let(:api_message) { raise 'set in example' }
    let(:course_jws) { jwt_message.generate_post_payload }

    shared_examples 'launch error check' do
      it 'raises launch error' do
        expect { jws }.to raise_error(launch_error, "#{launch_error} :: #{api_message}") do |e|
          expect(e.api_message).to eq api_message
        end
      end
    end

    it 'sets the assignment as resource link id' do
      expect_assignment_resource_link_id(jws)
    end

    context 'when assignment not configured for external tool lauch' do
      let(:api_message) { 'Assignment not configured for external tool launches' }

      before do
        assignment.update_attributes!(submission_types: 'none')
      end

      it_behaves_like 'launch error check'
    end

    context 'when tool bindings are unexpected' do
      let(:different_tool) do
        tool = course.context_external_tools.new(
          name: 'bob2',
          consumer_key: 'key2',
          shared_secret: 'secret2',
          url: 'http://www.example2.com/basic_lti'
        )
        tool.save!
        tool
      end

      context 'because the assignment tool binding does not match the launching tool' do
        let(:api_message) { 'Assignment not configured for launches with specified tool' }

        before do
          assignment.update_attributes!(external_tool_tag_attributes: { content: different_tool })
        end

        it_behaves_like 'launch error check'
      end

      context 'because the resource link tool binding does not match the launching tool' do
        let(:api_message) { 'Mismatched assignment vs resource link tool configurations' }

        before do
          assignment.line_items.find(&:assignment_line_item?).resource_link.update_attributes!(context_external_tool: different_tool)
        end

        it_behaves_like 'launch error check'
      end
    end

    it_behaves_like 'disabled rlid claim group check'
  end

  shared_examples 'assignment common extensions check' do
    it 'adds the canvas_assignment_id if the tool is public' do
      tool.update!(workflow_state: 'public')
      expect(jws['https://www.instructure.com/canvas_assignment_id']).to eq assignment.id
    end

    it 'does not add the canvas_assignment_id if the tool is not public' do
      tool.update!(workflow_state: 'private')
      expect(jws).not_to include 'https://www.instructure.com/canvas_assignment_id'
    end

    it 'adds the canvas_assignment_title' do
      expect(jws['https://www.instructure.com/canvas_assignment_title']).to eq assignment.title
    end

    it 'adds the canvas_assignment_points_possible' do
      expect(jws['https://www.instructure.com/canvas_assignment_points_possible']).to eq assignment.points_possible
    end
  end

  describe '#generate_post_payload_for_assignment' do
    let(:outcome_service_url) { 'https://www.outcome-service-url.com' }
    let(:legacy_outcome_service_url) { 'https://www.legacy-outcome-service-url.com' }
    let(:lti_turnitin_outcomes_placement_url) { 'https://www.lti-turnitin-outcomes-placement-url.com' }

    let(:jws) do
      jwt_message.generate_post_payload_for_assignment(
        assignment,
        outcome_service_url,
        legacy_outcome_service_url,
        lti_turnitin_outcomes_placement_url
      )
    end

    # Bunch of negative tests for claims that were previously added but then support was intentionally removed from the impl
    it 'does not add lis_result_sourcedid' do
      expect(jws).not_to include 'https://www.instructure.com/lis_result_sourcedid'
    end

    it 'does not add lis_outcome_service_url' do
      expect(jws).not_to include 'https://www.instructure.com/lis_outcome_service_url'
    end

    it 'does not add ims_lis_basic_outcome_url' do
      expect(jws).not_to include 'https://www.instructure.com/ims_lis_basic_outcome_url'
    end

    it 'does not add outcome_data_values_accepted' do
      expect(jws).not_to include 'https://www.instructure.com/outcome_data_values_accepted'
    end

    it 'does not add outcome_result_total_score_accepted' do
      expect(jws).not_to include 'https://www.instructure.com/outcome_result_total_score_accepted'
    end

    it 'does not add outcome_submission_submitted_at_accepted' do
      expect(jws).not_to include 'https://www.instructure.com/outcome_submission_submitted_at_accepted'
    end

    it 'does not add outcomes_tool_placement_url' do
      expect(jws).not_to include 'https://www.instructure.com/outcomes_tool_placement_url'
    end

    it_behaves_like 'assignment common extensions check'
    it_behaves_like 'assignment resource link id check'
  end

  describe '#generate_post_payload_for_homework_submission' do
    let(:jws) { jwt_message.generate_post_payload_for_homework_submission(assignment) }

    it 'adds the content_return_types' do
      expect(jws['https://www.instructure.com/content_return_types']).to eq lti_assignment.return_types.join(',')
    end

    it 'adds the content_file_extensions' do
      expect(jws['https://www.instructure.com/content_file_extensions']).to eq assignment.allowed_extensions&.join(',')
    end

    it_behaves_like 'assignment common extensions check'
    it_behaves_like 'assignment resource link id check'
  end

  def jwt_message
    Lti::Messages::ResourceLinkRequest.new(
      tool: tool,
      context: course,
      user: user,
      expander: expander,
      return_url: return_url,
      opts: opts
    )
  end

  def expect_assignment_resource_link_id(jws)
    rlid = assignment.line_items.first.resource_link.resource_link_id
    expect(jws.dig('https://purl.imsglobal.org/spec/lti/claim/resource_link', 'id')).to eq rlid
  end

  def expect_course_resource_link_id(jws)
    expect(jws.dig('https://purl.imsglobal.org/spec/lti/claim/resource_link', 'id')).to eq course.lti_context_id
  end
end
