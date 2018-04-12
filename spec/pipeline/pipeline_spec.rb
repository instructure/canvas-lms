require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'pipeline service' do
  before do
    @user = account_admin_user
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
    @enrollment.course = @course
    @enrollment.save!
  end

  context "Missing configuration" do
    before do
      ENV['PIPELINE_USER_NAME'] = nil
    end

    it 'wont raise an error through the api cus its queued' do
      expect { PipelineService.publish(@enrollment) }.to_not raise_error
    end

    it 'calling it directly will raise an error since its not queued' do
      expect { PipelineService::Commands::Send.new(object: @enrollment).call }.to raise_error(
        ArgumentError, 'Missing environment variables for the pipeline client'
      )
    end
  end

  context "Submission" do
    let(:context) { double('context') }
    let(:assignment) { double('assignment', context: context, submission_types:        []) }
    let(:user) { double('user') }

    let(:submission) do
      double(
        "submission",
        pipeline_serializer:     PipelineService::Serializers::Submission,
        assignment:              assignment,
        'assignment=' =>         nil,
        quiz_submission_version: 1,
        '[]' =>                  'user',
        media_comment_id:        1,
        media_comment_type:      '',
        originality_reports:     [],
        originality_data:        [],
        vericite_data:           {},
        versioned_attachments:   [],
        attachment:              nil

      )
    end

    before do
      Api.instance_variable_set('@current_user', user)
    end

    it do
      PipelineService::Commands::Send.new(object: submission).call
    end

  end

end
