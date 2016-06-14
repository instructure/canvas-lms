require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

module Turnitin
  describe OutcomeResponseProcessor do

    let(:lti_student) { user_model }
    let(:lti_course) { course_with_student({user: lti_student}).course }
    let(:tool) do
      tool = lti_course.context_external_tools.new(
          name: "bob",
          consumer_key: "bob",
          shared_secret: "bob",
          tool_id: 'some_tool',
          privacy_level: 'public'
      )
      tool.url = "http://www.example.com/basic_lti"
      tool.resource_selection = {
          :url => "http://#{HostUrl.default_host}/selection_test",
          :selection_width => 400,
          :selection_height => 400}
      tool.save!
      tool
    end

    let(:lti_assignment) do
      assignment = assignment_model(course: lti_course)
      tag = assignment.build_external_tool_tag(url: tool.url)
      tag.content_type = 'ContextExternalTool'
      tag.content_id = tool.id
      tag.save!
      assignment
    end

    let(:attachment) do
      Attachment.create! uploaded_data: StringIO.new('blah'),
                         context: lti_course,
                         filename: 'blah.txt'
    end

    let(:outcome_response_json) do
      {
          "paperid" => 200505101,
          "outcomes_tool_placement_url" => "https://sandbox.turnitin.com/api/lti/1p0/outcome_tool_data/200505101?lang=en_us",
          "lis_result_sourcedid" => Lti::LtiOutboundAdapter.new(tool, lti_student, lti_course).encode_source_id(lti_assignment)
      }
    end

    subject { described_class.new(tool, lti_assignment, lti_student, outcome_response_json) }

    describe '#process' do
      let(:filename) {'my_sample_file'}

      before(:each) do
        mock_response = mock('response_mock')
        mock_response.stubs(:headers).returns(
            {'content-disposition' => "attachment; filename=#{filename}", 'content-type' => 'plain/text'}
        )
        mock_response.stubs(:body).returns('1234')
        TurnitinApi::OutcomesResponseTransformer.any_instance.expects(:original_submission).yields(mock_response)
      end

      it 'creates an attachment' do
        subject.process_without_send_later
        attachment = lti_assignment.attachments.first
        expect(lti_assignment.attachments.count).to eq 1
        expect(attachment.display_name).to eq filename
      end

      it 'sets the turnitin status to pending' do
        subject.process_without_send_later
        submission = lti_assignment.submissions.first
        attachment = lti_assignment.attachments.first
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq 'pending'
      end

    end

    describe "#update_originality_data" do
      it 'sets an error message if max attempts are exceeded' do
        mock_turnitin_client = mock('turnitin_client')
        mock_turnitin_client.stubs(:scored?).returns(false)
        subject.instance_variable_set(:@turnitin_client, mock_turnitin_client)
        submission = lti_assignment.submit_homework(lti_student, attachments:[attachment], submission_type: 'online_upload')
        subject.update_originality_data(submission, attachment.asset_string, (OutcomeResponseProcessor::MAX_ATTEMPTS+1))
        expect(submission.turnitin_data[attachment.asset_string][:status]).to eq 'error'
        expect(submission.turnitin_data[attachment.asset_string][:public_error_message]).to start_with "Turnitin has not"
      end
    end

  end
end