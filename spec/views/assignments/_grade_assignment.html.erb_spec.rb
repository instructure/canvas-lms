#
# Copyright (C) 2018 - present Instructure, Inc.
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
require 'spec_helper'
require_relative '../views_helper'

describe '_grade_assignment' do
  before :once do
    course_with_ta
  end

  before :each do
    view_context(@course, @ta)
    @assignment = @course.assignments.create!(title: 'an assignment')
    assign(:assignment, @assignment)
    assign(:assignment_presenter, AssignmentPresenter.new(@assignment))
  end

  describe "SpeedGrader link mount point" do
    it 'renders if user can view all grades but not manage grades' do
      @course.account.role_overrides.create!(permission: 'manage_grades', role: ta_role, enabled: false)
      render partial: 'assignments/grade_assignment'
      expect(response).to have_tag("div#speed_grader_link_mount_point")
    end

    it 'renders if user can manage grades but not view all grades' do
      @course.account.role_overrides.create!(permission: 'view_all_grades', role: ta_role, enabled: false)
      render partial: 'assignments/grade_assignment'
      expect(response).to have_tag("div#speed_grader_link_mount_point")
    end

    it 'does not render if user can neither view all grades nor manage grades' do
      @course.account.role_overrides.create!(permission: 'view_all_grades', role: ta_role, enabled: false)
      @course.account.role_overrides.create!(permission: 'manage_grades', role: ta_role, enabled: false)
      render partial: 'assignments/grade_assignment'
      expect(response).not_to have_tag("div#speed_grader_link_mount_point")
    end
  end

  describe "student group filter mount point" do
    it 'renders if user can view all grades but not manage grades' do
      @course.account.role_overrides.create!(permission: 'manage_grades', role: ta_role, enabled: false)
      render partial: 'assignments/grade_assignment'
      expect(response).to have_tag("div#student_group_filter_mount_point")
    end

    it 'renders if user can manage grades but not view all grades' do
      @course.account.role_overrides.create!(permission: 'view_all_grades', role: ta_role, enabled: false)
      render partial: 'assignments/grade_assignment'
      expect(response).to have_tag("div#student_group_filter_mount_point")
    end

    it 'does not render if user can neither view all grades nor manage grades' do
      @course.account.role_overrides.create!(permission: 'view_all_grades', role: ta_role, enabled: false)
      @course.account.role_overrides.create!(permission: 'manage_grades', role: ta_role, enabled: false)
      render partial: 'assignments/grade_assignment'
      expect(response).not_to have_tag("div#student_group_filter_mount_point")
    end
  end

  describe "View Uploads Status link" do
    let(:progress) { Progress.new(context: @assignment, completion: 100) }

    it "is displayed when the user can manage grades" do
      allow(@assignment).to receive(:submission_reupload_progress).and_return(progress)
      assign(:can_grade, true)
      render partial: "assignments/grade_assignment"
      expect(response.body).to include "View Uploads Status"
    end

    it "is not displayed when the user cannot manage grades" do
      allow(@assignment).to receive(:submission_reupload_progress).and_return(progress)
      assign(:can_grade, false)
      render partial: "assignments/grade_assignment"
      expect(response.body).not_to include "View Uploads Status"
    end

    it "is not displayed when no submissions have been uploaded" do
      assign(:can_grade, true)
      render partial: "assignments/grade_assignment"
      expect(response.body).not_to include "View Uploads Status"
    end
  end
end
