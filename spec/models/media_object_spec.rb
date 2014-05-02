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
  end
end
