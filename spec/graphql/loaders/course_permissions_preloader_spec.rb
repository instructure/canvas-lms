# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

describe Loaders::CoursePermissionsPreloader do
  def count_enrollment_selects(&)
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      sql = payload[:sql].to_s
      count += 1 if sql.match?(/FROM (?:"\w+"\.)?"enrollments"/) && sql.include?("enrollment_states")
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &)
    count
  end

  it "batches permission checks for multiple courses into a single enrollments query" do
    user = user_factory(active_all: true)
    courses = Array.new(3) do
      c = course_factory(active_all: true)
      c.enroll_teacher(user, enrollment_state: "active")
      c
    end
    Rails.cache.clear

    count = RequestCache.enable do
      count_enrollment_selects do
        GraphQL::Batch.batch do
          Promise.all(courses.map { |course| described_class.for(current_user: user).load(course) }).sync
        end
      end
    end

    expect(count).to eq(1)
  end

  it "leaves subsequent active_enrollment_allows calls free of SQL within the same request" do
    user = user_factory(active_all: true)
    courses = Array.new(3) do
      c = course_factory(active_all: true)
      c.enroll_teacher(user, enrollment_state: "active")
      c
    end
    Rails.cache.clear

    RequestCache.enable do
      GraphQL::Batch.batch do
        Promise.all(courses.map { |course| described_class.for(current_user: user).load(course) }).sync
      end

      followup = count_enrollment_selects do
        courses.each { |c| c.active_enrollment_allows(user, :manage_course_content_edit) }
      end
      expect(followup).to eq(0)
    end
  end

  it "issues zero enrollments queries when Rails.cache is already warm" do
    user = user_factory(active_all: true)
    courses = Array.new(2) do
      c = course_factory(active_all: true)
      c.enroll_teacher(user, enrollment_state: "active")
      c
    end

    enable_cache do
      # Warm Rails.cache via a direct (un-preloaded) call path.
      courses.each { |c| c.active_enrollment_allows(user, :manage_course_content_edit) }

      count = RequestCache.enable do
        count_enrollment_selects do
          GraphQL::Batch.batch do
            Promise.all(courses.map { |course| described_class.for(current_user: user).load(course) }).sync
          end
        end
      end

      expect(count).to eq(0)
    end
  end

  it "fulfills with the course itself so resolvers can chain off the promise" do
    user = user_factory(active_all: true)
    course = course_factory(active_all: true)
    course.enroll_teacher(user, enrollment_state: "active")

    GraphQL::Batch.batch do
      described_class.for(current_user: user).load(course).then do |loaded|
        expect(loaded).to eq(course)
      end
    end
  end

  it "no-ops with a nil current_user" do
    course = course_factory(active_all: true)
    expect do
      GraphQL::Batch.batch do
        described_class.for(current_user: nil).load(course)
      end
    end.not_to raise_error
  end

  context "across multiple shards" do
    specs_require_sharding

    it "fires one enrollments query per shard, not one per course" do
      user = user_factory(active_all: true)
      shard1_courses = @shard1.activate do
        Array.new(2) do
          c = course_factory(active_all: true, account: Account.create!)
          c.enroll_teacher(user, enrollment_state: "active")
          c
        end
      end
      shard2_courses = @shard2.activate do
        Array.new(2) do
          c = course_factory(active_all: true, account: Account.create!)
          c.enroll_teacher(user, enrollment_state: "active")
          c
        end
      end
      Rails.cache.clear

      all_courses = shard1_courses + shard2_courses
      count = RequestCache.enable do
        count_enrollment_selects do
          GraphQL::Batch.batch do
            Promise.all(all_courses.map { |course| described_class.for(current_user: user).load(course) }).sync
          end
        end
      end

      expect(count).to eq(2)
    end
  end
end
