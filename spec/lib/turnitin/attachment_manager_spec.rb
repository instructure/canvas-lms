require File.expand_path(File.dirname(__FILE__) + '/turnitin_spec_helper')
require 'turnitin_api'
module Turnitin
  describe AttachmentManager do
    include_context "shared_tii_lti"
    before(:each) do
      TiiClient.stubs(:new).returns(tii_client)
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
        lti_assignment.submit_homework(
          lti_student,
          attachments: [attachment],
          submission_type: 'online_upload'
        )
      end

      it 'updates the submission' do
        submission.turnitin_data[attachment.asset_string] = {outcome_response: {}}
        updated_attachment = subject.class.update_attachment(submission, attachment)
        expect(updated_attachment.display_name).to eq filename
      end

    end

  end
end
