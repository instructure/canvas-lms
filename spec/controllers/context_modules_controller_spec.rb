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
    it "should require authorization" do
      course_with_student(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should redirect 'disabled', if disabled by the teacher" do
      course_with_student_logged_in(:active_all => true)
      @course.update_attribute(:tab_configuration, [{'id'=>10,'hidden'=>true}])
      get 'index', :course_id => @course.id
      response.should be_redirect
      flash[:notice].should match(/That page has been disabled/)
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      get 'index', :course_id => @course.id
      response.should be_success
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

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :first => 1
      response.should redirect_to course_assignment_url(@course.id, assignment1.id)

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :last => 1
      response.should redirect_to course_assignment_url(@course.id, assignment2.id)

      assignmentTag1.destroy
      assignmentTag2.destroy

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :first => 1
      response.should redirect_to course_context_modules_url(@course.id, :anchor => "module_#{@module.id}")

      get 'module_redirect', :course_id => @course.id, :context_module_id => @module.id, :last => 1
      response.should redirect_to course_context_modules_url(@course.id, :anchor => "module_#{@module.id}")
    end
  end
  
  describe "GET 'item_redirect'" do
    it "should require authorization" do
      course_with_student
      
      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(:context => @course)

      assignmentTag1 = @module.add_item :type => 'assignment', :id => assignment1.id
      
      get 'item_redirect', :course_id => @course.id, :id => assignmentTag1.id
      assert_unauthorized
    end
    
    it "should find a matching tool" do
      course_with_student_logged_in(:active_all => true)
      
      @module = @course.context_modules.create!
      @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool2 = @course.context_external_tools.create!(:name => "b", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

      tag1 = @module.add_item :type => 'context_external_tool', :id => @tool1.id, :url => @tool1.url
      tag1.content_id.should == @tool1.id
      tag2 = @module.add_item :type => 'context_external_tool', :id => @tool2.id, :url => @tool2.url
      tag2.content_id.should == @tool2.id
      
      get 'item_redirect', :course_id => @course.id, :id => tag1.id
      response.should_not be_redirect
      assigns[:tool].should == @tool1
      
      get 'item_redirect', :course_id => @course.id, :id => tag2.id
      response.should_not be_redirect
      assigns[:tool].should == @tool2
    end
    
    it "should find the preferred tool even if the url is different, but only if the url was inserted as part of a resourse_selection directive" do
      course_with_student_logged_in(:active_all => true)
      @module = @course.context_modules.create!
      @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')
      @tool1.settings[:resource_selection] = {:url => "http://www.google.com", :selection_width => 400, :selection_height => 400}
      @tool1.save!

      tag1 = @module.add_item :type => 'context_external_tool', :id => @tool1.id, :url => "http://www.yahoo.com"
      tag1.content_id.should == @tool1.id

      get "item_redirect", :course_id => @course.id, :id => tag1.id
      response.should be_success
      assigns[:tool].should == @tool1
      
      @tool1.settings.delete :resource_selection
      @tool1.save!
      get "item_redirect", :course_id => @course.id, :id => tag1.id
      response.should be_redirect
      assigns[:tool].should == nil
    end
    
    it "should fail if there is no matching tool" do
      course_with_student_logged_in(:active_all => true)
      
      @module = @course.context_modules.create!
      @tool1 = @course.context_external_tools.create!(:name => "a", :url => "http://www.google.com", :consumer_key => '12345', :shared_secret => 'secret')

      tag1 = @module.add_item :type => 'context_external_tool', :id => @tool1.id, :url => @tool1.url
      @tool1.update_attribute(:url, 'http://www.example.com')
      
      get 'item_redirect', :course_id => @course.id, :id => tag1.id
      response.should be_redirect
      assigns[:tool].should == nil
    end
    
    it "should redirect to an assignment page" do
      course_with_student_logged_in(:active_all => true)
      
      @module = @course.context_modules.create!
      ag = @course.assignment_groups.create!
      assignment1 = ag.assignments.create!(:context => @course)

      assignmentTag1 = @module.add_item :type => 'assignment', :id => assignment1.id
      
      get 'item_redirect', :course_id => @course.id, :id => assignmentTag1.id
      response.should be_redirect
      response.should redirect_to course_assignment_url(@course, assignment1)
    end
    
    it "should redirect to a discussion page" do
      course_with_student_logged_in(:active_all => true)
      
      @module = @course.context_modules.create!
      topic = @course.discussion_topics.create!

      topicTag = @module.add_item :type => 'discussion_topic', :id => topic.id
      
      get 'item_redirect', :course_id => @course.id, :id => topicTag.id
      response.should be_redirect
      response.should redirect_to course_discussion_topic_url(@course, topic)
    end
    
    it "should redirect to a quiz page" do
      course_with_student_logged_in(:active_all => true)
      
      @module = @course.context_modules.create!
      quiz = @course.quizzes.create!

      tag = @module.add_item :type => 'quiz', :id => quiz.id
      
      get 'item_redirect', :course_id => @course.id, :id => tag.id
      response.should be_redirect
      response.should redirect_to course_quiz_url(@course, quiz)
    end
  end
  
  describe "POST 'reorder_items'" do
    it "should reorder items" do
      course_with_teacher_logged_in(:active_all => true)

      ag = @course.assignment_groups.create!
      a1 = ag.assignments.create!(:context => @course)
      a1.points_possible = 10
      a1.save
      a2 = ag.assignments.create!(:context => @course)
      m1 = @course.context_modules.create!
      m2 = @course.context_modules.create!

      make_content_tag = lambda do |assignment|
        ct = ContentTag.new
        ct.content_id = assignment.id
        ct.content_type = 'Assignment'
        ct.context_id = @course.id
        ct.context_type = 'Course'
        ct.title = "Assignment #{assignment.id}"
        ct.tag_type = "context_module"
        ct.context_module_id = m1.id
        ct.context_code = "course_#{@course.id}"
        ct.save!
        ct
      end
      ct1 = make_content_tag.call a1
      ct2 = make_content_tag.call a2

      post 'reorder_items', :course_id => @course.id, :context_module_id => m2.id, :order => "#{ct2.id}"
      ct2.reload
      ct2.context_module.should == m2
      ct1.reload
      ct1.context_module.should == m1
    end
  end
end