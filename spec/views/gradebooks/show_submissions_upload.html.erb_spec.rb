# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

require "spec_helper"
require_relative "../views_helper"

describe "gradebooks/show_submissions_upload" do
  let(:assignment) { @course.assignments.create!(title: "Example Assignment") }
  let(:presenter) { Submission::UploadPresenter.for(@course, assignment) }
  let(:progress) { presenter.progress }
  let(:document) { Nokogiri::HTML5(response.body) }

  before do
    course_with_student
    view_context

    Progress.create!(context: assignment, completion: 0, tag: "submissions_reupload")
    assign(:assignment, assignment)
    assign(:presenter, presenter)
  end

  describe "when the user has not uploaded submissions" do
    it "displays a message indicating no uploads" do
      Progress.where(tag: "submissions_reupload").order(created_at: :desc).first.destroy
      render "gradebooks/show_submissions_upload"
      expect(document.css("h2").first.text).to include("No Submissions Have Been Uploaded")
    end
  end

  describe "when the submissions upload is in progress" do
    it "displays a message indicating upload in progress" do
      render "gradebooks/show_submissions_upload"
      expect(document.css(".Alert").first.text).to include("We are currently processing your files.")
    end
  end

  describe "when the submissions upload is finished" do
    before do
      progress.workflow_state = "completed"
      progress.set_results({
                             comments: [
                               {
                                 attachments: [
                                   { filename: "egg.png", display_name: "egg.png", id: "9901" }
                                 ],

                                 id: "9801",

                                 submission: {
                                   user_id: "1101",
                                   user_name: "Adam Jones"
                                 }
                               },

                               {
                                 attachments: [
                                   { filename: "mydog.png", display_name: "My Dog", id: "9902" }
                                 ],

                                 id: "9802",

                                 submission: {
                                   user_id: "1102",
                                   user_name: "Betty Ford"
                                 }
                               },

                               {
                                 attachments: [
                                   { filename: "bacon.png", display_name: "Delicious Bacon", id: "9903" },
                                   { filename: "toast.png", display_name: "toast.png", id: "9904" },
                                   { filename: "coffee.png", display_name: "coffee.png", id: "9905" }
                                 ],

                                 id: "9803",

                                 submission: {
                                   user_id: "1103",
                                   user_name: "Albert Breakfast"
                                 }
                               }
                             ],

                             ignored_files: [
                               "/tmp/pfKn/fartingkangaroo.mp4",
                               "/tmp/pfKn/naughtymuppets.jpeg"
                             ]
                           })
    end

    it "displays a message indicating successful upload" do
      render "gradebooks/show_submissions_upload"
      expect(document.css(".Alert").first.text).to include("Done!")
    end

    it "displays a message with the number of uploads" do
      render "gradebooks/show_submissions_upload"
      expect(document.css("h3").first.text).to include("(3) files were attached")
    end

    context "when some files were uploaded" do
      before do
        render "gradebooks/show_submissions_upload"
      end

      it "includes a row for each student" do
        student_names = document.css("#student-files tbody tr th").map { |e| e.text.strip }
        expect(student_names).to match_array ["Adam Jones", "Betty Ford", "Albert Breakfast"]
      end

      it "includes the files uploaded for each student" do
        file = document.css("#student-files tbody tr td")[0]
        expect(file.text.strip.gsub(/\s+/, " ")).to eql "egg.png"
      end

      it "mentions renamed files" do
        file = document.css("#student-files tbody tr td")[1]
        expect(file.text.strip.gsub(/\s+/, " ")).to eql "My Dog (renamed from mydog.png)"
      end

      it "separates each file with a comma" do
        file = document.css("#student-files tbody tr td")[2]
        expect(file.text.strip.gsub(/\s+/, " ")).to eql "Delicious Bacon (renamed from bacon.png), toast.png, coffee.png"
      end
    end

    it "displays a message with the number of files ignored when some files were ignored" do
      render "gradebooks/show_submissions_upload"
      expect(document.css("h3").last.text).to include("(2) files were ignored")
    end

    it "does not display a 'files ignored' message when no files were ignored" do
      results = progress.results
      results[:ignored_files] = []
      progress.set_results(results)
      render "gradebooks/show_submissions_upload"
      expect(document.css("h3").count).to be 1
    end
  end

  describe "when the submissions upload has failed" do
    it "displays a message indicating a failed upload" do
      progress.workflow_state = "failed"
      render "gradebooks/show_submissions_upload"
      expect(document.css(".Alert").first.text).to include("Oops, there was a problem")
    end
  end
end
