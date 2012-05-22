#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe Canvas do
  describe "sampling methods" do
    it "should sample the cpu on linux" do
      if File.directory?("/proc")
        sample = Canvas.sample_cpu_time
        sample[0].should be > 0.0
        sample[1].should be > 0.0
      end
    end
  end

  describe ".timeout_protection" do
    it "should wrap the block in a timeout" do
      Setting.set("service_generic_timeout", "2")
      Timeout.expects(:timeout).with(2).yields
      ran = false
      Canvas.timeout_protection("spec") { ran = true }
      ran.should == true

      # service-specific timeout
      Setting.set("service_spec_timeout", "1")
      Timeout.expects(:timeout).with(1).yields
      ran = false
      Canvas.timeout_protection("spec") { ran = true }
      ran.should == true
    end

    if Canvas.redis_enabled?
      it "should skip calling the block after X failures" do
        Setting.set("service_spec_cutoff", "2")
        Timeout.expects(:timeout).with(15).twice.raises(Timeout::Error)
        Canvas.timeout_protection("spec") {}
        Canvas.timeout_protection("spec") {}
        ran = false
        # third time, won't call timeout
        Canvas.timeout_protection("spec") { ran = true }
        ran.should == false
        # verify the redis key has a ttl
        key = "service:timeouts:spec"
        Canvas.redis.get(key).should == "2"
        Canvas.redis.ttl(key).should be_present
        # delete the redis key and it'll try again
        Canvas.redis.del(key)
        Timeout.expects(:timeout).with(15).yields
        Canvas.timeout_protection("spec") { ran = true }
        ran.should == true
      end
    end
  end
end
