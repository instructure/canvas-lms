#
# Copyright (C) 2017 - present Instructure, Inc.
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

require_relative '../spec_helper'

describe PlannerOverride do
  before :once do
    course_factory
    student_in_course
    teacher_in_course
    assignment_model course: @course
    @student_planner_override = PlannerOverride.create!(user_id: @student.id,
                                                        plannable_id: @assignment.id,
                                                        plannable_type: "Assignment",
                                                        visible: false)
    @teacher_planner_override = PlannerOverride.create!(user_id: @teacher.id,
                                                        plannable_id: @assignment.id,
                                                        plannable_type: "Assignment",
                                                        visible: true)
  end


  describe "::plannable_workflow_state" do
    context "respond_to?(:published?)" do
      mock_asset = Class.new do
        def initialize(opts={})
          opts = {published: true, deleted: false}.merge(opts)
          @published = opts[:published]
          @deleted = opts[:deleted]
        end

        def published?; !!@published; end

        def unpublished?; !@published; end

        def deleted?; @deleted; end
      end

      it "returns 'deleted' for deleted assets" do
        a = mock_asset.new(deleted: true)
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'deleted'
      end

      it "returns 'active' for published assets" do
        a = mock_asset.new(published: true)
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'active'
      end

      it "returns 'unpublished' for unpublished assets" do
        a = mock_asset.new(published: false)
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'unpublished'
      end
    end

    context "respond_to?(:workflow_state)" do
      mock_asset = Class.new do
        attr_reader :workflow_state
        def initialize(workflow_state)
          @workflow_state = workflow_state
        end
      end

      it "returns 'active' for 'active' workflow_state" do
        a = mock_asset.new('active')
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'active'
      end

      it "returns 'active' for 'available' workflow_state" do
        a = mock_asset.new('available')
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'active'
      end

      it "returns 'active' for 'published' workflow_state" do
        a = mock_asset.new('published')
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'active'
      end

      it "returns 'unpublished' for 'unpublished' workflow_state" do
        a = mock_asset.new('unpublished')
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'unpublished'
      end

      it "returns 'deleted' for 'deleted' workflow_state" do
        a = mock_asset.new('deleted')
        expect(PlannerOverride.plannable_workflow_state(a)).to eq 'deleted'
      end

      it "returns nil for other workflow_state" do
        a = mock_asset.new('terrified')
        expect(PlannerOverride.plannable_workflow_state(a)).to eq nil
      end
    end
  end

  describe "#for_user" do
    it "should return all PlannerOverrides for specified user" do
      student_overrides = PlannerOverride.for_user(@student)
      expect(student_overrides.count).to eq 1
      expect(student_overrides.first.user_id).to eq @student.id

      teacher_overrides = PlannerOverride.for_user(@teacher)
      expect(teacher_overrides.count).to eq 1
      expect(teacher_overrides.first.user_id).to eq @teacher.id
    end
  end

  describe "#update_for" do
    it "should update the PlannerOverride for the given object" do
      overrides = PlannerOverride.where(plannable_id: @assignment.id)
      expect(overrides.all? { |o| o.workflow_state == 'active' }).to be_truthy

      @assignment.destroy
      PlannerOverride.update_for(@assignment.reload)
      expect(overrides.reload.all? { |o| o.workflow_state == 'deleted' }).to be_truthy
    end
  end
end
