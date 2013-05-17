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

describe "Modules API", :type => :integration do
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

    it "should list published and unpublished modules" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules",
                      :controller => "context_modules_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}")
      json.should == [
          {
             "name" => @module1.name,
             "unlock_at" => nil,
             "position" => 1,
             "require_sequential_progress" => false,
             "prerequisite_module_ids" => [],
             "id" => @module1.id,
             "workflow_state" => "active"
          },
          {
             "name" => @module2.name,
             "unlock_at" => @christmas.as_json,
             "position" => 2,
             "require_sequential_progress" => true,
             "prerequisite_module_ids" => [@module1.id],
             "id" => @module2.id,
             "workflow_state" => "active"
          },
          {
             "name" => @module3.name,
             "unlock_at" => nil,
             "position" => 3,
             "require_sequential_progress" => false,
             "prerequisite_module_ids" => [],
             "id" => @module3.id,
             "workflow_state" => "unpublished"
          }
      ]
    end

    it "should show a single module" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module2.id}")
      json.should == {
        "name" => @module2.name,
        "unlock_at" => @christmas.as_json,
        "position" => 2,
        "require_sequential_progress" => true,
        "prerequisite_module_ids" => [@module1.id],
        "id" => @module2.id,
        "workflow_state" => "active"
      }
    end

    it "should show a single unpublished module" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module3.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => @module3.id.to_param)
      json.should == {
        "name" => @module3.name,
        "unlock_at" => nil,
        "position" => 3,
        "require_sequential_progress" => false,
        "prerequisite_module_ids" => [],
        "id" => @module3.id,
        "workflow_state" => "unpublished"
      }
    end

    it "should list module items" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
                      :controller => "context_modules_api", :action => "list_module_items", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}")
      json.should eql [
          {
              "type" => "Assignment",
              "id" => @assignment_tag.id,
              "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@assignment_tag.id}",
              "position" => 1,
              "url" => "http://www.example.com/api/v1/courses/#{@course.id}/assignments/#{@assignment.id}",
              "title" => @assignment_tag.title,
              "indent" => 0,
              "completion_requirement" => { "type" => "must_submit" }
          },
          {
              "type" => "Quiz",
              "id" => @quiz_tag.id,
              "position" => 2,
              "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@quiz_tag.id}",
              "url" => "http://www.example.com/api/v1/courses/#{@course.id}/quizzes/#{@quiz.id}",
              "title" => @quiz_tag.title,
              "indent" => 0,
              "completion_requirement" => { "type" => "min_score", "min_score" => 10 }
          },
          {
              "type" => "Discussion",
              "id" => @topic_tag.id,
              "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@topic_tag.id}",
              "position" => 3,
              "url" => "http://www.example.com/api/v1/courses/#{@course.id}/discussion_topics/#{@topic.id}",
              "title" => @topic_tag.title,
              "indent" => 0,
              "completion_requirement" => { "type" => "must_contribute" }
          },
          {
              "type" => "SubHeader",
              "id" => @subheader_tag.id,
              "position" => 4,
              "title" => @subheader_tag.title,
              "indent" => 0
          },
          {
              "type" => "ExternalUrl",
              "id" => @external_url_tag.id,
              "html_url" => "http://www.example.com/api/v1/courses/#{@course.id}/module_item_redirect/#{@external_url_tag.id}",
              "position" => 5,
              "title" => @external_url_tag.title,
              "indent" => 1,
              "completion_requirement" => { "type" => "must_view" }
          }
      ]
    end

    it "should show module items individually" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@wiki_page_tag.id}",
                      :controller => "context_modules_api", :action => "show_module_item", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                      :id => "#{@wiki_page_tag.id}")
      json.should == {
        "type" => "Page",
        "id" => @wiki_page_tag.id,
        "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@wiki_page_tag.id}",
        "position" => 1,
        "title" => @wiki_page_tag.title,
        "indent" => 0,
        "url" => "http://www.example.com/api/v1/courses/#{@course.id}/pages/#{@wiki_page.url}"
      }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@attachment_tag.id}",
                      :controller => "context_modules_api", :action => "show_module_item", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                      :id => "#{@attachment_tag.id}")
      json.should == {
        "type" => "File",
        "id" => @attachment_tag.id,
        "html_url" => "http://www.example.com/courses/#{@course.id}/modules/items/#{@attachment_tag.id}",
        "position" => 2,
        "title" => @attachment_tag.title,
        "indent" => 0,
        "url" => "http://www.example.com/api/v1/files/#{@attachment.id}"
      }
    end

    it "should paginate the module list" do
      # 3 modules already exist
      2.times { |i| @course.context_modules.create!(:name => "spurious module #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?per_page=3",
                      :controller => "context_modules_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :per_page => "3")
      response.headers["Link"].should be_present
      json.size.should == 3
      ids = json.collect{ |mod| mod['id'] }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules?per_page=3&page=2",
                      :controller => "context_modules_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}", :page => "2", :per_page => "3")
      json.size.should == 2
      ids += json.collect{ |mod| mod['id'] }

      ids.should == @course.context_modules.not_deleted.sort_by(&:position).collect(&:id)
    end

    it "should paginate the module item list" do
      module3 = @course.context_modules.create!(:name => "module with lots of items")
      4.times { |i| module3.add_item(:type => 'context_module_sub_header', :title => "item #{i}") }
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{module3.id}/items?per_page=2",
                      :controller => "context_modules_api", :action => "list_module_items", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{module3.id}", :per_page => "2")
      response.headers["Link"].should be_present
      json.size.should == 2
      ids = json.collect{ |tag| tag['id'] }

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{module3.id}/items?per_page=2&page=2",
                      :controller => "context_modules_api", :action => "list_module_items", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{module3.id}", :page => "2", :per_page => "2")
      json.size.should == 2
      ids += json.collect{ |tag| tag['id'] }

      ids.should == module3.content_tags.sort_by(&:position).collect(&:id)
    end

    describe "batch update" do
      before do
        @path = "/api/v1/courses/#{@course.id}/modules"
        @path_opts = { :controller => "context_modules_api", :action => "batch_update", :format => "json",
                       :course_id => @course.to_param }
        @test_modules = (1..4).map { |x| @course.context_modules.create! :name => "test module #{x}" }
        @test_modules[2..3].each { |m| m.update_attribute(:workflow_state , 'unpublished') }
        @test_modules.map { |tm| tm.workflow_state }.should == %w(active active unpublished unpublished)
        @modules_to_update = [@test_modules[1], @test_modules[3]]
        @ids_to_update = @modules_to_update.map(&:id)
      end
      
      it "should publish modules" do
        json = api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update })
        json['completed'].sort.should == @ids_to_update
        @test_modules.map { |tm| tm.reload.workflow_state }.should == %w(active active unpublished active)
      end

      it "should unpublish modules" do
        json = api_call(:put, @path, @path_opts, { :event => 'unpublish', :module_ids => @ids_to_update })
        json['completed'].sort.should == @ids_to_update
        @test_modules.map { |tm| tm.reload.workflow_state }.should == %w(active unpublished unpublished unpublished)
      end

      it "should delete modules" do
        json = api_call(:put, @path, @path_opts, { :event => 'delete', :module_ids => @ids_to_update })
        json['completed'].sort.should == @ids_to_update
        @test_modules.map { |tm| tm.reload.workflow_state }.should == %w(active deleted unpublished deleted)
      end

      it "should convert module ids to integer and ignore non-numeric ones" do
        json = api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => %w(lolcats abc123) + @ids_to_update.map(&:to_s) })
        json['completed'].sort.should == @ids_to_update
        @test_modules.map { |tm| tm.reload.workflow_state }.should == %w(active active unpublished active)
      end
      
      it "should not update soft-deleted modules" do
        @modules_to_update.each { |m| m.destroy }
        api_call(:put, @path, @path_opts, { :event => 'delete', :module_ids => @ids_to_update },
                 {}, { :expected_status => 404 })
      end

      it "should 404 if no modules exist with the given ids" do
        @modules_to_update.each { |m| m.destroy! }
        api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update },
                 {}, { :expected_status => 404 })
      end
      
      it "should 404 if only non-numeric ids are given" do
        api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update.map { |id| id.to_s + "abc" } },
                 {}, { :expected_status => 404})
      end

      it "should succeed if only some ids don't exist" do
        @modules_to_update.first.destroy!
        json = api_call(:put, @path, @path_opts, { :event => 'publish', :module_ids => @ids_to_update })
        json['completed'].should == [@modules_to_update.last.id]
        @modules_to_update.last.reload.should be_active
      end
      
      it "should 400 if :module_ids is missing" do
        api_call(:put, @path, @path_opts, { :event => 'publish' }, {}, { :expected_status => 400 })
      end

      it "should 400 if :event is missing" do
        api_call(:put, @path, @path_opts, { :module_ids => @ids_to_update }, {}, { :expected_status => 400 })
      end

      it "should 400 if :event is invalid" do
        api_call(:put, @path, @path_opts, { :event => 'burninate', :module_ids => @ids_to_update },
                 {}, { :expected_status => 400 })
      end

      it "should scope to the course" do
        other_course = Course.create! :name => "Other Course"
        other_module = other_course.context_modules.create! :name => "Other Module"
        
        json = api_call(:put, @path, @path_opts, { :event => 'unpublish',
          :module_ids => [@test_modules[1].id, other_module.id] })
        json['completed'].should == [@test_modules[1].id]

        @test_modules[1].reload.should be_unpublished
        other_module.reload.should be_active
      end
    end

  end
  
  context "as a student" do
    before :each do
      course_with_student_logged_in(:course => @course, :active_all => true)
    end

    it "should show locked state" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module2.id}")
      json['state'].should == 'locked'
    end

    it "should list module items" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
        :controller => "context_modules_api", :action => "list_module_items", :format => "json",
        :course_id => "#{@course.id}", :module_id => "#{@module1.id}")

      json.map{|item| item['id']}.sort.should == @module1.content_tags.map(&:id).sort

      #also for locked modules that have completion requirements
      @assignment2 = @course.assignments.create!(:name => "pls submit", :submission_types => ["online_text_entry"])
      @assignment_tag2 = @module2.add_item(:id => @assignment2.id, :type => 'assignment')
      @module2.completion_requirements = {
          @assignment_tag2.id => { :type => 'must_submit' }}
      @module2.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items",
        :controller => "context_modules_api", :action => "list_module_items", :format => "json",
        :course_id => "#{@course.id}", :module_id => "#{@module2.id}")

      json.map{|item| item['id']}.sort.should == @module2.content_tags.map(&:id).sort
    end

    it "should show module progress" do
      # to simplify things, eliminate the requirements on the quiz and discussion topic for this test
      @module1.completion_requirements.reject! {|r| [@quiz_tag.id, @topic_tag.id].include? r[:id]}
      @module1.save!

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module1.id}")
      json['state'].should == 'unlocked'

      @assignment.submit_homework(@user, :body => "done!")
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module1.id}")
      json['state'].should == 'started'
      json['completed_at'].should be_nil

      @external_url_tag.context_module_action(@user, :read)
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}",
                      :controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => "#{@module1.id}")
      json['state'].should == 'completed'
      json['completed_at'].should_not be_nil
    end

    it "should not list unpublished modules" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules",
                      :controller => "context_modules_api", :action => "index", :format => "json",
                      :course_id => "#{@course.id}")
      json.length.should == 2
      json.each{|cm| cm['workflow_state'].should == 'active'}
    end

    it "should not show a single unpublished module" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module3.id}",
                      {:controller => "context_modules_api", :action => "show", :format => "json",
                      :course_id => "#{@course.id}", :id => @module3.id.to_param},{},{}, {:expected_status => 404})
    end

    it "should show module item completion" do
      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                      :controller => "context_modules_api", :action => "show_module_item", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}")
      json['completion_requirement']['type'].should == 'must_submit'
      json['completion_requirement']['completed'].should be_false

      @assignment.submit_homework(@user, :body => "done!")

      json = api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items/#{@assignment_tag.id}",
                      :controller => "context_modules_api", :action => "show_module_item", :format => "json",
                      :course_id => "#{@course.id}", :module_id => "#{@module1.id}",
                      :id => "#{@assignment_tag.id}")
      json['completion_requirement']['completed'].should be_true
    end

    it "should mark viewed and redirect external URLs" do
      raw_api_call(:get, "/api/v1/courses/#{@course.id}/module_item_redirect/#{@external_url_tag.id}",
                   :controller => "context_modules_api", :action => "module_item_redirect",
                   :format => "json", :course_id => "#{@course.id}", :id => "#{@external_url_tag.id}")
      response.should redirect_to "http://example.com/lolcats"
      @module1.evaluate_for(@user).requirements_met.should be_any {
          |rm| rm[:type] == "must_view" && rm[:id] == @external_url_tag.id }
    end

    describe "batch update" do
      it "should disallow deleting" do
        api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=delete&module_ids[]=#{@module1.id}",
                 { :controller => "context_modules_api", :action => "batch_update", :event => 'delete',
                   :module_ids => [@module1.to_param], :format => "json", :course_id => "#{@course.id}"},
                 {}, {}, { :expected_status => 401 })
      end

      it "should disallow publishing" do
        api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=publish&module_ids[]=#{@module1.id}",
                 { :controller => "context_modules_api", :action => "batch_update", :event => 'publish',
                   :module_ids => [@module1.to_param], :format => "json", :course_id => "#{@course.id}"},
                 {}, {}, { :expected_status => 401 })
      end

      it "should disallow unpublishing" do
        api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=unpublish&module_ids[]=#{@module1.id}",
                 { :controller => "context_modules_api", :action => "batch_update", :event => 'unpublish',
                   :module_ids => [@module1.to_param], :format => "json", :course_id => "#{@course.id}"},
                 {}, {}, { :expected_status => 401 })
      end
    end
  end

  context "unauthorized user" do
    before do
      user
    end

    it "should check permissions" do
      api_call(:get, "/api/v1/courses/#{@course.id}/modules",
               { :controller => "context_modules_api", :action => "index", :format => "json",
                 :course_id => "#{@course.id}"}, {}, {}, {:expected_status => 401})
      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}",
               { :controller => "context_modules_api", :action => "show", :format => "json",
                 :course_id => "#{@course.id}", :id => "#{@module2.id}"},
               {}, {}, {:expected_status => 401})
      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module1.id}/items",
               { :controller => "context_modules_api", :action => "list_module_items", :format => "json",
                 :course_id => "#{@course.id}", :module_id => "#{@module1.id}"},
               {}, {}, { :expected_status => 401 })
      api_call(:get, "/api/v1/courses/#{@course.id}/modules/#{@module2.id}/items/#{@attachment_tag.id}",
               { :controller => "context_modules_api", :action => "show_module_item", :format => "json",
                 :course_id => "#{@course.id}", :module_id => "#{@module2.id}",
                 :id => "#{@attachment_tag.id}"}, {}, {}, { :expected_status => 401 })
      api_call(:get, "/api/v1/courses/#{@course.id}/module_item_redirect/#{@external_url_tag.id}",
               { :controller => "context_modules_api", :action => "module_item_redirect",
                 :format => "json", :course_id => "#{@course.id}", :id => "#{@external_url_tag.id}"},
               {}, {}, { :expected_status => 401 })
      api_call(:put, "/api/v1/courses/#{@course.id}/modules?event=publish&module_ids[]=1",
               { :controller => "context_modules_api", :action => "batch_update", :event => 'publish',
                 :module_ids => %w(1), :format => "json", :course_id => "#{@course.id}"},
               {}, {}, { :expected_status => 401 })
    end
  end
end
