# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe StreamItem do
  it "does not infer a user_id for DiscussionTopic" do
    user_factory
    context = Course.create!
    dt = DiscussionTopic.create!(context:)
    dt.generate_stream_items([@user])
    si = @user.stream_item_instances.first.stream_item
    data = si.data(@user.id)
    expect(data).to be_a DiscussionTopic
    expect(data.user_id).to be_nil
  end

  it "prefers a Context for Message stream item context" do
    notification_model(name: "Assignment Created")
    course_with_student(active_all: true)
    assignment_model(course: @course)
    item = @user.stream_item_instances.first.stream_item
    expect(item.data.notification_name).to eq "Assignment Created"
    expect(item.context).to eq @course

    course_items = @user.recent_stream_items(contexts: [@course])
    expect(course_items).to eq [item]
  end

  it "doesn't unlink discussion entries from their topics" do
    user_factory
    context = Course.create!
    dt = DiscussionTopic.create!(context:, require_initial_post: true)
    de = dt.root_discussion_entries.create!
    dt.generate_stream_items([@user])
    si = @user.stream_item_instances.first.stream_item
    si.data(@user.id)
    expect(de.reload.discussion_topic_id).not_to be_nil
  end

  it "uses new context short name" do
    user_factory
    context = Course.create!(course_code: "some name")
    enable_cache do
      dt1 = DiscussionTopic.create!(context:)
      dt1.generate_stream_items([@user])
      si1 = StreamItem.where(asset_id: dt1.id).first
      expect(si1.data.context_short_name).to eq "some name"

      context.update_attribute(:course_code, "some other name")
      dt2 = DiscussionTopic.create!(context:)
      dt2.generate_stream_items([@user])
      si2 = StreamItem.where(asset_id: dt2.id).first
      expect(si2.data.context_short_name).to eq "some other name"
    end
  end

  describe "destroy_stream_items_using_setting" do
    it "has a default ttl" do
      StreamItem.create!(asset_type: "Message", data: { notification_id: nil })
      si2 = StreamItem.create! do |si|
        si.asset_type = "Message"
        si.data = { notification_id: nil }
      end
      StreamItem.where(id: si2).update_all(updated_at: 1.year.ago)
      expect do
        StreamItem.destroy_stream_items_using_setting
      end.to change(StreamItem, :count).by(-1)
    end
  end

  context "across shards" do
    specs_require_sharding

    it "deletes instances on all associated shards" do
      course_with_teacher(active_all: 1)
      @user2 = @shard1.activate { user_model }
      @course.enroll_student(@user2).accept!

      dt = @course.discussion_topics.create!(title: "title")
      expect(@user2.reload.recent_stream_items).to eq [dt.stream_item]
      expect(dt.stream_item.associated_shards).to eq [Shard.current, @shard1]
      dt.stream_item.destroy
      expect(@user2.recent_stream_items).to eq []
    end

    it "does not find stream items for courses from the wrong shard" do
      course_with_teacher(active_all: 1)
      @shard1.activate do
        @user2 = user_model
        @course.enroll_student(@user2).accept!
        account = Account.create!
        @course2 = account.courses.create! { |c| c.id = @course.local_id }
        @course2.offer!
        @course2.enroll_student(@user2).accept!
        @dt2 = @course2.discussion_topics.create!
      end
      @dt = @course.discussion_topics.create!

      expect(@user2.recent_stream_items.map(&:data).sort_by(&:id)).to eq [@dt, @dt2].sort_by(&:id)
      expect(@user2.recent_stream_items(context: @course).map(&:data)).to eq [@dt]
      @shard1.activate do
        expect(@user2.recent_stream_items(context: @course2).map(&:data)).to eq [@dt2]
      end
    end

    it "always caches stream items on the user's shard" do
      course_with_teacher(active_all: 1)
      @user2 = @shard1.activate { user_model }
      @course.enroll_student(@user2).accept!

      dt = @course.discussion_topics.create!(title: "title")
      enable_cache do
        expect(@user2).to receive(:recent_stream_items).once.and_call_original
        items = @user2.cached_recent_stream_items
        items2 = @shard1.activate { @user2.cached_recent_stream_items }
        expect(items).to eq [dt.stream_item]
        expect(items).to eq items2

        item = @user2.visible_stream_item_instances.last
        item.update_attribute(:hidden, true)

        expect(@user2).to receive(:recent_stream_items).once.and_call_original
        # after dismissing an item, the old items should no longer be cached
        items = @user2.cached_recent_stream_items
        items2 = @shard1.activate { @user2.cached_recent_stream_items }
        expect(items).to be_empty
        expect(items2).to be_empty
      end
    end
  end

  it "returns a title for a Conversation" do
    user_factory
    convo = Conversation.create!(subject: "meow")
    convo.generate_stream_items([@user])
    si = @user.stream_item_instances.first.stream_item
    data = si.data(@user.id)
    expect(data).to be_a Conversation
    expect(data.title).to eql("meow")
  end

  it "does not unhide stream item instances when someone 'deletes' a message" do
    users = Array.new(3) { user_factory }
    user1, user2, user3 = users
    convo = Conversation.initiate(users, false)
    convo.add_message(user3, "hello")
    si = StreamItem.where(asset_type: "Conversation", asset_id: convo).first
    instance1, _instance2 = [user1, user2].map { |u| si.stream_item_instances.where(user_id: u).first }
    instance1.update_attribute(:hidden, true) # hide on user1's instance
    convo.conversation_participants.where(user_id: user2).first.remove_messages(:all) # remove on user2's side
    expect(instance1.reload).to be_hidden # should leave user1's instance alone

    # should remove the messages from user2's view after post_process
    expect(StreamItem.find(si.id).data(user2.id).latest_messages_from_stream_item).to be_empty
  end

  it "returns a description for a Collaboration" do
    user_factory
    context = Course.create!
    collab = Collaboration.create!(context:, description: "meow", title: "kitty")
    collab.generate_stream_items([@user])
    si = @user.stream_item_instances.first.stream_item
    data = si.data(@user.id)
    expect(data).to be_a Collaboration
    expect(data.description).to eql("meow")
  end

  describe ".generate_all" do
    context "when there is no item generated" do
      it "does not cause error when item is not generated" do
        allow(StreamItem).to receive(:generate_or_update).and_return(nil)
        expect(StreamItem.generate_all(double, [1])).to eq []
      end
    end

    context "when the caller is a submission" do
      let(:student) { User.create! }
      let(:teacher) { User.create! }
      let(:course) do
        course = Course.create!
        course.enroll_student(student, enrollment_state: "active")
        course.enroll_teacher(teacher, enrollment_state: "active")

        course
      end

      let(:assignment) { course.assignments.create! }
      let(:submission) { assignment.submission_for_student(student) }

      context "when the submission is not posted" do
        before do
          assignment.post_policy.update!(post_manually: true)
        end

        let(:generated_instances) do
          stream_items = StreamItem.generate_all(submission, [student.id, teacher.id])
          stream_items.first.stream_item_instances
        end

        it "hides the item instance associated with the student" do
          student_instance = generated_instances.detect { |instance| instance.user_id == student.id }
          expect(student_instance[:hidden]).to be true
        end

        it "does not hide the item instance associated with the teacher" do
          teacher_instance = generated_instances.detect { |instance| instance.user_id == teacher.id }
          expect(teacher_instance[:hidden]).to be false
        end
      end

      context "when the submission is posted" do
        let(:generated_instances) { StreamItem.generate_all(submission, [student.id, teacher.id]) }

        it "does not hide any of the generated instances" do
          expect(generated_instances.none? { |instance| instance[:hidden] }).to be true
        end
      end
    end
  end
end
