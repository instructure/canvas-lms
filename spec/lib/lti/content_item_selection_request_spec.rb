#
# Copyright (C) 2017 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Lti::ContentItemSelectionRequest do
  subject(:lti_request) { described_class.new(course, root_account, teacher) }

  let(:course) { course_model }
  let(:root_account) { course.root_account }
  let(:teacher) { course_with_teacher(course: course).user }

  context '#generate_lti_launch' do
    it 'generates an Lti::Launch' do
      expect(lti_request.generate_lti_launch).to be_a Lti::Launch
    end

    it 'generates resource_url based on a launch_url' do
      lti_launch = lti_request.generate_lti_launch(launch_url: 'https://www.example.com')
      expect(lti_launch.resource_url).to eq 'https://www.example.com'
    end

    context 'params' do
      it 'builds a params hash that includes the default lti params' do
        lti_launch = lti_request.generate_lti_launch
        default_params = described_class.default_lti_params(course, root_account, teacher)
        expect(lti_launch.params).to include(default_params)
      end
    end
  end

  context '.default_lti_params' do
    before do
      allow(Lti::Asset).to receive(:opaque_identifier_for).with(course).and_return('course_opaque_id')
    end

    it 'generates default_lti_params' do
      root_account.lti_guid = 'account_guid'
      I18n.locale = :de

      params = described_class.default_lti_params(course, root_account)
      expect(params).to include({
        context_id: 'course_opaque_id',
        tool_consumer_instance_guid: 'account_guid',
        roles: 'urn:lti:sysrole:ims/lis/None',
        launch_presentation_locale: :de,
        launch_presentation_document_target: 'iframe',
        ext_roles: 'urn:lti:sysrole:ims/lis/None'
      })
    end

    it 'adds user information when a user is provided' do
      allow(Lti::Asset).to receive(:opaque_identifier_for).with(teacher).and_return('teacher_opaque_id')

      params = described_class.default_lti_params(course, root_account, teacher)

      expect(params).to include({
        roles: 'Instructor',
        user_id: 'teacher_opaque_id'
      })
      expect(params[:ext_roles]).to include('urn:lti:role:ims/lis/Instructor','urn:lti:sysrole:ims/lis/User')
    end
  end
end
