#
# Copyright (C) 2013 Instructure, Inc.
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

describe "Module Items API", :type => :integration do
  before do
    course.offer!

    @module1 = @course.context_modules.create!(:name => "module1")
    @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
    @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')
    @quiz = @course.quizzes.create!(:title => "score 10")
    @quiz_tag = @module1.add_item(:id => @quiz.id, :type => 'quiz')
    @topic = @course.discussion_topics.create!(:message => 'pls contribute')
    @topic_tag = @module1.add_item(:id => @topic.id, :type => 'discussion_topic')
    @subheader_tag = @module1.add_item(:type => 'context_module_sub_header', :title => 'external resources')
    @external_url_tag = @module1.add_item(:type => 'external_url', :url => 'http://example.com/lolcats',
                                          :title => 'pls view', :indent => 1)
    @module1.completion_requirements = {
        @assignment_tag.id => { :type => 'must_submit' },
        @quiz_tag.id => { :type => 'min_score', :min_score => 10 },
        @topic_tag.id => { :type => 'must_contribute' },
        @external_url_tag.id => { :type => 'must_view' } }
    @module1.save!

    @christmas = Time.zone.local(Time.now.year + 1, 12, 25, 7, 0)
    @module2 = @course.context_modules.create!(:name => "do not open until christmas",
                                               :unlock_at => @christmas,
                                               :require_sequential_progress => true)
    @module2.prerequisites = "module_#{@module1.id}"
    @wiki_page = @course.wiki.wiki_page
    @wiki_page.workflow_state = 'active'; @wiki_page.save!
    @wiki_page_tag = @module2.add_item(:id => @wiki_page.id, :type => 'wiki_page')
    @attachment = attachment_model(:context => @course)
    @attachment_tag = @module2.add_item(:id => @attachment.id, :type => 'attachment')
    @module2.save!

    @module3 = @course.context_modules.create(:name => "module3")
    @module3.workflow_state = 'unpublished'
    @module3.save!
  end

  context "as a teacher" do
    before :each do
      course_with_teacher(:course => @course, :active_all => true)
    end

    it "should list module items" do
      @assignment_tag.unpublish
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")
      json.should eql [
          {
              "type" => "Assignment",
              "id" => @assignment_tag.id,
              "content_id" => @assignment.id,
              "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@assignment_tag.id}",
              "position" => 1,
              "url" => "http://www.example.com/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
              "title" => @assignment_tag.title,
              "indent" => 0,
              "completion_requirement" => { "type" => "must_submit" },
              "published" => false
          },
          {
              "type" => "Quiz",
              "id" => @quiz_tag.id,
              "content_id" => @quiz.id,
              "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@quiz_tag.id}",
              "url" => "http://www.example.com/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
              "position" => 2,
              "title" => @quiz_tag.title,
              "indent" => 0,
              "completion_requirement" => { "type" => "min_score", "min_score" => 10 },
              "published" => true
          },
          {
              "type" => "Discussion",
              "id" => @topic_tag.id,
              "content_id" => @topic.id,
              "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@topic_tag.id}",
              "position" => 3,
              "url" => "http://www.example.com/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
              "title" => @topic_tag.title,
              "indent" => 0,
              "completion_requirement" => { "type" => "must_contribute" },
              "published" => true
          },
          {
              "type" => "SubHeader",
              "id" => @subheader_tag.id,
              "position" => 4,
              "title" => @subheader_tag.title,
              "indent" => 0,
              "published" => true
          },
          {
              "type" => "ExternalUrl",
              "id" => @external_url_tag.id,
              "html_url" => "http://www.example.com/api/v1/courses/#{@course.id}/module_item_redirect/#{@external_url_tag.id}",
              "external_url" => @external_url_tag.url,
              "position" => 5,
              "title" => @external_url_tag.title,
              "indent" => 1,
              "completion_requirement" => { "type" => "must_view" },
              "published" => true
          }
      ]
    end

    it 'should return the url for external tool items' do
      tool = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @module1.add_item(:type => 'external_tool', :title => 'Tool', :id => tool.id, :url => 'http://www.google.com', :new_tab => false, :indent => 0)
      @module1.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      items = json.select {|item| item['type'] == 'ExternalTool'}
      items.length.should == 1
      items.each do |item|
        item.should include('url')
        uri = URI(item['url'])
        uri.path.should == "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
        uri.query.should include('url=')
      end
    end

    it "should show module items individually" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@wiki_page_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                      :id => "#{@wiki_page_tag.id}")
      json.should == {
          "type" => "Page",
          "id" => @wiki_page_tag.id,
          "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@wiki_page_tag.id}",
          "position" => 1,
          "title" => @wiki_page_tag.title,
          "indent" => 0,
          "url" => "http://www.example.com/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}",
          "page_url" => @wiki_page.url,
          "published" => true
      }

      @attachment_tag.unpublish
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@attachment_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                      :id => "#{@attachment_tag.id}")
      json.should == {
          "type" => "File",
          "id" => @attachment_tag.id,
          "content_id" => @attachment.id,
          "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@attachment_tag.id}",
          "position" => 2,
          "title" => @attachment_tag.title,
          "indent" => 0,
          "url" => "http://www.example.com/api/v1/files/#{@attachment.id}",
          "published" => false
      }
    end

    it "should paginate the module item list" do
      module3 = @course.context_modules.create!(:name => "module with lots of items")
      4.times { |i| module3.add_item(:type => 'context_module_sub_header', :title => "item #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{module3.id}/items?per_page=2",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{module3.id}", :per_page => "2")
      response.headers["Link"].should be_present
      json.size.should == 2
      ids = json.collect{ |tag| tag['id'] }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{module3.id}/items?per_page=2&page=2",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{module3.id}", :page => "2", :per_page => "2")
      json.size.should == 2
      ids += json.collect{ |tag| tag['id'] }

      ids.should == module3.content_tags.sort_by(&:position).collect(&:id)
    end

    describe "POST 'create'" do
      it "should create a module item" do
        assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
        new_title = 'New title'
        new_indent = 2
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => new_title, :indent => new_indent,
                                          :type => 'Assignment', :content_id => assignment.id}})

        json['type'].should == 'Assignment'
        json['title'].should == new_title
        json['indent'].should == new_indent

        tag = @module1.content_tags.find_by_id(json['id'])
        tag.should_not be_nil
        tag.title.should == new_title
        tag.content_type.should == 'Assignment'
        tag.content_id.should == assignment.id
        tag.indent.should == new_indent
      end

      it "should create with page_url for wiki page items" do
        wiki_page = @course.wiki.wiki_pages.create!(:title => 'whateva i do wut i want')

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'Blah', :type => 'Page', :page_url => wiki_page.url}})

        json['page_url'].should == wiki_page.url

        tag = @module1.content_tags.find_by_id(json['id'])
        tag.content_type.should == 'WikiPage'
        tag.content_id.should == wiki_page.id
      end

      it "should require valid page_url" do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'Blah', :type => 'Page'}},
                        {}, {:expected_status => 400})

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'Blah', :type => 'Page', :page_url => 'invalidpageurl'}},
                        {}, {:expected_status => 400})
      end

      it "should create with new_tab for external tool items" do
        tool = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'Blah', :type => 'ExternalTool', :content_id => tool.id,
                                          :external_url => tool.url, :new_tab => 'true'}})

        json['new_tab'].should == true

        tag = @module1.content_tags.find_by_id(json['id'])
        tag.new_tab.should == true
      end

      it "should create with url for external url items" do
        new_title = 'New title'
        new_url = 'http://example.org/new_tool'
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => new_title, :type => 'ExternalUrl', :external_url => new_url}})

        json['type'].should == 'ExternalUrl'
        json['external_url'].should == new_url

        tag = @module1.content_tags.find_by_id(json['id'])
        tag.should_not be_nil
        tag.content_type.should == 'ExternalUrl'
        tag.url.should == new_url
      end

      it "should insert into correct position" do
        @quiz_tag.destroy
        tags = @module1.content_tags.active
        tags.map(&:position).should == [1, 3, 4, 5]

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'title', :type => 'ExternalUrl',
                                          :url => 'http://example.com', :position => 3}})

        json['position'].should == 3

        tag = @module1.content_tags.find_by_id(json['id'])
        tag.should_not be_nil
        tag.position.should == 3

        tags.each{|t| t.reload}
        tags.map(&:position).should == [1, 2, 4, 5]
      end

      it "should set completion requirement" do
        assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'title', :type => 'Assignment', :content_id => assignment.id,
                         :completion_requirement => {:type => 'min_score', :min_score => 2}}})

        json['completion_requirement'].should == {"type" => "min_score", "min_score" => "2"}

        @module1.reload
        req = @module1.completion_requirements.find{|h| h[:id] == json['id'].to_i}
        req[:type].should == 'min_score'
        req[:min_score].should == "2"
      end

      it "should require valid completion requirement type" do
        assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'title', :type => 'Assignment', :content_id => assignment.id,
                         :completion_requirement => {:type => 'not a valid type'}}},
                         {}, {:expected_status => 400})

        json["errors"]["completion_requirement"].count.should == 1
      end
    end

    describe "PUT 'update'" do
      it "should update attributes" do
        new_title = 'New title'
        new_indent = 2
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                        :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:title => new_title, :indent => new_indent}})

        json['title'].should == new_title
        json['indent'].should == new_indent

        @assignment_tag.reload
        @assignment_tag.title.should == new_title
        @assignment.reload.title.should == new_title
        @assignment_tag.indent.should == new_indent
      end

      it "should update new_tab" do
        tool = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
        external_tool_tag = @module1.add_item(:type => 'context_external_tool', :id => tool.id, :url => tool.url, :new_tab => false)

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{external_tool_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{external_tool_tag.id}"},
                        {:module_item => {:new_tab => 'true'}})

        json['new_tab'].should == true

        external_tool_tag.reload
        external_tool_tag.new_tab.should == true
      end

      it "should update the url for an external url item" do
        new_url = 'http://example.org/new_tool'
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@external_url_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@external_url_tag.id}"},
                        {:module_item => {:external_url => new_url}})

        json['external_url'].should == new_url

        @external_url_tag.reload.url.should == new_url
      end

      it "should ignore the url for a non-applicable type" do
        new_url = 'http://example.org/new_tool'
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:external_url => new_url}})

        json['external_url'].should be_nil

        @assignment_tag.reload.url.should be_nil
      end

      it "should update the position" do
        tags = @module1.content_tags

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:position => 2}})

        json['position'].should == 2

        tags.each{|t| t.reload}
        tags.map(&:position).should == [2, 1, 3, 4, 5]

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:position => 4}})

        json['position'].should == 4

        tags.each{|t| t.reload}
        tags.map(&:position).should == [4, 1, 2, 3, 5]
      end

      it "should set completion requirement" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:title => 'title',
                                          :completion_requirement => {:type => 'min_score', :min_score => 3}}})

        json['completion_requirement'].should == {"type" => "min_score", "min_score" => "3"}

        @module1.reload
        req = @module1.completion_requirements.find{|h| h[:id] == json['id'].to_i}
        req[:type].should == 'min_score'
        req[:min_score].should == "3"
      end

      it "should remove completion requirement" do
        req = @module1.completion_requirements.find{|h| h[:id] == @assignment_tag.id}
        req.should_not be_nil

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:title => 'title', :completion_requirement => ''}})

        json['completion_requirement'].should be_nil

        @module1.reload
        req = @module1.completion_requirements.find{|h| h[:id] == json['id'].to_i}
        req.should be_nil
      end

      it "should publish module items" do
        course_with_student(:course => @course, :active_all => true)
        @user = @teacher

        @assignment.submit_homework(@student, :body => "done!")

        @assignment_tag.unpublish
        @assignment_tag.workflow_state.should == 'unpublished'
        @module1.save

        @module1.evaluate_for(@student).workflow_state.should == 'unlocked'

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:published => '1'}}
        )
        json['published'].should == true

        @assignment_tag.reload
        @assignment_tag.workflow_state.should == 'active'
      end

      it "should unpublish module items" do
        course_with_student(:course => @course, :active_all => true)
        @user = @teacher

        @assignment.submit_homework(@student, :body => "done!")

        @module1.evaluate_for(@student).workflow_state.should == 'started'

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:published => '0'}}
        )
        json['published'].should == false

        @assignment_tag.reload
        @assignment_tag.workflow_state.should == 'unpublished'

        @module1.reload
        @module1.evaluate_for(@student).workflow_state.should == 'unlocked'
      end
    end

    it "should delete a module item" do
      json = api_call(:delete, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
               {:controller => "context_module_items_api", :action => "destroy", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
               {}, {}
      )
      json['id'].should == @assignment_tag.id
      @assignment_tag.reload
      @assignment_tag.workflow_state.should == 'deleted'
    end
  end

  context "as a student" do
    before :each do
      course_with_student_logged_in(:course => @course, :active_all => true)
    end

    it "should list module items" do
      @assignment_tag.unpublish
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      json.map{|item| item['id']}.sort.should == @module1.content_tags.active.map(&:id).sort

      #also for locked modules that have completion requirements
      @assignment2 = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
      @assignment_tag2 = @module2.add_item(:id => @assignment2.id, :type => 'assignment')
      @module2.completion_requirements = {
          @assignment_tag2.id => { :type => 'must_submit' }}
      @module2.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}")

      json.map{|item| item['id']}.sort.should == @module2.content_tags.map(&:id).sort
    end

    it "should show module item completion" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}")
      json['completion_requirement']['type'].should == 'must_submit'
      json['completion_requirement']['completed'].should be_false

      @assignment.submit_homework(@user, :body => "done!")

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}")
      json['completion_requirement']['completed'].should be_true
    end

    it "should not show unpublished items" do
      @assignment_tag.unpublish
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                      {:controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}"}, {}, {}, {:expected_status => 404})
    end

    it "should mark viewed and redirect external URLs" do
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/module_item_redirect/#{@external_url_tag.id}",
                   :controller => "context_module_items_api", :action => "redirect",
                   :format => "json", :course_id => "#{@course.id}", :id => "#{@external_url_tag.id}")
      response.should redirect_to "http://example.com/lolcats"
      @module1.evaluate_for(@user).requirements_met.should be_any {
          |rm| rm[:type] == "must_view" && rm[:id] == @external_url_tag.id }
    end

    it "should disallow update" do
      api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
               {:controller => "context_module_items_api", :action => "update", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
               {:module_item => {:title => 'new name'}}, {},
               {:expected_status => 401}
      )
    end

    it "should disallow create" do
      api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
               {:controller => "context_module_items_api", :action => "create", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
               {:module_item => {:title => 'new name'}}, {},
               {:expected_status => 401}
      )
    end

    it "should disallow destroy" do
      api_call(:delete, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
               {:controller => "context_module_items_api", :action => "destroy", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
               {}, {},
               {:expected_status => 401}
      )
    end
  end

  context "unauthorized user" do
    before do
      user
    end

    it "should check permissions" do
      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
               { :controller => "context_module_items_api", :action => "index", :format => "json",
                 :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
               {}, {}, { :expected_status => 401 })
      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@attachment_tag.id}",
               { :controller => "context_module_items_api", :action => "show", :format => "json",
                 :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                 :id => "#{@attachment_tag.id}"}, {}, {}, { :expected_status => 401 })
      api_call(:get, "/api/v1/courses/#{@course.id}/module_item_redirect/#{@external_url_tag.id}",
               { :controller => "context_module_items_api", :action => "redirect",
                 :format => "json", :course_id => "#{@course.id}", :id => "#{@external_url_tag.id}"},
               {}, {}, { :expected_status => 401 })
      api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
               {:controller => "context_module_items_api", :action => "update", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
               {:module_item => {:title => 'new name'}}, {},
               {:expected_status => 401}
      )
      api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
               {:controller => "context_module_items_api", :action => "create", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
               {:module_item => {:title => 'new name'}}, {},
               {:expected_status => 401}
      )
      api_call(:delete, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
               {:controller => "context_module_items_api", :action => "destroy", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
               {}, {},
               {:expected_status => 401}
      )
    end
  end
end
