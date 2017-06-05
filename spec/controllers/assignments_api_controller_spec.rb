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
#

require_relative '../apis/api_spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../sharding_spec_helper')

describe AssignmentsApiController do
  before :once do
    course_with_teacher(active_all: true)
    student_in_course(active_all: true)
    @group = @course.assignment_groups.create(:name => "some group")
    @assignment = @course.assignments.create(
      :title => "some assignment",
      :assignment_group => @group,
      :due_at => Time.zone.now + 1.week,
      :points_possible => 20
    )
  end

  describe "POST 'duplicate'" do
    it "students cannot duplicate" do
      user_session(@student)
      post 'duplicate', :course_id => @course.id, :assignment_id => @assignment.id
      assert_unauthorized
    end

    it "should duplicate if teacher" do
      user_session(@teacher)
      post 'duplicate', :course_id => @course.id, :assignment_id => @assignment.id
      expect(response.code).to eq("200")
    end

    it "should require non-quiz" do
      user_session(@teacher)
      assignment = @course.assignments.create(:title => "some assignment")
      assignment.quiz = @course.quizzes.create
      assignment.save!
      post 'duplicate', :course_id => @course.id, :assignment_id => assignment.id
      expect(response.code).to eq("400")
    end

    it "should require non-discussion topic" do
      user_session(@teacher)
      assignment = group_discussion_assignment.assignment
      assignment.save!
      post 'duplicate', :course_id => @course.id, :assignment_id => assignment.id
      expect(response.code).to eq("400")
    end

    it "should require non-wikipage" do
      user_session(@teacher)
      assignment = wiki_page_assignment_model
      assignment.save!
      post 'duplicate', :course_id => @course.id, :assignment_id => assignment.id
      assert_unauthorized
    end

    it "should require non-deleted assignment" do
      user_session(@teacher)
      assignment = @course.assignments.create(
        :title => "some assignment",
        :workflow_state => "deleted")
      assignment.save!
      post 'duplicate', :course_id => @course.id, :assignment_id => assignment.id
      expect(response.code).to eq("400")
    end

    it "should require existing assignment" do
      user_session(@teacher)
      post 'duplicate', :course_id => @course.id, :assignment_id => Assignment.maximum(:id) + 100
      expect(response.code).to eq("400")
    end
  end
end
