require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'pipeline service' do
  let(:endpoint_instance) { double('endpoint instance', call: nil) }
  let(:endpoint) { double('endpoint class', new: endpoint_instance) }
  let(:http_client) { double('http_client', messages_post: nil) }

  before do
    ENV['SYNCHRONOUS_PIPELINE_JOBS'] = 'true'
    @user = account_admin_user
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
    @enrollment.course = @course
    @enrollment.save!
    allow(PipelineService::Endpoints::Pipeline).to receive(:http_client)
      .and_return(http_client)
  end

  context "Missing configuration" do
    before do
      @original_pipeline_user = ENV['PIPELINE_USER_NAME']
      ENV['PIPELINE_USER_NAME'] = nil
    end

    after do
      ENV['PIPELINE_USER_NAME'] = @original_pipeline_user
    end

    it 'wont raise an error through the api cus its queued' do
      ENV.delete 'SYNCHRONOUS_PIPELINE_JOBS'
      expect { PipelineService.publish(@enrollment) }.to_not raise_error
    end

    it 'calling it directly will raise an error since its not queued' do
      expect { PipelineService::Commands::Publish.new(object: @enrollment).call }
        .to raise_error(RuntimeError, 'Missing config')
    end
  end

  context "Assignment" do
    before do
      @user       = User.create!
      @course     = Course.create!
      @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
      @assignment = ::Assignment.create!(context: @course)
    end

    it do
      expect(http_client).to receive(:messages_post)
      ::Assignment.create!(context: @course)
    end
  end

  context "Submission" do
    before do
      ENV['PIPELINE_ENDPOINT']  = 'https://example.com'
      ENV['PIPELINE_USER_NAME'] = 'example_user'
      ENV['PIPELINE_PASSWORD']  = 'example_password'
      ENV['CANVAS_DOMAIN']      = 'someschool.com'

      @user       = User.create!
      @course     = Course.create!
      @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
      @enrollment.save

    end

    it do
      expect(http_client).to receive(:messages_post)
      @enrollment.update(workflow_state: 'completed')
    end

    # TODO: move this test to the shim
    xit 'will use the enrollment type with hashes' do
      # byebug
      # expect(endpoint).to receive(:new).with(hash_including(object: @enrollment))
      expect(PipelineService::Endpoints::Pipeline).to receive(:http_client)
        .and_return(http_client)
      expect(http_client).to receive(:messages_post)
      PipelineService::Commands::Publish.new(
        object: { id: @enrollment.id }
      ).call
    end
  end
end
