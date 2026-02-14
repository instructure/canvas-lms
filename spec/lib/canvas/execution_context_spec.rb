# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Canvas::ExecutionContext do
  before do
    Canvas::ExecutionContext.clear_cache
    allow(Canvas).to receive_messages(
      region: "us-east-1",
      revision: "abc123"
    )
  end

  after do
    Canvas::ExecutionContext.clear_cache
    ActiveSupport::ExecutionContext.clear
  end

  describe "[]" do
    it "returns values set in ActiveSupport::ExecutionContext" do
      ActiveSupport::ExecutionContext[:custom_key] = "custom_value"
      expect(Canvas::ExecutionContext[:custom_key]).to eq("custom_value")
    end

    it "returns :region value" do
      allow(Canvas).to receive(:region).and_return("us-east-1")
      expect(Canvas::ExecutionContext[:region]).to eq("us-east-1")
    end

    it "returns :revision value" do
      expect(Canvas::ExecutionContext[:revision]).to eq("abc123")
    end

    it 'returns "unknown-region" when Canvas.region is nil' do
      allow(Canvas).to receive(:region).and_return(nil)
      Canvas::ExecutionContext.clear_cache
      expect(Canvas::ExecutionContext[:region]).to eq("unknown-region")
    end

    it 'returns "unknown-revision" when Canvas.revision is nil' do
      allow(Canvas).to receive(:revision).and_return(nil)
      Canvas::ExecutionContext.clear_cache
      expect(Canvas::ExecutionContext[:revision]).to eq("unknown-revision")
    end
  end

  describe "job?" do
    it "returns true when :job is set in execution context" do
      job = instance_double(Delayed::Job, global_id: "job-123", source: "test_source", tag: "test_tag")

      expect do
        ActiveSupport::ExecutionContext[:job] = job
      end.to change { Canvas::ExecutionContext.job? }.from(false).to(true)
    end

    it "returns false when :job is not set" do
      expect(Canvas::ExecutionContext.job?).to be false
    end
  end

  describe "request?" do
    it "returns true when :controller is set and no :job" do
      allow(RequestContext::Generator).to receive(:request_id).and_return("req-123")

      expect do
        ActiveSupport::ExecutionContext[:controller] = "SomeController"
      end.to change { Canvas::ExecutionContext.request? }.from(false).to(true)
    end

    it "returns false when :controller is not set" do
      expect(Canvas::ExecutionContext.request?).to be false
    end

    it "returns false when both :controller and :job are set (job takes precedence)" do
      allow(RequestContext::Generator).to receive(:request_id).and_return("req-123")
      ActiveSupport::ExecutionContext[:controller] = "SomeController"

      job = instance_double(Delayed::Job, global_id: "job-123", source: "test_source", tag: "test_tag")
      expect do
        ActiveSupport::ExecutionContext[:job] = job
      end.to change { Canvas::ExecutionContext.request? }.from(true).to(false)
    end
  end

  describe "to_h" do
    it "returns request context as hash with request_id computed" do
      ActiveSupport::ExecutionContext[:controller] = "SomeController"
      allow(RequestContext::Generator).to receive(:request_id).and_return("req-456")
      Canvas::ExecutionContext.clear_cache

      result = Canvas::ExecutionContext.to_h
      expect(result).to eq(
        region: "us-east-1",
        revision: "abc123",
        request_id: "req-456"
      )
    end

    it "returns job context as hash without job object" do
      job = instance_double(Delayed::Job, global_id: "job-789", source: "delayed_job", tag: "important")
      ActiveSupport::ExecutionContext[:job] = job
      Canvas::ExecutionContext.clear_cache

      result = Canvas::ExecutionContext.to_h
      expect(result).to eq(
        region: "us-east-1",
        revision: "abc123",
        job_global_id: "job-789",
        job_source: "delayed_job",
        job_tag: "important"
      )
      expect(result).not_to have_key(:job)
    end

    it "returns only region and revision when no context is set" do
      result = Canvas::ExecutionContext.to_h
      expect(result).to eq(
        region: "us-east-1",
        revision: "abc123"
      )
    end
  end

  describe "to_headers" do
    it "returns request context as HTTP headers" do
      ActiveSupport::ExecutionContext[:controller] = "SomeController"
      allow(RequestContext::Generator).to receive(:request_id).and_return("req-456")
      Canvas::ExecutionContext.clear_cache

      headers = Canvas::ExecutionContext.to_headers
      expect(headers).to eq(
        "canvas-region" => "us-east-1",
        "canvas-revision" => "abc123",
        "canvas-request-id" => "req-456"
      )
    end

    it "returns job context as HTTP headers" do
      job = instance_double(Delayed::Job, global_id: "job-789", source: "delayed_job", tag: "important")
      ActiveSupport::ExecutionContext[:job] = job
      Canvas::ExecutionContext.clear_cache

      headers = Canvas::ExecutionContext.to_headers
      expect(headers).to eq(
        "canvas-region" => "us-east-1",
        "canvas-revision" => "abc123",
        "canvas-job-global-id" => "job-789",
        "canvas-job-source" => "delayed_job",
        "canvas-job-tag" => "important"
      )
    end

    it "returns only region and revision headers when no context is set" do
      headers = Canvas::ExecutionContext.to_headers
      expect(headers).to eq(
        "canvas-region" => "us-east-1",
        "canvas-revision" => "abc123"
      )
    end

    it "includes unknown-region when Canvas.region is nil" do
      allow(Canvas).to receive(:region).and_return(nil)
      Canvas::ExecutionContext.clear_cache

      headers = Canvas::ExecutionContext.to_headers
      expect(headers["canvas-region"]).to eq("unknown-region")
      expect(headers).to have_key("canvas-revision")
    end
  end

  describe "clear_cache" do
    it "clears the cached context so subsequent access re-reads from ActiveSupport" do
      ActiveSupport::ExecutionContext[:initial_key] = "initial_value"

      expect do
        ActiveSupport::ExecutionContext[:initial_key] = "updated_value"
        Canvas::ExecutionContext.clear_cache
      end.to change { Canvas::ExecutionContext[:initial_key] }.from("initial_value").to("updated_value")
    end
  end

  describe "caching behavior" do
    it "returns the same cached hash object on subsequent reads" do
      ActiveSupport::ExecutionContext[:test_key] = "test_value"
      first_access = Canvas::ExecutionContext[:test_key]
      second_access = Canvas::ExecutionContext[:test_key]

      expect(first_access).to eq("test_value")
      expect(second_access).to eq("test_value")
    end

    it "builds a fresh hash after clear_cache" do
      ActiveSupport::ExecutionContext[:first_key] = "first_value"
      Canvas::ExecutionContext[:first_key]

      Canvas::ExecutionContext.clear_cache

      ActiveSupport::ExecutionContext[:second_key] = "second_value"
      expect(Canvas::ExecutionContext[:second_key]).to eq("second_value")
    end
  end

  describe "enrichment behavior" do
    it "enriches context with region and revision from Canvas module" do
      Canvas::ExecutionContext.clear_cache

      expect(Canvas::ExecutionContext[:region]).to eq("us-east-1")
      expect(Canvas::ExecutionContext[:revision]).to eq("abc123")
    end

    it "does not write enriched values to ActiveSupport::ExecutionContext" do
      ActiveSupport::ExecutionContext.clear
      Canvas::ExecutionContext.clear_cache

      _ = Canvas::ExecutionContext[:region]

      expect(ActiveSupport::ExecutionContext.to_h).not_to have_key(:region)
      expect(ActiveSupport::ExecutionContext.to_h).not_to have_key(:revision)
    end

    it "computes job attributes from job object" do
      job = instance_double(Delayed::Job, global_id: "job-123", source: "test", tag: "urgent")
      ActiveSupport::ExecutionContext[:job] = job
      Canvas::ExecutionContext.clear_cache

      expect(Canvas::ExecutionContext[:job_global_id]).to eq("job-123")
      expect(Canvas::ExecutionContext[:job_source]).to eq("test")
      expect(Canvas::ExecutionContext[:job_tag]).to eq("urgent")
    end

    it "does not write job attributes to ActiveSupport::ExecutionContext" do
      job = instance_double(Delayed::Job, global_id: "job-123", source: "test", tag: "urgent")
      ActiveSupport::ExecutionContext[:job] = job
      Canvas::ExecutionContext.clear_cache

      _ = Canvas::ExecutionContext[:job_global_id]

      expect(ActiveSupport::ExecutionContext.to_h).not_to have_key(:job_global_id)
      expect(ActiveSupport::ExecutionContext.to_h).not_to have_key(:job_source)
      expect(ActiveSupport::ExecutionContext.to_h).not_to have_key(:job_tag)
    end

    it "caches computed attributes and does not recompute on subsequent access" do
      Canvas::ExecutionContext.clear_cache

      expect(Canvas).to receive(:region).once.and_return("us-east-1")

      Canvas::ExecutionContext[:region]
      Canvas::ExecutionContext[:region]
    end

    it "eagerly recomputes when ActiveSupport::ExecutionContext changes" do
      Canvas::ExecutionContext.clear_cache
      Canvas::ExecutionContext[:region]

      allow(Canvas).to receive(:region).and_return("us-west-2")
      ActiveSupport::ExecutionContext[:custom_key] = "new_value"

      expect(Canvas::ExecutionContext[:region]).to eq("us-west-2")
    end

    it "always computes attributes from lambdas, overriding AS::EC values" do
      ActiveSupport::ExecutionContext[:region] = "custom-region"
      Canvas::ExecutionContext.clear_cache

      expect(Canvas::ExecutionContext[:region]).to eq("us-east-1")
    end

    it "uses default value when Canvas.region returns nil" do
      allow(Canvas).to receive(:region).and_return(nil)
      Canvas::ExecutionContext.clear_cache

      expect(Canvas::ExecutionContext[:region]).to eq("unknown-region")
    end

    it "uses default value when Canvas.revision returns nil" do
      allow(Canvas).to receive(:revision).and_return(nil)
      Canvas::ExecutionContext.clear_cache

      expect(Canvas::ExecutionContext[:revision]).to eq("unknown-revision")
    end

    it "handles errors in attribute computation gracefully" do
      allow(Canvas).to receive(:region).and_raise(StandardError.new("test error"))
      Canvas::ExecutionContext.clear_cache

      expect(Rails.logger).to receive(:warn).with(/Error computing execution context attribute/)

      expect(Canvas::ExecutionContext[:region]).to be_nil
    end
  end

  describe "error handling" do
    it "rebuild_cache clears cache on error and allows lazy retry" do
      allow(ActiveSupport::ExecutionContext).to receive(:to_h).and_raise(RuntimeError.new("boom"))
      expect(Rails.logger).to receive(:warn).with(/Error rebuilding execution context cache: boom/)

      Canvas::ExecutionContext.rebuild_cache

      expect(Thread.current[:canvas_execution_context]).to be_nil

      allow(ActiveSupport::ExecutionContext).to receive(:to_h).and_call_original
      expect(Canvas::ExecutionContext[:region]).to eq("us-east-1")
    end

    it "cached_context returns empty hash on error and caches it" do
      Canvas::ExecutionContext.clear_cache
      allow(ActiveSupport::ExecutionContext).to receive(:to_h).and_raise(RuntimeError.new("boom"))
      expect(Rails.logger).to receive(:warn).with(/Error computing execution context: boom/)

      expect(Canvas::ExecutionContext[:region]).to be_nil
      expect(Canvas::ExecutionContext.to_h).to eq({})
      expect(Canvas::ExecutionContext.to_headers).to eq({})
      expect(Canvas::ExecutionContext.request?).to be false
      expect(Canvas::ExecutionContext.job?).to be false
    end

    it "rebuild_cache replaces a cached empty hash after recovery" do
      Canvas::ExecutionContext.clear_cache
      allow(ActiveSupport::ExecutionContext).to receive(:to_h).and_raise(RuntimeError.new("boom"))
      allow(Rails.logger).to receive(:warn)

      Canvas::ExecutionContext[:region]
      expect(Thread.current[:canvas_execution_context]).to eq({})

      allow(ActiveSupport::ExecutionContext).to receive(:to_h).and_call_original
      Canvas::ExecutionContext.rebuild_cache

      expect(Canvas::ExecutionContext[:region]).to eq("us-east-1")
    end
  end
end
