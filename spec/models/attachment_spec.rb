# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

describe Attachment do
  context "validation" do
    it "creates a new instance given valid attributes" do
      attachment_model
    end

    it "requires a context" do
      expect { attachment_model(context: nil) }.to raise_error(ActiveRecord::RecordInvalid, /Context/)
    end

    it "raises an error if you create in a deleted folder" do
      course_factory
      f1 = @course.folders.create!(name: "f1", workflow_state: "deleted")
      expect { attachment_model(context: @course, folder: f1) }.to raise_error ActiveRecord::StatementInvalid, /Cannot create attachments in deleted folders/
    end

    describe "category" do
      subject { attachment_model category: }

      context "with a valid category" do
        let(:category) { Attachment::ICON_MAKER_ICONS }

        it "does not raise a validation error" do
          expect { subject }.not_to raise_error
        end
      end

      context "with an invalid category" do
        let(:category) { "banana" }

        it "raises a validation error" do
          expect { subject }.to raise_error "Validation failed: Category is not included in the list"
        end
      end

      context "with a nil category" do
        let(:category) { nil }

        it "raises a validation error" do
          expect { subject }.to raise_error "Validation failed: Category can't be blank, Category is not included in the list"
        end
      end
    end
  end

  context "file_store_config" do
    around do |example|
      ConfigFile.unstub
      example.run
      ConfigFile.unstub
    end

    it "doesn't bomb on config" do
      Attachment.instance_variable_set(:@file_store_config, nil)
      ConfigFile.stub("file_store", { "storage" => "local" })
      expect { Attachment.file_store_config }.to_not raise_error
    end
  end

  context "default_values" do
    before :once do
      course_model
    end

    it "sets the display name to the filename if it is nil" do
      attachment_model(display_name: nil)
      expect(@attachment.display_name).to eql(@attachment.filename)
    end
  end

  context "public_url" do
    before do
      local_storage!
    end

    before :once do
      course_model
    end

    it "returns http as the protocol by default" do
      attachment_with_context(@course)
      expect(@attachment.public_url).to match(%r{^http://})
    end

    it "returns the protocol if specified" do
      attachment_with_context(@course)
      expect(@attachment.public_url(secure: true)).to match(%r{^https://})
    end

    context "for a quiz submission upload" do
      it "returns a routable url", type: :routing do
        quiz = @course.quizzes.create
        submission = Quizzes::SubmissionManager.new(quiz).find_or_create_submission(user_model)
        attachment = attachment_with_context(submission)
        expect(get(attachment.public_url)).to be_routable
      end
    end
  end

  context "public_url InstFS storage" do
    before :once do
      user_model
    end

    before do
      attachment_with_context(@user)
      @attachment.instfs_uuid = 1
      allow(InstFS).to receive(:enabled?).and_return true
      allow(InstFS).to receive(:authenticated_url)
    end

    it "gets url from InstFS when attachment has instfs_uuid" do
      @attachment.public_url
      expect(InstFS).to have_received(:authenticated_url)
    end

    it "still gets url from InstFS when attachment has instfs_uuid and instfs is later disabled" do
      allow(InstFS).to receive(:enabled?).and_return false
      @attachment.public_url
      expect(InstFS).to have_received(:authenticated_url)
    end

    it "does not get url from InstFS when instfs is enabled but attachment lacks instfs_uuid" do
      @attachment.instfs_uuid = nil
      @attachment.public_url
      expect(InstFS).not_to have_received(:authenticated_url)
    end
  end

  context "public_url s3_storage" do
    before do
      s3_storage!
    end

    it "gives back a signed s3 url" do
      a = attachment_model
      expect(a.public_url(expires_in: 1.day)).to match(%r{^https://})
      a.destroy_permanently!
    end
  end

  def configure_crocodoc
    PluginSetting.create! name: "crocodoc",
                          settings: { api_key: "blahblahblahblahblah" }
    allow_any_instance_of(Crocodoc::API).to receive(:upload).and_return "uuid" => "1234567890"
  end

  def configure_canvadocs(opts = {})
    ps = PluginSetting.where(name: "canvadocs").first_or_create
    ps.update_attribute :settings, {
      "api_key" => "blahblahblahblahblah",
      "base_url" => "http://example.com",
      "annotations_supported" => true
    }.merge(opts)
  end

  context "crocodoc" do
    include HmacHelper
    let_once(:user) { user_model }
    let_once(:course) { course_model }
    let_once(:student) do
      course.enroll_student(user_model).accept
      @user
    end
    before { configure_crocodoc }

    it "crocodocable?" do
      crocodocable_attachment_model
      expect(@attachment).to be_crocodocable
    end

    it "includes an allow list of moderated_grading_allow_list in the url blob" do
      crocodocable_attachment_model
      moderated_grading_allow_list = [user, student].map { |u| u.moderated_grading_ids(true) }

      @attachment.submit_to_crocodoc
      url_opts = {
        moderated_grading_allow_list:
      }
      url = Rack::Utils.parse_nested_query(@attachment.crocodoc_url(user, url_opts).sub(/^.*\?{1}/, ""))
      blob = extract_blob(url["hmac"],
                          url["blob"],
                          "user_id" => user.id,
                          "type" => "crocodoc")

      expect(blob["moderated_grading_allow_list"]).to include(user.moderated_grading_ids.as_json)
      expect(blob["moderated_grading_allow_list"]).to include(student.moderated_grading_ids.as_json)
    end

    it "always enables annotations when creating a crocodoc url" do
      crocodocable_attachment_model
      @attachment.submit_to_crocodoc

      url = Rack::Utils.parse_nested_query(@attachment.crocodoc_url(user, {}).sub(/^.*\?{1}/, ""))
      blob = extract_blob(url["hmac"],
                          url["blob"],
                          "user_id" => user.id,
                          "type" => "crocodoc")

      expect(blob["enable_annotations"]).to be(true)
    end

    it "does not modify the options reference given to create a crocodoc url" do
      crocodocable_attachment_model
      @attachment.submit_to_crocodoc

      url_opts = {}
      @attachment.crocodoc_url(user, url_opts)
      expect(url_opts).to eql({})
    end

    it "submits to crocodoc" do
      crocodocable_attachment_model
      expect(@attachment.crocodoc_available?).to be_falsey
      @attachment.submit_to_crocodoc

      expect(@attachment.crocodoc_available?).to be_truthy
      expect(@attachment.crocodoc_document.uuid).to eq "1234567890"
    end

    it "spawns delayed jobs to retry failed uploads" do
      allow_any_instance_of(Crocodoc::API).to receive(:upload).and_return "error" => "blah"
      crocodocable_attachment_model

      attempts = 3
      stub_const("Attachment::MAX_CROCODOC_ATTEMPTS", attempts)

      track_jobs do
        # first attempt
        @attachment.submit_to_crocodoc

        time = Time.now
        # nth attempt won't create more jobs
        attempts.times do
          time += 1.hour
          Timecop.freeze(time) do
            run_jobs
          end
        end
      end

      expect(created_jobs.count { |job| job.tag == "Attachment#submit_to_crocodoc" }).to eq attempts
    end

    it "submits to canvadocs if crocodoc fails to convert" do
      crocodocable_attachment_model
      @attachment.submit_to_crocodoc

      allow_any_instance_of(Crocodoc::API).to receive(:status).and_return [
        { "uuid" => "1234567890", "status" => "ERROR" }
      ]
      allow(Canvadocs).to receive(:enabled?).and_return true

      expects_job_with_tag("Attachment.submit_to_canvadocs") do
        CrocodocDocument.update_process_states
      end
    end
  end

  context "canvadocs" do
    before :once do
      course_model
      configure_canvadocs
    end

    before do
      allow_any_instance_of(Canvadocs::API).to receive(:upload).and_return "id" => 1234
    end

    it "treats text files equally" do
      a = attachment_model(content_type: "text/x-ruby-script")
      allow(Canvadoc).to receive(:mime_types).and_return(["text/plain"])
      expect(a.canvadocable?).to be_truthy
    end

    describe "submit_to_canvadocs" do
      it "submits canvadocable documents" do
        a = canvadocable_attachment_model
        a.submit_to_canvadocs
        expect(a.canvadoc.document_id).not_to be_nil
      end

      it "works from the bulk uploader" do
        a1 = canvadocable_attachment_model
        Attachment.submit_to_canvadocs([a1.id])
        expect(a1.canvadoc.document_id).not_to be_nil
      end

      it "doesn't submit non-canvadocable documents" do
        a = attachment_model
        a.submit_to_canvadocs
        expect(a.canvadoc).to be_nil
      end

      it "submits images when they are in the Student Annotation Documents folder" do
        att = attachment_model(
          context: @course,
          content_type: "image/jpeg",
          folder: @course.student_annotation_documents_folder
        )
        att.submit_to_canvadocs
        expect(att.canvadoc).not_to be_nil
      end

      it "does not submit images when they are not in the Student Annotation Documents folder" do
        att = attachment_model(context: @course, content_type: "image/jpeg")
        att.submit_to_canvadocs
        expect(att.canvadoc).to be_nil
      end

      it "tries again later when upload fails" do
        allow_any_instance_of(Canvadocs::API).to receive(:upload).and_return(nil)
        expects_job_with_tag("Attachment#submit_to_canvadocs") do
          canvadocable_attachment_model.submit_to_canvadocs
        end
      end

      it "sends annotatable documents to canvadocs if supported" do
        configure_crocodoc
        a = crocodocable_attachment_model
        a.submit_to_canvadocs 1, wants_annotation: true
        expect(a.canvadoc).not_to be_nil
      end

      it "prefers crocodoc when annotation is requested and canvadocs can't annotate" do
        configure_crocodoc
        configure_canvadocs "annotations_supported" => false
        stub_const("Canvadoc::DEFAULT_MIME_TYPES", (Canvadoc::DEFAULT_MIME_TYPES + ["application/blah"]))

        crocodocable = crocodocable_attachment_model
        canvadocable = canvadocable_attachment_model content_type: "application/blah"

        crocodocable.submit_to_canvadocs 1, wants_annotation: true
        run_jobs
        expect(crocodocable.canvadoc).to be_nil
        expect(crocodocable.crocodoc_document).not_to be_nil

        canvadocable.submit_to_canvadocs 1, wants_annotation: true
        expect(canvadocable.canvadoc).not_to be_nil
        expect(canvadocable.crocodoc_document).to be_nil
      end

      it "downgrades Canvadoc upload timeouts to WARN" do
        canvadocable = canvadocable_attachment_model content_type: "application/pdf"
        cd_double = double
        allow(canvadocable).to receive(:canvadoc).and_return(cd_double)
        expect(canvadocable.canvadoc).not_to be_nil
        expect(canvadocable.canvadoc).to receive(:upload).and_raise(Canvadoc::UploadTimeout, "test timeout")
        captured = false
        allow(Canvas::Errors).to receive(:capture) do |e, _error_data, error_level|
          if e.is_a?(Canvadoc::UploadTimeout)
            captured = true
            expect(error_level).to eq(:warn)
          end
        end
        canvadocable.submit_to_canvadocs 1
        expect(captured).to be_truthy
      end

      it "downgrades Canvadocs heavy load errors to WARN" do
        canvadocable = canvadocable_attachment_model content_type: "application/pdf"
        cd_double = double
        allow(canvadocable).to receive(:canvadoc).and_return(cd_double)
        expect(canvadocable.canvadoc).not_to be_nil
        expect(canvadocable.canvadoc).to receive(:upload).and_raise(Canvadocs::HeavyLoadError)
        captured = false
        allow(Canvas::Errors).to receive(:capture) do |e, _error_data, error_level|
          if e.is_a?(Canvadocs::HeavyLoadError)
            captured = true
            expect(error_level).to eq(:warn)
          end
        end
        canvadocable.submit_to_canvadocs 1
        expect(captured).to be_truthy
      end
    end
  end

  it "sets the uuid" do
    attachment_model
    expect(@attachment.uuid).not_to be_nil
  end

  context "workflow" do
    before :once do
      attachment_model
    end

    it "defaults to pending_upload" do
      expect(@attachment.state).to be(:pending_upload)
    end

    it "is able to take a processing object and complete its process" do
      attachment_model(workflow_state: "processing")
      @attachment.process!
      expect(@attachment.state).to be(:processed)
    end

    it "is able to take a new object and bypass upload with process" do
      @attachment.process!
      expect(@attachment.state).to be(:processed)
    end

    it "is able to recycle a processed object and re-upload it" do
      attachment_model(workflow_state: "processed")
      @attachment.recycle
      expect(@attachment.state).to be(:pending_upload)
    end
  end

  context "named scopes" do
    describe "uncategorized" do
      subject { Attachment.uncategorized }

      let!(:icon_maker) { attachment_model(category: Attachment::ICON_MAKER_ICONS) }
      let!(:uncategorized) { attachment_model }

      it { is_expected.to include uncategorized }
      it { is_expected.not_to include icon_maker }
    end

    describe "for_category" do
      subject { Attachment.for_category(category) }

      let_once(:icon_maker) { attachment_model(category: Attachment::ICON_MAKER_ICONS) }
      let_once(:uncategorized) { attachment_model }

      let(:category) { Attachment::ICON_MAKER_ICONS }

      before do
        icon_maker
        uncategorized
      end

      it { is_expected.to include icon_maker }
      it { is_expected.not_to include uncategorized }
    end

    context "by_content_types" do
      before :once do
        course_model
        @gif = attachment_model context: @course, content_type: "image/gif"
        @jpg = attachment_model context: @course, content_type: "image/jpeg"
        @weird = attachment_model context: @course, content_type: "%/what's this"
      end

      it "matches type" do
        expect(@course.attachments.by_content_types(["image"]).pluck(:id)).to match_array([@gif.id, @jpg.id])
      end

      it "matches type/subtype" do
        expect(@course.attachments.by_content_types(["image/gif"]).pluck(:id)).to eq [@gif.id]
        expect(@course.attachments.by_content_types(["image/gif", "image/jpeg"]).pluck(:id)).to match_array([@gif.id, @jpg.id])
      end

      it "escapes sql and wildcards" do
        expect(@course.attachments.by_content_types(["%"]).pluck(:id)).to eq [@weird.id]
        expect(@course.attachments.by_content_types(["%/what's this"]).pluck(:id)).to eq [@weird.id]
        expect(@course.attachments.by_content_types(["%/%"]).pluck(:id)).to eq []
      end

      it "finds tags without slashes" do
        video1 = attachment_model context: @course, content_type: "video"
        video2 = attachment_model context: @course, content_type: "video/mp4"
        expect(@course.attachments.by_content_types(["video"]).pluck(:id)).to match_array([video1.id, video2.id])
      end
    end

    context "by_exclude_content_types" do
      before :once do
        course_model
        @gif = attachment_model context: @course, content_type: "image/gif"
        @jpg = attachment_model context: @course, content_type: "image/jpeg"
        @txt = attachment_model context: @course, content_type: "text/plain"
        @pdf = attachment_model context: @course, content_type: "application/pdf"
      end

      it "matches type" do
        expect(@course.attachments.by_exclude_content_types(["image"]).pluck(:id)).to match_array([@txt.id, @pdf.id])
      end

      it "matches type/subtype" do
        expect(@course.attachments.by_exclude_content_types(["image/gif"]).pluck(:id)).to match_array([@jpg.id, @txt.id, @pdf.id])
        expect(@course.attachments.by_exclude_content_types(["image/gif", "image/jpeg"]).pluck(:id)).to match_array([@txt.id, @pdf.id])
      end

      it "escapes sql and wildcards" do
        @weird = attachment_model context: @course, content_type: "%/what's this"

        expect(@course.attachments.by_exclude_content_types(["%"]).pluck(:id)).to match_array([@gif.id, @jpg.id, @txt.id, @pdf.id])
        expect(@course.attachments.by_exclude_content_types(["%/what's this"]).pluck(:id)).to match_array([@gif.id, @jpg.id, @txt.id, @pdf.id])
        expect(@course.attachments.by_exclude_content_types(["%/%"]).pluck(:id)).to match_array([@gif.id, @jpg.id, @txt.id, @pdf.id, @weird.id])
      end

      it "finds tags without slashes" do
        attachment_model context: @course, content_type: "video"
        attachment_model context: @course, content_type: "video/mp4"
        expect(@course.attachments.by_exclude_content_types(["video"]).pluck(:id)).to match_array([@gif.id, @jpg.id, @txt.id, @pdf.id])
      end
    end
  end

  context "uploaded_data" do
    it "creates with uploaded_data" do
      a = attachment_model(uploaded_data: default_uploaded_data)
      expect(a.filename).to eql("doc.doc")
    end
  end

  context "ensure_media_object" do
    before :once do
      @course = course_factory
      @attachment = @course.attachments.build(filename: "foo.mp4")
      @attachment.content_type = "video"
    end

    it "is called automatically upon creation" do
      expect(@attachment).to receive(:ensure_media_object).once
      @attachment.save!
    end

    it "creates a media object for videos" do
      @attachment.update_attribute(:media_entry_id, "maybe")
      expect(@attachment).to receive(:build_media_object).once.and_return(true)
      @attachment.save!
    end

    it "delays the creation of the media object" do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)
      track_jobs do
        @attachment.save!
      end

      expect(MediaObject.count).to eq 0
      job = created_jobs.find { |j| j.tag == "MediaObject.add_media_files" }
      expect(job.tag).to eq "MediaObject.add_media_files"
      expect(job.run_at.to_i).to eq (now + 1.minute).to_i
    end

    it "does not create a media object in a skip_media_object_creation block" do
      Attachment.skip_media_object_creation do
        expect(@attachment).not_to receive(:build_media_object)
        @attachment.save!
      end
    end

    it "does not create a media object for images" do
      @attachment.filename = "foo.png"
      @attachment.content_type = "image/png"
      expect(@attachment).to receive(:ensure_media_object).once
      expect(@attachment).not_to receive(:build_media_object)
      @attachment.save!
    end

    it "creates a media object *after* a direct-to-s3 upload" do
      allowed = false
      expect(@attachment).to receive(:build_media_object) do
        raise "not allowed" unless allowed
      end
      @attachment.workflow_state = "unattached"
      @attachment.file_state = "deleted"
      @attachment.save!
      allowed = true
      @attachment.workflow_state = nil
      @attachment.file_state = "available"
      @attachment.save!
    end

    it "disassociates but not delete the associated media object" do
      @attachment.media_entry_id = "0_feedbeef"
      @attachment.save!

      media_object = @course.media_objects.build media_id: "0_feedbeef"
      media_object.attachment_id = @attachment.id
      media_object.save!

      @attachment.destroy

      media_object.reload
      expect(media_object).not_to be_deleted
      expect(media_object.attachment_id).to be_nil
    end
  end

  context "media_tracks_include_originals" do
    before :once do
      @course = course_factory
      teacher_in_course
      @media_object = media_object
      attachment_model(filename: "foo.mp4", content_type: "video", media_entry_id: @media_object.media_id)
    end

    it "returns original media object media tracks" do
      track = @media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher)
      expect(@attachment.media_tracks_include_originals).to include track
    end

    it "returns attachment media tracks if both attachment and media object have media tracks in the same locale" do
      en_track = @media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher)
      fr_track = @media_object.media_tracks.create!(kind: "subtitles", locale: "fr", content: "fr subs", user_id: @teacher)
      fra_track = @attachment.media_tracks.create!(kind: "subtitles", locale: "fr", content: "fr new", user_id: @teacher, media_object: @media_object)
      expect(@attachment.media_tracks_include_originals).to match [en_track, fra_track]
      expect(@attachment.media_tracks_include_originals).not_to include fr_track
    end

    it "differentiates between inherited and non-inherited tracks" do
      @media_object.media_tracks.create!(kind: "subtitles", locale: "en", content: "en subs", user_id: @teacher)
      @attachment.media_tracks.create!(kind: "subtitles", locale: "fr", content: "fr subs", user_id: @teacher, media_object: @media_object)
      expect(@attachment.media_tracks_include_originals.first.inherited).to be_truthy
      expect(@attachment.media_tracks_include_originals.last.inherited).to be_falsey
    end
  end

  context "destroy" do
    let(:a) { attachment_model(uploaded_data: default_uploaded_data) }

    it "does not actually destroy" do
      expect(a.filename).to eql("doc.doc")
      a.destroy
      expect(a).not_to be_frozen
      expect(a).to be_deleted
    end

    it "is probably not possible to actually destroy... somehow" do
      expect(a.filename).to eql("doc.doc")
      a.destroy
      expect(a).not_to be_frozen
      expect(a).to be_deleted
      a.destroy_permanently!
      expect(a).to be_frozen
    end

    it "does not show up in the context list after being destroyed" do
      @course = course_factory
      expect(@course).not_to be_nil
      expect(a.filename).to eql("doc.doc")
      expect(a.context).to eql(@course)
      a.destroy
      expect(a).not_to be_frozen
      expect(a).to be_deleted
      expect(@course.attachments).to include(a)
      expect(@course.attachments.active).not_to include(a)
    end

    it "still destroys without error if file data is lost" do
      allow(a).to receive(:downloadable?).and_return(false)
      a.destroy
      expect(a).to be_deleted
    end

    it "replaces uploaded data on destroy_content_and_replace" do
      expect(a.content_type).to eq "application/msword"
      a.destroy_content_and_replace
      expect(a.content_type).to eq "application/pdf"
    end

    it "also destroys thumbnails" do
      a = attachment_model(uploaded_data: stub_png_data, content_type: "image/png")
      thumb = a.thumbnail
      expect(thumb).not_to be_nil
      expect(thumb).to receive(:destroy).once
      a.destroy_content_and_replace
    end

    it "destroys content and record on destroy_permanently_plus" do
      a2 = attachment_model(root_attachment: a)
      expect(a).to receive(:make_childless).once
      expect(a).to receive(:destroy_content).once
      expect(a2).not_to receive(:make_childless)
      expect(a2).not_to receive(:destroy_content)
      a2.destroy_permanently_plus
      a.destroy_permanently_plus
      expect { a.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { a2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "does not delete s3objects if it is not production for destroy_content" do
      allow(ApplicationController).to receive(:test_cluster?).and_return(true)
      s3_storage!
      a = attachment_model
      allow(a).to receive(:s3object).and_return(double("s3object"))
      s3object = a.s3object
      expect(s3object).not_to receive(:delete)
      a.destroy_content
    end

    it "allows destroy_content_and_replace when s3object is already deleted" do
      s3_storage!
      a = attachment_model(uploaded_data: default_uploaded_data)
      a.s3object.delete
      a.destroy_content_and_replace
      expect(Purgatory.where(attachment_id: a.id).exists?).to be_truthy
    end

    it "does not do destroy_content_and_replace twice" do
      a.destroy_content_and_replace # works
      expect(a).not_to receive(:send_to_purgatory)
      a.destroy_content_and_replace # returns because it already happened
    end

    it "destroys all crocodocs even from children attachments" do
      local_storage!
      configure_crocodoc

      a = crocodocable_attachment_model(uploaded_data: default_uploaded_data)
      a2 = attachment_model(root_attachment: a)
      a2.submit_to_canvadocs 1, wants_annotation: true
      a.submit_to_canvadocs 1, wants_annotation: true
      run_jobs

      expect(a.crocodoc_document).not_to be_nil
      expect(a2.crocodoc_document).not_to be_nil
      a.destroy_content_and_replace
      expect(a.reload.crocodoc_document).to be_nil
      expect(a2.reload.crocodoc_document).to be_nil
    end

    it "allows destroy_content_and_replace on children attachments" do
      a2 = attachment_model(root_attachment: a)
      a2.destroy_content_and_replace
      purgatory = Purgatory.where(attachment_id: [a.id, a2.id])
      expect(purgatory.count).to eq 1
      expect(purgatory.take.attachment_id).to eq a.id
    end

    it "destroys all associated submission_draft_attachments on destroy" do
      submission = submission_model
      submission_draft = SubmissionDraft.create!(
        submission:,
        submission_attempt: submission.attempt
      )
      SubmissionDraftAttachment.create!(
        submission_draft:,
        attachment: a
      )
      a.destroy
      expect(a.submission_draft_attachments.count).to eq 0
    end

    it "does not destroy any submission_draft_attachments associated to other attachments on destroy" do
      a2 = attachment_model(uploaded_data: default_uploaded_data)
      submission = submission_model
      submission_draft = SubmissionDraft.create!(
        submission:,
        submission_attempt: submission.attempt
      )
      SubmissionDraftAttachment.create!(
        submission_draft:,
        attachment: a2
      )
      a.destroy
      expect(a2.submission_draft_attachments.count).to eq 1
    end

    it "removes avatars from the destroyed file" do
      user_model(avatar_image_url: a.public_url)
      a.update(context: @user)
      a.destroy
      expect(@user.reload.avatar_image_url).to be_nil
    end

    shared_examples_for "destroy_content_and_replace" do
      it "succeeds in destroying content and replacing after previous failure" do
        base_uuid = "base-id"
        a = attachment_model(uploaded_data: default_uploaded_data, instfs_uuid: "old-id")
        allow(InstFS).to receive(:duplicate_file)
        allow(Attachment).to receive(:file_removed_base_instfs_uuid).and_return(base_uuid)
        old_filename = a.filename
        allow(a).to receive(:destroy_content).and_raise
        a.destroy_content_and_replace rescue nil
        purgatory = Purgatory.find_by(attachment_id: a)
        expect(purgatory).not_to be_nil
        expect(a.reload.filename).to eq old_filename
        allow(a).to receive(:destroy_content).and_return(true)
        expect { a.destroy_content_and_replace }.not_to change { purgatory }
        expect(a.filename).to eq "file_removed.pdf"
        expect(a.display_name).to eq "file_removed.pdf"
      end
    end

    context "inst-fs" do
      before do
        allow(InstFS).to receive_messages(enabled?: true, app_host: "https://somehost.example")
        Attachment.class_variable_set :@@base_file_removed_uuids, nil if Attachment.class_variable_defined? :@@base_file_removed_uuids
      end

      include_examples "destroy_content_and_replace"

      it "only uploads the replacement file to inst-fs once" do
        instfs_uuid = "1234-abcd"
        expect(InstFS).to receive(:direct_upload)
          .with(hash_including(file_name: File.basename(Attachment.file_removed_path)))
          .and_return(instfs_uuid).exactly(1).times
        2.times do
          expect(Attachment.file_removed_base_instfs_uuid).to eq instfs_uuid
        end
      end

      it "sets the instfs_uuid to a duplicate of the replacement file" do
        base_uuid = "base-id"
        allow(Attachment).to receive(:file_removed_base_instfs_uuid).and_return(base_uuid)
        dup_uuid = "duplicate-id"
        expect(InstFS).to receive(:duplicate_file).with(base_uuid).and_return(dup_uuid)

        att = attachment_model(instfs_uuid: "old-id")
        expect(att).to receive(:send_to_purgatory) # stub these out for now - test separately
        expect(att).to receive(:destroy_content)
        att.destroy_content_and_replace
        expect(att.instfs_uuid).to eq dup_uuid
      end

      it "actually destroys the content" do
        uuid = "old-id"
        att = attachment_model(instfs_uuid: uuid)
        expect(InstFS).to receive(:delete_file).with(uuid)
        att.destroy_content
      end

      it "duplicates the file for purgatory and restores from there" do
        old_uuid = "old-id"
        att = attachment_model(instfs_uuid: old_uuid)

        purgatory_uuid = "purgatory-id"
        expect(InstFS).to receive(:duplicate_file).with(old_uuid).and_return(purgatory_uuid)
        purgatory = att.send_to_purgatory
        expect(purgatory.new_instfs_uuid).to eq purgatory_uuid
        att.resurrect_from_purgatory
        expect(att.instfs_uuid).to eq purgatory_uuid
      end
    end

    shared_examples_for "purgatory" do
      it "saves file in purgatory and then restore and back again" do
        a = attachment_model(uploaded_data: default_uploaded_data)
        old_filename = a.filename
        old_content_type = a.content_type
        old_file_state = a.file_state
        old_workflow_state = a.workflow_state
        a.destroy_content_and_replace
        purgatory = Purgatory.where(attachment_id: a).take
        expect(purgatory.old_filename).to eq old_filename
        expect(purgatory.old_display_name).to eq old_filename
        expect(purgatory.old_content_type).to eq old_content_type
        expect(purgatory.old_file_state).to eq old_file_state
        expect(purgatory.old_workflow_state).to eq old_workflow_state
        a.reload
        expect(a.filename).to eq "file_removed.pdf"
        expect(a.display_name).to eq "file_removed.pdf"
        a.resurrect_from_purgatory
        a.reload
        expect(a.filename).to eq old_filename
        expect(a.display_name).to eq old_filename
        expect(a.content_type).to eq old_content_type
        expect(a.file_state).to eq old_file_state
        expect(a.workflow_state).to eq old_workflow_state
        expect(purgatory.reload.workflow_state).to eq "restored"
        a.destroy_content_and_replace
        expect(purgatory.reload.workflow_state).to eq "active"
      end
    end

    context "s3 storage" do
      include_examples "purgatory"
      include_examples "destroy_content_and_replace"
      before { s3_storage! }
    end

    context "local storage" do
      include_examples "purgatory"
      include_examples "destroy_content_and_replace"
      before { local_storage! }
    end
  end

  context "restore" do
    it "restores to 'available' state" do
      a = attachment_model(uploaded_data: default_uploaded_data)
      a.destroy
      expect(a).to be_deleted
      a.restore
      expect(a).to be_available
    end

    it "restores deleted parent folders" do
      course_factory
      parent_folder = folder_model
      child_folder = folder_model(parent_folder_id: parent_folder.id)
      attachment = attachment_model(folder: child_folder)
      parent_folder.destroy

      child_folder.reload
      attachment.reload

      attachment.restore
      child_folder.reload
      parent_folder.reload

      expect(attachment).to be_available
      expect(child_folder.workflow_state).to eq "visible"
      expect(parent_folder.workflow_state).to eq "visible"
    end
  end

  context "destroy_permanently!" do
    it "does not delete the s3 object, even here" do
      s3_storage!
      a = attachment_model
      s3object = a.s3object
      expect(s3object).not_to receive(:delete)
      a.destroy_permanently!
    end
  end

  context "inferred display name" do
    before do
      s3_storage! # because we don't 'sanitize' filenames with the local backend
    end

    it "takes a normal filename and use it as a diplay name" do
      a = attachment_model(filename: "normal_name.ppt")
      expect(a.display_name).to eql("normal_name.ppt")
      expect(a.filename).to eql("normal_name.ppt")
    end

    it "preserves case" do
      a = attachment_model(filename: "Normal_naMe.ppt")
      expect(a.display_name).to eql("Normal_naMe.ppt")
      expect(a.filename).to eql("Normal_naMe.ppt")
    end

    it "truncates filenames to 255 characters (preserving extension)" do
      a = attachment_model(filename: "My new study guide or case study on this evolution on monkeys even in that land of costa rica somewhere my own point of  view going along with the field experiment I would say or try out is to put them not in wet areas like costa rico but try and put it so its not so long.docx")
      expect(a.display_name).to eql("My new study guide or case study on this evolution on monkeys even in that land of costa rica somewhere my own point of  view going along with the field experiment I would say or try out is to put them not in wet areas like costa rico but try and put.docx")
      expect(a.filename).to eql("My+new+study+guide+or+case+study+on+this+evolution+on+monkeys+even+in+that+land+of+costa+rica+somewhere+my+own+point+of++view+going+along+with+the+field+experiment+I+would+say+or+try+out+is+to+put+them+not+in+wet+areas+like+costa+rico+but+try+and+put.docx")
    end

    it "uses no more than half of the 255 characters for the extension" do
      a = attachment_model(filename: ("A" * 150) + "." + ("B" * 150))
      expect(a.display_name).to eql(("A" * 127) + "." + ("B" * 127))
      expect(a.filename).to eql(("A" * 127) + "." + ("B" * 127))
    end

    it "does not split unicode characters when truncating" do
      a = attachment_model(filename: "\u2603" * 300)
      expect(a.display_name).to eql("\u2603" * 255)
      expect(a.filename.length).to be(252)
      expect(a.unencoded_filename).to be_valid_encoding
      expect(a.unencoded_filename).to eql("\u2603" * 28)
    end

    it "truncates thumbnail names" do
      a = attachment_model(filename: "#{"a" * 251}.png")
      thumbname = a.thumbnail_name_for("thumb")
      expect(thumbname.length).to eq 255
      expect(thumbname).to eq "#{"a" * 245}_thumb.png"
    end

    it "does not double-escape a root attachment's filename" do
      a = attachment_model(filename: "something with spaces.txt")
      expect(a.filename).to eq "something+with+spaces.txt"
      a2 = Attachment.new
      a2.root_attachment = a
      expect(a2.sanitize_filename(nil)).to eq a.filename
    end
  end

  context "explicitly-set display name" do
    it "truncates to 1000 characters" do
      a = attachment_model(filename: "HE COMES", display_name: "#{"A" * 1000}.docx")
      expect(a.display_name).to eq "#{"A" * 995}.docx"
    end
  end

  context "clone_for" do
    context "with S3 storage enabled" do
      subject { attachment.clone_for(context, nil, { force_copy: true }) }

      let(:bank) { AssessmentQuestionBank.create!(context: course_model) }
      let(:context) { AssessmentQuestion.create!(assessment_question_bank: bank) }
      let(:attachment) { attachment_model(filename: "blech.ppt", context: bank.context) }

      before { s3_storage! }

      context "and the context has a nil root account" do
        before { context.update_columns(root_account_id: nil) }

        it "does not raise an error" do
          expect { subject }.not_to raise_exception
        end
      end

      context "across shards" do
        specs_require_sharding

        let(:shard1_account) { @shard1.activate { account_model } }

        it "duplicates the file via S3" do
          expect_any_instance_of(Aws::S3::Object).to receive(:copy_to).once
          att = attachment_model(context: Account.default)
          dup = nil
          @shard1.activate do
            dup = Attachment.new
            expect(dup).to receive(:s3object).at_least(:once).and_return(double("Aws::S3::Object", exists?: false))
            att.clone_for(shard1_account, dup)
          end
          expect(dup.content_type).to eq att.content_type
          expect(dup.size).to eq att.size
          expect(dup.md5).to eq att.md5
          expect(dup.workflow_state).to eq "processed"
        end
      end
    end

    context "with instfs enabled" do
      specs_require_sharding

      before do
        allow(InstFS).to receive(:enabled?).and_return(true)

        attachment_model(filename: "blech.ppt", instfs_uuid: "instfs_uuid")
      end

      it "creates an attachment with workflow_state of processed" do
        expect(InstFS).to receive(:duplicate_file).with("instfs_uuid").and_return("more_uuid")
        @shard1.activate do
          account_model
          course_model(account: @account)
          attachment = @attachment.clone_for(@course, nil, { force_copy: true })
          attachment.save!
          expect(attachment.workflow_state).to eq "processed"
          expect(attachment.instfs_uuid).to eq "more_uuid"
        end
      end
    end

    it "clones to another context" do
      a = attachment_model(filename: "blech.ppt")
      course_factory
      new_a = a.clone_for(@course)
      expect(new_a.context).not_to eql(a.context)
      expect(new_a.filename).to eql(a.filename)
      expect(new_a.read_attribute(:filename)).to be_nil
      expect(new_a.root_attachment_id).to eql(a.id)
    end

    it "clones to another root_account" do
      c = course_factory
      a = attachment_model(filename: "blech.ppt", context: c)
      new_account = Account.create
      c2 = course_factory(account: new_account)
      allow(Attachment).to receive(:s3_storage?).and_return(true)
      expect_any_instance_of(Attachment).to receive(:make_rootless).once
      expect_any_instance_of(Attachment).to receive(:change_namespace).once
      a.clone_for(c2)
    end

    it "creates thumbnails for images on clone" do
      c = course_factory
      a = attachment_model(filename: "blech.jpg", context: c, content_type: "image/jpg")
      new_account = Account.create
      c2 = course_factory(account: new_account)
      s3_storage!
      expect_any_instance_of(Attachment).to receive(:copy_attachment_content).once.and_call_original
      expect_any_instance_of(Attachment).to receive(:change_namespace).once
      expect_any_instance_of(Attachment).to receive(:create_thumbnail_size).once
      a.clone_for(c2)
    end

    it "links the thumbnail" do
      a = attachment_model(uploaded_data: stub_png_data, content_type: "image/png")
      expect(a.thumbnail).not_to be_nil
      course_factory
      new_a = a.clone_for(@course)
      expect(new_a.thumbnail).not_to be_nil
      expect(new_a.thumbnail_url).not_to be_nil
      expect(new_a.thumbnail_url).to eq a.thumbnail_url
    end

    it "does not create root_attachment_id cycles or self-references" do
      a = attachment_model(uploaded_data: stub_png_data, content_type: "image/png")
      expect(a.root_attachment_id).to be_nil
      coursea = @course
      @context = courseb = course_factory
      b = a.clone_for(courseb, nil, overwrite: true)
      b.save
      expect(b.context).to eq courseb
      expect(b.root_attachment).to eq a

      new_a = b.clone_for(coursea, nil, overwrite: true)
      expect(new_a).to eq a
      expect(new_a.root_attachment_id).to be_nil

      new_b = new_a.clone_for(courseb, nil, overwrite: true)
      expect(new_b.root_attachment_id).to eq a.id

      new_b = b.clone_for(courseb, nil, overwrite: true)
      expect(new_b.root_attachment_id).to eq a.id

      @context = coursec = course_factory
      c = b.clone_for(coursec, nil, overwrite: true)
      expect(c.root_attachment).to eq a

      new_a = c.clone_for(coursea, nil, overwrite: true)
      expect(new_a).to eq a
      expect(new_a.root_attachment_id).to be_nil

      # pretend b's content changed so it got disconnected
      b.update_attribute(:root_attachment_id, nil)
      new_b = b.clone_for(courseb, nil, overwrite: true)
      expect(new_b.root_attachment_id).to be_nil
    end

    it "sets correct namespace across clones" do
      s3_storage!
      a = attachment_model
      expect(a.root_attachment_id).to be_nil
      coursea = @course
      @context = courseb = course_factory(account: Account.create)

      b = a.clone_for(courseb, nil, overwrite: true)
      expect(b.id).not_to be_nil
      expect(b.filename).to eq a.filename
      b.save
      expect(b.root_attachment_id).to be_nil
      expect(b.namespace).to eq courseb.root_account.file_namespace

      new_a = b.clone_for(coursea, nil, overwrite: true)
      new_a.save
      expect(new_a).to eq a
      expect(new_a.namespace).to eq coursea.root_account.file_namespace
    end
  end

  describe "computed_visibility_level" do
    let_once(:user) { user_model }
    let_once(:course) do
      course_model
      @course.offer
      @course.update_attribute(:is_public, false)
      @course
    end
    let_once(:student) do
      course.enroll_student(user_model).accept
      @user
    end
    let_once(:attachment) do
      attachment_model(context: course)
    end

    it "always returns 'context' if the Course is not published" do
      course.claim
      expect(attachment.computed_visibility_level).to eq("context")
      attachment.update!(visibility_level: "public")
      expect(attachment.computed_visibility_level).to eq("context")
    end

    it "returns the Course setting if 'inherit'" do
      attachment.update(visibility_level: "inherit")

      course.apply_custom_visibility_configuration("files", "course")
      course.save!
      expect(attachment.computed_visibility_level).to eq("context")

      course.apply_custom_visibility_configuration("files", "institution")
      course.save!
      attachment.reload
      expect(attachment.computed_visibility_level).to eq("institution")

      course.apply_custom_visibility_configuration("files", "public")
      course.save!
      attachment.reload
      expect(attachment.computed_visibility_level).to eq("public")
    end
  end

  context "adheres_to_policy" do
    let_once(:user) { user_model }
    let_once(:course) do
      course_model
      @course.offer
      @course.update_attribute(:is_public, false)
      @course
    end
    let_once(:student) do
      course.enroll_student(user_model).accept
      @user
    end
    let_once(:attachment) do
      attachment_model(context: course)
    end

    it "does not allow unauthorized users to read files" do
      a = attachment_model(context: course_model, visibility_level: "context")
      @course.update_attribute(:is_public, false)
      expect(a.grants_right?(user, :read)).to be(false)
    end

    it "disallows anonymous access for unpublished public contexts" do
      a = attachment_model(context: course_model, visibility_level: "public")
      expect(a.grants_right?(user, :read)).to be(false)
    end

    it "allows anonymous access for public contexts" do
      a = attachment_model(context: course_model, visibility_level: "public")
      @course.offer
      expect(a.grants_right?(user, :read)).to be(true)
    end

    it "allows students to read files" do
      a = attachment
      a.reload
      expect(a.grants_right?(student, :read)).to be(true)
    end

    it "allows students to download files" do
      a = attachment
      a.reload
      expect(a.grants_right?(student, :download)).to be(true)
    end

    it "allows students to read (but not download) locked files" do
      a = attachment
      a.update_attribute(:locked, true)
      a.reload
      expect(a.grants_right?(student, :read)).to be(true)
      expect(a.grants_right?(student, :download)).to be(false)
    end

    it "allows user access based on 'file_access_user_id' and 'file_access_expiration' in the session" do
      a = attachment
      expect(a.grants_right?(nil, :read)).to be(false)
      expect(a.grants_right?(nil, :download)).to be(false)
      mock_session = ActionController::TestSession.new({
                                                         "file_access_user_id" => student.id,
                                                         "file_access_expiration" => 1.hour.from_now.to_i,
                                                         "permissions_key" => SecureRandom.uuid
                                                       })
      expect(a.grants_right?(nil, mock_session, :read)).to be(true)
      expect(a.grants_right?(nil, mock_session, :download)).to be(true)
    end

    it "denies user access based on 'file_access_user_id' correctly" do
      a = attachment_model(context: user)
      other_user = user_model
      mock_session = ActionController::TestSession.new({
                                                         "file_access_user_id" => other_user.id,
                                                         "file_access_expiration" => 1.hour.from_now.to_i,
                                                         "permissions_key" => SecureRandom.uuid
                                                       })
      expect(a.grants_right?(nil, mock_session, :read)).to be(false)
      expect(a.grants_right?(nil, mock_session, :download)).to be(false)
    end

    it "allows user access to anyone if the course is public to auth users (with 'file_access_user_id' and 'file_access_expiration' in the session)" do
      mock_session = ActionController::TestSession.new({
                                                         "file_access_user_id" => user.id,
                                                         "file_access_expiration" => 1.hour.from_now.to_i,
                                                         "permissions_key" => SecureRandom.uuid
                                                       })

      a = attachment_model(context: course)
      expect(a.grants_right?(nil, mock_session, :read)).to be(false)
      expect(a.grants_right?(nil, mock_session, :download)).to be(false)

      course.is_public_to_auth_users = true
      course.save!
      a.reload
      AdheresToPolicy::Cache.clear

      expect(a.grants_right?(nil, :read)).to be(false)
      expect(a.grants_right?(nil, :download)).to be(false)
      expect(a.grants_right?(nil, mock_session, :read)).to be(true)
      expect(a.grants_right?(nil, mock_session, :download)).to be(true)
    end

    it "does not allow user access based on incorrect 'file_access_user_id' in the session" do
      a = attachment
      expect(a.grants_right?(nil, :read)).to be(false)
      expect(a.grants_right?(nil, :download)).to be(false)
      expect(a.grants_right?(nil, ActionController::TestSession.new({ "file_access_user_id" => 0, "file_access_expiration" => 1.hour.from_now.to_i }), :read)).to be(false)
    end

    it "does not allow user access based on incorrect 'file_access_expiration' in the session" do
      a = attachment
      expect(a.grants_right?(nil, :read)).to be(false)
      expect(a.grants_right?(nil, :download)).to be(false)
      expect(a.grants_right?(nil, ActionController::TestSession.new({ "file_access_user_id" => student.id, "file_access_expiration" => 1.minute.ago.to_i }), :read)).to be(false)
    end

    it "allows students to download a file on an assessment question if it's part of a quiz they can read" do
      @bank = @course.assessment_question_banks.create!(title: "bank")
      @a1 = attachment_with_context(@course, display_name: "a1")
      @a2 = attachment_with_context(@course, display_name: "a2")

      data1 = { "name" => "Hi", "question_text" => "hey look <img src='/courses/#{@course.id}/files/#{@a1.id}/download'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
      @aquestion1 = @bank.assessment_questions.create!(question_data: data1)
      aq_att1 = @aquestion1.attachments.first
      data2 = { "name" => "Hi", "question_text" => "hey look <img src='/courses/#{@course.id}/files/#{@a2.id}/download'>", "answers" => [{ "id" => 1 }, { "id" => 2 }] }
      @aquestion2 = @bank.assessment_questions.create!(question_data: data2)
      aq_att2 = @aquestion2.attachments.first

      quiz = @course.quizzes.create!
      AssessmentQuestion.find_or_create_quiz_questions([@aquestion1], quiz.id, nil)
      quiz.publish!
      expect(aq_att1.grants_right?(student, :download)).to be true
      expect(aq_att2.grants_right?(student, :download)).to be false
    end

    context "attachments with assignment context" do
      before :once do
        assignment_model(course: @course, submission_types: "online_upload")
        @submission = @assignment.submit_homework(student, attachments: [attachment_model(context: student)])
        @course.enroll_student(user_model).accept
        @student2 = @user
        @course.enroll_teacher(user_model).accept
        @teacher = @user
      end

      it "only allows graders to access the 'download all submissions' zip file on an assignment" do
        attachment = SubmissionsController.new.submission_zip(@assignment)
        expect(attachment.grants_right?(@teacher, :download)).to be true
        expect(attachment.grants_right?(student, :download)).to be false
      end

      it "allows graders to access attachments from students on submission comments" do
        @submission.add_comment(author: student, comment: "comment", attachments: [attachment_model(context: @assignment)])
        expect(@attachment.grants_right?(@teacher, :download)).to be true
      end

      it "allows students access to files they just created" do
        attachment_model(context: @assignment, user: student)
        expect(@attachment.grants_right?(student, :download)).to be true
      end

      it "allows students to access attachments on submission comments associated to their submissions" do
        @submission.add_comment(author: @teacher, comment: "comment", attachments: [attachment_model(context: @assignment)])
        expect(@attachment.grants_right?(student, :download)).to be true

        @submission.add_comment(author: student, comment: "comment", attachments: [attachment_model(context: @assignment)])
        expect(@attachment.grants_right?(student, :download)).to be true
      end

      it "does not allow students to access attachments on submission comments for other's submissions" do
        @submission.add_comment(author: @teacher, comment: "comment", attachments: [attachment_model(context: @assignment)])
        expect(@attachment.grants_right?(@student2, :download)).to be false

        @submission.add_comment(author: student, comment: "comment", attachments: [attachment_model(context: @assignment)])
        expect(@attachment.grants_right?(@student2, :download)).to be false
      end

      it "allows students to access attachments on submissions" do
        attachment_model(context: @assignment)
        @assignment.submit_homework(student, attachments: [@attachment])

        expect(@attachment.grants_right?(student, :download)).to be true
      end

      it "doesn't crash when there is no user" do
        attachment_model(context: @assignment)
        @assignment.submit_homework(student, attachments: [@attachment])

        expect(@attachment.grants_right?(nil, :download)).to be false
      end

      it "does not allow users to access attachments for deleted submissions" do
        attachment_model(context: @assignment)
        submission = @assignment.submit_homework(student, attachments: [@attachment])
        submission.destroy

        expect(@attachment.grants_right?(student, :download)).to be false
      end

      it "does not allow users to access attachments for deleted submission comments" do
        attachment1 = attachment_model(context: @assignment)
        attachment2 = attachment_model(context: @assignment)
        comment1 = @submission.add_comment(author: @user, comment: "comment", attachments: [attachment1])
        comment2 = @submission.add_comment(author: student, comment: "comment", attachments: [attachment2])
        comment1.destroy
        comment2.destroy

        expect(attachment1.grants_right?(student, :download)).to be false
        expect(attachment2.grants_right?(student, :download)).to be false
      end

      context "submission attachments with an attachment context (LTI submissions?)" do
        before :once do
          @submission = @assignment.submit_homework(student, attachments: [attachment_model(context: @assignment)])
        end

        it "allows graders to access attachments for submissions on an assignment" do
          expect(@attachment.grants_right?(@teacher, :download)).to be true
        end

        it "allows students to access submission attachments for their submissions" do
          expect(@attachment.grants_right?(student, :download)).to be true
        end

        it "does not allow students to access submission attachments for other's submissions" do
          expect(@attachment.grants_right?(@student2, :download)).to be false
        end
      end
    end

    context "attachments with quiz context" do
      before :once do
        quiz_with_submission(true)
        @course.enroll_teacher(user_model).accept
        @teacher = @user
      end

      it "only allows graders to access the 'download all submissions' zip file on an assignment" do
        attachment = SubmissionsController.new.submission_zip(@quiz)
        expect(attachment.grants_right?(@teacher, :download)).to be true
        expect(attachment.grants_right?(@student, :download)).to be false
      end
    end

    context "group assignment" do
      before :once do
        group_category = @course.group_categories.create!(name: "Group Category")
        group_1 = group_model(context: @course, group_category:)
        group_2 = group_model(context: @course, group_category:)

        @user_1 = user_model
        @user_2 = user_model
        @user_3 = user_model
        @user_4 = user_model

        course.enroll_student(@user_1).accept
        course.enroll_student(@user_2).accept
        course.enroll_student(@user_3).accept
        course.enroll_student(@user_4).accept

        group_1.add_user(@user_1)
        group_1.add_user(@user_2)

        group_2.add_user(@user_3)
        group_2.add_user(@user_4)

        assignment = assignment_model(course: @course, submission_types: "online_upload")
        assignment.group_category = group_category
        assignment.save!

        @attachment = attachment_model(context: @user_1)

        submission_1 = assignment.find_or_create_submission(@user_1)
        submission_2 = assignment.find_or_create_submission(@user_2)

        @attachment.attachment_associations.create!(context: submission_1)
        @attachment.attachment_associations.create!(context: submission_2)
      end

      it "does allow read attachments for users in the same group" do
        expect(@attachment.grants_right?(@user_1, :read)).to be(true)
        expect(@attachment.grants_right?(@user_2, :read)).to be(true)
      end

      it "does not allow read attachments for users in another group" do
        expect(@attachment.grants_right?(@user_3, :read)).to be(false)
        expect(@attachment.grants_right?(@user_4, :read)).to be(false)
      end
    end
  end

  context "duplicate handling" do
    before :once do
      course_model
      @a1 = attachment_with_context(@course, display_name: "a1")
      @a2 = attachment_with_context(@course, display_name: "a2")
      @a = attachment_with_context(@course)
    end

    it "returns replaced attachments when using the replaced_attachments association" do
      @a.display_name = "a1"
      @a.handle_duplicates(:overwrite)
      expect(@a.replaced_attachments).to include @a1
    end

    it "excludes not-replaced attachments when using the replaced_attachments association" do
      @a.display_name = "a1 fancy name"
      @a.handle_duplicates(:overwrite)
      expect(@a.replaced_attachments).not_to include @a1
    end

    it "handles overwriting duplicates" do
      @a.display_name = "a1"
      deleted = @a.handle_duplicates(:overwrite)
      expect(@a.file_state).to eq "available"
      @a1.reload
      expect(@a1.file_state).to eq "deleted"
      expect(@a1.replacement_attachment).to eql @a
      expect(deleted).to eq [@a1]
    end

    it "updates replacement pointers to replaced files" do
      @a.update_attribute(:display_name, "a1")
      @a.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql @a
      again = attachment_with_context(@course, display_name: "a1")
      again.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql again
    end

    it "updates replacement pointers to replaced-then-renamed files" do
      @a.update_attribute(:display_name, "a1")
      @a.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql @a
      @a.update_attribute(:display_name, "renamed")
      again = attachment_with_context(@course, display_name: "renamed")
      again.handle_duplicates(:overwrite)
      expect(@a1.reload.replacement_attachment).to eql again
    end

    it "handles renaming duplicates" do
      @a.display_name = "a1"
      deleted = @a.handle_duplicates(:rename)
      expect(deleted).to be_empty
      expect(@a.file_state).to eq "available"
      @a1.reload
      expect(@a1.file_state).to eq "available"
      expect(@a.display_name).to eq "a1-1"
    end

    it "rename itself after collision on restoration" do
      @a1.destroy!
      @a.display_name = @a1.display_name
      @a.save!
      @a1.restore
      expect(@a1.reload.display_name).to eq "#{@a.display_name}-1"
    end

    it "updates ContentTags when overwriting" do
      mod = @course.context_modules.create!(name: "some module")
      tag1 = mod.add_item(id: @a1.id, type: "attachment")
      tag2 = mod.add_item(id: @a2.id, type: "attachment")
      mod.save!

      @a1.reload
      expect(@a1.could_be_locked).to be_truthy

      @a.display_name = "a1"
      @a.handle_duplicates(:overwrite)
      tag1.reload
      expect(tag1).to be_active
      expect(tag1.content_id).to eq @a.id

      @a.reload
      expect(@a.could_be_locked).to be_truthy

      tag2.update! workflow_state: "unpublished"
      @a2.destroy
      tag2.reload
      expect(tag2).to be_deleted
    end

    it "destroys all associated submission_draft_attachments when overwriting" do
      @a1.update_attribute(:display_name, "a2")
      submission = submission_model
      submission_draft = SubmissionDraft.create!(
        submission:,
        submission_attempt: submission.attempt
      )
      SubmissionDraftAttachment.create!(
        submission_draft:,
        attachment: @a1
      )

      @a2.handle_duplicates(:overwrite)
      @a1.reload
      expect(@a1.submission_draft_attachments.count).to eq 0
    end

    it "does not destroy any submission_draft_attachments associated to other attachments when overwriting" do
      @a1.update_attribute(:display_name, "a2")
      submission = submission_model
      submission_draft = SubmissionDraft.create!(
        submission:,
        submission_attempt: submission.attempt
      )
      SubmissionDraftAttachment.create!(
        submission_draft:,
        attachment: @a2
      )

      @a2.handle_duplicates(:overwrite)
      @a1.reload
      expect(@a2.submission_draft_attachments.count).to eq 1
    end

    it "finds replacement file by id if name changes" do
      @a.display_name = "a1"
      @a.handle_duplicates(:overwrite)
      @a.display_name = "renamed!!"
      @a.save!
      expect(@course.attachments.find(@a1.id)).to eql @a
    end

    it "finds replacement file by name if id isn't present" do
      @a.display_name = "a1"
      @a.handle_duplicates(:overwrite)
      @a1.update_attribute(:replacement_attachment_id, nil)
      expect(@course.attachments.find(@a1.id)).to eql @a
    end

    it "preserves hidden state" do
      @a1.update_attribute(:file_state, "hidden")
      @a.update_attribute(:display_name, "a1")
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.file_state).to eq "hidden"
    end

    it "preserves unpublished state" do
      @a1.update_attribute(:locked, true)
      @a.update_attribute(:display_name, "a1")
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.locked).to be true
    end

    it "preserves lock dates" do
      @a1.unlock_at = Date.new(2016, 1, 1)
      @a1.lock_at = Date.new(2016, 4, 1)
      @a1.save!
      @a.update_attribute(:display_name, "a1")
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.unlock_at).to eq @a1.reload.unlock_at
      expect(@a.lock_at).to eq @a1.lock_at
    end

    it "preserves usage rights" do
      usage_rights = @course.usage_rights.create! use_justification: "creative_commons", legal_copyright: "(C) 2014 XYZ Corp", license: "cc_by_nd"
      @a1.usage_rights = usage_rights
      @a1.save!
      @a.update_attribute(:display_name, "a1")
      @a.handle_duplicates(:overwrite)
      expect(@a.reload.usage_rights).to eq usage_rights
    end

    it "forces rename semantics in submissions folders" do
      user_model
      attachment_model context: @user, folder: @user.submissions_folder, filename: "a1.txt"
      a2 = attachment_model context: @user, folder: @user.submissions_folder, filename: "a2.txt"
      a2.display_name = "a1.txt"
      deleted = a2.handle_duplicates(:overwrite)
      expect(deleted).to be_empty
      a2.reload
      expect(a2.display_name).not_to eq "a1.txt"
      expect(a2.display_name).not_to eq "a2.txt"
    end

    context "sharding" do
      specs_require_sharding

      it "forms proper queries when run from a different shard" do
        @shard1.activate do
          @a.display_name = "a1"
          deleted = @a.handle_duplicates(:overwrite)
          expect(@a.file_state).to eq "available"
          @a1.reload
          expect(@a1.file_state).to eq "deleted"
          expect(@a1.replacement_attachment).to eql @a
          expect(deleted).to eq [@a1]
        end
      end

      it "can still rename when folder lives on a different shard" do
        @shard1.activate do
          shard_attachment_1 = attachment_with_context(@course, display_name: "old_name_1")
          shard_attachment_2 = attachment_with_context(@course, display_name: "old_name_2")
          folder = shard_attachment_1.folder
          expect(folder.shard.id).to_not eq(shard_attachment_1.shard.id)
          shard_attachment_1.display_name = "old_name_2"
          deleted = shard_attachment_1.handle_duplicates(:rename)
          expect(deleted).to be_empty
          shard_attachment_1.reload
          shard_attachment_2.reload
          expect(shard_attachment_1.file_state).to eq "available"
          expect(shard_attachment_2.file_state).to eq "available"
          expect(shard_attachment_2.display_name).to_not eq(shard_attachment_1.display_name)
          expect(shard_attachment_2.display_name).to eq "old_name_2"
          expect(shard_attachment_1.display_name).to eq "old_name_2-2"
        end
      end
    end
  end

  describe "make_unique_filename" do
    it "finds a unique name for files" do
      existing_files = %w[a.txt b.txt c.txt]
      expect(Attachment.make_unique_filename("d.txt", existing_files)).to eq "d.txt"
      expect(existing_files).not_to include(Attachment.make_unique_filename("b.txt", existing_files))

      existing_files = %w[/a/b/a.txt /a/b/b.txt /a/b/c.txt]
      expect(Attachment.make_unique_filename("/a/b/d.txt", existing_files)).to eq "/a/b/d.txt"
      new_name = Attachment.make_unique_filename("/a/b/b.txt", existing_files)
      expect(existing_files).not_to include(new_name)
      expect(new_name).to match(%r{^/a/b/b[^.]+\.txt})
    end

    it "deals with missing extensions" do
      expect(Attachment.make_unique_filename("blah", ["blah"])).to eq "blah-1"
    end

    it "puts the uniquifier before double extensions" do
      expect(Attachment.make_unique_filename("blah.tar.bz2", ["blah.tar.bz2"])).to eq "blah-1.tar.bz2"
    end

    it "deals with extensions starting with a digit" do
      expect(Attachment.make_unique_filename("blah.3dm", ["blah.3dm"])).to eq "blah-1.3dm"
    end

    it "does not treat numbers after a decimal point as extensions" do
      expect(Attachment.make_unique_filename("section 11.5.doc", ["section 11.5.doc"])).to eq "section 11.5-1.doc"
      expect(Attachment.make_unique_filename("3.3.2018 footage.mp4", ["3.3.2018 footage.mp4"])).to eq "3.3.2018 footage-1.mp4"
    end
  end

  context "download/inline urls" do
    subject { attachment.public_download_url }

    before :once do
      course_model
    end

    context "when the attachment context is a ContentExport" do
      let(:attachment) do
        content_export = ContentExport.new(id: 1)
        Attachment.new(
          id: 1,
          context: content_export,
          display_name: "attachment",
          uuid: SecureRandom.uuid
        )
      end

      it { is_expected.to eq "http://localhost/files/#{attachment.id}/download?verifier=#{attachment.uuid}" }
    end

    context "when the attachment context is not a ContentExport" do
      let(:attachment) do
        Attachment.new(
          id: 1,
          context: @course,
          display_name: "attachment",
          uuid: SecureRandom.uuid
        )
      end

      it { is_expected.to eq "http://localhost/courses/#{@course.id}/files/#{attachment.id}/download?verifier=#{attachment.uuid}" }
    end

    it "works with s3 storage" do
      s3_storage!
      attachment = attachment_with_context(@course, display_name: "foo")
      expect(attachment.public_download_url).to match(/response-content-disposition=attachment/)
      expect(attachment.public_inline_url).to match(/response-content-disposition=inline/)
    end

    it "allows custom ttl for download_url" do
      attachment = attachment_with_context(@course, display_name: "foo")
      allow(attachment).to receive(:public_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:public_url).with(include(expires_in: 1.day))
      attachment.public_download_url
      expect(attachment).to receive(:public_url).with(include(expires_in: 2.days))
      attachment.public_download_url(2.days)
    end

    it "allows custom ttl for root_account" do
      attachment = attachment_with_context(@course, display_name: "foo")
      root = @course.root_account
      root.settings[:s3_url_ttl_seconds] = 3.days.seconds.to_s
      root.save!
      expect(attachment).to receive(:public_url).with(include(expires_in: 3.days.to_i.seconds))
      attachment.public_download_url
    end

    it "includes response-content-disposition" do
      attachment = attachment_with_context(@course, display_name: "foo")
      allow(attachment).to receive(:authenticated_s3_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:authenticated_s3_url).with(include(response_content_disposition: %(attachment; filename="foo"; filename*=UTF-8''foo)))
      attachment.public_download_url
      expect(attachment).to receive(:authenticated_s3_url).with(include(response_content_disposition: %(inline; filename="foo"; filename*=UTF-8''foo)))
      attachment.public_inline_url
    end

    it "uses the display_name, not filename, in the response-content-disposition" do
      attachment = attachment_with_context(@course, filename: "bar", display_name: "foo")
      allow(attachment).to receive(:authenticated_s3_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:authenticated_s3_url).with(include(response_content_disposition: %(attachment; filename="foo"; filename*=UTF-8''foo)))
      attachment.public_download_url
    end

    it "https quote the filename in the response-content-disposition if necessary" do
      attachment = attachment_with_context(@course, display_name: 'fo"o')
      allow(attachment).to receive(:authenticated_s3_url) # allow other calls due to, e.g., save
      expect(attachment).to receive(:authenticated_s3_url).with(include(response_content_disposition: %(attachment; filename="fo\\"o"; filename*=UTF-8''fo%22o)))
      attachment.public_download_url
    end

    it "transliterates filename with i18n" do
      a = attachment_with_context(@course, display_name: "糟糕.pdf")
      sanitized_filename = I18n.transliterate(a.display_name, replacement: "_")
      allow(a).to receive(:authenticated_s3_url)
      expect(a).to receive(:authenticated_s3_url).with(include(response_content_disposition: %(attachment; filename="#{sanitized_filename}"; filename*=UTF-8''%E7%B3%9F%E7%B3%95.pdf)))
      a.public_download_url
    end

    it "escapes all non-alphanumeric characters in the utf-8 filename" do
      attachment = attachment_with_context(@course, display_name: '"This file[0] \'{has}\' \# awesome `^<> chars 100%,|<-pipe"')
      allow(attachment).to receive(:authenticated_s3_url)
      expect(attachment).to receive(:authenticated_s3_url).with(include(response_content_disposition: %(attachment; filename="\\"This file[0] '{has}' \\# awesome `^<> chars 100%,|<-pipe\\""; filename*=UTF-8''%22This%20file%5B0%5D%20%27%7Bhas%7D%27%20%5C%23%20awesome%20%60%5E%3C%3E%20chars%20100%25%2C%7C%3C%2Dpipe%22)))
      attachment.public_download_url
    end
  end

  context "root_account_id" do
    before :once do
      account_model
      course_model(account: @account)
      @a = attachment_with_context(@course)
    end

    it "returns account id for normal namespaces" do
      @a.namespace = "account_#{@account.id}"
      expect(@a.root_account_id).to eq @account.id
    end

    it "returns account id for localstorage namespaces" do
      @a.namespace = "_localstorage_/#{@account.file_namespace}"
      expect(@a.root_account_id).to eq @account.id
    end

    it "immediately infers the namespace if not yet set" do
      Attachment.current_root_account = nil
      @a = Attachment.new(context: @course)
      expect(@a).to be_new_record
      expect(@a.read_attribute(:namespace)).to be_nil
      expect(@a.namespace).not_to be_nil
      @a.set_root_account_id
      expect(@a.read_attribute(:namespace)).not_to be_nil
      expect(@a.root_account_id).to eq @account.id
    end

    it "does not infer the namespace if it's not a new record" do
      Attachment.current_root_account = nil
      attachment_model(context: submission_model)
      original_namespace = @attachment.namespace
      @attachment.context = @course
      @attachment.save!
      expect(@attachment).not_to be_new_record
      expect(@attachment.read_attribute(:namespace)).to eq original_namespace
      expect(@attachment.namespace).to eq original_namespace
      expect(@attachment.read_attribute(:namespace)).to eq original_namespace
    end

    context "sharding" do
      specs_require_sharding

      it "stores a local id on the birth shard" do
        Attachment.current_root_account = Account.default
        att = Attachment.new
        att.infer_namespace
        att.set_root_account_id
        expect(att.namespace).to eq Account.default.asset_string
        expect(att.root_account_id).to eq Account.default.local_id
        @shard1.activate do
          expect(att.root_account_id).to eq Account.default.global_id
        end
      end

      it "stores a global id on all other shards" do
        a = nil
        att = nil
        @shard1.activate do
          a = Account.create!
          Attachment.current_root_account = a
          att = Attachment.new
          att.infer_namespace
          att.set_root_account_id
          expect(att.namespace).to eq a.global_asset_string
          expect(att.root_account_id).to eq a.local_id
        end
        expect(att.root_account_id).to eq a.global_id
      end

      it "interprets root_account_id correctly, even when local on not the birth shard" do
        a = nil
        att = nil
        @shard1.activate do
          a = Account.create!
          att = Attachment.new
          att.namespace = a.asset_string
          att.set_root_account_id
          expect(att.root_account_id).to eq a.local_id
        end
        expect(att.root_account_id).to eq a.global_id
      end

      it "stores ID for a cross-shard attachment" do
        Attachment.current_root_account = Account.default
        att = nil
        @shard1.activate do
          att = Attachment.new
          att.infer_namespace
          att.set_root_account_id
          expect(att.namespace).to eq Account.default.global_asset_string
          expect(att.root_account_id).to eq Account.default.global_id
        end
        expect(att.root_account_id).to eq Account.default.local_id
      end

      it "links a cross-shard cloned_item correctly" do
        course_factory
        a0 = attachment_model(display_name: "lolcats.mp4", context: @course, uploaded_data: stub_file_data("lolcats.mp4", "...", "video/mp4"))
        @shard1.activate do
          c1 = course_factory(account: account_model)
          a0.clone_for(c1)
        end
        a0.reload
        expect(Shard.shard_for(a0.cloned_item_id)).to eq @shard1
        expect(a0.cloned_item_id).not_to be_nil
      end
    end
  end

  context "encoding detection" do
    it "includes the charset when appropriate" do
      a = Attachment.new
      a.content_type = "text/html"
      expect(a.content_type_with_encoding).to eq "text/html"
      a.encoding = ""
      expect(a.content_type_with_encoding).to eq "text/html"
      a.encoding = "UTF-8"
      expect(a.content_type_with_encoding).to eq "text/html; charset=UTF-8"
      a.encoding = "mycustomencoding"
      expect(a.content_type_with_encoding).to eq "text/html; charset=mycustomencoding"
    end

    it "schedules encoding detection when appropriate" do
      expects_job_with_tag("Attachment#infer_encoding", 0) do
        attachment_model(uploaded_data: stub_file_data("file.txt", nil, "image/png"), content_type: "image/png")
      end
      expects_job_with_tag("Attachment#infer_encoding", 1) do
        attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")
      end
      expects_job_with_tag("Attachment#infer_encoding", 0) do
        attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html", encoding: "UTF-8")
      end
    end

    it "properly infers encoding" do
      attachment_model(uploaded_data: stub_png_data("blank.gif", "GIF89a\001\000\001\000\200\377\000\377\377\377\000\000\000,\000\000\000\000\001\000\001\000\000\002\002D\001\000;"))
      expect(@attachment.encoding).to be_nil
      @attachment.infer_encoding
      # can't figure out GIF encoding
      expect(@attachment.encoding).to eq ""

      attachment_model(uploaded_data: stub_png_data("blank.txt", "Hello World!"))
      expect(@attachment.encoding).to be_nil
      @attachment.infer_encoding
      expect(@attachment.encoding).to eq "UTF-8"

      attachment_model(uploaded_data: stub_png_data("blank.txt", "\xc2\xa9 2011"))
      expect(@attachment.encoding).to be_nil
      @attachment.infer_encoding
      expect(@attachment.encoding).to eq "UTF-8"

      attachment_model(uploaded_data: stub_png_data("blank.txt", "can't read me"))
      allow(@attachment).to receive(:open).and_raise(IOError)
      @attachment.infer_encoding
      expect(@attachment.encoding).to be_nil

      # work across split bytes
      allow(Attachment).to receive(:read_file_chunk_size).and_return(1)
      attachment_model(uploaded_data: stub_png_data("blank.txt", "\xc2\xa9 2011"))
      @attachment.infer_encoding
      expect(@attachment.encoding).to eq "UTF-8"
    end
  end

  context "sharding" do
    specs_require_sharding

    it "grants rights to owning user even if the user is on a seperate shard" do
      user = nil

      @shard1.activate do
        user = User.create!
        expect(user.attachments.build.grants_right?(user, :read)).to be_truthy
      end

      @shard2.activate do
        expect(user.attachments.build.grants_right?(user, :read)).to be_truthy
      end

      expect(user.attachments.build.grants_right?(user, :read)).to be_truthy
    end
  end

  context "#change_namespace and #make_childless" do
    before :once do
      @old_account = account_model
      @new_account = account_model
    end

    before do
      s3_storage!
      Attachment.current_root_account = @old_account
      @root = attachment_model(filename: "unknown 2.example")
      @child = attachment_model(root_attachment: @root)

      @old_object = double("old object")
      @new_object = double("new object")
      new_full_filename = @root.full_filename.sub(@root.namespace, @new_account.file_namespace)
      allow(@root.bucket).to receive(:object).with(@root.full_filename).and_return(@old_object)
      allow(@root.bucket).to receive(:object).with(new_full_filename).and_return(@new_object)
    end

    it "fails for non-root attachments" do
      expect(@old_object).not_to receive(:copy_to)
      expect { @child.change_namespace(@new_account.file_namespace) }.to raise_error("change_namespace must be called on a root attachment")
      expect(@root.reload.namespace).to eq @old_account.file_namespace
      expect(@child.reload.namespace).to eq @root.reload.namespace
    end

    it "does not copy if the destination exists" do
      expect(@new_object).to receive(:exists?).and_return(true)
      expect(@old_object).not_to receive(:copy_to)
      @root.change_namespace(@new_account.file_namespace)
      expect(@root.namespace).to eq @new_account.file_namespace
      expect(@child.reload.namespace).to eq @root.namespace
    end

    it "renames root attachments and update children" do
      expect(@new_object).to receive(:exists?).and_return(false)
      expect(@old_object).to receive(:copy_to).with(@new_object, anything)
      @root.change_namespace(@new_account.file_namespace)
      expect(@root.namespace).to eq @new_account.file_namespace
      expect(@child.reload.namespace).to eq @root.namespace
    end

    it "allows making a root_attachment childless" do
      @child.update_attribute(:filename, "invalid")
      expect(@root.s3object).to receive(:exists?).and_return(true)
      expect(@child).to receive(:s3object).and_return(@old_object)
      expect(@old_object).to receive(:exists?).and_return(true)
      @root.make_childless(@child)
      expect(@root.reload.children).to eq []
      expect(@child.reload.root_attachment_id).to be_nil
      expect(@child.read_attribute(:filename)).to eq @root.filename
    end
  end

  context "s3 storage with sharding" do
    let(:sz) { "640x>" }

    specs_require_sharding

    before do
      s3_storage!
      attachment_model(uploaded_data: stub_png_data, filename: "profile.png")
    end

    it "has namespaced thumb" do
      @shard1.activate do
        @attachment.thumbnail || @attachment.build_thumbnail.save!
        thumb = @attachment.thumbnail

        # i can't seem to get a s3 url so I am just going to make sure the thumbnail namespace was inherited from the attachment
        expect(thumb.namespace).to eq @attachment.namespace
        expect(thumb.authenticated_s3_url).to include @attachment.namespace
      end
    end

    it "does not have namespaced thumb when namespace is nil" do
      @shard1.activate do
        @attachment.thumbnail || @attachment.build_thumbnail.save!
        thumb = @attachment.thumbnail

        # nil out namespace so we can make sure the url generating is working properly
        thumb.namespace = nil
        expect(thumb.authenticated_s3_url).not_to include @attachment.namespace
      end
    end
  end

  context "has_thumbnail?" do
    context "non-instfs attachment" do
      it "is false when it doesn't have a thumbnail object (yet?)" do
        attachment_model(uploaded_data: stub_png_data)
        if @attachment.thumbnail
          @attachment.thumbnail.destroy!
          @attachment.thumbnail = nil
        end
        expect(@attachment.has_thumbnail?).to be false
      end

      it "is false when it doesn't have a thumbnail object even if instfs is enabled" do
        attachment_model(uploaded_data: stub_png_data)
        if @attachment.thumbnail
          @attachment.thumbnail.destroy!
          @attachment.thumbnail = nil
        end
        allow(InstFS).to receive(:enabled?).and_return true
        expect(@attachment.has_thumbnail?).to be false
      end

      it "is true when it has a thumbnail object" do
        attachment_model(uploaded_data: stub_png_data)
        @attachment.thumbnail || @attachment.build_thumbnail.save!
        expect(@attachment.has_thumbnail?).to be true
      end
    end

    context "instfs attachment" do
      before do
        allow(InstFS).to receive_messages(enabled?: true, jwt_secret: "secret", app_host: "instfs")
      end

      it "is false when not thumbnailable" do
        attachment_model(instfs_uuid: "abc", content_type: "text/plain")
        expect(@attachment.has_thumbnail?).to be false
      end

      it "is true when thumbnailable" do
        attachment_model(instfs_uuid: "abc", content_type: "image/png")
        expect(@attachment.has_thumbnail?).to be true
      end

      it "is true when thumbnailable and instfs is later disabled" do
        attachment_model(instfs_uuid: "abc", content_type: "image/png")
        allow(InstFS).to receive(:enabled?).and_return false
        expect(@attachment.has_thumbnail?).to be true
      end
    end
  end

  context "thumbnail_url (non-instfs)" do
    it "is the thumbnail's url" do
      attachment_model(uploaded_data: stub_png_data)
      @attachment.thumbnail || @attachment.build_thumbnail.save!
      expect(@attachment.thumbnail_url).to eq @attachment.thumbnail.cached_s3_url
    end
  end

  context "dynamic thumbnails" do
    let(:sz) { "640x>" }

    before do
      attachment_model(uploaded_data: stub_png_data)
    end

    around do |example|
      Timecop.freeze(&example)
    end

    it "uses the default size if an unknown size is passed in" do
      @attachment.thumbnail || @attachment.build_thumbnail.save!
      url = @attachment.thumbnail_url(size: "100x100")
      expect(url).to be_present
      expect(url).to eq @attachment.thumbnail.authenticated_s3_url(expires_in: 144.hours)
    end

    it "generates the thumbnail on the fly" do
      thumb = @attachment.thumbnails.where(thumbnail: "640x>").first
      expect(thumb).to be_nil

      expect(@attachment).to receive(:create_or_update_thumbnail).with(anything, sz, sz) {
        @attachment.thumbnails.create!(thumbnail: "640x>", uploaded_data: stub_png_data)
      }
      url = @attachment.thumbnail_url(size: "640x>")
      expect(url).to be_present
      thumb = @attachment.thumbnails.where(thumbnail: "640x>").first
      expect(thumb).to be_present
      expect(url).to eq thumb.authenticated_s3_url(expires_in: 144.hours)
    end

    it "uses the existing thumbnail if present" do
      expect(@attachment).to receive(:create_or_update_thumbnail).with(anything, sz, sz) {
        @attachment.thumbnails.create!(thumbnail: "640x>", uploaded_data: stub_png_data)
      }
      @attachment.thumbnail_url(size: "640x>")
      expect(@attachment).not_to receive(:create_dynamic_thumbnail)
      url = @attachment.thumbnail_url(size: "640x>")
      thumb = @attachment.thumbnails.where(thumbnail: "640x>").first
      expect(url).to be_present
      expect(thumb).to be_present
      expect(url).to eq thumb.authenticated_s3_url(expires_in: 144.hours)
    end
  end

  describe ".allows_thumbnails_for_size" do
    it "inevitably returns false if there is no size provided" do
      expect(Attachment.allows_thumbnails_of_size?(nil)).to be_falsey
    end

    it "returns true if the provided size is in the configured dynamic sizes" do
      expect(Attachment.allows_thumbnails_of_size?(Attachment::DYNAMIC_THUMBNAIL_SIZES.first)).to be_truthy
    end

    it "returns false if the provided size is not in the configured dynamic sizes" do
      expect(Attachment.allows_thumbnails_of_size?("nonsense")).to be_falsey
    end
  end

  describe "thumbnail source image size limitation" do
    before do
      local_storage! # s3 attachment data is stubbed out, so there is no image to identify the size of
      course_factory
    end

    it "creates thumbnails for smaller images" do
      att = @course.attachments.create! uploaded_data: jpeg_data_frd, filename: "ok.jpg"
      expect(att.thumbnail).not_to be_nil
      expect(att.thumbnail.width).not_to be_nil
    end

    it "does not create thumbnails for larger images" do
      att = @course.attachments.create! uploaded_data: one_hundred_megapixels_of_highly_compressed_png_data, filename: "3vil.png"
      expect(att.thumbnail).to be_nil
    end
  end

  context "notifications" do
    before :once do
      course_model(workflow_state: "available")
      # ^ enrolls @teacher in @course

      # create a student to receive notifications
      @student = user_model
      @student.register!
      @course.enroll_student(@student).accept
      communication_channel(@student, { username: "default@example.com", active_cc: true })

      @student_ended = user_model
      @student_ended.register!
      @section_ended = @course.course_sections.create!(end_at: 1.day.ago)
      @course.enroll_student(@student_ended, section: @section_ended).accept
      communication_channel(@student_ended, { username: "default2@example.com", active_cc: true })

      Notification.create!(name: "New File Added", category: "TestImmediately")
      Notification.create!(name: "New Files Added", category: "TestImmediately")
      Notification.create!(name: "New File Added - ended", category: "TestImmediately")
      Notification.create!(name: "New Files Added - ended", category: "TestImmediately")
    end

    it "sends a single-file notification" do
      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")
      expect(@attachment.need_notify).to be_truthy

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).not_to be_nil
    end

    it "does not send to student on hidden files" do
      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html", file_state: "hidden")
      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil
    end

    it "sends a batch notification" do
      att1 = attachment_model(uploaded_data: stub_file_data("file1.txt", nil, "text/html"), content_type: "text/html")
      att2 = attachment_model(uploaded_data: stub_file_data("file2.txt", nil, "text/html"), content_type: "text/html")
      att3 = attachment_model(uploaded_data: stub_file_data("file3.txt", nil, "text/html"), content_type: "text/html")
      [att1, att2, att3].each { |att| expect(att.need_notify).to be_truthy }

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      [att1, att2, att3].each { |att| expect(att.reload.need_notify).not_to be_truthy }
      expect(Message.where(user_id: @student, notification_name: "New Files Added").first).not_to be_nil
    end

    it "does not notify before a file finishes uploading" do
      # it's weird, but file_state is 'deleted' until the upload completes, when it is changed to 'available'
      attachment_model(file_state: "deleted", content_type: "text/html")
      expect(@attachment.need_notify).not_to be_truthy
    end

    it "postpones notification of a batch judged to be in-progress" do
      att1 = attachment_model(uploaded_data: stub_file_data("file1.txt", nil, "text/html"), content_type: "text/html")
      att2 = attachment_model(uploaded_data: stub_file_data("file2.txt", nil, "text/html"), content_type: "text/html")
      att3 = attachment_model(uploaded_data: stub_file_data("file3.txt", nil, "text/html"), content_type: "text/html")
      [att1, att2, att3].each { |att| expect(att.need_notify).to be_truthy }

      Timecop.freeze(2.minutes.from_now) { Attachment.do_notifications }
      [att1, att2, att3].each { |att| expect(att.reload.need_notify).to be_truthy }
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil

      Timecop.freeze(6.minutes.from_now) { Attachment.do_notifications }
      [att1, att2, att3].each { |att| expect(att.reload.need_notify).not_to be_truthy }
      expect(Message.where(user_id: @student, notification_name: "New Files Added").first).not_to be_nil
    end

    it "discards really old pending notifications" do
      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")
      expect(@attachment.need_notify).to be_truthy

      Timecop.freeze(1.week.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).to be_falsey
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil
    end

    it "respects save_without_broadcasting" do
      att1 = attachment_model(file_state: "deleted", uploaded_data: stub_file_data("file1.txt", nil, "text/html"), content_type: "text/html")
      att2 = attachment_model(file_state: "deleted", uploaded_data: stub_file_data("file2.txt", nil, "text/html"), content_type: "text/html")
      att3 = attachment_model(file_state: "deleted", uploaded_data: stub_file_data("file2.txt", nil, "text/html"), content_type: "text/html")

      expect(att1.need_notify).not_to be_truthy
      att1.file_state = "available"
      att1.save!
      expect(att1.need_notify).to be_truthy

      expect(att2.need_notify).not_to be_truthy
      att2.file_state = "available"
      att2.save_without_broadcasting
      expect(att2.need_notify).not_to be_truthy

      expect(att3.need_notify).not_to be_truthy
      att3.file_state = "available"
      att3.save_without_broadcasting!
      expect(att3.need_notify).not_to be_truthy
    end

    it "does not send notifications to students if the file is uploaded to a locked folder" do
      @teacher.register!
      communication_channel(@teacher, { username: "default@example.com", active_cc: true })

      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")

      @attachment.folder.locked = true
      @attachment.folder.save!

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil
      expect(Message.where(user_id: @teacher, notification_name: "New File Added").first).not_to be_nil
    end

    it "does not send notifications to students if the file is unpublished because of usage rights" do
      @teacher.register!
      communication_channel(@teacher, { username: "default@example.com", active_cc: true })

      @course.usage_rights_required = true
      @course.save!
      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")
      @attachment.set_publish_state_for_usage_rights
      @attachment.save!

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil
      expect(Message.where(user_id: @teacher, notification_name: "New File Added").first).not_to be_nil
    end

    it "does not send notifications to students if the files navigation is hidden from student view" do
      @teacher.register!
      communication_channel(@teacher, { username: "default@example.com", active_cc: true })

      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")

      @course.tab_configuration = [{ id: Course::TAB_FILES, hidden: true }]
      @course.save!

      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }

      @attachment.reload
      expect(@attachment.need_notify).not_to be_truthy
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil
      expect(Message.where(user_id: @teacher, notification_name: "New File Added").first).not_to be_nil
    end

    it "does not fail if the attachment context does not have participants" do
      cm = ContentMigration.create!(context: course_factory)
      attachment_model(context: cm, uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")

      Attachment.where(id: @attachment).update_all(need_notify: true)

      Timecop.freeze(10.minutes.from_now) do
        expect { Attachment.do_notifications }.not_to raise_error
      end
    end

    it "does not fail if the attachment context is a User" do
      attachment_model(context: user_factory, uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")

      Attachment.where(id: @attachment).update_all(need_notify: true)

      Timecop.freeze(10.minutes.from_now) do
        expect { Attachment.do_notifications }.not_to raise_error
      end
    end

    it "doesn't send notifications for a concluded course" do
      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")
      @course.soft_conclude!
      @course.save!
      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }
      expect(Message.where(user_id: @student, notification_name: "New File Added").first).to be_nil
    end

    it "doesn't send notifications for a concluded section in an active course" do
      skip("This test was not accurate, should be fixed in VICE-4138")
      attachment_model(uploaded_data: stub_file_data("file.txt", nil, "text/html"), content_type: "text/html")
      Timecop.freeze(10.minutes.from_now) { Attachment.do_notifications }
      expect(Message.where(user_id: @student_ended, notification_name: "New File Added").first).to be_nil
    end
  end

  context "quota" do
    it "gives small files a minimum quota size" do
      course_model
      attachment_model(context: @course, uploaded_data: stub_png_data, size: 25)
      quota = Attachment.get_quota(@course)
      expect(quota[:quota_used]).to eq Attachment::MINIMUM_SIZE_FOR_QUOTA
    end

    it "does not count attachments a student has used for submissions towards the quota" do
      course_with_student(active_all: true)
      attachment_model(context: @user, uploaded_data: stub_png_data, filename: "homework.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte

      @assignment = @course.assignments.create!
      @assignment.submit_homework(@user, attachments: [@attachment])

      attachment_model(context: @user, uploaded_data: stub_png_data, filename: "otherfile.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte
    end

    it "does not count attachments a student has used for graded discussion replies towards the quota" do
      course_with_student(active_all: true)
      attachment_model(context: @user, uploaded_data: stub_png_data, filename: "homework.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte

      assignment = @course.assignments.create!(title: "asmt")
      topic = @course.discussion_topics.create!(title: "topic", assignment:)
      entry = topic.reply_from(user: @student, text: "entry")
      entry.attachment = @attachment
      entry.save!

      attachment_model(context: @user, uploaded_data: stub_png_data, filename: "otherfile.png")
      @attachment.update_attribute(:size, 1.megabyte)

      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 1.megabyte
    end

    it "does not count attachments in submissions folders toward the quota" do
      user_model
      attachment_model(context: @user, uploaded_data: stub_png_data, filename: "whatever.png", folder: @user.submissions_folder)
      @attachment.update_attribute(:size, 1.megabyte)
      quota = Attachment.get_quota(@user)
      expect(quota[:quota_used]).to eq 0
    end

    it "does not count attachments in group submissions folders toward the quota" do
      group_model
      attachment_model(context: @group, uploaded_data: stub_png_data, filename: "whatever.png", folder: @group.submissions_folder)
      @attachment.update_attribute(:size, 1.megabyte)
      quota = Attachment.get_quota(@group)
      expect(quota[:quota_used]).to eq 0
    end

    it "returns available quota" do
      course_model
      @course.update storage_quota: 5.megabytes
      attachment_model(context: @course, uploaded_data: stub_png_data, filename: "whatever.png")
      @attachment.update_attribute :size, 1.megabyte
      expect(Attachment.quota_available(@course)).to eq 4.megabytes

      # ensure it doesn't go negative
      @attachment.update_attribute :size, 10.megabytes
      expect(Attachment.quota_available(@course)).to eq 0
    end
  end

  context "#open" do
    include WebMock::API

    context "instfs branch" do
      before :once do
        user_model
        attachment_model(context: @user)
        @public_url = "http://www.example.com/foo"
        @attachment.update md5: Digest::SHA512.hexdigest("test response body")
      end

      before do
        allow(@attachment).to receive_messages(instfs_hosted?: true, public_url: @public_url)
      end

      context "with good data" do
        before do
          stub_request(:get, @public_url)
            .to_return(status: 200, body: "test response body", headers: {})
        end

        it "streams data to the block given" do
          callback = false
          @attachment.open do |data|
            expect(data).to eq "test response body"
            callback = true
          end
          expect(callback).to be true
        end

        it "streams to a tempfile without a block given" do
          file = @attachment.open
          expect(file).to be_a(Tempfile)
          expect(file.read).to eq("test response body")
        end

        it "retries without duplicating already downloaded data" do
          # WebMock operates at too high a level to simulate a read timeout, so we'll hack the Tempfile
          # to raise one after the first write to it so we can test the exception flow
          raised = false
          allow(CanvasHttp::CircuitBreaker).to receive(:trip_if_necessary)
          expect_any_instance_of(Tempfile).to receive(:<<).at_least(:once).and_wrap_original do |m, *args|
            m.call(*args)
            unless raised
              raised = true
              raise Net::ReadTimeout
            end
          end
          file = @attachment.open
          expect(file).to be_a(Tempfile)
          expect(file.read).to eq("test response body")
        end
      end

      context "with bad data and :integrity_check" do
        # return bad data the first time, then correct data the second time
        before do
          stub_request(:get, @public_url)
            .to_return(status: 200, body: "bad response body :( :(").then
            .to_return(status: 200, body: "test response body")
        end

        # since we already sent bad data to the block, we can't fix this
        it "raises an error in the block flow" do
          expect { @attachment.open(integrity_check: true) { |data| data } }.to raise_error(Attachment::CorruptedDownload)
        end

        # we should rewind/truncate the tempfile and try the download again (but also log the exception)
        it "retries the download in the tempfile flow" do
          expect(Canvas::Errors).to receive(:capture_exception).with(:attachment, Attachment::CorruptedDownload, :info).once
          expect(@attachment.open(integrity_check: true).read).to eq "test response body"
        end
      end
    end

    shared_examples_for "non-streaming integrity_check" do
      it "accepts a correct md5" do
        @attachment.md5 = Digest::MD5.hexdigest("good data")
        expect { @attachment.open(integrity_check: true) }.not_to raise_error
      end

      it "rejects an invalid md5" do
        @attachment.md5 = Digest::MD5.hexdigest("bad data")
        expect { @attachment.open(integrity_check: true) }.to raise_error(Attachment::CorruptedDownload)
      end

      it "does nothing if there is no md5" do
        @attachment.md5 = nil
        expect { @attachment.open(integrity_check: true) }.not_to raise_error
      end
    end

    context "s3_storage" do
      before do
        s3_storage!
        attachment_model
      end

      it "streams data to the block given" do
        callback = false
        data = ["test", false]
        tempfile = double
        expect(tempfile).to receive(:binmode)
        expect(tempfile).to receive(:rewind)
        expect(tempfile).to receive(:path)

        expect(Tempfile).to receive(:new).and_return(tempfile)
        actual_file = double
        expect(actual_file).to(receive(:read).twice { data.shift })
        expect(File).to receive(:open).and_yield(actual_file)
        expect_any_instance_of(@attachment.s3object.class).to receive(:get).with(include(:response_target))
        @attachment.open do |d|
          expect(d).to eq "test"
          callback = true
        end
        expect(callback).to be true
      end

      it "streams to a tempfile without a block given" do
        expect_any_instance_of(@attachment.s3object.class).to receive(:get).with(include(:response_target))
        file = @attachment.open
        expect(file).to be_a(Tempfile)
      end

      describe "integrity_check" do
        before do
          expect_any_instance_of(@attachment.s3object.class).to receive(:get) do |_s3, args|
            args[:response_target].write("good data")
          end
        end

        include_examples "non-streaming integrity_check"
      end
    end

    context "local storage" do
      before :once do
        attachment_model
      end

      describe "integrity_check" do
        before do
          allow(@attachment).to receive(:full_filename).and_return(file_fixture("good_data.txt").to_s)
        end

        include_examples "non-streaming integrity_check"
      end
    end
  end

  context "#process_s3_details!" do
    before :once do
      attachment_model(filename: "new filename")
    end

    before do
      allow(Attachment).to receive_messages(local_storage?: false, s3_storage?: true)
      allow(@attachment).to receive(:s3object).and_return(double("s3object"))
      allow(@attachment).to receive(:after_attachment_saved)
    end

    context "deduplication" do
      before :once do
        attachment = @attachment
        @existing_attachment = attachment_model(filename: "existing filename")
        @child_attachment = attachment_model(root_attachment: @existing_attachment)
        @attachment = attachment
      end

      before do
        allow(@existing_attachment).to receive(:s3object).and_return(double("existing_s3object"))
        allow(@attachment).to receive(:find_existing_attachment_for_md5).and_return(@existing_attachment)
      end

      context "existing attachment has s3object" do
        before do
          allow(@existing_attachment.s3object).to receive(:exists?).and_return(true)
          allow(@attachment.s3object).to receive(:delete)
        end

        it "deletes the new (redundant) s3object" do
          expect(@attachment.s3object).to receive(:delete).once
          @attachment.process_s3_details!({})
        end

        it "puts the new attachment under the existing attachment" do
          @attachment.process_s3_details!({})
          expect(@attachment.reload.root_attachment).to eq @existing_attachment
        end

        it "retires the new attachment's filename" do
          @attachment.process_s3_details!({})
          expect(@attachment.reload.filename).to eq @existing_attachment.filename
        end
      end

      context "existing attachment is missing s3object" do
        before do
          allow(@existing_attachment.s3object).to receive(:exists?).and_return(false)
        end

        it "does not delete the new s3object" do
          expect(@attachment.s3object).not_to receive(:delete)
          @attachment.process_s3_details!({})
        end

        it "does not put the new attachment under the existing attachment" do
          @attachment.process_s3_details!({})
          expect(@attachment.reload.root_attachment).to be_nil
        end

        it "does not retire the new attachment's filename" do
          @attachment.process_s3_details!({})
          @attachment.reload.filename == "new filename"
        end

        it "puts the existing attachment under the new attachment" do
          @attachment.process_s3_details!({})
          expect(@existing_attachment.reload.root_attachment).to eq @attachment
        end

        it "retires the existing attachment's filename" do
          @attachment.process_s3_details!({})
          expect(@existing_attachment.reload.read_attribute(:filename)).to be_nil
          expect(@existing_attachment.filename).to eq @attachment.filename
        end

        it "reparents the child attachment under the new attachment" do
          @attachment.process_s3_details!({})
          expect(@child_attachment.reload.root_attachment).to eq @attachment
        end
      end
    end
  end

  context "permissions" do
    describe ":attach_to_submission_comment" do
      it "works for assignments if you own the attachment" do
        @s1, @s2 = n_students_in_course(2)
        @assignment = @course.assignments.create! name: "blah"
        @attachment = Attachment.create! context: @assignment,
                                         filename: "foo.txt",
                                         uploaded_data: StringIO.new("bar"),
                                         user: @s1
        expect(@attachment.grants_right?(@s1, :attach_to_submission_comment)).to be_truthy
        expect(@attachment.grants_right?(@s2, :attach_to_submission_comment)).to be_falsey
      end
    end
  end

  describe "#full_path" do
    it "does not puke for things that don't have folders" do
      attachment_obj_with_context(Account.default.default_enrollment_term)
      @attachment.folder = nil
      expect(@attachment.full_path).to eq "/#{@attachment.display_name}"
    end
  end

  describe ".clone_url_strand" do
    it "falls back for invalid URLs" do
      expect(Attachment.clone_url_strand("")).to eq "file_download"
    end

    it "gives the host for 'local' host" do
      expect(Attachment.clone_url_strand("http://localhost:9090/image.jpg")).to eq ["file_download", "localhost"]
    end

    it "gives the full host for simple domain" do
      expect(Attachment.clone_url_strand("http://google.com/image.jpg")).to eq ["file_download", "google.com"]
    end

    it "strips subdomains" do
      expect(Attachment.clone_url_strand("http://cdn.google.com/image.jpg")).to eq ["file_download", "google.com"]
    end

    it "accepts overrides" do
      allow(Attachment).to receive(:clone_url_strand_overrides).and_return("cdn.google.com" => "cdn")
      expect(Attachment.clone_url_strand("http://cdn.google.com/image.jpg")).to eq ["file_download", "cdn"]
    end
  end

  describe ".clone_url_as_attachment" do
    it "rejects invalid urls" do
      expect { Attachment.clone_url_as_attachment("ftp://some/stuff") }.to raise_error(ArgumentError)
    end

    it "uses an existing attachment if passed in" do
      url = "http://example.com/test.png"
      a = attachment_model
      expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new("200", "this is a jpeg", "content-type" => "image/jpeg"))
      Attachment.clone_url_as_attachment(url, attachment: a)
      a.save!
      expect(a.open.read).to eq "this is a jpeg"
    end

    it "does not overwrite the content_type if already present" do
      url = "http://example.com/test.png"
      a = attachment_model(content_type: "image/jpeg")
      expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new("200", "this is a jpeg", "content-type" => "application/octet-stream"))
      Attachment.clone_url_as_attachment(url, attachment: a)
      a.save!
      expect(a.open.read).to eq "this is a jpeg"
      expect(a.content_type).to eq "image/jpeg"
    end

    it "detects the content_type from the body" do
      url = "http://example.com/test.png"
      expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new("200", file_fixture("cn_image.jpg").read, "content-type" => "image/jpeg"))
      att = Attachment.clone_url_as_attachment(url)
      expect(att).to be_present
      expect(att).to be_new_record
      expect(att.content_type).to eq "image/jpeg"
    end

    context "with non-200 responses" do
      subject { Attachment.clone_url_as_attachment(url) }

      let(:url) { "http://example.com/test.png" }
      let(:body) { "body content" }
      let(:http_response) { FakeHttpResponse.new(401, body) }

      before { allow(CanvasHttp).to receive(:get).with(url).and_yield(http_response) }

      it "raises on non-200 responses" do
        expect { subject }.to raise_error(CanvasHttp::InvalidResponseCodeError)
      end

      it "includes the body in the reaised error" do
        expect { subject }.to raise_error(
          an_instance_of(
            CanvasHttp::InvalidResponseCodeError
          ).and(having_attributes(body: "#{body}..."))
        )
      end

      context "and an error reading the response body" do
        before { allow(http_response).to receive(:read_body).and_raise StandardError }

        it "raises the invalid response error" do
          expect { subject }.to raise_error(CanvasHttp::InvalidResponseCodeError)
        end
      end
    end
  end

  describe ".migrate_attachments" do
    before :once do
      @merge_user_1 = student_in_course(active_all: true).user
      @merge_user_2 = student_in_course(active_all: true).user

      @user_1_file = Attachment.create!(user: @merge_user_1,
                                        context: @merge_user_1,
                                        filename: "hi.txt",
                                        uploaded_data: StringIO.new("hi_data"))
    end

    it "changes the context over to the new context" do
      Attachment.migrate_attachments(@merge_user_1, @merge_user_2)
      expect(@user_1_file.reload.context).to eq @merge_user_2
    end

    it "doesn't move files that already exist in the new context" do
      @user_2_file = Attachment.create!(user: @merge_user_2,
                                        context: @merge_user_2,
                                        filename: "hi.txt",
                                        uploaded_data: StringIO.new("hi_data"))
      Attachment.migrate_attachments(@merge_user_1, @merge_user_2)
      expect(@user_1_file.reload.context).to eq @merge_user_1
    end

    it "does move files that already exist (by filename), but have nil md5" do
      @user_1_file.update(md5: nil)
      @user_2_file = Attachment.create!(user: @merge_user_2,
                                        context: @merge_user_2,
                                        filename: "hi.txt",
                                        uploaded_data: StringIO.new("hi_data"))
      @user_2_file.update(md5: nil)
      Attachment.migrate_attachments(@merge_user_1, @merge_user_2)
      expect(@user_1_file.reload.context).to eq @merge_user_2
    end

    it "handles name changes for files that are different but have the same name" do
      @user_2_file = Attachment.create!(user: @merge_user_2,
                                        context: @merge_user_2,
                                        filename: "hi.txt",
                                        uploaded_data: StringIO.new("yo_data"))
      Attachment.migrate_attachments(@merge_user_1, @merge_user_2)
      expect(@user_1_file.title).not_to eq(@user_1_file.reload.title)
      expect(@user_1_file.title).not_to eq(@user_2_file.title)
      expect(@user_1_file.context).to eq @merge_user_2
    end

    it "ensures files in submissions folders stay in submissions folders" do
      @user_1_file.update! folder: @merge_user_1.submissions_folder(@course)
      Attachment.migrate_attachments(@merge_user_1, @merge_user_2)
      expect(@user_1_file.reload.folder.submission_context_code).to eq @course.asset_string
    end

    it "ensures files NOT in submissions folders don't end up in submissions folders" do
      not_submissions_folder = Folder.assert_path("Submissions/#{@course.name}", @merge_user_1)
      @user_1_file.update! folder: not_submissions_folder
      sub_folder_2 = @merge_user_2.submissions_folder(@course)
      Attachment.migrate_attachments(@merge_user_1, @merge_user_2)
      dest_folder = @user_1_file.reload.folder
      expect(dest_folder).not_to eq sub_folder_2
      expect(dest_folder.submission_context_code).to be_nil
    end

    context "with sharding" do
      specs_require_sharding

      before :once do
        @shard1.activate do
          @merge_user_3 = user_model
        end
      end

      it "copies the attachment to the new shard and leaves the existing attachment" do
        Attachment.migrate_attachments(@merge_user_1, @merge_user_3)
        expect(@user_1_file.reload.context).to eq @merge_user_1
        expect(@user_1_file.user).to eq @merge_user_3
        new_attachment = @merge_user_3.attachments.find_by(filename: @user_1_file.title, md5: @user_1_file.md5)
        expect(new_attachment.full_display_path).to eq @user_1_file.full_display_path
      end

      it "translates a submission folder's context code" do
        @user_1_file.update! folder: @merge_user_1.submissions_folder(@course)
        Attachment.migrate_attachments(@merge_user_1, @merge_user_3)
        new_attachment = @merge_user_3.attachments.find_by(filename: @user_1_file.title, md5: @user_1_file.md5)
        expect(new_attachment.folder.submission_context_code).to eq @course.global_asset_string
      end
    end
  end

  describe ".clone_url" do
    def clone_it
      attachment.clone_url(url, handling, check_quota, opts)
    end

    let(:attachment) { attachment_model }
    let(:url) { "https://www.test.com/file.jpg" }
    let(:handling) { nil }
    let(:check_quota) { nil }
    let(:opts) { {} }

    context "when an error retrieving the file occurs" do
      before { allow(Attachment).to receive(:clone_url_as_attachment).and_raise error }

      context "and the error was an invalid response code" do
        let(:error) { CanvasHttp::InvalidResponseCodeError.new(code, body) }
        let(:code) { 400 }
        let(:body) { "response body" }

        it "captures the error" do
          expect(Canvas::Errors).to receive(:capture).with(
            error, attachment.clone_url_error_info(error, url)
          )
          clone_it
          expect(attachment.upload_error_message).to include(url)
        end
      end

      context "and the error was unknown" do
        let(:error) { StandardError }

        it "captures the error" do
          expect(Canvas::Errors).to receive(:capture).with(
            error, attachment.clone_url_error_info(error, url)
          )
          clone_it
          expect(attachment.upload_error_message).to include(url)
        end
      end
    end
  end

  describe ".clone_url_error_info" do
    subject { attachment.clone_url_error_info(error, url) }

    let(:attachment) { attachment_model }
    let(:url) { "https://www.test.com/file.jpg" }
    let(:error) { StandardError.new }

    it "includes the proper type tag" do
      expect(subject.dig(:tags, :type)).to eq Attachment::CLONING_ERROR_TYPE
    end

    it "includes the url of the failed download" do
      expect(subject.dig(:extra, :url)).to eq url
    end

    context "when the exception includes a code" do
      let(:error) { CanvasHttp::InvalidResponseCodeError.new(code, nil) }
      let(:code) { 400 }

      it "includes the code from the error" do
        expect(subject.dig(:extra, :http_status_code)).to eq code
      end
    end

    context "when the exception includes a body" do
      let(:error) { CanvasHttp::InvalidResponseCodeError.new(nil, body) }
      let(:body) { "body content" }

      it "includes the code from the error" do
        expect(subject.dig(:extra, :body)).to eq body
      end
    end
  end

  describe "infer_namespace" do
    it "infers the correct namespace from the root attachment" do
      local_storage!
      allow(Rails.env).to receive(:development?).and_return(true)
      course_factory
      a1 = attachment_model(context: @course, uploaded_data: default_uploaded_data)
      a2 = attachment_model(context: @course, uploaded_data: default_uploaded_data)
      expect(a2.root_attachment).to eql(a1)
      expect(a2.namespace).to eql(a1.namespace)
    end
  end

  it "is able to add a hidden attachment as a context module item" do
    course_factory
    att = attachment_model(context: @course, uploaded_data: default_uploaded_data)
    att.hidden = true
    att.save!
    mod = @course.context_modules.create!(name: "some module")
    tag1 = mod.add_item(id: att.id, type: "attachment")
    expect(tag1).not_to be_nil
  end

  it "unlocks and lock files at the right time even if they're accessed shortly before" do
    enable_cache do
      course_with_student active_all: true
      attachment_model uploaded_data: default_uploaded_data, unlock_at: 30.seconds.from_now, lock_at: 35.seconds.from_now
      expect(@attachment.grants_right?(@student, :download)).to be false # prime cache
      Timecop.freeze(@attachment.unlock_at + 1.second) do
        run_jobs
        expect(Attachment.find(@attachment.id).grants_right?(@student, :download)).to be true
      end

      Timecop.freeze(@attachment.lock_at + 1.second) do
        run_jobs
        expect(Attachment.find(@attachment.id).grants_right?(@student, :download)).to be false
      end
    end
  end

  it "is not locked_for soft-concluded admin users" do
    term = Account.default.enrollment_terms.create!
    term.set_overrides(Account.default, "TeacherEnrollment" => { end_at: 3.days.ago })
    course_with_teacher(active_all: true)
    @course.enrollment_term = term
    @course.save!

    attachment_model uploaded_data: default_uploaded_data
    @attachment.update_attribute(:locked, true)
    @attachment.reload
    expect(@attachment.locked_for?(@teacher, check_policies: true)).to be_falsey
  end

  describe "local storage" do
    it "properly sanitizes a filename containing a slash" do
      local_storage!
      course_factory
      a = attachment_model(filename: "ENGL_100_/_ENGL_200.csv")
      expect(a.filename).to eql("ENGL_100___ENGL_200.csv")
    end

    it "still properly escapes the same filename on s3" do
      s3_storage!
      course_factory
      a = attachment_model(filename: "ENGL_100_/_ENGL_200.csv")
      expect(a.filename).to eql("ENGL_100_%2F_ENGL_200.csv")
    end
  end

  describe "#ajax_upload_params" do
    it "returns the attachment filename in the upload params" do
      attachment_model filename: "test.txt"
      pseudonym @user
      json = @attachment.ajax_upload_params("", "")
      expect(json[:upload_params]["Filename"]).to eq "test.txt"
    end
  end

  describe "copy_to_folder!" do
    before(:once) do
      attachment_model filename: "test.txt"
      @folder = @context.folders.create! name: "over there"
    end

    it "copies a file into a folder" do
      dup = @attachment.copy_to_folder!(@folder)
      expect(dup.root_attachment).to eq @attachment
      expect(dup.display_name).to eq "test.txt"
    end

    it "handles duplicates" do
      attachment_model filename: "test.txt", folder: @folder
      dup = @attachment.copy_to_folder!(@folder)
      expect(dup.root_attachment).to eq @attachment
      expect(dup.display_name).not_to eq "test.txt"
    end
  end

  context "create" do
    it "sets the root_account_id using course context" do
      attachment_model filename: "test.txt"
      expect(@attachment.root_account_id).to eq @course.root_account_id
    end

    it "sets the root_account_id using account context" do
      account_model
      attachment_model filename: "test.txt", context: @account
      expect(@attachment.root_account_id).to eq @account.id
    end

    describe "word count" do
      it "updates the word count for a PDF" do
        attachment_model(filename: "test.pdf", uploaded_data: fixture_file_upload("example.pdf", "application/pdf"))
        @attachment.update_word_count
        expect(@attachment.word_count).to eq 3328
      end

      it "updates the word count for a DOCX file" do
        attachment_model(filename: "test.docx", uploaded_data: fixture_file_upload("test.docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"))
        @attachment.update_word_count
        expect(@attachment.word_count).to eq 5
      end

      it "updates the word count for an RTF file" do
        attachment_model(filename: "test.rtf", uploaded_data: fixture_file_upload("test.rtf", "application/rtf"))
        @attachment.update_word_count
        expect(@attachment.word_count).to eq 5
      end

      it "updates the word count for a text file" do
        attachment_model(filename: "test.txt", uploaded_data: fixture_file_upload("amazing_file.txt", "text/plain"))
        @attachment.update_word_count
        expect(@attachment.word_count).to eq 5
      end

      it "sets 0 if the file is not supported" do
        attachment_model(filename: "test.png", uploaded_data: fixture_file_upload("instructure.png", "image/png"))
        @attachment.update_word_count
        expect(@attachment.word_count).to eq 0
      end
    end
  end

  context "mime_class" do
    it "handles general video types" do
      attachment_model content_type: "video/mp4"
      expect(@attachment.mime_class).to eq "video"
    end

    it "handles general audio types" do
      attachment_model content_type: "audio/webm"
      expect(@attachment.mime_class).to eq "audio"
    end

    it "handles general image types" do
      attachment_model content_type: "image/svg+xml"
      expect(@attachment.mime_class).to eq "image"
    end

    it "handles specifically enumerated types" do
      attachment_model content_type: "application/vnd.ms-powerpoint"
      expect(@attachment.mime_class).to eq "ppt"
    end
  end

  describe "copy_attachments_to_submissions_folder" do
    before(:once) do
      course_with_student
      @course.account.enable_service(:avatars)
      attachment_model(context: @student)
    end

    it "copies a user attachment into the user's submissions folder" do
      atts = Attachment.copy_attachments_to_submissions_folder(@course, [@attachment])
      expect(atts.length).to eq 1
      expect(atts[0]).not_to eq @attachment
      expect(atts[0].folder).to eq @student.submissions_folder(@course)
    end

    it "copies an attachment for a separate submission into the user's submission folder" do
      submission_model(context: @course, user: @student)
      @submission.attachment = @attachment
      @submission.save!

      @attachment.folder = @student.submissions_folder(@course)
      @attachment.save!

      atts = Attachment.copy_attachments_to_submissions_folder(@course, [@submission.attachment])
      expect(atts.length).to eq 1
      expect(atts[0]).not_to eq @attachment
      expect(atts[0].folder).to eq @student.submissions_folder(@course)
    end

    it "leaves files already in submissions folders alone" do
      @attachment.folder = @student.submissions_folder(@course)
      @attachment.save!
      atts = Attachment.copy_attachments_to_submissions_folder(@course, [@attachment])
      expect(atts).to eq [@attachment]
    end

    it "copies a group attachment into the group submission folder" do
      group_model(context: @course)
      attachment_model(context: @group)
      atts = Attachment.copy_attachments_to_submissions_folder(@course, [@attachment])
      expect(atts.length).to eq 1
      expect(atts[0]).not_to eq @attachment
      expect(atts[0].folder).to eq @group.submissions_folder
    end

    it "leaves files in non user/group context alone" do
      assignment_model(context: @course)
      weird_file = @assignment.attachments.create! display_name: "blah", uploaded_data: default_uploaded_data
      atts = Attachment.copy_attachments_to_submissions_folder(@course, [weird_file])
      expect(atts).to eq [weird_file]
    end
  end

  describe "#copy_to_student_annotation_documents_folder" do
    before(:once) do
      course_model
    end

    it "copies attachment into the course Student Annotation Documents folder if not present already" do
      att = attachment_model(context: @course)
      att_clone = att.copy_to_student_annotation_documents_folder(@course)

      aggregate_failures do
        expect(att_clone.id).not_to be att.id
        expect(att_clone.folder).to eq @course.student_annotation_documents_folder
      end
    end

    it "does not copy attachment into the course Student Annotation Documents folder if already present" do
      att = attachment_model(context: @course, folder: @course.student_annotation_documents_folder)
      same_att = att.copy_to_student_annotation_documents_folder(@course)

      expect(same_att).to eq att
    end
  end

  describe "media_object_by_media_id" do
    before(:once) do
      course_with_teacher(active_all: true)
      @media_object = @course.media_objects.create!(media_id: "0_feedbeef", attachment: attachment_model(context: @course))
      @attachment = attachment_model(context: @course, media_entry_id: @media_object.media_id)
    end

    it "returns the media object with the given media id" do
      expect(@attachment.media_object_by_media_id).to eq @media_object
    end

    it "returns soft-deleted media objects" do
      @media_object.destroy
      expect(@attachment.media_object_by_media_id).to eq @media_object
    end
  end
end
