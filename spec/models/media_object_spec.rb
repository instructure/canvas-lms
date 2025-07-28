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

describe MediaObject do
  before :once do
    course_factory
  end

  context "loading with legacy support" do
    it "loads by either media_id or old_media_id" do
      mo = MediaObject.create!(media_id: "0_abcdefgh", old_media_id: "1_01234567", context: @course)

      expect(MediaObject.by_media_id("0_abcdefgh").first).to eq mo
      expect(MediaObject.by_media_id("1_01234567").first).to eq mo
    end

    it "does not find an arbitrary MediaObject when given a nil id" do
      MediaObject.create!(media_id: "0_abcdefgh", context: @course)
      expect(MediaObject.by_media_id(nil).first).to be_nil
    end

    it "raises an error if someone tries to use find_by_media_id" do
      expect { MediaObject.find_by(media_id: "fjdksl") }.to raise_error("Do not look up MediaObjects by media_id - use the scope by_media_id instead to support migrated content.")
    end
  end

  describe ".build_media_objects" do
    it "builds media objects from attachment_id" do
      @a1 = attachment_model(context: @course, uploaded_data: stub_file_data("video1.mp4", nil, "video/mp4"))
      @a3 = attachment_model(context: @course, uploaded_data: stub_file_data("video1.mp4", nil, "video/mp4"))
      @a4 = attachment_model(context: @course, uploaded_data: stub_file_data("video1.mp4", nil, "video/mp4"))
      data = {
        entries: [
          { entryId: "test2", originalId: @a1.id.to_s },
          { entryId: "test3", originalId: @a3.id },
          { entryId: "test4", originalId: "attachment_id=#{@a4.id}" }
        ],
      }
      MediaObject.create!(context: user_factory, media_id: "test")
      MediaObject.create!(context: user_factory, media_id: "test2")
      MediaObject.create!(context: user_factory, media_id: "test3")
      MediaObject.build_media_objects(data, Account.default.id)
      media_object = MediaObject.where(attachment_id: @a1).first
      expect(media_object).not_to be_nil
      media_object = MediaObject.where(attachment_id: @a3).first
      expect(media_object).not_to be_nil
      media_object = MediaObject.where(attachment_id: @a4).first
      expect(media_object).not_to be_nil
    end
  end

  describe ".ensure_media_object" do
    it "does not create if the media object exists already" do
      MediaObject.create!(context: user_factory, media_id: "test")
      expect(MediaObject).not_to receive(:create!)
      MediaObject.ensure_media_object("test")
    end

    it "does not create if the media id doesn't exist in kaltura" do
      expect(MediaObject).to receive(:media_id_exists?).with("test").and_return(false)
      expect(MediaObject).not_to receive(:create!)
      MediaObject.ensure_media_object("test")
      run_jobs
    end

    it "creates the media object" do
      expect(MediaObject).to receive(:media_id_exists?).with("test").and_return(true)
      MediaObject.ensure_media_object("test", context: user_factory)
      run_jobs
      obj = MediaObject.by_media_id("test").first
      expect(obj.context).to eq @user
    end
  end

  describe ".ensure_attachment_media_info" do
    it "fixes associated attachments in a weird state" do
      file_data = fixture_file_upload("292.mp3", "audio/mpeg", true)
      a1 = attachment_model(context: @course, uploaded_data: file_data, media_entry_id: "m-unicorns")
      client = double("kaltura_client")
      expect(CanvasKaltura::ClientV3).to receive_messages(new: client)
      url = "http://example.com/video1.mp3"
      media_sources = [{
        size: "283",
        isOriginal: "0",
        fileExt: "mp3",
        url:,
        content_type: "audio/mpeg"
      }]
      expect(client).to receive_messages(media_sources:)
      mo = @course.media_objects.create!(attachment_id: a1, media_id: "m-unicorns", title: "video1.mp3", media_type: "video/*")
      course_model
      attachment_model(context: @course, uploaded_data: file_data)
      a1.update!(root_attachment_id: @attachment.id, content_type: "unknown/unknown", workflow_state: "pending_upload", display_name: "video1", media_entry_id: nil)
      a1.update_columns(filename: nil)

      expect(CanvasHttp).to receive_messages(validate_url: [nil, URI.parse(url)])
      expect(CanvasHttp).to receive(:get).with(url).and_yield(FakeHttpResponse.new("200", File.read(file_data)))
      mo.ensure_attachment_media_info
      expect(a1.reload.attributes).to include({ "filename" => match("292.mp3"), "content_type" => "audio/mpeg", "workflow_state" => "processed", "media_entry_id" => mo.media_id, "display_name" => "video1.mp3" })
    end
  end

  describe "#transcoded_details" do
    before do
      @mock_kaltura = double("CanvasKaltura::ClientV3")
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(@mock_kaltura)
      allow(@mock_kaltura).to receive(:media_sources).and_return(
        [{ height: "240",
           bitrate: "382",
           isOriginal: "0",
           width: "336",
           content_type: "video/mp4",
           containerFormat: "isom",
           url: "https://kaltura.example.com/some/url",
           size: "204",
           fileExt: "mp4" },
         { height: "240",
           bitrate: "382",
           isOriginal: "0",
           width: "336",
           content_type: "audio/mpeg",
           containerFormat: "isom",
           url: "https://kaltura.example.com/some/url",
           size: "204",
           fileExt: "mp3" }]
      )
    end

    it "returns the mp3 info" do
      mo = MediaObject.create!(context: user_factory, media_id: "test")
      expect(mo.transcoded_details).to be_nil
      mo.data = { extensions: { mov: { id: "t-xxx" } } }
      expect(mo.transcoded_details).to be_nil
      mo.data = { extensions: { mp3: { id: "t-yyy" } } }
      expect(mo.transcoded_details).to eq(id: "t-yyy")
    end

    it "returns the mp4 info" do
      mo = MediaObject.create!(context: user_factory, media_id: "test")
      mo.data = { extensions: { mp4: { id: "t-yyy" } } }
      expect(mo.transcoded_details).to eq(id: "t-yyy")
    end

    it "returns the mp3 info if the mp3 and mp4 extensions are present" do
      mo = MediaObject.create!(context: user_factory, media_id: "test")
      mo.data = { extensions: { mp3: { id: "t-yyy", fileExt: "mp3" }, mp4: { id: "t-zzz", fileExt: "mp4" } } }
      expect(mo.transcoded_details).to eq({ id: "t-yyy", fileExt: "mp3" })
    end

    it "returns the mp4 info if the mp3 extension is present but media source is not available" do
      allow(@mock_kaltura).to receive(:media_sources).and_return(
        [{ height: "240",
           bitrate: "382",
           isOriginal: "0",
           width: "336",
           content_type: "video/mp4",
           containerFormat: "isom",
           url: "https://kaltura.example.com/some/url",
           size: "204",
           fileExt: "mp4" }]
      )
      mo = MediaObject.create!(context: user_factory, media_id: "test")
      mo.data = { extensions: { mp3: { id: "t-yyy", fileExt: "mp3" }, mp4: { id: "t-zzz", fileExt: "mp4" } } }
      expect(mo.transcoded_details).to eq({ id: "t-zzz", fileExt: "mp4" })
    end
  end

  describe "#retrieve_details_ensure_codecs" do
    before do
      @mock_kaltura = double("CanvasKaltura::ClientV3")
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(@mock_kaltura)
      allow(@mock_kaltura).to receive(:media_sources).and_return(
        [{ height: "240",
           bitrate: "382",
           isOriginal: "0",
           width: "336",
           content_type: "video/mp4",
           containerFormat: "isom",
           url: "https://kaltura.example.com/some/url",
           size: "204",
           fileExt: "mp4" },
         { height: "240",
           bitrate: "382",
           isOriginal: "0",
           width: "336",
           content_type: "audio/mpeg",
           containerFormat: "isom",
           url: "https://kaltura.example.com/some/url",
           size: "204",
           fileExt: "mp3" }]
      )
    end

    it "retries later when the transcode isn't available" do
      Timecop.freeze do
        mo = MediaObject.create!(context: user_factory, media_id: "test")
        expect(mo).to receive(:retrieve_details)
        expect(mo).to receive(:delay).with(run_at: 5.minutes.from_now).and_return(mo)
        expect(mo).to receive(:retrieve_details_ensure_codecs).ordered.with(1).and_call_original
        expect(mo).to receive(:retrieve_details_ensure_codecs).ordered.with(2)
        mo.retrieve_details_ensure_codecs(1)
      end
    end

    it "verifies existence of the transcoded details" do
      mo = MediaObject.create!(context: user_factory, media_id: "test")
      mo.data = { extensions: { mp4: { id: "t-yyy" } } }
      expect(mo).to receive(:retrieve_details)
      expect(mo).not_to receive(:delay)
      mo.retrieve_details_ensure_codecs(1)
    end
  end

  context "permissions" do
    context "captions" do
      it "allows course admin users to add_captions to objects" do
        course_with_teacher
        mo = media_object

        mo.user = nil
        mo.save!

        expect(mo.grants_right?(@teacher, :add_captions)).to be true
        expect(mo.grants_right?(@teacher, :delete_captions)).to be true
      end

      it "does not allow course non-admin users to add_captions to objects" do
        course_with_student
        mo = media_object

        expect(mo.grants_right?(@student, :add_captions)).to be false
        expect(mo.grants_right?(@student, :delete_captions)).to be false
      end

      it "does not allow course non-admin users to add_captions to objects even if they own it" do
        course_with_student
        mo = media_object
        user_factory

        mo.user = @user
        mo.save!

        expect(mo.grants_right?(@user, :add_captions)).to be false
        expect(mo.grants_right?(@user, :delete_captions)).to be false
      end

      it "does not allow course non-admin users to add_captions to objects even if they own the attachment" do
        course_with_student
        mo = media_object

        attachment = mo.attachment
        attachment.user = @student
        attachment.save!

        expect(mo.grants_right?(@student, :add_captions)).to be false
        expect(mo.grants_right?(@student, :delete_captions)).to be false
      end

      context "with specific permissions" do
        let(:ta_role) { Role.get_built_in_role("TaEnrollment", root_account_id: @course.root_account.id) }

        before do
          course_with_ta
          @mo = media_object
        end

        it "allows course non-admin users to add_captions to attachments they can manage_files_add on the course" do
          # disable manage_course_content_add for TAs to test that manage_files_edit is used instead
          RoleOverride.create!(
            permission: "manage_course_content_add",
            enabled: false,
            role: ta_role,
            account: @course.root_account
          )

          expect(@mo.grants_right?(@ta, :add_captions)).to be true
        end

        it "does not allow course non-admin users to add_captions to attachments if they don't have permissions" do
          RoleOverride.create!(
            permission: "manage_files_edit",
            enabled: false,
            role: ta_role,
            account: @course.root_account
          )
          RoleOverride.create!(
            permission: "manage_course_content_add",
            enabled: false,
            role: ta_role,
            account: @course.root_account
          )

          expect(@mo.grants_right?(@ta, :add_captions)).to be false
        end

        it "allows course non-admin users to delete_captions to attachments they can manage_files_delete on the course" do
          # disable manage_course_content_delete for TAs to test that manage_files_edit is used instead
          RoleOverride.create!(
            permission: "manage_course_content_delete",
            enabled: false,
            role: ta_role,
            account: @course.root_account
          )

          expect(@mo.grants_right?(@ta, :delete_captions)).to be true
        end

        it "does not allow course non-admin users to delete_captions to attachments if they don't have permissions" do
          RoleOverride.create!(
            permission: "manage_files_edit",
            enabled: false,
            role: ta_role,
            account: @course.root_account
          )
          RoleOverride.create!(
            permission: "manage_course_content_delete",
            enabled: false,
            role: ta_role,
            account: @course.root_account
          )

          expect(@mo.grants_right?(@ta, :delete_captions)).to be false
        end

        context "without an attachment" do
          before do
            @mo.update_column(:attachment_id, nil)
            # disable attachment permissions just in case
            RoleOverride.create!(
              permission: "manage_files_edit",
              enabled: false,
              role: ta_role,
              account: @course.root_account
            )
          end

          it "allows course non-admin users to add_captions to attachments they can manage_course_content_add" do
            RoleOverride.create!(
              permission: "manage_course_content_add",
              enabled: true,
              role: ta_role,
              account: @course.root_account
            )

            expect(@mo.attachment).to be_nil
            expect(@mo.grants_right?(@ta, :add_captions)).to be true
          end

          it "does allow course non-admin users to add_captions to attachments if they don't have manage_course_content_add but own media object" do
            RoleOverride.create!(
              permission: "manage_course_content_add",
              enabled: false,
              role: ta_role,
              account: @course.root_account
            )

            expect(@mo.attachment).to be_nil
            expect(@mo.grants_right?(@ta, :add_captions)).to be true
          end

          it "does not allow course non-admin users to add_captions to attachments if they don't have manage_course_content_add" do
            @mo.user = user_factory
            RoleOverride.create!(
              permission: "manage_course_content_add",
              enabled: false,
              role: ta_role,
              account: @course.root_account
            )

            expect(@mo.attachment).to be_nil
            expect(@mo.grants_right?(@ta, :add_captions)).to be false
          end

          it "allows course non-admin users to delete_captions to attachments they can manage_course_content_delete" do
            RoleOverride.create!(
              permission: "manage_course_content_delete",
              enabled: true,
              role: ta_role,
              account: @course.root_account
            )

            expect(@mo.attachment).to be_nil
            expect(@mo.grants_right?(@ta, :delete_captions)).to be true
          end

          it "does allow course non-admin users to delete_captions to attachments if they don't have manage_course_content_delete but own media object" do
            RoleOverride.create!(
              permission: "manage_course_content_delete",
              enabled: false,
              role: ta_role,
              account: @course.root_account
            )
            expect(@mo.attachment).to be_nil
            expect(@mo.grants_right?(@ta, :delete_captions)).to be true
          end

          it "does not allow course non-admin users to delete_captions to attachments if they don't have manage_course_content_delete" do
            @mo.user = user_factory
            RoleOverride.create!(
              permission: "manage_course_content_delete",
              enabled: false,
              role: ta_role,
              account: @course.root_account
            )
            expect(@mo.attachment).to be_nil
            expect(@mo.grants_right?(@ta, :delete_captions)).to be false
          end
        end
      end
    end

    context "when context_root_account is nil" do
      before do
        @mo = media_object
        @mo.update!(
          user: nil,
          context: nil
        )
        @not_logged_in_user = nil
      end

      it "does not error when context_root_account is nil" do
        expect { @mo.grants_right?(@not_logged_in_user, :add_captions) }.not_to raise_error
        expect { @mo.grants_right?(@not_logged_in_user, :delete_captions) }.not_to raise_error
        expect(@mo.grants_right?(@not_logged_in_user, :add_captions)).to be false
        expect(@mo.grants_right?(@not_logged_in_user, :delete_captions)).to be false
      end
    end
  end

  describe ".add_media_files" do
    before do
      @attachment = Attachment.new
      @kaltura_media_file_handler = double("KalturaMediaFileHandler")
      allow(KalturaMediaFileHandler).to receive(:new).and_return(@kaltura_media_file_handler)
    end

    it "delegates to the KalturaMediaFileHandler to make a bulk upload to kaltura" do
      wait_for_completion = true
      expect(@kaltura_media_file_handler).to receive(:add_media_files).with([@attachment], wait_for_completion).and_return(:retval)
      expect(MediaObject.add_media_files(@attachment, wait_for_completion)).to eq :retval
    end

    it "doesn't try to upload when all attachments have media objects already" do
      @attachment.media_entry_id = media_object.media_id

      expect(@kaltura_media_file_handler).not_to receive(:add_media_files)
      MediaObject.add_media_files(@attachment, false)
    end
  end

  describe ".create_attachment" do
    before :once do
      @media_object = MediaObject.create!(
        context: @course,
        title: "uploaded_video.mp4",
        media_id: "m-somejunkhere",
        media_type: "video"
      )
    end

    it "creates the corresponding attachment" do
      att = @media_object.attachment
      expect(att).to be_hidden
      expect(att.folder.name).to eq "Uploaded Media"
      expect(att[:media_entry_id]).to eql @media_object[:media_id]
    end

    it "defaults the usage rights if the root account requires it" do
      @course.update(usage_rights_required: true)
      @media_object = MediaObject.create!(
        context: @course,
        title: "usage_video.mp4",
        media_id: "m-usage",
        media_type: "video"
      )
      att = @media_object.attachment
      expect(att.usage_rights).to be_present
      expect(att.usage_rights.use_justification).to eq "own_copyright"
    end
  end

  describe ".process_retrieved_details" do
    before :once do
      @mock_entry = {
        name: "Kaltura Title",
        duration: 30,
        plays: 0,
        download_url: "https://google.com"
      }
      @media_type = "video"
      @assets = []

      @media_object = MediaObject.create!(
        context: @course,
        title: "uploaded_video.mp4",
        media_id: "m-somejunkhere",
        media_type: "video"
      )
    end

    before do
      @mock_kaltura = double("CanvasKaltura::ClientV3")
      allow(CanvasKaltura::ClientV3).to receive(:new).and_return(@mock_kaltura)
      allow(@mock_kaltura).to receive_messages(startSession: nil,
                                               media_sources: [{ height: "240",
                                                                 bitrate: "382",
                                                                 isOriginal: "0",
                                                                 width: "336",
                                                                 content_type: "video/mp4",
                                                                 containerFormat: "isom",
                                                                 url: "https://kaltura.example.com/some/url",
                                                                 size: "204",
                                                                 fileExt: "mp4" }],
                                               mediaGet: media_object,
                                               mediaTypeToSymbol: "video",
                                               flavorAssetGetByEntryId: [])
    end

    it "keeps the current title if already set" do
      mo = @media_object
      mo.title = "Canvas Title"
      mo.save!

      mo.process_retrieved_details(@mock_entry, @media_type, @assets)
      expect(mo.title).to eq "Canvas Title"
    end

    it "uses the kaltura title if no current title" do
      mo = @media_object
      mo.title = ""
      mo.save!

      mo.process_retrieved_details(@mock_entry, @media_type, @assets)
      expect(mo.title).to eq "Kaltura Title"
    end

    it "ensures retrieve_details adds '/' to media_type" do
      mo = @media_object
      mo.retrieve_details
      expect(mo.media_type).to eql "video/*"
    end

    it "doesn't add '/' to media_type if blank" do
      allow(@mock_kaltura).to receive(:mediaTypeToSymbol).and_return("")
      mo = @media_object
      mo.retrieve_details
      expect(mo.media_type).to eql("")
    end

    it "doesn't create an attachment if is one" do
      expect { @media_object.process_retrieved_details(@mock_entry, @media_type, @assets) }.not_to change { Attachment.count }
    end

    it "creates an attachment if there isn't one and there should be" do
      @media_object.attachment.update(media_entry_id: "maybe")
      @media_object.update(attachment_id: nil)
      @media_object.process_retrieved_details(@mock_entry, @media_type, @assets)
      att = @media_object.reload.attachment
      expect(att.folder.name).to eq "Uploaded Media"
      expect(att[:media_entry_id]).to eql @media_object[:media_id]
    end

    it "doesn't mark the attachment as processed until media_sources exist" do
      allow(@mock_kaltura).to receive(:media_sources).and_return([])
      @media_object.process_retrieved_details(@mock_entry, @media_type, @assets)
      expect(@media_object.attachment.workflow_state).to eq("pending_upload")
    end

    it "marks the attachment as processed when media_sources exist" do
      @media_object.process_retrieved_details(@mock_entry, @media_type, @assets)
      expect(@media_object.attachment.reload.workflow_state).to eq("processed")
    end

    it "marks the correct attachment as processed if one is specified" do
      att = attachment_model
      @media_object.current_attachment = att
      @media_object.process_retrieved_details(@mock_entry, @media_type, @assets)
      att.reload
      expect(@media_object.attachment.reload.workflow_state).to eq("pending_upload")
      expect(att.workflow_state).to eq("processed")
    end

    it "doesn't recreate deleted attachments" do
      @media_object.attachment.destroy
      expect { @media_object.reload.process_retrieved_details(@mock_entry, @media_type, @assets) }.not_to change { Attachment.count }
      expect(Attachment.find_by(media_entry_id: @media_object.media_id).file_state).to eq "deleted"
    end
  end

  describe ".guaranteed_title" do
    before :once do
      @mo = media_object_model
      @mo.title = nil
      @mo.user_entered_title = nil
    end

    it "returns 'Untitled' if there is no title" do
      expect(@mo.guaranteed_title).to eq "Untitled"
    end

    it "returns the title if available" do
      @mo.title = "The title"
      expect(@mo.guaranteed_title).to eq "The title"
    end

    it "returns the user_entered_title if available" do
      @mo.user_entered_title = "User title"
      expect(@mo.guaranteed_title).to eq "User title"
    end
  end

  describe "#attachments_by_media_id" do
    it "returns attachments with the given media_id" do
      attachment = media_object.attachment
      other_attachment = attachment_model(media_entry_id: media_object.media_id)
      attachment_model(media_entry_id: "something else")
      expect(media_object.attachments_by_media_id).to match_array([attachment, other_attachment])
    end

    it "returns soft-deleted attachments with the given media_id" do
      attachment = media_object.attachment
      attachment.destroy
      other_attachment = attachment_model(media_entry_id: media_object.media_id)
      attachment_model(media_entry_id: "something else")
      expect(media_object.attachments_by_media_id).to match_array([attachment, other_attachment])
    end
  end

  context "validations" do
    it "validates auto_caption_status" do
      expect do
        MediaObject.create!(
          context: @course,
          title: "uploaded_video.mp4",
          media_id: "m-somejunkhere",
          media_type: "video",
          auto_caption_status: "non_existent_status"
        )
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect do
        MediaObject.create!(
          context: @course,
          title: "uploaded_video.mp4",
          media_id: "m-somejunkhere",
          media_type: "video",
          auto_caption_status: "failed_captions"
        )
      end.not_to raise_error
    end
  end
end
