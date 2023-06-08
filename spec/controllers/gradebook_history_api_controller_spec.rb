# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

describe GradebookHistoryApiController do
  def json_body
    JSON.parse(response.body.split(";").last)
  end

  def date_key(submission)
    submission.graded_at.to_date.as_json
  end

  before :once do
    course_with_teacher(active_all: true)

    student = user_with_pseudonym(username: "student@example.com", active_all: 1)
    student_in_course(user: student, active_all: 1)
    student2 = user_with_pseudonym(username: "student2@example.com", active_all: 1)
    student_in_course(user: student2, active_all: 1)
    student3 = user_with_pseudonym(username: "student3@example.com", active_all: 1)
    student_in_course(user: student3, active_all: 1)

    @grader = user_with_pseudonym(name: "Grader", username: "grader@example.com", active_all: 1)
    @super_grader = user_with_pseudonym(name: "SuperGrader", username: "super_grader@example.com", active_all: 1)
    @other_grader = user_with_pseudonym(name: "OtherGrader", username: "other_grader@example.com", active_all: 1)

    @assignment1 = @course.assignments.create!(title: "some assignment")
    @assignment2 = @course.assignments.create!(title: "another assignment")

    @submission1 = @assignment1.submit_homework(student)
    @submission2 = @assignment1.submit_homework(student2)
    @submission3 = @assignment1.submit_homework(student3)
    @submission4 = @assignment2.submit_homework(student)

    @submission1.update!(graded_at: Time.now, grader_id: @grader.id, score: 100)
    @submission2.update!(graded_at: Time.now, grader_id: @super_grader.id, score: 90)
    @submission3.update!(graded_at: (Time.now - 24.hours), grader_id: @other_grader.id, score: 80)
    @submission4.update!(graded_at: (Time.now - 24.hours), grader_id: @other_grader.id, score: 70)
  end

  before do
    user_session(@teacher)
  end

  describe "GET days" do
    def graders_hash_for(submission)
      json_body.find { |d| d["date"] == date_key(submission) }["graders"]
    end

    describe "default params" do
      before { get "days", params: { course_id: @course.id }, format: "json" }

      it "provides an array of the dates where there are submissions" do
        expect(json_body.pluck("date").sort).to eq [date_key(@submission1), date_key(@submission3)].sort
      end

      it "nests all the graders for a day inside the date entry" do
        expect(graders_hash_for(@submission1).pluck("name").sort).to eq ["Grader", "SuperGrader"]
        expect(graders_hash_for(@submission3).pluck("name")).to eq ["OtherGrader"]
      end

      it "includes a list of assignment names for each grader" do
        grader_hash = graders_hash_for(@submission3).find { |h| h["id"] == @other_grader.id }
        expect(grader_hash["assignments"].pluck("name").sort).to eq ["some assignment", "another assignment"].sort
      end
    end

    it "paginates" do
      get "days", params: { course_id: @course.id, page: 2, per_page: 2 }, format: "json"
      expect(json_body.pluck("date")).to eq [@submission3.graded_at.to_date.as_json]
    end
  end

  describe "GET day_details" do
    before { get "day_details", params: { course_id: @course.id, date: @submission1.graded_at.strftime("%Y-%m-%d") }, format: "json" }

    it "has the graders as the top level piece of data" do
      expect(json_body.pluck("id").sort).to eq [@grader.id, @super_grader.id].sort
    end

    it "lists assignment names under the graders" do
      expect(json_body.find { |g| g["id"] == @grader.id }["assignments"].first["name"]).to eq @assignment1.title
    end
  end

  describe "GET assignment" do
    let(:date) { @submission1.graded_at.strftime("%Y-%m-%d") }
    let(:params) { { course_id: @course.id, date:, grader_id: @grader.id, assignment_id: @assignment1.id } }

    before { get("submissions", params:, format: "json") }

    it "lists submissions" do
      expect(json_body.first["submission_id"]).to eq @submission1.id
      expect(json_body.first["versions"].first["score"]).to eq 100
    end
  end

  describe "GET feed" do
    context "deleted submissions" do
      before do
        @submission1.destroy
        get "feed", params: { course_id: @course.id }, format: "json"
      end

      it "does not return an error" do
        expect(response).to be_ok
      end

      it "excludes deleted submissions in the response" do
        response_ids = json_body.pluck("id")
        expect(response_ids).to_not include @submission1.id
      end
    end
  end
end
