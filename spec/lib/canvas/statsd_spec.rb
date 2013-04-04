#
# Copyright (C) 2012 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe "Canvas::Statsd" do
  METHODS = %w(increment decrement count gauge timing)

  it "should append the hostname to stat names by default" do
    Canvas::Statsd.stubs(:hostname).returns("testhost")
    statsd = mock()
    Canvas::Statsd.stubs(:instance).returns(statsd)
    Canvas::Statsd.stubs(:append_hostname?).returns(true)
    METHODS.each do |method|
      statsd.expects(method).with("test.name.testhost", "test")
      Canvas::Statsd.send(method, "test.name", "test")
    end
    statsd.expects("timing").with("test.name.testhost", anything, anything)
    Canvas::Statsd.time("test.name") { "test" }.should == "test"
  end

  it "should omit hostname if specified in config" do
    Canvas::Statsd.expects(:hostname).never
    statsd = mock()
    Canvas::Statsd.stubs(:instance).returns(statsd)
    Canvas::Statsd.stubs(:append_hostname?).returns(false)
    METHODS.each do |method|
      statsd.expects(method).with("test.name", "test")
      Canvas::Statsd.send(method, "test.name", "test")
    end
    statsd.expects("timing").with("test.name", anything, anything)
    Canvas::Statsd.time("test.name") { "test" }.should == "test"
  end

  it "should ignore all calls if statsd isn't enabled" do
    Canvas::Statsd.stubs(:instance).returns(nil)
    METHODS.each do |method|
      Canvas::Statsd.send(method, "test.name").should be_nil
    end
    Canvas::Statsd.time("test.name") { "test" }.should == "test"
  end

  it "should configure a statsd instance" do
    Setting.expects(:from_config).with('statsd').returns({})
    Canvas::Statsd.reset_instance
    Canvas::Statsd.instance.should be_nil

    Setting.expects(:from_config).with('statsd').returns({ :host => "testhost", :namespace => "test", :port => 1234 })
    Canvas::Statsd.reset_instance
    instance = Canvas::Statsd.instance
    instance.should be_a ::Statsd
    instance.host.should == "testhost"
    instance.port.should == 1234
    instance.namespace.should == "test"
  end

  after do
    Canvas::Statsd.reset_instance
  end
end
