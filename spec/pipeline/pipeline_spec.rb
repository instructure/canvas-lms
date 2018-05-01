require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe 'pipeline service' do
  let(:endpoint_instance) { double('endpoint instance', call: nil) }
  let(:endpoint) { double('endpoint class', new: endpoint_instance) }

  before do
    @user = account_admin_user
    @course = Course.create!
    @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
    @enrollment.course = @course
    @enrollment.save!
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
      expect(endpoint_instance).to receive(:call)
      PipelineService::Commands::Publish.new(
        object: @assignment,
        endpoint: endpoint
      ).call
    end
  end

  context "Submission" do
    before do
      @user       = User.create!
      @course     = Course.create!
      @enrollment = StudentEnrollment.new(valid_enrollment_attributes)
      @enrollment.save
      @enrollment.update(workflow_state: 'completed')
    end

    before do
      ENV['PIPELINE_ENDPOINT']  = 'https://example.com'
      ENV['PIPELINE_USER_NAME'] = 'example_user'
      ENV['PIPELINE_PASSWORD']  = 'example_password'
      ENV['CANVAS_DOMAIN']      = 'someschool.com'
    end

    it do
      expect(endpoint_instance).to receive(:call)
      PipelineService::Commands::Publish.new(
        object: @enrollment,
        endpoint: endpoint
      ).call
    end

  end

end
