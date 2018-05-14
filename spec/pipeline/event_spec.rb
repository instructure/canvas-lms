require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'pipeline service' do
  let(:endpoint_instance) { double('endpoint instance', call: nil) }
  let(:endpoint) { double('endpoint class', new: endpoint_instance) }
  let(:http_client) { double('http_client') }

  before do
    ENV['SYNCHRONOUS_PIPELINE_JOBS'] = 'true'
    allow(
      PipelineService::Events::Responders::SIS::PostJob
    ).to receive(:http_client).and_return(http_client)

    @user = account_admin_user
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
    @enrollment.course = @course
    @enrollment.save!
  end

  it do
    expect(http_client).to receive(:post)
    @enrollment.update(workflow_state: 'completed')
  end
end
