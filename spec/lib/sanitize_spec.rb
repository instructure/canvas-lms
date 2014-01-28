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

describe Sanitize do
  it "should sanitize style attributes width invalid url protocols" do
    str = "<div style='width: 200px; background: url(httpx://www.google.com) no-repeat left center; height: 10px;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should_not match(/background/)
    res.should_not match(/google/)
    res.should match(/width/)
    res.should match(/height/)
  end

  it "should sanitize the entire style string if they try to get tricky" do
    str = "<div style=\"width: 200px; background:url('java\nscript:alert(1)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should_not match(/background/)
    res.should_not match(/alert/)
    res.should_not match(/height/)
    res.should_not match(/width/)

    str = "<div style=\"width: 200px; background:url('javascript\n:alert(1)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should_not match(/background/)
    res.should_not match(/alert/)
    res.should_not match(/height/)
    res.should_not match(/width/)
    
    str = "<div style=\"width: 200px; background:url('&#106;avascript:alert(5)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should_not match(/background/)
    res.should_not match(/alert/)
    res.should_not match(/height/)
    res.should_not match(/width/)
  end
  
  it "should sanitize style attributes width invalid methods" do
    str = "<div style='width: 200px; background: xurl(http://www.google.com) no-repeat left center; height: 10px;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should_not match(/background/)
    res.should_not match(/google/)
    res.should match(/width/)
    res.should match(/height/)

    str = "<div style=\"width: 200px; background:(http://www.yahoo.com); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should_not match(/background/)
    res.should_not match(/yahoo/)
    res.should match(/height/)
    res.should match(/width/)

    str = "<div style=\"width: 200px; background:expression(); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should_not match(/background/)
    res.should_not match(/\(/)
    res.should match(/height/)
    res.should match(/width/)
  end
  
  it "should allow negative values" do
    str = "<div style='margin: -18px;height: 10px;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should match(/margin/)
    res.should match(/height/)
  end

  it "should remove non-whitelisted css attributes" do
    str = "<div style='bacon: 5px; border-left-color: #fff;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should match(/border-left-color/)
    res.should_not match(/bacon/)
  end

  it "should allow valid css methods with valid css protocols" do
    str = %{<div style="width: 200px; background: url(http://www.google.com) no-repeat left center; height: 10px;"></div>}
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should == str
  end
  
  it "should allow font tags with valid attributes" do
    str = %{<font face="Comic Sans MS" color="blue" size="3" bacon="yes">hello</font>}
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should == %{<font face="Comic Sans MS" color="blue" size="3">hello</font>}
  end

  it "should remove and not escape contents of style tags" do
    str = %{<p><style type="text/css">pleaseignoreme: blahblahblah</style>but not me</p>}
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    res.should == "<p>but not me</p>"
  end

  Dir.glob(Rails.root.join('spec', 'fixtures', 'xss', '*.xss')) do |filename|
    name = File.split(filename).last
    it "should sanitize xss attempts for #{name}" do
      f = File.open(filename)
      check = f.readline.strip
      str = f.read
      res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
      res.downcase.should_not match(Regexp.new(check.downcase))
    end
  end
end
