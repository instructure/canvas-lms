# frozen_string_literal: true

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

describe GradebookCsvsController do
  before :once do
    course_with_teacher active_all: true
    @course.short_name = "ENG/ 101"
    @course.save
  end

  it "uses GradebookCsvsController" do
    expect(controller).to be_an_instance_of(GradebookCsvsController)
  end

  describe "POST 'create'" do
    it "returns the attachment and progress" do
      user_session @teacher

      post :create, params: { course_id: @course.id }, format: :json
      json = json_parse(response.body)
      expect(response).to be_successful
      expect(json).to have_key "attachment_id"
      expect(json).to have_key "progress_id"
    end

    it "creates the attachment and progress" do
      user_session @teacher

      post :create, params: { course_id: @course.id }, format: :json
      json = json_parse(response.body)
      expect(Attachment.find(json["attachment_id"])).not_to be_nil
      expect(Progress.find(json["progress_id"])).not_to be_nil
    end

    it "accepts an assignment_order param to be passed to the CSV exporter" do
      assignment = @course.assignments.create!
      assignment2 = @course.assignments.create!
      user_session(@teacher)

      expect_any_instance_of(Progress).to receive(:process_job).with(
        anything,
        :generate_csv,
        anything,
        anything,
        hash_including(assignment_order: [assignment2.id, assignment.id]),
        anything
      )
      post :create, params: { course_id: @course.id, assignment_order: [assignment2.id, assignment.id] }
    end

    it "names the CSV file after course#short_name" do
      user_session @teacher

      post :create, params: { course_id: @course.id }, format: :json
      json = json_parse(response.body)
      attachment = Attachment.find(json["attachment_id"])
      expect(File.basename(attachment.filename.split("-").last, ".csv")).to eq("ENG__101")
    end

    it "the CSV filename starts with YYYY-MM-DDTHHMM" do
      user_session @teacher
      now = Time.zone.now
      Timecop.freeze(now) do
        post :create, params: { course_id: @course.id }, format: :json
      end

      filename = Attachment.find(json_parse(response.body)["attachment_id"]).filename
      expect(/^#{now.strftime("%FT%H%M")}_Grades/).to match(filename)
    end
  end
end
