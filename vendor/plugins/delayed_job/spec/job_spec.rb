require 'spec_helper'

describe Delayed::Job do
  before(:all) do
    @backend = Delayed::Job
  end
  
  before(:each) do
    Delayed::Worker.max_priority = nil
    Delayed::Worker.min_priority = nil
    Delayed::Job.delete_all
    SimpleJob.runs = 0
  end
  
  after do
    Time.zone = nil
  end
  
  it_should_behave_like 'a backend'

  context "db_time_now" do
    it "should return time in current time zone if set" do
      Time.zone = 'Eastern Time (US & Canada)'
      Delayed::Job.db_time_now.zone.should match(/EST|EDT/)
    end
    
    it "should return UTC time if that is the AR default" do
      Time.zone = nil
      ActiveRecord::Base.default_timezone = :utc
      Delayed::Job.db_time_now.zone.should == 'UTC'
    end

    it "should return local time if that is the AR default" do
      Time.zone = 'Central Time (US & Canada)'
      ActiveRecord::Base.default_timezone = :local
      Delayed::Job.db_time_now.zone.should match(/CST|CDT/)
    end
  end
  
end
