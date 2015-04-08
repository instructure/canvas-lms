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

require 'nokogiri'

describe UserContent do
  describe "find_user_content" do
    it "should not yield non-string width/height fields" do
      doc = Nokogiri::HTML::DocumentFragment.parse('<object width="100%" />')
      UserContent.find_user_content(doc) do |node, uc|
        expect(uc.width).to eq '100%'
      end
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
      course
      att1 = attachment_model(context: @course)
      att2 = attachment_model(context: @course)
      att2.update_attribute(:locked, true)
      rewriter = UserContent::HtmlRewriter.new(@course, nil)
      expect(rewriter.user_can_view_content?(att1)).to be_truthy
      expect(rewriter.user_can_view_content?(att2)).to be_falsey
    end
  end
end
