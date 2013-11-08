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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe WikiPagesController do
  before do
    course_with_teacher_logged_in(:active_all => true)
  end

  it "should not render wiki page body at all if it was deleted" do
    @wiki_page = @course.wiki.wiki_pages.create :title => "Some random wiki page",
                                                :body => "this is the content of the wikipage body asdfasdf"
    @wiki_page.destroy
    get course_wiki_page_url(@course, @wiki_page)
    response.body.should_not have_text @wiki_page.body
  end

  it "should link correctly in the breadcrumbs for group wikis" do
    course_with_teacher_logged_in(:active_all => true, :user => user_with_pseudonym)
    group_category = @course.group_categories.build(:name => "mygroup")
    @group = Group.create!(:name => "group1", :group_category => group_category, :context => @course)
    @wiki_page = @group.wiki.wiki_pages.create :title => 'hello', :body => 'This is a wiki page.'

    def test_page(url)
      get url
      response.should be_success

      html = Nokogiri::HTML(response.body)
      html.css('#breadcrumbs a').each do |link|
        href = link.attr('href')
        next if href == "/"
        href.should =~ %r{^/groups/#{@group.id}}
      end
    end

    test_page("/groups/#{@group.id}/wiki/hello")
    test_page("/groups/#{@group.id}/wiki/hello/revisions")
  end

  it "should permit the student to view the page history if they have permissions" do
    @wiki_page = @course.wiki.wiki_pages.create :title => "Some random wiki page",
                                                :body => "this is the content of the wikipage body asdfasdf",
                                                :editing_roles => "teachers,students",
                                                :hide_from_students => false
    student = user()
    enrollment = @course.enroll_student(student)
    enrollment.accept!
    @course.reload
    user_session(student)
    get course_wiki_page_url(@course, @wiki_page)
    html = Nokogiri::HTML(response.body)
    html.css("#page_history").should_not be_empty

    @wiki_page.editing_roles = "teachers"
    @wiki_page.save
    get course_wiki_page_url(@course, @wiki_page)
    html = Nokogiri::HTML(response.body)
    html.css("#page_history").should be_empty
  end

  it "should cache the user_content call on the wiki_page body and clear on wiki_page update" do
    enable_cache do
      course_with_teacher_logged_in(:active_all => true)
      @wiki_page = @course.wiki.wiki_pages.create :title => 'hello', :body => 'This is a wiki page.'

      get course_wiki_page_url(@course, @wiki_page)

      data = Rails.cache.read("views/#{["wiki_page_body_render", @wiki_page].cache_key}/en")
      data.should_not be_nil

      new_body = "all aboard the lollertrain woo woo"
      @wiki_page.body = new_body
      @wiki_page.save!

      get course_wiki_page_url(@course, @wiki_page)
      response.body.should include(new_body)
    end
  end

  context "draft state forwarding" do
    before do
      @front = @course.wiki.front_page
      @wiki_page = @course.wiki.wiki_pages.create :title => "a-page", :body => "body"
      @base_url = "/courses/#{@course.id}/"
      @course.reload
    end

    context "draft state enabled" do
      before do
        root = @course.root_account
        root.settings[:enable_draft] = true
        root.save!
        @course.reload
      end

      it "should forward /wiki to /pages index if no front page" do
        @course.wiki.has_no_front_page = true
        @course.wiki.save!
        get @base_url + "wiki"
        response.code.should == '302'
        response.redirected_to.should =~ %r{/pages\z}
      end

      it "should forward /wiki to /pages/front-page" do
        @front.set_as_front_page!
        get @base_url + "wiki"
        response.code.should == '302'
        response.redirected_to.should =~ %r{/pages/front-page\z}
      end

      it "should forward /wiki/name to /pages/name" do
        get @base_url + "wiki/a-page"
        response.code.should == '302'
        response.redirected_to.should =~ %r{/pages/a-page\z}
      end
    end

    context "draft state disabled" do
      it "should forward /pages to /wiki" do
        get @base_url + "pages"
        response.code.should == '302'
        response.redirected_to.should =~ %r{/wiki\z}
      end

      it "should forward /pages/name to /wiki/name" do
        get @base_url + "pages/a-page"
        response.code.should == '302'
        response.redirected_to.should =~ %r{/wiki/a-page\z}
      end

      it "should forward /pages/name/edit to /wiki/name#edit" do
        get @base_url + "pages/a-page/edit"
        response.code.should == '302'
        response.redirected_to.should =~ %r{/wiki/a-page#edit\z}
      end
    end

  end

end

