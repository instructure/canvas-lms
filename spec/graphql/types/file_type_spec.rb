# frozen_string_literal: true

#
# Copyright (C) 2019 - present Instructure, Inc.
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

require_relative "../graphql_spec_helper"

describe Types::FileType do
  let_once(:course) do
    course_with_teacher(active_all: true)
    @course
  end
  let_once(:student) { student_in_course(course: @course) }
  let_once(:file) { attachment_with_context(course) }
  let(:file_type) { GraphQLTypeTester.new(file, current_user: @teacher) }

  it "has display name" do
    expect(file_type.resolve("displayName")).to eq file.display_name
  end

  it "has the file's size" do
    expect(file_type.resolve("size")).to eq "100 Bytes"
  end

  it "has modules" do
    module1 = course.context_modules.create!(name: "Module 1")
    module2 = course.context_modules.create!(name: "Module 2")
    file.context_module_tags.create!(context_module: module1, context: course, tag_type: "context_module")
    file.context_module_tags.create!(context_module: module2, context: course, tag_type: "context_module")
    expect(file_type.resolve("modules { _id }").sort).to eq [module1.id.to_s, module2.id.to_s]
  end

  it "requires read permission" do
    other_course_student = student_in_course(course: course_factory).user
    resolver = GraphQLTypeTester.new(file, current_user: other_course_student)
    expect(resolver.resolve("_id")).to be_nil
  end

  it "requires the file to not be deleted" do
    file.destroy
    expect(file_type.resolve("displayName")).to be_nil
  end

  it "return the url if the file is not locked" do
    expect(
      file_type.resolve("url", request: ActionDispatch::TestRequest.create, current_user: @student)
    ).to eq "http://test.host/files/#{file.id}/download?download_frd=1"
  end

  it "returns nil for the url if the file is locked" do
    file.locked = true
    file.save!
    expect(
      file_type.resolve("url", request: ActionDispatch::TestRequest.create, current_user: @student)
    ).to be_nil
  end

  it "has a thumbnail url" do
    f = attachment_with_context(course, uploaded_data: stub_png_data, content_type: "image/png")
    f_type = GraphQLTypeTester.new(f, current_user: @teacher)
    expect(
      f_type.resolve("thumbnailUrl", request: ActionDispatch::TestRequest.create, current_user: @student).start_with?("http://localhost/images/thumbnails/show")
    ).to be true
  end

  describe "url" do
    let(:file) { attachment_with_context(course, uploaded_data: stub_png_data, content_type: "image/png") }
    let(:type_tester) { GraphQLTypeTester.new(file, current_user: @student) }

    it "returns an https URL if the request was issued over SSL" do
      request = ActionDispatch::TestRequest.create({ "HTTPS" => "on" })
      expect(type_tester.resolve("url", request:, current_user: @student)).to start_with("https:")
    end

    it "returns an http URL if the request was not issued over SSL" do
      request = ActionDispatch::TestRequest.create
      expect(type_tester.resolve("url", request:, current_user: @student)).to start_with("http:")
    end
  end

  context "submission preview url" do
    before(:once) do
      @assignment = assignment_model(course: @course)
      @student_file = attachment_with_context(@student, content_type: "application/pdf")
      @submission = @assignment.submit_homework(
        @student,
        body: "Attempt 1",
        submitted_at: 2.hours.ago,
        submission_type: "online_upload",
        attachments: [@student_file]
      )
      AttachmentAssociation.create!(attachment: @student_file, context: @submission, context_type: "Submission")
      @resolver = GraphQLTypeTester.new(@student_file, current_user: @student)
    end

    it "returns nil if the the file is locked" do
      file.update!(locked: true)
      expect(
        file_type.resolve(
          'submissionPreviewUrl(submissionId: "' + @submission.id.to_s + '")',
          request: ActionDispatch::TestRequest.create,
          current_user: @student
        )
      ).to be_nil
    end

    it "returns nil if the file is not a canvadocable type" do
      allow(Canvadocs).to receive(:enabled?).and_return true
      @student_file.update!(content_type: "application/unknown")
      expect(
        @resolver.resolve('submissionPreviewUrl(submissionId: "' + @submission.id.to_s + '")')
      ).to be_nil
    end

    it "returns nil if canvadocs is not enabled" do
      allow(Canvadocs).to receive(:enabled?).and_return false
      expect(
        @resolver.resolve('submissionPreviewUrl(submissionId: "' + @submission.id.to_s + '")')
      ).to be_nil
    end

    it "returns nil if the given submission id is not associated with the attachment" do
      other_assignment = assignment_model(course: @course)
      other_submission = other_assignment.submit_homework(
        @student,
        body: "Attempt 1",
        submitted_at: 2.hours.ago
      )
      resp = @resolver.resolve('submissionPreviewUrl(submissionId: "' + other_submission.id.to_s + '")')
      expect(resp).to be_nil
    end

    it "returns the submission preview url" do
      allow(Canvadocs).to receive(:enabled?).and_return true
      resp = @resolver.resolve('submissionPreviewUrl(submissionId: "' + @submission.id.to_s + '")')
      expect(resp).not_to be_nil
      expect(resp.start_with?("/api/v1/canvadoc_session")).to be true
    end
  end
end
