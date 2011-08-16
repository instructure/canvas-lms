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

describe DiscussionTopicsController do
  def course_topic
    @topic = @course.discussion_topics.build(:title => "some topic")
    if @user
      @topic.user = @user
    end
    @topic.save
    @topic
  end
  def topic_entry
    @entry = @topic.discussion_entries.create(:message => "some message", :user => @user)
  end

  describe "GET 'index'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      get 'index', :course_id => @course.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      get 'index', :course_id => @course.id
      assigns[:topics].should_not be_nil
      assigns[:topics].should_not be_empty
      assigns[:topics][0].should eql(@topic)
    end
    
  end
  
  describe "GET 'show'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_topic
      get 'show', :course_id => @course.id, :id => @topic.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      topic_entry
      @topic.reload
      @topic.discussion_entries.should_not be_empty
      get 'show', :course_id => @course.id, :id => @topic.id
      response.should be_success
      assigns[:topic].should_not be_nil
      assigns[:topic].should eql(@topic)
      assigns[:entries].should_not be_nil
      assigns[:entries].should_not be_empty
      assigns[:entries][0].should eql(@entry)
    end
    
    it "should allow concluded teachers to see discussions" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      @enrollment.conclude
      get 'show', :course_id => @course.id, :id => @topic.id
      response.should be_success
      get 'index', :course_id => @course.id
      response.should be_success
    end
    
    it "should allow concluded students to see discussions" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      @enrollment.conclude
      get 'show', :course_id => @course.id, :id => @topic.id
      response.should be_success
      get 'index', :course_id => @course.id
      response.should be_success
    end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_topic => {:title => "some title"}
      assert_unauthorized
    end
    
    it "should create a message" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_topic => {:title => "some title"}
      assigns[:topic].title.should eql("some title")
      response.should be_redirect
    end
    
    it "should attach a file if authorized" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_topic => {:title => "some title"}, :attachment => {:uploaded_data => default_uploaded_data}
      assigns[:topic].title.should eql("some title")
      assigns[:topic].attachment.should_not be_nil
      response.should be_redirect
    end
    
    it "should not attach a file if not authorized" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_topic => {:title => "some title"}, :attachment => {:uploaded_data => default_uploaded_data}
      assigns[:topic].title.should eql("some title")
      assigns[:topic].attachment.should be_nil
      response.should be_redirect
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_topic
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {}
      assert_unauthorized
    end
    
    it "should update the entry" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:title => "new title"}
      response.should be_redirect
      assigns[:topic].should eql(@topic)
      assigns[:topic].title.should eql("new title")
    end
    
    it "should attach a new file" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:title => "new title"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:topic].should eql(@topic)
      assigns[:topic].title.should eql("new title")
      assigns[:topic].attachment.should_not be_nil
    end
    
    it "should replace the attached file" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      @topic.attachment = @a
      @topic.save
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:title => "new title"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:topic].should eql(@topic)
      assigns[:topic].title.should eql("new title")
      assigns[:topic].attachment.should_not be_nil
      assigns[:topic].attachment.should_not eql(@a)
    end
    
    it "should remove the attached file" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      @topic.attachment = @a
      @topic.save
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:title => "new title", :remove_attachment => '1'}
      response.should be_redirect
      assigns[:topic].should eql(@topic)
      assigns[:topic].title.should eql("new title")
      assigns[:topic].attachment.should be_nil
    end
    
    it "should not attach a new file if not authorized" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:title => "new title"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:topic].should eql(@topic)
      assigns[:topic].title.should eql("new title")
      assigns[:topic].attachment.should be_nil
    end
    
    it "should set the editor_id to whoever edited to entry" do
      course_with_teacher_logged_in(:active_all => true)
      @teacher = @user
      @student = user_model
      @course.enroll_student(@student).accept
      @topic = @course.discussion_topics.build(:title => "some message", :message => "test")
      @topic.user = @student
      @topic.save!
      @topic.user.should eql(@student)
      @topic.editor.should eql(nil)
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:message => "new message"}
      response.should be_redirect
      assigns[:topic].editor.should eql(@teacher)
      assigns[:topic].user.should eql(@student)
    end

    it "should not duplicate when adding or removing an assignment" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic

      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:assignment => { :set_assignment => '1' }}
      @topic.reload
      @topic.assignment_id.should_not be_nil
      @topic.old_assignment_id.should_not be_nil
      old_assignment_id = @topic.old_assignment_id
      DiscussionTopic.find_all_by_old_assignment_id(old_assignment_id).should == [ @topic ]

      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:assignment => { :set_assignment => '0' }}
      @topic.reload
      @topic.assignment_id.should be_nil
      @topic.old_assignment_id.should == old_assignment_id
      DiscussionTopic.find_all_by_old_assignment_id(old_assignment_id).should == [ @topic ]

      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:assignment => { :set_assignment => '1' }}
      @topic.reload
      @topic.assignment_id.should == old_assignment_id
      @topic.old_assignment_id.should == old_assignment_id
      DiscussionTopic.find_all_by_old_assignment_id(old_assignment_id).should == [ @topic ]

      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:assignment => { :set_assignment => '0' }}
      @topic.reload
      @topic.assignment_id.should be_nil
      @topic.old_assignment_id.should == old_assignment_id
      DiscussionTopic.find_all_by_old_assignment_id(old_assignment_id).should == [ @topic ]
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_topic
      delete 'destroy', :course_id => @course.id, :id => @topic.id
      assert_unauthorized
    end
    
    it "should delete the entry" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      delete 'destroy', :course_id => @course.id, :id => @topic.id
      response.should be_redirect
      assigns[:topic].should be_deleted
      @course.reload
      @course.discussion_topics.should_not be_include(@topic)
    end
  end
end
