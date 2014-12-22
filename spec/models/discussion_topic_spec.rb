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
  before :once do
    course_with_teacher(:active_all => 1)
    student_in_course(:active_all => 1)
  end

  it "should santize message" do
    @course.discussion_topics.create!(:message => "<a href='#' onclick='alert(12);'>only this should stay</a>")
    expect(@course.discussion_topics.first.message).to eql("<a href=\"#\">only this should stay</a>")
  end

  it "should default to side_comment type" do
    d = DiscussionTopic.new
    expect(d.discussion_type).to eq 'side_comment'

    d.threaded = '1'
    expect(d.discussion_type).to eq 'threaded'

    d.threaded = ''
    expect(d.discussion_type).to eq 'side_comment'
  end

  it "should require a valid discussion_type" do
    @topic = @course.discussion_topics.build(:message => 'test', :discussion_type => "gesundheit")
    expect(@topic.save).to eq false
    expect(@topic.errors.detect { |e| e.first.to_s == 'discussion_type' }).to be_present
  end

  it "should update the assignment it is associated with" do
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    expect(a.points_possible).to eql(5.0)
    expect(a.submission_types).not_to eql("online_quiz")
    t = @course.discussion_topics.build(:assignment => a, :title => "some topic", :message => "a little bit of content")
    t.save
    expect(t.assignment_id).to eql(a.id)
    expect(t.assignment).to eql(a)
    a.reload
    expect(a.discussion_topic).to eql(t)
    expect(a.submission_types).to eql("discussion_topic")
  end

  it "should delete the assignment if the topic is no longer graded" do
    a = @course.assignments.create!(:title => "some assignment", :points_possible => 5)
    expect(a.points_possible).to eql(5.0)
    expect(a.submission_types).not_to eql("online_quiz")
    t = @course.discussion_topics.build(:assignment => a, :title => "some topic", :message => "a little bit of content")
    t.save
    expect(t.assignment_id).to eql(a.id)
    expect(t.assignment).to eql(a)
    a.reload
    expect(a.discussion_topic).to eql(t)
    t.assignment = nil
    t.save
    t.reload
    expect(t.assignment_id).to eql(nil)
    expect(t.assignment).to eql(nil)
    a.reload
    expect(a).to be_deleted
  end

  context "permissions" do
    before :each do
      @teacher1 = @teacher
      @teacher2 = user
      teacher_in_course(:course => @course, :user => @teacher2, :active_all => true)

      @topic = @course.discussion_topics.create!(:user => @teacher1)
      @topic.unpublish!
      @entry = @topic.discussion_entries.create!(:user => @teacher1)
      @entry.discussion_topic = @topic

      @relevant_permissions = [:read, :reply, :update, :delete]
    end

    it "should grant permissions if it not locked" do
      @topic.publish!
      expect((@topic.check_policy(@teacher1) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@topic.check_policy(@teacher2) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@topic.check_policy(@student) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply'].sort

      expect((@entry.check_policy(@teacher1) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@entry.check_policy(@teacher2) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@entry.check_policy(@student) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply'].sort
    end

    it "should not grant reply permissions to students if it is locked" do
      @topic.publish!
      @topic.lock!
      expect((@topic.check_policy(@teacher1) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@topic.check_policy(@teacher2) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@topic.check_policy(@student) & @relevant_permissions).map(&:to_s)).to eq ['read']

      expect((@entry.check_policy(@teacher1) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@entry.check_policy(@teacher2) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@entry.check_policy(@student) & @relevant_permissions).map(&:to_s)).to eq ['read']
    end

    it "should not grant any permissions to students if it is unpublished" do
      expect((@topic.check_policy(@teacher1) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@topic.check_policy(@teacher2) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@topic.check_policy(@student) & @relevant_permissions).map(&:to_s).sort).to eq []

      expect((@entry.check_policy(@teacher1) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@entry.check_policy(@teacher2) & @relevant_permissions).map(&:to_s).sort).to eq ['read', 'reply', 'update', 'delete'].sort
      expect((@entry.check_policy(@student) & @relevant_permissions).map(&:to_s).sort).to eq []
    end
  end

  describe "visibility" do
    before(:once) do
      #course_with_teacher(:active_all => 1, :draft_state => false) # this does not disable draft state if it is switched on at the account level
      #student_in_course(:active_all => 1)
      @course.disable_feature!(:draft_state)
      @topic = @course.discussion_topics.create!(:user => @teacher)
    end

    context "with draft state enabled" do
      before(:once) do
        @course.enable_feature!(:draft_state)
      end

      it "should be visible to author when unpublished" do
        @topic.unpublish!
        expect(@topic.visible_for?(@teacher)).to be_truthy
      end

      it "should be visible when published even when for delayed posting" do
        @topic.delayed_post_at = 5.days.from_now
        @topic.workflow_state = 'post_delayed'
        @topic.save!
        expect(@topic.visible_for?(@student)).to be_truthy
      end
    end

    it "should not be visible when unpublished even when it is active" do
      @topic.unpublish!
      expect(@topic.visible_for?(@student)).to be_falsey
    end

    it "should be visible to students when topic is not locked" do
      expect(@topic.visible_for?(@student)).to be_truthy
    end

    it "should not be visible to students when topic delayed_post_at is in the future" do
      @topic.delayed_post_at = 5.days.from_now
      @topic.save!
      expect(@topic.visible_for?(@student)).to @topic.draft_state_enabled? ? be_truthy : be_falsey
    end

    it "should not be visible to students when topic is for delayed posting" do
      @topic.workflow_state = 'post_delayed'
      @topic.save!
      expect(@topic.visible_for?(@student)).to @topic.draft_state_enabled? ? be_truthy : be_falsey
    end

    it "should be visible to students when topic delayed_post_at is in the past" do
      @topic.delayed_post_at = 5.days.ago
      @topic.save!
      expect(@topic.visible_for?(@student)).to be_truthy
    end

    it "should be visible to students when topic delayed_post_at is nil" do
      @topic.delayed_post_at = nil
      @topic.save!
      expect(@topic.visible_for?(@student)).to be_truthy
    end

    it "should not be visible when no delayed_post but assignment unlock date in future" do
      @topic.delayed_post_at = nil
      group_category = @course.group_categories.create(:name => "category")
      @topic.group_category = group_category
      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic',
        :title => @topic.title,
        :unlock_at => 10.days.from_now,
        :lock_at => 30.days.from_now)
      @topic.assignment.infer_times
      @topic.assignment.saved_by = :discussion_topic
      @topic.save

      expect(@topic.visible_for?(@student)).to @topic.draft_state_enabled? ? be_truthy : be_falsey
    end

    it "should be visible to all teachers in the course" do
      @topic.update_attribute(:delayed_post_at, Time.now + 1.day)
      new_teacher = user
      @course.enroll_teacher(new_teacher).accept!
      expect(@topic.visible_for?(new_teacher)).to be_truthy
    end

    context "differentiated assignements" do
      before do
        @course = course(:active_course => true)
        discussion_topic_model(:user => @teacher, :context => @course)
        @course.enroll_teacher(@teacher).accept!
        @course_section = @course.course_sections.create
        @student1, @student2, @student3 = create_users(3, return_type: :record)

        @assignment = @course.assignments.create!(:title => "some discussion assignment", only_visible_to_overrides: true)
        @assignment.submission_types = 'discussion_topic'
        @assignment.save!
        @topic.assignment_id = @assignment.id
        @topic.save!
        @entry1 = @topic.discussion_entries.create!(:message => "second message", :user => @student)
        @entry1.created_at = 1.week.ago
        @entry1.save

        @course.enroll_student(@student2, :enrollment_state => 'active')
        @section = @course.course_sections.create!(name: "test section")
        @section2 = @course.course_sections.create!(name: "second test section")
        student_in_section(@section, user: @student1)
        create_section_override_for_assignment(@assignment, {course_section: @section})
        @course.reload
      end

      context "feature flag on" do
        before {@course.enable_feature!(:differentiated_assignments)}
        it "should be visible to a student with an override" do
          expect(@topic.visible_for?(@student1)).to be_truthy
        end
        it "should not be visible to a student without an override" do
          expect(@topic.visible_for?(@student2)).to be_falsey
        end
        it "should be visible to a teacher" do
          expect(@topic.visible_for?(@teacher)).to be_truthy
        end
        it "should not grant reply permissions to a student without an override" do
          expect(@topic.check_policy(@student1)).to include :reply
          expect(@topic.check_policy(@student2)).not_to include :reply
        end
        context "active_participants_with_visibility" do
          it "should filter participants by visibility" do
            [@student1, @teacher].each do |user|
              expect(@topic.active_participants_with_visibility.include?(user)).to be_truthy
            end
            expect(@topic.active_participants_with_visibility.include?(@student2)).to be_falsey
          end
        end
      end

      context "feature flag off" do
        before {@course.disable_feature!(:differentiated_assignments)}
        it "should be visible to everybody in the class" do
          [@student1,@student2,@teacher].each do |user|
            expect(@topic.visible_for?(user)).to be_truthy
          end
        end
        context "active_participants_with_visibility" do
          it "should not filter any participants" do
            [@student1,@student2].each do |user|
              expect(@topic.active_participants_with_visibility.include?(user)).to be_truthy
            end
          end
        end
      end
    end
  end

  def discussion_with_assignment(opts={})
    assignment = @course.assignments.create!(:title => "some discussion assignment", only_visible_to_overrides: !!opts[:only_visible_to_overrides])
    assignment.submission_types = 'discussion_topic'
    assignment.save!
    topic = assignment.discussion_topic
    topic.save!
    [topic, assignment]
  end

  context "visible_ids_by_user" do
    before :once do
      @course = course(:active_course => true)
      discussion_topic_model(:user => @teacher)
      @topic_without_assignment = @topic
      @course_section = @course.course_sections.create
      @student1, @student2, @student3 = create_users(3, return_type: :record)

      @topic_with_assignment_and_only_vis, @assignment = discussion_with_assignment(only_visible_to_overrides: true)
      @topic_with_assignment_and_visible_to_all, @assignment2 = discussion_with_assignment(only_visible_to_overrides: false)
      @topic_with_override_for_section_with_no_students, @assignment3 = discussion_with_assignment(only_visible_to_overrides: true)
      @topic_with_no_override, @assignment4 = discussion_with_assignment(only_visible_to_overrides: true)

      @course.enroll_student(@student2, :enrollment_state => 'active')
      @section = @course.course_sections.create!(name: "test section")
      @section2 = @course.course_sections.create!(name: "second test section")
      student_in_section(@section, user: @student1)
      create_section_override_for_assignment(@assignment, {course_section: @section})
      create_section_override_for_assignment(@assignment3, {course_section: @section2})
      @course.enable_feature!(:differentiated_assignments)
      @course.reload
      @vis_hash = DiscussionTopic.visible_ids_by_user(course_id: @course.id, user_id: [@student1, @student2, @student3].map(&:id))
    end

    it "should return both topics for a student with an override" do
      expect(@vis_hash[@student1.id].sort).to eq [@topic_without_assignment.id, @topic_with_assignment_and_only_vis.id, @topic_with_assignment_and_visible_to_all.id].sort
    end

    it "should not return differentiated topics to a student with no overrides" do
      expect(@vis_hash[@student2.id].sort).to eq [@topic_without_assignment.id, @topic_with_assignment_and_visible_to_all.id].sort
    end
  end

  describe "allow_student_discussion_topics setting" do

    before(:once) do
      @topic = @course.discussion_topics.create!(:user => @teacher)
    end

    it "should allow students to create topics by default" do
      expect(@topic.check_policy(@teacher)).to include :create
      expect(@topic.check_policy(@student)).to include :create
    end

    it "should disallow students from creating topics" do
      @course.allow_student_discussion_topics = false
      @course.save!
      @topic.reload
      expect(@topic.check_policy(@teacher)).to include :create
      expect(@topic.check_policy(@student)).not_to include :create
    end

  end

  context "observers" do
    before :once do
      course_with_observer(:course => @course, :active_all => true)
    end

    it "should grant observers read permission by default" do
      @relevant_permissions = [:read, :reply, :update, :delete]

      @topic = @course.discussion_topics.create!(:user => @teacher)
      expect((@topic.check_policy(@observer) & @relevant_permissions).map(&:to_s).sort).to eq ['read'].sort
      @entry = @topic.discussion_entries.create!(:user => @teacher)
      expect((@entry.check_policy(@observer) & @relevant_permissions).map(&:to_s).sort).to eq ['read'].sort
    end

    it "should not grant observers read permission when read_forum override is false" do
      RoleOverride.create!(:context => @course.account, :permission => 'read_forum',
                           :role => observer_role, :enabled => false)

      @relevant_permissions = [:read, :reply, :update, :delete]
      @topic = @course.discussion_topics.create!(:user => @teacher)
      expect((@topic.check_policy(@observer) & @relevant_permissions).map(&:to_s)).to be_empty
      @entry = @topic.discussion_entries.create!(:user => @teacher)
      expect((@entry.check_policy(@observer) & @relevant_permissions).map(&:to_s)).to be_empty
    end
  end

  context "delayed posting" do
    before :once do
      @student.register
    end

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
      topic = @course.discussion_topics.create!(:title => "this should not be delayed", :message => "content here")
      expect(topic.stream_item).not_to be_nil

      topic = delayed_discussion_topic(:title => "this should be delayed", :message => "content here", :delayed_post_at => Time.now + 1.day)
      expect(topic.stream_item).to be_nil

      topic.message = "content changed!"
      topic.save
      expect(topic.stream_item).to be_nil
    end

    it "should send to streams on update from delayed to active" do
      topic = delayed_discussion_topic(:title => "this should be delayed", :message => "content here", :delayed_post_at => Time.now + 1.day)
      expect(topic.workflow_state).to eq 'post_delayed'
      expect(topic.stream_item).to be_nil

      topic.delayed_post_at = nil
      topic.title = "this isn't delayed any more"
      topic.workflow_state = 'active'
      topic.save!
      expect(topic.stream_item).not_to be_nil
    end

    describe "#update_based_on_date" do
      it "should be active when delayed_post_at is in the past" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => Time.now - 1.day,
                                         :lock_at => nil)
        topic.update_based_on_date
        expect(topic.workflow_state).to eql 'active'
        expect(topic.locked?).to be_falsey
      end

      it "should be post_delayed when delayed_post_at is in the future" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => Time.now + 1.day,
                                         :lock_at => nil)
        topic.update_based_on_date
        expect(topic.workflow_state).to eql 'post_delayed'
        expect(topic.locked?).to be_falsey
      end

      it "should be locked when lock_at is in the past" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => nil,
                                         :lock_at => Time.now - 1.day)
        topic.update_based_on_date
        expect(topic.locked?).to be_truthy
      end

      it "should be active when lock_at is in the future" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => nil,
                                         :lock_at => Time.now + 1.day)
        topic.update_based_on_date
        expect(topic.workflow_state).to eql 'active'
        expect(topic.locked?).to be_falsey
      end

      it "should be active when now is between delayed_post_at and lock_at" do
        topic = delayed_discussion_topic(:title => "title",
                                         :message => "content here",
                                         :delayed_post_at => Time.now - 1.day,
                                         :lock_at => Time.now + 1.day)
        topic.update_based_on_date
        expect(topic.workflow_state).to eql 'active'
        expect(topic.locked?).to be_falsey
      end

      it "should be post_delayed when delayed_post_at and lock_at are in the future" do
        topic = delayed_discussion_topic(:title           => "title",
                                         :message         => "content here",
                                         :delayed_post_at => Time.now + 1.day,
                                         :lock_at         => Time.now + 3.days)
        topic.update_based_on_date
        expect(topic.workflow_state).to eql 'post_delayed'
        expect(topic.locked?).to be_falsey
      end

      it "should be locked when delayed_post_at and lock_at are in the past" do
        topic = delayed_discussion_topic(:title           => "title",
                                         :message         => "content here",
                                         :delayed_post_at => Time.now - 3.days,
                                         :lock_at         => Time.now - 1.day)
        topic.update_based_on_date
        expect(topic.workflow_state).to eql 'active'
        expect(topic.locked?).to be_truthy
      end

      it "should not unlock a topic even if the lock date is in the future" do
        topic = discussion_topic(:title           => "title",
                                 :message         => "content here",
                                 :workflow_state  => 'locked',
                                 :locked          => true,
                                 :delayed_post_at => nil,
                                 :lock_at         => Time.now + 1.day)
        topic.update_based_on_date
        expect(topic.locked?).to be_truthy
      end

      it "should not mark a topic with post_delayed even if delayed_post_at even is in the future" do
        topic = discussion_topic(:title           => "title",
                                 :message         => "content here",
                                 :workflow_state  => 'active',
                                 :delayed_post_at => Time.now + 1.day,
                                 :lock_at         => nil)
        topic.update_based_on_date
        expect(topic.workflow_state).to eql 'active'
        expect(topic.locked?).to be_falsey
      end
    end
  end

  context "sub-topics" do
    it "should default subtopics_refreshed_at on save if a group discussion" do
      group_category = @course.group_categories.create(:name => "category")
      @group = @course.groups.create(:name => "group", :group_category => group_category)
      @topic = @course.discussion_topics.create(:title => "topic")
      expect(@topic.subtopics_refreshed_at).to be_nil

      @topic.group_category = group_category
      @topic.save
      expect(@topic.subtopics_refreshed_at).not_to be_nil
    end

    it "should not allow students to edit sub-topics" do
      @first_user = @student
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
      expect(@group_topic.grants_right?(@second_user, :update)).to eql(false)
      expect(@sub_topic.grants_right?(@second_user, :update)).to eql(false)
    end
  end

  context "refresh_subtopics" do
    it "should be a no-op unless it has a group_category" do
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.refresh_subtopics
      expect(@topic.reload.child_topics).to be_empty

      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @topic.assignment.saved_by = :discussion_topic
      @topic.save
      @topic.refresh_subtopics
      expect(@topic.reload.child_topics).to be_empty
    end

    context "in a group discussion" do
      before :once do
        group_discussion_assignment
      end

      it "should create a topic per active group in the category otherwise" do
        @topic.refresh_subtopics
        subtopics = @topic.reload.child_topics
        expect(subtopics).not_to be_nil
        expect(subtopics.size).to eq 2
        subtopics.each { |t| expect(t.root_topic).to eq @topic }
        expect(@group1.reload.discussion_topics).not_to be_empty
        expect(@group2.reload.discussion_topics).not_to be_empty
      end

      it "should copy appropriate attributes from the parent topic to subtopics on updates to the parent" do
        @topic.refresh_subtopics
        subtopics = @topic.reload.child_topics
        subtopics.each {|st| expect(st.discussion_type).to eq 'side_comment' }
        @topic.discussion_type = 'threaded'
        @topic.save!
        subtopics.each {|st| expect(st.reload.discussion_type).to eq 'threaded' }
      end

      it "should not rename the assignment to match a subtopic" do
        original_name = @assignment.title
        @assignment.reload
        expect(@assignment.title).to eq original_name
      end
    end
  end

  context "root_topic?" do
    it "should be false if the topic has a root topic" do
      # subtopic has the assignment and group_category, but has a root topic
      group_category = @course.group_categories.create(:name => "category")
      @parent_topic = @course.discussion_topics.create(:title => "parent topic")
      @parent_topic.group_category = group_category
      @subtopic = @parent_topic.child_topics.build(:title => "subtopic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @subtopic.title)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @subtopic.assignment = @assignment
      @subtopic.group_category = group_category
      @subtopic.save

      expect(@subtopic).not_to be_root_topic
    end

    it "should be false unless the topic has an assignment" do
      # topic has no root topic, but also has no assignment
      @topic = @course.discussion_topics.create(:title => "subtopic")
      expect(@topic).not_to be_root_topic
    end

    it "should be false unless the topic has a group_category" do
      # topic has no root topic and has an assignment, but the assignment has no group_category
      @topic = @course.discussion_topics.create(:title => "topic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save

      expect(@topic).not_to be_root_topic
    end

    it "should be true otherwise" do
      # topic meets all criteria
      group_category = @course.group_categories.create(:name => "category")
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.group_category = group_category
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save

      expect(@topic).to be_root_topic
    end
  end

  context "#discussion_subentry_count" do
    it "returns the count of all active discussion_entries" do
      @topic = @course.discussion_topics.create(:title => "topic")
      @topic.reply_from(:user => @teacher, :text => "entry 1").destroy  # no count
      @topic.reply_from(:user => @teacher, :text => "entry 1")          # 1
      @entry = @topic.reply_from(:user => @teacher, :text => "entry 2") # 2
      @entry.reply_from(:user => @student, :html => "reply 1")          # 3
      @entry.reply_from(:user => @student, :html => "reply 2")          # 4
      # expect
      expect(@topic.discussion_subentry_count).to eq 4
    end
  end

  context "for_assignment?" do
    it "should not be for_assignment? unless it has an assignment" do
      @topic = @course.discussion_topics.create(:title => "topic")
      expect(@topic).not_to be_for_assignment

      @topic.assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @topic.assignment.infer_times
      @topic.assignment.saved_by = :discussion_topic
      @topic.save
      expect(@topic).to be_for_assignment
    end
  end

  context "for_group_discussion?" do
    it "should not be for_group_discussion? unless it has a group_category" do
      course_with_student(:active_all => true)
      @topic = @course.discussion_topics.build(:title => "topic")
      @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title)
      @assignment.infer_times
      @assignment.saved_by = :discussion_topic
      @topic.assignment = @assignment
      @topic.save
      expect(@topic).not_to be_for_group_discussion

      @topic.group_category = @course.group_categories.create(:name => "category")
      @topic.save
      expect(@topic).to be_for_group_discussion
    end
  end

  context "should_send_to_stream" do
    context "in a published course" do
      it "should be true for non-assignment discussions" do
        @topic = @course.discussion_topics.create(:title => "topic")
        expect(@topic.should_send_to_stream).to be_truthy
      end

      it "should be true for non-group discussion assignments" do
        @topic = @course.discussion_topics.build(:title => "topic")
        @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @topic.title, :due_at => 1.day.from_now)
        @assignment.saved_by = :discussion_topic
        @topic.assignment = @assignment
        @topic.save
        expect(@topic.should_send_to_stream).to be_truthy
      end

      it "should be true for the parent topic only in group discussions, not the subtopics" do
        group_category = @course.group_categories.create(:name => "category")
        @parent_topic = @course.discussion_topics.create(:title => "parent topic")
        @parent_topic.group_category = group_category
        @parent_topic.save
        @subtopic = @parent_topic.child_topics.build(:title => "subtopic")
        @subtopic.group_category = group_category
        @assignment = @course.assignments.build(:submission_types => 'discussion_topic', :title => @subtopic.title, :due_at => 1.day.from_now)
        @assignment.saved_by = :discussion_topic
        @subtopic.assignment = @assignment
        @subtopic.save
        expect(@parent_topic.should_send_to_stream).to be_truthy
        expect(@subtopic.should_send_to_stream).to be_falsey
      end
    end

    it "should not send stream items to students if course isn't published'" do
      @course.update_attribute(:workflow_state, "created")
      topic = @course.discussion_topics.create!(:title => "secret topic", :user => @teacher)

      expect(@student.stream_item_instances.count).to eq 0
      expect(@teacher.stream_item_instances.count).to eq 1

      topic.discussion_entries.create!

      expect(@student.stream_item_instances.count).to eq 0
      expect(@teacher.stream_item_instances.count).to eq 1
    end

  end

  context "posting first to view" do
    before(:once) do
      @observer = user(:active_all => true)
      @context = @course
      discussion_topic_model
      @topic.require_initial_post = true
      @topic.save
    end

    it "should allow admins to see posts without posting" do
      expect(@topic.user_can_see_posts?(@teacher)).to eq true
    end

    it "should only allow active admins to see posts without posting" do
      @ta_enrollment = course_with_ta(:course => @course, :active_enrollment => true)
      # TA should be able to see
      expect(@topic.user_can_see_posts?(@ta)).to eq true
      # Remove user as TA and enroll as student, should not be able to see
      @ta_enrollment.destroy
      # enroll as a student.
      course_with_student(:course => @course, :user => @ta, :active_enrollment => true)
      @topic.reload
      @topic.clear_permissions_cache(@ta)
      expect(@topic.user_can_see_posts?(@ta)).to eq false
    end

    it "shouldn't allow student (and observer) who hasn't posted to see" do
      expect(@topic.user_can_see_posts?(@student)).to eq false
    end

    it "should allow student (and observer) who has posted to see" do
      @topic.reply_from(:user => @student, :text => 'hai')
      expect(@topic.user_can_see_posts?(@student)).to eq true
    end

    it "should work the same for group discussions" do
      group_discussion_assignment
      @topic.require_initial_post = true
      @topic.save!
      ct = @topic.child_topics.first
      ct.context.add_user(@student)
      expect(ct.user_can_see_posts?(@student)).to be_falsey
      ct.reply_from(user: @student, text: 'ohai')
      ct.user_ids_who_have_posted_and_admins
      expect(ct.user_can_see_posts?(@student)).to be_truthy
    end
  end

  context "subscribers" do
    before :once do
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    it "should automatically include the author" do
      expect(@topic.subscribers).to include(@teacher)
    end

    it "should not include the author if they unsubscribe" do
      @topic.unsubscribe(@teacher)
      expect(@topic.subscribers).not_to include(@teacher)
    end

    it "should automatically include posters" do
      @topic.reply_from(:user => @student, :text => "entry")
      expect(@topic.subscribers).to include(@student)
    end

    it "should include author when topic was created before subscriptions where added" do
      participant = @topic.update_or_create_participant(current_user: @topic.user, subscribed: nil)
      expect(participant.subscribed).to be_nil
      expect(@topic.subscribers.map(&:id)).to include(@teacher.id)
    end

    it "should include users that have posted entries before subscriptions were added" do
      @topic.reply_from(:user => @student, :text => "entry")
      participant = @topic.update_or_create_participant(current_user: @student, subscribed: nil)
      expect(participant.subscribed).to be_nil
      expect(@topic.subscribers.map(&:id)).to include(@student.id)
    end

    it "should not include posters if they unsubscribe" do
      @topic.reply_from(:user => @student, :text => "entry")
      @topic.unsubscribe(@student)
      expect(@topic.subscribers).not_to include(@student)
    end

    it "should resubscribe unsubscribed users if they post" do
      @topic.reply_from(:user => @student, :text => "entry")
      @topic.unsubscribe(@student)
      @topic.reply_from(:user => @student, :text => "another entry")
      expect(@topic.subscribers).to include(@student)
    end

    it "should include users who subscribe" do
      @topic.subscribe(@student)
      expect(@topic.subscribers).to include(@student)
    end

    it "should not include anyone no longer in the course" do
      @topic.subscribe(@student)
      @topic2 = @course.discussion_topics.create!(:title => "student topic", :message => "I'm outta here", :user => @student)
      @student.enrollments.first.destroy
      expect(@topic.subscribers).not_to include(@student)
      expect(@topic2.subscribers).not_to include(@student)
    end

    context "differentiated_assignments" do
      before do
        @assignment = @course.assignments.create!(:title => "some discussion assignment",only_visible_to_overrides: true)
        @assignment.submission_types = 'discussion_topic'
        @assignment.save!
        @topic.assignment_id = @assignment.id
        @topic.save!
        @section = @course.course_sections.create!(name: "test section")
        create_section_override_for_assignment(@topic.assignment, {course_section: @section})
      end
      context "enabled" do
        before{@course.enable_feature!(:differentiated_assignments)}
        it "should filter subscribers based on visibility" do
          @topic.subscribe(@student)
          expect(@topic.subscribers).not_to include(@student)
          student_in_section(@section, user: @student)
          expect(@topic.subscribers).to include(@student)
        end

        it "filters observers if their student cant see" do
          @observer = user(:active_all => true, :name => "Observer")
          observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section, :enrollment_state => 'active')
          observer_enrollment.update_attribute(:associated_user_id, @student.id)
          @topic.subscribe(@observer)
          expect(@topic.subscribers.include?(@observer)).to be_falsey
          student_in_section(@section, user: @student)
          expect(@topic.subscribers.include?(@observer)).to be_truthy
        end

        it "doesnt filter for observers with no student" do
          @observer = user(:active_all => true)
          observer_enrollment = @course.enroll_user(@observer, 'ObserverEnrollment', :section => @section, :enrollment_state => 'active')
          @topic.subscribe(@observer)
          expect(@topic.subscribers).to include(@observer)
        end

      end
      context "disabled" do
        before{@course.disable_feature!(:differentiated_assignments)}
        it "should not filter subscribers based on visibility" do
          @topic.subscribe(@student)
          expect(@topic.subscribers).to include(@student)
        end
      end
    end
  end

  context "visible_to_students_in_course_with_da" do
    before :once do
      @context = @course
      discussion_topic_model(:user => @teacher)
      @assignment = @course.assignments.create!(:title => "some discussion assignment",only_visible_to_overrides: true)
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!
      @topic.assignment_id = @assignment.id
      @topic.save!
      @section = @course.course_sections.create!(name: "test section")
      @student = create_users(1, return_type: :record).pop
      student_in_section(@section, user: @student)
    end
    it "returns discussions that have assignment and visibility" do
      create_section_override_for_assignment(@topic.assignment, {course_section: @section})
      expect(DiscussionTopic.visible_to_students_in_course_with_da([@student.id],[@course.id])).to include(@topic)
    end
    it "returns discussions that have no assignment" do
      @topic.assignment_id = nil
      @topic.save!
      expect(DiscussionTopic.visible_to_students_in_course_with_da([@student.id],[@course.id])).to include(@topic)
    end
    it "does not return discussions that have an assignment and no visibility" do
      expect(DiscussionTopic.visible_to_students_in_course_with_da([@student.id],[@course.id])).not_to include(@topic)
    end
  end

  context "posters" do
    before :once do
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    it "should include the topic author" do
      expect(@topic.posters).to include(@teacher)
    end

    it "should include users that have posted entries" do
      @student = student_in_course(:active_all => true).user
      @topic.reply_from(:user => @student, :text => "entry")
      expect(@topic.posters).to include(@student)
    end

    it "should include users that have replies to entries" do
      @entry = @topic.reply_from(:user => @teacher, :text => "entry")
      @student = student_in_course(:active_all => true).user
      @entry.reply_from(:user => @student, :html => "reply")

      @topic.reload
      expect(@topic.posters).to include(@student)
    end

    it "should dedupe users" do
      @entry = @topic.reply_from(:user => @teacher, :text => "entry")
      @student = student_in_course(:active_all => true).user
      @entry.reply_from(:user => @student, :html => "reply 1")
      @entry.reply_from(:user => @student, :html => "reply 2")

      @topic.reload
      expect(@topic.posters).to include(@teacher)
      expect(@topic.posters).to include(@student)
      expect(@topic.posters.size).to eq 2
    end

    it "should not include topic author if she is no longer enrolled in the course" do
      student_in_course(:active_all => true)
      @topic2 = @course.discussion_topics.create!(:title => "student topic", :message => "I'm outta here", :user => @student)
      @entry = @topic2.discussion_entries.create!(:message => "go away", :user => @teacher)
      expect(@topic2.posters.map(&:id).sort).to eql [@student.id, @teacher.id].sort
      @student.enrollments.first.destroy
      expect(@topic2.posters.map(&:id).sort).to eql [@teacher.id].sort
    end
  end

  context "submissions when graded" do
    before :once do
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    def build_submitted_assignment
      @assignment = @course.assignments.create!(:title => "some discussion assignment")
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!
      @topic.assignment_id = @assignment.id
      @topic.save!
      @entry1 = @topic.discussion_entries.create!(:message => "second message", :user => @student)
      @entry1.created_at = 1.week.ago
      @entry1.save!
      @submission = @assignment.submissions.where(:user_id => @entry1.user_id).first
    end

    it "should not re-flag graded discussion as needs grading if student make another comment" do
      assignment = @course.assignments.create(:title => "discussion assignment", :points_possible => 20)
      topic = @course.discussion_topics.create!(:title => 'discussion topic 1', :message => "this is a new discussion topic", :assignment => assignment)
      topic.discussion_entries.create!(:message => "student message for grading", :user => @student)

      submissions = Submission.where(user_id: @student, assignment_id: assignment).to_a
      expect(submissions.count).to eq 1
      student_submission = submissions.first
      assignment.grade_student(@student, {:grade => 9})
      student_submission.reload
      expect(student_submission.workflow_state).to eq 'graded'

      topic.discussion_entries.create!(:message => "student message 2 for grading", :user => @student)
      submissions = Submission.where(user_id: @student, assignment_id: assignment).to_a
      expect(submissions.count).to eq 1
      student_submission = submissions.first
      expect(student_submission.workflow_state).to eq 'graded'
    end

    it "should create submissions for existing entries when setting the assignment (even if locked)" do
      @topic.reply_from(:user => @student, :text => "entry")
      @student.reload
      expect(@student.submissions).to be_empty

      @assignment = assignment_model(:course => @course, :lock_at => 1.day.ago)
      @topic.assignment = @assignment
      @topic.save
      @student.reload
      expect(@student.submissions.size).to eq 1
      expect(@student.submissions.first.submission_type).to eq 'discussion_topic'
    end

    it "should have the correct submission date if submission has comment" do
      @assignment = @course.assignments.create!(:title => "some discussion assignment")
      @assignment.submission_types = 'discussion_topic'
      @assignment.save!
      @topic.assignment = @assignment
      @topic.save
      @submission = @assignment.find_or_create_submission(@student.id)
      @submission_comment = @submission.add_comment(:author => @teacher, :comment => "some comment")
      @submission.created_at = 1.week.ago
      @submission.save!
      expect(@submission.workflow_state).to eq 'unsubmitted'
      expect(@submission.submitted_at).to be_nil
      @entry = @topic.discussion_entries.create!(:message => "somne discussion message", :user => @student)
      @submission.reload
      expect(@submission.workflow_state).to eq 'submitted'
      expect(@submission.submitted_at.to_i).to be >= @entry.created_at.to_i #this time may not be exact because it goes off of time.now in the submission
    end

    it "should fix submission date after deleting the oldest entry" do
      build_submitted_assignment()
      @entry2 = @topic.discussion_entries.create!(:message => "some message", :user => @student)
      @entry2.created_at = 1.day.ago
      @entry2.save!
      @entry1.destroy
      @topic.reload
      expect(@topic.discussion_entries).not_to be_empty
      expect(@topic.discussion_entries.active).not_to be_empty
      @submission.reload
      expect(@submission.submitted_at.to_i).to eq @entry2.created_at.to_i
      expect(@submission.workflow_state).to eq 'submitted'
    end

    it "should mark submission as unsubmitted after deletion" do
      build_submitted_assignment()
      @entry1.destroy
      @topic.reload
      expect(@topic.discussion_entries).not_to be_empty
      expect(@topic.discussion_entries.active).to be_empty
      @submission.reload
      expect(@submission.workflow_state).to eq 'unsubmitted'
      expect(@submission.submission_type).to eq nil
      expect(@submission.submitted_at).to eq nil
    end

    it "should have new submission date after deletion and re-submission" do
      build_submitted_assignment()
      @entry1.destroy
      @topic.reload
      expect(@topic.discussion_entries).not_to be_empty
      expect(@topic.discussion_entries.active).to be_empty
      @entry2 = @topic.discussion_entries.create!(:message => "some message", :user => @student)
      @submission.reload
      expect(@submission.submitted_at.to_i).to be >= @entry2.created_at.to_i #this time may not be exact because it goes off of time.now in the submission
      expect(@submission.workflow_state).to eq 'submitted'
    end

    it "should not duplicate submissions for existing entries that already have submissions" do
      @assignment = assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save
      @topic.reload # to get the student in topic.assignment.context.students

      @topic.reply_from(:user => @student, :text => "entry")
      @student.reload
      expect(@student.submissions.size).to eq 1
      @existing_submission_id = @student.submissions.first.id

      @topic.assignment = nil
      @topic.save
      @topic.reply_from(:user => @student, :text => "another entry")
      @student.reload
      expect(@student.submissions.size).to eq 1
      expect(@student.submissions.first.id).to eq @existing_submission_id

      @topic.assignment = @assignment
      @topic.save
      @student.reload
      expect(@student.submissions.size).to eq 1
      expect(@student.submissions.first.id).to eq @existing_submission_id
    end

    it "should not resubmit graded discussion submissions" do
      @assignment = assignment_model(:course => @course)
      @topic.assignment = @assignment
      @topic.save!
      @topic.reload

      @topic.reply_from(:user => @student, :text => "entry")
      @student.reload

      @assignment.grade_student(@student, :grade => 1)
      @submission = Submission.where(:user_id => @student, :assignment_id => @assignment).first
      expect(@submission.workflow_state).to eq 'graded'

      @topic.ensure_submission(@student)
      expect(@submission.reload.workflow_state).to eq 'graded'
    end
  end

  context "read/unread state" do
    before(:once) do
      @topic = @course.discussion_topics.create!(:title => "title", :message => "message", :user => @teacher)
    end

    it "should mark a topic you created as read" do
      expect(@topic.read?(@teacher)).to be_truthy
      expect(@topic.unread_count(@teacher)).to eq 0
    end

    it "should be unread by default" do
      expect(@topic.read?(@student)).to be_falsey
      expect(@topic.unread_count(@student)).to eq 0
    end

    it "should allow being marked unread" do
      @topic.change_read_state("unread", @teacher)
      @topic.reload
      expect(@topic.read?(@teacher)).to be_falsey
      expect(@topic.unread_count(@teacher)).to eq 0
    end

    it "should allow being marked read" do
      @topic.change_read_state("read", @student)
      @topic.reload
      expect(@topic.read?(@student)).to be_truthy
      expect(@topic.unread_count(@student)).to eq 0
    end

    it "should allow mark all as unread with forced_read_state" do
      @entry = @topic.discussion_entries.create!(:message => "Hello!", :user => @teacher)
      @reply = @entry.reply_from(:user => @student, :text => "ohai!")
      @reply.change_read_state('read', @teacher, :forced => false)

      @topic.change_all_read_state("unread", @teacher, :forced => true)
      @topic.reload
      expect(@topic.read?(@teacher)).to be_falsey

      expect(@entry.read?(@teacher)).to be_falsey
      expect(@entry.find_existing_participant(@teacher)).to be_forced_read_state

      expect(@reply.read?(@teacher)).to be_falsey
      expect(@reply.find_existing_participant(@teacher)).to be_forced_read_state

      expect(@topic.unread_count(@teacher)).to eq 2
    end

    it "should allow mark all as read without forced_read_state" do
      @entry = @topic.discussion_entries.create!(:message => "Hello!", :user => @teacher)
      @reply = @entry.reply_from(:user => @student, :text => "ohai!")
      @reply.change_read_state('unread', @student, :forced => true)

      @topic.change_all_read_state("read", @student)
      @topic.reload

      expect(@topic.read?(@student)).to be_truthy

      expect(@entry.read?(@student)).to be_truthy
      expect(@entry.find_existing_participant(@student)).not_to be_forced_read_state

      expect(@reply.read?(@student)).to be_truthy
      expect(@reply.find_existing_participant(@student)).to be_forced_read_state

      expect(@topic.unread_count(@student)).to eq 0
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
      expect(@stream_item.stream_item_instances.detect{|sii| sii.user_id == @teacher.id}).to be_read
      expect(@stream_item.stream_item_instances.detect{|sii| sii.user_id == @student.id}).to be_unread

      @topic.change_all_read_state("unread", @teacher)
      @topic.change_all_read_state("read", @student)
      @topic.reload

      @stream_item = @topic.stream_item
      expect(@stream_item.stream_item_instances.detect{|sii| sii.user_id == @teacher.id}).to be_unread
      expect(@stream_item.stream_item_instances.detect{|sii| sii.user_id == @student.id}).to be_read
    end
  end

  context "subscribing" do
    before :once do
      @context = @course
      discussion_topic_model(:user => @teacher)
    end

    it "should allow subscription" do
      expect(@topic.subscribed?(@student)).to be_falsey
      @topic.subscribe(@student)
      expect(@topic.subscribed?(@student)).to be_truthy
    end

    it "should allow unsubscription" do
      expect(@topic.subscribed?(@teacher)).to be_truthy
      @topic.unsubscribe(@teacher)
      expect(@topic.subscribed?(@teacher)).to be_falsey
    end

    it "should be idempotent" do
      expect(@topic.subscribed?(@student)).to be_falsey
      @topic.unsubscribe(@student)
      expect(@topic.subscribed?(@student)).to be_falsey
    end

    it "should assume the author is subscribed" do
      expect(@topic.subscribed?(@teacher)).to be_truthy
    end

    it "should assume posters are subscribed" do
      @topic.reply_from(:user => @student, :text => 'first post!')
      expect(@topic.subscribed?(@student)).to be_truthy
    end

    context "when initial_post_required" do
      it "should unsubscribe a user when all of their posts are deleted" do
        @topic.require_initial_post = true
        @topic.save!
        @entry = @topic.reply_from(:user => @student, :text => 'first post!')
        expect(@topic.subscribed?(@student)).to be_truthy
        @entry.destroy
        expect(@topic.subscribed?(@student)).to be_falsey
      end
    end
  end

  context "subscription holds" do
    before :once do
      @context = @course
    end

    it "should hold when requiring an initial post" do
      discussion_topic_model(:user => @teacher, :require_initial_post => true)
      expect(@topic.subscription_hold(@student, nil, nil)).to eql(:initial_post_required)
    end

    it "should hold when the user is not in a group set" do
      # i.e. when you check holds on a root topic and no child topics are for groups
      # the user is in
      group_discussion_assignment
      expect(@topic.subscription_hold(@student, nil, nil)).to eql(:not_in_group_set)
    end

    it "should hold when the user is not in a group" do
      group_discussion_assignment
      expect(@topic.child_topics.first.subscription_hold(@student, nil, nil)).to eql(:not_in_group)
    end

    it "should handle nil user case" do
      group_discussion_assignment
      expect(@topic.child_topics.first.subscription_hold(nil, nil, nil)).to be_nil
    end

    it "should not subscribe the author if there is a hold" do
      group_discussion_assignment
      @topic.user = @teacher
      @topic.save!
      expect(@topic.subscription_hold(@teacher, nil, nil)).to eql(:not_in_group_set)
      expect(@topic.subscribed?(@teacher)).to be_falsey
    end

    it "should set the topic participant subscribed field to false when there is a hold" do
      teacher_in_course(:active_all => true)
      group_discussion_assignment
      group_discussion = @topic.child_topics.first
      group_discussion.user = @teacher
      group_discussion.save!
      group_discussion.change_read_state('read', @teacher) # quick way to make a participant
      expect(group_discussion.discussion_topic_participants.where(:user_id => @teacher.id).first.subscribed).to eq false
    end
  end

  context "a group topic subscription" do

    before(:once) do
      group_discussion_assignment
    end

    it "should return true if the user is subscribed to a child topic" do
      @topic.child_topics.first.subscribe(@student)
      expect(@topic.child_topics.first.subscribed?(@student)).to be_truthy
      expect(@topic.subscribed?(@student)).to be_truthy
    end

    it "should return true if the user has posted to a child topic" do
      child_topic = @topic.child_topics.first
      child_topic.context.add_user(@student)
      child_topic.reply_from(:user => @student, :text => "post")
      child_topic_participant = child_topic.update_or_create_participant(:current_user => @student, :subscribed => nil)
      expect(child_topic_participant.subscribed).to be_nil
      expect(@topic.subscribed?(@student)).to be_truthy
    end

    it "should subscribe a group user to the child topic" do
      child_one, child_two = @topic.child_topics
      child_one.context.add_user(@student)
      @topic.subscribe(@student)

      expect(child_one.subscribed?(@student)).to be_truthy
      expect(child_two.subscribed?(@student)).not_to be_truthy
      expect(@topic.subscribed?(@student)).to be_truthy
    end

    it "should unsubscribe a group user from the child topic" do
      child_one, child_two = @topic.child_topics
      child_one.context.add_user(@student)
      @topic.subscribe(@student)
      @topic.unsubscribe(@student)

      expect(child_one.subscribed?(@student)).not_to be_truthy
      expect(child_two.subscribed?(@student)).not_to be_truthy
      expect(@topic.subscribed?(@student)).not_to be_truthy
    end
  end

  context "materialized view" do
    before :once do
      topic_with_nested_replies
    end

    before :each do
      # materialized view jobs are now delayed
      Timecop.travel(Time.now + 20.seconds)
    end

    it "should return nil if the view has not been built yet, and schedule a job" do
      DiscussionTopic::MaterializedView.for(@topic).destroy
      expect(@topic.materialized_view).to be_nil
      expect(@topic.materialized_view).to be_nil
      expect(Delayed::Job.strand_size("materialized_discussion:#{@topic.id}")).to eq 1
    end

    it "should return the materialized view if it's up to date" do
      run_jobs
      view = DiscussionTopic::MaterializedView.where(discussion_topic_id: @topic).first
      expect(@topic.materialized_view).to eq [view.json_structure, view.participants_array, view.entry_ids_array, []]
    end

    it "should update the materialized view on new entry" do
      run_jobs
      expect(Delayed::Job.strand_size("materialized_discussion:#{@topic.id}")).to eq 0
      @topic.reply_from(:user => @user, :text => "ohai")
      expect(Delayed::Job.strand_size("materialized_discussion:#{@topic.id}")).to eq 1
    end

    it "should update the materialized view on edited entry" do
      reply = @topic.reply_from(:user => @user, :text => "ohai")
      run_jobs
      expect(Delayed::Job.strand_size("materialized_discussion:#{@topic.id}")).to eq 0
      reply.update_attributes(:message => "i got that wrong before")
      expect(Delayed::Job.strand_size("materialized_discussion:#{@topic.id}")).to eq 1
    end

    it "should return empty data for a materialized view on a new (unsaved) topic" do
      new_topic = DiscussionTopic.new(:context => @topic.context, :discussion_type => DiscussionTopic::DiscussionTypes::SIDE_COMMENT)
      expect(new_topic).to be_new_record
      expect(new_topic.materialized_view).to eq [ "[]", [], [], [] ]
      expect(Delayed::Job.strand_size("materialized_discussion:#{new_topic.id}")).to eq 0
    end
  end

  context "destroy" do
    before(:once) { group_discussion_assignment }

    it "should destroy the assignment and associated child topics" do
      @topic.destroy
      expect(@topic.reload).to be_deleted
      @topic.child_topics.each{ |ct| expect(ct.reload).to be_deleted }
      expect(@assignment.reload).to be_deleted
    end

    it "should not revive the assignment if updated when deleted" do
      @topic.destroy
      expect(@assignment.reload).to be_deleted
      @topic.touch
      expect(@assignment.reload).to be_deleted
    end
  end

  context "restore" do
    before(:once) { group_discussion_assignment }

    it "should restore the assignment and associated child topics" do
      @topic.destroy

      @topic.reload.assignment.expects(:restore).with(:discussion_topic).once
      @topic.restore
      expect(@topic.reload).to be_active
      @topic.child_topics.each { |ct| expect(ct.reload).to be_active }
    end

    it "should restore to unpublished state if draft mode is enabled" do
      @course.root_account.enable_feature!(:draft_state)
      @topic.destroy

      @topic.reload.assignment.expects(:restore).with(:discussion_topic).once
      @topic.restore
      expect(@topic.reload).to be_post_delayed
      @topic.child_topics.each { |ct| expect(ct.reload).to be_post_delayed }
    end
  end

  describe "reply_from" do
    it "should ignore responses in deleted account" do
      account = Account.create!
      @teacher = course_with_teacher(:active_all => true, :account => account).user
      @context = @course
      discussion_topic_model(:user => @teacher)
      account.destroy
      expect { @topic.reply_from(:user => @teacher, :text => "entry") }.to raise_error(IncomingMail::Errors::UnknownAddress)
    end

    it "should prefer html to text" do
      discussion_topic_model
      msg = @topic.reply_from(:user => @teacher, :text => "text body", :html => "<p>html body</p>")
      expect(msg).not_to be_nil
      expect(msg.message).to eq "<p>html body</p>"
    end

    it "should not allow replies from students to locked topics" do
      discussion_topic_model
      @topic.lock!
      @topic.reply_from(:user => @teacher, :text => "reply") # should not raise error
      student_in_course(:course => @course)
      expect { @topic.reply_from(:user => @student, :text => "reply") }.to raise_error(IncomingMail::Errors::ReplyToLockedTopic)
    end

  end

  describe "locked flag" do
    before :once do
      discussion_topic_model
    end

    it "should ignore workflow_state if the flag is set" do
      @topic.locked = true
      @topic.workflow_state = 'active'
      expect(@topic.locked?).to be_truthy
      @topic.locked = false
      @topic.workflow_state = 'locked'
      expect(@topic.locked?).to be_falsey
    end

    it "should fall back to the workflow_state if the flag is nil" do
      @topic.locked = nil
      @topic.workflow_state = 'active'
      expect(@topic.locked?).to be_falsey
      @topic.workflow_state = 'locked'
      expect(@topic.locked?).to be_truthy
    end

    it "should fix up a 'locked' workflow_state" do
      @topic.workflow_state = 'locked'
      @topic.locked = nil
      @topic.save!
      @topic.unlock!
      expect(@topic.workflow_state).to eql 'active'
      expect(@topic.locked?).to be_falsey
    end
  end

  describe "update_order" do
    it "should handle existing null positions" do
      topics = (1..4).map{discussion_topic_model(pinned: true)}
      topics.each {|x| x.position = nil; x.save}

      new_order = [2, 3, 4, 1]
      ids = new_order.map {|x| topics[x-1].id}
      topics[0].update_order(ids)
      expect(topics.first.list_scope.map(&:id)).to eq ids
    end
  end
end
