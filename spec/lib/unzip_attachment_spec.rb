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
  def fixture_filename(filename)
    File.expand_path(File.join(File.dirname(__FILE__), %W(.. fixtures #{filename})))
  end

  def add_folder_to_course(name)
    folder_model :name => name
    @course.folders << @folder
    @course.save!
    @course.reload
  end

  before do
    course_model
    add_folder_to_course 'course files'
  end

  context "unzipping" do
    let(:filename) { fixture_filename('attachments.zip') }
    let(:unzipper) { UnzipAttachment.new( :course => @course, :filename => filename) }

    it "should store a course, course_files_folder, and filename" do
      unzipper.course.should eql(@course)
      unzipper.filename.should eql(filename)
      unzipper.course_files_folder.should eql(@folder)
    end

    it "should be able to take a root_directory argument" do
      add_folder_to_course('a special folder')
      root_zipper = UnzipAttachment.new(:course => @course, :filename => filename, :root_directory => @folder)
      root_zipper.course_files_folder.should eql(@folder)
    end

    describe 'after processing' do
      before { unzipper.process; @course.reload }

      let(:first_attachment) { @course.attachments.find_by_display_name('first_entry.txt') }
      let(:second_attachment) { @course.attachments.find_by_display_name('second_entry.txt') }

      it "should unzip the file, create folders, and stick the contents of the zipped file as attachments in the folders" do
        first_attachment.should_not be_nil
        first_attachment.folder.name.should eql('course files')
        second_attachment.should_not be_nil
        second_attachment.folder.full_name.should eql('course files/adir')
        @course.folders.find_by_full_name('course files/adir').should_not be_nil
      end

      it "should be able to overwrite files in a folder on the database" do
        # Not overwriting FileInContext.attach, so we're actually attaching the files now.
        # The identical @us.process guarantees that every file attached the second time 
        # overwrites a file that was already there.
        unzipper.process
        @course.reload

        attachment_group_1 = @course.attachments.find_all_by_display_name('first_entry.txt')
        attachment_group_1.size.should eql(2)
        attachment_group_1.any?{|a| a.file_state == 'deleted' }.should eql(true)
        attachment_group_1.any?{|a| a.file_state == 'available' }.should eql(true)

        attachment_group_2 = @course.attachments.find_all_by_display_name('second_entry.txt')
        attachment_group_2.size.should eql(2)
        attachment_group_2.any?{|a| a.file_state == 'deleted' }.should eql(true)
        attachment_group_2.any?{|a| a.file_state == 'available' }.should eql(true)
      end

      it "should update attachment items in modules when overwriting their files via zip upload" do
        context_module = @course.context_modules.create!(:name => "teh module")
        attachment_tag = context_module.add_item(:id => first_attachment.id, :type => 'attachment')

        unzipper.process
        first_attachment.reload
        first_attachment.file_state.should == 'deleted'

        new_attachment = @course.attachments.active.find_by_display_name!('first_entry.txt')
        new_attachment.id.should_not == first_attachment.id

        attachment_tag.reload
        attachment_tag.should be_active
        attachment_tag.content_id.should == new_attachment.id
      end
    end

    it "should update progress as it goes" do
      progress = nil
      unzipper.progress_proc = Proc.new { |pct| progress = pct }
      unzipper.process
      progress.should_not be_nil
    end

    it "should import files alphabetically" do
      filename = fixture_filename('alphabet_soup.zip')
      Zip::File.open(filename) do |zip|
        # make sure the files aren't read from the zip in alphabetical order (so it's not alphabetized by chance)
        zip.entries.map(&:name).should eql(%w(f.txt d/e.txt d/d.txt c.txt b.txt a.txt))
      end

      ua = UnzipAttachment.new(:course => @course, :filename => filename)
      ua.process

      @course.attachments.count.should == 6
      %w(a b c d e f).each_with_index do |letter, index|
        @course.attachments.find_by_position(index).display_name.should == "#{letter}.txt"
      end
    end

    it "should not fall over when facing a filename starting with ~" do
      filename = fixture_filename('tilde.zip')
      ua = UnzipAttachment.new(:course => @course, :filename => filename)
      lambda { ua.process }.should_not raise_error
      @course.attachments.map(&:display_name).should == ['~tilde']
    end

    describe 'validations' do

      let(:filename) { fixture_filename('huge_zip.zip') }

      it 'errors when the number of files in the zip exceed the configured limit' do
        current_setting = Setting.get('max_zip_file_count', '100000')
        Setting.set('max_zip_file_count', '9')
        lambda{ unzipper.process }.should raise_error(ArgumentError, "Zip File cannot have more than 9 entries")
        Setting.set('max_zip_file_count', current_setting)
      end

      it 'errors when the file quotas push the context over its quota' do
        Attachment.stubs(:get_quota).returns({:quota => 5000, :quota_used => 0})
        lambda{ unzipper.process }.should raise_error(Attachment::OverQuotaError, "Zip file would exceed quota limit")
      end

      it 'should be able to rescue the file quota error' do
        Attachment.stubs(:get_quota).returns({:quota => 5000, :quota_used => 0})
        unzipper.process rescue nil
      end
    end

    describe 'zip bomb mitigation' do
      # unzip -l output for this file:
      #  Length     Date   Time    Name
      # --------    ----   ----    ----
      #       12  02-05-14 16:03   a
      #       18  02-05-14 16:03   b
      #       70  02-05-14 16:05   c   <-- this is a lie.  the file is really 10K
      #       19  02-05-14 16:03   d
      let(:filename) { fixture_filename('zipbomb.zip') }

      it 'double-checks the extracted file sizes in case the central directory lies' do
        Attachment.stubs(:get_quota).returns({:quota => 5000, :quota_used => 0})
        lambda{ unzipper.process }.should raise_error(Attachment::OverQuotaError)
        # a and b should have been attached
        # but we should have bailed once c ate the remaining quota
        @course.attachments.count.should eql 2
      end

      it "doesn't interfere when the quota is 0 (unlimited)" do
        Attachment.stubs(:get_quota).returns({:quota => 0, :quota_used => 0})
        lambda{ unzipper.process }.should_not raise_error
        @course.attachments.count.should eql 4
      end

      it "lets incorrect central directory size slide if the quota isn't exceeded" do
        Attachment.stubs(:get_quota).returns({:quota => 15000, :quota_used => 0})
        lambda{ unzipper.process }.should_not raise_error
        @course.attachments.count.should eql 4
      end
    end

  end

  context "scribdable files" do
    before do
      ScribdAPI.stubs(:config).returns({ key: "a", secret: "b" })
      scribd_mime_type_model(:extension => 'docx')
    end

    def job_queue_size
      Delayed::Job.strand_size('scribd')
    end

    def process_file(name, opts={})
      filename = fixture_filename(name)
      opts = opts.merge(:course => @course, :filename => filename)
      UnzipAttachment.new(opts).process
    end

    it "should not queue any scribd jobs if there are not any scribdable attachments" do
      process_file('attachments-none-scribdable.zip')
      job_queue_size.should == 0
    end

    it "should not queue a scribd job by default" do
      process_file('attachments-scribdable.zip')
      job_queue_size.should == 0
    end

    it "should queue a scribd job if there is a scribdable attachment" do
      process_file('attachments-scribdable.zip', {:queue_scribd => true})
      job_queue_size.should == 1
    end
  end
end

