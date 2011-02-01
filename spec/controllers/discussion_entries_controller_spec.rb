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

describe DiscussionEntriesController do
  def course_topic
    @topic = @course.discussion_topics.create(:title => "some topic")
  end
  def topic_entry
    @entry = @topic.discussion_entries.create(:message => "some message", :user => @user)
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_topic
      topic_entry
      get 'show', :course_id => @course.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should assign variables" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      topic_entry
      get 'show', :course_id => @course.id, :id => @entry.id, :format => :json
      # response.should be_success
      assigns[:entry].should_not be_nil
      assigns[:entry].should eql(@entry)
    end
  end
  
  describe "POST 'create'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}
      assert_unauthorized
    end
    
    it "should create a message" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}
      assigns[:topic].should eql(@topic)
      assigns[:entry].should_not be_nil
      assigns[:entry].message.should eql("yo")
      response.should be_redirect
    end
    
    it "should attach a file if authorized" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}, :attachment => {:uploaded_data => default_uploaded_data}
      assigns[:topic].should eql(@topic)
      assigns[:entry].should_not be_nil
      assigns[:entry].message.should eql("yo")
      assigns[:entry].attachment.should_not be_nil
      response.should be_redirect
    end
    
    it "should NOT attach a file if not authorized" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      post 'create', :course_id => @course.id, :discussion_entry => {:discussion_topic_id => @topic.id, :message => "yo"}, :attachment => {:uploaded_data => default_uploaded_data}
      assigns[:topic].should eql(@topic)
      assigns[:entry].should_not be_nil
      assigns[:entry].message.should eql("yo")
      assigns[:entry].attachment.should be_nil
      response.should be_redirect
    end
  end
  
  describe "PUT 'update'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_topic
      topic_entry
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {}
      assert_unauthorized
    end
    
    it "should update the entry" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      topic_entry
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
    end
    
    it "should attach a new file to the entry" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      topic_entry
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should_not be_nil
    end
    
    it "should replace the file to the entry" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      topic_entry
      @entry.attachment = @a
      @entry.save
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should_not be_nil
      assigns[:entry].attachment.should_not eql(@a)
    end
    
    it "should replace the file to the entry" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      @a = @course.attachments.create!(:uploaded_data => default_uploaded_data)
      topic_entry
      @entry.attachment = @a
      @entry.save
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem", :remove_attachment => '1'}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should be_nil
    end
    
    it "should not replace the file to the entry if not authorized" do
      course_with_student_logged_in(:active_all => true)
      course_topic
      topic_entry
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "ahem"}, :attachment => {:uploaded_data => default_uploaded_data}
      response.should be_redirect
      assigns[:entry].should eql(@entry)
      assigns[:entry].message.should eql("ahem")
      assigns[:entry].attachment.should be_nil
    end
    
    it "should set the editor_id to whoever edited to entry" do
      course_with_teacher_logged_in(:active_all => true)
      @teacher = @user
      course_topic
      @student = user_model
      @course.enroll_student(@student).accept
      @entry = @topic.discussion_entries.build(:message => "test")
      @entry.user = @student
      @entry.save!
      @entry.user.should eql(@student)
      @entry.editor.should eql(nil)
      put 'update', :course_id => @course.id, :id => @entry.id, :discussion_entry => {:message => "new message"}
      response.should be_redirect
      assigns[:entry].editor.should eql(@teacher)
      assigns[:entry].user.should eql(@student)
    end
  end
  
  describe "DELETE 'destroy'" do
    it "should require authorization" do
      course_with_teacher(:active_all => true)
      course_topic
      topic_entry
      delete 'destroy', :course_id => @course.id, :id => @entry.id
      assert_unauthorized
    end
    
    it "should delete the entry" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      topic_entry
      delete 'destroy', :course_id => @course.id, :id => @entry.id
      response.should be_redirect
      @topic.reload
      @topic.discussion_entries.should_not be_empty
      @topic.discussion_entries.active.should be_empty
    end
  end
end
