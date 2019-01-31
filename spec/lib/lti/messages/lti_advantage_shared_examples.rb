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

require File.expand_path(File.dirname(__FILE__) + '/../../../lti_1_3_spec_helper')

RSpec.shared_context 'lti_advantage_shared_examples' do
  include_context 'lti_1_3_spec_helper'

  let(:return_url) { 'http://www.platform.com/return_url' }
  let(:opts) { { resource_type: 'course_navigation' } }
  let(:lti_assignment) { Lti::LtiAssignmentCreator.new(assignment).convert }
  let(:deep_linking_return_url) { 'http://www.test.cop/success' }
  let(:controller) do
    controller = double('controller')
    allow(controller).to receive(:request).and_return(request)
    allow(controller).to receive(:polymorphic_url).and_return(deep_linking_return_url)
    controller
  end
  # All this setup just so we can stub out controller.*_url methods
  let(:request) do
    request = double('request')
    allow(request).to receive(:url).and_return('https://localhost')
    allow(request).to receive(:host).and_return('/my/url')
    allow(request).to receive(:scheme).and_return('https')
    request
  end
  let(:expander) do
    Lti::VariableExpander.new(
      course.root_account,
      course,
      controller,
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
    tool.developer_key = developer_key
    tool.save!
    tool
  end
  let(:developer_key) do
    DeveloperKey.create!(
      name: 'Developer Key With Scopes',
      account: course.root_account,
      scopes: developer_key_scopes,
      require_scopes: true
    )
  end
  let(:developer_key_scopes) { [] }

  shared_examples_for 'lti 1.3 message initialization' do
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

    it 'adds lti11_legacy_user_id' do
      expected_val = Lti::Asset.opaque_identifier_for(user)
      expect(jws['https://purl.imsglobal.org/spec/lti/claim/lti11_legacy_user_id']).to eq expected_val
    end

    it 'adds security claims' do
      expected_sub = user.lti_id
      expect(jws['sub']).to eq expected_sub
    end
  end
end
