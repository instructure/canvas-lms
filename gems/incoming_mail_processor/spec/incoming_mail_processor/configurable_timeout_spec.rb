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
require 'spec_helper'

describe IncomingMailProcessor::ConfigurableTimeout do
  class TimeoutTester
    include IncomingMailProcessor::ConfigurableTimeout
    def default_timeout_duration
      0.0001
    end

    def foo(arg)
      arg
    end

  end

  before do
    @tester = TimeoutTester.new
  end

  it "should provide a default timeout" do
    expect { @tester.with_timeout { sleep 1 } }.to raise_error(Timeout::Error)
  end

  it "should use the provided timeout method" do
    method_called = false
    block_called = false
    # use an explicit block param because yield scoping is weird
    @tester.set_timeout_method do |&block|
      method_called = true
      block.call
    end
    @tester.with_timeout { block_called = true }
    expect(method_called).to be_truthy
    expect(block_called).to be_truthy
  end

  it "should return what the timeout method returns" do
    @tester.set_timeout_method { 42 }
    expect(@tester.with_timeout).to equal 42
  end

  it "should raise what the timeout method raises" do
    @tester.set_timeout_method { raise ArgumentError }
    expect { @tester.with_timeout { 42 } }.to raise_error(ArgumentError)
  end

  it "should raise what the target method raises" do
    expect { @tester.with_timeout { raise ArgumentError } }.to raise_error(ArgumentError)
  end

  it "should allow easy wrapping of methods" do
    @tester.wrap_with_timeout(@tester, [:foo])
    @tester.set_timeout_method { raise ArgumentError }
    expect { @tester.foo(42) }.to raise_error(ArgumentError)
    expect(@tester.untimed_foo(42)).to equal 42
    @tester.set_timeout_method {|&block| block.call }
    expect(@tester.foo(42)).to equal 42
  end

end
