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
      course
      mo = factory_with_protected_attributes(MediaObject, :media_id => '0_abcdefgh', :old_media_id => '1_01234567', :context => @course)

      MediaObject.by_media_id('0_abcdefgh').first.should == mo
      MediaObject.by_media_id('1_01234567').first.should == mo
    end

    it "should raise an error if someone tries to use find_by_media_id" do
      lambda { MediaObject.find_by_media_id('fjdksl') }.should raise_error
    end
  end

  describe ".build_media_objects" do
    it "should delete attachments created temporarily for import" do
      course
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
      @a1.reload.file_state.should == 'deleted'
      @a2.reload.file_state.should == 'available'
    end

    it "should build media objects from attachment_id" do
      course
      @a1 = attachment_model(:context => @course, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      @a2 = attachment_model(:context => @course, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      @a3 = attachment_model(:context => @course, :uploaded_data => stub_file_data('video1.mp4', nil, 'video/mp4'))
      data = {
          :entries => [
              { :entryId => "test", :originalId => %Q[{"context_code":"context", "attachment_id": "#{@a2.id}"} ]},
              { :entryId => "test2", :originalId => "#{@a1.id}" },
              { :entryId => "test3", :originalId => @a3.id },
          ],
      }
      MediaObject.create!(:context => user, :media_id => "test")
      MediaObject.create!(:context => user, :media_id => "test2")
      MediaObject.create!(:context => user, :media_id => "test3")
      MediaObject.build_media_objects(data, Account.default.id)
      media_object = MediaObject.find_by_attachment_id(@a1.id)
      media_object.should_not be_nil
      media_object = MediaObject.find_by_attachment_id(@a2.id)
      media_object.should_not be_nil
      media_object = MediaObject.find_by_attachment_id(@a3.id)
      media_object.should_not be_nil
    end
  end

  describe ".ensure_media_object" do
    it "should not create if the media object exists already" do
      MediaObject.create!(:context => user, :media_id => "test")
      expect {
        MediaObject.ensure_media_object("test", {})
      }.to change { Delayed::Job.jobs_count(:future) }.by(0)
    end

    it "should not create if the media id doesn't exist in kaltura" do
      MediaObject.expects(:media_id_exists?).with("test").returns(false)
      expect {
        MediaObject.ensure_media_object("test", {})
        run_jobs
      }.to change { Delayed::Job.jobs_count(:future) }.by(0)
    end

    it "should create the media object" do
      MediaObject.expects(:media_id_exists?).with("test").returns(true)
      expect {
        MediaObject.ensure_media_object("test", { :context => user })
        run_jobs
      }.to change { Delayed::Job.jobs_count(:future) }.by(1)
      obj = MediaObject.by_media_id("test").first
      obj.context.should == @user
    end
  end

  context "permissions" do
    context "captions" do
      it "should allow course admin users to add_captions to userless objects" do
        course_with_teacher
        mo = media_object

        mo.user = nil
        mo.save!

        mo.grants_right?(@teacher, :add_captions).should == true
        mo.grants_right?(@teacher, :delete_captions).should == true
      end

      it "should not allow course non-admin users to add_captions to userless objects" do
        course_with_student
        mo = media_object

        mo.user = nil
        mo.save!

        mo.grants_right?(@student, :add_captions).should == false
        mo.grants_right?(@student, :delete_captions).should == false
      end

      it "should allow course non-admin users to add_captions to objects belonging to them" do
        course_with_student
        mo = media_object

        mo.user = @student
        mo.save!

        mo.grants_right?(@student, :add_captions).should == true
        mo.grants_right?(@student, :delete_captions).should == true
      end

      it "should not allow course non-admin users to add_captions to objects not belonging to them" do
        course_with_student
        mo = media_object
        user

        mo.user = @user
        mo.save!

        mo.grants_right?(@student, :add_captions).should == false
        mo.grants_right?(@student, :delete_captions).should == false
      end
    end
  end

  describe ".add_media_files" do
    it "should work for user context" do
      stub_kaltura
      user
      attachment_obj_with_context(@user, user: @user)
      CanvasKaltura::ClientV3.any_instance.stubs(:startSession).returns(nil)
      CanvasKaltura::ClientV3.any_instance.stubs(:bulkUploadAdd).returns({})
      MediaObject.add_media_files(@attachment, false)
    end

    context "partner_data" do
      let(:uploading_user) { user }
      let(:attachment_context) { uploading_user }
      let(:attachment) { attachment_obj_with_context(attachment_context, user: uploading_user) }
      let(:kaltura_config) { {} }
      let(:kaltura_client) { mock('CanvasKaltura::ClientV3') }
      let(:wait_for_completion) { false }
      let(:files_sent_to_kaltura) { [] }

      before do
        CanvasKaltura::ClientV3.stubs(:config).returns(kaltura_config)
        CanvasKaltura::ClientV3.expects(:new).returns(kaltura_client)

        kaltura_client.stubs(:startSession)
        kaltura_client.stubs(:bulkUploadAdd).with do |files|
          files_sent_to_kaltura.concat(files)
        end.returns({})
      end

      it "always includes basic info about attachment and context" do
        MediaObject.add_media_files([attachment], wait_for_completion)

        partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
        partner_data_json.should == {
          "attachment_id" => attachment.id.to_s,
          "context_source" => "file_upload",
          "root_account_id" => attachment.root_account_id.to_s,
        }
      end

      context "when the kaltura settings for the account include 'Write SIS data to Kaltura'" do
        let(:kaltura_config) { { 'kaltura_sis' => '1' }}

        it "adds a context_code to the partner_data sent to kaltura" do
          MediaObject.add_media_files([attachment], wait_for_completion)

          partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
          partner_data_json['context_code'].should == "user_#{attachment_context.id}"
        end

        context "and the context has a root_account attached" do
          let(:attachment_context) { course_with_teacher(user: uploading_user).course }

          context "and the user has a pseudonym with a user_sis_id attached" do
            let(:uploading_user) { user_with_pseudonym }

            before do
              uploading_user.pseudonym.sis_user_id = "some_id_from_sis"
              uploading_user.pseudonym.save
            end

            it "adds sis_user_id to partner_data" do
              MediaObject.add_media_files([attachment], wait_for_completion)

              partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
              partner_data_json["sis_user_id"].should == "some_id_from_sis"
            end
          end

          context 'and the context has a sis_source_id attached' do
            before do
              attachment_context.sis_source_id = "gooboo"
              attachment_context.save!
            end

            it "adds sis_source_id to partner_data" do
              MediaObject.add_media_files([attachment], wait_for_completion)

              partner_data_json = JSON.parse(files_sent_to_kaltura.first[:partner_data])
              partner_data_json["sis_source_id"].should == "gooboo"
            end
          end
        end
      end
    end
  end
end
