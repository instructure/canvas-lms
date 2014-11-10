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
    expect(res).not_to match(/background/)
    expect(res).not_to match(/google/)
    expect(res).to match(/width/)
    expect(res).to match(/height/)
  end

  it "should sanitize the entire style string if they try to get tricky" do
    str = "<div style=\"width: 200px; background:url('java\nscript:alert(1)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/alert/)
    expect(res).not_to match(/height/)
    expect(res).not_to match(/width/)

    str = "<div style=\"width: 200px; background:url('javascript\n:alert(1)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/alert/)
    expect(res).not_to match(/height/)
    expect(res).not_to match(/width/)
    
    str = "<div style=\"width: 200px; background:url('&#106;avascript:alert(5)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/alert/)
    expect(res).not_to match(/height/)
    expect(res).not_to match(/width/)
  end
  
  it "should sanitize style attributes width invalid methods" do
    str = "<div style='width: 200px; background: xurl(http://www.google.com) no-repeat left center; height: 10px;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/google/)
    expect(res).to match(/width/)
    expect(res).to match(/height/)

    str = "<div style=\"width: 200px; background:(http://www.yahoo.com); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/yahoo/)
    expect(res).to match(/height/)
    expect(res).to match(/width/)

    str = "<div style=\"width: 200px; background:expression(); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/\(/)
    expect(res).to match(/height/)
    expect(res).to match(/width/)
  end
  
  it "should allow negative values" do
    str = "<div style='margin: -18px;height: 10px;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to match(/margin/)
    expect(res).to match(/height/)
  end

  it "should remove non-whitelisted css attributes" do
    str = "<div style='bacon: 5px; border-left-color: #fff;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to match(/border-left-color/)
    expect(res).not_to match(/bacon/)
  end

  it "should allow valid css methods with valid css protocols" do
    str = %{<div style="width: 200px; background: url(http://www.google.com) no-repeat left center; height: 10px;"></div>}
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end
  
  it "should allow font tags with valid attributes" do
    str = %{<font face="Comic Sans MS" color="blue" size="3" bacon="yes">hello</font>}
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq %{<font face="Comic Sans MS" color="blue" size="3">hello</font>}
  end

  it "should remove and not escape contents of style tags" do
    str = %{<p><style type="text/css">pleaseignoreme: blahblahblah</style>but not me</p>}
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq "<p>but not me</p>"
  end

  it "should not be extremely slow with long, weird microsoft styles" do
    str = %{<span lang="EN" style="font-family: 'Times New Roman','serif'; color: #17375e; font-size: 12pt; mso-fareast-font-family: 'Times New Roman'; mso-themecolor: text2; mso-themeshade: 191; mso-style-textfill-fill-color: #17375E; mso-style-textfill-fill-themecolor: text2; mso-style-textfill-fill-alpha: 100.0%; mso-ansi-language: EN; mso-style-textfill-fill-colortransforms: lumm=75000"><p></p></span>}
    # the above string took over a minute to sanitize as of 8ae4ba8e
    Timeout.timeout(1) { Sanitize.clean(str, CanvasSanitize::SANITIZE) }
  end

  Dir.glob(Rails.root.join('spec', 'fixtures', 'xss', '*.xss')) do |filename|
    name = File.split(filename).last
    it "should sanitize xss attempts for #{name}" do
      f = File.open(filename)
      check = f.readline.strip
      str = f.read
      res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
      expect(res.downcase).not_to match(Regexp.new(check.downcase))
    end
  end
end
