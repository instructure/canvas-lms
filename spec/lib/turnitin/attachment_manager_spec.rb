# frozen_string_literal: true

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

require_relative "turnitin_spec_helper"
require "turnitin_api"
module Turnitin
  describe AttachmentManager do
    include_context "shared_tii_lti"
    before do
      allow(TiiClient).to receive(:new).with(lti_student, lti_assignment, tool, outcome_response_json).and_return(tii_client)
    end

    describe ".create_attachment" do
      it "creates an attachment" do
        expect do
          subject.class.create_attachment(tii_client, lti_student, lti_assignment)
        end.to change { lti_assignment.attachments.count }.by(1)
      end

      it "uses the filename from the tii client and replaces forward slashes with dashes" do
        subject.class.create_attachment(tii_client, lti_student, lti_assignment)
        expect(lti_assignment.attachments.first.display_name).to eq "my-new-filename.txt"
      end

      it "assigns the correct user" do
        subject.class.create_attachment(tii_client, lti_student, lti_assignment)
        expect(lti_assignment.attachments.first.user).to eq lti_student
      end

      context "when the TII response is an error" do
        let(:response_mock) do
          r_mock = double("response")
          allow(r_mock).to receive_messages(headers: {}, body: "abcdef", status: 401)
          r_mock
        end

        it "raises a OriginalSubmissionUnavailableError with the status code" do
          expect do
            subject.class.create_attachment(tii_client, lti_student, lti_assignment)
          end.to raise_error do |e|
            expect(e).to be_a(Turnitin::Errors::OriginalSubmissionUnavailableError)
            expect(e.status_code).to eq(401)
          end
        end
      end
    end

    describe ".update_attachment" do
      let(:submission) do
        sub = lti_assignment.submit_homework(
          lti_student,
          attachments: [attachment],
          submission_type: "online_upload"
        )
        sub.turnitin_data = { attachment.asset_string => { outcome_response: outcome_response_json } }
        sub.save!
        sub
      end

      it "updates the submission" do
        updated_attachment = Turnitin::AttachmentManager.update_attachment(submission, attachment)
        expect(updated_attachment.display_name).to eq "my-new-filename.txt"
      end

      it "works when there is only a url in the content_tag" do
        tag = lti_assignment.external_tool_tag
        tag.content_id = nil
        tag.save!
        updated_attachment = Turnitin::AttachmentManager.update_attachment(submission, attachment)
        expect(updated_attachment.display_name).to eq "my-new-filename.txt"
      end
    end
  end
end
