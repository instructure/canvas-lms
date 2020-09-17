#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_dependency "canvas/errors"
module Canvas
  describe Errors do
    before(:each) do
      @old_registry = described_class.instance_variable_get(:@registry)
      described_class.clear_callback_registry!
    end

    after(:each) do
      described_class.instance_variable_set(:@registry, @old_registry)
    end

    let(:error){double("Some Error") }

    describe '.capture_exception' do
      it 'tags with the exception type' do
        exception = details = nil
        Canvas::Errors.register!(:test_thing) do |e, d|
          exception = e
          details = d
        end
        Canvas::Errors.capture_exception(:core_meltdown, error)
        expect(exception).to eq(error)
        expect(details).to eq({tags: {type: 'core_meltdown'}})
      end
    end

    describe 'with inferred context' do
      around(:each) do |example|
        prev_context = Thread.current[:context]
        example.run
      ensure
        Thread.current[:context] = prev_context
      end

      it "attaches current job context to error hashes" do
        fake_job_class = Class.new do
          def perform; end
        end
        exception = details = nil
        Canvas::Errors.register!(:test_thing) do |e, d|
          exception = e
          details = d
        end
        job = Delayed::Job.enqueue(fake_job_class.new)
        allow(Delayed::Worker).to receive(:current_job).and_return(job)
        Canvas::Errors.capture(RuntimeError.new, { my_tag: "my_value"})

        expect(details[:extra][:my_tag]).to eq("my_value")
        expect(details[:tags][:job_tag]).to match('#perform')
      end

      it "attaches request context to error hashes collected manually" do
        Thread.current[:context] = {
          request_id: '1234request1234',
          session_id: '1234session1234'
        }
        exception = details = nil
        Canvas::Errors.register!(:test_thing) do |e, d|
          exception = e
          details = d
        end
        Canvas::Errors.capture(RuntimeError.new, { my_tag: "custom_value"})
        expect(details[:extra][:my_tag]).to eq("custom_value")
        expect(details[:extra][:request_id]).to eq("1234request1234")
        expect(details[:extra][:session_id]).to match('1234session1234')
      end
    end

    it 'fires callbacks when it handles an exception' do
      called_with = nil
      Canvas::Errors.register!(:test_thing) do |exception|
        called_with = exception
      end
      Canvas::Errors.capture(error)
      expect(called_with).to eq(error)
    end

    it "passes through extra information if available wrapped in extra" do
      extra_info = nil
      Canvas::Errors.register!(:test_thing) do |_exception, details|
        extra_info = details
      end
      Canvas::Errors.capture(double(), {detail1: 'blah'})
      expect(extra_info).to eq({extra: {detail1: 'blah'}})
    end

    it 'captures output from each callback according to their registry tag' do
      Canvas::Errors.register!(:test_thing) do
        "FOO-BAR"
      end
      outputs = Canvas::Errors.capture(double())
      expect(outputs[:test_thing]).to eq('FOO-BAR')
    end
  end
end
