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
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe DiscussionTopicsController do
  def course_topic(opts={})
    @topic = @course.discussion_topics.build(:title => "some topic")
    if @user
      @topic.user = @user
    end

    if opts[:with_assignment]
      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @topic.assignment.infer_due_at
      @topic.assignment.saved_by = :discussion_topic
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

    it "should allow observer by default" do
      course_with_teacher
      course_with_observer_logged_in(:course => @course)
      @user = @teacher
      course_topic
      get 'index', :course_id => @course.id
      assigns[:topics].should_not be_nil
      assigns[:topics].should_not be_empty
      assigns[:topics][0].should eql(@topic)
    end

    it "should reject observer if read_forum role is false" do
      course_with_teacher
      course_with_observer_logged_in(:course => @course)
      RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                           :enrollment_type => "ObserverEnrollment", :enabled => false)
      @user = @teacher
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

    it "should assign groups from the topic's assignment's category if the topic is for a group assignment" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic(:with_assignment => true)

      # set up groups
      group_category1 = @course.group_categories.create(:name => 'category 1')
      group_category2 = @course.group_categories.create(:name => 'category 2')
      @course.groups.create!(:group_category => group_category1)
      @course.groups.create!(:group_category => group_category1)
      @course.groups.create!(:group_category => group_category2)
      @topic.assignment.group_category = group_category1
      @topic.assignment.save!

      get 'show', :course_id => @course.id, :id => @topic.id
      assigns[:groups].size.should eql(2)
    end

    context "posting first to view setting" do
      before(:each) do
        course_with_student(:active_all => true)

        @observer = user(:name => "Observer", :active_all => true)
        e = @course.enroll_user(@observer, 'ObserverEnrollment')
        e.associated_user = @student
        e.save
        @observer.reload

        course_with_teacher(:course => @course, :active_all => true)
        @context = @course
        discussion_topic_model
        @topic.require_initial_post = true
        @topic.save
      end

      it "should allow admins to see posts without posting" do
        @topic.reply_from(:user => @student, :text => 'hai')
        user_session(@teacher)
        get 'show', :course_id => @course.id, :id => @topic.id
        assigns[:initial_post_required].should be_false
      end

      it "shouldn't allow student who hasn't posted to see" do
        @topic.reply_from(:user => @teacher, :text => 'hai')
        user_session(@student)
        get 'show', :course_id => @course.id, :id => @topic.id
        assigns[:initial_post_required].should be_true
      end

      it "shouldn't allow student's observer who hasn't posted to see" do
        @topic.reply_from(:user => @teacher, :text => 'hai')
        user_session(@observer)
        get 'show', :course_id => @course.id, :id => @topic.id
        assigns[:initial_post_required].should be_true
      end

      it "should allow student who has posted to see" do
        @topic.reply_from(:user => @student, :text => 'hai')
        user_session(@student)
        get 'show', :course_id => @course.id, :id => @topic.id
        assigns[:initial_post_required].should be_false
      end

      it "should allow student's observer who has posted to see" do
        @topic.reply_from(:user => @student, :text => 'hai')
        user_session(@observer)
        get 'show', :course_id => @course.id, :id => @topic.id
        assigns[:initial_post_required].should be_false
      end

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

    it "should not drift when saving delayed_post_at with user-preferred timezone set" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic

      @teacher.time_zone = 'Alaska'
      @teacher.save

      teacher_tz = Time.use_zone(@teacher.time_zone) { Time.zone }
      time_string = "Fri Aug 26, 2031 8:39AM"
      expected_time = teacher_tz.parse(time_string)

      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {
        :delay_posting => '1',
        :delayed_post_at => time_string
      }

      @topic.reload
      @topic.delayed_post_at.should == expected_time
    end

    it "should allow unlocking a locked topic" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      @topic.lock!

      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => { :event => 'unlock' }

      @topic.reload
      @topic.should_not be_locked
    end

    it "should allow locking a topic after due date" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:assignment => { :set_assignment => '1' }}
      @topic.reload
      @topic.assignment.update_attribute(:due_at, 1.week.ago)
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => { :event => 'lock' }
      @topic.reload
      @topic.should be_locked
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => { :event => 'unlock' }
      @topic.reload
      @topic.should_not be_locked
    end

    it "should not allow locking a topic before due date" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic
      put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => {:assignment => { :set_assignment => '1' }}
      @topic.reload
      @topic.assignment.update_attribute(:due_at, 1.week.from_now)
      lambda {put 'update', :course_id => @course.id, :id => @topic.id, :discussion_topic => { :event => 'lock' }}.should raise_error
      @topic.reload
      @topic.should_not be_locked
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

  describe "GET 'public_feed.atom'" do
    before(:each) do
      course_with_student(:active_all => true)
      course_topic
    end

    it "should require authorization" do
      get 'public_feed', :format => 'atom', :feed_code => @course.feed_code + 'x'
      assigns[:problem].should eql("The verification code is invalid.")
    end

    it "should include absolute path for rel='self' link" do
      get 'public_feed', :format => 'atom', :feed_code => @course.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.links.first.rel.should match(/self/)
      feed.links.first.href.should match(/http:\/\//)
    end

    it "should include an author for each entry" do
      get 'public_feed', :format => 'atom', :feed_code => @course.feed_code
      feed = Atom::Feed.load_feed(response.body) rescue nil
      feed.should_not be_nil
      feed.entries.should_not be_empty
      feed.entries.all?{|e| e.authors.present?}.should be_true
    end
  end
end
