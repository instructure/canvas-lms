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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')
require File.expand_path(File.dirname(__FILE__) + '/../../lti_1_3_spec_helper')

describe Lti::LtiAdvantageAdapter do
  include_context 'lti_1_3_spec_helper'
  include Lti::RedisMessageClient

  let!(:lti_user_id) { Lti::Asset.opaque_identifier_for(@student) }
  let(:return_url) { 'http://www.platform.com/return_url' }
  let(:user) { @student }
  let(:opts) { { resource_type: 'course_navigation', domain: 'test.com' } }
  let(:expander_opts) { { current_user: user, tool: tool } }
  let(:expander) do
    Lti::VariableExpander.new(
      course.root_account,
      course,
      nil,
      expander_opts
    )
  end
  let(:adapter) do
    Lti::LtiAdvantageAdapter.new(
      tool: tool,
      user: user,
      context: course,
      return_url: return_url,
      expander: expander,
      opts: opts
    )
  end
  let(:tool) do
    tool = course.context_external_tools.new(
      name: 'bob',
      consumer_key: 'key',
      shared_secret: 'secret',
      url: 'http://www.example.com/basic_lti'
    )
    tool.course_navigation = { enabled: true, message_type: 'ResourceLinkRequest' }
    tool.use_1_3 = true
    tool.developer_key = DeveloperKey.create!
    tool.save!
    tool
  end
  let(:login_message) { adapter.generate_post_payload }
  let(:verifier) { Canvas::Security.decode_jwt(login_message['lti_message_hint'])['verifier'] }
  let(:params) { JSON.parse(fetch_and_delete_launch(course, verifier)) }
  let(:assignment) do
    assignment_model(
      course: course,
      submission_types: 'external_tool',
      external_tool_tag_attributes: { content: tool }
    )
  end
  let_once(:course) do
    course_with_student
    @course
  end

  describe '#generate_post_payload' do
    it "generates a resource link request if the tool's resource type setting is 'ResourceLinkRequest'" do
      expect(params["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiResourceLinkRequest"
    end

    it 'creats a login message' do
      expect(login_message.keys).to match_array [
        "iss",
        "login_hint",
        "target_link_uri",
        "lti_message_hint"
      ]
    end

    it 'sets the "login_hint" to the current user LTI ID' do
      expect(login_message['login_hint']).to eq lti_user_id
    end

    it 'sets the domain in the message hint' do
      expect(Canvas::Security.decode_jwt(login_message['lti_message_hint'])['canvas_domain']).to eq 'test.com'
    end
  end

  describe '#generate_post_payload_for_assignment' do
    let(:outcome_service_url) { 'https://www.outcome_service_url.com' }
    let(:legacy_outcome_service_url) { 'https://www.legacy_url.com' }
    let(:lti_turnitin_outcomes_placement_url) { 'https://www.turnitin.com' }
    let(:params) { JSON.parse(fetch_and_delete_launch(course, verifier)) }
    let(:verifier) do
      jws = adapter.generate_post_payload_for_homework_submission(assignment)['lti_message_hint']
      Canvas::Security.decode_jwt(jws)['verifier']
    end
    let(:expander_opts) { super().merge(assignment: assignment) }

    it 'adds assignment specific claims' do
      expect(params['https://www.instructure.com/canvas_assignment_title']).to eq assignment.title
    end
  end

  describe '#generate_post_payload_for_homework_submission' do
    let(:verifier) do
      jws = adapter.generate_post_payload_for_homework_submission(assignment)['lti_message_hint']
      Canvas::Security.decode_jwt(jws)['verifier']
    end
    let(:params) { JSON.parse(fetch_and_delete_launch(course, verifier)) }

    it 'adds hoemwork specific claims' do
      expect(params['https://www.instructure.com/content_file_extensions']).to eq assignment.allowed_extensions&.join(',')
    end
  end

  describe '#launch_url' do
    it 'returns the resource-specific launch URL if set' do
      tool.course_navigation = {
        enabled: true,
        message_type: 'ResourceLinkRequest',
        url: 'https://www.launch.com/course-navigation'
      }
      tool.save!
      expect(adapter.launch_url).to eq 'https://www.launch.com/course-navigation'
    end

    it 'returns the general launch URL if no resource url is set' do
      expect(adapter.launch_url).to eq 'http://www.example.com/basic_lti'
    end
  end
end
