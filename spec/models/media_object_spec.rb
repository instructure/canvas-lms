#
# Copyright (C) 2011 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper.rb')

describe MediaObject do
  context "loading with legacy support" do
    it "should load by either media_id or old_media_id" do
      course_factory
      mo = factory_with_protected_attributes(MediaObject, :media_id => '0_abcdefgh', :old_media_id => '1_01234567', :context => @course)

      expect(MediaObject.by_media_id('0_abcdefgh').first).to eq mo
      expect(MediaObject.by_media_id('1_01234567').first).to eq mo
    end

    it "should raise an error if someone tries to use find_by_media_id" do
      expect { MediaObject.find_by_media_id('fjdksl') }.to raise_error
    end
  end

  describe ".build_media_objects" do
    it "should delete attachments created temporarily for import" do
      course_factory
      folder = Folder.assert_path(CC::CCHelper::MEDIA_OBJECTS_FOLDER, @course)
      @a1 = attachment_model(:folder => folder, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      @a2 = attachment_model(:context => @course, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      data = {
        :entries => [
          { :originalId => @a1.id, },
          { :originalId => @a2.id, },
        ],
      }
      MediaObject.build_media_objects(data, Account.default.id)
      expect(@a1.reload.file_state).to eq 'deleted'
      expect(@a2.reload.file_state).to eq 'available'
    end

    it "should build media objects from attachment_id" do
      course_factory
      @a1 = attachment_model(:context => @course, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      @a3 = attachment_model(:context => @course, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      @a4 = attachment_model(:context => @course, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      data = {
          :entries => [
              { :entryId => "test2", :originalId => "#{@a1.id}" },
              { :entryId => "test3", :originalId => @a3.id },
              { :entryId => "test4", :originalId => "attachment_id=#{@a4.id}" }
          ],
      }
      MediaObject.create!(:context => user_factory, :media_id => "test")
      MediaObject.create!(:context => user_factory, :media_id => "test2")
      MediaObject.create!(:context => user_factory, :media_id => "test3")
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
    it "should not create if the media object exists already" do
      MediaObject.create!(:context => user_factory, :media_id => "test")
      MediaObject.expects(:create!).never
      MediaObject.ensure_media_object("test", {})
    end

    it "should not create if the media id doesn't exist in kaltura" do
      MediaObject.expects(:media_id_exists?).with("test").returns(false)
      MediaObject.expects(:create!).never
      MediaObject.ensure_media_object("test", {})
      run_jobs
    end

    it "should create the media object" do
      MediaObject.expects(:media_id_exists?).with("test").returns(true)
      MediaObject.ensure_media_object("test", { :context => user_factory })
      run_jobs
      obj = MediaObject.by_media_id("test").first
      expect(obj.context).to eq @user
    end
  end

  describe '#transcoded_details' do
    it 'returns the mp3 info' do
      mo = MediaObject.create!(:context => user_factory, :media_id => "test")
      expect(mo.transcoded_details).to be_nil
      mo.data = { extensions: { mov: { id: "t-xxx" } } }
      expect(mo.transcoded_details).to be_nil
      mo.data = { extensions: { mp3: { id: "t-yyy" } } }
      expect(mo.transcoded_details).to eq(id: "t-yyy")
    end

    it 'returns the mp4 info' do
      mo = MediaObject.create!(:context => user_factory, :media_id => "test")
      mo.data = { extensions: { mp4: { id: "t-yyy" } } }
      expect(mo.transcoded_details).to eq(id: "t-yyy")
    end
  end

  describe '#retrieve_details_ensure_codecs' do
    it "retries later when the transcode isn't available" do
      Timecop.freeze do
        mo = MediaObject.create!(:context => user_factory, :media_id => "test")
        mo.expects(:retrieve_details)
        mo.expects(:send_at).with(5.minutes.from_now, :retrieve_details_ensure_codecs, 2)
        mo.retrieve_details_ensure_codecs(1)
      end
    end

    it "verifies existence of the transcoded details" do
      mo = MediaObject.create!(:context => user_factory, :media_id => "test")
      mo.data = { extensions: { mp4: { id: "t-yyy" } } }
      mo.expects(:retrieve_details)
      mo.expects(:send_at).never
      mo.retrieve_details_ensure_codecs(1)
    end
  end

  context "permissions" do
    context "captions" do
      it "should allow course admin users to add_captions to userless objects" do
        course_with_teacher
        mo = media_object

        mo.user = nil
        mo.save!

        expect(mo.grants_right?(@teacher, :add_captions)).to eq true
        expect(mo.grants_right?(@teacher, :delete_captions)).to eq true
      end

      it "should not allow course non-admin users to add_captions to userless objects" do
        course_with_student
        mo = media_object

        mo.user = nil
        mo.save!

        expect(mo.grants_right?(@student, :add_captions)).to eq false
        expect(mo.grants_right?(@student, :delete_captions)).to eq false
      end

      it "should allow course non-admin users to add_captions to objects belonging to them" do
        course_with_student
        mo = media_object

        mo.user = @student
        mo.save!

        expect(mo.grants_right?(@student, :add_captions)).to eq true
        expect(mo.grants_right?(@student, :delete_captions)).to eq true
      end

      it "should not allow course non-admin users to add_captions to objects not belonging to them" do
        course_with_student
        mo = media_object
        user_factory

        mo.user = @user
        mo.save!

        expect(mo.grants_right?(@student, :add_captions)).to eq false
        expect(mo.grants_right?(@student, :delete_captions)).to eq false
      end
    end
  end

  describe ".add_media_files" do
    it "delegates to the KalturaMediaFileHandler to make a bulk upload to kaltura" do
      kaltura_media_file_handler = mock('KalturaMediaFileHandler')
      KalturaMediaFileHandler.expects(:new).returns(kaltura_media_file_handler)

      attachments = [ Attachment.new ]
      wait_for_completion = true

      kaltura_media_file_handler.expects(:add_media_files).with(attachments, wait_for_completion).returns(:retval)

      expect(MediaObject.add_media_files(attachments, wait_for_completion)).to eq :retval
    end
  end
end
