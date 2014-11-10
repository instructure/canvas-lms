#
# Copyright (C) 2013 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ProgressRunner do
  before do
    @progress = mock("progress")
    @progress.stub_everything
  end

  module ProgressMessages
    def message=(m)
      @message = m
    end

    def message
      @message
    end
  end

  it "should perform normal processing and update progress" do
    @progress.expects(:start!).once
    @progress.expects(:calculate_completion!).times(3)
    @progress.expects(:complete!).once
    @progress.expects(:completion=).with(100.0).once
    @progress.expects(:message=).with("foo").once
    @progress.expects(:save).once

    progress_runner = ProgressRunner.new(@progress)

    completed_message_value = nil
    progress_runner.completed_message {|completed| completed_message_value = completed; "foo"}

    error_callback_called = false
    progress_runner.error_message {|message, error_ids| error_callback_called = true; "bar"}

    process_callback_count = 0
    ids = (0..9).to_a
    progress_runner.do_batch_update(ids) do |id|
      expect(id).to eql process_callback_count
      process_callback_count += 1
    end

    expect(process_callback_count).to eql ids.size
    expect(completed_message_value).to eql ids.size
    expect(error_callback_called).to be_falsey
  end

  it "should rescue exceptions and record messages as errors" do
    @progress.extend(ProgressMessages)
    @progress.expects(:complete!).once
    @progress.expects(:completion=).with(100.0)
    @progress.expects(:save).once

    progress_runner = ProgressRunner.new(@progress)

    progress_runner.completed_message do |count|
      expect(count).to eql 1
      "abra"
    end

    error_callback_count = 0
    progress_runner.error_message do |error, ids|
      error_callback_count += 1
      "#{error}: #{ids.join(', ')}"
    end

    ids = (1..3).to_a
    progress_runner.do_batch_update(ids) do |id|
      raise "error processing #{id}" if id >= 2
    end

    expect(error_callback_count).to eql 2
    message_lines = @progress.message.lines.map(&:strip).sort
    expect(message_lines.size).to eql 3
    expect(message_lines).to eql ["abra", "error processing 2: 2", "error processing 3: 3"]
  end

  it "should have default completion and error messages" do
    @progress.extend(ProgressMessages)

    progress_runner = ProgressRunner.new(@progress)
    ids = (1..4).to_a
    progress_runner.do_batch_update(ids) do |id|
      raise "processing error" if id >= 3
    end
    expect(@progress.message).to eql "2 items processed\nprocessing error: 3, 4"
  end
  # These are also tested above
  #it "should accumulate like errors into a single mesage line"
  #it "should complete progress if only some records fail"

  it "should fail progress if all records fail" do
    @progress.extend(ProgressMessages)
    @progress.expects(:completion=).with(100.0)
    @progress.expects(:fail!).once
    @progress.expects(:save).once

    progress_runner = ProgressRunner.new(@progress)
    ids = (1..4).to_a
    progress_runner.do_batch_update(ids) do |id|
      raise "processing error"
    end

    expect(@progress.message).to eql "0 items processed\nprocessing error: 1, 2, 3, 4"
  end

  it "updates progress frequency relative to size of input" do
    ids = (1..255).to_a
    times_update = (ids.size / (ids.size / 20).to_f).ceil
    @progress.expects(:calculate_completion!).times(times_update)

    progress_runner = ProgressRunner.new(@progress)
    progress_runner.do_batch_update(ids) {}
  end

end
