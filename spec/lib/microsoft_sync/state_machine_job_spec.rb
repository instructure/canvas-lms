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

require 'spec_helper'

require_dependency "microsoft_sync/state_machine_job"
require_dependency "microsoft_sync/errors"

module MicrosoftSync
  class StateMachineJobTestStepsBase
    def steps_run
      # For spec expectations
      @steps_run ||= []
    end

    def initial_step
      :step_first
    end

    def max_retries
      4
    end

    def restart_job_after_inactivity
      6.hours
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
    def step_first(mem_data, job_state_data)
      steps_run << [:step_first, mem_data, job_state_data]

      case [job_state_data, @internal_data]
      when [nil, nil]
        StateMachineJob::Retry.new(error: StandardError.new('bar')) do
          steps_run << [:stash_first]
          # In the real code, we would actually write to the DB here, but since we
          # aren't running delayed jobs which would recreate objects here, we can
          # just keep this in memory.
          @internal_data = 'retry1'
        end
      when [nil, 'retry1']
        @internal_data = nil
        StateMachineJob::Retry.new(
          error: StandardError.new('foo'),
          delay_amount: 2.seconds,
          job_state_data: 'retry2',
        )
      when ['retry2', nil]
        StateMachineJob::NextStep.new(:step_second, 'first_data')
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
    def initialize(step_first_retries)
      @step_first_retries = step_first_retries
    end

    def step_first(_mem_data, _job_state_data)
      if (@step_first_retries -= 1) >= 0
        StateMachineJob::Retry.new(error: Errors::PublicError.new('foo')) { steps_run << :stash }
      else
        StateMachineJob::NextStep.new(:step_second)
      end
    end

    def step_second(_mem_data, _job_state_data)
      StateMachineJob::Retry.new(error: Errors::PublicError.new('foo'), delay_amount: [1,2,3])
    end
  end

  # Used instead of StateMachineJob directly to stub out/capture sleeps &
  # delays, and record when they are used
  class StateMachineJobTest < StateMachineJob
    def sleep(amt)
      steps_object.steps_run << [:sleep, amt]
    end

    def delay(*args)
      so = steps_object
      Object.new.tap do |mock_delay_object|
        mock_delay_object.define_singleton_method(:run) do |*run_args|
          so.steps_run << [:delay_run, args, run_args]
        end
      end
    end
  end

  describe StateMachineJob do
    subject { StateMachineJobTest.new(state_record, steps_object) }

    let(:state_record) { MicrosoftSync::Group.create(course: course_model) }
    let(:steps_object) { StateMachineJobTestSteps1.new }
    let(:strand) { "MicrosoftSync::StateMachineJobTest:MicrosoftSync::Group:#{state_record.id}" }

    around(:each) { |example| Timecop.freeze { example.run } }

    describe '#run_synchronously' do
      it 'runs all the steps' do
        subject.run_synchronously
        expect(steps_object.steps_run).to eq([
          [:step_first, nil, nil],
          [:stash_first],
          [:step_first, nil, nil],
          [:sleep, 2.seconds],
          [:step_first, nil, 'retry2'],
          [:step_second, 'first_data', nil],
          [:after_complete],
        ])
      end
    end

    describe '#run_later' do
      it 'enqueues a job calling run() with a nil step' do
        subject.send(:run_later)
        expect(steps_object.steps_run).to eq([
          [:delay_run, [{strand: strand, run_at: nil}], [nil]],
        ])
      end
    end

    describe '#run' do
      it 'runs steps until it hits a retry then enqueues a delayed job' do
        subject.send(:run, nil)
        expect(steps_object.steps_run).to eq([
          [:step_first, nil, nil],
          [:stash_first],
          [:delay_run, [{strand: strand, run_at: nil}], [:step_first]],
        ])
        steps_object.steps_run.clear

        subject.send(:run, :step_first)
        expect(steps_object.steps_run).to eq([
          [:step_first, nil, nil],
          [:delay_run, [{strand: strand, run_at: 2.seconds.from_now}], [:step_first]],
        ])
        steps_object.steps_run.clear

        subject.send(:run, :step_first)
        expect(steps_object.steps_run).to eq([
          [:step_first, nil, 'retry2'],
          [:step_second, 'first_data', nil],
          [:after_complete],
        ])
      end

      it 'sets workflow_state to the correct state (running, retrying, completed)' do
        expect(state_record.workflow_state).to eq('pending')

        expect(steps_object).to receive(:step_first).once do
          expect(state_record.reload.workflow_state).to eq('running')
          StateMachineJob::Retry.new(error: StandardError.new)
        end

        subject.send(:run, nil)
        expect(state_record.reload.workflow_state).to eq('retrying')

        expect(steps_object).to receive(:step_first).once do
          expect(state_record.reload.workflow_state).to eq('running')
          StateMachineJob::COMPLETE
        end
        subject.send(:run, :step_first)

        expect(state_record.reload.workflow_state).to eq('completed')
      end

      it 'increments a statsd counter when complete' do
        expect(steps_object).to receive(:step_first).and_return StateMachineJob::COMPLETE
        allow(InstStatsd::Statsd).to receive(:increment)
        subject.send(:run, nil)
        expect(InstStatsd::Statsd).to \
          have_received(:increment).with('microsoft_sync.smj.complete', tags: {})
      end

      describe 'retry counting' do
        let(:steps_object) { StateMachineJobTestSteps2.new(5) }

        it 'counts retries for each step and stores in job_state' do
          subject.send(:run, nil)
          expect(state_record.reload.job_state[:retries_by_step]['step_first']).to eq(1)
          subject.send(:run, :step_first)
          expect(state_record.reload.job_state[:retries_by_step]['step_first']).to eq(2)
          subject.send(:run, :step_first)
          expect(state_record.reload.job_state[:retries_by_step]['step_first']).to eq(3)
        end

        it 'increments the "retry" statsd counter' do
          allow(InstStatsd::Statsd).to receive(:increment)
          subject.send(:run, nil)
          expect(InstStatsd::Statsd).to have_received(:increment).with(
            'microsoft_sync.smj.retry',
            tags: {
              microsoft_sync_step: 'step_first', category: 'MicrosoftSync::Errors::PublicError'
            }
          )
        end

        context 'when the number of retries for a step is exceeded' do
          before do
            subject.send(:run, nil)
            3.times { subject.send(:run, :step_first) }
          end

          it 're-raises the error and sets the record state to errored' do
            expect { subject.send(:run, :step_first) }.to raise_error(Errors::PublicError, 'foo')
            expect(state_record.reload.job_state).to eq(nil)
            expect(state_record.workflow_state).to eq('errored')
            expect(state_record.last_error).to \
              eq(Errors.user_facing_message(Errors::PublicError.new('foo')))
          end

          it "doesn't run the stash block on the last failure" do
            expect { subject.send(:run, :step_first) }.to raise_error(Errors::PublicError, 'foo')
            expect(steps_object.steps_run.count(:stash)).to eq(4)
            steps_object.steps_run.clear
            expect(steps_object.steps_run).to be_empty
          end

          it 'increments the "final_retry" statsd counter' do
            allow(InstStatsd::Statsd).to receive(:increment)
            expect { subject.send(:run, :step_first) }.to raise_error(Errors::PublicError)
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              'microsoft_sync.smj.final_retry',
              tags: {microsoft_sync_step: 'step_first', category: 'MicrosoftSync::Errors::PublicError'}
            )
          end

          it 'sends an RetriesExhaustedError to Canvas::Errors' do
            expect(Canvas::Errors).to receive(:capture) do |error, options, level|
              expect(error).to be_a(described_class::RetriesExhaustedError)
              expect(error.cause).to be_a(MicrosoftSync::Errors::PublicError)
              expect(options).to \
                eq(tags: {type: 'microsoft_sync_smj'})
              expect(level).to eq(:error)
            end
            expect { subject.send(:run, :step_first) }.to raise_error(Errors::PublicError)
          end
        end

        context 'when multiple steps fail' do
          let(:steps_object) { StateMachineJobTestSteps2.new(2) }

          before do
            subject.send(:run, nil)
            2.times { subject.send(:run, :step_first) }
            3.times { subject.send(:run, :step_second) }
          end

          it 'counts retries per-step' do
            expect { subject.send(:run, :step_second) }.to raise_error(Errors::PublicError, 'foo')
            expect(state_record.reload.job_state).to eq(nil)
            expect(state_record.workflow_state).to eq('errored')
            expect(state_record.last_error).to \
              eq(Errors.user_facing_message(Errors::PublicError.new('foo')))
          end

          context 'when delay is an array of integers' do
            it 'uses delays based on the per-step retry count' do
              delays = steps_object.steps_run.select{|step| step.is_a?(Array)}
              expect(delays).to eq([
                [:delay_run, [{run_at: nil, strand: strand}], [:step_first]],
                [:delay_run, [{run_at: nil, strand: strand}], [:step_first]],
                [:delay_run, [{run_at: 1.second.from_now, strand: strand}], [:step_second]],
                [:delay_run, [{run_at: 2.seconds.from_now, strand: strand}], [:step_second]],
                [:delay_run, [{run_at: 3.seconds.from_now, strand: strand}], [:step_second]],
                # Uses last value once past end of array:
                [:delay_run, [{run_at: 3.seconds.from_now, strand: strand}], [:step_second]],
              ])
            end
          end
        end

        context 'when Retry points to a different step' do
          let(:steps_object) { StateMachineJobTestSteps2.new(4) }

          context 'when the number of retries has not surpassed max_retries for the destination step' do
            before do
              allow(steps_object).to receive(:step_first).and_return(
                described_class::Retry.new(
                  error: StandardError.new, step: :step_second, delay_amount: 123
                )
              )

              subject.send(:run, nil)
            end

            it 'enqueues a job starting at that step' do
              expect(steps_object.steps_run).to eq([
                [:delay_run, [{run_at: 123.seconds.from_now, strand: strand}], [:step_second]],
              ])
            end

            it 'sets step in job' do
              expect(state_record.reload.job_state).to include(step: :step_second)
            end

            it 'keeps track of retries under that step' do
              expect(state_record.reload.job_state).to include(retries_by_step: {'step_second' => 1})
            end
          end

          context 'when the number of retries has surpassed max_retries for the destination step' do
            before do
              subject.send(:run, nil)
              4.times { subject.send(:run, :step_first) }
              # now, retries are exhausted for step_first
              allow(steps_object).to receive(:step_second).and_return(
                described_class::Retry.new(
                  error: StandardError.new('foo'), step: :step_first, delay_amount: 123
                )
              )
            end

            it 'bubbles up the retry' do
              expect { subject.send(:run, :step_second) }.to raise_error(StandardError, 'foo')
              expect(state_record.reload.workflow_state).to eq('errored')
            end
          end
        end
      end

      context 'when the step returns a DelayedNextStep' do
        before do
          subject.send(:run, nil)
          allow(steps_object).to receive(:step_first).and_return \
            described_class::DelayedNextStep.new(:step_second, 1.minute, 'abc123')
          steps_object.steps_run.clear
        end

        it 'enqueues a job for that step' do
          subject.send(:run, :step_first)
          expect(steps_object.steps_run).to eq([
            [:delay_run, [{run_at: 1.minute.from_now, strand: strand}], [:step_second]],
          ])
        end

        it 'leaves retries_by_step untouched' do
          expect { subject.send(:run, :step_first) }.not_to \
            change { state_record.reload.job_state[:retries_by_step] }.from('step_first' => 1)
        end

        it 'sets job_state step, updated_at, and data' do
          Timecop.freeze(2.minutes.from_now) do
            expect { subject.send(:run, :step_first) }
              .to change { state_record.reload.job_state[:data] }.to('abc123')
              .and change { state_record.reload.job_state[:step] }.to(:step_second)
              .and change { state_record.reload.job_state[:updated_at] }.to(Time.zone.now)
          end
        end
      end

      context 'when an unhandled error occurs' do
        let(:error) { Errors::PublicError.new('uhoh') }

        context "when the error doesn't include GracefulCancelTestError" do
          before do
            subject.send(:run, nil)
            subject.send(:run, :step_first)

            allow(steps_object).to receive(:step_second).and_raise(error)
          end

          it 'bubbles up the error, sets the record state to errored, and calls after_failure' do
            expect { subject.send(:run, :step_first) }.to raise_error(error)

            expect(state_record.reload.job_state).to eq(nil)
            expect(state_record.workflow_state).to eq('errored')
            expect(state_record.last_error).to eq(Errors.user_facing_message(error))
            expect(steps_object.steps_run.last).to eq([:after_failure])
          end

          it 'sends the error to Canvas::Errors.capture' do
            expect(Canvas::Errors).to receive(:capture).with(
              error, {tags: {type: 'microsoft_sync_smj'}}, :error
            )
            expect { subject.send(:run, :step_first) }.to raise_error(error)
          end

          it 'increments the "failure" statsd metric' do
            allow(InstStatsd::Statsd).to receive(:increment)
            expect { subject.send(:run, :step_first) }.to raise_error(error)
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              'microsoft_sync.smj.failure',
              tags: {
                microsoft_sync_step: 'step_second', category: 'MicrosoftSync::Errors::PublicError'
              }
            )
          end
        end

        context 'when the error includes GracefulCancelErrorMixin' do
          class GracefulCancelTestError < StandardError
            include MicrosoftSync::StateMachineJob::GracefulCancelErrorMixin
          end

          let(:error) { GracefulCancelTestError.new }

          before { allow(steps_object).to receive(:step_first).and_raise(error) }

          it 'sets the record state, calls after_failure, and stops processing but does not bubble up the error' do
            subject.send(:run, nil)
            # nothing enqueued
            expect(steps_object.steps_run).to eq([[:after_failure]])

            expect(state_record.reload.job_state).to eq(nil)
            expect(state_record.workflow_state).to eq('errored')
            expect(state_record.last_error).to eq(Errors.user_facing_message(error))
          end

          it 'increments a "canceled" statsd metric' do
            allow(InstStatsd::Statsd).to receive(:increment)
            subject.send(:run, nil)
            expect(InstStatsd::Statsd).to have_received(:increment).with(
              'microsoft_sync.smj.cancel',
              tags: {
                microsoft_sync_step: 'step_first',
                category: 'MicrosoftSync::GracefulCancelTestError'
              }
            )
          end
        end
      end

      context 'when the record is in workflow_state deleted' do
        before { state_record.update!(workflow_state: 'deleted') }

        it "doesn't start a new job" do
          subject.send(:run, nil)
          expect(steps_object.steps_run).to eq([])
        end

        it "doesn't continue a retried job" do
          state_record.update(job_state: {step: :step_first})
          subject.send(:run, :step_first)
          expect(steps_object.steps_run).to eq([])
        end
      end

      context 'when the record is deleted while the job is running' do
        before do
          expect(steps_object).to receive(:step_first) do
            MicrosoftSync::Group.where(id: state_record.id).update_all(workflow_state: 'deleted')
            step_result
          end
        end

        context 'when the step returns COMPLETE' do
          let(:step_result) { described_class::COMPLETE }

          it "doesn't set the workflow_state to completed" do
            subject.send(:run, nil)
            expect(state_record.reload.workflow_state).to eq('deleted')
          end
        end

        context 'when the step returns Retry' do
          let(:step_result) { described_class::Retry.new(error: StandardError.new) }

          before { subject.send(:run, nil) }

          it "doesn't update the job_state/workflow_state" do
            expect(state_record.reload.workflow_state).to eq('deleted')
            expect(state_record.job_state).to eq(nil)
          end

          it "doesn't retry the job or run the stash block" do
            expect(steps_object.steps_run).to eq([])
          end
        end

        context 'when the step raises an error' do
          let(:step_result) { raise StandardError, 'foo123' }

          it "doesn't set the workflow_state to errored" do
            expect { subject.send(:run, nil) }.to raise_error(StandardError, 'foo123')
            expect(state_record.reload.workflow_state).to eq('deleted')
          end
        end
      end

      context 'when there is a mismatch between the step in the job_state field and job arguments' do
        context 'when job_state is nil' do
          it 'captures an error with Canvas::Errors and then raises it' do
            expect(Canvas::Errors).to receive(:capture).with(
              instance_of(StateMachineJob::InternalError),
              {tags: {type: 'microsoft_sync_smj'}},
              :error
            )
            expect {
              subject.send(:run, :step_first)
            }.to raise_error(StateMachineJob::InternalError, /Job step doesn't match state: :step_first != nil/)
          end
        end

        context 'when the step in the job args is nil' do
          before do
            subject.send(:run, nil)
            subject.send(:run, :step_first)
          end

          context 'when the updated_at is before restart_job_after_inactivity' do
            before do
              Timecop.travel((6.hours + 1.second).from_now)
            end

            it 'restarts the job (in-progress job has stalled)' do
              expect(state_record.job_state[:step]).to eq(:step_first)
              expect(state_record.job_state[:retries_by_step]['step_first']).to eq(2)
              expect(steps_object).to receive(:step_first) do
                expect(state_record.job_state).to eq(nil)
                expect(state_record.workflow_state).to eq('running')
                described_class::Retry.new(error: StandardError.new)
              end
              expect { subject.send(:run, nil) }.to change{ state_record.job_state[:updated_at] }
              expect(state_record.job_state[:retries_by_step]['step_first']).to eq(1)
            end

            it 'increments a "stalled" statsd metric' do
              allow(InstStatsd::Statsd).to receive(:increment)
              subject.send(:run, nil)
              expect(InstStatsd::Statsd).to have_received(:increment).with(
                'microsoft_sync.smj.stalled',
                tags: {microsoft_sync_step: 'step_first'}
              )
            end
          end

          context 'when the updated_at is not before restart_job_after_inactivity (in-progress job)' do
            it 'does nothing (ignores/drops the job)' do
              Timecop.travel((5.hours + 59.minutes).from_now)
              expect(state_record.job_state[:step]).to eq(:step_first)
              expect(steps_object).not_to receive(:step_first)
              expect { subject.send(:run, nil) }.to_not change{ state_record.reload.attributes }
            end
          end
        end

        context 'when neither is nil' do
          it 'raises an error' do
            subject.send(:run, nil)
            expect { subject.send(:run, :step_second) }.to raise_error(
              StateMachineJob::InternalError, /Job step doesn't match state: :step_second != :step_first/
            )
          end
        end
      end
    end
  end
end
