# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

require "spec_helper"
require "timeout"

describe CanvasSanitize do
  describe "#clean" do
    subject { Sanitize.clean(html_string, CanvasSanitize::SANITIZE) }

    context "when the HTML string contains anchor tags" do
      context "and the href uses the 'tel' protocol" do
        let(:html_string) { '<a href="tel:+14123815500">Call Number</a>' }

        it { is_expected.to eq html_string }
      end

      context "and the href uses the 'skype' protocol" do
        let(:html_string) { '<a href="skype:inst-support?call">Call Support</a>' }

        it { is_expected.to eq html_string }
      end
    end
  end

  it "shouldnt strip lang attributes by default" do
    cleaned = Sanitize.clean("<p lang='es'>Hola</p>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<p lang=\"es\">Hola</p>")
  end

  it "doesnt strip dir attributes by default" do
    cleaned = Sanitize.clean("<p dir='rtl'>RightToLeft</p>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<p dir=\"rtl\">RightToLeft</p>")
  end

  it "doesnt strip data-* attributes by default" do
    cleaned = Sanitize.clean("<p data-item-id='1234'>Item1234</p>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<p data-item-id=\"1234\">Item1234</p>")
  end

  it "does strip the specific data-method attribute" do
    input_html = "<a data-method='post'>Data-Method Attr</a>"
    expected_html = "<a>Data-Method Attr</a>"
    cleaned = Sanitize.clean(input_html, CanvasSanitize::SANITIZE)
    expect(cleaned).to eq(expected_html)
  end

  it "does not strip track elements" do
    cleaned = Sanitize.clean("<track src=\"http://google.com\"></track>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<track src=\"http://google.com\">")
  end

  it "sanitizes javascript protocol in mathml" do
    cleaned = Sanitize.clean("<math href=\"javascript:alert(1)\">CLICKME</math>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<math>CLICKME</math>")
  end

  it "allows abbr elements" do
    cleaned = Sanitize.clean("<abbr title=\"Internationalization\">I18N</abbr>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<abbr title=\"Internationalization\">I18N</abbr>")
  end

  it "sanitizes javascript protocol in data-url" do
    cleaned = Sanitize.clean("<a data-url=\"javascript:alert('bad')\">Link</a>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<a>Link</a>")
  end

  it "sanitizes javascript protocol in data-item-href" do
    cleaned = Sanitize.clean("<a data-item-href=\"javascript:alert('bad')\">Link</a>", CanvasSanitize::SANITIZE)
    expect(cleaned).to eq("<a>Link</a>")
  end

  it "sanitizes style attributes width invalid url protocols" do
    str = "<div style='width: 200px; background: url(httpx://www.google.com) no-repeat left center; height: 10px;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/google/)
    expect(res).to match(/width/)
    expect(res).to match(/height/)
  end

  it "handles some tricky urls" do
    str = "<div style=\"width: 200px; background:url('java\nscript:alert(1)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/alert/)
    expect(res).not_to match(/height/)
    expect(res).to match(/width/)

    str = "<div style=\"width: 200px; background:url('javascript\n:alert(1)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/alert/)
    expect(res).not_to match(/height/)
    expect(res).to match(/width/)

    str = "<div style=\"width: 200px; background:url('&#106;avascript:alert(5)'); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/alert/)
    expect(res).to match(/height/)
    expect(res).to match(/width/)
  end

  it "sanitizes style attributes with invalid methods" do
    str = "<div style=\"width: 200px; background:expression(); height: 10px;\"></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/background/)
    expect(res).not_to match(/\(/)
    expect(res).to match(/height/)
    expect(res).to match(/width/)
  end

  it "allows negative values" do
    str = "<div style='margin: -18px;height: 10px;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to match(/margin/)
    expect(res).to match(/height/)
  end

  it "removes non-whitelisted css attributes" do
    str = "<div style='bacon: 5px; border-left-color: #fff;'></div>"
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to match(/border-left-color/)
    expect(res).not_to match(/bacon/)
  end

  it "allows valid css methods with valid css protocols" do
    str = %{<div style="width: 200px; background: url(http://www.google.com) no-repeat left center; height: 10px;"></div>}
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end

  it "allows font tags with valid attributes" do
    str = %(<font face="Comic Sans MS" color="blue" size="3" bacon="yes">hello</font>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq %(<font face="Comic Sans MS" color="blue" size="3">hello</font>)
  end

  it "allows valid MathML" do
    str = %(<math xmlns="http://www.w3.org/1998/Math/MathML"><mrow><mi>a</mi><mo>+</mo><mi>b</mi></mrow></math>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end

  it "strips invalid attributes from MathML" do
    str = %(<math xmlns="http://www.w3.org/1998/Math/MathML"><mrow><mi foo="bar">a</mi><mo>+</mo><mi>b</mi></mrow></math>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).not_to match(/foo/)
  end

  it "removes and not escape contents of style tags" do
    str = %(<p><style type="text/css">pleaseignoreme: blahblahblah</style>but not me</p>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq "<p>but not me</p>"
  end

  it "is not extremely slow with long, weird microsoft styles" do
    str = %(<span lang="EN" style="font-family: 'Times New Roman','serif'; color: #17375e; font-size: 12pt; mso-fareast-font-family: 'Times New Roman'; mso-themecolor: text2; mso-themeshade: 191; mso-style-textfill-fill-color: #17375E; mso-style-textfill-fill-themecolor: text2; mso-style-textfill-fill-alpha: 100.0%; mso-ansi-language: EN; mso-style-textfill-fill-colortransforms: lumm=75000"><p></p></span>)
    # the above string took over a minute to sanitize as of 8ae4ba8e
    Timeout.timeout(1) { Sanitize.clean(str, CanvasSanitize::SANITIZE) }
  end

  it "allows data sources for audio tags" do
    str = %(<audio controls="" src="data:audio/mp3;base64,aHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ=="></audio>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end

  it "allows data sources for video tags" do
    str = %(<video controls="" src="data:video/mp4;base64,aHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ=="></video>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end

  it "allows data sources for source tags" do
    str = %(<source type="audio/mp3" src="data:audio/mp3;base64,aHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==">)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end

  it "allows data sources for track tags" do
    str = %(<track kind="subtitles" srclang="en" label="English" src="data:audio/mp3;base64,aHR0cHM6Ly93d3cueW91dHViZS5jb20vd2F0Y2g/dj1kUXc0dzlXZ1hjUQ==">)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end

  it "strips spaces from ids" do
    str = %(<div class="mini_month"><div class="day_wrapper" id="mini_day_2023_10_31_1"><div class="mini_calendar_day" id="mini_day_2023_10_31_1, id=[<img src=x onerror='alert(`${document.domain}:${document.cookie}`)' />]">Click me to trigger XSS</div></div></div>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq(%(<div class="mini_month"><div class="day_wrapper" id="mini_day_2023_10_31_1"><div class="mini_calendar_day" id="mini_day_2023_10_31_1,id=[<imgsrc=xonerror='alert(`${document.domain}:${document.cookie}`)'/>]">Click me to trigger XSS</div></div></div>))
  end

  it "strips tabs and long whitespace from ids" do
    str = %(<div id="my id    with      tabs    and  spaces"></div>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq %(<div id="myidwithtabsandspaces"></div>)
  end

  it "does not affect ids without whitespace" do
    str = %(<div id="my-id-5"></div>)
    res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
    expect(res).to eq str
  end

  Dir.glob(File.expand_path(File.join(__FILE__, "..", "..", "fixtures", "xss", "*.xss"))) do |filename|
    name = File.split(filename).last
    it "sanitizes xss attempts for #{name}" do
      f = File.open(filename)
      check = f.readline.strip
      str = f.read
      res = Sanitize.clean(str, CanvasSanitize::SANITIZE)
      expect(res.downcase).not_to match(Regexp.new(check.downcase))
    end
  end
end
