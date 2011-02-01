require 'spec_helper'

describe 'random ruby objects' do
   before :each do
     Delayed::Worker.queue = nil
     Delayed::Job.delete_all
   end

  it "should respond_to :send_later method" do
    Object.new.respond_to?(:send_later)
  end

  it "should raise a ArgumentError if send_later is called but the target method doesn't exist" do
    lambda { Object.new.send_later(:method_that_deos_not_exist) }.should raise_error(NoMethodError)
  end

  it "should add a new entry to the job table when send_later is called on it" do
    lambda { Object.new.send_later(:to_s) }.should change { Delayed::Job.count }.by(1)
  end

  it "should add a new entry to the job table when send_later_with_queue is called on it" do
    lambda { Object.new.send_later_with_queue(:to_s, "testqueue") }.should change { Delayed::Job.count }.by(1)
  end

  it "should add a new entry to the job table when send_later is called on the class" do
    lambda { Object.send_later(:to_s) }.should change { Delayed::Job.count }.by(1)
  end

  it "should add a new entry to the job table when send_later_with_queue is called on the class" do
    lambda { Object.send_later_with_queue(:to_s, "testqueue") }.should change { Delayed::Job.count }.by(1)
  end

  it "should call send later on methods which are wrapped with handle_asynchronously" do
    story = Story.create :text => 'Once upon...'
  
    Delayed::Job.count.should == 0
  
    story.whatever(1, 5)
  
    Delayed::Job.count.should == 1
    job =  Delayed::Job.find(:first)
    job.payload_object.class.should   == Delayed::PerformableMethod
    job.payload_object.method.should  == :whatever_without_send_later
    job.payload_object.args.should    == [1, 5]
    job.payload_object.perform.should == 'Once upon...'
  end

  it "should call send later on methods which are wrapped with handle_asynchronously_with_queue" do
    story = Story.create :text => 'Once upon...'
  
    Delayed::Job.count.should == 0
  
    story.whatever_else(1, 5)
  
    Delayed::Job.count.should == 1
    job =  Delayed::Job.find(:first)
    job.payload_object.class.should   == Delayed::PerformableMethod
    job.payload_object.method.should  == :whatever_else_without_send_later
    job.payload_object.args.should    == [1, 5]
    job.payload_object.perform.should == 'Once upon...'
  end
  
  context "send_later" do
    it "should use the default queue if there is one" do
      Delayed::Worker.queue = "testqueue"
      job = "string".send_later :reverse
      job.queue.should == "testqueue"
    end
    
    it "should have nil queue if there is not a default" do
      job = "string".send_later :reverse
      job.queue.should == nil
    end
  end

  context "send_at" do
    it "should queue a new job" do
      lambda do
        "string".send_at(1.hour.from_now, :length)
      end.should change { Delayed::Job.count }.by(1)
    end
    
    it "should schedule the job in the future" do
      time = 1.hour.from_now
      job = "string".send_at(time, :length)
      job.run_at.should == time
    end
    
    it "should store payload as PerformableMethod" do
      job = "string".send_at(1.hour.from_now, :count, 'r')
      job.payload_object.class.should   == Delayed::PerformableMethod
      job.payload_object.method.should  == :count
      job.payload_object.args.should    == ['r']
      job.payload_object.perform.should == 1
    end
    
    it "should use the default queue if there is one" do
      Delayed::Worker.queue = "testqueue"
      job = "string".send_at 1.hour.from_now, :reverse
      job.queue.should == "testqueue"
    end
    
    it "should have nil queue if there is not a default" do
      job = "string".send_at 1.hour.from_now, :reverse
      job.queue.should == nil
    end
  end

  context "send_at_with_queue" do
    it "should queue a new job" do
      lambda do
        "string".send_at_with_queue(1.hour.from_now, :length, "testqueue")
      end.should change { Delayed::Job.count }.by(1)
    end
    
    it "should schedule the job in the future" do
      time = 1.hour.from_now
      job = "string".send_at_with_queue(time, :length, "testqueue")
      job.run_at.should == time
    end
    
    it "should override the default queue" do
      Delayed::Worker.queue = "default_queue"
      job = "string".send_at_with_queue(1.hour.from_now, :length, "testqueue")
      job.queue.should == "testqueue"
    end
    
    it "should store payload as PerformableMethod" do
      job = "string".send_at_with_queue(1.hour.from_now, :count, "testqueue", 'r')
      job.payload_object.class.should   == Delayed::PerformableMethod
      job.payload_object.method.should  == :count
      job.payload_object.args.should    == ['r']
      job.payload_object.perform.should == 1
    end
  end

end
