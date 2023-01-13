# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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
require_relative "../../spec_helper"

module Assignments
  describe ScopedToUser do
    before(:once) do
      course_with_teacher(active_all: true)
      student_in_course(active_all: true, user_name: "some user")
    end

    let_once(:published) do
      @course.assignments.create({
                                   title: "published assignment"
                                 })
    end
    let_once(:unpublished) do
      @course.assignments.create({
                                   title: "unpublished assignment"
                                 }).tap(&:unpublish)
    end
    let_once(:inactive) do
      @course.assignments.create({
                                   title: "unpublished assignment"
                                 }).tap do |assignment|
        assignment.update_attribute(:workflow_state, "deleted")
      end
    end

    describe "#scope" do
      it "does not include inactive assignments" do
        expect(inactive.workflow_state).to eq("deleted"), "precondition"
        scope_filter = Assignments::ScopedToUser.new(@course, @student)
        expect(scope_filter.scope).not_to include(inactive)
      end

      it "returns unpublished assignments if user can :manage_assignments" do
        expect(@course.grants_right?(@teacher, :manage_assignments_add)).to be_truthy,
                                                                            "precondition"
        expect(unpublished.workflow_state).to eq("unpublished"), "precondition"
        scope_filter = Assignments::ScopedToUser.new(@course, @teacher)
        expect(scope_filter.scope).to include(unpublished)
      end

      it "does not return unpublished assignments if user cannot :manage_assignments" do
        expect(@course.grants_right?(@student, :manage_assignments_add)).to be_falsey,
                                                                            "precondition"
        expect(unpublished.workflow_state).to eq("unpublished"), "precondition"
        scope_filter = Assignments::ScopedToUser.new(@course, @student)
        expect(scope_filter.scope).not_to include(unpublished)
      end

      it "returns unpublished assignments if user can :read_as_admin" do
        RoleOverride::GRANULAR_MANAGE_ASSIGNMENT_PERMISSIONS.each do |permission|
          @course.account.role_overrides.create!({
                                                   role: teacher_role,
                                                   permission:,
                                                   enabled: false
                                                 })
        end
        expect(@course.grants_right?(@teacher, :manage_assignments_add)).to be_falsey,
                                                                            "precondition"
        expect(@course.grants_right?(@teacher, :read_as_admin)).to be_truthy,
                                                                   "precondition"
        scope_filter = Assignments::ScopedToUser.new(@course, @teacher)
        expect(scope_filter.scope).to include(unpublished)
      end
    end
  end
end
