shared_examples_for 'random ruby objects' do
  def set_queue(name)
    old_name = Delayed::Worker.queue
    Delayed::Worker.queue = name
  ensure
    Delayed::Worker.queue = old_name
  end

  it "should respond_to :send_later method" do
    Object.new.respond_to?(:send_later)
  end

  it "should raise a ArgumentError if send_later is called but the target method doesn't exist" do
    expect { Object.new.send_later(:method_that_deos_not_exist) }.to raise_error(NoMethodError)
  end

  it "should add a new entry to the job table when send_later is called on it" do
    expect { Object.new.send_later(:to_s) }.to change { Delayed::Job.jobs_count(:current) }.by(1)
  end

  it "should add a new entry to the job table when send_later_with_queue is called on it" do
    expect { Object.new.send_later_with_queue(:to_s, "testqueue") }.to change { Delayed::Job.jobs_count(:current, "testqueue") }.by(1)
  end

  it "should add a new entry to the job table when send_later is called on the class" do
    expect { Object.send_later(:to_s) }.to change { Delayed::Job.jobs_count(:current) }.by(1)
  end

  it "should add a new entry to the job table when send_later_with_queue is called on the class" do
    expect { Object.send_later_with_queue(:to_s, "testqueue") }.to change { Delayed::Job.jobs_count(:current, "testqueue") }.by(1)
  end

  context "class methods" do
    context "add_send_later_methods" do
      it "should work with default_async" do
        class TestObject
          attr_reader :ran
          def test_method; @ran = true; end
          add_send_later_methods :test_method, {}, true
        end
        obj = TestObject.new
        expect { obj.test_method }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect { obj.test_method_with_send_later }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect(obj.ran).to be_falsey
        expect { obj.test_method_without_send_later }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to be true
      end

      it "should work without default_async" do
        class TestObject
          attr_accessor :ran
          def test_method; @ran = true; end
          add_send_later_methods :test_method, {}, false
        end
        obj = TestObject.new
        expect { obj.test_method_with_send_later }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect(obj.ran).to be_falsey
        expect { obj.test_method }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to be true
        obj.ran = false
        expect(obj.ran).to be false
        expect { obj.test_method_without_send_later }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to be true
      end

      it "should send along enqueue args and args default async" do
        class TestObject
          attr_reader :ran
          def test_method(*args); @ran = args; end
          add_send_later_methods(:test_method, {:enqueue_arg_1 => :thing}, true)
        end
        obj = TestObject.new
        method = mock()
        Delayed::PerformableMethod.expects(:new).with(obj, :test_method_without_send_later, [1,2,3]).returns(method)
        Delayed::Job.expects(:enqueue).with(method, :enqueue_arg_1 => :thing)
        obj.test_method(1,2,3)
        Delayed::PerformableMethod.expects(:new).with(obj, :test_method_without_send_later, [4]).returns(method)
        Delayed::Job.expects(:enqueue).with(method, :enqueue_arg_1 => :thing)
        obj.test_method(4)
        Delayed::PerformableMethod.expects(:new).with(obj, :test_method_without_send_later, [6]).returns(method)
        Delayed::Job.expects(:enqueue).with(method, :enqueue_arg_1 => :thing)
        obj.test_method_with_send_later(6)
        Delayed::PerformableMethod.expects(:new).with(obj, :test_method_without_send_later, [5,6]).returns(method)
        Delayed::Job.expects(:enqueue).with(method, :enqueue_arg_1 => :thing)
        obj.test_method_with_send_later(5,6)
        expect(obj.ran).to be_nil
        obj.test_method_without_send_later(7)
        expect(obj.ran).to eq [7]
        obj.ran = nil
        expect(obj.ran).to eq nil
        obj.test_method_without_send_later(8,9)
        expect(obj.ran).to eq [8,9]
      end

      it "should send along enqueue args and args without default async" do
        class TestObject
          attr_reader :ran
          def test_method(*args); @ran = args; end
          add_send_later_methods(:test_method, {:enqueue_arg_2 => :thing2}, false)
        end
        obj = TestObject.new
        method = mock()
        Delayed::PerformableMethod.expects(:new).with(obj, :test_method_without_send_later, [6]).returns(method)
        Delayed::Job.expects(:enqueue).with(method, :enqueue_arg_2 => :thing2)
        obj.test_method_with_send_later(6)
        Delayed::PerformableMethod.expects(:new).with(obj, :test_method_without_send_later, [5,6]).returns(method)
        Delayed::Job.expects(:enqueue).with(method, :enqueue_arg_2 => :thing2)
        obj.test_method_with_send_later(5,6)
        expect(obj.ran).to be_nil
        obj.test_method(1,2,3)
        expect(obj.ran).to eq [1,2,3]
        obj.ran = nil
        expect(obj.ran).to eq nil
        obj.test_method(4)
        expect(obj.ran).to eq [4]
        obj.ran = nil
        expect(obj.ran).to eq nil
        obj.test_method_without_send_later(7)
        expect(obj.ran).to eq [7]
        obj.ran = nil
        expect(obj.ran).to eq nil
        obj.test_method_without_send_later(8,9)
        expect(obj.ran).to eq [8,9]
      end

      it "should handle punctuation correctly with default_async" do
        class TestObject
          attr_reader :ran
          def test_method?; @ran = true; end
          add_send_later_methods :test_method?, {}, true
        end
        obj = TestObject.new
        expect { obj.test_method? }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect { obj.test_method_with_send_later? }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect(obj.ran).to be_falsey
        expect { obj.test_method_without_send_later? }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to be true
      end

      it "should handle punctuation correctly without default_async" do
        class TestObject
          attr_accessor :ran
          def test_method?; @ran = true; end
          add_send_later_methods :test_method?, {}, false
        end
        obj = TestObject.new
        expect { obj.test_method_with_send_later? }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect(obj.ran).to be_falsey
        expect { obj.test_method? }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to be true
        obj.ran = false
        expect(obj.ran).to be false
        expect { obj.test_method_without_send_later? }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to be true
      end

      it "should handle assignment punctuation correctly with default_async" do
        class TestObject
          attr_reader :ran
          def test_method=(val); @ran = val; end
          add_send_later_methods :test_method=, {}, true
        end
        obj = TestObject.new
        expect { obj.test_method = 3 }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect { obj.test_method_with_send_later = 4 }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect(obj.ran).to be_nil
        expect { obj.test_method_without_send_later = 5 }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to eq 5
      end

      it "should handle assignment punctuation correctly without default_async" do
        class TestObject
          attr_accessor :ran
          def test_method=(val); @ran = val; end
          add_send_later_methods :test_method=, {}, false
        end
        obj = TestObject.new
        expect { obj.test_method_with_send_later = 1 }.to change { Delayed::Job.jobs_count(:current) }.by(1)
        expect(obj.ran).to be_nil
        expect { obj.test_method = 2 }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to eq 2
        expect { obj.test_method_without_send_later = 3 }.not_to change { Delayed::Job.jobs_count(:current) }
        expect(obj.ran).to eq 3
      end

      it "should correctly sort out method accessibility with default async" do
        class TestObject1
          def test_method; end
          add_send_later_methods :test_method, {}, true
        end
        class TestObject2
          protected
          def test_method; end
          add_send_later_methods :test_method, {}, true
        end
        class TestObject3
          private
          def test_method; end
          add_send_later_methods :test_method, {}, true
        end
        expect(TestObject1.public_method_defined?(:test_method)).to be true
        expect(TestObject2.public_method_defined?(:test_method)).to be false
        expect(TestObject3.public_method_defined?(:test_method)).to be false
        expect(TestObject2.protected_method_defined?(:test_method)).to be true
        expect(TestObject3.protected_method_defined?(:test_method)).to be false
        expect(TestObject3.private_method_defined?(:test_method)).to be true
      end
    end

    context "handle_asynchonously_if_production" do
      it "should work in production" do
        Rails.env.expects(:production?).returns(true)
        class TestObject; end
        TestObject.expects(:add_send_later_methods).with(:test_method, {}, true)
        class TestObject
          def test_method; end
          handle_asynchronously_if_production :test_method
        end
      end

      it "should work in other environments" do
        class TestObject; end
        TestObject.expects(:add_send_later_methods).with(:test_method, {}, false)
        class TestObject
          def test_method; end
          handle_asynchronously_if_production :test_method
        end
      end

      it "should pass along enqueue args in production" do
        Rails.env.expects(:production?).returns(true)
        class TestObject; end
        TestObject.expects(:add_send_later_methods).with(:test_method, {:enqueue_arg_1 => true}, true)
        class TestObject
          def test_method; end
          handle_asynchronously_if_production :test_method, :enqueue_arg_1 => true
        end
      end

      it "should pass along enqueue args in other environments" do
        class TestObject; end
        TestObject.expects(:add_send_later_methods).with(:test_method, {:enqueue_arg_2 => "thing", :enqueue_arg_3 => 4}, false)
        class TestObject
          def test_method; end
          handle_asynchronously_if_production :test_method, :enqueue_arg_2 => "thing", :enqueue_arg_3 => 4
        end
      end
    end

    context "handle_asynchronously" do
      it "should work without enqueue_args" do
        class TestObject; end
        TestObject.expects(:add_send_later_methods).with(:test_method, {}, true)
        class TestObject
          def test_method; end
          handle_asynchronously :test_method
        end
      end

      it "should work with enqueue_args" do
        class TestObject; end
        TestObject.expects(:add_send_later_methods).with(:test_method, {:enqueue_arg_1 => :thing}, true)
        class TestObject
          def test_method; end
          handle_asynchronously :test_method, :enqueue_arg_1 => :thing
        end
      end
    end

    context "handle_asynchronously_with_queue" do
      it "should pass along the queue" do
        class TestObject; end
        TestObject.expects(:add_send_later_methods).with(:test_method, {:queue => "myqueue"}, true)
        class TestObject
          def test_method; end
          handle_asynchronously_with_queue :test_method, "myqueue"
        end
      end
    end
  end

  it "should call send later on methods which are wrapped with handle_asynchronously" do
    story = Story.create :text => 'Once upon...'

    expect { story.whatever(1, 5) }.to change { Delayed::Job.jobs_count(:current) }.by(1)

    job = Delayed::Job.list_jobs(:current, 1).first
    expect(job.payload_object.class).to   eq Delayed::PerformableMethod
    expect(job.payload_object.method).to  eq :whatever_without_send_later
    expect(job.payload_object.args).to    eq [1, 5]
    expect(job.payload_object.perform).to eq 'Once upon...'
  end

  it "should call send later on methods which are wrapped with handle_asynchronously_with_queue" do
    story = Story.create :text => 'Once upon...'

    expect { story.whatever_else(1, 5) }.to change { Delayed::Job.jobs_count(:current, "testqueue") }.by(1)

    job = Delayed::Job.list_jobs(:current, 1, 0, "testqueue").first
    expect(job.payload_object.class).to   eq Delayed::PerformableMethod
    expect(job.payload_object.method).to  eq :whatever_else_without_send_later
    expect(job.payload_object.args).to    eq [1, 5]
    expect(job.payload_object.perform).to eq 'Once upon...'
  end

  context "send_later" do
    it "should use the default queue if there is one" do
      set_queue("testqueue") do
        "string".send_later :reverse
        job = Delayed::Job.list_jobs(:current, 1).first
        expect(job.queue).to eq "testqueue"

        "string".send_later :reverse, :queue => nil
        job2 = Delayed::Job.list_jobs(:current, 2).last
        expect(job2.queue).to eq "testqueue"
      end
    end

    it "should require a queue" do
      expect { set_queue(nil) }.to raise_error(ArgumentError)
    end
  end

  context "send_at" do
    it "should queue a new job" do
      expect do
        "string".send_at(1.hour.from_now, :length)
      end.to change { Delayed::Job.jobs_count(:future) }.by(1)
    end
    
    it "should schedule the job in the future" do
      time = 1.hour.from_now
      "string".send_at(time, :length)
      job = Delayed::Job.list_jobs(:future, 1).first
      expect(job.run_at.to_i).to eq time.to_i
    end
    
    it "should store payload as PerformableMethod" do
      "string".send_at(1.hour.from_now, :count, 'r')
      job = Delayed::Job.list_jobs(:future, 1).first
      expect(job.payload_object.class).to   eq Delayed::PerformableMethod
      expect(job.payload_object.method).to  eq :count
      expect(job.payload_object.args).to    eq ['r']
      expect(job.payload_object.perform).to eq 1
    end
    
    it "should use the default queue if there is one" do
      set_queue("testqueue") do
        "string".send_at 1.hour.from_now, :reverse
        job = Delayed::Job.list_jobs(:current, 1).first
        expect(job.queue).to eq "testqueue"
      end
    end
  end

  context "send_at_with_queue" do
    it "should queue a new job" do
      expect do
        "string".send_at_with_queue(1.hour.from_now, :length, "testqueue")
      end.to change { Delayed::Job.jobs_count(:future, "testqueue") }.by(1)
    end
    
    it "should schedule the job in the future" do
      time = 1.hour.from_now
      "string".send_at_with_queue(time, :length, "testqueue")
      job = Delayed::Job.list_jobs(:future, 1, 0, "testqueue").first
      expect(job.run_at.to_i).to eq time.to_i
    end
    
    it "should override the default queue" do
      set_queue("default_queue") do
        "string".send_at_with_queue(1.hour.from_now, :length, "testqueue")
        job = Delayed::Job.list_jobs(:future, 1, 0, "testqueue").first
        expect(job.queue).to eq "testqueue"
      end
    end
    
    it "should store payload as PerformableMethod" do
      "string".send_at_with_queue(1.hour.from_now, :count, "testqueue", 'r')
      job = Delayed::Job.list_jobs(:future, 1, 0, "testqueue").first
      expect(job.payload_object.class).to   eq Delayed::PerformableMethod
      expect(job.payload_object.method).to  eq :count
      expect(job.payload_object.args).to    eq ['r']
      expect(job.payload_object.perform).to eq 1
    end
  end

  describe "send_later_unless_in_job" do
    module UnlessInJob
      @runs = 0
      def self.runs; @runs; end

      def self.run
        @runs += 1
      end

      def self.run_later
        self.send_later_unless_in_job :run
      end
    end

    before do
      UnlessInJob.class_eval { @runs = 0 }
    end

    it "should perform immediately if in job" do
      UnlessInJob.send_later :run_later
      job = Delayed::Job.list_jobs(:current, 1).first
      job.invoke_job
      expect(UnlessInJob.runs).to eq 1
    end

    it "should queue up for later if not in job" do
      UnlessInJob.run_later
      expect(UnlessInJob.runs).to eq 0
    end
  end

end
