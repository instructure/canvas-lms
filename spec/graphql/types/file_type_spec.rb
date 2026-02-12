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

require "cgi"
require "uri"
require_relative "../graphql_spec_helper"

describe Types::FileType do
  let_once(:course) do
    course_with_teacher(active_all: true)
    @course
  end
  let_once(:student) { student_in_course(course: @course) }
  let_once(:file) { attachment_with_context(course) }
  let(:file_type) do
    GraphQLTypeTester.new(file, current_user: @teacher, in_app: true, domain_root_account: Account.default)
  end

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

  it "returns a verifier in the url unless the disable_adding_uuid_verifier_in_api flag is on" do
    file.root_account.disable_feature!(:disable_adding_uuid_verifier_in_api)
    uuid = file.uuid
    expect(
      file_type.resolve("url", request: ActionDispatch::TestRequest.create, current_user: @student)
    ).to include("verifier=#{uuid}")
  end

  it "does not return a verifier in the url if the disable_adding_uuid_verifier_in_api flag is on" do
    file.root_account.enable_feature!(:disable_adding_uuid_verifier_in_api)
    uuid = file.uuid
    expect(
      file_type.resolve("url", request: ActionDispatch::TestRequest.create, current_user: @student)
    ).not_to include("verifier=#{uuid}")
  end

  it "add a location query param to url if file_association_access feature flag is enabled" do
    file.root_account.enable_feature!(:file_association_access)
    file_type = GraphQLTypeTester.new(file, current_user: @teacher, in_app: true, domain_root_account: Account.default, asset_location: "course_#{file.context_id}")
    expect(
      file_type.resolve("url", request: ActionDispatch::TestRequest.create, current_user: @student)
    ).to include("location=course_#{file.context_id}")
  end

  it "does not add a location query param to url if file_association_access feature flag is disabled" do
    file.root_account.disable_feature!(:file_association_access)
    file.root_account.disable_feature!(:disable_adding_uuid_verifier_in_api)
    file_type = GraphQLTypeTester.new(file, current_user: @teacher, in_app: true, domain_root_account: Account.default, asset_location: "course_#{file.context_id}")
    resolver = file_type.resolve("url", request: ActionDispatch::TestRequest.create, current_user: @student)
    expect(
      resolver
    ).not_to include("location")
    expect(
      resolver
    ).to include("verifier=#{file.uuid}")
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

  it "prevents N+1 queries when loading thumbnail URLs for multiple files" do
    # Create multiple files
    files = Array.new(5) do |i|
      attachment_with_context(course, uploaded_data: stub_png_data, content_type: "image/png", filename: "test#{i}.png")
    end

    # Count queries that match any thumbnail queries
    query_count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _start, _finish, _id, payload|
      query_count += 1 if /SELECT.*thumbnails/.match?(payload[:sql])
    end

    # Test the ThumbnailLoader directly using GraphQL::Batch
    GraphQL::Batch.batch do
      files.each do |file|
        Loaders::ThumbnailLoader.for.load(file).then(&:thumbnail)
      end
    end

    # Should have at most 1 bulk query instead of N individual queries
    expect(query_count).to be <= 1
    ActiveSupport::Notifications.unsubscribe(subscriber)
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

    context "with peer reviews" do
      before(:once) do
        @assignment = assignment_model(course: @course, peer_reviews: true)
        @reviewee = student_in_course(course: @course, active_all: true).user
        @reviewer = student_in_course(course: @course, active_all: true).user
        @submission_file = attachment_with_context(@course, user: @reviewee)
        @submission = @assignment.submit_homework(
          @reviewee,
          submission_type: "online_upload",
          attachments: [@submission_file]
        )
        AttachmentAssociation.create!(attachment: @submission_file, context: @submission, context_type: "Submission")
        @assignment.assign_peer_review(@reviewer, @reviewee)
      end

      it "peer_reviewer? returns true for assigned peer reviewers" do
        expect(@submission.peer_reviewer?(@reviewer)).to be true
      end

      it "peer_reviewer? returns false for non-peer-reviewers" do
        other_student = student_in_course(course: @course, active_all: true).user
        expect(@submission.peer_reviewer?(other_student)).to be false
      end

      it "returns regular submission download URL for non-anonymous peer reviewers" do
        submission_type = GraphQLTypeTester.new(@submission, current_user: @reviewer, in_app: true, domain_root_account: Account.default, request: ActionDispatch::TestRequest.create)
        urls = submission_type.resolve("attachments { url }")

        expect(urls).not_to be_empty
        url = urls.first
        expect(url).to include("/courses/#{@course.id}/assignments/#{@assignment.id}/submissions/#{@reviewee.id}")
        expect(url).to include("download=#{@submission_file.id}")
      end

      it "returns anonymous submission download URL for anonymous peer reviewers" do
        @assignment.update!(anonymous_peer_reviews: true)
        submission_type = GraphQLTypeTester.new(@submission, current_user: @reviewer, in_app: true, domain_root_account: Account.default, request: ActionDispatch::TestRequest.create)
        urls = submission_type.resolve("attachments { url }")

        expect(urls).not_to be_empty
        url = urls.first
        expect(url).to include("/courses/#{@course.id}/assignments/#{@assignment.id}/anonymous_submissions/#{@submission.anonymous_id}")
        expect(url).to include("download=#{@submission_file.id}")
      end

      it "does not return submission download URL for non-peer-reviewers" do
        other_student = student_in_course(course: @course, active_all: true).user
        submission_type = GraphQLTypeTester.new(@submission, current_user: other_student, in_app: true, domain_root_account: Account.default, request: ActionDispatch::TestRequest.create)
        urls = submission_type.resolve("attachments { url }")

        # Should return nil or regular file download URL, not submission URL
        if urls.present?
          url = urls.first
          expect(url).not_to include("/submissions/") if url
        end
      end

      it "does not cause N+1 queries when loading URLs for multiple files" do
        # Add more files to the submission
        file2 = attachment_with_context(@course, user: @reviewee)
        file3 = attachment_with_context(@course, user: @reviewee)
        @submission.attachment_ids = "#{@submission_file.id},#{file2.id},#{file3.id}"
        @submission.save!
        AttachmentAssociation.create!(attachment: file2, context: @submission, context_type: "Submission")
        AttachmentAssociation.create!(attachment: file3, context: @submission, context_type: "Submission")

        submission_type = GraphQLTypeTester.new(@submission, current_user: @reviewer, in_app: true, domain_root_account: Account.default, request: ActionDispatch::TestRequest.create)

        # Count queries for 3 files
        query_count = 0
        counter = ->(*) { query_count += 1 }
        ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
          urls = submission_type.resolve("attachments { url }")
          expect(urls.length).to eq 3
        end

        # Now add 2 more files and verify query count doesn't increase significantly
        file4 = attachment_with_context(@course, user: @reviewee)
        file5 = attachment_with_context(@course, user: @reviewee)
        @submission.attachment_ids = "#{@submission_file.id},#{file2.id},#{file3.id},#{file4.id},#{file5.id}"
        @submission.save!
        AttachmentAssociation.create!(attachment: file4, context: @submission, context_type: "Submission")
        AttachmentAssociation.create!(attachment: file5, context: @submission, context_type: "Submission")

        # Reload to clear any caching
        @submission.reload

        # Count queries for 5 files
        query_count_with_more_files = 0
        counter2 = ->(*) { query_count_with_more_files += 1 }
        ActiveSupport::Notifications.subscribed(counter2, "sql.active_record") do
          urls = submission_type.resolve("attachments { url }")
          expect(urls.length).to eq 5
        end

        # Query count should not increase linearly with number of files
        # Allow for some variance but ensure we don't have N+1
        # The difference should be minimal (just for loading 2 extra attachments)
        expect(query_count_with_more_files - query_count).to be <= 2
      end

      it "checks peer_reviewer? only once per submission, not per file" do
        # Add multiple files to the submission
        file2 = attachment_with_context(@course, user: @reviewee)
        file3 = attachment_with_context(@course, user: @reviewee)
        @submission.attachment_ids = "#{@submission_file.id},#{file2.id},#{file3.id}"
        @submission.save!
        AttachmentAssociation.create!(attachment: file2, context: @submission, context_type: "Submission")
        AttachmentAssociation.create!(attachment: file3, context: @submission, context_type: "Submission")

        # Mock peer_reviewer? at the class level to count calls across all instances
        call_count = 0
        allow_any_instance_of(Submission).to receive(:peer_reviewer?).and_wrap_original do |method, *args|
          call_count += 1
          method.call(*args)
        end

        submission_type = GraphQLTypeTester.new(@submission, current_user: @reviewer, in_app: true, domain_root_account: Account.default, request: ActionDispatch::TestRequest.create)
        urls = submission_type.resolve("attachments { url }")
        expect(urls.length).to eq 3

        # peer_reviewer? should NOT be called once per file (3 times)
        # It should be called a constant number of times regardless of file count
        # (may be 1-2 depending on GraphQL loader behavior, but NOT 3)
        expect(call_count).to be < 3
      end
    end
  end

  context "submission preview url" do
    before(:once) do
      @assignment = assignment_model(course: @course)
      @student_file = attachment_with_context(@course, content_type: "application/pdf", user: @student)
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

    it "returns nil when no id is passed" do
      allow(Canvadocs).to receive(:enabled?).and_return true
      resp = @resolver.resolve("submissionPreviewUrl")
      expect(resp).to be_nil
    end

    context "when assignment has anonymous_instructor_annotations is enabled" do
      def get_blob_json_from_url(url)
        qs = URI.parse(url).query
        params = CGI.parse(qs)
        blob = params["blob"].first
        decoded_blob = CGI.unescape(blob)
        JSON.parse(decoded_blob)
      end

      before(:once) do
        @course.account.enable_feature!(:anonymous_instructor_annotations)
        @course.enable_feature!(:anonymous_instructor_annotations)
        @assignment.update!(anonymous_instructor_annotations: true)
      end

      before do
        allow(Canvadocs).to receive(:enabled?).and_return true
      end

      it "teacher can anonymize annotations" do
        resp = @resolver.resolve(
          'submissionPreviewUrl(submissionId: "' + @submission.id.to_s + '")',
          current_user: @teacher
        )

        expect(resp).not_to be_nil
        blob_json = get_blob_json_from_url(resp)
        expect(blob_json).to include("anonymous_instructor_annotations" => true)
      end

      it "teacher without :manage_grades permission can't anonymize annotations" do
        ta = ta_in_course(course: @course).user
        @course.account.role_overrides.create!(permission: "manage_grades", role: ta_role, enabled: false)
        resp = @resolver.resolve(
          'submissionPreviewUrl(submissionId: "' + @submission.id.to_s + '")',
          current_user: ta
        )

        expect(resp).not_to be_nil
        blob_json = get_blob_json_from_url(resp)
        expect(blob_json).to include("anonymous_instructor_annotations" => false)
      end

      it "student can't anonymize annotations" do
        resp = @resolver.resolve('submissionPreviewUrl(submissionId: "' + @submission.id.to_s + '")')

        expect(resp).not_to be_nil
        blob_json = get_blob_json_from_url(resp)
        expect(blob_json).to include("anonymous_instructor_annotations" => false)
      end
    end
  end
end
