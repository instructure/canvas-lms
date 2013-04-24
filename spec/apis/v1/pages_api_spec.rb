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

require File.expand_path(File.dirname(__FILE__) + '/../api_spec_helper')

describe "Pages API", :type => :integration do
  before do
    course
    @course.offer!
    @wiki = @course.wiki
    @front_page = @wiki.wiki_page
    @front_page.workflow_state = 'active'
    @front_page.save!
    @hidden_page = @wiki.wiki_pages.create!(:title => "Hidden Page", :hide_from_students => true, :body => "Body of hidden page")
  end

  context "as a teacher" do
    before :each do
      course_with_teacher(:course => @course, :active_all => true)
    end

    it "should list pages, including hidden ones" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}")
      json.should == [{"hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.updated_at.as_json, "title" => @front_page.title},
                      {"hide_from_students" => true, "url" => @hidden_page.url, "created_at" => @hidden_page.created_at.as_json, "updated_at" => @hidden_page.updated_at.as_json, "title" => @hidden_page.title}]
    end

    it "should paginate" do
      2.times { |i| @wiki.wiki_pages.create!(:title => "New Page #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?per_page=2",
                      :controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}", :per_page=>"2")
      json.size.should == 2
      urls = json.collect{ |page| page['url'] }
      
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?page=2&per_page=2",
                      :controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}", :page => "2", :per_page=>"2")
      json.size.should == 2
      urls += json.collect{ |page| page['url'] }
      
      urls.should == @wiki.wiki_pages.sort_by(&:id).collect(&:url)
    end
    
    it "should retrieve page content" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                      :controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{@course.id}", :url=>@hidden_page.url)
      json.should == { "hide_from_students" => true,
                       "url" => @hidden_page.url,
                       "created_at" => @hidden_page.created_at.as_json,
                       "updated_at" => @hidden_page.updated_at.as_json,
                       "title" => @hidden_page.title,
                       "body" => @hidden_page.body }
    end
    
    it "should update view count" do
      views = @front_page.view_count
      api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}",
               :controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{@course.id}", :url=>@front_page.url)
      @front_page.reload
      @front_page.view_count.should == views + 1
    end
    
    it "should return not-found on a nonexistent page" do
      api_call(:get, "/api/v1/courses/#{@course.id}/pages/nonexistent",
               { :controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{@course.id}", :url=>'nonexistent' },
               {}, {}, { :expected_status => 404 })
    end

    context "unpublished pages" do
      before do
        @unpublished_page = @wiki.wiki_pages.create(:title => "Draft Page", :body => "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "should be in index" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}")
        json.select{|w|w[:title] == @unpublished_page.title}.should_not be_nil
      end
      it "should show" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                      :controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{@course.id}", :url=>@unpublished_page.url)
        json['title'].should == @unpublished_page.title
      end
    end
  end

  context "as a student" do
    before :each do
      course_with_student(:course => @course, :active_all => true)
    end
    
    it "should list pages, excluding hidden ones" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}")
      json.should == [{"hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.updated_at.as_json, "title" => @front_page.title}]
    end

    it "should paginate, excluding hidden" do
      11.times { |i| @wiki.wiki_pages.create!(:title => "New Page #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}")
      json.size.should == 10
      urls = json.collect{ |page| page['url'] }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?page=2",
                      :controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}", :page => "2")
      json.size.should == 2
      urls += json.collect{ |page| page['url'] }

      urls.should == @wiki.wiki_pages.select{ |p| !p.hide_from_students }.sort_by(&:id).collect(&:url)      
    end
    
    it "should refuse to show a hidden page" do
      api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
               {:controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{@course.id}", :url=>@hidden_page.url},
               {}, {}, { :expected_status => 401 })      
    end

    it "should refuse to list pages in an unpublished course" do
      @course.workflow_state = 'created'
      @course.save!
      api_call(:get, "/api/v1/courses/#{@course.id}/pages",
               {:controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}"},
               {}, {}, { :expected_status => 401 })
    end

    it "should deny access to wiki in an unenrolled course" do
      other_course = course
      other_course.offer!
      other_wiki = other_course.wiki
      other_page = other_wiki.wiki_page
      other_page.workflow_state = 'active'
      other_page.save!
      
      api_call(:get, "/api/v1/courses/#{other_course.id}/pages",
               {:controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{other_course.id}"},
               {}, {}, { :expected_status => 401 })
      
      api_call(:get, "/api/v1/courses/#{other_course.id}/pages/front-page",
               {:controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{other_course.id}", :url=>'front-page'},
               {}, {}, { :expected_status => 401 })
    end
    
    it "should allow access to a wiki in a public unenrolled course" do
      other_course = course
      other_course.is_public = true
      other_course.offer!
      other_wiki = other_course.wiki
      other_page = other_wiki.wiki_page
      other_page.workflow_state = 'active'
      other_page.save!

      api_call(:get, "/api/v1/courses/#{other_course.id}/pages",
               {:controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{other_course.id}"})
      
      api_call(:get, "/api/v1/courses/#{other_course.id}/pages/front-page",
               {:controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{other_course.id}", :url=>'front-page'})
    end
    
    it "should fulfill module progression requirements" do
      mod = @course.context_modules.create!(:name => "some module")
      tag = mod.add_item(:id => @front_page.id, :type => 'wiki_page')
      mod.completion_requirements = { tag.id => {:type => 'must_view'} }
      mod.save!

      # index should not affect anything
      api_call(:get, "/api/v1/courses/#{@course.id}/pages",
               {:controller=>"wiki_pages", :action=>"api_index", :format=>"json", :course_id=>"#{@course.id}"})
      mod.evaluate_for(@user).workflow_state.should == "unlocked"

      # show should count as a view
      api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}",
               {:controller=>"wiki_pages", :action=>"api_show", :format=>"json", :course_id=>"#{@course.id}", :url=>@front_page.url})
      mod.evaluate_for(@user).workflow_state.should == "completed"     
    end

    context "unpublished pages" do
      before do
        @unpublished_page = @wiki.wiki_pages.create(:title => "Draft Page", :body => "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "should not be in index" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                        :controller => "wiki_pages", :action => "api_index", :format => "json", :course_id => "#{@course.id}")
        json.select { |w| w[:title] == @unpublished_page.title }.should == []
      end

      it "should not show" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                        {:controller => "wiki_pages", :action => "api_show", :format => "json", :course_id => "#{@course.id}", :url => @unpublished_page.url},
                        {}, {}, {:expected_status => 401})
      end

      it "should not show unpublished on public courses" do
        @course.is_public = true
        @course.save!
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                        {:controller => "wiki_pages", :action => "api_show", :format => "json", :course_id => "#{@course.id}", :url => @unpublished_page.url},
                        {}, {}, {:expected_status => 401})
      end
    end
  end
  
  context "group" do
    before :each do
      group_with_user(:active_all => true)
      5.times { |i| @group.wiki.wiki_pages.create!(:title => "Group Wiki Page #{i}", :body => "<blink>Content of page #{i}</blink>") }
    end
    
    it "should list the contents of a group wiki" do
      json = api_call(:get, "/api/v1/groups/#{@group.id}/pages",
                     {:controller=>"wiki_pages", :action=>"api_index", :format=>"json", :group_id=>"#{@group.id}"})
      json.collect { |row| row['title'] }.should == @group.wiki.wiki_pages.active.order_by_id.collect(&:title)      
    end
    
    it "should retrieve page content from a group wiki" do
      testpage = @group.wiki.wiki_pages.last
      json = api_call(:get, "/api/v1/groups/#{@group.id}/pages/#{testpage.url}",
                      {:controller=>"wiki_pages", :action=>"api_show", :format=>"json", :group_id=>"#{@group.id}", :url=>testpage.url})
      json['body'].should == testpage.body
    end
  end
end
