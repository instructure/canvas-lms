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

require_relative '../spec_helper'

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

  def enroll_observer(course, observer, linked_student)
    course.enroll_user(observer, "ObserverEnrollment", {associated_user_id: linked_student.id})
  end

  it "returns empty list if user has no self or observer enrollments" do
    expect(observed_users(@observer, nil)).to eq []
  end

  it "returns just self user if user has no observer enrollments" do
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

  it "does not include self user if no own enrollments" do
    enroll_observer(@course1, @observer, @student1)
    enroll_observer(@course1, @observer, @student2)

    users = observed_users(@observer, nil)
    expect(users.length).to be(2)
    expect(users[0][:name]).to eq("Student 1")
    expect(users[1][:name]).to eq("Student 2")
    expect(@selected_observed_user.id).to be(@student1.id)
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

  context "SELECTED_OBSERVED_USER_COOKIE cookie" do
    before :once do
      @course1.enroll_teacher(@observer)
      enroll_observer(@course1, @observer, @student1)
      enroll_observer(@course1, @observer, @student2)
    end

    it "sets @selected_observed_user to user passed in cookie, if valid" do
      cookies["k5_observed_user_id"] = @student2.id.to_s

      observed_users(@observer, nil)
      expect(@selected_observed_user.id).to be(@student2.id)
    end

    it "does not set @selected_observed_user to an invalid user" do
      cookies["k5_observed_user_id"] = "53276893"

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
end
