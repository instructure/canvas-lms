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

describe ContentZipper do
  describe "zip_assignment" do
    it "should zip up online_url submissions" do
      course_with_student(:active_all => true)
      submission_model
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @teacher
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment)
      attachment.reload
      attachment.workflow_state.should == 'zipped'
      Zip::ZipFile.foreach(attachment.full_filename) do |f|
        if f.file?
          f.get_input_stream.read.should match(%r{This submission was a url, we're taking you to the url link now.})
          f.get_input_stream.read.should be_include("http://www.instructure.com/")
        end
      end
    end

    it "should zip up online_text_entry submissions" do
      course_with_student(:active_all => true)
      submission_model(:body => "hai this is my answer")
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @teacher
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment)
      attachment.reload
      attachment.workflow_state.should == 'zipped'
      Zip::ZipFile.foreach(attachment.full_filename) do |f|
        if f.file?
          f.get_input_stream.read.should be_include("hai this is my answer")
        end
      end
    end

    it "should only include submissions in the correct section " do
      course_with_student(:active_all => true)
      submission_model(:body => "hai this is my answer")
      @section = @course.course_sections.create!
      @ta = user_with_pseudonym(:active_all => 1)
      @course.enroll_user(@ta, "TaEnrollment", :limit_privileges_to_course_section => true, :section => @section)
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @ta
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment)
      attachment.reload
      # no submissions
      attachment.workflow_state.should == 'errored'
    end
  end

  describe "zip_folder" do
    it "should only zip up files/folders the user has access to" do
      course_with_student(:active_all => true)
      folder = Folder.root_folders(@course).first
      attachment_model(:uploaded_data => stub_png_data('hidden.png'), :content_type => 'image/png', :hidden => true, :folder => folder)
      attachment_model(:uploaded_data => stub_png_data('visible.png'), :content_type => 'image/png', :folder => folder)
      attachment_model(:uploaded_data => stub_png_data('locked.png'), :content_type => 'image/png', :folder => folder, :locked => true)
      hidden_folder = folder.sub_folders.create!(:context => @course, :name => 'hidden', :hidden => true)
      visible_folder = folder.sub_folders.create!(:context => @course, :name => 'visible')
      locked_folder = folder.sub_folders.create!(:context => @course, :name => 'locked', :locked => true)
      attachment_model(:uploaded_data => stub_png_data('sub-hidden.png'), :content_type => 'image/png', :folder => hidden_folder)
      attachment_model(:uploaded_data => stub_png_data('sub-vis.png'), :content_type => 'image/png', :folder => visible_folder)
      attachment_model(:uploaded_data => stub_png_data('sub-locked.png'), :content_type => 'image/png', :folder => visible_folder, :locked => true)
      attachment_model(:uploaded_data => stub_png_data('sub-locked-vis.png'), :content_type => 'image/png', :folder => locked_folder)

      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user_id = @user.id
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = folder
      attachment.save!
      ContentZipper.process_attachment(attachment, @user)
      names = []
      attachment.reload
      Zip::ZipFile.foreach(attachment.full_filename) do |f|
        names << f.name if f.file?
      end
      names.sort.should == ['visible.png', 'visible/sub-vis.png']
    end

    it "should not error on empty folders" do
      course_with_student(:active_all => true)
      folder = Folder.root_folders(@course).first
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user_id = @user.id
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = folder
      attachment.save!
      ContentZipper.process_attachment(attachment, @user)
      attachment.workflow_state.should == 'zipped'
    end
  end
end
