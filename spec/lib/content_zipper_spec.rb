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
      @user.update_attributes!(:sortable_name => 'some_999_, _1234_guy')
      submission_model :user => @user
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = @teacher
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = @assignment
      attachment.save!
      ContentZipper.process_attachment(attachment, @teacher)
      attachment.reload
      attachment.workflow_state.should == 'zipped'
      Zip::ZipFile.foreach(attachment.full_filename) do |f|
        if f.file?
          f.name.should =~ /some-999-_-1234-guy/
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
      ContentZipper.process_attachment(attachment, @teacher)
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
      ContentZipper.process_attachment(attachment, @ta)
      attachment.reload
      # no submissions
      attachment.workflow_state.should == 'errored'
    end
  end

  describe "assignment_zip_filename" do
    it "should use use course and title slugs to keep filename length down" do
      course(:active_all => true)
      @course.short_name = "a" * 31
      @course.save!
      assignment_model(:course => @course, :title => "b" * 31)

      zipper = ContentZipper.new
      filename = zipper.assignment_zip_filename(@assignment)
      filename.should match /#{@course.short_name_slug}/
      filename.should match /#{@assignment.title_slug}/
      filename.should_not match /#{@course.short_name}/
      filename.should_not match /#{@assignment.title}/
    end
  end

  describe "zip_folder" do
    context "checking permissions" do
      before(:each) do
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

        @attachment = Attachment.new(:display_name => 'my_download.zip')
        @attachment.workflow_state = 'to_be_zipped'
        @attachment.context = folder
      end

      def zipped_files_for_user(user=nil, check_user=true)
        @attachment.user_id = user.id if user
        @attachment.save!
        ContentZipper.process_attachment(@attachment, user, :check_user => check_user)
        names = []
        @attachment.reload
        Zip::ZipFile.foreach(@attachment.full_filename) {|f| names << f.name if f.file? }
        names.sort
      end

      context "in a private course" do
        it "should give logged in students some files" do
          zipped_files_for_user(@user).should == ['visible.png', 'visible/sub-vis.png'].sort
        end

        it "should give logged in teachers all files" do
          zipped_files_for_user(@teacher).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end

        it "should give logged out people no files" do
          zipped_files_for_user(nil).should == []
        end
        
        it "should give all files if check_user=false" do
          zipped_files_for_user(nil, false).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end
      end

      context "in a public course" do
        before(:each) do
          @course.is_public = true
          @course.save!
        end

        it "should give logged in students some files" do
          zipped_files_for_user(@user).should == ['visible.png', 'visible/sub-vis.png'].sort
        end

        it "should give logged in teachers all files" do
          zipped_files_for_user(@teacher).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end

        it "should give logged out people the same thing as students" do
          zipped_files_for_user(nil).should == ['visible.png', 'visible/sub-vis.png'].sort
        end

        it "should give all files if check_user=false" do
          zipped_files_for_user(nil, false).should == ["locked/sub-locked-vis.png", "hidden/sub-hidden.png", "hidden.png", "visible.png", "visible/sub-locked.png", "visible/sub-vis.png", "locked.png"].sort
        end
      end
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

    it "should use the display name" do
      course_with_student(:active_all => true)
      folder = Folder.root_folders(@course).first
      attachment_model(:uploaded_data => stub_png_data('hidden.png'), :content_type => 'image/png', :folder => folder, :display_name => 'otherfile.png')
      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user_id = @user.id
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = folder
      attachment.save!
      ContentZipper.process_attachment(attachment, @user)
      attachment.reload
      names = []
      Zip::ZipFile.foreach(attachment.full_filename) {|f| names << f.name if f.file? }
      names.should == ['otherfile.png']
    end
  end

  describe "zip_eportfolio" do
    it "should sanitize the zip file name" do
      user = User.create!
      eportfolio = user.eportfolios.create!(:name => '/../../etc/passwd')

      attachment = Attachment.new(:display_name => 'my_download.zip')
      attachment.user = user
      attachment.workflow_state = 'to_be_zipped'
      attachment.context = eportfolio
      attachment.save!
      Dir.expects(:mktmpdir).once.yields('/tmp')
      Zip::ZipFile.expects(:open).once.with('/tmp/etcpasswd.zip', Zip::ZipFile::CREATE)
      ContentZipper.process_attachment(attachment, user)
    end
  end
end
