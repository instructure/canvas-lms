require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'pipeline service' do
  let(:serializer_instance) { double('serializer_instance', call: nil) }
  let(:enrollment) { double('enrollment', pipeline_serializer: double('serializer_class', new: serializer_instance), id: 1) }

  before do
    ENV['PIPELINE_USER_NAME'] = nil
  end

  it 'wont raise an error through the api cus its queued' do
    expect { PipelineService.publish(enrollment) }.to_not raise_error
  end

  it 'calling it directly will raise an error since its not queued' do
    expect { PipelineService::Commands::Send.new(object: enrollment).call }.to raise_error(
      ArgumentError, 'Missing environment variables for the pipeline client'
    )
  end
end
