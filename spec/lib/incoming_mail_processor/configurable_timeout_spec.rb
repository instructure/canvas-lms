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

require File.expand_path('../../../../lib/incoming_mail_processor/configurable_timeout', __FILE__)
require File.expand_path('../../../mocha_rspec_adapter', __FILE__)

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
    lambda { @tester.with_timeout { sleep 1 } }.should raise_error(Timeout::Error)
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
    method_called.should be_true
    block_called.should be_true
  end

  it "should return what the timeout method returns" do
    @tester.set_timeout_method { 42 }
    @tester.with_timeout.should equal 42
  end

  it "should raise what the timeout method raises" do
    @tester.set_timeout_method { raise ArgumentError }
    lambda { @tester.with_timeout { 42 } }.should raise_error(ArgumentError)
  end

  it "should raise what the target method raises" do
    lambda { @tester.with_timeout { raise ArgumentError } }.should raise_error(ArgumentError)
  end

  it "should allow easy wrapping of methods" do
    @tester.wrap_with_timeout(@tester, [:foo])
    @tester.set_timeout_method { raise ArgumentError }
    lambda { @tester.foo(42) }.should raise_error(ArgumentError)
    @tester.untimed_foo(42).should equal 42
    @tester.set_timeout_method {|&block| block.call }
    @tester.foo(42).should equal 42
  end

end
