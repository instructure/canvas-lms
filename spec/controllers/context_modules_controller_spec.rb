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

describe ContextModulesController do
  describe "GET 'index'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "should require authorization" do
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      user_session(@student)
      @course.update_attribute(:tab_configuration, [{'id'=>10,'hidden'=>true}])
      get 'index', :course_id => @course.id
      expect(response).to be_redirect
      expect(flash[:notice]).to match(/That page has been disabled/)
    end
    
    it "should assign variables" do
      user_session(@student)
      get 'index', :course_id => @course.id
      expect(response).to be_success
    end

    context "unpublished modules" do
      before :once do
        @m1 = @course.context_modules.create(:name => "unpublished oi")
        @m1.workflow_state = 'unpublished'
        @m1.save!
        @m2 = @course.context_modules.create!(:name => "published hey")
      end

      it "should show all modules for teachers" do
        user_session(@teacher)
        get 'index', :course_id => @course.id
        expect(assigns[:modules]).to eq [@m1, @m2]
      end

      it "should not show unpublished for students" do
        user_session(@student)
        get 'index', :course_id => @course.id
        expect(assigns[:modules]).to eq [@m2]
      end
    end

  end

  describe "PUT 'update'" do
    before :once do
      course_with_teacher(:active_all => true)
      @m1 = @course.context_modules.create(:name => "unpublished")
      @m1.workflow_state = 'unpublished'
      @m1.save!
      @m2 = @course.context_modules.create!(:name => "published")
    end

    before :each do
      user_session(@teacher)
    end

    it "should publish modules" do
      put 'update', :course_id => @course.id, :id => @m1.id, :publish => '1'
      @m1.reload
      expect(@m1.active?).to eq true
    end

    it "should unpublish modules" do
      put 'update', :course_id => @course.id, :id => @m2.id, :unpublish => '1'
      @m2.reload
      expect(@m2.unpublished?).to eq true
    end

    it "should update the name" do
      put 'update', :course_id => @course.id, :id => @m1.id, :context_module => {:name => "new name"}
      @m1.reload
      expect(@m1.name).to eq "new name"
    end
  end

  describe "GET 'module_redirect'" do
    it "should skip leading and trailing sub-headers" do
      course_with_student_logged_in(:active_all => true)
      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(:context => @course)
      assignment2 = ag.assignments.create!(:context => @course)

      header1 = @module.add_item :type => 'context_module_sub_header'
      assignmentTag1 = @module.add_item :type => 'assignment', :id => assignment1.id
      assignmentTag2 = @module.add_item :type => 'assignment', :id => assignment2.id
      header2 = @module.add_item :type => 'context_module_sub_header'

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :first => 1, :use_route => :course_context_module_first_redirect
      expect(response).to redirect_to course_assignment_url(@course.id, assignment1.id, :module_item_id => assignmentTag1.id)

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :last => 1, :use_route => :course_context_module_last_redirect
      expect(response).to redirect_to course_assignment_url(@course.id, assignment2.id, :module_item_id => assignmentTag2.id)

      assignmentTag1.destroy
      assignmentTag2.destroy

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :first => 1, :use_route => :course_context_module_first_redirect
      expect(response).to redirect_to course_context_modules_url(@course.id, :anchor => "module_#{@module.id}")

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :last => 1, :use_route => :course_context_module_last_redirect
      expect(response).to redirect_to course_context_modules_url(@course.id, :anchor => "module_#{@module.id}")
    end
  end
  
  describe "GET 'item_redirect'" do
    before :once do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true)
    end

    it "should require authorization" do
      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(:context => @course)

      assignmentTag1 = @module.add_item :type => 'assignment', :id => assignment1.id
      
      get 'item_redirect', :course_id => @course.id, :id => assignmentTag1.id
      assert_unauthorized
    end

    it "should still redirect for unpublished modules if teacher" do
      user_session(@teacher)

      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(:context => @course)

      assignmentTag1 = @module.add_item :type => 'assignment', :id => assignment1.id

      assignmentTag1.unpublish

      get 'item_redirect', :course_id => @course.id, :id => assignmentTag1.id
      expect(response).to be_redirect
      expect(response).to redirect_to course_assignment_url(@course, assignment1, :module_item_id => assignmentTag1.id)
    end

    it "should not redirect for unpublished modules if student" do
      user_session(@student)

      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(:context => @course)

      assignmentTag1 = @module.add_item :type => 'assignment', :id => assignment1.id

      assignmentTag1.unpublish

      get 'item_redirect', :course_id => @course.id, :id => assignmentTag1.id
      assert_unauthorized
    end

    context 'ContextExternalTool' do
      it "should find a matching tool" do
        user_session(@student)

        @module = @course.context_modules.create!
        @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
        @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

        tag1 = @module.add_item :type => 'context_external_tool', :id => @tool1.id, :url => @tool1.url
        expect(tag1.content_id).to eq @tool1.id
        tag1.publish if tag1.unpublished?
        tag2 = @module.add_item :type => 'context_external_tool', :id => @tool2.id, :url => @tool2.url
        expect(tag2.content_id).to eq @tool2.id
        tag2.publish if tag2.unpublished?

        get 'item_redirect', :course_id => @course.id, :id => tag1.id
        expect(response).not_to be_redirect
        expect(assigns[:tool]).to eq @tool1

        get 'item_redirect', :course_id => @course.id, :id => tag2.id
        expect(response).not_to be_redirect
        expect(assigns[:tool]).to eq @tool2
      end

      it "generate lti params" do
        user_session(@student)

        @module = @course.context_modules.create!
        @tool = @course.context_external_tools.create!(
            :name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret',
            custom_fields: {'canvas_module_id' => '$Canvas.module.id', 'canvas_module_item_id' => '$Canvas.moduleItem.id'}
        )

        tag = @module.add_item :type => 'context_external_tool', :id => @tool.id, :url => @tool.url
        tag.publish if tag.unpublished?

        get 'item_redirect', :course_id => @course.id, :id => tag.id
        lti_launch = assigns[:lti_launch]
        expect(lti_launch.params['custom_canvas_module_id']).to eq @module.id.to_s
        expect(lti_launch.params['custom_canvas_module_item_id']).to eq tag.id.to_s
      end

      it "should fail if there is no matching tool" do
        user_session(@student)

        @module = @course.context_modules.create!
        @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

        tag1 = @module.add_item :type => 'context_external_tool', :id => @tool1.id, :url => @tool1.url
        tag1.publish if tag1.unpublished?
        @tool1.update_attribute(:url, 'http://www.example.com')

        get 'item_redirect', :course_id => @course.id, :id => tag1.id
        expect(response).to be_redirect
        expect(assigns[:tool]).to eq nil
      end
    end
    
    it "should redirect to an assignment page" do
      user_session(@student)
      
      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(:context => @course)

      assignmentTag1 = @module.add_item :type => 'assignment', :id => assignment1.id
      
      get 'item_redirect', :course_id => @course.id, :id => assignmentTag1.id
      expect(response).to be_redirect
      expect(response).to redirect_to course_assignment_url(@course, assignment1, :module_item_id => assignmentTag1.id)
    end
    
    it "should redirect to a discussion page" do
      user_session(@student)
      
      @module = @course.context_modules.create!
      topic = @course.discussion_topics.create!

      topicTag = @module.add_item :type => 'discussion_topic', :id => topic.id
      
      get 'item_redirect', :course_id => @course.id, :id => topicTag.id
      expect(response).to be_redirect
      expect(response).to redirect_to course_discussion_topic_url(@course, topic, :module_item_id => topicTag.id)
    end
    
    it "should redirect to a quiz page" do
      user_session(@student)
      
      @module = @course.context_modules.create!
      quiz = @course.quizzes.create!
      quiz.publish!

      tag = @module.add_item :type => 'quiz', :id => quiz.id
      tag.publish if tag.unpublished?

      get 'item_redirect', :course_id => @course.id, :id => tag.id
      expect(response).to be_redirect
      expect(response).to redirect_to course_quiz_url(@course, quiz, :module_item_id => tag.id)
    end

    it "should mark an external url item read" do
      user_session(@student)
      @module = @course.context_modules.create!
      tag = @module.add_item :type => 'external_url', :url => 'http://lolcats', :title => 'lol'
      tag.publish if tag.unpublished?
      @module.completion_requirements = { tag.id => { :type => 'must_view' }}
      @module.save!
      expect(@module.evaluate_for(@user)).to be_unlocked
      get 'item_redirect', :course_id => @course.id, :id => tag.id
      requirements_met = @module.evaluate_for(@user).requirements_met
      expect(requirements_met[0][:type]).to eq 'must_view'
      expect(requirements_met[0][:id]).to eq tag.id
    end

    it "should not mark a locked external url item read" do
      user_session(@student)
      @module = @course.context_modules.create! :unlock_at => 1.week.from_now
      tag = @module.add_item :type => 'external_url', :url => 'http://lolcats', :title => 'lol'
      @module.completion_requirements = { tag.id => { :type => 'must_view' }}
      @module.save!
      expect(@module.evaluate_for(@user)).to be_locked
      get 'item_redirect', :course_id => @course.id, :id => tag.id
      expect(@module.evaluate_for(@user).requirements_met).to be_blank
    end

    it "should not mark a locked external url item read" do
      user_session(@student)
      @module = @course.context_modules.create!
      @module.unpublish
      tag = @module.add_item :type => 'external_url', :url => 'http://lolcats', :title => 'lol'
      @module.completion_requirements = { tag.id => { :type => 'must_view' }}
      @module.save!
      expect(@module.evaluate_for(@user)).to be_locked
      get 'item_redirect', :course_id => @course.id, :id => tag.id
      expect(@module.evaluate_for(@user).requirements_met).to be_blank
    end

  end
  
  describe "POST 'reorder_items'" do
    def make_content_tag(assignment, course, mod)
      ct = ContentTag.new
      ct.content_id = assignment.id
      ct.content_type = 'Assignment'
      ct.context_id = course.id
      ct.context_type = 'Course'
      ct.title = "Assignment #{assignment.id}"
      ct.tag_type = "context_module"
      ct.context_module_id = mod.id
      ct.context_code = "course_#{course.id}"
      ct.save!
      ct
    end

    it "should reorder items" do
      course_with_teacher_logged_in(:active_all => true)

      ag = @course.assignment_groups.create!
      a1 = ag.assignments.create!(:context => @course)
      a1.points_possible = 10
      a1.save
      a2 = ag.assignments.create!(:context => @course)
      m1 = @course.context_modules.create!
      m2 = @course.context_modules.create!

      ct1 = make_content_tag(a1, @course, m1)
      ct2 = make_content_tag(a2, @course, m1)

      post 'reorder_items', :course_id => @course.id, :context_module_id => m2.id, :order => "#{ct2.id}"
      ct2.reload
      expect(ct2.context_module).to eq m2
      ct1.reload
      expect(ct1.context_module).to eq m1
    end

    it "should reorder unpublished items" do
      course_with_teacher_logged_in(active_all: true, draft_state: true)
      pageA = @course.wiki.wiki_pages.create title: "pageA"
      pageA.workflow_state = 'unpublished'
      pageA.save
      pageB = @course.wiki.wiki_pages.create! title: "pageB"
      m1 = @course.context_modules.create!
      tagB = m1.add_item({type: "wiki_page", id: pageB.id}, nil, position: 1)
      expect(tagB).to be_published
      tagA = m1.add_item({type: "wiki_page", id: pageA.id}, nil, position: 2)
      expect(tagA).to be_unpublished
      expect(m1.reload.content_tags.order(:position).pluck(:id)).to eq [tagB.id, tagA.id]
      post 'reorder_items', course_id: @course.id, context_module_id: m1.id, order: "#{tagA.id},#{tagB.id}"
      expect(m1.reload.content_tags.order(:position).pluck(:id)).to eq [tagA.id, tagB.id]
    end

    it "should only touch module once on reorder" do
      course_with_teacher_logged_in(:active_all => true)
      assign_group = @course.assignment_groups.create!
      mod = @course.context_modules.create!

      tags = []
      5.times do
        assign = assign_group.assignments.create!(:context => @course)
        tags << make_content_tag(assign, @course, mod)
      end

      ContentTag.expects(:touch_context_modules).once
      order = tags.reverse.map(&:id)
      post 'reorder_items', :course_id => @course.id, :context_module_id => mod.id, :order => order.join(",")
      expect(mod.reload.content_tags.map(&:id)).to eq order
    end
  end

  describe "PUT 'update_item'" do
    before :once do
      course_with_teacher(:active_all => true)
      @module = @course.context_modules.create!
      @assignment = @course.assignments.create! :title => 'An Assignment'
      @assignment_item = @module.add_item :type => 'assignment', :id => @assignment.id
      @external_url_item = @module.add_item :type => 'external_url', :title => 'Example URL', :url => 'http://example.org'
      @external_tool_item = @module.add_item :type => 'context_external_tool', :title => 'Example Tool', :url => 'http://example.com/tool'
    end

    before :each do
      user_session(@teacher)
    end

    it "should update the tag title" do
      put 'update_item', :course_id => @course.id, :id => @assignment_item.id, :content_tag => { :title => 'New Title' }
      expect(@assignment_item.reload.title).to eq 'New Title'
    end

    it "should update the asset title" do
      put 'update_item', :course_id => @course.id, :id => @assignment_item.id, :content_tag => { :title => 'New Title' }
      expect(@assignment.reload.title).to eq 'New Title'
    end

    it "should update indent" do
      put 'update_item', :course_id => @course.id, :id => @external_url_item.id, :content_tag => { :indent => 2 }
      expect(@external_url_item.reload.indent).to eq 2
    end

    it "should update the url for an external url item" do
      new_url = 'http://example.org/new_url'
      put 'update_item', :course_id => @course.id, :id => @external_url_item.id, :content_tag => { :url => new_url }
      expect(@external_url_item.reload.url).to eq new_url
    end

    it "should update the url for an external tool item" do
      new_url = 'http://example.org/new_tool'
      put 'update_item', :course_id => @course.id, :id => @external_tool_item.id, :content_tag => { :url => new_url }
      expect(@external_tool_item.reload.url).to eq new_url
    end

    it "should ignore the url for a non-applicable type" do
      put 'update_item', :course_id => @course.id, :id => @assignment_item.id, :content_tag => { :url => 'http://example.org/new_tool' }
      expect(@assignment_item.reload.url).to be_nil
    end
  end

  describe "GET item_details" do
    before :once do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @m1 = @course.context_modules.create!(:name => "first module")
      @m1.publish
      @m2 = @course.context_modules.create(:name => "middle foo")
      @m2.workflow_state = 'unpublished'
      @m2.save!
      @m3 = @course.context_modules.create!(:name => "last module")
      @m3.publish

      @topic = @course.discussion_topics.create!
      @topicTag = @m1.add_item :type => 'discussion_topic', :id => @topic.id
    end

    it "should show unpublished modules for teachers" do
      user_session(@teacher)
      get 'item_details', :course_id => @course.id, :module_item_id => @topicTag.id, :id => "discussion_topic_#{@topic.id}"
      json = JSON.parse response.body.gsub("while(1);",'')
      expect(json["next_module"]["context_module"]["id"]).to eq @m2.id
    end

    it "should skip unpublished modules for students" do
      user_session(@student)
      get 'item_details', :course_id => @course.id, :module_item_id => @topicTag.id, :id => "discussion_topic_#{@topic.id}"
      json = JSON.parse response.body.gsub("while(1);",'')
      expect(json["next_module"]["context_module"]["id"]).to eq @m3.id
    end

    it "should parse namespaced quiz as id" do
      user_session(@teacher)
      quiz = @course.quizzes.create!
      quiz.publish!

      quiz_tag = @m2.add_item :type => 'quiz', :id => quiz.id

      get 'item_details', :course_id => @course.id, :module_item_id => quiz_tag.id, :id => "quizzes:quiz_#{quiz.id}"
      json = JSON.parse response.body.gsub("while(1);",'')
      expect(json['current_item']['content_tag']['content_type']).to eq 'Quizzes::Quiz'
    end
  end
  
  describe "GET progressions" do
    before :once do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @module = @course.context_modules.create!(:name => "first module")
      @module.publish
      @wiki = @course.wiki.wiki_pages.create!(:title => "wiki", :body => 'hi')
      
      @tag = @module.add_item(:id => @wiki.id, :type => 'wiki_page')
      @module.completion_requirements = {@tag.id => {:type => 'must_view'}}
    end

    before :each do
      @progression = @module.update_for(@student, :read, @tag)
    end
    
    it "should return all student progressions to teacher" do
      user_session(@teacher)
      get 'progressions', :course_id => @course.id, :format => "json"
      json = JSON.parse response.body.gsub("while(1);",'')
      expect(json.length).to eq 1
    end
    
    it "should return a single student progression" do
      user_session(@student)
      get 'progressions', :course_id => @course.id, :format => "json"
      json = JSON.parse response.body.gsub("while(1);",'')
      expect(json.length).to eq 1
    end
    
    context "with large_roster" do
      before :once do
        @course.large_roster = true
        @course.save!
      end
      
      it "should return a single student progression" do
        user_session(@student)
        get 'progressions', :course_id => @course.id, :format => "json"
        json = JSON.parse response.body.gsub("while(1);",'')
        expect(json.length).to eq 1
      end
      
      it "should not return any student progressions to teacher" do
        user_session(@teacher)
        get 'progressions', :course_id => @course.id, :format => "json"
        json = JSON.parse response.body.gsub("while(1);",'')
        expect(json.length).to eq 0
      end
    end
  end

  describe "GET assignment_info" do
    it "should return updated due dates/points possible" do
      Timecop.freeze(1.minute.ago) do
        course_with_student_logged_in active_all: true
        @mod = @course.context_modules.create!
        @assign = @course.assignments.create! title: "WHAT", points_possible: 123
        @tag = @mod.add_item(type: 'assignment', id: @assign.id)
      end
      enable_cache do
        get 'content_tag_assignment_data', course_id: @course.id, format: 'json' # precache
        @assign.points_possible = 456
        @assign.save!
        get 'content_tag_assignment_data', course_id: @course.id, format: 'json'
        json = JSON.parse response.body.gsub("while(1);",'')
        expect(json[@tag.id.to_s]["points_possible"].to_i).to eql 456
      end
    end
  end
end
