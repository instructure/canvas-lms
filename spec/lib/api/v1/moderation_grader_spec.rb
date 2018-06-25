#
# Copyright (C) 2012 - present Instructure, Inc.
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

require_relative '../../../spec_helper.rb'

describe "Api::V1::ModerationGrader" do
  api = (Class.new do
    include Api::V1::ModerationGrader
  end).new

  describe "#moderation_graders_json" do
    let_once(:course) do
      course_with_teacher(active_all: true)
      @course
    end

    let_once(:teacher) { @teacher }
    let_once(:grader_1) do
      ta = User.create!(name: "Adam Jones")
      course.enroll_ta(ta, enrollment_state: 'active')
      ta
    end
    let_once(:grader_2) do
      ta = User.create!(name: "Betty Ford")
      course.enroll_ta(ta, enrollment_state: 'active')
      ta
    end

    let_once(:assignment) { @course.assignments.create!(final_grader: @teacher, grader_count: 2, moderated_grading: true) }

    let_once(:session) { Object.new }

    let(:json) { api.moderation_graders_json(assignment, teacher, session) }

    before :once do
      assignment.moderation_graders.create!(anonymous_id: "abcde", user: grader_1)
      assignment.moderation_graders.create!(anonymous_id: "fghij", user: grader_2)
    end

    context "when the user can view other grader identities" do
      let(:json) { api.moderation_graders_json(assignment, teacher, session) }

      it "returns all provisional moderation graders for the assignment" do
        expect(json.length).to be(2)
      end

      it "excludes the final grader" do
        assignment.moderation_graders.create!(anonymous_id: "teach", user: teacher)
        expect(json.map {|grader| grader['user_id']}).not_to include(teacher.id)
      end

      it "includes user_id on graders" do
        expect(json.map {|grader| grader['user_id']}).to match_array([grader_1.id, grader_2.id])
      end

      it "includes ids on graders" do
        expect(json.map {|grader| grader['id']}).to match_array(assignment.moderation_graders.map(&:id))
      end

      it "includes grader_name on graders" do
        expect(json.map {|grader| grader['grader_name']}).to match_array([grader_1, grader_2].map(&:short_name))
      end
    end

    context "when the user cannot view other grader identities" do
      before :once do
        assignment.update(grader_names_visible_to_final_grader: false)
      end

      it "returns all provisional moderation graders for the assignment" do
        expect(json.length).to be(2)
      end

      it "excludes the final grader" do
        assignment.moderation_graders.create!(anonymous_id: "teach", user: teacher)
        expect(json.map {|grader| grader['anonymous_id']}).not_to include("teach")
      end

      it "includes anonymous_id on graders" do
        expect(json.map {|grader| grader['anonymous_id']}).to match_array(["abcde", "fghij"])
      end

      it "includes ids on graders" do
        expect(json.map {|grader| grader['id']}).to match_array(assignment.moderation_graders.map(&:id))
      end

      it "excludes grader_name from graders" do
        expect(json).to all(not_have_key('grader_name'))
      end
    end
  end
end
