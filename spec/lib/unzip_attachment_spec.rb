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

describe UnzipAttachment do
  before do
    course_model
    folder_model(:name => 'course files')
    @course.folders << @folder
    @course.save!
    @course.reload
  end
  
  context "unzipping" do
    before do
      @filename = File.expand_path(File.join(File.dirname(__FILE__), %w(.. fixtures attachments.zip)))
      @ua = UnzipAttachment.new(:course => @course, :filename => @filename)
    end

    it "should store a course, course_files_folder, and filename" do
      @ua.course.should eql(@course)
      @ua.filename.should eql(@filename)
      @ua.course_files_folder.should eql(@folder)
    end

    it "should be able to take a root_directory argument" do
      folder_model(:name => "a special folder")
      @course.folders << @folder
      @course.save!
      @course.reload
      ua = UnzipAttachment.new(:course => @course, :filename => @filename, :root_directory => @folder)
      ua.course_files_folder.should eql(@folder)
      
      ua = UnzipAttachment.new(:course => @course, :filename => @filename, :root_directory => @folder)
      ua.course_files_folder.should eql(@folder)
      
    end

    it "should unzip the file, create folders, and stick the contents of the zipped file as attachments in the folders" do
      @ua.process

      @course.reload
      @course.attachments.find_by_display_name('first_entry.txt').should_not be_nil
      @course.attachments.find_by_display_name('first_entry.txt').folder.name.should eql('course files')

      @course.folders.find_by_full_name('course files/adir').should_not be_nil
      @course.attachments.find_by_display_name('second_entry.txt').should_not be_nil
      @course.attachments.find_by_display_name('second_entry.txt').folder.full_name.should eql('course files/adir')
    end

    it "should be able to overwrite files in a folder on the database" do
      # Not overwriting FileInContext.attach, so we're actually attaching the files now.
      # The identical @us.process guarantees that every file attached the second time 
      # overwrites a file that was already there.
      @ua.process
      lambda{@ua.process}.should_not raise_error
      @course.reload
      @course.attachments.find_all_by_display_name('first_entry.txt').size.should eql(2)
      @course.attachments.find_all_by_display_name('first_entry.txt').any?{|a| a.file_state == 'deleted' }.should eql(true)
      @course.attachments.find_all_by_display_name('first_entry.txt').any?{|a| a.file_state == 'available' }.should eql(true)
      @course.attachments.find_all_by_display_name('second_entry.txt').size.should eql(2)
      @course.attachments.find_all_by_display_name('second_entry.txt').any?{|a| a.file_state == 'deleted' }.should eql(true)
      @course.attachments.find_all_by_display_name('second_entry.txt').any?{|a| a.file_state == 'available' }.should eql(true)
    end

    it "should update progress as it goes" do
      progress = nil
      @ua.progress_proc = Proc.new { |pct|
        progress = pct
      }
      @ua.process
      progress.should_not be_nil
    end
  end

  context "scribdable files" do
    before do
      scribd_mime_type_model(:extension => 'docx')
    end

    it "should not queue any scribd jobs if there are not any scribdable attachments" do
      @filename = File.expand_path(File.join(File.dirname(__FILE__), %w(.. fixtures attachments-none-scribdable.zip)))
      @ua = UnzipAttachment.new(:course => @course, :filename => @filename)
      @ua.process
      Delayed::Job.count(:conditions => { :strand => 'scribd' }).should == 0
    end

    it "should queue a scribd job if there is a scribdable attachment" do
      @filename = File.expand_path(File.join(File.dirname(__FILE__), %w(.. fixtures attachments-scribdable.zip)))
      @ua = UnzipAttachment.new(:course => @course, :filename => @filename)
      @ua = UnzipAttachment.new(:course => @course, :filename => @filename)
      @ua.process
      Delayed::Job.count(:conditions => { :strand => 'scribd' }).should == 1
    end
  end
end

class G
  @@list = []
  def self.<<(val)
    @@list << val
  end

  def self.list
    @@list
  end
end
