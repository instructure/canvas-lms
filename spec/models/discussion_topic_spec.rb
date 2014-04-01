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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe DiscussionTopic do
  it "should santize message" do
    course_model
    @course.discussion_topics.create!(:message => "<a href='#' onclick='alert(12);'>only this should stay</a>")
    @course.discussion_topics.first.message.should eql("<a href=\"#\">only this should stay</a>")
  end

  it "should default to side_comment type" do
    d = DiscussionTopic.new
    d.discussion_type.should == 'side_comment'

    d.threaded = '1'
    d.discussion_type.should == 'threaded'

    d.threaded = ''
    d.discussion_type.should == 'side_comment'
  end

  it "should require a valid discussion_type" do
    @topic = course_model.discussion_topics.build(:message => 'test', :discussion_type => "gesundheit")
    @topic.save.should == false
    @topic.errors.detect { |e| e.first.to_s == 'discussion_type' }.should be_present
  end

  it "should update the assignment it is associated with" do
    course_model
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    a.points_possible.should eql(5.0)
    a.submission_types.should_not eql("online_quiz")
    t = @course.discussion_topics.build(:assignment => a, :title => "some topic", :message => "a little bit of content")
    t.save
    t.assignment_id.should eql(a.id)
    t.assignment.should eql(a)
    a.reload
    a.discussion_topic.should eql(t)
    a.submission_types.should eql("discussion_topic")
  end

  it "should delete the assignment if the topic is no longer graded" do
    course_model
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    a.points_possible.should eql(5.0)
    a.submission_types.should_not eql("online_quiz")
    t = @course.discussion_topics.build(:assignment => a, :title => "some topic", :message => "a little bit of content")
    t.save
    t.assignment_id.should eql(a.id)
    t.assignment.should eql(a)
    a.reload
    a.discussion_topic.should eql(t)
    t.assignment = nil
    t.save
    t.reload
    t.assignment_id.should eql(nil)
    t.assignment.should eql(nil)
    a.reload
    a.should be_deleted
  end

  it "should not grant permissions if it is locked" do
    course_with_teacher(:active_all => 1)
    student_in_course(:active_all => 1)
    @topic = @course.discussion_topics.create!(:user => @teacher)
    relevant_permissions = [:read, :reply, :update, :delete]
    (@topic.check_policy(@teacher) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply', 'update', 'delete'].sort
    (@topic.check_policy(@student) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply'].sort
    @topic.lock!
    (@topic.check_policy(@teacher) & relevant_permissions).map(&:to_s).sort.should == ['read', 'update', 'delete'].sort
    (@topic.check_policy(@student) & relevant_permissions).map(&:to_s).should == ['read']
    @topic.unlock!
    (@topic.check_policy(@teacher) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply', 'update', 'delete'].sort
    (@topic.check_policy(@student) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply'].sort

    @entry = @topic.discussion_entries.create!(:user => @teacher)
    @entry.discussion_topic = @topic
    (@entry.check_policy(@teacher) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply', 'update', 'delete'].sort
    (@entry.check_policy(@student) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply'].sort
    @topic.lock!
    (@topic.check_policy(@teacher) & relevant_permissions).map(&:to_s).sort.should == ['read', 'update', 'delete'].sort
    (@entry.check_policy(@student) & relevant_permissions).map(&:to_s).should == ['read']
    @topic.unlock!
    (@entry.check_policy(@teacher) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply', 'update', 'delete'].sort
    (@entry.check_policy(@student) & relevant_permissions).map(&:to_s).sort.should == ['read', 'reply'].sort
  end

  describe "visibility" do
    before(:each) do
      course_with_teacher(:active_all => 1, :draft_state => draft_state)
      student_in_course(:active_all => 1)
      @topic = @course.discussion_topics.create!(:user => @teacher)
    end

    let(:draft_state) {false} # this does not disable draft state is it is switched on at the account level

    context "with draft state enabled" do
      let(:draft_state) {true}

      it "should be visible to author when unpublished" do
        @topic.unpublish!
        @topic.visible_for?(@teacher).should be_true
      end

      it "should be visible when published even when for delayed posting" do
        @topic.delayed_post_at = 5.days.from_now
        @topic.workflow_state = 'post_delayed'
        @topic.save!
        @topic.visible_for?(@student).should be_true
      end
    end

    it "should not be visible when unpublished even when it is active" do
      @topic.unpublish!
      @topic.visible_for?(@student).should be_false
    end

    it "should be visible to students when topic is not locked" do
      @topic.visible_for?(@student).should be_true
    end

    it "should not be visible to students when topic delayed_post_at is in the future" do
      @topic.delayed_post_at = 5.days.from_now
      @topic.save!
      @topic.visible_for?(@student).should @topic.draft_state_enabled? ? be_true : be_false
    end

    it "should not be visible to students when topic is for delayed posting" do
      @topic.workflow_state = 'post_delayed'
      @topic.save!
      @topic.visible_for?(@student).should @topic.draft_state_enabled? ? be_true : be_false
    end

    it "should be visible to students when topic delayed_post_at is in the past" do
      @topic.delayed_post_at = 5.days.ago
      @topic.save!
      @topic.visible_for?(@student).should be_true
    end

    it "should be visible to students when topic delayed_post_at is nil" do
      @topic.delayed_post_at = nil
      @topic.save!
      @topic.visible_for?(@student).should be_true
    end

    it "should not be visible when no delayed_post but assignment unlock date in future" do
      @topic.delayed_post_at = nil
      group_category = @course.group_categories.create(:name => "category")
      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic',
        :title => @topic.title,
        :group_category => group_category,
        :unlock_at => 10.days.from_now,
        :lock_at => 30.days.from_now)
      @topic.assignment.infer_times
      @topic.assignment.saved_by = :discussion_topic
      @topic.save

      @topic.visible_for?(@student).should @topic.draft_state_enabled? ? be_true : be_false
    end

    it "should be visible to all teachers in the course" do
      @topic.update_attribute(:delayed_post_at, Time.now + 1.day)
      new_teacher = user
      @course.enroll_teacher(new_teacher).accept!
      @topic.visible_for?(new_teacher).should be_true
    end
  end

  describe "allow_student_discussion_topics setting" do

    before(:each) do
      course_with_teacher(:active_all => 1)
      student_in_course(:active_all => 1)
      @topic = @course.discussion_topics.create!(:user => @teacher)
    end

    it "should allow students to create topics by default" do
      @topic.check_policy(@teacher).should include :create
      @topic.check_policy(@student).should include :create
    end

    it "should disallow students from creating topics" do
      @course.allow_student_discussion_topics = false
      @course.save!
      @topic.reload
      @topic.check_policy(@teacher).should include :create
      @topic.check_policy(@student).should_not include :create
    end

  end

  it "should grant observers read permission by default" do
    course_with_teacher(:active_all => true)
    course_with_observer(:course => @course, :active_all => true)
    relevant_permissions = [:read, :reply, :update, :delete]

    @topic = @course.discussion_topics.create!(:user => @teacher)
    (@topic.check_policy(@observer) & relevant_permissions).map(&:to_s).sort.should == ['read'].sort
    @entry = @topic.discussion_entries.create!(:user => @teacher)
    (@entry.check_policy(@observer) & relevant_permissions).map(&:to_s).sort.should == ['read'].sort
  end

  it "should not grant observers read permission when read_forum override is false" do
    course_with_teacher(:active_all => true)
    course_with_observer(:course => @course, :active_all => true)

    RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                         :enrollment_type => "ObserverEnrollment", :enabled => false)

    relevant_permissions = [:read, :reply, :update, :delete]
    @topic = @course.discussion_topics.create!(:user => @teacher)
    (@topic.check_policy(@observer) & relevant_permissions).map(&:to_s).should be_empty
    @entry = @topic.discussion_entries.create!(:user => @teacher)
    (@entry.check_policy(@observer) & relevant_permissions).map(&:to_s).should be_empty
  end

  context "delayed posting" do
    def discussion_topic(opts = {})
      workflow_state = opts.delete(:workflow_state)
      @topic = @course.discussion_topics.build(opts)
      @topic.workflow_state = workflow_state if workflow_state
      @topic.save!
      @topic
    end

    def delayed_discussion_topic(opts = {})
      discussion_topic({:workflow_state => 'post_delayed'}.merge(opts))
    end

    it "shouldn't send to streams on creation or update if it's delayed" do
      course_with_student(:active_all => true)
      @user.register
      topic = @course.discussion_topics.create!(:title => "this should not be delayed", :message => "content here")
      topic.stream_item.should_not be_nil

      topic = delayed_discussion_topic(:title => "this should be delayed", :message => "content here", :delayed_post_at => Time.now + 1.day)
      topic.stream_item.should be_nil

      topic.message = "content changed!"
      topic.save
      topic.stream_item.should be_nil
    end

    it "should send to streams on update from delayed to active" do
      course_with_student(:active_all => true)
      @user.register
      topic = delayed_discussion_topic(:title => "this should be delayed", :message => "content here", :delayed_post_at => Time.now + 1.day)
      topic.workflow_state.should == 'post_delayed'
      topic.stream_item.should be_nil

      topic.delayed_post_at = nil
      topic.title = "this isn't delayed any more"
      topic.workflow_state = 'active'
      topic.save!
      topic.stream_item.should_not be_nil
    end

    describe "#update_based_on_date" do
      before do
        course_with_student(:active_all => true)
        @user.register
      end

      it "should be active when delayed_post_at is in the past" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => Time.now - 1.day,
                                         :lock_at => nil)
        topic.update_based_on_date
        topic.workflow_state.should eql 'active'
        topic.locked?.should be_false
      end

      it "should be post_delayed when delayed_post_at is in the future" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => Time.now + 1.day,
                                         :lock_at => nil)
        topic.update_based_on_date
        topic.workflow_state.should eql 'post_delayed'
        topic.locked?.should be_false
      end

      it "should be locked when lock_at is in the past" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => nil,
                                         :lock_at => Time.now - 1.day)
        topic.update_based_on_date
        topic.locked?.should be_true
      end

      it "should be active when lock_at is in the future" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => nil,
                                         :lock_at => Time.now + 1.day)
        topic.update_based_on_date
        topic.workflow_state.should eql 'active'
        topic.locked?.should be_false
      end

      it "should be active when now is between delayed_post_at and lock_at" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => Time.now - 1.day,
                                         :lock_at => Time.now + 1.day)
        topic.update_based_on_date
        topic.workflow_state.should eql 'active'
        topic.locked?.should be_false
      end

      it "should be post_delayed when delayed_post_at and lock_at are in the future" do
        topic = delayed_discussion_topic(:title           => "title",
                                         :message         => "content here",
                                         :delayed_post_at => Time.now + 1.day,
                                         :lock_at         => Time.now + 3.days)
        topic.update_based_on_date
        topic.workflow_state.should eql 'post_delayed'
        topic.locked?.should be_false
      end

      it "should be locked when delayed_post_at and lock_at are in the past" do
        topic = delayed_discussion_topic(:title           => "title",
                                         :message         => "content here",
                                         :delayed_post_at => Time.now - 3.days,
                                         :lock_at         => Time.now - 1.day)
        topic.update_based_on_date
        topic.workflow_state.should eql 'active'
        topic.locked?.should be_true
      end

      it "should not unlock a topic even if the lock date is in the future" do
        topic = discussion_topic(:title           => "title",
                                 :message         => "content here",
                                 :workflow_state  => 'locked',
                                 :locked          => true,
                                 :delayed_post_at => nil,
                                 :lock_at         => Time.now + 1.day)
        topic.update_based_on_date
        topic.locked?.should be_true
      end

      it "should not mark a topic with post_delayed even if delayed_post_at even is in the future" do
        topic = discussion_topic(:title           => "title",
                                 :message         => "content here",
                                 :workflow_state  => 'active',
                                 :delayed_post_at => Time.now + 1.day,
                                 :lock_at         => nil)
        topic.update_based_on_date
        topic.workflow_state.should eql 'active'
        topic.locked?.should be_false
      end
    end
  end

  context "sub-topics" do
    it "should default subtopics_refreshed_at on save if a group assignment" do
      course_with_student(:active_all => true)
      group_category = @course.group_categories.create(:name => "category")
      @group = @course.groups.create(:name => "group", :group_category => group_category)
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.subtopics_refreshed_at.should be_nil

      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title, :group_category => @group.group_category)
      @topic.assignment.infer_times
      @topic.assignment.saved_by = :discussion_topic
      @topic.save
      @topic.subtopics_refreshed_at.should_not be_nil
    end

    it "should not allow students to edit sub-topics" do
      course_with_student(:active_all => true)
      @first_user = @user
      @second_user = user_model
      @course.enroll_student(@second_user).accept
      @parent_topic = @course.discussion_topics.create!(:title => "parent topic", :message => "msg")
      @group = @course.groups.create!(:name => "course group")
      @group.add_user(@first_user)
      @group.add_user(@second_user)
      @group_topic = @group.discussion_topics.create!(:title => "group topic", :message => "ok to be edited", :user => @first_user)
      @sub_topic = @group.discussion_topics.build(:title => "sub topic", :message => "not ok to be edited", :user => @first_user)
      @sub_topic.root_topic_id = @parent_topic.id
      @sub_topic.save!
      @group_topic.grants_right?(@second_user, nil, :update).should eql(false)
      @sub_topic.grants_right?(@second_user, nil, :update).should eql(false)
    end
  end

  context "refresh_subtopics" do
    it "should be a no-op unless there's an assignment and it has a group_category" do
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.refresh_subtopics
      @topic.reload.child_topics.should be_empty

      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @topic.assignment.saved_by = :discussion_topic
      @topic.save
      @topic.refresh_subtopics
      @topic.reload.child_topics.should be_empty
    end

    it "should create a topic per active group in the category otherwise" do
      group_discussion_assignment
      @topic.refresh_subtopics
      subtopics = @topic.reload.child_topics
      subtopics.should_not be_nil
      subtopics.size.should == 2
      subtopics.each { |t| t.root_topic.should == @topic }
      @group1.reload.discussion_topics.should_not be_empty
      @group2.reload.discussion_topics.should_not be_empty
    end

    it "should copy appropriate attributes from the parent topic to subtopics on updates to the parent" do
      group_discussion_assignment
      @topic.refresh_subtopics
      subtopics = @topic.reload.child_topics
      subtopics.each {|st| st.discussion_type.should == 'side_comment' }
      @topic.discussion_type = 'threaded'
      @topic.save!
      subtopics.each {|st| st.reload.discussion_type.should == 'threaded' }
    end

    it "should not rename the assignment to match a subtopic" do
      group_discussion_assignment
      original_name = @assignment.title
      @assignment.reload
      @assignment.title.should == original_name
    end
  end

  context "root_topic?" do
    it "should be false if the topic has a root topic" do
      # subtopic has the assignment and group_category, but has a root topic
      course_with_student(:active_all => true)
      group_category = @course.group_categories.create(:name => "category")
      @parent_topic = @course.discussion_topics.create(:title => "parent topic")
      @subtopic = @parent_topic.child_topics.build(:title => "subtopic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @subtopic.title, :group_category => group_category)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @subtopic.assignment = @assignment
      @subtopic.save

      @subtopic.should_not be_root_topic
    end

    it "should be false unless the topic has an assignment" do
      # topic has no root topic, but also has no assignment
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "subtopic")
      @topic.should_not be_root_topic
    end

    it "should be false unless the topic's assignment has a group_category" do
      # topic has no root topic and has an assignment, but the assignment has no group_category
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "topic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save

      @topic.should_not be_root_topic
    end

    it "should be true otherwise" do
      # topic meets all criteria
      course_with_student(:active_all => true)
      group_category = @course.group_categories.create(:name => "category")
      @topic = @course.discussion_topics.create(:title => "topic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title, :group_category => group_category)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save

      @topic.should be_root_topic
    end
  end

  context "#discussion_subentry_count" do
    it "returns the count of all active discussion_entries" do
      @student = student_in_course(:active_all => true).user
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.reply_from(:user => @teacher, :text => "entry 1").destroy  # no count
      @topic.reply_from(:user => @teacher, :text => "entry 1")          # 1
      @entry = @topic.reply_from(:user => @teacher, :text => "entry 2") # 2
      @entry.reply_from(:user => @student, :html => "reply 1")          # 3
      @entry.reply_from(:user => @student, :html => "reply 2")          # 4
      # expect
      @topic.discussion_subentry_count.should == 4
    end
  end

  context "for_assignment?/for_group_assignment?" do
    it "should not be for_assignment?/for_group_assignment? unless it has an assignment" do
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.should_not be_for_assignment
      @topic.should_not be_for_group_assignment

      group_category = @course.group_categories.build(:name => "category")
      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title, :group_category => group_category)
      @topic.assignment.infer_times
      @topic.assignment.saved_by = :discussion_topic
      @topic.save
      @topic.should be_for_assignment
      @topic.should be_for_group_assignment
    end

    it "should not be for_group_assignment? unless the assignment has a group_category" do
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.build(:title => "topic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save
      @topic.should be_for_assignment
      @topic.should_not be_for_group_assignment

      @assignment.group_category = @course.group_categories.create(:name => "category")
      @assignment.save
      @topic.reload.should be_for_group_assignment
    end
  end

  context "should_send_to_stream" do
    it "should be true for non-assignment discussions" do
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.should_send_to_stream.should be_true
    end

    it "should be true for non-group discussion assignments" do
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.build(:title => "topic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title, :due_at => 1.day.from_now)
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save
      @topic.should_send_to_stream.should be_true
    end

    it "should be true for the parent topic only in group discussion assignments, not the subtopics" do
      course_with_student(:active_all => true)
      group_category = @course.group_categories.create(:name => "category")
      @parent_topic = @course.discussion_topics.create(:title => "parent topic")
      @subtopic = @parent_topic.child_topics.build(:title => "subtopic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @subtopic.title, :group_category => group_category, :due_at => 1.day.from_now)
      @assignment.saved_by = :discussion_topic
      @subtopic.assignment = @assignment
      @subtopic.save
      @parent_topic.should_send_to_stream.should be_true
      @subtopic.should_send_to_stream.should be_false
    end

    it "should not send stream items to students if course isn't published'" do
      course
      course_with_teacher(:course => @course, :active_all => true)
      student_in_course(:course => @course, :active_all => true)

      topic = @course.discussion_topics.create!(:title => "secret topic", :user => @teacher)

      @student.stream_item_instances.count.should == 0
      @teacher.stream_item_instances.count.should == 1

      topic.discussion_entries.create!

      @student.stream_item_instances.count.should == 0
      @teacher.stream_item_instances.count.should == 1
    end

  end

  context "posting first to view" do
    before(:each) do
      course_with_student(:active_all => true)
      @observer = user(:active_all => true)
      course_with_teacher(:course => @course, :active_all => true)
      @context = @course
      discussion_topic_model
      @topic.require_initial_post = true
      @topic.save
    end

    it "should allow admins to see posts without posting" do
      @topic.user_can_see_posts?(@teacher).should == true
    end

    it "should only allow active admins to see posts without posting" do
      @ta_enrollment = course_with_ta(:course => @course, :active_enrollment => true)
      # TA should be able to see
      @topic.user_can_see_posts?(@ta).should == true
      # Remove user as TA and enroll as student, should not be able to see
      @ta_enrollment.destroy
      # enroll as a student.
      course_with_student(:course => @course, :user => @ta, :active_enrollment => true)
      @topic.reload
      DiscussionTopic.clear_cached_contexts
      @topic.user_can_see_posts?(@ta).should == false
    end

    it "shouldn't allow student (and observer) who hasn't posted to see" do
      @topic.user_can_see_posts?(@student).should == false
    end

    it "should allow student (and observer) who has posted to see" do
      @topic.reply_from(:user => @student, :text => 'hai')
      @topic.user_can_see_posts?(@student).should == true
    end

    it "should work the same for group discussions" do
      group_discussion_assignment
      @topic.require_initial_post = true
      @topic.save!
      ct = @topic.child_topics.first
      ct.context.add_user(@student)
      ct.user_can_see_posts?(@student).should be_false
      ct.reply_from(user: @student, text: 'ohai')
      ct.user_ids_who_have_posted_and_admins
      ct.user_can_see_posts?(@student).should be_true
    end
  end

  context "subscribers" do
    before :each do
      course_with_student(:active_all => true)
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    it "should automatically include the author" do
      @topic.subscribers.should include(@teacher)
    end

    it "should not include the author if they unsubscribe" do
      @topic.unsubscribe(@teacher)
      @topic.subscribers.should_not include(@teacher)
    end

    it "should automatically include posters" do
      @topic.reply_from(:user => @student, :text => "entry")
      @topic.subscribers.should include(@student)
    end

    it "should include author when topic was created before subscriptions where added" do
      participant = @topic.update_or_create_participant(current_user: @topic.user, subscribed: nil)
      participant.subscribed.should be_nil
      @topic.subscribers.map(&:id).should include(@teacher.id)
    end

    it "should include users that have posted entries before subscriptions were added" do
      @topic.reply_from(:user => @student, :text => "entry")
      participant = @topic.update_or_create_participant(current_user: @student, subscribed: nil)
      participant.subscribed.should be_nil
      @topic.subscribers.map(&:id).should include(@student.id)
    end

    it "should not include posters if they unsubscribe" do
      @topic.reply_from(:user => @student, :text => "entry")
      @topic.unsubscribe(@student)
      @topic.subscribers.should_not include(@student)
    end

    it "should resubscribe unsubscribed users if they post" do
      @topic.reply_from(:user => @student, :text => "entry")
      @topic.unsubscribe(@student)
      @topic.reply_from(:user => @student, :text => "another entry")
      @topic.subscribers.should include(@student)
    end

    it "should include users who subscribe" do
      @topic.subscribe(@student)
      @topic.subscribers.should include(@student)
    end

    it "should not include anyone no longer in the course" do
      @topic.subscribe(@student)
      @topic2 = @course.discussion_topics.create!(:title => "student topic", :message => "I'm outta here", :user => @student)
      @student.enrollments.first.destroy
      @topic.subscribers.should_not include(@student)
      @topic2.subscribers.should_not include(@student)
    end
  end

  context "posters" do
    before :each do
      @teacher = course_with_teacher(:active_all => true).user
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    it "should include the topic author" do
      @topic.posters.should include(@teacher)
    end

    it "should include users that have posted entries" do
      @student = student_in_course(:active_all => true).user
      @topic.reply_from(:user => @student, :text => "entry")
      @topic.posters.should include(@student)
    end

    it "should include users that have replies to entries" do
      @entry = @topic.reply_from(:user => @teacher, :text => "entry")
      @student = student_in_course(:active_all => true).user
      @entry.reply_from(:user => @student, :html => "reply")
      @topic.posters.should include(@student)
    end

    it "should dedupe users" do
      @entry = @topic.reply_from(:user => @teacher, :text => "entry")
      @student = student_in_course(:active_all => true).user
      @entry.reply_from(:user => @student, :html => "reply 1")
      @entry.reply_from(:user => @student, :html => "reply 2")
      @topic.posters.should include(@teacher)
      @topic.posters.should include(@student)
      @topic.posters.size.should == 2
    end

    it "should not include topic author if she is no longer enrolled in the course" do
      student_in_course(:active_all => true)
      @topic2 = @course.discussion_topics.create!(:title => "student topic", :message => "I'm outta here", :user => @student)
      @entry = @topic2.discussion_entries.create!(:message => "go away", :user => @teacher)
      @topic2.posters.map(&:id).sort.should eql [@student.id, @teacher.id].sort
      @student.enrollments.first.destroy
      @topic2.posters.map(&:id).sort.should eql [@teacher.id].sort
    end
  end

  context "submissions when graded" do
    before :each do
      @teacher = course_with_teacher(:active_all => true).user
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    def build_submitted_assignment
      student_in_course(name: 'student in course', active_all: true)
      @assignment = @course.assignments.create!(:title => "some discussion assignment")
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!
      @topic.assignment_id = @assignment.id
      @topic.save!
      @entry1 = @topic.discussion_entries.create!(:message => "second message", :user => @user)
      @entry1.created_at = 1.week.ago
      @entry1.save!
      @submission = @assignment.submissions.where(:user_id => @entry1.user_id).first
    end

    it "should not re-flag graded discussion as needs grading if student make another comment" do
      student_in_course(name: 'student in course', active_all: true)
      assignment = @course.assignments.create(:title => "discussion assignment", :points_possible => 20)
      topic = @course.discussion_topics.create!(:title => 'discussion topic 1', :message => "this is a new discussion topic", :assignment => assignment)
      topic.discussion_entries.create!(:message => "student message for grading", :user => @student)

      submissions = Submission.find_all_by_user_id_and_assignment_id(@student.id, assignment.id)
      submissions.count.should == 1
      student_submission = submissions.first
      assignment.grade_student(@student, {:grade => 9})
      student_submission.reload
      student_submission.workflow_state.should == 'graded'

      topic.discussion_entries.create!(:message => "student message 2 for grading", :user => @student)
      submissions = Submission.find_all_by_user_id_and_assignment_id(@student.id, assignment.id)
      submissions.count.should == 1
      student_submission = submissions.first
      student_submission.workflow_state.should == 'graded'
    end

    it "should create submissions for existing entries when setting the assignment" do
      @student = student_in_course(:active_all => true).user
      @topic.reply_from(:user => @student, :text => "entry")
      @student.reload
      @student.submissions.should be_empty

      @assignment = assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save
      @student.reload
      @student.submissions.size.should == 1
      @student.submissions.first.submission_type.should == 'discussion_topic'
    end

    it "should have the correct submission date if submission has comment" do
      student_in_course(:active_all => true)
      @assignment = @course.assignments.create!(:title => "some discussion assignment")
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!
      @topic.assignment = @assignment
      @topic.save
      te = @course.enroll_teacher(user)
      @submission = @assignment.find_or_create_submission(@student.id)
      @submission_comment = @submission.add_comment(:author => te.user, :comment => "some comment")
      @submission.created_at = 1.week.ago
      @submission.save!
      @submission.workflow_state.should == 'unsubmitted'
      @submission.submitted_at.should be_nil
      @entry = @topic.discussion_entries.create!(:message => "somne discussion message", :user => @student)
      @submission.reload
      @submission.workflow_state.should == 'submitted'
      @submission.submitted_at.to_i.should >= @entry.created_at.to_i #this time may not be exact because it goes off of time.now in the submission
    end

    it "should fix submission date after deleting the oldest entry" do
      build_submitted_assignment()
      @entry2 = @topic.discussion_entries.create!(:message => "some message", :user => @user)
      @entry2.created_at = 1.day.ago
      @entry2.save!
      @entry1.destroy
      @topic.reload
      @topic.discussion_entries.should_not be_empty
      @topic.discussion_entries.active.should_not be_empty
      @submission.reload
      @submission.submitted_at.to_i.should == @entry2.created_at.to_i
      @submission.workflow_state.should == 'submitted'
    end

    it "should mark submission as unsubmitted after deletion" do
      build_submitted_assignment()
      @entry1.destroy
      @topic.reload
      @topic.discussion_entries.should_not be_empty
      @topic.discussion_entries.active.should be_empty
      @submission.reload
      @submission.workflow_state.should == 'unsubmitted'
      @submission.submission_type.should == nil
      @submission.submitted_at.should == nil
    end

    it "should have new submission date after deletion and re-submission" do
      build_submitted_assignment()
      @entry1.destroy
      @topic.reload
      @topic.discussion_entries.should_not be_empty
      @topic.discussion_entries.active.should be_empty
      @entry2 = @topic.discussion_entries.create!(:message => "some message", :user => @user)
      @submission.reload
      @submission.submitted_at.to_i.should >= @entry2.created_at.to_i #this time may not be exact because it goes off of time.now in the submission
      @submission.workflow_state.should == 'submitted'
    end

    it "should not duplicate submissions for existing entries that already have submissions" do
      @student = student_in_course(:active_all => true).user

      @assignment = assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save
      @topic.reload # to get the student in topic.assignment.context.students

      @topic.reply_from(:user => @student, :text => "entry")
      @student.reload
      @student.submissions.size.should == 1
      @existing_submission_id = @student.submissions.first.id

      @topic.assignment = nil
      @topic.save
      @topic.reply_from(:user => @student, :text => "another entry")
      @student.reload
      @student.submissions.size.should == 1
      @student.submissions.first.id.should == @existing_submission_id

      @topic.assignment = @assignment
      @topic.save
      @student.reload
      @student.submissions.size.should == 1
      @student.submissions.first.id.should == @existing_submission_id
    end

    it "should not resubmit graded discussion submissions" do
      @student = student_in_course(:active_all => true).user

      @assignment = assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save!
      @topic.reload

      @topic.reply_from(:user => @student, :text => "entry")
      @student.reload

      @assignment.grade_student(@student, :grade => 1)
      @submission = Submission.where(:user_id => @student, :assignment_id => @assignment).first
      @submission.workflow_state.should == 'graded'

      @topic.ensure_submission(@student)
      @submission.reload.workflow_state.should == 'graded'
    end
  end

  context "read/unread state" do
    before(:each) do
      course_with_teacher(:active_all => true)
      student_in_course(:active_all => true)
      @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher)
    end

    it "should mark a topic you created as read" do
      @topic.read?(@teacher).should be_true
      @topic.unread_count(@teacher).should == 0
    end

    it "should be unread by default" do
      @topic.read?(@student).should be_false
      @topic.unread_count(@student).should == 0
    end

    it "should allow being marked unread" do
      @topic.change_read_state("unread", @teacher)
      @topic.reload
      @topic.read?(@teacher).should be_false
      @topic.unread_count(@teacher).should == 0
    end

    it "should allow being marked read" do
      @topic.change_read_state("read", @student)
      @topic.reload
      @topic.read?(@student).should be_true
      @topic.unread_count(@student).should == 0
    end

    it "should allow mark all as unread with forced_read_state" do
      @entry = @topic.discussion_entries.create!(:message => "Hello!", :user => @teacher)
      @reply = @entry.reply_from(:user => @student, :text => "ohai!")
      @reply.change_read_state('read', @teacher, :forced => false)

      @topic.change_all_read_state("unread", @teacher, :forced => true)
      @topic.reload
      @topic.read?(@teacher).should be_false

      @entry.read?(@teacher).should be_false
      @entry.find_existing_participant(@teacher).should be_forced_read_state

      @reply.read?(@teacher).should be_false
      @reply.find_existing_participant(@teacher).should be_forced_read_state

      @topic.unread_count(@teacher).should == 2
    end

    it "should allow mark all as read without forced_read_state" do
      @entry = @topic.discussion_entries.create!(:message => "Hello!", :user => @teacher)
      @reply = @entry.reply_from(:user => @student, :text => "ohai!")
      @reply.change_read_state('unread', @student, :forced => true)

      @topic.change_all_read_state("read", @student)
      @topic.reload

      @topic.read?(@student).should be_true

      @entry.read?(@student).should be_true
      @entry.find_existing_participant(@student).should_not be_forced_read_state

      @reply.read?(@student).should be_true
      @reply.find_existing_participant(@student).should be_forced_read_state

      @topic.unread_count(@student).should == 0
    end

    it "should use unique_constaint_retry when updating read state" do
      DiscussionTopic.expects(:unique_constraint_retry).once
      @topic.change_read_state("read", @student)
    end

    it "should use unique_constaint_retry when updating all read state" do
      DiscussionTopic.expects(:unique_constraint_retry).once
      @topic.change_all_read_state("unread", @student)
    end

    it "should sync unread state with the stream item" do
      @stream_item = @topic.stream_item(true)
      @stream_item.stream_item_instances.detect{|sii| sii.user_id == @teacher.id}.should be_read
      @stream_item.stream_item_instances.detect{|sii| sii.user_id == @student.id}.should be_unread

      @topic.change_all_read_state("unread", @teacher)
      @topic.change_all_read_state("read", @student)
      @topic.reload

      @stream_item = @topic.stream_item
      @stream_item.stream_item_instances.detect{|sii| sii.user_id == @teacher.id}.should be_unread
      @stream_item.stream_item_instances.detect{|sii| sii.user_id == @student.id}.should be_read
    end
  end

  context "subscribing" do
    before :each do
      course_with_student(:active_all => true)
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    it "should allow subscription" do
      @topic.subscribed?(@student).should be_false
      @topic.subscribe(@student)
      @topic.subscribed?(@student).should be_true
    end

    it "should allow unsubscription" do
      @topic.subscribed?(@teacher).should be_true
      @topic.unsubscribe(@teacher)
      @topic.subscribed?(@teacher).should be_false
    end

    it "should be idempotent" do
      @topic.subscribed?(@student).should be_false
      @topic.unsubscribe(@student)
      @topic.subscribed?(@student).should be_false
    end

    it "should assume the author is subscribed" do
      @topic.subscribed?(@teacher).should be_true
    end

    it "should assume posters are subscribed" do
      @topic.reply_from(:user => @student, :text => 'first post!')
      @topic.subscribed?(@student).should be_true
    end

    context "when initial_post_required" do
      it "should unsubscribe a user when all of their posts are deleted" do
        @topic.require_initial_post = true
        @topic.save!
        @entry = @topic.reply_from(:user => @student, :text => 'first post!')
        @topic.subscribed?(@student).should be_true
        @entry.destroy
        @topic.subscribed?(@student).should be_false
      end
    end
  end

  context "subscription holds" do
    before :each do
      course_with_student(:active_all => true)
      @context = @course
    end

    it "should hold when requiring an initial post" do
      discussion_topic_model(:user => @teacher, :require_initial_post => true)
      @topic.subscription_hold(@student, nil, nil).should eql(:initial_post_required)
    end

    it "should hold when the user is not in a group set" do
      # i.e. when you check holds on a root topic and no child topics are for groups
      # the user is in
      group_discussion_assignment
      @topic.subscription_hold(@student, nil, nil).should eql(:not_in_group_set)
    end

    it "should hold when the user is not in a group" do
      group_discussion_assignment
      @topic.child_topics.first.subscription_hold(@student, nil, nil).should eql(:not_in_group)
    end

    it "should not subscribe the author if there is a hold" do
      group_discussion_assignment
      @topic.user = @teacher
      @topic.save!
      @topic.subscription_hold(@teacher, nil, nil).should eql(:not_in_group_set)
      @topic.subscribed?(@teacher).should be_false
    end

    it "should set the topic participant subscribed field to false when there is a hold" do
      teacher_in_course(:active_all => true)
      group_discussion_assignment
      group_discussion = @topic.child_topics.first
      group_discussion.user = @teacher
      group_discussion.save!
      group_discussion.change_read_state('read', @teacher) # quick way to make a participant
      group_discussion.discussion_topic_participants.where(:user_id => @teacher.id).first.subscribed.should == false
    end
  end

  context "a group topic subscription" do

    before(:each) do
      group_discussion_assignment
      course_with_student(active_all: true)
    end

    it "should return true if the user is subscribed to a child topic" do
      @topic.child_topics.first.subscribe(@student)
      @topic.child_topics.first.subscribed?(@student).should be_true
      @topic.subscribed?(@student).should be_true
    end

    it "should return true if the user has posted to a child topic" do
      child_topic = @topic.child_topics.first
      child_topic.context.add_user(@student)
      child_topic.reply_from(:user => @student, :text => "post")
      child_topic_participant = child_topic.update_or_create_participant(:current_user => @student, :subscribed => nil)
      child_topic_participant.subscribed.should be_nil
      @topic.subscribed?(@student).should be_true
    end

    it "should subscribe a group user to the child topic" do
      child_one, child_two = @topic.child_topics
      child_one.context.add_user(@student)
      @topic.subscribe(@student)

      child_one.subscribed?(@student).should be_true
      child_two.subscribed?(@student).should_not be_true
      @topic.subscribed?(@student).should be_true
    end

    it "should unsubscribe a group user from the child topic" do
      child_one, child_two = @topic.child_topics
      child_one.context.add_user(@student)
      @topic.subscribe(@student)
      @topic.unsubscribe(@student)

      child_one.subscribed?(@student).should_not be_true
      child_two.subscribed?(@student).should_not be_true
      @topic.subscribed?(@student).should_not be_true
    end
  end

  context "materialized view" do
    before do
      topic_with_nested_replies
      # materialized view jobs are now delayed
      Timecop.travel(Time.now + 20.seconds)
    end

    it "should return nil if the view has not been built yet, and schedule a job" do
      DiscussionTopic::MaterializedView.for(@topic).destroy
      @topic.materialized_view.should be_nil
      @topic.materialized_view.should be_nil
      Delayed::Job.strand_size("materialized_discussion:#{@topic.id}").should == 1
    end

    it "should return the materialized view if it's up to date" do
      run_jobs
      view = DiscussionTopic::MaterializedView.find_by_discussion_topic_id(@topic.id)
      @topic.materialized_view.should == [view.json_structure, view.participants_array, view.entry_ids_array, []]
    end

    it "should update the materialized view on new entry" do
      run_jobs
      Delayed::Job.strand_size("materialized_discussion:#{@topic.id}").should == 0
      @topic.reply_from(:user => @user, :text => "ohai")
      Delayed::Job.strand_size("materialized_discussion:#{@topic.id}").should == 1
    end

    it "should update the materialized view on edited entry" do
      reply = @topic.reply_from(:user => @user, :text => "ohai")
      run_jobs
      Delayed::Job.strand_size("materialized_discussion:#{@topic.id}").should == 0
      reply.update_attributes(:message => "i got that wrong before")
      Delayed::Job.strand_size("materialized_discussion:#{@topic.id}").should == 1
    end

    it "should return empty data for a materialized view on a new (unsaved) topic" do
      new_topic = DiscussionTopic.new(:context => @topic.context, :discussion_type => DiscussionTopic::DiscussionTypes::SIDE_COMMENT)
      new_topic.should be_new_record
      new_topic.materialized_view.should == [ "[]", [], [], [] ]
      Delayed::Job.strand_size("materialized_discussion:#{new_topic.id}").should == 0
    end
  end

  context "destroy" do
    it "should destroy the assignment and associated child topics" do
      group_discussion_assignment
      @topic.destroy
      @topic.reload.should be_deleted
      @topic.child_topics.each{ |ct| ct.reload.should be_deleted }
      @assignment.reload.should be_deleted
    end

    it "should not revive the assignment if updated when deleted" do
      group_discussion_assignment
      @topic.destroy
      @assignment.reload.should be_deleted
      @topic.touch
      @assignment.reload.should be_deleted
    end
  end

  context "restore" do
    it "should restore the assignment and associated child topics" do
      group_discussion_assignment
      @topic.destroy

      @topic.reload.assignment.expects(:restore).with(:discussion_topic).once
      @topic.restore
      @topic.reload.should be_active
      @topic.child_topics.each { |ct| ct.reload.should be_active }
    end

    it "should restore to unpublished state if draft mode is enabled" do
      group_discussion_assignment
      @course.root_account.enable_feature!(:draft_state)
      @topic.destroy

      @topic.reload.assignment.expects(:restore).with(:discussion_topic).once
      @topic.restore
      @topic.reload.should be_post_delayed
      @topic.child_topics.each { |ct| ct.reload.should be_post_delayed }
    end
  end

  describe "reply_from" do
    it "should ignore responses in deleted account" do
      account = Account.create!
      @teacher = course_with_teacher(:active_all => true, :account => account).user
      @context = @course
      discussion_topic_model(:user => @teacher)
      account.destroy
      lambda { @topic.reply_from(:user => @teacher, :text => "entry") }.should raise_error(IncomingMail::UnknownAddressError)
    end

    it "should prefer html to text" do
      course_with_teacher
      discussion_topic_model
      msg = @topic.reply_from(:user => @teacher, :text => "text body", :html => "<p>html body</p>")
      msg.should_not be_nil
      msg.message.should == "<p>html body</p>"
    end

    it "should not allow replies to locked topics" do
      course_with_teacher
      discussion_topic_model
      @topic.lock!
      lambda { @topic.reply_from(:user => @teacher, :text => "reply") }.should raise_error(IncomingMail::ReplyToLockedTopicError)
    end

  end

  describe "locked flag" do
    before :each do
      discussion_topic_model
    end

    it "should ignore workflow_state if the flag is set" do
      @topic.locked = true
      @topic.workflow_state = 'active'
      @topic.locked?.should be_true
      @topic.locked = false
      @topic.workflow_state = 'locked'
      @topic.locked?.should be_false
    end

    it "should fall back to the workflow_state if the flag is nil" do
      @topic.locked = nil
      @topic.workflow_state = 'active'
      @topic.locked?.should be_false
      @topic.workflow_state = 'locked'
      @topic.locked?.should be_true
    end

    it "should fix up a 'locked' workflow_state" do
      @topic.workflow_state = 'locked'
      @topic.locked = nil
      @topic.save!
      @topic.unlock!
      @topic.workflow_state.should eql 'active'
      @topic.locked?.should be_false
    end
  end
end
