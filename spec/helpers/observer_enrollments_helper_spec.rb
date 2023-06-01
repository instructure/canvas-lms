# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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
#

require_relative "../spec_helper"

describe ObserverEnrollmentsHelper do
  include ObserverEnrollmentsHelper

  before :once do
    @course1 = course_factory(active_all: true)
    @course2 = course_factory(active_all: true)
    @student1 = user_factory(active_all: true, name: "Student 1")
    @student2 = user_factory(active_all: true, name: "Student 2")
    @observer = user_factory(active_all: true, name: "Observer")
    @course1.enroll_student(@student1)
    @course1.enroll_student(@student2)
    @course2.enroll_student(@student1)
  end

  before do
    instance_variable_set(:@current_user, @observer)
  end

  def enroll_observer(course, observer, linked_student)
    course.enroll_user(observer, "ObserverEnrollment", { associated_user_id: linked_student.id })
  end

  it "returns empty list if user has no self or unlinked observer enrollments" do
    expect(observed_users(@observer, nil)).to eq []
  end

  it "returns self user if user has only self enrollments" do
    @course1.enroll_teacher(@observer)

    users = observed_users(@observer, nil)
    expect(users.length).to be(1)
    expect(users[0][:name]).to eq("Observer")
    expect(@selected_observed_user.id).to be(@observer.id)
  end

  it "returns self and observers if both enrollment types exist" do
    @course1.enroll_student(@observer)
    enroll_observer(@course1, @observer, @student1)
    enroll_observer(@course1, @observer, @student2)

    users = observed_users(@observer, nil)
    expect(users.length).to be(3)
    expect(users[0][:name]).to eq("Observer")
    expect(users[1][:name]).to eq("Student 1")
    expect(users[2][:name]).to eq("Student 2")
    expect(@selected_observed_user.id).to be(@observer.id)
  end

  it "does not include self user if no self of unlinked observer enrollments" do
    enroll_observer(@course1, @observer, @student1)
    enroll_observer(@course1, @observer, @student2)

    users = observed_users(@observer, nil)
    expect(users.length).to be(2)
    expect(users[0][:name]).to eq("Student 1")
    expect(users[1][:name]).to eq("Student 2")
    expect(@selected_observed_user.id).to be(@student1.id)
  end

  it "includes self user if the user has unlinked observer enrollments" do
    @course1.enroll_user(@observer, "ObserverEnrollment")

    users = observed_users(@observer, nil)
    expect(users.length).to be(1)
    expect(users[0][:name]).to eq("Observer")
    expect(@selected_observed_user.id).to be(@observer.id)
  end

  it "sorts by sortable name except self enrollment" do
    @course1.enroll_student(@observer)
    enroll_observer(@course1, @observer, @student1)
    enroll_observer(@course1, @observer, @student2)
    @student1.sortable_name = "Z"
    @student1.save!
    @student2.sortable_name = "A"
    @student2.save!

    users = observed_users(@observer, nil)
    expect(users.length).to be(3)
    expect(users[0][:name]).to eq("Observer")
    expect(users[1][:name]).to eq("Student 2")
    expect(users[2][:name]).to eq("Student 1")
  end

  it "does not return duplicates of the requesting user" do
    @course1.enroll_student(@observer)
    @course1.enroll_teacher(@observer)

    users = observed_users(@observer, nil)
    expect(users.length).to be(1)
    expect(users[0][:name]).to eq("Observer")
  end

  it "does not return duplicate observed users" do
    enroll_observer(@course1, @observer, @student1)
    enroll_observer(@course2, @observer, @student1)

    users = observed_users(@observer, nil)
    expect(users.length).to be(1)
    expect(users[0][:name]).to eq("Student 1")
  end

  it "includes id, name, and sortable_name fields" do
    @course1.enroll_teacher(@observer)

    users = observed_users(@observer, nil)
    expect(users[0][:id]).to be(@observer.id)
    expect(users[0][:name]).to eq("Observer")
    expect(users[0][:sortable_name]).to eq("Observer")
  end

  context "with the observed user cookie" do
    before :once do
      @course1.enroll_teacher(@observer)
      enroll_observer(@course1, @observer, @student1)
      enroll_observer(@course1, @observer, @student2)
      @observed_user_cookie_name = "#{ObserverEnrollmentsHelper::OBSERVER_COOKIE_PREFIX}#{@observer.id}"
    end

    it "sets @selected_observed_user to user passed in cookie, if valid" do
      cookies[@observed_user_cookie_name] = @student2.id.to_s

      observed_users(@observer, nil)
      expect(@selected_observed_user.id).to be(@student2.id)
    end

    it "does not set @selected_observed_user to an invalid user" do
      cookies[@observed_user_cookie_name] = "53276893"

      observed_users(@observer, nil)
      expect(@selected_observed_user.id).to be(@observer.id)
    end

    it "sets @selected_observed_user to first user in list if cookie is not present" do
      observed_users(@observer, nil)
      expect(@selected_observed_user.id).to be(@observer.id)
    end
  end

  it "only shows observed users from provided course" do
    enroll_observer(@course1, @observer, @student1)
    enroll_observer(@course1, @observer, @student2)
    enroll_observer(@course2, @observer, @student1)

    users = observed_users(@observer, nil, @course2.id)
    expect(users.length).to be(1)
    expect(users[0][:name]).to eq("Student 1")
  end

  it "returns [] if user not provided" do
    enroll_observer(@course1, @observer, @student1)

    expect(observed_users(nil, nil)).to eq []
  end

  it "returns up to MAX_OBSERVED_USERS users" do
    stub_const("ObserverEnrollmentsHelper::MAX_OBSERVED_USERS", 2)
    @course1.enroll_teacher(@observer) # non-observer enrollment not counted toward limit of 2
    enroll_observer(@course1, @observer, @student1)
    enroll_observer(@course1, @observer, @student2)
    enroll_observer(@course2, @observer, @student1)

    users = observed_users(@observer, nil)
    expect(users.length).to be(3)
  end

  it "does not consider concluded enrollments" do
    enroll_observer(@course1, @observer, @student1)
    @course1.conclude_at = 1.week.ago
    @course1.restrict_enrollments_to_course_dates = true
    @course1.save!

    users = observed_users(@observer, nil)
    expect(users.length).to be(0)
  end

  context "sharding" do
    specs_require_sharding

    before :once do
      @shard2.activate do
        @student3 = user_factory(active_all: true, name: "Student 3")
      end
    end

    it "includes and sorts observed users from multiple shards" do
      @student3.sortable_name = "0" # before student 1
      @student3.save!
      @course1.enroll_student(@student3)
      enroll_observer(@course1, @observer, @student3)
      enroll_observer(@course1, @observer, @student1)

      users = observed_users(@observer, nil)
      expect(users.length).to be(2)
      expect(users[0][:name]).to eq("Student 3")
      expect(users[1][:name]).to eq("Student 1")
    end

    it "includes observers with observer enrollments in courses on another shard" do
      enroll_observer(@course1, @observer, @student1)
      @shard2.activate do
        account = Account.create!
        @course3 = course_factory(active_all: true, account:)
        @course3.enroll_student(@student3)
        enroll_observer(@course3, @observer, @student3)

        users = observed_users(@observer, nil)
        expect(users.length).to be(2)
        expect(users[0][:name]).to eq("Student 1")
        expect(users[1][:name]).to eq("Student 3")
      end
    end
  end
end
