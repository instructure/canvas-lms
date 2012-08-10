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
  end

  describe ".ensure_media_object" do
    it "should not create if the media object exists already" do
      MediaObject.create!(:context => user, :media_id => "test")
      expect {
        MediaObject.ensure_media_object("test", {})
      }.to change(Delayed::Job, :count).by(0)
    end

    it "should not create if the media id doesn't exist in kaltura" do
      MediaObject.expects(:media_id_exists?).with("test").returns(false)
      expect {
        MediaObject.ensure_media_object("test", {})
        run_jobs
      }.to change(MediaObject, :count).by(0)
    end

    it "should create the media object" do
      MediaObject.expects(:media_id_exists?).with("test").returns(true)
      expect {
        MediaObject.ensure_media_object("test", { :context => user })
        run_jobs
      }.to change(MediaObject, :count).by(1)
      obj = MediaObject.by_media_id("test").first
      obj.context.should == @user
    end
  end
end
