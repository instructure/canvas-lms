require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'pipeline service' do
  let(:endpoint_instance) { double('endpoint instance', call: nil) }
  let(:endpoint) { double('endpoint class', new: endpoint_instance) }
  let(:http_client) { double('http_client') }

  let(:enrollment) do
    @user = account_admin_user
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
    @enrollment.course = @course
    @enrollment.save!
    @enrollment
  end

  subject { enrollment }

  before do
    PipelineService.queue_mode = 'synchronous'
    allow(PipelineService::Events::HTTPClient).to receive(:post)
    allow(PipelineService::HTTPClient).to receive(:get).and_return(double('get_response', parsed_response: ''))
  end

  it 'will post to the client if workflow_state is "completed"'do
    expect(PipelineService::Events::HTTPClient).to receive(:post)
    subject.update(workflow_state: 'completed')
  end

  it 'will not post to the client if workflow_state is "completed"'do
    expect(PipelineService::Events::HTTPClient).to_not receive(:post)
    subject.update(workflow_state: 'invited')
  end
end
