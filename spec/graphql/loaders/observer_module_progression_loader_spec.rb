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

RSpec.describe Loaders::ObserverModuleProgressionLoader do
  before :once do
    course_with_teacher(active_all: true)
    @observer = User.create!
    @student1 = User.create!
    @student2 = User.create!

    @course.enroll_student(@student1, enrollment_state: "active")
    @course.enroll_student(@student2, enrollment_state: "active")

    # Observer enrolls to observe both students
    @observer_enrollment1 = @course.observer_enrollments.create!(
      user: @observer,
      associated_user: @student1,
      workflow_state: "active"
    )
    @observer_enrollment2 = @course.observer_enrollments.create!(
      user: @observer,
      associated_user: @student2,
      workflow_state: "active"
    )

    # Create a context module
    @context_module = @course.context_modules.create!(name: "Test Module")

    # Create progression for student1 (this is what observer should see)
    @progression_student1 = @context_module.context_module_progressions.create!(
      user: @student1,
      workflow_state: "completed",
      completed_at: 1.day.ago
    )

    # Create progression for student2 as well
    @progression_student2 = @context_module.context_module_progressions.create!(
      user: @student2,
      workflow_state: "started"
    )
  end

  def with_batch_loader(user, session = nil)
    GraphQL::Batch.batch do
      yield Loaders::ObserverModuleProgressionLoader.for(current_user: user, session:)
    end
  end

  it "loads progression for observed students" do
    progression = with_batch_loader(@observer) { |loader| loader.load(@context_module) }

    expect(progression).not_to be_nil
    expect(progression.user_id).to eq(@student1.id) # Should be first observed student
    expect(progression.workflow_state).to eq("completed")
  end

  it "returns nil when current_user is not an observer" do
    progression = with_batch_loader(@teacher) { |loader| loader.load(@context_module) }

    expect(progression).to be_nil
  end

  it "returns nil when current_user is nil" do
    progression = with_batch_loader(nil) { |loader| loader.load(@context_module) }

    expect(progression).to be_nil
  end

  it "returns nil when observer has no observed students" do
    # Create an observer without observed students
    lone_observer = User.create!
    @course.observer_enrollments.create!(
      user: lone_observer,
      workflow_state: "active"
    )

    progression = with_batch_loader(lone_observer) { |loader| loader.load(@context_module) }

    expect(progression).to be_nil
  end

  it "handles modules without progression records gracefully" do
    # Create another module without any progressions
    module_without_progression = @course.context_modules.create!(name: "No Progression Module")

    progression = with_batch_loader(@observer) { |loader| loader.load(module_without_progression) }

    expect(progression).to be_nil
  end

  it "loads multiple modules efficiently" do
    module2 = @course.context_modules.create!(name: "Second Module")

    # Create progression for second module
    module2.context_module_progressions.create!(
      user: @student1,
      workflow_state: "started"
    )

    # Load each module separately to avoid Promise array issues
    progression1 = with_batch_loader(@observer) { |loader| loader.load(@context_module) }
    progression2 = with_batch_loader(@observer) { |loader| loader.load(module2) }

    expect(progression1&.workflow_state).to eq("completed")
    expect(progression2&.workflow_state).to eq("started")
    expect(progression1.user_id).to eq(@student1.id)
    expect(progression2.user_id).to eq(@student1.id)
  end
end
