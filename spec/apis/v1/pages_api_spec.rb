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

    describe "index" do
      it "should list pages, including hidden ones" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                        :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>@course.to_param)
        json.map {|entry| entry.slice(*%w(hide_from_students url created_at updated_at title))}.should == 
          [{"hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.updated_at.as_json, "title" => @front_page.title},
           {"hide_from_students" => true, "url" => @hidden_page.url, "created_at" => @hidden_page.created_at.as_json, "updated_at" => @hidden_page.updated_at.as_json, "title" => @hidden_page.title}]
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
      include Api::V1::User
      def avatar_url_for_user(user, *a)
        "http://www.example.com/images/messages/avatar-50.png"
      end
      def blank_fallback
        nil
      end

      before do
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
                     "created_at" => @hidden_page.created_at.as_json,
                     "updated_at" => @hidden_page.updated_at.as_json,
                     "title" => @hidden_page.title,
                     "body" => @hidden_page.body,
                     "published" => true }
        json.should == expected
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
      
      it "should create a new page in published state" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                        { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                        { :wiki_page => { :published => true, :title => 'New Wiki Page!', :body => 'hello new page' }})
        page = @course.wiki.wiki_pages.find_by_url!(json['url'])
        page.should be_active
        json['published'].should be_true
      end
      
      it "should create a new page in unpublished state" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/pages",
                        { :controller => 'wiki_pages_api', :action => 'create', :format => 'json', :course_id => @course.to_param },
                        { :wiki_page => { :published => false, :title => 'New Wiki Page!', :body => 'hello new page' }})
        page = @course.wiki.wiki_pages.find_by_url!(json['url'])
        page.should be_unpublished
        json['published'].should be_false
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

      context "with unpublished page" do
        before do
          @hidden_page.workflow_state = 'unpublished'
          @hidden_page.save!
        end

        it "should publish a page with published=true" do
          json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}?wiki_page[published]=true",
                   :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url, :wiki_page => {'published' => 'true'})
          json['published'].should be_true
          @hidden_page.reload.should be_active
        end
        
        it "should not publish a page otherwise" do
          json = api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                   :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url)
          json['published'].should be_false
          @hidden_page.reload.should be_unpublished
        end
      end

      it "should unpublish a page" do
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
      
      it "should clean editing_roles" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url },
                 { :wiki_page => { :editing_roles => 'teachers, chimpanzees, students' }})
        @hidden_page.reload
        @hidden_page.editing_roles.should == 'teachers,students'
      end
      
      it "should 404 if the page doesn't exist" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/nonexistent-url?title=renamed",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => 'nonexistent-url', :title => 'renamed' }, {}, {}, { :expected_status => 404 })
      end
      
      describe "notify_of_update" do
        before do
          @front_page.update_attribute(:created_at, 1.hour.ago)
          @hidden_page.update_attribute(:created_at, 1.hour.ago)
          @notification = Notification.create! :name => "Updated Wiki Page"
          @teacher.communication_channels.create(:path => "teacher@instructure.com").confirm!
          @teacher.email_channel.notification_policies.
              find_or_create_by_notification_id(@notification.id).
              update_attribute(:frequency, 'immediately')
        end
        
        it "should notify iff the notify_on_update flag is sent" do
          api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@front_page.url}?wiki_page[body]=updated+front+page",
                   :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @front_page.url, :wiki_page => { "body" => "updated front page" })
          api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@hidden_page.url}?wiki_page[body]=updated+hidden+page&wiki_page[notify_of_update]=true",
                   :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @hidden_page.url, :wiki_page => { "body" => "updated hidden page", "notify_of_update" => 'true' })
          @teacher.messages.map(&:context_id).should == [@hidden_page.id]
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
    end

    context "unpublished pages" do
      before do
        @unpublished_page = @wiki.wiki_pages.create(:title => "Draft Page", :body => "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "should be in index" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>"wiki_pages_api", :action=>"index", :format=>"json", :course_id=>"#{@course.id}")
        json.select{|w|w[:title] == @unpublished_page.title}.should_not be_nil
      end
      it "should show" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages/#{@unpublished_page.url}",
                      :controller=>"wiki_pages_api", :action=>"show", :format=>"json", :course_id=>"#{@course.id}", :url=>@unpublished_page.url)
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
                      :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}")
      json.map{|entry| entry.slice(*%w(hide_from_students url created_at updated_at title))}.should ==
          [{"hide_from_students" => false, "url" => @front_page.url, "created_at" => @front_page.created_at.as_json, "updated_at" => @front_page.updated_at.as_json, "title" => @front_page.title}]
    end
    
    it "should paginate, excluding hidden" do
      11.times { |i| @wiki.wiki_pages.create!(:title => "New Page #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                      :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}")
      json.size.should == 10
      urls = json.collect{ |page| page['url'] }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/pages?page=2",
                      :controller=>'wiki_pages_api', :action=>'index', :format=>'json', :course_id=>"#{@course.id}", :page => "2")
      json.size.should == 2
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
      other_page = other_wiki.wiki_page
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
      other_page = other_wiki.wiki_page
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
      before do
        @editable_page = @course.wiki.wiki_pages.create! :title => 'Editable Page', :editing_roles => 'students'
        @editable_page.workflow_state = 'active'
        @editable_page.save!
      end
      
      it "should allow editing the body, but not attributes" do
        api_call(:put, "/api/v1/courses/#{@course.id}/pages/#{@editable_page.url}",
                 { :controller => 'wiki_pages_api', :action => 'update', :format => 'json', :course_id => @course.to_param,
                   :url => @editable_page.url },
                 { :wiki_page => { :published => false, :title => 'Broken Links', :body => '?!?!' }})
        @editable_page.reload
        @editable_page.should be_active
        @editable_page.title.should == 'Editable Page'
        @editable_page.body.should == '?!?!'
        @editable_page.user_id.should == @student.id
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
      before do
        @unpublished_page = @wiki.wiki_pages.create(:title => "Draft Page", :body => "Don't text and drive.")
        @unpublished_page.workflow_state = :unpublished
        @unpublished_page.save!
      end

      it "should not be in index" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/pages",
                        :controller => "wiki_pages_api", :action => "index", :format => "json", :course_id => "#{@course.id}")
        json.select { |w| w[:title] == @unpublished_page.title }.should == []
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
  end
  
  context "group" do
    before :each do
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
  end
end
