# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require "delayed/testing"
require_relative "../../apm_common"

describe Canvas::Apm::InstJobs::Plugin do
  include_context "apm"

  around do |example|
    Canvas::Apm::InstJobs::Plugin.tracer = tracer
    Delayed::Worker.plugins << Canvas::Apm::InstJobs::Plugin
    example.run
    Delayed::Worker.plugins.delete(Canvas::Apm::InstJobs::Plugin)
    Delayed::Worker.lifecycle.reset!
    span.reset!
    Canvas::Apm::InstJobs::Plugin.reset!
  end

  describe "instrumenting worker execution" do
    let(:worker) { double(:worker, name: "worker") }

    it "execution callback yields control" do
      expect { |b| Delayed::Worker.lifecycle.run_callbacks(:execute, worker, &b) }.to yield_with_args(worker)
    end
  end

  describe "instrumented job invocation" do
    specs_require_sharding
    let(:sample_job_object) do
      stub_const("SampleJob", Class.new do
        def perform; end
      end)
    end

    it "has resource name equal to job name" do
      expect(Canvas::Apm::InstJobs::Plugin.tracer).to eq(tracer)
      job = Delayed::Job.enqueue(sample_job_object.new)
      job.account_id = 12_345
      Delayed::Testing.run_job(job)
      expect(span.resource).to eq("SampleJob")
      expect(span.tags["inst_jobs.id"] > 0).to be_truthy
      expect(span.tags["inst_jobs.queue"]).to eq("canvas_queue")
      expect(span.tags["inst_jobs.priority"] > 0).to be_truthy
      expect(span.tags["inst_jobs.attempts"]).to eq(0)
      expect(span.tags["inst_jobs.strand"]).to be_nil
      expect(job.shard_id > 0).to be_truthy
      expect(span.tags["shard"]).to eq(job.shard_id.to_s)
      expect(job.account_id > 0).to be_truthy
      expect(span.tags["root_account"]).to eq(job.account_id.to_s)
    end
  end
end
