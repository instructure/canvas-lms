# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

require_relative "../../spec_helper"

RSpec.describe Loaders::ObservedStudentsLoader do
  before :once do
    @observer = User.create!
    @student1 = User.create!
    @student2 = User.create!
    @student3 = User.create!

    @course1 = course_factory(active_all: true)
    @course2 = course_factory(active_all: true)

    @course1.enroll_student(@student1, enrollment_state: "active")
    @course1.enroll_student(@student2, enrollment_state: "active")
    @course2.enroll_student(@student3, enrollment_state: "active")

    @course1.observer_enrollments.create!(
      user: @observer,
      associated_user: @student1,
      workflow_state: "active"
    )
    @course1.observer_enrollments.create!(
      user: @observer,
      associated_user: @student2,
      workflow_state: "active"
    )
    @course2.observer_enrollments.create!(
      user: @observer,
      associated_user: @student3,
      workflow_state: "active"
    )
  end

  def with_batch_loader(user, include_restricted_access: false)
    GraphQL::Batch.batch do
      yield Loaders::ObservedStudentsLoader.for(current_user: user, include_restricted_access:)
    end
  end

  it "loads observed students for a single course" do
    observed_students_hash = with_batch_loader(@observer) { |loader| loader.load(@course1) }

    expect(observed_students_hash.keys).to contain_exactly(@student1, @student2)
    expect(observed_students_hash[@student1]).to be_an(Array)
    expect(observed_students_hash[@student2]).to be_an(Array)
  end

  it "batches queries for multiple courses" do
    course1_students, course2_students = with_batch_loader(@observer) do |loader|
      Promise.all([loader.load(@course1), loader.load(@course2)])
    end

    expect(course1_students.keys).to contain_exactly(@student1, @student2)
    expect(course2_students.keys).to contain_exactly(@student3)
  end

  it "returns empty hash when current_user is nil" do
    observed_students_hash = with_batch_loader(nil) { |loader| loader.load(@course1) }

    expect(observed_students_hash).to eq({})
  end

  it "returns empty hash when user is not an observer" do
    regular_user = User.create!
    observed_students_hash = with_batch_loader(regular_user) { |loader| loader.load(@course1) }

    expect(observed_students_hash).to eq({})
  end

  it "returns empty hash when observer has no associated students" do
    observer_without_students = User.create!
    @course1.enroll_user(observer_without_students, "ObserverEnrollment", enrollment_state: "active")

    observed_students_hash = with_batch_loader(observer_without_students) { |loader| loader.load(@course1) }

    expect(observed_students_hash).to eq({})
  end

  it "excludes students with restricted access by default" do
    enrollment = @course1.student_enrollments.find_by(user: @student1)
    enrollment.enrollment_state.update!(restricted_access: true)

    observed_students_hash = with_batch_loader(@observer) { |loader| loader.load(@course1) }

    expect(observed_students_hash.keys).to contain_exactly(@student2)
    expect(observed_students_hash.keys).not_to include(@student1)
  end

  it "includes students with restricted access when requested" do
    enrollment = @course1.student_enrollments.find_by(user: @student1)
    enrollment.enrollment_state.update!(restricted_access: true)

    observed_students_hash = with_batch_loader(@observer, include_restricted_access: true) { |loader| loader.load(@course1) }

    expect(observed_students_hash.keys).to contain_exactly(@student1, @student2)
  end

  it "excludes inactive student enrollments" do
    enrollment = @course1.student_enrollments.find_by(user: @student1)
    enrollment.update!(workflow_state: "inactive")

    observed_students_hash = with_batch_loader(@observer) { |loader| loader.load(@course1) }

    expect(observed_students_hash.keys).to contain_exactly(@student2)
  end

  it "excludes deleted student enrollments" do
    enrollment = @course1.student_enrollments.find_by(user: @student1)
    enrollment.update!(workflow_state: "deleted")

    observed_students_hash = with_batch_loader(@observer) { |loader| loader.load(@course1) }

    expect(observed_students_hash.keys).to contain_exactly(@student2)
  end
end
