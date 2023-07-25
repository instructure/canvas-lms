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

require "spec_helper"
require "action_controller"
require_relative "data/owned_class"

describe CanvasErrors do
  error_testing_class = Class.new do
    attr_accessor :exception, :details, :level

    def register!
      target = self
      CanvasErrors.register!(:test_thing) do |e, d, l|
        target.exception = e
        target.details = d
        target.level = l
        "ERROR_BLOCK_RESPONSE"
      end
    end
  end

  before do
    @old_registry = described_class.instance_variable_get(:@registry)
    described_class.clear_callback_registry!
    @error_harness = error_testing_class.new
    @error_harness.register!
  end

  after do
    described_class.instance_variable_set(:@registry, @old_registry)
  end

  let(:error) { double("Some Error", backtrace: []) }

  describe ".capture_exception" do
    it "tags with the exception type and default level" do
      CanvasErrors.capture_exception(:core_meltdown, error)
      expect(@error_harness.exception).to eq(error)
      expect(@error_harness.details[:tags][:type]).to eq("core_meltdown")
      expect(@error_harness.level).to eq(:error)
    end
  end

  describe "with inferred context" do
    around do |example|
      prev_context = Thread.current[:context]
      example.run
    ensure
      Thread.current[:context] = prev_context
    end

    it "attaches current job context to error hashes" do
      fake_job_class = Class.new do
        def perform; end

        def tag
          "#perform"
        end
      end
      job = fake_job_class.new
      allow(Delayed::Worker).to receive(:current_job).and_return(job)
      CanvasErrors.capture(RuntimeError.new, { my_tag: "my_value" }, :warn)
      expect(@error_harness.details[:extra][:my_tag]).to eq("my_value")
      expect(@error_harness.details[:tags]).to eq({ :job_tag => "#perform", "inst.team" => "unknown", :process_type => "BackgroundJob" })
      expect(@error_harness.level).to eq(:warn)
    end

    it "attaches request context to error hashes collected manually" do
      Thread.current[:context] = {
        request_id: "1234request1234",
        session_id: "1234session1234"
      }
      CanvasErrors.capture(RuntimeError.new, { my_tag: "custom_value" }, :info)
      expect(@error_harness.details[:tags]).to eq({ "inst.team" => "unknown" })
      expect(@error_harness.details[:extra][:my_tag]).to eq("custom_value")
      expect(@error_harness.details[:extra][:request_id]).to eq("1234request1234")
      expect(@error_harness.details[:extra][:session_id]).to match("1234session1234")
      expect(@error_harness.level).to eq(:info)
    end
  end

  it "fires callbacks when it handles an exception" do
    CanvasErrors.capture(error)
    expect(@error_harness.exception).to eq(error)
  end

  it "passes through extra information if available wrapped in extra" do
    CanvasErrors.capture(error, { detail1: "blah" })
    expect(@error_harness.details[:extra][:detail1]).to eq("blah")
  end

  it "captures output from each callback according to their registry tag" do
    outputs = CanvasErrors.capture(error)
    expect(outputs[:test_thing]).to eq("ERROR_BLOCK_RESPONSE")
  end

  describe "with an owned class" do
    it "sets the team tag" do
      begin
        OwnedClass.new.raise
      rescue => e
        CanvasErrors.capture(e)
      end
      expect(@error_harness.details[:tags]["inst.team"]).to eq("test")
    end
  end
end
