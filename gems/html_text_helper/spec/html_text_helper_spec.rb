# encoding: UTF-8
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

require 'spec_helper'

describe HtmlTextHelper do

  class TestClassForMixins
    extend HtmlTextHelper
  end

  def th
    TestClassForMixins
  end

  context "format_message" do
    it "should detect and linkify URLs" do
      str = th.format_message("click here: (http://www.instructure.com) to check things out\nnewline").first
      html = Nokogiri::HTML::DocumentFragment.parse(str)
      link = html.css('a').first
      link['href'].should == "http://www.instructure.com"

      str = th.format_message("click here: http://www.instructure.com\nnewline").first
      html = Nokogiri::HTML::DocumentFragment.parse(str)
      link = html.css('a').first
      link['href'].should == "http://www.instructure.com"

      str = th.format_message("click here: www.instructure.com/a/b?a=1&b=2\nnewline").first
      html = Nokogiri::HTML::DocumentFragment.parse(str)
      link = html.css('a').first
      link['href'].should == "http://www.instructure.com/a/b?a=1&b=2"

      str = th.format_message("click here: http://www.instructure.com/\nnewline").first
      html = Nokogiri::HTML::DocumentFragment.parse(str)
      link = html.css('a').first
      link['href'].should == "http://www.instructure.com/"

      str = th.format_message("click here: http://www.instructure.com/courses/1/wiki/informação").first
      html = Nokogiri::HTML::DocumentFragment.parse(str)
      link = html.css('a').first
      link['href'].should == "http://www.instructure.com/courses/1/wiki/informa%C3%A7%C3%A3o"

      str = th.format_message("click here: http://www.instructure.com/'onclick=alert(document.cookie)//\nnewline").first
      html = Nokogiri::HTML::DocumentFragment.parse(str)
      link = html.css('a').first
      link['href'].should == "http://www.instructure.com/%27onclick=alert(document.cookie)//"

      # > ~15 chars in parens used to blow up the parser to take forever
      str = th.format_message("click here: http://www.instructure.com/(012345678901234567890123456789012345678901234567890)").first
      html = Nokogiri::HTML::DocumentFragment.parse(str)
      link = html.css('a').first
      link['href'].should == "http://www.instructure.com/(012345678901234567890123456789012345678901234567890)"
    end

    it "should handle having the placeholder in the text body" do
      str = th.format_message("this text has the placeholder #{HtmlTextHelper::AUTO_LINKIFY_PLACEHOLDER} embedded right in it.\nhttp://www.instructure.com/\n").first
      str.should == "this text has the placeholder #{HtmlTextHelper::AUTO_LINKIFY_PLACEHOLDER} embedded right in it.<br/>\r\n<a href='http://www.instructure.com/'>http://www.instructure.com/</a><br/>\r"
    end
  end

  context ".html_to_text" do
    it "should format links in markdown-like style" do
      th.html_to_text("<a href='www.example.com'>Link</a>").should == "[Link](www.example.com)"
      th.html_to_text("<a href='www.example.com'>www.example.com</a>").should == "www.example.com"
    end

    it "should not format href-less links" do
      th.html_to_text("<a>Link</a>").should == "Link"
    end

    it "should turn images into urls" do
      th.html_to_text("<img src='http://www.example.com/a'>").should == "http://www.example.com/a"
    end

    it "should turn images with alt text into markdown style links" do
      th.html_to_text('<img alt="an image" src="/image.png"').should == "[an image](/image.png)"
    end

    it "should not format src-less images" do
      th.html_to_text('<img alt="an image">').should == ''
    end

    it "should add base urls to links" do
      th.html_to_text('<a href="/link">Link</a>', base_url: "http://example.com").should == "[Link](http://example.com/link)"
      th.html_to_text('<a href="http://example.org/link">Link</a>', base_url: "http://example.com").should == "[Link](http://example.org/link)"
    end

    it "should add base urls to img src" do
      th.html_to_text('<img src="/image.png" alt="Image" />', base_url: "http://example.com").should == "[Image](http://example.com/image.png)"
      th.html_to_text('<img src="http://example.org/image.png" />', base_url: "http://example.com").should == "http://example.org/image.png"
    end

    it "should not format src-less images even with base urls" do
      th.html_to_text('<img alt="an image">', base_url: "http://example.com").should == ''
    end

    it "should format list elements" do
      th.html_to_text("<li>Item 1</li><li>Item 2</li>\n<li>Item 3</li> <li>Item 4\n<li>  Item 5").should == <<EOS.strip
* Item 1

* Item 2

* Item 3

* Item 4

* Item 5
EOS
    end

    it "should format headings" do
      th.html_to_text("<h1>heading 1</h1><h2>heading two<br>text\n</h2>\n<h3>heading 3 <br> through heading 6</h3>").should == <<EOS.strip
*********
heading 1
*********

-----------
heading two
text
-----------

heading 3
through heading 6
-----------------
EOS
    end

    it "should format headings in a word wrap friendly way" do
      th.html_to_text("<h1>heading 1</h1><h2>heading two<br>text\n</h2>\n<h3>heading 3 through heading 6</h3>", line_width: 9).should == <<EOS.strip
*********
heading 1
*********

---------
heading
two
text
---------

heading 3
through
heading 6
---------
EOS
    end

    it "should word wrap" do
      th.html_to_text("text that is a bit too long", line_width: 10).should == <<EOS.strip
text that
is a bit
too long
EOS
    end

    it "should squeeze whitespace" do
      th.html_to_text("too     many\n\n\nspaces   ").should == "too many spaces"
    end

    it "should strip link and script tags" do
      th.html_to_text('<script>script script script</script>text<link rel="stuff">').should == "text"
    end

    it "should strip other tags but leave their text" do
      th.html_to_text("text<span>span text</span>").should == "textspan text"
    end

    it "should replace html entities" do
      th.html_to_text("&&amp; >&lt;&nbsp;").should == "&& ><\302\240"
    end

    it "should add newlines around block elements" do
      th.html_to_text("text<div>div text</div>").should == "text\n\ndiv text"
    end

    it "should preserve whitespace in pre tags (until squeezing)" do
      th.html_to_text("<pre>i have\nactual\n\nnewlines\n\n\n!</pre>").should == "i have\nactual\n\nnewlines\n\n!"
    end

    it "should insert newlines for ps and brs" do
      th.html_to_text("Ohai<br>Text <p>paragraph of text.</p>End").should == "Ohai\nText\n\nparagraph of text.\n\nEnd"
    end

    it "should return a string with no html back unchanged" do
      th.html_to_text('String without HTML').should == 'String without HTML'
    end

    it "should return an empty string if passed a nil value" do
      th.html_to_text(nil).should == ''
    end
  end

  describe "simplify html" do
    before(:each) do
      @body = <<-END.strip
<p><strong>This is a bold tag</strong></p>
<p><em>This is an em tag</em></p>
<h1>This is an h1 tag</h1>
<h2>This is an h2 tag</h2>
<h3>This is an h3 tag</h3>
<h4>This is an h4 tag</h4>
<h5>This is an h5 tag</h5>
<h6>This is an h6 tag</h6>
<p><a href="http://foo.com">Link to Foo</a></p>
<p><img src="http://google.com/someimage.png" width="50" height="50" alt="Some Image" title="Some Image" /></p>
      END
    end

    it "should convert simple tags to minimal html" do
      html = th.html_to_simple_html(@body).gsub("\r\n", "\n")
      html.should_not match(/<h[1-6]|img/)
    end

    it "should convert relative links to absolute links" do
      original_html = %q{ <a href="/relative/link">Relative link</a> }
      html          = th.html_to_simple_html(original_html, base_url: 'http://example.com')

      html.should match(%r{http://example.com/relative/link})
    end
  end

  context "#strip_and_truncate" do
    it "should strip and truncate text" do
      HtmlTextHelper.stub(:strip_tags){"something else"}
      CanvasTextHelper.stub(:truncate_text){true}
      HtmlTextHelper.strip_and_truncate("some text").should be_true
      expect(HtmlTextHelper).to have_received(:strip_tags).with('some text')
      expect(CanvasTextHelper).to have_received(:truncate_text).with('something else', {})
    end
  end
end
