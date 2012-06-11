require File.expand_path("../spec_helper", __FILE__)

describe 'Delayed::Backed::ActiveRecord::Job' do
  before :all do
    @job_spec_backend = Delayed::Job
    Delayed.send(:remove_const, :Job)
    Delayed::Job = Delayed::Backend::ActiveRecord::Job
  end

  after :all do
    Delayed.send(:remove_const, :Job)
    Delayed::Job = @job_spec_backend
  end

  before do
    Delayed::Job.delete_all
  end

  it_should_behave_like 'a delayed_jobs implementation'

  it "should recover as well as possible from a failure failing a job" do
    Delayed::Job::Failed.stubs(:create).raises(RuntimeError)
    job = "test".send_later :reverse
    job_id = job.id
    proc { job.fail! }.should raise_error
    proc { Delayed::Job.find(job_id) }.should raise_error(ActiveRecord::RecordNotFound)
    Delayed::Job.count.should == 0
  end
end
