#
# Copyright (C) 2016 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/turnitin_spec_helper')
require 'turnitin_api'
module Turnitin
  describe AttachmentManager do
    include_context "shared_tii_lti"
    before(:each) do
      TiiClient.stubs(:new).with(lti_student, lti_assignment, tool, outcome_response_json).returns(tii_client)
    end

    describe '.create_attachment' do
      it 'creates an attachment' do
        expect do
          subject.class.create_attachment(lti_student, lti_assignment, tool, outcome_response_json)
        end.to change{lti_assignment.attachments.count}.by(1)
      end

      it 'uses the filename from the tii client' do
        subject.class.create_attachment(lti_student, lti_assignment, tool, outcome_response_json)
        expect(lti_assignment.attachments.first.display_name).to eq filename
      end

      it 'assigns the correct user' do
        subject.class.create_attachment(lti_student, lti_assignment, tool, outcome_response_json)
        expect(lti_assignment.attachments.first.user).to eq lti_student
      end

    end

    describe '.update_attachment' do
      let(:submission) do
        sub = lti_assignment.submit_homework(
          lti_student,
          attachments: [attachment],
          submission_type: 'online_upload',
        )
        sub.turnitin_data = {attachment.asset_string => {outcome_response: outcome_response_json}}
        sub.save!
        sub
      end

      it 'updates the submission' do
        updated_attachment = Turnitin::AttachmentManager.update_attachment(submission, attachment)
        expect(updated_attachment.display_name).to eq filename
      end

      it 'works when there is only a url in the content_tag' do
        tag = lti_assignment.external_tool_tag
        tag.content_id = nil
        tag.save!
        updated_attachment = Turnitin::AttachmentManager.update_attachment(submission, attachment)
        expect(updated_attachment.display_name).to eq filename
      end

    end

  end
end
