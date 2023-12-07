# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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
#

describe Progress do
  describe "#process_job" do
    before do
      stub_const("Jerbs", Class.new do
        cattr_accessor :flag
        extend RSpec::Matchers

        def self.succeed(progress, flag)
          expect(progress.state).to eq :running
          self.flag = flag
        end

        def self.fail(_progress)
          raise "fail!"
        end
      end)
    end

    before { Jerbs.flag = nil }

    let(:progress) { Progress.create!(tag: "test", context: user_factory) }

    it "updates the progress while running the job" do
      progress.process_job(Jerbs, :succeed, {}, :flag)
      expect(progress).to be_queued
      run_jobs
      expect(progress.reload).to be_completed
      expect(progress.completion).to eq 100
      expect(Jerbs.flag).to eq :flag
    end

    it "stores the delayed_job_id" do
      progress.process_job(Jerbs, :succeed, {}, :flag)
      expect(progress).to be_queued
      expect(progress.delayed_job_id).to be_present
    end

    it "fails the progress if the job fails" do
      progress.process_job(Jerbs, :fail, {})
      run_jobs
      expect(progress.reload).to be_failed
    end

    it "cancels other queued progresses with the same delayed_job_id" do
      job1 = progress.process_job(Jerbs, :succeed, { singleton: "test_singleton", on_conflict: :overwrite }, :flag)
      expect(progress.reload).to be_queued
      expect(job1.enqueue_result).to be :inserted
      progress2 = Progress.create!(tag: "test", context: @user)
      job2 = progress2.process_job(Jerbs, :succeed, { singleton: "test_singleton", on_conflict: :overwrite }, :flag)
      expect(progress2.reload).to be_queued
      expect(progress.reload).to be_canceled
      expect(job1.id).to be job2.id
      expect(job2.enqueue_result).to be :updated
    end

    it "defaults to low priority" do
      job = progress.process_job(Jerbs, :succeed, {}, :flag)
      expect(job.priority).to eq Delayed::LOW_PRIORITY
    end

    context "with high priority" do
      it "is set to high priortiy" do
        job = progress.process_job(Jerbs, :succeed, { priority: Delayed::HIGH_PRIORITY }, :flag)
        expect(job.priority).to eq Delayed::HIGH_PRIORITY
      end
    end

    context "running totals" do
      it "calculates increments correctly" do
        progress.calculate_completion!(2, 50)
        expect(progress.completion).to eq 4.0
        expect(progress).not_to be_changed
        progress.increment_completion!(1)
        expect(progress.completion).to eq 6.0
        expect(progress).not_to be_changed
      end

      it "does not update for very tiny increments" do
        progress.calculate_completion!(2, 5000)
        expect(progress.completion).to eq 0.04
        expect(progress).not_to be_changed
        progress.increment_completion!(1)
        expect(progress.completion).to eq 0.06
        # it didn't actually save it to the db
        expect(progress).to be_changed
        progress.increment_completion!(1000)
        expect(progress.completion).to eq 20.06
        expect(progress).not_to be_changed
      end
    end
  end
end
