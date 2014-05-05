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
    @topic = @course.discussion_topics.build(:title => "some topic", :pinned => opts[:pinned])
    user = @user || opts[:user]
    if user && !opts[:skip_set_user]
      @topic.user = user
    end

    if opts[:with_assignment]
      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @topic.assignment.infer_times
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
  end

  describe "GET 'show'" do
    it "should require authorization" do
      course_with_student(:active_all => true)
      course_topic
      get 'show', :course_id => @course.id, :id => @topic.id
      assert_unauthorized
    end

    it "should work for announcements in a public course" do
      course_with_student(:active_all => true)
      @course.update_attribute(:is_public, true)
      @announcement = @course.announcements.create!(
        :title => "some announcement",
        :message => "some message"
      )
      get 'show', :course_id => @course.id, :id => @announcement.id
      response.should be_success
    end

    it "should not display announcements in private courses to users who aren't logged in" do
      course(active_all: true)
      announcement = @course.announcements.create!(title: 'Test announcement', message: 'Message')
      get('show', course_id: @course.id, id: announcement.id)
      response.code.should == '401'
    end

    context "discussion topic with assignment with overrides" do
      integrate_views

      before do
        course(:course_name => "I <3 Discussions", :active_all => 1)
        course_topic(:with_assignment => true, :user => @teacher)
        @section = @course.course_sections.create!(:name => "I <3 Discusions")
        @override = assignment_override_model(:assignment => @topic.assignment,
                                  :due_at => Time.now,
                                  :set => @section)
      end

      it "doesn't show overrides to students" do
        course_with_student_logged_in(:course => @course)
        get 'show', :course_id => @course.id, :id => @topic.id
        response.should be_success
        response.body.should_not match 'discussion-topic-due-dates'
        due_date = OverrideListPresenter.new.due_at(@topic.assignment)
        response.body.should match "due #{due_date}"
      end

      it "doesn't show overrides for observers" do
        course_with_observer_logged_in(:course => @course)
        @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section)
        get 'show', :course_id => @course.id, :id => @topic.id
        response.should be_success
        response.body.should_not match 'discussion-topic-due-dates'
        due_date = OverrideListPresenter.new.due_at(@topic.assignment.overridden_for(@observer))
        response.body.should match "due #{due_date}"
      end

      it "does show overrides to teachers" do
        course_with_teacher_logged_in(:course => @course)
        get 'show', :course_id => @course.id, :id => @topic.id
        response.should be_success
        response.body.should match 'discussion-topic-due-dates'
      end

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

    it "should display speedgrader when not for a large course" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic(:with_assignment => true)
      get 'show', :course_id => @course.id, :id => @topic.id
      assigns[:js_env][:DISCUSSION][:SPEEDGRADER_URL_TEMPLATE].should be_true
    end

    it "should hide speedgrader when for a large course" do
      course_with_teacher_logged_in(:active_all => true)
      course_topic(:with_assignment => true)
      Course.any_instance.stubs(:large_roster?).returns(true)
      get 'show', :course_id => @course.id, :id => @topic.id
      assigns[:js_env][:DISCUSSION][:SPEEDGRADER_URL_TEMPLATE].should be_nil
    end

    it "should mark as read when viewed" do
      course_with_student_logged_in(:active_all => true)
      course_topic(:skip_set_user => true)

      @topic.read_state(@student).should == 'unread'
      get 'show', :course_id => @course.id, :id => @topic.id
      @topic.reload.read_state(@student).should == 'read'
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

  describe 'POST create:' do
    before(:each) do
      Setting.set('enable_page_views', 'db')
      course_with_student_logged_in :active_all => true
      controller.stubs(:form_authenticity_token => 'abc', :form_authenticity_param => 'abc')
      post 'create', :course_id => @course.id, :title => 'Topic Title', :is_announcement => false,
                     :discussion_type => 'side_comment', :require_initial_post => true, :format => 'json',
                     :podcast_has_student_posts => false, :delayed_post_at => '', :lock_at => '',
                     :message => 'Message', :delay_posting => false, :threaded => false
    end

    after { Setting.set 'enable_page_views', 'false' }

    describe 'the new topic' do
      let(:topic) { assigns[:topic] }

      specify { topic.should be_a DiscussionTopic }
      specify { topic.user.should == @user }
      specify { topic.current_user.should == @user }
      specify { topic.delayed_post_at.should be_nil }
      specify { topic.lock_at.should be_nil }
      specify { topic.workflow_state.should == 'active' }
      specify { topic.id.should_not be_nil }
      specify { topic.title.should == 'Topic Title' }
      specify { topic.is_announcement.should be_false }
      specify { topic.discussion_type.should == 'side_comment' }
      specify { topic.message.should == 'Message' }
      specify { topic.threaded.should be_false }
    end

    it 'logs an asset access record for the discussion topic' do
      accessed_asset = assigns[:accessed_asset]
      accessed_asset[:category].should == 'topics'
      accessed_asset[:level].should == 'participate'
    end

    it 'registers a page view' do
      page_view = assigns[:page_view]
      page_view.should_not be_nil
      page_view.http_method.should == 'post'
      page_view.url.should =~ %r{^http://test\.host/api/v1/courses/\d+/discussion_topics}
      page_view.participated.should be_true
    end

  end

  describe "PUT: update" do
    before(:each) do
      course_with_teacher_logged_in(active_all: true)
      @topic = DiscussionTopic.create!(context: @course, title: 'Test Topic',
        delayed_post_at: '2013-01-01T00:00:00UTC', lock_at: '2013-01-02T00:00:00UTC')
    end

    it "should not clear lock_at if locked is not changed" do
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          locked: false)
      @topic.reload.should_not be_locked
      @topic.lock_at.should_not be_nil
    end

    it "should not clear delayed_post_at if published is not changed" do
      @topic.workflow_state = 'post_delayed'
      @topic.save!
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          published: false)
      @topic.reload.should_not be_published
      @topic.delayed_post_at.should_not be_nil
    end

    it "should unlock discussions with a lock_at attribute if lock state changes" do
      @topic.lock!
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          locked: false)

      @topic.reload.should_not be_locked
      @topic.lock_at.should be_nil
    end

    it "should set workflow to post_delayed when delayed_post_at and lock_at are in the future" do
      put(:update, course_id: @course.id, topic_id: @topic.id,
          title: 'Updated topic', format: 'json', delayed_post_at: Time.zone.now + 5.days)
      @topic.reload.should be_post_delayed
    end

    it "should not clear lock_at if lock state hasn't changed" do
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json', lock_at: @topic.lock_at,
          locked: true)
      @topic.reload.should be_locked
      @topic.lock_at.should_not be_nil
    end

    it "should set draft state on discussions with delayed_post_at" do
      put('update', course_id: @course.id, topic_id: @topic.id,
          title: 'Updated Topic', format: 'json',
          lock_at: @topic.lock_at, delayed_post_at: @topic.delayed_post_at,
          published: false)

      @topic.reload.should_not be_published
    end

    it "should delete attachments" do
      attachment = @topic.attachment = attachment_model(context: @course)
      @topic.lock_at = Time.now + 1.week
      @topic.unlock_at = Time.now - 1.week
      @topic.save!
      @topic.unlock!
      put('update', course_id: @course.id, topic_id: @topic.id,
          format: 'json', remove_attachment: '1')
      response.should be_success

      @topic.reload.attachment.should be_nil
      attachment.reload.should be_deleted
    end
  end

  describe "POST 'reorder'" do
    it "should reorder pinned topics" do
      course_with_teacher_logged_in(:active_all => true)

      # add noise
      @course.announcements.create!(message: 'asdf')
      course_topic

      topics = 3.times.map { course_topic(pinned: true) }
      topics.map(&:position).should == [1, 2, 3]
      t1, t2, _ = topics
      post 'reorder', :course_id => @course.id, :order => "#{t2.id},#{t1.id}", :format => 'json'
      response.should be_success
      topics.each &:reload
      topics.map(&:position).should == [2, 1, 3]
    end
  end
end
