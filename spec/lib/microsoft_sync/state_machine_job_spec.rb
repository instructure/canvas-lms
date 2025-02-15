# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

module MicrosoftSync
  class StateMachineJobTestStepsBase
    MAX_DELAY = 6.hours

    def steps_run
      # For spec expectations
      @steps_run ||= []
    end

    def max_retries
      4
    end

    def max_delay
      MAX_DELAY
    end

    def after_failure
      steps_run << [:after_failure]
    end

    def after_complete
      steps_run << [:after_complete]
    end
  end

  # Sample steps object to test functionality of StateMachineJob framework by
  # recording when steps are called
  class StateMachineJobTestSteps1 < StateMachineJobTestStepsBase
    def step_initial(mem_data, job_state_data)
      steps_run << [:step_initial, mem_data, job_state_data]

      return StateMachineJob::NextStep.new(:step_second) if mem_data == "passedin_initial_mem_state"

      case [job_state_data, @internal_data]
      when [nil, nil]
        StateMachineJob::Retry.new(error: StandardError.new("bar")) do
          steps_run << [:stash_first]
          # In the real code, we would actually write to the DB here, but since we
          # aren't running delayed jobs which would recreate objects here, we can
          # just keep this in memory.
          @internal_data = "retry1"
        end
      when [nil, "retry1"]
        @internal_data = nil
        StateMachineJob::Retry.new(
          error: StandardError.new("foo"),
          delay_amount: 2.seconds,
          job_state_data: "retry2"
        )
      when ["retry2", nil]
        StateMachineJob::NextStep.new(:step_second, "first_data")
      else
        raise "Unknown job_state_data/steps internal_data: " +
              [job_state_data, @internal_data].inspect
      end
    end

    def step_second(mem_data, job_state_data)
      steps_run << [:step_second, mem_data, job_state_data]
      StateMachineJob::COMPLETE
    end
  end

  class StateMachineJobTestSteps2 < StateMachineJobTestStepsBase
    def initialize(step_initial_retries,
                   step_second_delay_amounts = [1, 2, 3],
                   error_class: Errors::PublicError)
      super()
      @error_class = error_class
      @step_initial_retries = step_initial_retries
      @step_second_delay_amounts = step_second_delay_amounts
    end

    def step_initial(_mem_data, _job_state_data)
      if (@step_initial_retries -= 1) >= 0
        StateMachineJob::Retry.new(error: @error_class.new("foo")) { steps_run << :stash }
      else
        StateMachineJob::NextStep.new(:step_second)
      end
    end

    def step_second(_mem_data, _job_state_data)
      StateMachineJob::Retry.new(
        error: @error_class.new("foo"),
        delay_amount: @step_second_delay_amounts
      )
    end
  end

  # Used instead of StateMachineJob directly to stub out/capture sleeps &
  # delays, and record when they are used
  class StateMachineJobTest < StateMachineJob
    def sleep(amt)
      steps_object.steps_run << [:sleep, amt]
    end

    # Used as a helper to enqueue actual delayed jobs
    def direct_enqueue_run(run_at, step, initial_mem_state)
      StateMachineJob.instance_method(:delay).bind_call(self, sender: self, strand:, run_at:)
                     .run(step, initial_mem_state)
    end

    def delay(*args)
      so = steps_object
      Object.new.tap do |mock_delay_object|
        mock_delay_object.define_singleton_method(:run) do |*run_args|
          so.steps_run << [:delay_run, args, run_args]
        end
        mock_delay_object.define_singleton_method(:run_later) do |*run_later_args|
          so.steps_run << [:delay_run_later, args, run_later_args]
        end
      end
    end
  end

  describe StateMachineJob do
    subject { StateMachineJobTest.new(state_record, steps_object) }

    let(:state_record) { MicrosoftSync::Group.create(course: course_model) }
    let(:steps_object) { StateMachineJobTestSteps1.new }
    let(:strand) do
      "MicrosoftSync::StateMachineJobTest:MicrosoftSync::Group:#{state_record.global_id}"
    end

    around { |example| Timecop.freeze(&example) }

    describe "#run_synchronously" do
      it "runs all the steps" do
        subject.run_synchronously
        expect(steps_object.steps_run).to eq([
                                               [:step_initial, nil, nil],
                                               [:stash_first],
                                               [:step_initial, nil, nil],
                                               [:sleep, 2.seconds],
                                               [:step_initial, nil, "retry2"],
                                               [:step_second, "first_data", nil],
                                               [:after_complete],
                                             ])
      end

      context "when there is a job currently retrying" do
        it "raises an error" do
          subject.send(:run, nil, nil)
          subject.direct_enqueue_run(10.minutes.from_now, :step_initial, nil)
          expect { subject.run_synchronously }
            .to raise_error(described_class::InternalError, /A job is waiting to be retried/)
        end
      end

      context "when canceled in an IRB session" do
        it "doesn't leave state as pending" do
          expect(steps_object).to receive(:step_initial).and_raise(IRB::Abort)
          expect { subject.run_synchronously }.to raise_error(IRB::Abort)
          expect(state_record.reload.workflow_state).to eq("errored")
        end
      end
    end

    describe "#run_later" do
      it "enqueues a job calling run() with a nil step" do
        subject.run_later
        expect(steps_object.steps_run).to eq([
                                               [:delay_run, [{ strand:, run_at: nil }], [nil, nil]],
                                             ])
      end

      # On Jenkins, global and local IDs seems to be the same, so test this explicitly:
      it "uses the global id in the strand name" do
        expect(state_record).to receive(:global_id).and_return 987_650_000_000_012_345
        subject.run_later
        expect(steps_object.steps_run[0][1][0][:strand]).to eq(
          "MicrosoftSync::StateMachineJobTest:MicrosoftSync::Group:987650000000012345"
        )
      end

      it "takes an optional initial_mem_state parameter it passes on to run()" do
        subject.run_later("initial mem state")
        expect(steps_object.steps_run).to eq([
                                               [:delay_run, [{ strand:, run_at: nil }], [nil, "initial mem state"]],
                                             ])
      end
    end

    describe "#run" do
      it "runs steps until it hits a retry then enqueues a delayed job" do
        subject.send(:run, nil, nil)
        expect(steps_object.steps_run).to eq([
                                               [:step_initial, nil, nil],
                                               [:stash_first],
                                               [:delay_run, [{ strand:, run_at: nil }], [:step_initial, nil]],
                                             ])
        steps_object.steps_run.clear

        subject.send(:run, :step_initial, nil)
        expect(steps_object.steps_run).to eq([
                                               [:step_initial, nil, nil],
                                               [:delay_run, [{ strand:, run_at: 2.seconds.from_now }], [:step_initial, nil]],
                                             ])
        steps_object.steps_run.clear

        subject.send(:run, :step_initial, nil)
        expect(steps_object.steps_run).to eq([
                                               [:step_initial, nil, "retry2"],
                                               [:step_second, "first_data", nil],
                                               [:after_complete],
                                             ])
      end

      context "when an initial memory state is given" do
        it "uses it for the first step" do
          subject.send(:run, nil, "passedin_initial_mem_state")
          expect(steps_object.steps_run).to eq([
                                                 [:step_initial, "passedin_initial_mem_state", nil],
                                                 [:step_second, nil, nil],
                                                 [:after_complete]
                                               ])
        end
      end

      it "sets workflow_state to the correct state (running, retrying, completed)" do
        expect(state_record.workflow_state).to eq("pending")

        expect(steps_object).to receive(:step_initial).once do
          expect(state_record.reload.workflow_state).to eq("running")
          StateMachineJob::Retry.new(error: StandardError.new)
        end

        subject.send(:run, nil, nil)
        expect(state_record.reload.workflow_state).to eq("retrying")

        expect(steps_object).to receive(:step_initial).once do
          expect(state_record.reload.workflow_state).to eq("running")
          StateMachineJob::COMPLETE
        end
        subject.send(:run, :step_initial, nil)

        expect(state_record.reload.workflow_state).to eq("completed")
      end

      it "increments a statsd counter when complete" do
        expect(steps_object).to receive(:step_initial).and_return StateMachineJob::COMPLETE
        allow(InstStatsd::Statsd).to receive(:increment).and_call_original
        subject.send(:run, nil, nil)
        expect(InstStatsd::Statsd).to have_received(:increment)
          .with("microsoft_sync.smj.complete", tags: { microsoft_sync_step: "step_initial" })
      end

      describe "retry counting" do
        let(:steps_object) { StateMachineJobTestSteps2.new(5) }
        let(:error_name_underscored) { "MicrosoftSync__Errors__PublicError" }

        shared_examples_for "a non-final retry" do
          it "counts retries for each step and stores in job_state" do
            subject.send(:run, nil, nil)
            expect(state_record.reload.job_state[:retries_by_step]["step_initial"]).to eq(1)
            subject.send(:run, :step_initial, nil)
            expect(state_record.reload.job_state[:retries_by_step]["step_initial"]).to eq(2)
            subject.send(:run, :step_initial, nil)
            expect(state_record.reload.job_state[:retries_by_step]["step_initial"]).to eq(3)
          end

          it 'increments the "retry" statsd counter' do
            allow(InstStatsd::Statsd).to receive(:increment).and_call_original
            subject.send(:run, nil, nil)
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              "microsoft_sync.smj.retry",
              tags: {
                microsoft_sync_step: "step_initial", category: error_name_underscored,
              }
            )
          end
        end

        it_behaves_like "a non-final retry"

        context "when the number of retries for a step is exceeded" do
          before do
            subject.send(:run, nil, nil)
            3.times { subject.send(:run, :step_initial, nil) }
          end

          it "re-raises the error and sets the record state to errored" do
            expect { subject.send(:run, :step_initial, nil) }
              .to raise_error(Errors::PublicError, "foo")
            expect(state_record.reload.job_state).to be_nil
            expect(state_record.workflow_state).to eq("errored")
          end

          it "captures error data and the current_state in the last_error field" do
            expect { subject.send(:run, :step_initial, nil) }
              .to raise_error(Errors::PublicError)
            expect(state_record.last_error)
              .to eq(Errors.serialize(Errors::PublicError.new("foo"), step: "step_initial"))
          end

          it "doesn't run the stash block on the last failure" do
            expect(steps_object.steps_run.count(:stash)).to eq(4)
            steps_object.steps_run.clear
            expect { subject.send(:run, :step_initial, nil) }
              .to raise_error(Errors::PublicError, "foo")
            expect(steps_object.steps_run.count(:stash)).to eq(0)
          end

          it 'increments the "final_retry" statsd counter' do
            allow(InstStatsd::Statsd).to receive(:increment).and_call_original
            expect { subject.send(:run, :step_initial, nil) }
              .to raise_error(Errors::PublicError)
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              "microsoft_sync.smj.final_retry",
              tags: { microsoft_sync_step: "step_initial", category: "MicrosoftSync__Errors__PublicError" }
            )
          end

          it "sends an RetriesExhaustedError to Canvas::Errors and saves last_error_report_id" do
            expect(Canvas::Errors).to receive(:capture) do |error, options, level|
              expect(error).to be_a(described_class::RetriesExhaustedError)
              expect(error.cause).to be_a(MicrosoftSync::Errors::PublicError)
              expect(options).to eq(tags: { type: "microsoft_sync_smj" })
              expect(level).to eq(:error)
              { error_report: 456 }
            end
            expect { subject.send(:run, :step_initial, nil) }.to raise_error(Errors::PublicError)
            expect(state_record.last_error_report_id).to eq(456)
          end
        end

        context "when the retrying error is a GracefulCancelError" do
          let(:steps_object) do
            StateMachineJobTestSteps2.new(5, error_class: Errors::GracefulCancelError)
          end
          let(:error_name_underscored) { "MicrosoftSync__Errors__GracefulCancelError" }

          it_behaves_like "a non-final retry"

          context "when the number of retries for a step is exceeded" do
            before do
              subject.send(:run, nil, nil)
              3.times { subject.send(:run, :step_initial, nil) }
            end

            it "sets the record state but does not bubble up the error" do
              subject.send(:run, :step_initial, nil)
              expect(state_record.reload.job_state).to be_nil
              expect(state_record.workflow_state).to eq("errored")
              expect(state_record.last_error)
                .to eq(Errors.serialize(Errors::GracefulCancelError.new("foo"), step: "step_initial"))
            end

            it 'increments a "canceled" statsd metric' do
              allow(InstStatsd::Statsd).to receive(:increment).and_call_original
              subject.send(:run, :step_initial, nil)
              expect(InstStatsd::Statsd).to have_received(:increment).with(
                "microsoft_sync.smj.cancel",
                tags: {
                  microsoft_sync_step: "step_initial",
                  category: "MicrosoftSync__Errors__GracefulCancelError"
                }
              )
            end

            it "doesn't run the stash block on the last failure" do
              expect(steps_object.steps_run.count(:stash)).to eq(4)
              steps_object.steps_run.clear
              subject.send(:run, :step_initial, nil)
              expect(steps_object.steps_run.count(:stash)).to eq(0)
            end

            it "does not send anything to Canvas::Errors" do
              expect(Canvas::Errors).to_not receive(:capture)
              subject.send(:run, :step_initial, nil)
            end
          end
        end

        context "when multiple steps fail" do
          let(:steps_object) { StateMachineJobTestSteps2.new(2) }

          before do
            subject.send(:run, nil, nil)
            2.times { subject.send(:run, :step_initial, nil) }
            3.times { subject.send(:run, :step_second, nil) }
          end

          it "counts retries per-step" do
            expect { subject.send(:run, :step_second, nil) }.to raise_error(Errors::PublicError, "foo")
            expect(state_record.reload.job_state).to be_nil
            expect(state_record.workflow_state).to eq("errored")
            expect(state_record.last_error)
              .to eq(Errors.serialize(Errors::PublicError.new("foo"), step: "step_second"))
          end

          context "when delay is an array of integers" do
            it "uses delays based on the per-step retry count" do
              delays = steps_object.steps_run.select { |step| step.is_a?(Array) }
              expect(delays).to eq([
                                     [:delay_run, [{ run_at: nil, strand: }], [:step_initial, nil]],
                                     [:delay_run, [{ run_at: nil, strand: }], [:step_initial, nil]],
                                     [:delay_run, [{ run_at: 1.second.from_now, strand: }], [:step_second, nil]],
                                     [:delay_run, [{ run_at: 2.seconds.from_now, strand: }], [:step_second, nil]],
                                     [:delay_run, [{ run_at: 3.seconds.from_now, strand: }], [:step_second, nil]],
                                     # Uses last value once past end of array:
                                     [:delay_run, [{ run_at: 3.seconds.from_now, strand: }], [:step_second, nil]],
                                   ])
            end
          end

          context "when a delay is greater than max_delay" do
            let(:max_delay) do
              StateMachineJobTestStepsBase::MAX_DELAY
            end

            let(:run_ats) do
              delays = steps_object.steps_run.select { |step| step.is_a?(Array) }
              delays.map { |d| d[1][0][:run_at] }
            end

            context "when delay is a single duration value" do
              let(:steps_object) { StateMachineJobTestSteps2.new(2, max_delay + 3.minutes) }

              it "clips the delay the maximum" do
                expect(run_ats).to eq([nil, nil] + ([max_delay.from_now] * 4))
              end
            end

            context "when delay is an array of integers" do
              let(:steps_object) do
                StateMachineJobTestSteps2.new(2, [-3, max_delay - 5, max_delay + 5])
              end

              it "clips the delay to between 0 and the maximum" do
                expect(run_ats).to eq([
                                        nil,
                                        nil,
                                        Time.zone.now,
                                        (max_delay - 5).from_now,
                                        max_delay.from_now,
                                        max_delay.from_now
                                      ])
              end
            end
          end
        end

        context "when Retry points to a different step" do
          let(:steps_object) { StateMachineJobTestSteps2.new(4) }

          context "when the number of retries has not surpassed max_retries for the destination step" do
            before do
              allow(steps_object).to receive(:step_initial).and_return(
                described_class::Retry.new(
                  error: StandardError.new, step: :step_second, delay_amount: 123
                )
              )

              subject.send(:run, nil, nil)
            end

            it "enqueues a job starting at that step" do
              expect(steps_object.steps_run).to eq([
                                                     [:delay_run, [{ run_at: 123.seconds.from_now, strand: }], [:step_second, nil]],
                                                   ])
            end

            it "sets step in job" do
              expect(state_record.reload.job_state).to include(step: :step_second)
            end

            it "keeps track of retries under that step" do
              expect(state_record.reload.job_state).to include(retries_by_step: { "step_second" => 1 })
            end
          end

          context "when the number of retries has surpassed max_retries for the destination step" do
            before do
              subject.send(:run, nil, nil)
              4.times { subject.send(:run, :step_initial, nil) }
              # now, retries are exhausted for step_initial
              allow(steps_object).to receive(:step_second).and_return(
                described_class::Retry.new(
                  error: StandardError.new("foo"), step: :step_initial, delay_amount: 123
                )
              )
            end

            it "bubbles up the retry" do
              expect { subject.send(:run, :step_second, nil) }.to raise_error(StandardError, "foo")
              expect(state_record.reload.workflow_state).to eq("errored")
            end
          end
        end
      end

      context "when the step returns a DelayedNextStep" do
        let(:delay_amount) { 1.minute }

        before do
          subject.send(:run, nil, nil)
          allow(steps_object).to receive(:step_initial)
            .and_return(described_class::DelayedNextStep.new(:step_second, delay_amount, "abc123"))
          steps_object.steps_run.clear
        end

        it "enqueues a job for that step" do
          subject.send(:run, :step_initial, nil)
          expect(steps_object.steps_run).to eq([
                                                 [:delay_run, [{ run_at: 1.minute.from_now, strand: }], [:step_second, nil]],
                                               ])
        end

        context "the delay_amount is greater than max_delay" do
          let(:delay_amount) { 100.days }

          it "clips the delay_amount to max_delay" do
            subject.send(:run, :step_initial, nil)
            run_at = Time.zone.now + StateMachineJobTestStepsBase::MAX_DELAY

            expect(steps_object.steps_run).to eq([
                                                   [:delay_run, [{ run_at:, strand: }], [:step_second, nil]],
                                                 ])
          end
        end

        it "leaves retries_by_step untouched" do
          expect { subject.send(:run, :step_initial, nil) }.not_to \
            change { state_record.reload.job_state[:retries_by_step] }.from("step_initial" => 1)
        end

        it "sets job_state step, updated_at, and data" do
          Timecop.freeze(2.minutes.from_now) do
            expect { subject.send(:run, :step_initial, nil) }
              .to change { state_record.reload.job_state[:data] }.to("abc123")
                                                                 .and change { state_record.reload.job_state[:step] }.to(:step_second)
                                                                                                                     .and change { state_record.reload.job_state[:updated_at] }.to(Time.zone.now)
          end
        end
      end

      context "when an unhandled error occurs" do
        let(:error) { Errors::PublicError.new("uhoh") }

        context "when the error is not a GracefulCancelError" do
          before do
            subject.send(:run, nil, nil)
            subject.send(:run, :step_initial, nil)

            allow(steps_object).to receive(:step_second).and_raise(error)
          end

          it "bubbles up the error, sets the record state to errored, and calls after_failure" do
            expect { subject.send(:run, :step_initial, nil) }.to raise_error(error)

            expect(state_record.reload.job_state).to be_nil
            expect(state_record.workflow_state).to eq("errored")
            expect(state_record.last_error).to eq(Errors.serialize(error, step: "step_second"))
            expect(steps_object.steps_run.last).to eq([:after_failure])
          end

          it "sends the error to Canvas::Errors.capture and saves the error report" do
            expect(Canvas::Errors).to receive(:capture).with(
              error, { tags: { type: "microsoft_sync_smj" } }, :error
            ).and_return({ error_report: 123 })
            expect { subject.send(:run, :step_initial, nil) }.to raise_error(error)
            expect(state_record.last_error_report_id).to eq(123)
          end

          it 'increments the "failure" statsd metric' do
            allow(InstStatsd::Statsd).to receive(:increment).and_call_original
            expect { subject.send(:run, :step_initial, nil) }.to raise_error(error)
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              "microsoft_sync.smj.failure",
              tags: {
                microsoft_sync_step: "step_second", category: "MicrosoftSync__Errors__PublicError"
              }
            )
          end
        end

        context "when the error is a GracefulCancelError" do
          before do
            stub_const("MicrosoftSync::GracefulCancelTestError", Class.new(MicrosoftSync::Errors::GracefulCancelError))
          end

          let(:error) { GracefulCancelTestError.new }

          before { allow(steps_object).to receive(:step_initial).and_raise(error) }

          it "sets the record state, calls after_failure, and stops processing but does not bubble up the error" do
            subject.send(:run, nil, nil)
            # nothing enqueued
            expect(steps_object.steps_run).to eq([[:after_failure]])

            expect(state_record.reload.job_state).to be_nil
            expect(state_record.workflow_state).to eq("errored")
            expect(state_record.last_error).to eq(Errors.serialize(error, step: "step_initial"))
          end

          it 'increments a "canceled" statsd metric' do
            allow(InstStatsd::Statsd).to receive(:increment).and_call_original
            subject.send(:run, nil, nil)
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              "microsoft_sync.smj.cancel",
              tags: {
                microsoft_sync_step: "step_initial",
                category: "MicrosoftSync__GracefulCancelTestError"
              }
            )
          end
        end
      end

      context "when the step returns IGNORED" do
        let(:error) { Errors::PublicError.new("uhoh") }

        context "when last_error is already set" do
          it "changes the state back to errored but doesn't overwrite last_error" do
            expected_serialized_error = Errors.serialize(error, step: "step_initial")

            expect(steps_object).to receive(:step_initial).once.and_raise(error)
            expect { subject.send(:run, nil, nil) }.to raise_error(error)

            expect(steps_object).to receive(:step_initial).once do
              expect(state_record.workflow_state).to eq("running")
              described_class::IGNORE
            end
            subject.send(:run, nil, nil)

            expect(state_record.workflow_state).to eq("errored")
            expect(state_record.last_error).to eq(expected_serialized_error)
          end
        end

        context "when last error is not set" do
          it "just sets the state to complete" do
            expect(steps_object).to receive(:step_initial).once.and_return(described_class::IGNORE)
            subject.send(:run, nil, nil)
            expect(state_record.workflow_state).to eq("complete")
          end
        end
      end

      context "when the record is in workflow_state deleted" do
        before { state_record.update!(workflow_state: "deleted") }

        it "doesn't start a new job" do
          subject.send(:run, nil, nil)
          expect(steps_object.steps_run).to eq([])
        end

        it "doesn't continue a retried job" do
          state_record.update(job_state: { step: :step_initial })
          subject.send(:run, :step_initial, nil)
          expect(steps_object.steps_run).to eq([])
        end
      end

      context "when the record is deleted while the job is running" do
        before do
          expect(steps_object).to receive(:step_initial) do
            MicrosoftSync::Group.where(id: state_record.id).update_all(workflow_state: "deleted")
            step_result
          end
        end

        context "when the step returns COMPLETE" do
          let(:step_result) { described_class::COMPLETE }

          it "doesn't set the workflow_state to completed" do
            subject.send(:run, nil, nil)
            expect(state_record.reload.workflow_state).to eq("deleted")
          end
        end

        context "when the step returns Retry" do
          let(:step_result) { described_class::Retry.new(error: StandardError.new) }

          before { subject.send(:run, nil, nil) }

          it "doesn't update the job_state/workflow_state" do
            expect(state_record.reload.workflow_state).to eq("deleted")
            expect(state_record.job_state).to be_nil
          end

          it "doesn't retry the job or run the stash block" do
            expect(steps_object.steps_run).to eq([])
          end
        end

        context "when the step raises an error" do
          let(:step_result) { raise StandardError, "foo123" }

          it "doesn't set the workflow_state to errored" do
            expect { subject.send(:run, nil, nil) }.to raise_error(StandardError, "foo123")
            expect(state_record.reload.workflow_state).to eq("deleted")
          end
        end
      end

      context "when there is a mismatch between the step in the job_state field and job arguments" do
        context "when job_state is nil" do
          it "captures an error with Canvas::Errors and then raises it" do
            expect(Canvas::Errors).to receive(:capture).with(
              instance_of(StateMachineJob::InternalError),
              { tags: { type: "microsoft_sync_smj" } },
              :error
            )
            expect do
              subject.send(:run, :step_initial, nil)
            end.to raise_error(StateMachineJob::InternalError, /Job step doesn't match state: :step_initial != nil/)
          end
        end

        context "when the step in the job args is nil" do
          before do
            subject.send(:run, nil, nil)
            subject.send(:run, :step_initial, nil)
          end

          shared_examples_for "restarting when a retrying job has stalled" do
            it "restarts the job (in-progress job has stalled)" do
              expect(state_record.job_state[:step]).to eq(:step_initial)
              expect(state_record.job_state[:retries_by_step]["step_initial"]).to eq(2)
              expect(steps_object).to receive(:step_initial) do
                expect(state_record.job_state).to be_nil
                expect(state_record.workflow_state).to eq("running")
                described_class::Retry.new(error: StandardError.new)
              end
              subject.send(:run, nil, nil)
              expect(state_record.job_state[:retries_by_step]["step_initial"]).to eq(1)
            end

            it 'increments a "stalled" statsd metric' do
              allow(InstStatsd::Statsd).to receive(:increment).and_call_original
              subject.send(:run, nil, nil)
              expect(InstStatsd::Statsd).to have_received(:increment).with(
                "microsoft_sync.smj.stalled",
                tags: { microsoft_sync_step: "step_initial" }
              )
            end
          end

          let(:retrying_job_run_at) { 1.minute.from_now }

          context "when there is no job with that state" do
            it_behaves_like "restarting when a retrying job has stalled"
          end

          context "when there is a job with that state" do
            before do
              # Currently retrying job:
              subject.direct_enqueue_run(retrying_job_run_at, :step_initial, nil)
            end

            context "when the retrying job's run_at is before than 1 day in the past" do
              let(:retrying_job_run_at) { (1.day + 1.second).ago }

              it_behaves_like "restarting when a retrying job has stalled"
            end

            context "when the retrying job's run_at > max_delay in the future" do
              let(:retrying_job_run_at) do
                (steps_object.max_delay + 1.second).from_now
              end

              it_behaves_like "restarting when a retrying job has stalled"
            end

            context "when the retrying job's run_at is after 1 day in the past" do
              let(:retrying_job_run_at) { (1.day - 1.second).ago }

              it "enqueues a new job" do
                steps_object.steps_run.clear
                subject.send(:run, nil, nil)
                expect(steps_object.steps_run).to eq([
                                                       [:delay_run, [{ strand:, run_at: retrying_job_run_at + 1.second }], [nil, nil]]
                                                     ])
              end
            end

            context "when the retrying job's run_at < max_delay" do
              let(:retrying_job_run_at) do
                (steps_object.max_delay - 1.second).from_now
              end

              it "enqueues a new job" do
                steps_object.steps_run.clear
                subject.send(:run, nil, nil)
                expect(steps_object.steps_run).to eq([
                                                       [:delay_run, [{ strand:, run_at: retrying_job_run_at + 1.second }], [nil, nil]]
                                                     ])
              end
            end

            [[nil, :my_mem_state], [:my_mem_state, nil]].each do |mem_state1, mem_state2|
              context "when there is another initial job with the same " \
                      "initial_mem_state (#{mem_state1.inspect}) enqueued" do
                it "does nothing (ignores/drops the job)" do
                  subject.direct_enqueue_run(2.minutes.from_now, nil, mem_state1)

                  allow(Delayed::Worker).to receive(:current_job).and_return(Delayed::Job.last)
                  # Backlog job with the same initial_mem_state:
                  subject.direct_enqueue_run(2.minutes.from_now, nil, mem_state1)
                  expect(state_record.job_state[:step]).to eq(:step_initial)
                  expect(steps_object).not_to receive(:step_initial)
                  expect { subject.send(:run, nil, mem_state1) }
                    .to_not change { state_record.reload.attributes }
                end
              end

              context "when there are other jobs but none with the same initial_mem_state " \
                      "(#{mem_state1.inspect})" do
                it "enqueues another job one second after the currently retrying one" do
                  subject.direct_enqueue_run(2.minutes.from_now, nil, mem_state1)
                  allow(Delayed::Worker).to receive(:current_job).and_return(Delayed::Job.last)

                  subject.direct_enqueue_run(30.seconds.from_now, nil, "some_initial_mem_state")
                  subject.direct_enqueue_run(2.minutes.from_now, nil, mem_state2)
                  expect(steps_object).not_to receive(:step_initial)
                  steps_object.steps_run.clear
                  expect { subject.send(:run, nil, mem_state1) }.to_not change { state_record.reload.attributes }
                  expect(steps_object.steps_run).to eq([
                                                         [:delay_run, [{ strand:, run_at: 61.seconds.from_now }], [nil, mem_state1]]
                                                       ])
                end
              end
            end
          end
        end

        context "when neither is nil" do
          it "raises an error" do
            subject.send(:run, nil, nil)
            expect { subject.send(:run, :step_second, nil) }.to raise_error(
              StateMachineJob::InternalError, /Job step doesn't match state: :step_second != :step_initial/
            )
          end
        end
      end
    end
  end
end
