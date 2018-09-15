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

  let(:return_url) { 'http://www.platform.com/return_url' }
  let(:user) { @student }
  let(:opts) { { resource_type: 'course_navigation' } }
  let(:expander) do
    Lti::VariableExpander.new(
      course.root_account,
      course,
      nil,
      {
        current_user: user,
        tool: tool
      }
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

  let_once(:assignment) { assignment_model(course: course) }
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
    tool.course_navigation = { enabled: true, message_type: 'ResourceLinkRequest' }
    tool.settings['use_1_3'] = true
    tool.developer_key = DeveloperKey.create!
    tool.save!
    tool
  end

  describe '#generate_post_payload' do
    it "generates a resource link request if the tool's resource type setting is 'ResourceLinkRequest'" do
      jwt = JSON::JWT.decode(adapter.generate_post_payload[:id_token], :skip_verification)
      expect(jwt["https://purl.imsglobal.org/spec/lti/claim/message_type"]).to eq "LtiResourceLinkRequest"
    end
  end

  describe '#generate_post_payload_for_assignment' do
    let(:outcome_service_url) { 'https://www.outcome_service_url.com' }
    let(:legacy_outcome_service_url) { 'https://www.legacy_url.com' }
    let(:lti_turnitin_outcomes_placement_url) { 'https://www.turnitin.com' }

    it 'adds assignment specific claims' do
      jws = adapter.generate_post_payload_for_assignment(
        assignment,
        outcome_service_url,
        legacy_outcome_service_url,
        lti_turnitin_outcomes_placement_url
      )
      params = JSON::JWT.decode(jws[:id_token], :skip_verification)
      expect(params['https://www.instructure.com/lis_outcome_service_url']).to eq outcome_service_url
    end
  end

  describe '#generate_post_payload_for_homework_submission' do
    it 'adds hoemwork specific claims' do
      jws = adapter.generate_post_payload_for_homework_submission(assignment)
      params = JSON::JWT.decode(jws[:id_token], :skip_verification)
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