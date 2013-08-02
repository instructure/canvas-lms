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

describe Wiki do
  before :each do
    course
    @wiki = @course.wiki
  end

  context "get_front_page_url" do
    it "should return default url if front_page_url is not set" do
      @wiki.get_front_page_url.should == Wiki::DEFAULT_FRONT_PAGE_URL # 'front-page'
    end
  end

  context "unset_front_page!" do
    it "should unset front page" do
      @wiki.unset_front_page!

      @wiki.front_page_url.should == nil
      @wiki.front_page.should == nil
      @wiki.has_front_page?.should == false
    end
  end

  context "set_front_page_url!" do
    it "should set front_page_url" do
      @wiki.unset_front_page!

      new_url = "ponies4ever"
      @wiki.set_front_page_url!(new_url).should == true
      @wiki.has_front_page?.should == true
      @wiki.front_page_url.should == new_url
    end
  end

  context "front_page" do
    it "should build a default page if not found" do
      @wiki.wiki_pages.count.should == 0

      page = @wiki.front_page
      page.new_record?.should == true
      page.url.should == @wiki.get_front_page_url
    end

    it "should build a custom front page if not found" do
      new_url = "whyyyyy"
      @wiki.set_front_page_url!(new_url)

      page = @wiki.front_page
      page.new_record?.should == true
      page.url.should == new_url
    end

    it "should find front_page by url" do
      page = @wiki.wiki_pages.create!(:title => "stuff and stuff")

      @wiki.set_front_page_url!(page.url)
      page.should == @wiki.front_page
    end
  end
end
