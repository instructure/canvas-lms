#
# Copyright (C) 2012 - present Instructure, Inc.
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

require 'nokogiri'

describe UserContent do
  describe ".find_user_content" do
    it "should not yield non-string width/height fields" do
      doc = Nokogiri::HTML::DocumentFragment.parse('<object width="100%" />')
      UserContent.find_user_content(doc) do |_, uc|
        expect(uc.width).to eq '100%'
      end
    end
  end

  describe ".find_equation_images" do
    it "yields each equation image one at a time" do
      html = "<div><ul><li><img class='equation_image'/></li>"\
             "<li><img class='equation_image'/></li>"\
             "<li><img class='nothing_special'></li></ul></div>"
      parsed = Nokogiri::HTML::DocumentFragment.parse(html)
      yield_count = 0
      UserContent.find_equation_images(parsed) do
        yield_count += 1
      end
      expect(yield_count).to eq(2)
    end
  end

  describe "css_size" do
    it "should be nil for non-numbers" do
      expect(UserContent.css_size(nil)).to be_nil
      expect(UserContent.css_size('')).to be_nil
      expect(UserContent.css_size('non-number')).to be_nil
    end

    it "should be nil for numbers that equate to 0" do
      expect(UserContent.css_size('0%')).to be_nil
      expect(UserContent.css_size('0px')).to be_nil
      expect(UserContent.css_size('0')).to be_nil
    end

    it "should preserve percents" do
      expect(UserContent.css_size('100%')).to eq '100%'
    end

    it "should preserve px" do
      expect(UserContent.css_size('100px')).to eq '100px'
    end

    # TODO: these ones are questionable
    it "should add 10 to raw numbers and make them px" do
      expect(UserContent.css_size('100')).to eq '110px'
    end

    it "should be nil for numbers with an unrecognized prefix" do
      expect(UserContent.css_size('x-100')).to be_nil
    end

    it "should keep just the raw number from numbers with an unrecognized suffix" do
      expect(UserContent.css_size('100-x')).to eq '100'
    end
  end

  describe 'HtmlRewriter' do
    let(:rewriter) do
      course_with_teacher
      UserContent::HtmlRewriter.new(@course, @teacher)
    end

    it "handler should not convert id to integer for 'wiki' matches" do
      called = false
      rewriter.set_handler('wiki') do |match|
        called = true
        expect(match.obj_id.class).to eq String
      end
      rewriter.translate_content("<a href=\"/courses/#{rewriter.context.id}/wiki/1234-numbered-page\">test</a>")
      expect(called).to be_truthy
    end

    it "handler should not convert id to integer for 'pages' matches" do
      called = false
      rewriter.set_handler('pages') do |match|
        called = true
        expect(match.obj_id.class).to eq String
      end
      rewriter.translate_content("<a href=\"/courses/#{rewriter.context.id}/pages/1234-numbered-page\">test</a>")
      expect(called).to be_truthy
    end

    it "should not grant public access to locked files" do
      course_factory
      att1 = attachment_model(context: @course)
      att2 = attachment_model(context: @course)
      att2.update_attribute(:locked, true)
      rewriter = UserContent::HtmlRewriter.new(@course, nil)
      expect(rewriter.user_can_view_content?(att1)).to be_truthy
      expect(rewriter.user_can_view_content?(att2)).to be_falsey
    end

    describe "@toplevel_regex" do
      let(:regex) do
        rewriter.instance_variable_get(:@toplevel_regex)
      end

      it "matches relative paths" do
        expect(regex.match("<a href='/courses/#{rewriter.context.id}/assignments/5'>").to_a).to eq([
          "/courses/#{rewriter.context.id}/assignments/5",
          nil,
          "/courses/#{rewriter.context.id}",
          "assignments",
          "5",
          ""
        ])
      end

      it "matches relative paths with no content prefix" do
        expect(regex.match("<a href='/files/101/download?download_frd=1'>").to_a).to eq([
          "/files/101/download?download_frd=1",
          nil,
          nil,
          "files",
          "101",
          "/download?download_frd=1"
        ])
      end

      it "matches absolute paths with http" do
        expect(regex.match(%Q{<img src="http://localhost:3000/files/110/preview">}).to_a).to eq([
            "http://localhost:3000/files/110/preview",
            "http://localhost:3000",
            nil,
            "files",
            "110",
            "/preview"
          ])
      end

      it "matches absolute paths with https" do
        expect(regex.match(%Q{<a href="https://this-is-terrible.example.com/courses/#{rewriter.context.id}/pages/whatever?srsly=0">}).to_a).to eq([
            "https://this-is-terrible.example.com/courses/#{rewriter.context.id}/pages/whatever?srsly=0",
            "https://this-is-terrible.example.com",
            "/courses/#{rewriter.context.id}",
            "pages",
            "whatever",
            "?srsly=0"
          ])
      end

      it "doesn't match invalid hostnames" do
        expect(regex.match("https://thisisn'tvalid.com/files/3")[1]).to be_nil
      end
    end
  end

  describe ".latex_to_mathml" do
    it "translates valid latex string cleanly" do
      mathml = "<math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"inline\">"\
               "<mo lspace=\"thinmathspace\" rspace=\"thinmathspace\">&Sum;</mo>"\
               "<mn>1</mn><mo>.</mo><mo>.</mo><mi>n</mi></math>"
      expect(UserContent.latex_to_mathml('\sum 1..n')).to eq(mathml)
    end

    it "returns a blank string for invalid latex" do
      expect(UserContent.latex_to_mathml('1234!@#$!@#$!@#%@#%^^&!')).to eq("")
    end

    it "prefers not translating over bombing with invalid-but-understandable latex" do
      expect(UserContent.latex_to_mathml('\sum1..n')).to eq("")
    end
  end

  describe ".escape" do
    it "stuffs mathml into a data attribute on equation images" do
      string = "<div><ul><li><img class='equation_image' data-equation-content='\int f(x)/g(x)'/></li>"\
             "<li><img class='equation_image' data-equation-content='\\sum 1..n'/></li>"\
             "<li><img class='nothing_special'></li></ul></div>"
      html = UserContent.escape(string)
      expected = "<div><ul>\n"\
        "<li>\n"\
        "<img class=\"equation_image\" data-equation-content=\"int f(x)/g(x)\"><span class=\"hidden-readable\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"inline\"><mi>i</mi><mi>n</mi><mi>t</mi><mi>f</mi><mo stretchy=\"false\">(</mo><mi>x</mi><mo stretchy=\"false\">)</mo><mo>/</mo><mi>g</mi><mo stretchy=\"false\">(</mo><mi>x</mi><mo stretchy=\"false\">)</mo></math></span>\n"\
        "</li>\n"\
        "<li>\n"\
        "<img class=\"equation_image\" data-equation-content=\"\\sum 1..n\"><span class=\"hidden-readable\"><math xmlns=\"http://www.w3.org/1998/Math/MathML\" display=\"inline\"><mo lspace=\"thinmathspace\" rspace=\"thinmathspace\">&amp;Sum;</mo><mn>1</mn><mo>.</mo><mo>.</mo><mi>n</mi></math></span>\n"\
        "</li>\n"\
        "<li><img class=\"nothing_special\"></li>\n"\
        "</ul></div>"
      expect(html).to eq(expected)
    end
  end
end
