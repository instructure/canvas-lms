# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

describe Loaders::ActivityStreamSummaryLoader do
  around do |example|
    @query_count = 0
    subscription = ActiveSupport::Notifications.subscribe("sql.active_record") do
      @query_count += 1
    end

    example.run

    ActiveSupport::Notifications.unsubscribe(subscription)
  end

  it "batch loads activity stream summaries" do
    cur_user = user_factory(active_all: true)
    courses = []
    4.times do |i|
      course = course_with_student(user: cur_user, active_all: true).course
      course.update!(name: "Course #{i}")
      courses << course
    end

    courses[0].announcements.create!(title: "Announcement 1", message: "Hello!")
    courses[1].discussion_topics.create!(title: "Discussion 1", message: "Let's talk!")

    courses[3].announcements.create!(title: "Announcement 2", message: "Important!")
    courses[3].discussion_topics.create!(title: "Discussion 2", message: "More talk!")

    expect do
      GraphQL::Batch.batch do
        Loaders::ActivityStreamSummaryLoader.for(current_user: cur_user).load(courses[0]).then do |items|
          expect(items).to eq [
            { type: "Announcement", count: 1, unread_count: 1, notification_category: nil },
            { type: "DiscussionTopic", count: 0, unread_count: 0, notification_category: nil }
          ]
        end
        Loaders::ActivityStreamSummaryLoader.for(current_user: cur_user).load(courses[1]).then do |items|
          expect(items).to eq [
            { type: "DiscussionTopic", count: 1, unread_count: 1, notification_category: nil }
          ]
        end
        Loaders::ActivityStreamSummaryLoader.for(current_user: cur_user).load(courses[2]).then do |items|
          expect(items).to eq []
        end
        Loaders::ActivityStreamSummaryLoader.for(current_user: cur_user).load(courses[3]).then do |items|
          expect(items).to eq [
            { type: "Announcement", count: 1, unread_count: 1, notification_category: nil },
            { type: "DiscussionTopic", count: 1, unread_count: 1, notification_category: nil }
          ]
        end
      end
    end.to change { @query_count }.by(5)
  end

  context "multiple shards" do
    specs_require_sharding

    it "batch loads cross-shard activity stream summaries" do
      @student = user_factory(active_all: true)
      @shard1.activate do
        @account = Account.create!
        @course1 = course_factory(active_all: true, account: @account)
        @course1.enroll_student(@student).accept!
        @context = @course1
        discussion_topic_model(context: @course1)
        announcement_model(context: @course1)
      end
      @shard2.activate do
        @course2 = course_factory(active_all: true, account: @account)
        @course2.enroll_student(@student).accept!
        @context = @course2
        discussion_topic_model(context: @course2)
        conversation(User.create, @student)
        Notification.create(name: "Assignment Due Date Changed", category: "TestImmediately")
        allow_any_instance_of(Assignment).to receive(:created_at).and_return(4.hours.ago)
        assignment_model(course: @course2)
        @assignment.update_attribute(:due_at, 1.week.from_now)
      end

      expect do
        GraphQL::Batch.batch do
          Loaders::ActivityStreamSummaryLoader.for(current_user: @student).load(@course1).then do |items|
            expect(items).to eq [
              { type: "Announcement", count: 1, unread_count: 1, notification_category: nil },
              { type: "DiscussionTopic", count: 1, unread_count: 1, notification_category: nil }
            ]
          end
          Loaders::ActivityStreamSummaryLoader.for(current_user: @student).load(@course2).then do |items|
            expect(items).to eq [
              { type: "DiscussionTopic", count: 1, unread_count: 1, notification_category: nil },
              { type: "Message", count: 1, unread_count: 0, notification_category: "TestImmediately" }
            ]
          end
        end
      end.to change { @query_count }.by(12)
    end
  end

  it "handles courses with no activity streams" do
    cur_user = user_factory(active_all: true)
    course1 = course_with_student(user: cur_user, active_all: true).course
    course2 = course_with_student(user: cur_user, active_all: true).course

    GraphQL::Batch.batch do
      Loaders::ActivityStreamSummaryLoader.for(current_user: cur_user).load(course1).then do |items|
        expect(items).to eq []
      end
      Loaders::ActivityStreamSummaryLoader.for(current_user: cur_user).load(course2).then do |items|
        expect(items).to eq []
      end
    end
  end

  it "handles nil course" do
    cur_user = user_factory(active_all: true)
    GraphQL::Batch.batch do
      Loaders::ActivityStreamSummaryLoader.for(current_user: cur_user).load(nil).then do |items|
        expect(items).to be_nil
      end
    end
  end
end
