# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

RSpec.describe CanvasOperations::BaseOperation do
  specs_require_sharding

  let(:progress) { Progress.new(context: Account.default, tag: "test/progress") }
  let(:cluster) { Shard.current.database_server }

  shared_context "simple operation" do
    before do
      stub_const("MyOperation", Class.new(described_class) do
        def execute
          log_message("Executing SimpleOperation")
        end
      end)
    end
  end

  shared_context "result setting operation" do
    before do
      stub_const("MyOperation", Class.new(described_class) do
        def execute
          results[:custom_result] = "banana"
        end
      end)
    end
  end

  shared_context "callback operation" do
    before do
      stub_const("MyOperation", Class.new(described_class) do
        before_run :pre_run
        after_run :post_run
        around_run :around_run_method

        before_failure :pre_failure
        after_failure :post_failure
        around_failure :around_failure_method

        def pre_run; end

        def post_run; end

        def around_run_method
          yield
        end

        def pre_failure; end

        def post_failure; end

        def around_failure_method
          yield
        end

        def execute
          log_message("Executing CallbackOperation")
        end
      end)
    end
  end

  shared_context "setting operation" do
    before do
      stub_const("MyOperation", Class.new(described_class) do
        setting :float_feature, default: 0.3, type_cast: :to_f
        setting :integer_feature, default: 5, type_cast: :to_i
        setting :custom_feature, default: "custom_value", type_cast: ->(v) { v.upcase }

        def execute
          log_message("Executing SettingOperation")
        end
      end)
    end
  end

  shared_context "no progress operation" do
    before do
      stub_const("NoProgressOperation", Class.new(described_class) do
        self.progress_tracking = false

        def execute
          log_message("Executing NoProgressOperation")
        end
      end)
    end
  end

  describe ".setting" do
    include_context "setting operation"

    it "creates a class-level setting mutator and accessor" do
      MyOperation.float_feature = 1.5
      expect(MyOperation.float_feature).to eq(1.5)

      MyOperation.integer_feature = 10
      expect(MyOperation.integer_feature).to eq(10)

      MyOperation.custom_feature = "another_value"
      expect(MyOperation.custom_feature).to eq("ANOTHER_VALUE")
    end

    it "creates class-level setting mutators with cluster argument" do
      MyOperation.set_float_feature_for_cluster(2.5, cluster: cluster.id)
      expect(MyOperation.float_feature).to eq(2.5)

      MyOperation.set_integer_feature_for_cluster(20, cluster: cluster.id)
      expect(MyOperation.integer_feature).to eq(20)

      MyOperation.set_custom_feature_for_cluster("cluster_value", cluster: cluster.id)
      expect(MyOperation.custom_feature).to eq("CLUSTER_VALUE")
    end

    it "creates instance-level setting accessors" do
      operation_instance = MyOperation.new

      expect(operation_instance.send(:float_feature)).to eq(0.3)
      expect(operation_instance.send(:integer_feature)).to eq(5)
      expect(operation_instance.send(:custom_feature)).to eq("CUSTOM_VALUE")
    end

    context "with multiple clusters specified" do
      let(:second_cluster) { second_shard.database_server }
      let(:second_shard) { @shard2 }

      it "keeps settings isolated by cluster" do
        MyOperation.set_float_feature_for_cluster(3.5, cluster: cluster.id)
        MyOperation.set_float_feature_for_cluster(4.5, cluster: second_cluster.id)

        expect(MyOperation.float_feature).to eq(3.5)

        second_shard.activate do
          expect(MyOperation.float_feature).to eq(4.5)
        end
      end
    end

    context "when the given type_cast is an invalid symbol" do
      it "raises an InvalidTypeCast error" do
        expect do
          stub_const("MyInvalidOperation", Class.new(described_class) do
            setting :float_feature, default: 0.3, type_cast: :to_banana

            def execute
              log_message("Executing InvalidOperation")
            end
          end)
        end.to raise_error(CanvasOperations::Errors::InvalidTypeCast, /Unsupported type_cast `to_banana`/)
      end
    end

    context "when the given type_cast is an invalid proc" do
      it "raises an InvalidTypeCast error" do
        expect do
          stub_const("MyInvalidOperation", Class.new(described_class) do
            setting :float_feature, default: 0.3, type_cast: ->(v, _extra_arg) { v }

            def execute
              log_message("Executing InvalidProcOperation")
            end
          end)
        end.to raise_error(CanvasOperations::Errors::InvalidTypeCast, /type_cast Proc must take exactly one argument/)
      end
    end
  end

  describe "callbacks" do
    include_context "callback operation"

    let(:operation_instance) { MyOperation.new }

    it "invokes `run` callbacks" do
      expect(operation_instance).to receive(:pre_run).once.ordered
      expect(operation_instance).to receive(:around_run_method).once.ordered.and_yield
      expect(operation_instance).to receive(:post_run).once.ordered

      operation_instance.run
    end

    it "defines `failure` callback class methods" do
      expect(operation_instance).to receive(:pre_failure).once.ordered
      expect(operation_instance).to receive(:around_failure_method).once.ordered.and_yield
      expect(operation_instance).to receive(:post_failure).once.ordered

      operation_instance.fail_with_error!
    end
  end

  describe "#run" do
    subject(:run_operation) { operation_instance.run }

    include_context "result setting operation"

    let(:operation_instance) { MyOperation.new }

    it "runs #execute" do
      expect(operation_instance).to receive(:execute).once

      run_operation
    end

    it "sets the current progress" do
      operation_instance.run(progress)

      expect(operation_instance.send(:progress)).to eq(progress)
    end

    it "completes the progress after execution" do
      expect(progress).to receive(:complete).once

      operation_instance.run(progress)
    end

    it "manually sets workflow_state to completed when progress.complete returns false" do
      allow(progress).to receive(:complete).and_return(false)

      operation_instance.run(progress)

      expect(progress.workflow_state).to eq("completed")
    end

    it "emits an event notifying the run is starting and completing" do
      expect(InstStatsd::Statsd).to receive(:event).with(
        "my_operation started",
        "my_operation operation for shard #{Shard.current.id} started",
        {
          tags: { cluster: Shard.current.database_server.id, shard: Shard.current.id },
          type: "my_operation",
          alert_type: :success
        }
      ).once

      expect(InstStatsd::Statsd).to receive(:event).with(
        "my_operation completed",
        "my_operation operation for shard #{Shard.current.id} completed",
        {
          tags: { cluster: Shard.current.database_server.id, shard: Shard.current.id },
          type: "my_operation",
          alert_type: :success
        }
      ).once

      operation_instance.run
    end

    it "updates the progress with results after execution" do
      expect(progress).to receive(:update!).with(results: { custom_result: "banana" }).once

      operation_instance.run(progress)
    end

    context "when the current shard is not the shard of the operation" do
      include_context "simple operation"

      it "raises a WrongShard" do
        operation = @shard1.activate { MyOperation.new }

        expect { @shard2.activate { operation.run } }.to raise_error(CanvasOperations::Errors::WrongShard, /Operation is being run on the wrong shard/)
      end
    end

    context "when #execute raises Errors::InvalidOperationTarget" do
      include_context "simple operation"

      let(:operation_instance) { MyOperation.new }

      before do
        allow(operation_instance).to receive(:execute).and_raise(
          CanvasOperations::Errors::InvalidOperationTarget,
          "Invalid target"
        )
      end

      it "invokes failure callbacks and marks the progress as failed" do
        expect(operation_instance).to receive(:fail_with_error!).once

        operation_instance.run(progress)
      end

      it "does not raise the error further" do
        expect do
          operation_instance.run(progress)
        end.not_to raise_error
      end

      it "stores the error message in results" do
        operation_instance.run(progress)

        expect(operation_instance.results[:error]).to eq("Invalid target")
      end
    end
  end

  describe "#run_later" do
    subject(:run_later) { operation_instance.run_later }

    context "when progress tracking is enabled" do
      include_context "simple operation"

      let(:operation_instance) { MyOperation.new }

      before do
        allow(operation_instance).to receive(:progress).and_return(progress)
      end

      it "relies on Progress#process_job to enqueue the operation with correct options" do
        expect(progress).to receive(:process_job).with(
          operation_instance,
          :run,
          { on_conflict: :overwrite, singleton: "operations/my_operation/shards/#{Shard.current.id}" }
        ).once

        run_later
      end
    end

    context "when progress tracking is disabled" do
      include_context "no progress operation"

      let(:operation_instance) { NoProgressOperation.new }

      # Testing production-like behavior with `delay_if_production`
      before { allow(Rails.env).to receive(:production?).and_return(true) }

      it "enqueues the operation without Progress tracking" do
        expect(operation_instance).to receive(:log_message).with("Progress tracking is disabled; running operation without Progress tracking.", level: :debug).once

        expect { run_later }.to change {
          Delayed::Job.where(
            singleton: "operations/no_progress_operation/shards/#{Shard.current.id}",
            tag: "NoProgressOperation#run"
          ).count
        }.from(0).to(1)
      end

      it "configures job to call fail_with_error! on permanent failure" do
        run_later

        job = Delayed::Job.find_by(
          singleton: "operations/no_progress_operation/shards/#{Shard.current.id}",
          tag: "NoProgressOperation#run"
        )
        expect(job.payload_object.permanent_fail_cb).to eq(:fail_with_error!)
      end

      it "does not create a Progress record" do
        expect { run_later }.not_to change(Progress, :count)
      end

      it "runs the operation without creating a Progress record" do
        run_later

        expect { run_jobs }.not_to change(Progress, :count)
      end

      it "fails without creating a Progress record" do
        allow_any_instance_of(NoProgressOperation).to receive(:execute).and_raise(
          CanvasOperations::Errors::InvalidOperationTarget,
          "Invalid target"
        )

        run_later

        expect { run_jobs }.not_to change(Progress, :count)
      end
    end
  end

  describe "#job_options" do
    context "when progress tracking is enabled" do
      include_context "simple operation"

      let(:operation_instance) { MyOperation.new }

      it "does not include on_permanent_failure" do
        options = operation_instance.send(:job_options)

        expect(options).to eq({
                                singleton: "shards/#{Shard.current.id}",
                                on_conflict: :overwrite
                              })
        expect(options).not_to have_key(:on_permanent_failure)
      end
    end

    context "when progress tracking is disabled" do
      include_context "no progress operation"

      let(:operation_instance) { NoProgressOperation.new }

      it "includes on_permanent_failure" do
        options = operation_instance.send(:job_options)

        expect(options).to eq({
                                singleton: "shards/#{Shard.current.id}",
                                on_conflict: :overwrite,
                                on_permanent_failure: :fail_with_error!
                              })
      end
    end
  end

  describe "#fail_with_error!" do
    subject(:fail_operation) { operation_instance.fail_with_error! }

    include_context "simple operation"

    let(:operation_instance) { MyOperation.new }

    before do
      allow(operation_instance).to receive(:progress).and_return(progress)
    end

    it "marks the progress as failed" do
      expect(progress).to receive(:fail).once

      fail_operation
    end

    it "updates the progress with results after failure" do
      expect(progress).to receive(:update!).with(results: {}).once

      fail_operation
    end
  end

  describe "#report_message" do
    subject(:report_message) { operation_instance.send(:report_message, title:, message:, alert_type:) }

    include_context "simple operation"

    let(:operation_instance) { MyOperation.new }
    let(:title) { "Test Title" }
    let(:message) { "Test message content" }
    let(:alert_type) { :success }

    it "logs the message with title" do
      expect(operation_instance).to receive(:log_message).with("#{title}: #{message}").once

      report_message
    end

    it "emits an InstStatsd event with correct parameters" do
      expect(InstStatsd::Statsd).to receive(:event).with(
        "my_operation: #{title}",
        "my_operation #{message}",
        {
          tags: { cluster: Shard.current.database_server.id, shard: Shard.current.id },
          type: "my_operation",
          alert_type:
        }
      ).once

      report_message
    end

    context "with different alert types" do
      %i[error warning info].each do |type|
        context "when alert_type is #{type}" do
          let(:alert_type) { type }

          it "uses the correct alert_type in the event" do
            expect(InstStatsd::Statsd).to receive(:event).with(
              "my_operation: #{title}",
              "my_operation #{message}",
              {
                tags: { cluster: Shard.current.database_server.id, shard: Shard.current.id },
                type: "my_operation",
                alert_type: type
              }
            ).once

            report_message
          end
        end
      end
    end

    context "with default alert_type" do
      subject(:report_message) { operation_instance.send(:report_message, title:, message:) }

      it "defaults to :success alert_type" do
        expect(InstStatsd::Statsd).to receive(:event).with(
          "my_operation: #{title}",
          "my_operation #{message}",
          {
            tags: { cluster: Shard.current.database_server.id, shard: Shard.current.id },
            type: "my_operation",
            alert_type: :success
          }
        ).once

        report_message
      end
    end
  end
end
