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
require File.expand_path(File.dirname(__FILE__) + '/../locked_spec')

describe "Pages API", type: :request do
  include Api::V1::User
  def avatar_url_for_user(user, *a)
    User.avatar_fallback_url
  end
  def blank_fallback
    nil
  end

  context 'locked api item' do
    let(:item_type) { 'page' }

    let(:locked_item) do
      wiki = @course.wiki
      front_page = wiki.front_page
      front_page.workflow_state = 'active'
      front_page.save!
      front_page
    end

    def api_get_json
      api_call(
        :get,
        "/api/v1/courses/#{@course.id}/pages/#{locked_item.url}",
        {:controller=>'wiki_pages_api', :action=>'show', :format=>'json', :course_id=>"#{@course.id}", :url=>locked_item.url},
      )
    end

    include_examples 'a locked api item'
  end

  before :once do
    course
    @course.offer!
    @wiki = @course.wiki
    @front_page = @wiki.front_page
    @front_page.workflow_state = 'active'
    @front_page.save!
    @front_page.set_as_front_page!
    @hidden_page = @wiki.wiki_pages.create!(:title => "Hidden Page", :body => "Body of hidden page")
    @hidden_page.unpublish!
  end

  context 'versions' do
    before :once do
      @page = @wiki.wiki_pages.create!(:title => 'Test Page', :body => 'Test content')
    end

    example 'creates initial version of the page' do
      @page.versions.count.should == 1
      version = @page.current_version.model
      version.title.should == 'Test Page'
      version.body.should == 'Test content'
    end

    example 'creates a version when the title changes' do
      @page.title = 'New Title'
      @page.save!
      @page.versions.count.should == 2
      version = @page.current_version.model
      version.title.should == 'New Title'
      version.body.should == 'Test content'
    end

    example 'creates a verison when the body changes' do
      @page.body = 'New content'
      @page.save!
      @page.versions.count.should == 2
      version = @page.current_version.model
      version.title.should == 'Test Page'
      version.body.should == 'New content'
    end

    example 'does not create a version when workflow_state changes' do
      @page.workflow_state = 'active'
      @page.save!
      @page.versions.count.should == 1
    end

    example 'does not create a version when editing_roles changes' do
      @page.editing_roles = 'teachers,students,public'
      @page.save!
      @page.versions.count.should == 1
    end

    example 'does not create a version when notify_of_update changes' do
      @page.notify_of_update = true
      @page.save!
      @page.versions.count.should == 1
    end

    example 'does not create a version when just the user_id changes' do
      user1 = user(:active_all => true)
      @page.user_id = user1.id
      @page.title = 'New Title'
      @page.save!
      @page.versions.count.should == 2
      current_version = @page.current_version.model
      current_version.user_id.should == user1.id

      user2 = user(:active_all => true)
      @page.user_id = user2.id
      @page.save!
      @page.versions.count.should == 2
    end
  end

  context "as a teacher" do
    before :once do
      course_with_teacher(:course => @course, :active_all => true)
    end

    describe "index" do
      it "should list pages, including hidden ones" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                        :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param)
        json.map {|entry| entry.slice(*%w(hide_from_students url created_at updated_at title front_page))}.should ==
          [{"hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.updated_at.as_json, "title" => @front_page.title, "front_page" => true},
           {"hide_from_students" => true, "url" => @hidden_page.url, "created_at" => @hidden_page.created_at.as_json, "updated_at" => @hidden_page.updated_at.as_json, "title" => @hidden_page.title, "front_page" => false}]
      end
  
      it "should paginate" do
        2.times { |i| @wiki.wiki_pages.create!(:title => "New Page #{i}") }
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?per_page=2",
                        :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param, :per_page => "2")
        json.size.should == 2
        urls = json.collect{ |page| page['url'] }
        
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?per_page=2&page=2",
                        :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param, :per_page => "2", :page => "2")
        json.size.should == 2
        urls += json.collect{ |page| page['url'] }
        
        urls.should == @wiki.wiki_pages.sort_by(&:id).collect(&:url)
      end

      it "should search for pages by title" do
        new_pages = []
        3.times { |i| new_pages << @wiki.wiki_pages.create!(:title => "New Page #{i}") }

        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?search_term=new",
                        :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param, :search_term => "new")
        json.size.should == 3
        json.collect{ |page| page['url'] }.should == new_pages.sort_by(&:id).collect(&:url)

        # Should also paginate
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?search_term=New&per_page=2",
                        :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param, :search_term => "New", :per_page => "2")
        json.size.should == 2
        urls = json.collect{ |page| page['url'] }

        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?search_term=New&per_page=2&page=2",
                        :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param, :search_term => "New", :per_page => "2", :page => "2")
        json.size.should == 1
        urls += json.collect{ |page| page['url'] }

        urls.should == new_pages.sort_by(&:id).collect(&:url)
      end

      it "should return an error if the search term is fewer than 3 characters" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?search_term=aa",
                        {:controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param, :search_term => "aa"},
                        {}, {}, {:expected_status => 400})
        error = json["errors"].first
        verify_json_error(error, "search_term", "invalid", "3 or more characters is required")
      end

      describe "sorting" do
        it "should sort by title (case-insensitive)" do
          @wiki.wiki_pages.create! :title => 'gIntermediate Page'
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?sort=title",
                          :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param,
                          :sort=>'title')
          json.map {|page|page['title']}.should == ['Front Page', 'gIntermediate Page', 'Hidden Page']

          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?sort=title&order=desc",
                          :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param,
                          :sort=>'title', :order=>'desc')
          json.map {|page|page['title']}.should == ['Hidden Page', 'gIntermediate Page', 'Front Page']
        end
        
        it "should sort by created_at" do
          @hidden_page.update_attribute(:created_at, 1.hour.ago)
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?sort=created_at&order=asc",
                          :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param,
                          :sort=>'created_at', :order=>'asc')
          json.map {|page|page['url']}.should == [@hidden_page.url, @front_page.url]
        end
        
        it "should sort by updated_at" do
          Timecop.freeze(1.hour.ago) { @hidden_page.touch }
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?sort=updated_at&order=desc",
                          :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param,
                          :sort=>'updated_at', :order=>'desc')
          json.map {|page|page['url']}.should == [@front_page.url, @hidden_page.url]
        end
      end
    end
    
    describe "show" do
      before :once do
        @teacher.short_name = 'the teacher'
        @teacher.save!
        @hidden_page.user_id = @teacher.id
        @hidden_page.save!
      end
      
      it "should retrieve page content and attributes" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                        :controller=>"wiki_pages_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :url=>@hidden_page.url)
        expected = { "hide_from_students" => true,
                     "editing_roles" => "teachers",
                     "last_edited_by" => user_display_json(@teacher, @course).stringify_keys!,
                     "url" => @hidden_page.url,
                     "html_url" => "http://www.example.com/courses/#{@course.id}/wiki/#{@hidden_page.url}",
                     "created_at" => @hidden_page.created_at.as_json,
                     "updated_at" => @hidden_page.updated_at.as_json,
                     "title" => @hidden_page.title,
                     "body" => @hidden_page.body,
                     "published" => true,
                     "front_page" => false,
                     "locked_for_user" => false,
                     "page_id" => @hidden_page.id
        }
        json.should == expected
      end

      it "should retrieve front_page" do
        page = @course.wiki.wiki_pages.create!(:title => "hrup", :body => "blooop")
        page.set_as_front_page!

        json = api_call(:get, "/api/v1/courses/#{@course.id}/front_page",
                        :controller=>"wiki_pages_api", :action=>"show_front_page", :format=>"json", :course_id=>"#{@course.id}")

        expected = { "hide_from_students" => false,
                     "editing_roles" => "teachers",
                     "url" => page.url,
                     "html_url" => "http://www.example.com/courses/#{@course.id}/wiki/#{page.url}",
                     "created_at" => page.created_at.as_json,
                     "updated_at" => page.updated_at.as_json,
                     "title" => page.title,
                     "body" => page.body,
                     "published" => true,
                     "front_page" => true,
                     "locked_for_user" => false,
                     "page_id" => page.id
        }
        json.should == expected
      end

      it "should implicitly find the 'front-page' if no front page is set" do
        @wiki.reload
        @wiki.front_page_url = nil
        @wiki.has_no_front_page = nil
        @wiki.save!

        json = api_call(:get, "/api/v1/courses/#{@course.id}/front_page",
                        :controller=>"wiki_pages_api", :action=>"show_front_page", :format=>"json", :course_id=>"#{@course.id}")

        expected = { "hide_from_students" => false,
                     "editing_roles" => "teachers",
                     "url" => @front_page.url,
                     "html_url" => "http://www.example.com/courses/#{@course.id}/wiki/#{@front_page.url}",
                     "created_at" => @front_page.created_at.as_json,
                     "updated_at" => @front_page.updated_at.as_json,
                     "title" => @front_page.title,
                     "body" => @front_page.body,
                     "published" => true,
                     "front_page" => true,
                     "locked_for_user" => false,
                     "page_id" => @front_page.id
        }
        json.should == expected
      end

      it "should give a meaningful error if there is no front page" do
        @front_page.workflow_state = 'deleted'
        @front_page.save!
        wiki = @front_page.wiki
        wiki.unset_front_page!

        json = api_call(:get, "/api/v1/courses/#{@course.id}/front_page",
                        {:controller=>"wiki_pages_api", :action=>"show_front_page", :format=>"json", :course_id=>"#{@course.id}"},
                        {}, {}, {:expected_status => 404})

        json['message'].should == "No front page has been set"
      end
    end
    
    describe "revisions" do
      before :once do
        @timestamps = %w(2013-01-01 2013-01-02 2013-01-03).map { |d| Time.zone.parse(d) }
        course_with_ta :course => @course, :active_all => true
        Timecop.freeze(@timestamps[0]) do      # rev 1
          @vpage = @course.wiki.wiki_pages.build :title => 'version test page'
          @vpage.workflow_state = 'unpublished'
          @vpage.body = 'draft'
          @vpage.save!
        end

        Timecop.freeze(@timestamps[1]) do      # rev 2
          @vpage.workflow_state = 'active'
          @vpage.body = 'published by teacher'
          @vpage.user = @teacher
          @vpage.save!
        end

        Timecop.freeze(@timestamps[2]) do      # rev 3
          @vpage.body = 'revised by ta'
          @vpage.user = @ta
          @vpage.save!
        end
        @user = @teacher
      end

      it "should list revisions of a page" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions",
                        :controller=>"wiki_pages_api", :action=>"revisions", :format=>"json",
                        :course_id=>@course.to_param, :url=>@vpage.url)
        json.should == [
          {
            'revision_id' => 3,
            'latest' => true,
            'updated_at' => @timestamps[2].as_json,
            'edited_by' => user_display_json(@ta, @course).stringify_keys!,
          },
          {
            'revision_id' => 2,
            'latest' => false,
            'updated_at' => @timestamps[1].as_json,
            'edited_by' => user_display_json(@teacher, @course).stringify_keys!,
          },
          {
            'revision_id' => 1,
            'latest' => false,
            'updated_at' => @timestamps[0].as_json,
          }
        ]
      end

      it "should summarize the latest revision" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/latest?summary=true",
                        :controller => "wiki_pages_api", :action => "show_revision", :format => "json",
                        :course_id => @course.to_param, :url => @vpage.url, :summary => 'true')
        json.should == {
            'revision_id' => 3,
            'latest' => true,
            'updated_at' => @timestamps[2].as_json,
            'edited_by' => user_display_json(@ta, @course).stringify_keys!,
        }
      end

      it "should paginate the revision list" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions?per_page=2",
                        :controller=>"wiki_pages_api", :action=>"revisions", :format=>"json",
                        :course_id=>@course.to_param, :url=>@vpage.url, :per_page=>'2')
        json.size.should == 2
        json += api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions?per_page=2&page=2",
                         :controller=>"wiki_pages_api", :action=>"revisions", :format=>"json",
                         :course_id=>@course.to_param, :url=>@vpage.url, :per_page=>'2', :page=>'2')
        json.map { |r| r['revision_id'] }.should == [3, 2, 1]
      end

      it "should retrieve an old revision" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/1",
                        :controller=>"wiki_pages_api", :action=>"show_revision", :format=>"json", :course_id=>"#{@course.id}", :url=>@vpage.url, :revision_id=>'1')
        json.should == {
            'body' => 'draft',
            'title' => 'version test page',
            'url' => @vpage.url,
            'updated_at' => @timestamps[0].as_json,
            'revision_id' => 1,
            'latest' => false
        }
      end

      it "should retrieve the latest revision" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/latest",
                        :controller=>"wiki_pages_api", :action=>"show_revision", :format=>"json", :course_id=>"#{@course.id}", :url=>@vpage.url)
        json.should == {
            'body' => 'revised by ta',
            'title' => 'version test page',
            'url' => @vpage.url,
            'updated_at' => @timestamps[2].as_json,
            'revision_id' => 3,
            'latest' => true,
            'edited_by' => user_display_json(@ta, @course).stringify_keys!
        }
      end

      it "should revert to a prior revision" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                        :controller=>"wiki_pages_api", :action=>"revert", :format=>"json", :course_id=>@course.to_param,
                        :url=>@vpage.url, :revision_id=>'2')
        json['body'].should == 'published by teacher'
        json['revision_id'].should == 4
        @vpage.reload.body.should == 'published by teacher'
      end

      it "should revert page content only" do
        @vpage.workflow_state = 'unpublished'
        @vpage.title = 'booga!'
        @vpage.body = 'booga booga!'
        @vpage.editing_roles = 'teachers,students,public'
        @vpage.save! # rev 4
        api_call(:post, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                 :controller=>"wiki_pages_api", :action=>"revert", :format=>"json", :course_id=>@course.to_param,
                 :url=>@vpage.url, :revision_id=>'3')
        @vpage.reload
        @vpage.hide_from_students.should be_true
        @vpage.editing_roles.should == 'teachers,students,public'
        @vpage.title.should == 'version test page'  # <- reverted
        @vpage.body.should == 'revised by ta'       # <- reverted
        @vpage.user_id.should == @teacher.id        # the user who performed the revert (not the original author)
      end

      it "show should 404 when given a bad revision number" do
        api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/99",
                 { :controller=>"wiki_pages_api", :action=>"show_revision", :format=>"json", :course_id=>"#{@course.id}",
                   :url=>@vpage.url, :revision_id=>'99' }, {}, {}, { :expected_status => 404 })
      end

      it "revert should 404 when given a bad revision number" do
        api_call(:post, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/99",
                 { :controller=>"wiki_pages_api", :action=>"revert", :format=>"json", :course_id=>"#{@course.id}",
                   :url=>@vpage.url, :revision_id=>'99' }, {}, {}, { :expected_status => 404 })
      end
    end

    describe "create" do
      it "should require a title" do
        api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                 { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                 {}, {}, {:expected_status => 400})
      end
            
      it "should create a new page" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                        { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                        { :wiki_page => { :title => 'New Wiki Page!', :body => 'hello new page' }})
        page = @course.wiki.wiki_pages.find_by_url!(json['url'])
        page.title.should == 'New Wiki Page!'
        page.url.should == 'new-wiki-page'
        page.body.should == 'hello new page'
        page.user_id.should == @teacher.id
      end

      it 'should process body with process_incoming_html_content' do
        WikiPagesApiController.any_instance.stubs(:process_incoming_html_content).returns('processed content')

        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                 { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                 { :wiki_page => { :title => 'New Wiki Page', :body => 'content to process' } })
        page = @course.wiki.wiki_pages.find_by_url!(json['url'])
        page.title.should == 'New Wiki Page'
        page.url.should == 'new-wiki-page'
        page.body.should == 'processed content'
      end

      it "should set as front page" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                        { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                        { :wiki_page => { :title => 'New Wiki Page!', :body => 'hello new page', :published => true, :front_page => true}})

        page = @course.wiki.wiki_pages.find_by_url!(json['url'])
        page.is_front_page?.should be_true

        wiki = @course.wiki
        wiki.reload
        wiki.get_front_page_url.should == page.url

        json['front_page'].should == true
      end

      it "should not set hidden page as front page" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                { :wiki_page => { :title => 'hidden page', :hide_from_students => true,
                                   :body => 'Information wants to be free', :front_page => true }}, {},
                {:expected_status => 400})

        wiki = @course.wiki
        wiki.reload
        wiki.get_front_page_url.should == Wiki::DEFAULT_FRONT_PAGE_URL
      end

      it "should create a new page in published state" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                        { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                        { :wiki_page => { :published => true, :title => 'New Wiki Page!', :body => 'hello new page' }})
        page = @course.wiki.wiki_pages.find_by_url!(json['url'])
        page.should be_active
        json['published'].should be_true
      end
      
      it "should create a new page in unpublished state (draft state)" do
        @course.account.allow_feature!(:draft_state)
        @course.enable_feature!(:draft_state)

        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                        { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                        { :wiki_page => { :published => false, :title => 'New Wiki Page!', :body => 'hello new page' }})
        page = @course.wiki.wiki_pages.find_by_url!(json['url'])
        page.should be_unpublished
        json['published'].should be_false
      end
      
      it "should create a published front page, even when published is blank (draft state)" do
        @course.account.allow_feature!(:draft_state)
        @course.enable_feature!(:draft_state)

        front_page_url = 'my-front-page'
        json = api_call(:put, "/api/v1/courses/#{@course.id}/front_page",
                        { :controller => 'wiki_pages_api', :action => 'update_front_page', :format => 'json', :course_id => @course.to_param },
                        { :wiki_page => { :published => '', :title => 'My Front Page' }})
        json['url'].should == front_page_url
        json['published'].should be_true

        @course.wiki.get_front_page_url.should == front_page_url
        page = @course.wiki.wiki_pages.find_by_url!(front_page_url)
        page.should be_published
      end

      it 'should allow teachers to set editing_roles' do
        @course.default_wiki_editing_roles = 'teachers'
        @course.save
        api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                 { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                 { :wiki_page => { :title => 'New Wiki Page!', :body => 'hello new page', :editing_roles => 'teachers,students,public' } })
      end

      it 'should not allow students to set editing_roles' do
        course_with_student(:course => @course, :active_all => true)
        @course.default_wiki_editing_roles = 'teachers,students'
        @course.save
        api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                 { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                 { :wiki_page => { :title => 'New Wiki Page!', :body => 'hello new page', :editing_roles => 'teachers,students,public' } },
                 {}, {:expected_status => 401})
      end
    end

    describe "update" do
      it "should update page content and attributes" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url },
                 { :wiki_page => { :title => 'No Longer Hidden Page', :hide_from_students => false,
                   :body => 'Information wants to be free' }})
        @hidden_page.reload
        @hidden_page.should be_active
        @hidden_page.hide_from_students.should be_false
        @hidden_page.title.should == 'No Longer Hidden Page'
        @hidden_page.body.should == 'Information wants to be free'
        @hidden_page.user_id.should == @teacher.id        
      end

      it "should update front_page" do
        page = @course.wiki.wiki_pages.create!(:title => "hrup", :body => "blooop")
        page.set_as_front_page!

        new_title = 'blah blah blah'

        api_call(:put, "/api/v1/courses/#{@course.id}/front_page",
                 { :controller => 'wiki_pages_api', :action => 'update_front_page', :format => 'json', :course_id => @course.to_param},
                 { :wiki_page => { :title => new_title}})

        page.reload
        page.title.should == new_title
      end

      it "should set as front page" do
        wiki = @course.wiki
        wiki.unset_front_page!.should == true

        json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url },
                 { :wiki_page => { :title => 'No Longer Hidden Page', :hide_from_students => false,
                                   :body => 'Information wants to be free', :front_page => true }})
        no_longer_hidden_page = @hidden_page
        no_longer_hidden_page.reload
        no_longer_hidden_page.is_front_page?.should be_true

        wiki.reload
        wiki.front_page.should == no_longer_hidden_page

        json['front_page'].should == true
      end

      it "should un-set as front page" do
        wiki = @course.wiki
        wiki.reload
        wiki.has_front_page?.should be_true

        front_page = wiki.front_page

        json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{front_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => front_page.url },
                 { :wiki_page => { :title => 'No Longer Front Page', :hide_from_students => false,
                                   :body => 'Information wants to be free', :front_page => false }})

        front_page.reload
        front_page.is_front_page?.should be_false

        wiki.reload
        wiki.has_front_page?.should be_false
        wiki.front_page.should be_new_record

        json['front_page'].should == false
      end

      it "should not change the front page unless set differently" do
        set_course_draft_state true

        # make sure we don't catch the default 'front-page'
        @front_page.title = 'Different Front Page'
        @front_page.save!

        wiki = @course.wiki.reload
        wiki.set_front_page_url!(@front_page.url)

        # create and update another page
        other_page = @wiki.wiki_pages.create!(:title => "Other Page", :body => "Body of other page")
        other_page.workflow_state = 'active'
        other_page.save!

        json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{other_page.url}",
                        { :controller => 'wiki_pages_api', :action => 'update', :format => 'json',
                          :course_id => @course.to_param, :url => other_page.url },
                        { :wiki_page =>
                          { :title => 'Another Page', :body => 'Another page body', :front_page => false }
                        })

        # the front page url should remain unchanged
        wiki.reload.get_front_page_url.should == @front_page.url
      end

      it "should update wiki front page url if page url is updated" do
        page = @course.wiki.wiki_pages.create!(:title => "hrup")
        page.set_as_front_page!

        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => page.url },
                 { :wiki_page => { :url => 'noooo' }})

        page.reload
        page.is_front_page?.should be_true

        wiki = @course.wiki
        wiki.reload
        wiki.get_front_page_url.should == page.url
      end

      it "should not set hidden page as front page" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url },
                 { :wiki_page => { :title => 'Actually Still Hidden Page',
                                   :body => 'Information wants to be free', :front_page => true }}, {},
                 {:expected_status => 400})

        @hidden_page.reload
        @hidden_page.is_front_page?.should_not be_true
      end

      context 'hide_from_students' do
        before :once do
          @test_page = @course.wiki.wiki_pages.build(:title => 'Test Page')
          @test_page.workflow_state = 'active'
          @test_page.save!
        end

        context 'without draft state' do
          before :once do
            set_course_draft_state false
          end

          it 'should accept hide_from_students' do
            json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@test_page.url}",
                     { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param, :url => @test_page.url },
                     { :wiki_page => {'hide_from_students' => 'true'} })
            json['published'].should be_true
            json['hide_from_students'].should be_true

            @test_page.reload
            @test_page.should be_unpublished
            @test_page.hide_from_students.should be_true
          end

          it 'should not set hide_from_students to nil' do
            json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@test_page.url}",
                            { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param, :url => @test_page.url },
                            { :wiki_page => {'hide_from_students' => nil} })
            json['published'].should be_true
            json['hide_from_students'].should be_false

            @test_page.reload
            @test_page.should be_active
            @test_page.hide_from_students.should be_false
          end

          it 'should ignore published' do
            json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@test_page.url}",
                     { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param, :url => @test_page.url },
                     { :wiki_page => {'published' => 'false'} })
            json['published'].should be_true
            json['hide_from_students'].should be_false

            @test_page.reload
            @test_page.should be_active
            @test_page.hide_from_students.should be_false
          end
        end

        context 'with draft state' do
          before :once do
            set_course_draft_state true
          end

          it 'should accept published' do
            json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@test_page.url}",
                     { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param, :url => @test_page.url },
                     { :wiki_page => {'published' => 'false'} })
            json['published'].should be_false
            json['hide_from_students'].should be_true

            @test_page.reload
            @test_page.should be_unpublished
            @test_page.hide_from_students.should be_true
          end

          it 'should ignore hide_from_students' do
            set_course_draft_state true

            json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@test_page.url}",
                     { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param, :url => @test_page.url },
                     { :wiki_page => {'hide_from_students' => 'true'} })
            json['published'].should be_true
            json['hide_from_students'].should be_false

            @test_page.reload
            @test_page.should be_active
            @test_page.hide_from_students.should be_false
          end
        end
      end

      context 'with unpublished page' do
        before :once do
          set_course_draft_state
          @unpublished_page = @course.wiki.wiki_pages.build(:title => 'Unpublished Page', :body => 'Body of unpublished page')
          @unpublished_page.workflow_state = 'unpublished'
          @unpublished_page.save!

          @unpublished_page.reload
        end

        it 'should publish a page with published=true' do
          json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                   { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param, :url => @unpublished_page.url },
                   { :wiki_page => {'published' => 'true'} })
          json['published'].should be_true
          @unpublished_page.reload.should be_active
        end
        
        it 'should not publish a page otherwise' do
          json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                   { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param, :url => @unpublished_page.url })
          json['published'].should be_false
          @unpublished_page.reload.should be_unpublished
        end
      end

      it "should unpublish a page" do
        set_course_draft_state
        json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}?wiki_page[published]=false",
                 :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                 :url => @hidden_page.url, :wiki_page => {'published' => 'false'})
        json['published'].should be_false
        @hidden_page.reload.should be_unpublished
      end

      it "should sanitize page content" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url },
                 { :wiki_page => { :body => "<p>lolcats</p><script>alert('what')</script>" }})
        @hidden_page.reload
        @hidden_page.body.should == "<p>lolcats</p>alert('what')"
      end

      it 'should process body with process_incoming_html_content' do
        WikiPagesApiController.any_instance.stubs(:process_incoming_html_content).returns('processed content')

        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url },
                 { :wiki_page => { :body => 'content to process' } })
        @hidden_page.reload
        @hidden_page.body.should == 'processed content'
      end
      
      it "should not allow invalid editing_roles" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url },
                 { :wiki_page => { :editing_roles => 'teachers, chimpanzees, students' }},
                 {}, {:expected_status => 400})
      end
      
      it "should create a page if the page doesn't exist" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/nonexistent-url",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => 'nonexistent-url' },
                 { :wiki_page => { :body => 'Nonexistent page content' } })
        page = @wiki.wiki_pages.find_by_url!('nonexistent-url')
        page.should_not be_nil
        page.body.should == 'Nonexistent page content'
      end
      
      describe "notify_of_update" do
        before :once do
          @notify_page = @hidden_page
          @notify_page.publish!

          @front_page.update_attribute(:created_at, 1.hour.ago)
          @notify_page.update_attribute(:created_at, 1.hour.ago)
          @notification = Notification.create! :name => "Updated Wiki Page"
          @teacher.communication_channels.create(:path => "teacher@instructure.com").confirm!
          @teacher.email_channel.notification_policies.
              find_or_create_by_notification_id(@notification.id).
              update_attribute(:frequency, 'immediately')
        end
        
        it "should notify iff the notify_of_update flag is set" do
          api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}?wiki_page[body]=updated+front+page",
                   :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @front_page.url, :wiki_page => { "body" => "updated front page" })
          api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}?wiki_page[body]=updated+hidden+page&wiki_page[notify_of_update]=true",
                   :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @notify_page.url, :wiki_page => { "body" => "updated hidden page", "notify_of_update" => 'true' })
          @teacher.messages.map(&:context_id).should == [@notify_page.id]
        end
      end
    end
    
    describe "delete" do
      it "should delete a page" do
        api_call(:delete, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'destroy', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url })
        @hidden_page.reload.should be_deleted
      end

      it "should not delete the front_page" do
        page = @course.wiki.wiki_pages.create!(:title => "hrup", :body => "blooop")
        page.set_as_front_page!

        api_call(:delete, "/api/v1/courses/#{@course.id}/pages/#{page.url}",
                 { :controller => 'wiki_pages_api', :action => 'destroy', :format => 'json', :course_id => @course.to_param, :url => page.url},
                 {}, {}, {:expected_status => 400})

        page.reload
        page.should_not be_deleted

        wiki = @course.wiki
        wiki.reload
        wiki.has_front_page?.should == true
      end
    end

    context "unpublished pages" do
      before :once do
        @deleted_page = @wiki.wiki_pages.create! :title => "Deleted page"
        @deleted_page.destroy
        @course.account.allow_feature!(:draft_state)
        @course.enable_feature!(:draft_state)
        @unpublished_page = @wiki.wiki_pages.create(:title => "Draft Page", :body => "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "should be in index" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>"wiki_pages_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}")
        json.select{|w| w['title'] == @unpublished_page.title}.should_not be_empty
        json.select{|w| w['title'] == @hidden_page.title}.should_not be_empty
        json.select{|w| w['title'] == @deleted_page.title}.should be_empty
        json.select{|w| w['published'] == true}.should_not be_empty
        json.select{|w| w['published'] == false}.should_not be_empty
      end

      it "should not be in index if ?published=true" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?published=true",
                        :controller=>"wiki_pages_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}", :published => 'true')
        json.select{|w| w['title'] == @unpublished_page.title}.should be_empty
        json.select{|w| w['title'] == @hidden_page.title}.should be_empty
        json.select{|w| w['title'] == @deleted_page.title}.should be_empty
        json.select{|w| w['published'] == true}.should_not be_empty
        json.select{|w| w['published'] == false}.should be_empty
      end

      it "should be in index exclusively if ?published=false" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?published=false",
                        :controller=>"wiki_pages_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}", :published => 'false')
        json.select{|w| w['title'] == @unpublished_page.title}.should_not be_empty
        json.select{|w| w['title'] == @hidden_page.title}.should_not be_empty
        json.select{|w| w['title'] == @deleted_page.title}.should be_empty
        json.select{|w| w['published'] == true}.should be_empty
        json.select{|w| w['published'] == false}.should_not be_empty
      end

      it "should show" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                      :controller=>"wiki_pages_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :url=>@unpublished_page.url)
        json['title'].should == @unpublished_page.title
      end
    end
  end

  context "as a student" do
    before :once do
      course_with_student(:course => @course, :active_all => true)
    end
    
    it "should list pages, excluding hidden ones" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}")
      json.map{|entry| entry.slice(*%w(hide_from_students url created_at updated_at title))}.should ==
          [{"hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.updated_at.as_json, "title" => @front_page.title}]
    end
    
    it "should paginate, excluding hidden" do
      2.times { |i| @wiki.wiki_pages.create!(:title => "New Page #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?per_page=2",
                      :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}", :per_page => "2")
      json.size.should == 2
      urls = json.collect{ |page| page['url'] }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?per_page=2&page=2",
                      :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}", :per_page => "2", :page => "2")
      json.size.should == 1
      urls += json.collect{ |page| page['url'] }

      urls.should == @wiki.wiki_pages.select{ |p| !p.hide_from_students }.sort_by(&:id).collect(&:url)
    end
    
    it "should refuse to show a hidden page" do
      api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
               {:controller=>'wiki_pages_api', :action=>'show', :format=>'json', :course_id=>"#{@course.id}", :url=>@hidden_page.url},
               {}, {}, { :expected_status => 401 })
    end

    it "should refuse to list pages in an unpublished course" do
      @course.workflow_state = 'created'
      @course.save!
      api_call(:get, "/api/v1/courses/#{@course.id}/pages",
               {:controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}"},
               {}, {}, { :expected_status => 401 })
    end

    it "should deny access to wiki in an unenrolled course" do
      other_course = course
      other_course.offer!
      other_wiki = other_course.wiki
      other_page = other_wiki.front_page
      other_page.workflow_state = 'active'
      other_page.save!
      
      api_call(:get, "/api/v1/courses/#{other_course.id}/pages",
               {:controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{other_course.id}"},
               {}, {}, { :expected_status => 401 })
      
      api_call(:get, "/api/v1/courses/#{other_course.id}/pages/front-page",
               {:controller=>'wiki_pages_api', :action=>'show', :format=>'json', :course_id=>"#{other_course.id}", :url=>'front-page'},
               {}, {}, { :expected_status => 401 })
    end
    
    it "should allow access to a wiki in a public unenrolled course" do
      other_course = course
      other_course.is_public = true
      other_course.offer!
      other_wiki = other_course.wiki
      other_page = other_wiki.front_page
      other_page.workflow_state = 'active'
      other_page.save!

      json = api_call(:get, "/api/v1/courses/#{other_course.id}/pages",
               {:controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{other_course.id}"})
      json.should_not be_empty
      
      api_call(:get, "/api/v1/courses/#{other_course.id}/pages/front-page",
               {:controller=>'wiki_pages_api', :action=>'show', :format=>'json', :course_id=>"#{other_course.id}", :url=>'front-page'})
    end
    
    it "should fulfill module progression requirements" do
      mod = @course.context_modules.create!(:name => "some module")
      tag = mod.add_item(:id => @front_page.id, :type => 'wiki_page')
      mod.completion_requirements = { tag.id => {:type => 'must_view'} }
      mod.save!

      # index should not affect anything
      api_call(:get, "/api/v1/courses/#{@course.id}/pages",
               {:controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}"})
      mod.evaluate_for(@user).workflow_state.should == "unlocked"

      # show should count as a view
      api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}",
               {:controller=>'wiki_pages_api', :action=>'show', :format=>'json', :course_id=>"#{@course.id}", :url=>@front_page.url})
      mod.evaluate_for(@user).workflow_state.should == "completed"
    end
    
    it "should not allow editing a page" do
      api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}",
               { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                 :url => @front_page.url },
               { :publish => false, :wiki_page => { :body => '!!!!' }}, {}, {:expected_status => 401})
      @front_page.reload.body.should_not == '!!!!'
    end

    describe "with students in editing_roles" do
      before :once do
        @editable_page = @course.wiki.wiki_pages.create! :title => 'Editable Page', :editing_roles => 'students'
        @editable_page.workflow_state = 'active'
        @editable_page.save!
      end
      
      it "should allow editing the body" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :body => '?!?!' }})
        @editable_page.reload
        @editable_page.should be_active
        @editable_page.title.should == 'Editable Page'
        @editable_page.body.should == '?!?!'
        @editable_page.user_id.should == @student.id
      end
      
      it "should not allow editing attributes" do
        set_course_draft_state false
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :hide_from_students => true }},
                 {}, {:expected_status => 401})
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :title => 'Broken Links' }},
                 {}, {:expected_status => 401})
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :editing_roles => 'teachers' }},
                 {}, {:expected_status => 401})
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :editing_roles => 'teachers,students,public' }},
                 {}, {:expected_status => 401})

        @editable_page.reload
        @editable_page.should be_active
        @editable_page.hide_from_students.should be_false
        @editable_page.title.should == 'Editable Page'
        @editable_page.user_id.should_not == @student.id
        @editable_page.editing_roles.should == 'students'
      end

      it 'should not allow editing attributes (with draft state)' do
        set_course_draft_state
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :published => false }},
                 {}, {:expected_status => 401})
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :title => 'Broken Links' }},
                 {}, {:expected_status => 401})
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :editing_roles => 'teachers' }},
                 {}, {:expected_status => 401})
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :editing_roles => 'teachers,students,public' }},
                 {}, {:expected_status => 401})

        @editable_page.reload
        @editable_page.should be_active
        @editable_page.hide_from_students.should be_false
        @editable_page.title.should == 'Editable Page'
        @editable_page.user_id.should_not == @student.id
        @editable_page.editing_roles.should == 'students'
      end

      it "should fulfill module completion requirements" do
        mod = @course.context_modules.create!(:name => "some module")
        tag = mod.add_item(:id => @editable_page.id, :type => 'wiki_page')
        mod.completion_requirements = { tag.id => {:type => 'must_contribute'} }
        mod.save!

        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 {:controller=>'wiki_pages_api', :action=>'update', :format=>'json', :course_id=>"#{@course.id}",
                  :url=>@editable_page.url}, { :wiki_page => { :body => 'edited by student' }})
        mod.evaluate_for(@user).workflow_state.should == "completed"
      end
      
      it "should not allow creating pages" do
        api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                 { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                 {}, {}, {:expected_status => 401})
      end

      it "should not allow deleting pages" do
        api_call(:delete, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'destroy', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url }, {}, {}, {:expected_status => 401})
      end
    end

    context "unpublished pages" do
      before :once do
        @course.account.allow_feature!(:draft_state)
        @course.enable_feature!(:draft_state)
        @unpublished_page = @wiki.wiki_pages.create(:title => "Draft Page", :body => "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "should not be in index" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                        :controller => "wiki_pages_api", :action => "index", :format => "json", :course_id => "#{@course.id}")
        json.select { |w| w['title'] == @unpublished_page.title }.should == []
        json.select { |w| w['title'] == @hidden_page.title }.should == []
      end

      it "should not be in index even with ?published=false" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?published=0",
                        :controller => "wiki_pages_api", :action => "index", :format => "json", :course_id => "#{@course.id}", :published => '0')
        json.should be_empty
      end

      it "should not show" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                        {:controller => "wiki_pages_api", :action => "show", :format => "json", :course_id => "#{@course.id}", :url => @unpublished_page.url},
                        {}, {}, {:expected_status => 401})
      end

      it "should not show unpublished on public courses" do
        @course.is_public = true
        @course.save!
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                        {:controller => "wiki_pages_api", :action => "show", :format => "json", :course_id => "#{@course.id}", :url => @unpublished_page.url},
                        {}, {}, {:expected_status => 401})
      end
    end

    context "revisions" do
      before :once do
        @vpage = @course.wiki.wiki_pages.build :title => 'student version test page', :body => 'draft'
        @vpage.workflow_state = 'unpublished'
        @vpage.save! # rev 1

        @vpage.hide_from_students = true
        @vpage.workflow_state = 'active'
        @vpage.body = 'published but hidden'
        @vpage.save! # rev 2

        @vpage.hide_from_students = false
        @vpage.body = 'now visible to students'
        @vpage.save! # rev 3
      end

      it "should refuse to list revisions" do
        api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions",
                 { :controller => "wiki_pages_api", :action => "revisions", :format => "json",
                   :course_id => @course.to_param, :url => @vpage.url }, {}, {},
                   { :expected_status => 401 })
      end

      it "should refuse to retrieve a revision" do
        api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                 { :controller => "wiki_pages_api", :action => "show_revision", :format => "json", :course_id => "#{@course.id}",
                   :url => @vpage.url, :revision_id => '3' }, {}, {}, { :expected_status => 401 })
      end

      it "should refuse to revert a page" do
        api_call(:post, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                 { :controller=>"wiki_pages_api", :action=>"revert", :format=>"json", :course_id=>@course.to_param,
                  :url=>@vpage.url, :revision_id=>'2' }, {}, {}, { :expected_status => 401 })
      end

      it "should describe the latest version" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/latest",
                        :controller => "wiki_pages_api", :action => "show_revision", :format => "json",
                        :course_id => @course.to_param, :url => @vpage.url)
        json['revision_id'].should == 3
      end

      context "with page-level student editing role" do
        before :once do
          @vpage.editing_roles = 'teachers,students'
          @vpage.body = 'with student editing roles'
          @vpage.save! # rev 4
        end

        it "should list revisions" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions",
                          :controller => "wiki_pages_api", :action => "revisions", :format => "json",
                          :course_id => @course.to_param, :url => @vpage.url)
          json.map { |r| r['revision_id'] }.should == [4, 3, 2, 1]
        end

        it "should retrieve an old revision" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                         :controller => "wiki_pages_api", :action => "show_revision", :format => "json", :course_id => "#{@course.id}",
                         :url => @vpage.url, :revision_id => '3')
          json['body'].should == 'now visible to students'
        end

        it "should retrieve a (formerly) hidden revision" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                          :controller => "wiki_pages_api", :action => "show_revision", :format => "json", :course_id => "#{@course.id}",
                          :url => @vpage.url, :revision_id => '2')
          json['body'].should == 'published but hidden'
        end

        it "should retrieve a (formerly) unpublished revision" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/1",
                          :controller => "wiki_pages_api", :action => "show_revision", :format => "json", :course_id => "#{@course.id}",
                          :url => @vpage.url, :revision_id => '1')
          json['body'].should == 'draft'
        end

        it "should not retrieve a version of a locked page" do
          mod = @course.context_modules.create! :name => 'bad module'
          mod.add_item(:id => @vpage.id, :type => 'wiki_page')
          mod.unlock_at = 1.year.from_now
          mod.save!
          json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/3",
                   { :controller => "wiki_pages_api", :action => "show_revision", :format => "json", :course_id => "#{@course.id}",
                     :url => @vpage.url, :revision_id => '3' }, {}, {}, { :expected_status => 401 })
        end

        it "should not revert page content" do
          api_call(:post, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                   { :controller=>"wiki_pages_api", :action=>"revert", :format=>"json", :course_id=>@course.to_param,
                     :url=>@vpage.url, :revision_id=>'2' }, {}, {}, { :expected_status => 401 })
        end
      end

      context "with course-level student editing role" do
        before :once do
          @course.default_wiki_editing_roles = 'teachers,students'
          @course.save!
        end

        it "should revert page content" do
          api_call(:post, "/api/v1/courses/#{@course.id}/pages/#{@vpage.url}/revisions/2",
                   :controller=>"wiki_pages_api", :action=>"revert", :format=>"json", :course_id=>@course.to_param,
                   :url=>@vpage.url, :revision_id=>'2')
          @vpage.reload
          @vpage.hide_from_students.should be_false  # permissions aren't (conceptually) versioned
          @vpage.body.should == 'published but hidden'
        end
      end
    end
  end
  
  context "group" do
    before :once do
      group_with_user(:active_all => true)
      5.times { |i| @group.wiki.wiki_pages.create!(:title => "Group Wiki Page #{i}", :body => "<blink>Content of page #{i}</blink>") }
    end
    
    it "should list the contents of a group wiki" do
      json = api_call(:get, "/api/v1/groups/#{@group.id}/pages",
                     {:controller=>'wiki_pages_api', :action=>'index', :format=>'json', :group_id=>@group.to_param})
      json.collect { |row| row['title'] }.should == @group.wiki.wiki_pages.active.order_by_id.collect(&:title)      
    end
    
    it "should retrieve page content from a group wiki" do
      testpage = @group.wiki.wiki_pages.last
      json = api_call(:get, "/api/v1/groups/#{@group.id}/pages/#{testpage.url}",
                      {:controller=>'wiki_pages_api', :action=>'show', :format=>'json', :group_id=>@group.to_param, :url=>testpage.url})
      json['body'].should == testpage.body
    end
    
    it "should create a group wiki page" do
      json = api_call(:post, "/api/v1/groups/#{@group.id}/pages?wiki_page[title]=newpage",
               {:controller=>'wiki_pages_api', :action=>'create', :format=>'json', :group_id=>@group.to_param, :wiki_page => {'title' => 'newpage'}})
      page = @group.wiki.wiki_pages.find_by_url!(json['url'])
      page.title.should == 'newpage'
    end
    
    it "should update a group wiki page" do
      testpage = @group.wiki.wiki_pages.first
      api_call(:put, "/api/v1/groups/#{@group.id}/pages/#{testpage.url}?wiki_page[body]=lolcats",
               {:controller=>'wiki_pages_api', :action=>'update', :format=>'json', :group_id=>@group.to_param, :url=>testpage.url, :wiki_page => {'body' => 'lolcats'}})
      testpage.reload.body.should == 'lolcats'
    end
    
    it "should delete a group wiki page" do
      count = @group.wiki.wiki_pages.not_deleted.size
      testpage = @group.wiki.wiki_pages.last
      api_call(:delete, "/api/v1/groups/#{@group.id}/pages/#{testpage.url}",
               {:controller=>'wiki_pages_api', :action=>'destroy', :format=>'json', :group_id=>@group.to_param, :url=>testpage.url})
      @group.reload.wiki.wiki_pages.not_deleted.size.should == count - 1
    end

    context "revisions" do
      before :once do
        @vpage = @group.wiki.wiki_pages.create! :title => 'revision test page', :body => 'old version'
        @vpage.body = 'new version'
        @vpage.save!
      end

      it "should list revisions for a page" do
        json = api_call(:get, "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions",
                        :controller => 'wiki_pages_api', :action => 'revisions', :format => 'json',
                        :group_id => @group.to_param, :url => @vpage.url)
        json.map { |v| v['revision_id'] }.should == [2, 1]
      end

      it "should retrieve an old revision of a page" do
        json = api_call(:get, "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/1",
                        :controller => 'wiki_pages_api', :action => 'show_revision', :format => 'json',
                        :group_id => @group.to_param, :url => @vpage.url, :revision_id => '1')
        json['body'].should == 'old version'
      end

      it "should retrieve the latest version of a page" do
        json = api_call(:get, "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/latest",
                        :controller => 'wiki_pages_api', :action => 'show_revision', :format => 'json',
                        :group_id => @group.to_param, :url => @vpage.url)
        json['body'].should == 'new version'
      end

      it "should revert to an old version of a page" do
        api_call(:post, "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/1",
                 { :controller=>"wiki_pages_api", :action=>"revert", :format=>"json", :group_id=>@group.to_param,
                   :url=>@vpage.url, :revision_id=>'1' })
        @vpage.reload.body.should == 'old version'
      end

      it "should summarize the latest version" do
        json = api_call(:get, "/api/v1/groups/#{@group.id}/pages/#{@vpage.url}/revisions/latest?summary=1",
                        :controller => "wiki_pages_api", :action => "show_revision", :format => "json",
                        :group_id => @group.to_param, :url => @vpage.url, :summary => '1')
        json['revision_id'].should == 2
        json['body'].should be_nil
      end
    end
  end
end

