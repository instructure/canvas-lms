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

describe "Module Items API", type: :request do
  before :once do
    course_factory.offer!

    @module1 = @course.context_modules.create!(:name => "module1")
    @assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"], :points_possible => 20)
    @assignment.publish! if @assignment.unpublished?
    @assignment_tag = @module1.add_item(:id => @assignment.id, :type => 'assignment')

    @quiz = @course.quizzes.create!(:title => "score 10")
    @quiz.publish!
    @quiz_tag = @module1.add_item(:id => @quiz.id, :type => 'quiz')

    @topic = @course.discussion_topics.create!(:message => 'pls contribute')
    @topic.publish! if @topic.unpublished?
    @topic_tag = @module1.add_item(:id => @topic.id, :type => 'discussion_topic')

    @subheader_tag = @module1.add_item(:type => 'context_module_sub_header', :title => 'external resources')
    @subheader_tag.publish! if @subheader_tag.unpublished?

    @external_url_tag = @module1.add_item(:type => 'external_url', :url => 'http://example.com/lolcats',
                                          :title => 'pls view', :indent => 1)
    @external_url_tag.publish! if @external_url_tag.unpublished?

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
    @wiki_page = @course.wiki.wiki_pages.create!(:title => "wiki title", :body => "")
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
    before :once do
      course_with_teacher(:course => @course, :active_all => true)
    end

    it "should list module items" do
      @assignment_tag.unpublish
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      expected = [
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
              "published" => false,
              "module_id" => @module1.id
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
              "completion_requirement" => { "type" => "min_score", "min_score" => 10.0 },
              "published" => true,
              "module_id" => @module1.id
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
              "published" => true,
              "module_id" => @module1.id
          },
          {
              "type" => "SubHeader",
              "id" => @subheader_tag.id,
              "position" => 4,
              "title" => @subheader_tag.title,
              "indent" => 0,
              "published" => true,
              "module_id" => @module1.id
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
              "published" => true,
              "module_id" => @module1.id
          }
      ]
      compare_json(json, expected)
    end

    context 'index with content details' do
      let(:json) do
        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items?include[]=content_details",
          :controller => "context_module_items_api", :action => "index", :format => "json",
          :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :include => ['content_details'])
      end
      let(:assignment_details) { json.find{|item| item['id'] == @assignment_tag.id }['content_details'] }

      it "should include item details" do
        expect(assignment_details).to include(
          'points_possible' => @assignment.points_possible,
          'locked_for_user' => false,
        )
      end
    end

    it 'should return the url for external tool items' do
      tool = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @module1.add_item(:type => 'external_tool', :title => 'Tool', :id => tool.id, :url => 'http://www.google.com', :new_tab => false, :indent => 0)
      @module1.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      items = json.select {|item| item['type'] == 'ExternalTool'}
      expect(items.length).to eq 1
      items.each do |item|
        expect(item).to include('url')
        uri = URI(item['url'])
        expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
        expect(uri.query).to include("module_item_id=#{@module1.content_tags.last.id}")
        expect(uri.query).to include('launch_type=module_item')
      end
    end

    it 'should return the url for external tool manually entered urls' do
      @module1.add_item(:type => 'external_tool', :title => 'Tool', :url => 'http://www.google.com', :new_tab => false, :indent => 0)
      @module1.save!
      @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      items = json.select {|item| item['type'] == 'ExternalTool'}
      expect(items.length).to eq 1
      items.each do |item|
        expect(item).to include('url')
        uri = URI(item['url'])
        expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
        expect(uri.query).to include('url=')
      end
    end

    it "should return the url for external tool with tool_id" do
      tool = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret', :tool_id => 'ewet00b')
      @module1.add_item(:type => 'external_tool', :title => 'Tool', :id => tool.id, :url => 'http://www.google.com', :new_tab => false, :indent => 0)
      @module1.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      items = json.select {|item| item['type'] == 'ExternalTool'}
      expect(items.length).to eq 1
      items.each do |item|
        expect(item).to include('url')
        uri = URI(item['url'])
        expect(uri.path).to eq "/api/v1/courses/#{@course.id}/external_tools/sessionless_launch"
        expect(uri.query).to include("id=#{tool.id}")
        expect(uri.query).to include('url=')
      end
    end

    it "should show module items individually" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@wiki_page_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                      :id => "#{@wiki_page_tag.id}")
      expect(json).to eq({
          "type" => "Page",
          "id" => @wiki_page_tag.id,
          "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@wiki_page_tag.id}",
          "position" => 1,
          "title" => @wiki_page_tag.title,
          "indent" => 0,
          "url" => "http://www.example.com/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}",
          "page_url" => @wiki_page.url,
          "published" => true,
          "module_id" => @module2.id
      })

      @attachment_tag.unpublish
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@attachment_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                      :id => "#{@attachment_tag.id}")
      expect(json).to eq({
          "type" => "File",
          "id" => @attachment_tag.id,
          "content_id" => @attachment.id,
          "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@attachment_tag.id}",
          "position" => 2,
          "title" => @attachment_tag.title,
          "indent" => 0,
          "url" => "http://www.example.com/api/v1/courses/#{@course.id}/files/#{@attachment.id}",
          "published" => false,
          "module_id" => @module2.id
      })
    end

    context 'with differentiated assignments' do
      before :each do
        course_with_student(:course => @course, :active_all => true)
        @user = @student
      end

      it "should find module items" do
        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
          :controller => "context_module_items_api", :action => "show", :format => "json",
          :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
          :id => "#{@assignment_tag.id}")
      end

      it "should not find module items when hidden" do
        @assignment.only_visible_to_overrides = true
        @assignment.save!
        @section = @course.course_sections.create!(name: "test section")
        create_section_override_for_assignment(@assignment, {course_section: @section})

        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
          {:controller => "context_module_items_api", :action => "show", :format => "json",
          :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
          :id => "#{@assignment_tag.id}"}, {}, {}, {:expected_status => 404})
      end
    end

    context 'show with content details' do
      let(:json) do
        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}?include[]=content_details",
          :controller => "context_module_items_api", :action => "show", :format => "json",
          :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :include => ['content_details'],
          :id => "#{@assignment_tag.id}")
      end
      let(:assignment_details) { json['content_details'] }

      it "should include item details" do
        expect(assignment_details).to include(
          'points_possible' => @assignment.points_possible,
          'locked_for_user' => false,
        )
      end
    end

    it "should frame_external_urls" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@external_url_tag.id}?frame_external_urls=true",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :frame_external_urls => 'true',
                      :id => "#{@external_url_tag.id}")
      expect(json['html_url']).to eql "http://www.example.com/courses/#{@course.id}/modules/items/#{@external_url_tag.id}"
    end

    it "should paginate the module item list" do
      module3 = @course.context_modules.create!(:name => "module with lots of items")
      4.times { |i| module3.add_item(:type => 'context_module_sub_header', :title => "item #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{module3.id}/items?per_page=2",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{module3.id}", :per_page => "2")
      expect(response.headers["Link"]).to be_present
      expect(json.size).to eq 2
      ids = json.collect{ |tag| tag['id'] }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{module3.id}/items?per_page=2&page=2",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{module3.id}", :page => "2", :per_page => "2")
      expect(json.size).to eq 2
      ids += json.collect{ |tag| tag['id'] }

      expect(ids).to eq module3.content_tags.sort_by(&:position).collect(&:id)
    end

    it "should search for module items by name" do
      module3 = @course.context_modules.create!(:name => "module with lots of items")
      tags = []
      2.times { |i| tags << module3.add_item(:type => 'context_module_sub_header', :title => "specific tag #{i}") }
      2.times { |i| module3.add_item(:type => 'context_module_sub_header', :title => "other tag #{i}") }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{module3.id}/items?search_term=spec",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{module3.id}", :search_term => 'spec')
      expect(json.map{ |mod| mod['id'] }.sort).to eq tags.map(&:id).sort
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

        expect(json['type']).to eq 'Assignment'
        expect(json['title']).to eq new_title
        expect(json['indent']).to eq new_indent

        tag = @module1.content_tags.where(id: json['id']).first
        expect(tag).not_to be_nil
        expect(tag.title).to eq new_title
        expect(tag.content_type).to eq 'Assignment'
        expect(tag.content_id).to eq assignment.id
        expect(tag.indent).to eq new_indent
      end

      it "should create with page_url for wiki page items" do
        wiki_page = @course.wiki.wiki_pages.create!(:title => 'whateva i do wut i want')

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'Blah', :type => 'Page', :page_url => wiki_page.url}})

        expect(json['page_url']).to eq wiki_page.url

        tag = @module1.content_tags.where(id: json['id']).first
        expect(tag.content_type).to eq 'WikiPage'
        expect(tag.content_id).to eq wiki_page.id
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

      it "should require a non-deleted page_url" do
        page = @course.wiki.wiki_pages.create(:title => 'Deleted Page')
        page.workflow_state = 'deleted'
        page.save!

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'Deleted Page', :type => 'Page', :page_url => page.url}},
                        {}, {:expected_status => 400})
      end

      it "should create with new_tab for external tool items" do
        tool = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'Blah', :type => 'ExternalTool', :content_id => tool.id,
                                          :external_url => tool.url, :new_tab => 'true'}})

        expect(json['new_tab']).to eq true

        tag = @module1.content_tags.where(id: json['id']).first
        expect(tag.new_tab).to eq true
      end

      it "should create with url for external url items" do
        new_title = 'New title'
        new_url = 'http://example.org/new_tool'
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => new_title, :type => 'ExternalUrl', :external_url => new_url}})

        expect(json['type']).to eq 'ExternalUrl'
        expect(json['external_url']).to eq new_url

        tag = @module1.content_tags.where(id: json['id']).first
        expect(tag).not_to be_nil
        expect(tag.content_type).to eq 'ExternalUrl'
        expect(tag.url).to eq new_url
      end

      it "should insert into correct position" do
        @quiz_tag.destroy
        tags = @module1.content_tags.active
        expect(tags.map(&:position)).to eq [1, 3, 4, 5]

        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'title', :type => 'ExternalUrl',
                                          :url => 'http://example.com', :position => 3}})

        expect(json['position']).to eq 3

        tag = @module1.content_tags.where(id: json['id']).first
        expect(tag).not_to be_nil
        expect(tag.position).to eq 3

        tags.each{|t| t.reload}
        # 2 is deleted; 3 is the new one, that displaced the others to 4-6
        expect(tags.map(&:position)).to eq [1, 4, 5, 6]
      end

      it "should set completion requirement" do
        assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'title', :type => 'Assignment', :content_id => assignment.id,
                         :completion_requirement => {:type => 'min_score', :min_score => 2}}})

        expect(json['completion_requirement']).to eq({"type" => "min_score", "min_score" => 2})

        @module1.reload
        req = @module1.completion_requirements.find{|h| h[:id] == json['id'].to_i}
        expect(req[:type]).to eq 'min_score'
        expect(req[:min_score]).to eq 2
      end

      it "should require valid completion requirement type" do
        assignment = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                        {:controller => "context_module_items_api", :action => "create", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
                        {:module_item => {:title => 'title', :type => 'Assignment', :content_id => assignment.id,
                         :completion_requirement => {:type => 'not a valid type'}}},
                         {}, {:expected_status => 400})

        expect(json["errors"]["completion_requirement"].count).to eq 1
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

        expect(json['title']).to eq new_title
        expect(json['indent']).to eq new_indent

        @assignment_tag.reload
        expect(@assignment_tag.title).to eq new_title
        expect(@assignment.reload.title).to eq new_title
        expect(@assignment_tag.indent).to eq new_indent
      end

      it "should update new_tab" do
        tool = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
        external_tool_tag = @module1.add_item(:type => 'context_external_tool', :id => tool.id, :url => tool.url, :new_tab => false)

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{external_tool_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{external_tool_tag.id}"},
                        {:module_item => {:new_tab => 'true'}})

        expect(json['new_tab']).to eq true

        external_tool_tag.reload
        expect(external_tool_tag.new_tab).to eq true
      end

      it "should update the url for an external url item" do
        new_url = 'http://example.org/new_tool'
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@external_url_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@external_url_tag.id}"},
                        {:module_item => {:external_url => new_url}})

        expect(json['external_url']).to eq new_url

        expect(@external_url_tag.reload.url).to eq new_url
      end

      it "should ignore the url for a non-applicable type" do
        new_url = 'http://example.org/new_tool'
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:external_url => new_url}})

        expect(json['external_url']).to be_nil

        expect(@assignment_tag.reload.url).to be_nil
      end

      it "should update the position" do
        tags = @module1.content_tags.to_a

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:position => 2}})

        expect(json['position']).to eq 2

        tags.each{|t| t.reload}
        expect(tags.map(&:position)).to eq [2, 1, 3, 4, 5]

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:position => 4}})

        expect(json['position']).to eq 4

        tags.each{|t| t.reload}
        expect(tags.map(&:position)).to eq [4, 1, 2, 3, 5]
      end

      it "should set completion requirement" do
        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:title => 'title',
                                          :completion_requirement => {:type => 'min_score', :min_score => 3}}})

        expect(json['completion_requirement']).to eq({"type" => "min_score", "min_score" => 3})

        @module1.reload
        req = @module1.completion_requirements.find{|h| h[:id] == json['id'].to_i}
        expect(req[:type]).to eq 'min_score'
        expect(req[:min_score]).to eq 3
      end

      it "should remove completion requirement" do
        req = @module1.completion_requirements.find{|h| h[:id] == @assignment_tag.id}
        expect(req).not_to be_nil

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:title => 'title', :completion_requirement => ''}})

        expect(json['completion_requirement']).to be_nil

        @module1.reload
        req = @module1.completion_requirements.find{|h| h[:id] == json['id'].to_i}
        expect(req).to be_nil
      end

      it "should publish module items" do
        course_with_student(:course => @course, :active_all => true)
        @user = @teacher

        @assignment.submit_homework(@student, :body => "done!")

        @assignment_tag.unpublish
        expect(@assignment_tag.workflow_state).to eq 'unpublished'
        @module1.save

        expect(@module1.evaluate_for(@student).workflow_state).to eq 'unlocked'

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:published => '1'}}
        )
        expect(json['published']).to eq true

        @assignment_tag.reload
        expect(@assignment_tag.workflow_state).to eq 'active'
      end

      it "should unpublish module items" do
        course_with_student(:course => @course, :active_all => true)
        @user = @teacher

        @assignment.submit_homework(@student, :body => "done!")

        expect(@module1.evaluate_for(@student).workflow_state).to eq 'started'

        json = api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                        {:controller => "context_module_items_api", :action => "update", :format => "json",
                         :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                        {:module_item => {:published => '0'}}
        )
        expect(json['published']).to eq false

        @assignment_tag.reload
        expect(@assignment_tag.workflow_state).to eq 'unpublished'

        @module1.reload
        expect(@module1.evaluate_for(@student).workflow_state).to eq 'unlocked'
      end

      describe "moving items between modules" do
        it "should move a module item" do
          old_updated_ats = []
          Timecop.freeze(1.minute.ago) do
            @module2.touch; old_updated_ats << @module2.updated_at
            @module3.touch; old_updated_ats << @module3.updated_at
          end
          api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@wiki_page_tag.id}",
                   {:controller => "context_module_items_api", :action => "update", :format => "json",
                    :course_id => "#{@course.id}", :module_id => "#{@module2.id}", :id => "#{@wiki_page_tag.id}"},
                   {:module_item => {:module_id => @module3.id}})

          expect(@module2.reload.content_tags.map(&:id)).not_to be_include @wiki_page_tag.id
          expect(@module2.updated_at).to be > old_updated_ats[0]
          expect(@module3.reload.content_tags.map(&:id)).to eq [@wiki_page_tag.id]
          expect(@module3.updated_at).to be > old_updated_ats[1]
        end

        it "should move completion requirements" do
          old_updated_ats = []
          Timecop.freeze(1.minute.ago) do
            @module1.touch; old_updated_ats << @module1.updated_at
            @module2.touch; old_updated_ats << @module2.updated_at
          end
          api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
              {:controller => "context_module_items_api", :action => "update", :format => "json",
               :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
              {:module_item => {:module_id => @module2.id}})

          expect(@module1.reload.content_tags.map(&:id)).not_to be_include @assignment_tag.id
          expect(@module1.updated_at).to be > old_updated_ats[0]
          expect(@module1.completion_requirements.size).to eq 3
          expect(@module1.completion_requirements.detect { |req| req[:id] == @assignment_tag.id }).to be_nil

          expect(@module2.reload.updated_at).to be > old_updated_ats[1]
          expect(@module2.completion_requirements.detect { |req| req[:id] == @assignment_tag.id }).not_to be_nil
        end

        it "should set the position in the target module" do
          old_updated_ats = []
          Timecop.freeze(1.minute.ago) do
            @module1.touch; old_updated_ats << @module1.updated_at
            @module2.touch; old_updated_ats << @module2.updated_at
          end
          api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                   {:controller => "context_module_items_api", :action => "update", :format => "json",
                    :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
                   {:module_item => {:module_id => @module2.id, :position => 2}})

          expect(@module1.reload.content_tags.map(&:id)).not_to be_include @assignment_tag.id
          expect(@module1.updated_at).to be > old_updated_ats[0]
          expect(@module1.completion_requirements.size).to eq 3
          expect(@module1.completion_requirements.detect { |req| req[:id] == @assignment_tag.id }).to be_nil

          expect(@module2.reload.content_tags.sort_by(&:position).map(&:id)).to eq [@wiki_page_tag.id, @assignment_tag.id, @attachment_tag.id]
          expect(@module2.updated_at).to be > old_updated_ats[1]
          expect(@module2.completion_requirements.detect { |req| req[:id] == @assignment_tag.id }).not_to be_nil
        end

        it "should verify the target module is in the course" do
          course_with_teacher
          mod = @course.context_modules.create!
          item = mod.add_item(:type => 'context_module_sub_header', :title => 'blah')
          api_call(:put, "/api/v1/courses/#{@course.id}/modules/#{mod.id}/items/#{item.id}",
                   {:controller => "context_module_items_api", :action => "update", :format => "json",
                    :course_id => @course.to_param, :module_id => mod.to_param, :id => item.to_param},
                   {:module_item => {:module_id => @module1.id}}, {}, {:expected_status => 400})
        end
      end
    end

    it "should delete a module item" do
      json = api_call(:delete, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
               {:controller => "context_module_items_api", :action => "destroy", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
               {}, {}
      )
      expect(json['id']).to eq @assignment_tag.id
      @assignment_tag.reload
      expect(@assignment_tag.workflow_state).to eq 'deleted'
    end

    it "should show module item completion for a student" do
      student = User.create!
      @course.enroll_student(student).accept!

      @assignment.submit_homework(student, :body => "done!")

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items?student_id=#{student.id}",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :student_id => "#{student.id}", :module_id => "#{@module1.id}")
      expect(json.find{|m| m["id"] == @assignment_tag.id}["completion_requirement"]["completed"]).to eq true

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}?student_id=#{student.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}", :student_id => "#{student.id}")
      expect(json["completion_requirement"]["completed"]).to eq true
    end

    describe "GET 'module_item_sequence'" do
      it "should 400 if the asset_type is missing" do
        api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_id=999",
                 { :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                   :course_id => @course.to_param, :asset_id => '999' }, {}, {}, { :expected_status => 400 })
      end

      it "should 400 if the asset_id is missing" do
        api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=quiz",
                 { :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                   :course_id => @course.to_param, :asset_type => 'quiz' }, {}, {}, { :expected_status => 400 })
      end

      it "should return a skeleton json structure if referencing an item that isn't in a module" do
        other_quiz = @course.quizzes.create!
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=quiz&asset_id=#{other_quiz.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'quiz', :asset_id => other_quiz.to_param)
        expect(json).to eq({ 'items' => [], 'modules' => [] })
      end

      it "should work with the first item" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Assignment&asset_id=#{@assignment.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'Assignment', :asset_id => @assignment.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['prev']).to be_nil
        expect(json['items'][0]['current']['id']).to eq @assignment_tag.id
        expect(json['items'][0]['next']['id']).to eq @quiz_tag.id
        expect(json['modules'].size).to eql 1
        expect(json['modules'][0]['id']).to eq @module1.id
      end

      it "should skip subheader items" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=ModuleItem&asset_id=#{@external_url_tag.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'ModuleItem', :asset_id => @external_url_tag.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['prev']['id']).to eq @topic_tag.id
        expect(json['items'][0]['current']['id']).to eq @external_url_tag.id
        expect(json['items'][0]['next']['id']).to eq @wiki_page_tag.id
        expect(json['modules'].map {|mod| mod['id']}.sort).to eq [@module1.id, @module2.id].sort
      end

      it "should find a (non-deleted) wiki page by url" do
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Page&asset_id=#{@wiki_page.url}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'Page', :asset_id => @wiki_page.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['prev']['id']).to eq @external_url_tag.id
        expect(json['items'][0]['current']['id']).to eq @wiki_page_tag.id
        expect(json['items'][0]['next']['id']).to eq @attachment_tag.id
        expect(json['modules'].map {|mod| mod['id']}.sort).to eq [@module1.id, @module2.id].sort

        @wiki_page.workflow_state = 'deleted'
        @wiki_page.save!

        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Page&asset_id=#{@wiki_page.url}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'Page', :asset_id => @wiki_page.to_param)
        expect(json['items'].size).to eql 0
        expect(json['modules'].size).to eql 0
      end

      it "should skip a deleted module" do
        new_tag = @module3.add_item(:id => @attachment.id, :type => 'attachment')
        @module2.destroy
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=ModuleItem&asset_id=#{@external_url_tag.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'ModuleItem', :asset_id => @external_url_tag.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['next']['id']).to eql new_tag.id
        expect(json['modules'].map {|mod| mod['id']}.sort).to eq [@module1.id, @module3.id].sort
      end

      it "should skip a deleted item" do
        @quiz_tag.destroy
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Assignment&asset_id=#{@assignment.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'Assignment', :asset_id => @assignment.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['current']['id']).to eq @assignment_tag.id
        expect(json['items'][0]['next']['id']).to eq @topic_tag.id
      end

      it "should find an item containing the assignment associated with a quiz" do
        other_quiz = @course.quizzes.create!
        other_quiz.publish!
        wacky_tag = @module3.add_item(:type => 'assignment', :id => other_quiz.assignment.id)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=quiz&asset_id=#{other_quiz.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'quiz', :asset_id => other_quiz.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['current']['id']).to eql wacky_tag.id
      end

      it "should find an item containing the assignment associated with a graded discussion topic" do
        discussion_assignment = @course.assignments.create!
        other_topic = @course.discussion_topics.create! :assignment => discussion_assignment
        wacky_tag = @module3.add_item(:type => 'assignment', :id => other_topic.assignment.id)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=discussioN&asset_id=#{other_topic.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'discussioN', :asset_id => other_topic.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['current']['id']).to eql wacky_tag.id
      end

      it "should deal with multiple modules having the same position" do
        @module2.update_attribute(:position, 1)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=quiz&asset_id=#{@quiz.id}",
                         :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                         :course_id => @course.to_param, :asset_type => 'quiz', :asset_id => @quiz.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['prev']['id']).to eql @assignment_tag.id
        expect(json['items'][0]['next']['id']).to eql @topic_tag.id
      end

      it "should treat a nil position as sort-last" do
        @external_url_tag.update_attribute(:position, nil)
        json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=discussion&asset_id=#{@topic.id}",
                        :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                        :course_id => @course.to_param, :asset_type => 'discussion', :asset_id => @topic.to_param)
        expect(json['items'].size).to eql 1
        expect(json['items'][0]['prev']['id']).to eql @quiz_tag.id
        expect(json['items'][0]['next']['id']).to eql @external_url_tag.id
      end

      context "with duplicate items" do
        before :once do
          @other_quiz_tag = @module3.add_item(:id => @quiz.id, :type => 'quiz')
        end

        it "should return multiple items" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Quiz&asset_id=#{@quiz.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'Quiz', :asset_id => @quiz.to_param)
          expect(json['items'].size).to eql 2
          expect(json['items'][0]['prev']['id']).to eq @assignment_tag.id
          expect(json['items'][0]['current']['id']).to eq @quiz_tag.id
          expect(json['items'][0]['next']['id']).to eq @topic_tag.id
          expect(json['items'][1]['prev']['id']).to eq @attachment_tag.id
          expect(json['items'][1]['current']['id']).to eq @other_quiz_tag.id
          expect(json['items'][1]['next']).to be_nil
        end

        it "should limit the number of sequences returned to 10" do
          modules = (0..9).map do |x|
            mod = @course.context_modules.create! :name => "I will do it #{x} times"
            mod.add_item :type => 'assignment', :id => @assignment.id
            mod
          end
          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Assignment&asset_id=#{@assignment.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'Assignment', :asset_id => @assignment.to_param)
          expect(json['items'].size).to eql 10
          expect(json['items'][9]['current']['module_id']).to eq modules[8].id
        end

        it "should return a single item, given the content tag" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=ModuleItem&asset_id=#{@quiz_tag.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'ModuleItem', :asset_id => @quiz_tag.to_param)
          expect(json['items'].size).to eql 1
          expect(json['items'][0]['prev']['id']).to eq @assignment_tag.id
          expect(json['items'][0]['current']['id']).to eq @quiz_tag.id
          expect(json['items'][0]['next']['id']).to eq @topic_tag.id
        end
      end
    end

    describe 'POST select_mastery_path' do
      before do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
        ConditionalRelease::Service.stubs(:select_mastery_path).returns({ code: '200', body: {} })
        student_in_course(course: @course)
      end

      def call_select_mastery_path(item, assignment_set_id, student_id, opts = {})
        api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{item.id}/select_mastery_path",
                        { controller: "context_module_items_api", action: 'select_mastery_path', format: 'json',
                          course_id: "#{@course.id}", module_id: "#{@module1.id}", id: "#{item.id}" },
                        { assignment_set_id: assignment_set_id, student_id: student_id },
                        {},
                        opts)
      end

      it 'should require mastery paths to be enabled' do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(false)
        call_select_mastery_path @assignment_tag, 100, @student.id, expected_status: 400
      end

      it 'should require a student_id specified' do
        call_select_mastery_path @assignment_tag, 100, nil, expected_status: 401
      end

      it 'should require an assignment_set_id specified' do
        json = call_select_mastery_path @assignment_tag, nil, @student.id, expected_status: 400
        expect(json['message']).to match(/assignment_set_id/)
      end

      it 'should require the module item be attached to an assignment' do
        json = call_select_mastery_path @external_url_tag, 100, @student.id, expected_status: 400
        expect(json['message']).to match(/assignment/)
      end

      it 'should return the CYOE error if the action is unsuccessful' do
        ConditionalRelease::Service.stubs(:select_mastery_path).returns({ code: '909', body: { 'foo' => 'bar' } })
        json = call_select_mastery_path @assignment_tag, 100, @student.id, expected_status: 909
        expect(json).to eq({ 'foo' => 'bar' })
      end

      it 'should not allow unpublished items' do
        @assignment.unpublish!
        call_select_mastery_path @assignment_tag, 100, @student.id, expected_status: 404
      end

      context 'successful' do
        def cyoe_returns(assignment_ids)
          cyoe_ids = assignment_ids.map {|id| { 'assignment_id' => "#{id}" }} # cyoe ids in strings
          cyoe_response = { 'assignments' => cyoe_ids }
          ConditionalRelease::Service.stubs(:select_mastery_path).returns({ code: '200', body: cyoe_response })
        end

        it 'should return a list of assignments if the action is successful' do
          assignment_ids = create_assignments([@course.id], 3)
          cyoe_returns assignment_ids
          json = call_select_mastery_path @assignment_tag, 100, @student.id
          expect(json['assignments'].length).to eq 3
          expect(json['assignments'].map {|a| a['id']}).to eq assignment_ids
          expect(json['items']).to eq []
        end

        it 'should return a list of associated module items' do
          @graded_topic = group_discussion_assignment
          @graded_topic.publish!
          @graded_topic_tag = @module1.add_item(:id => @graded_topic.id, :type => 'discussion_topic')

          assignment_ids = [@quiz.assignment_id] + create_assignments([@course.id], 3) + [@graded_topic.assignment_id]
          cyoe_returns assignment_ids
          json = call_select_mastery_path @assignment_tag, 100, @student.id
          items = json['items']
          expect(items.length).to eq 2
          expect(items.map {|item| item['id']}).to match_array [@quiz_tag.id, @graded_topic_tag.id]
        end

        it 'should return assignments in the same order as cyoe' do
          assignment_ids = create_assignments([@course.id], 5)
          cyoe_returns assignment_ids.reverse
          json = call_select_mastery_path @assignment_tag, 100, @student.id
          expect(json['assignments'].map {|a| a['id']}).to eq assignment_ids.reverse
          expect(json['items']).to eq []
        end

        it 'should return only published assignments' do
          assignment_ids = create_assignments([@course.id], 5)
          Assignment.find(assignment_ids.last).unpublish!
          cyoe_returns assignment_ids
          json = call_select_mastery_path @assignment_tag, 100, @student.id
          expect(json['assignments'].map {|a| a['id']}).to eq assignment_ids[0..-2]
        end
      end
    end
  end

  context "as a student" do
    before :once do
      course_with_student(:course => @course, :active_all => true)
    end

    def override_assignment
      @due_at = Time.zone.now + 2.days
      @unlock_at = Time.zone.now + 1.days
      @lock_at = Time.zone.now + 3.days
      @override = assignment_override_model(:assignment => @assignment, :due_at => @due_at, :unlock_at => @unlock_at, :lock_at => @lock_at)
      @override_student = @override.assignment_override_students.build
      @override_student.user = @student
      @override_student.save!
      overrides = AssignmentOverrideApplicator.overrides_for_assignment_and_user(@assignment, @student)
      @student = nil
      overrides
    end

    it "should list module items" do
      @assignment_tag.unpublish
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      expect(json.map{|item| item['id']}.sort).to eq @module1.content_tags.active.map(&:id).sort

      #also for locked modules that have completion requirements
      @assignment2 = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
      @assignment_tag2 = @module2.add_item(:id => @assignment2.id, :type => 'assignment')
      @module2.completion_requirements = {
          @assignment_tag2.id => { :type => 'must_submit' }}
      @module2.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items",
                      :controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}")

      expect(json.map{|item| item['id']}.sort).to eq @module2.content_tags.map(&:id).sort
    end

    context 'differentiated_assignments' do
      before do
        @new_section = @course.course_sections.create!(name: "test section")
        @student.enrollments.each(&:destroy_permanently!)
        student_in_section(@new_section, user: @student)
        @assignment.only_visible_to_overrides = true
        @assignment.save!
      end

      context 'enabled' do
        context 'with override' do
          before{create_section_override_for_assignment(@assignment, {course_section: @new_section})}
          it "should list all assignments" do
            json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                                  :controller => "context_module_items_api", :action => "index", :format => "json",
                                  :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

            expect(json.map{|item| item['id']}.sort).to eq @module1.content_tags.map(&:id).sort
          end
        end
        context 'without override' do
          it "should exclude unassigned assignments" do
            json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                                  :controller => "context_module_items_api", :action => "index", :format => "json",
                                  :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

            expect(json.map{|item| item['id']}.sort).not_to eq @module1.content_tags.map(&:id).sort
          end
        end
      end
    end

    context 'index including content details' do
      let(:json) do
        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items?include[]=content_details",
          :controller => "context_module_items_api", :action => "index", :format => "json",
          :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :include => ['content_details'])
      end
      let(:assignment_details) { json.find{|item| item['id'] == @assignment_tag.id}['content_details'] }
      let(:external_url_details) { json.find{|item| item['id'] == @external_url_tag.id}['content_details'] }

      before :once do
        override_assignment
        @module1.update_attribute(:require_sequential_progress, true)
      end

      it "should include user specific details" do
        expect(assignment_details).to include(
          'points_possible' => @assignment.points_possible,
          'due_at' => @due_at.iso8601,
          'unlock_at' => @unlock_at.iso8601,
          'lock_at' => @lock_at.iso8601,
        )
      end

      it "should include lock information" do
        expect(assignment_details['locked_for_user']).to eq true
        expect(assignment_details).to include 'lock_explanation'
        expect(assignment_details).to include 'lock_info'
        expect(assignment_details['lock_info']).to include(
          'asset_string' => @assignment.asset_string,
          'unlock_at' => @unlock_at.iso8601,
        )
      end

      it "should include lock information for contentless tags" do
        expect(external_url_details['locked_for_user']).to eq true
        expect(external_url_details).to include 'lock_explanation'
        expect(external_url_details).to include 'lock_info'
        expect(external_url_details['lock_info']).to include(
            'asset_string' => @module1.asset_string
        )
      end
    end

    context "index including mastery_paths (CYOE)" do
      def has_assignment_model?(item)
        rules = item.deep_symbolize_keys
        return false unless rules[:mastery_paths].present?
        rules[:mastery_paths][:assignment_sets].find do |set|
          set[:assignments].find do |asg|
            asg.key? :model
          end
        end
      end

      before :once do
        @cyoe_module1 = @course.context_modules.create!(:name => "cyoe_module1")
        @cyoe_module2 = @course.context_modules.create!(:name => "cyoe_module2")
        @cyoe_module3 = @course.context_modules.create!(:name => "cyoe_module3")

        [@cyoe_module1, @cyoe_module2, @cyoe_module3].each do |mod|
          mod.add_item(:id => @assignment.id, :type => 'assignment')
          mod.add_item(:id => @quiz.id, :type => 'quiz')
          mod.add_item(:id => @topic.id, :type => 'discussion_topic')
          mod.add_item(:id => @wiki_page.id, :type => 'wiki_page')
          mod.add_item(:type => 'external_url', :url =>
                       'http://example.com/cyoe', :title => 'cyoe link',
                       :indent => 1, :updated_at => nil).publish!
          mod.publish
        end
      end

      before :each do
        @resp = [{
                  locked: false,
                  trigger_assignment: @quiz.assignment_id,
                  assignment_sets: [{
                    id: 1,
                    scoring_range_id: 1,
                    created_at: @assignment.created_at,
                    updated_at: @assignment.updated_at,
                    position: 1,
                    assignments: [{
                      id: 1,
                      assignment_id: @assignment.id,
                      created_at: @assignment.created_at,
                      updated_at: @assignment.updated_at,
                      assignment_set_id: 1,
                      position: 1
                    }]
                  }]
                }]
        ConditionalRelease::Service.stubs(headers_for: {}, submissions_for: [],
          domain_for: "canvas.xyz", "enabled_in_context?" => true,
          rules_summary_url: "cyoe.abc/rules", request_rules: @resp)
      end

      describe "CYOE interaction" do
        it "makes a request to the CYOE service when included" do
          ConditionalRelease::Service.expects(:request_rules).once

          api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@cyoe_module1.id}/items?include[]=mastery_paths",
            :controller => "context_module_items_api", :action => "index", :format => "json",
            :course_id => @course.id.to_s, :module_id => @cyoe_module1.id.to_s,
            :include => ['mastery_paths'])
        end
      end

      describe "module item list response data" do
        it "includes conditional release information from CYOE" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@cyoe_module2.id}/items?include[]=mastery_paths",
          :controller => "context_module_items_api", :action => "index", :format => "json",
          :course_id => @course.id.to_s, :module_id => @cyoe_module2.id.to_s, :include => ['mastery_paths'])
          mastery_paths = json.all? { |item| item.key? 'mastery_paths' }
          expect(mastery_paths).to be_truthy
        end

        it "includes model data merge from Canvas" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@cyoe_module2.id}/items?include[]=mastery_paths",
            :controller => "context_module_items_api", :action => "index", :format => "json",
            :course_id => @course.id.to_s, :module_id => @cyoe_module2.id.to_s, :include => ['mastery_paths'])
          models = json.any? { |item| has_assignment_model?(item) }
          expect(models).to be_truthy
        end
      end

      describe "caching CYOE data" do
        it "uses the cache when requested again" do
          ConditionalRelease::Service.expects(:request_rules).never
          ConditionalRelease::Service.stubs(rules_cache: {rules: @resp, updated_at: 1.day.from_now})
          3.times do
            api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@cyoe_module3.id}/items?include[]=mastery_paths",
              :controller => "context_module_items_api", :action => "index", :format => "json",
              :course_id => @course.id.to_s, :module_id => @cyoe_module3.id.to_s,
              :include => ['mastery_paths'])
          end
        end
      end
    end

    context 'show including content details' do
      let(:json) do
        api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}?include[]=content_details",
          :controller => "context_module_items_api", :action => "show", :format => "json",
          :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :include => ['content_details'],
          :id => "#{@assignment_tag.id}")
      end
      let(:assignment_details) { json['content_details'] }

      before :once do
        override_assignment
      end

      it "should include user specific details" do
        expect(assignment_details).to include(
          'points_possible' => @assignment.points_possible,
          'due_at' => @due_at.iso8601,
          'unlock_at' => @unlock_at.iso8601,
          'lock_at' => @lock_at.iso8601,
        )
      end

      it "should include lock information" do
        expect(assignment_details['locked_for_user']).to eq true
        expect(assignment_details).to include 'lock_explanation'
        expect(assignment_details).to include 'lock_info'
        expect(assignment_details['lock_info']).to include(
          'asset_string' => @assignment.asset_string,
          'unlock_at' => @unlock_at.iso8601,
        )
      end
    end

    it "should show module item completion" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}")
      expect(json['completion_requirement']['type']).to eq 'must_submit'
      expect(json['completion_requirement']['completed']).to be_falsey

      @assignment.submit_homework(@user, :body => "done!")

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                      :controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}")
      expect(json['completion_requirement']['completed']).to be_truthy
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
      expect(response).to redirect_to "http://example.com/lolcats"
      expect(@module1.evaluate_for(@user).requirements_met).to be_any {
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

    it "should not show module item completion for other students" do
      student = User.create!
      @course.enroll_student(student).accept!

      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items?student_id=#{student.id}",
                      {:controller => "context_module_items_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :student_id => "#{student.id}", :module_id => "#{@module1.id}"},
                      {}, {},
                      {:expected_status => 401})

      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}?student_id=#{student.id}",
                      {:controller => "context_module_items_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}", :student_id => "#{student.id}"},
                      {}, {},
                      {:expected_status => 401})
    end

    context 'mark_as_done' do
      before :once do
        @module = @course.context_modules.create(:name => "mark_as_done_module")
        wiki_page = @course.wiki.wiki_pages.create!(:title => "mark_as_done page", :body => "")
        wiki_page.workflow_state = 'active'
        wiki_page.save!
        @tag = @module.add_item(:id => wiki_page.id, :type => 'wiki_page')
        @module.completion_requirements = {
          @tag.id => { :type => 'must_mark_done' },
        }
        @module.save!
      end

      def mark_done_api_call
        api_call(:put,
                 "/api/v1/courses/#{@course.id}/modules/#{@module.id}/items/#{@tag.id}/done",
                 :controller => "context_module_items_api",
                 :action     => "mark_as_done",
                 :format     => "json",
                 :course_id  => @course.to_param,
                 :module_id  => @module.to_param,
                 :id => @tag.to_param,
                )
      end

      def mark_not_done_api_call
        api_call(:delete,
                 "/api/v1/courses/#{@course.id}/modules/#{@module.id}/items/#{@tag.id}/done",
                 :controller => "context_module_items_api",
                 :action     => "mark_as_not_done",
                 :format     => "json",
                 :course_id  => @course.to_param,
                 :module_id  => @module.to_param,
                 :id => @tag.to_param,
                )
      end

      describe "PUT" do
        it "should fulfill must-mark-done requirement" do
          mark_done_api_call
          expect(@module.evaluate_for(@user).requirements_met).to be_any do |rm|
            rm[:type] == "must_mark_done" && rm[:id] == @tag.id
          end
        end
      end

      describe "DELETE" do
        it "should remove must-mark-done requirement" do
          mark_done_api_call
          mark_not_done_api_call
          expect(@module.evaluate_for(@user).requirements_met).to be_none do |rm|
            rm[:type] == "must_mark_done"
          end
        end

        it "should work even when there is none must-mark-done requirement to delete" do
          mark_not_done_api_call
        end
      end
    end

    describe "POST 'mark_item_read'" do
      it "should fulfill must-view requirement" do
        api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@external_url_tag.id}/mark_read",
                 :controller => "context_module_items_api", :action => "mark_item_read",
                 :format => "json", :course_id => @course.to_param, :module_id => @module1.to_param, :id => @external_url_tag.to_param)
        expect(@module1.evaluate_for(@user).requirements_met).to be_any {
            |rm| rm[:type] == "must_view" && rm[:id] == @external_url_tag.id }
      end

      it "should not fulfill must-view requirement on unpublished item" do
        @external_url_tag.unpublish
        api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@external_url_tag.id}/mark_read",
                 { :controller => "context_module_items_api", :action => "mark_item_read",
                   :format => "json", :course_id => @course.to_param, :module_id => @module1.to_param, :id => @external_url_tag.to_param },
                 {}, {}, { expected_status: 404 })
        expect(@module1.evaluate_for(@user).requirements_met).not_to be_any {
            |rm| rm[:type] == "must_view" && rm[:id] == @external_url_tag.id }
      end

      it "should not fulfill must-view requirement on locked item" do
        @module2.completion_requirements = { @attachment_tag.id => { :type => 'must_view' } }
        @module2.save!
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@attachment_tag.id}/mark_read",
                 { :controller => "context_module_items_api", :action => "mark_item_read",
                   :format => "json", :course_id => @course.to_param, :module_id => @module2.to_param, :id => @attachment_tag.to_param },
                 {}, {}, { expected_status: 403 })
        expect(json['message']).to eq('The module item is locked.')
        expect(@module2.evaluate_for(@user).requirements_met).to be_empty
      end
    end

    describe "GET 'module_item_sequence'" do
      context "unpublished item" do
        before :once do
          @quiz_tag.unpublish
        end

        it "should not find an unpublished item" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Quiz&asset_id=#{@quiz.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'Quiz', :asset_id => @quiz.to_param)
          expect(json['items']).to be_empty
        end

        it "should skip an unpublished item in the sequence" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Assignment&asset_id=#{@assignment.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'Assignment', :asset_id => @assignment.to_param)
          expect(json['items'][0]['next']['id']).to eql @topic_tag.id

          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Discussion&asset_id=#{@topic.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'Discussion', :asset_id => @topic.to_param)
          expect(json['items'][0]['prev']['id']).to eql @assignment_tag.id
        end
      end

      context "unpublished module" do
        before :once do
          @new_assignment_1 = @course.assignments.create!
          @new_assignment_1_tag = @module3.add_item :type => 'assignment', :id => @new_assignment_1.id
          @module4 = @course.context_modules.create!
          @new_assignment_2 = @course.assignments.create!
          @new_assignment_2_tag = @module4.add_item :type => 'assignment', :id => @new_assignment_2.id
        end

        it "should not find an item in an unpublished module" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Assignment&asset_id=#{@new_assignment_1.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'Assignment', :asset_id => @new_assignment_1.to_param)
          expect(json['items']).to be_empty
        end

        it "should skip an unpublished module in the sequence" do
          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=File&asset_id=#{@attachment.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'File', :asset_id => @attachment.to_param)
          expect(json['items'][0]['next']['id']).to eq @new_assignment_2_tag.id
          expect(json['modules'].map { |item| item['id'] }.sort).to eq [@module2.id, @module4.id].sort

          json = api_call(:get, "/api/v1/courses/#{@course.id}/module_item_sequence?asset_type=Assignment&asset_id=#{@new_assignment_2.id}",
                          :controller => "context_module_items_api", :action => "item_sequence", :format => "json",
                          :course_id => @course.to_param, :asset_type => 'Assignment', :asset_id => @new_assignment_2.to_param)
          expect(json['items'][0]['prev']['id']).to eq @attachment_tag.id
          expect(json['modules'].map { |item| item['id'] }.sort).to eq [@module2.id, @module4.id].sort
        end
      end
    end

    describe 'POST select_mastery_path' do
      before do
        ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
        ConditionalRelease::Service.stubs(:select_mastery_path).returns({ code: '200', body: { 'assignments' => [] } })
      end

      it 'should allow a mastery path' do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}/select_mastery_path",
                        { controller: "context_module_items_api", action: 'select_mastery_path', format: 'json',
                          course_id: "#{@course.id}", module_id: "#{@module1.id}", id: "#{@assignment_tag.id}" },
                        { assignment_set_id: 100 },
                        {},
                        {:expected_status => 200})

      end

      it 'should allow specifying own student id' do
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}/select_mastery_path",
                        { controller: "context_module_items_api", action: 'select_mastery_path', format: 'json',
                          course_id: "#{@course.id}", module_id: "#{@module1.id}", id: "#{@assignment_tag.id}" },
                        { student_id: @student.id, assignment_set_id: 100 },
                        {},
                        {:expected_status => 200})
      end

      it 'should not allow selecting another student' do
        other_student = @student
        student_in_course(course: @course) # reassigns @student, @user
        json = api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}/select_mastery_path",
                        { controller: "context_module_items_api", action: 'select_mastery_path', format: 'json',
                          course_id: "#{@course.id}", module_id: "#{@module1.id}", id: "#{@assignment_tag.id}" },
                        { student_id: other_student.id, assignment_set_id: 100 },
                        {},
                        {:expected_status => 401})
      end
    end
  end

  context "unauthorized user" do
    before :once do
      user_factory
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
      ConditionalRelease::Service.stubs(:enabled_in_context?).returns(true)
      api_call(:post, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}/select_mastery_path",
               {:controller => "context_module_items_api", :action => "select_mastery_path", :format => "json",
                :course_id => "#{@course.id}", :module_id => "#{@module1.id}", :id => "#{@assignment_tag.id}"},
               { assignment_set_id: 100 },
               {},
               {:expected_status => 401}
      )
    end
  end
end
