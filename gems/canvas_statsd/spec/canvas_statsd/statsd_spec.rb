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

require 'spec_helper'

describe CanvasStatsd::Statsd do
  METHODS = %w(increment decrement count gauge timing)

  it "appends the hostname to stat names by default" do
    CanvasStatsd::Statsd.stub(:hostname).and_return("testhost")
    statsd = double
    CanvasStatsd::Statsd.stub(:instance).and_return(statsd)
    CanvasStatsd::Statsd.stub(:append_hostname?).and_return(true)
    METHODS.each do |method|
      expect(statsd).to receive(method).with("test.name.testhost", "test")
      CanvasStatsd::Statsd.send(method, "test.name", "test")
    end
    expect(statsd).to receive("timing").with("test.name.testhost", anything, anything)
    expect(CanvasStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "omits hostname if specified in config" do
    expect(CanvasStatsd::Statsd).to receive(:hostname).never
    statsd = double
    CanvasStatsd::Statsd.stub(:instance).and_return(statsd)
    CanvasStatsd::Statsd.stub(:append_hostname?).and_return(false)
    METHODS.each do |method|
      expect(statsd).to receive(method).with("test.name", "test")
      CanvasStatsd::Statsd.send(method, "test.name", "test")
    end
    expect(statsd).to receive("timing").with("test.name", anything, anything)
    expect(CanvasStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "ignores all calls if statsd isn't enabled" do
    CanvasStatsd::Statsd.stub(:instance).and_return(nil)
    METHODS.each do |method|
      expect(CanvasStatsd::Statsd.send(method, "test.name")).to be_nil
    end
    expect(CanvasStatsd::Statsd.time("test.name") { "test" }).to eq "test"
  end

  it "configures a statsd instance" do
    expect(CanvasStatsd::Statsd.instance).to be_nil

    CanvasStatsd.settings = { :host => "testhost", :namespace => "test", :port => 1234 }
    CanvasStatsd::Statsd.reset_instance

    instance = CanvasStatsd::Statsd.instance
    expect(instance).to be_a ::Statsd
    expect(instance.host).to eq "testhost"
    expect(instance.port).to eq 1234
    expect(instance.namespace).to eq "test"
  end

  after do
    CanvasStatsd::Statsd.reset_instance
  end
end
