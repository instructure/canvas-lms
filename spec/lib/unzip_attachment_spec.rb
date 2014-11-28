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
      expect(unzipper.course).to eql(@course)
      expect(unzipper.filename).to eql(filename)
      expect(unzipper.course_files_folder).to eql(@folder)
    end

    it "should be able to take a root_directory argument" do
      add_folder_to_course('a special folder')
      root_zipper = UnzipAttachment.new(:course => @course, :filename => filename, :root_directory => @folder)
      expect(root_zipper.course_files_folder).to eql(@folder)
    end

    describe 'after processing' do
      before { unzipper.process; @course.reload }

      let(:first_attachment) { @course.attachments.where(display_name: 'first_entry.txt').first }
      let(:second_attachment) { @course.attachments.where(display_name: 'second_entry.txt').first }

      it "should unzip the file, create folders, and stick the contents of the zipped file as attachments in the folders" do
        expect(first_attachment).not_to be_nil
        expect(first_attachment.folder.name).to eql('course files')
        expect(second_attachment).not_to be_nil
        expect(second_attachment.folder.full_name).to eql('course files/adir')
        expect(@course.folders.where(full_name:'course files/adir')).to be_exists
      end

      it "should be able to overwrite files in a folder on the database" do
        # Not overwriting FileInContext.attach, so we're actually attaching the files now.
        # The identical @us.process guarantees that every file attached the second time 
        # overwrites a file that was already there.
        unzipper.process
        @course.reload

        attachment_group_1 = @course.attachments.where(display_name: 'first_entry.txt').to_a
        expect(attachment_group_1.size).to eql(2)
        expect(attachment_group_1.any?{|a| a.file_state == 'deleted' }).to eql(true)
        expect(attachment_group_1.any?{|a| a.file_state == 'available' }).to eql(true)

        attachment_group_2 = @course.attachments.where(display_name: 'second_entry.txt').to_a
        expect(attachment_group_2.size).to eql(2)
        expect(attachment_group_2.any?{|a| a.file_state == 'deleted' }).to eql(true)
        expect(attachment_group_2.any?{|a| a.file_state == 'available' }).to eql(true)
      end

      it "should update attachment items in modules when overwriting their files via zip upload" do
        context_module = @course.context_modules.create!(:name => "teh module")
        attachment_tag = context_module.add_item(:id => first_attachment.id, :type => 'attachment')

        unzipper.process
        first_attachment.reload
        expect(first_attachment.file_state).to eq 'deleted'

        new_attachment = @course.attachments.active.where(display_name: 'first_entry.txt').first
        expect(new_attachment.id).not_to eq first_attachment.id

        attachment_tag.reload
        expect(attachment_tag).to be_active
        expect(attachment_tag.content_id).to eq new_attachment.id
      end
    end

    it "should update progress as it goes" do
      progress = nil
      unzipper.progress_proc = Proc.new { |pct| progress = pct }
      unzipper.process
      expect(progress).not_to be_nil
    end

    it "should import files alphabetically" do
      filename = fixture_filename('alphabet_soup.zip')
      Zip::File.open(filename) do |zip|
        # make sure the files aren't read from the zip in alphabetical order (so it's not alphabetized by chance)
        expect(zip.entries.map(&:name)).to eql(%w(f.txt d/e.txt d/d.txt c.txt b.txt a.txt))
      end

      ua = UnzipAttachment.new(:course => @course, :filename => filename)
      ua.process

      expect(@course.attachments.count).to eq 6
      %w(a b c d e f).each_with_index do |letter, index|
        expect(@course.attachments.where(position: index).first.display_name).to eq "#{letter}.txt"
      end
    end

    it "should not fall over when facing a filename starting with ~" do
      filename = fixture_filename('tilde.zip')
      ua = UnzipAttachment.new(:course => @course, :filename => filename)
      expect { ua.process }.not_to raise_error
      expect(@course.attachments.map(&:display_name)).to eq ['~tilde']
    end

    describe 'validations' do

      let(:filename) { fixture_filename('huge_zip.zip') }

      it 'errors when the number of files in the zip exceed the configured limit' do
        current_setting = Setting.get('max_zip_file_count', '100000')
        Setting.set('max_zip_file_count', '9')
        expect{ unzipper.process }.to raise_error(ArgumentError, "Zip File cannot have more than 9 entries")
        Setting.set('max_zip_file_count', current_setting)
      end

      it 'errors when the file quotas push the context over its quota' do
        Attachment.stubs(:get_quota).returns({:quota => 5000, :quota_used => 0})
        expect{ unzipper.process }.to raise_error(Attachment::OverQuotaError, "Zip file would exceed quota limit")
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
        expect{ unzipper.process }.to raise_error(Attachment::OverQuotaError)
        # a and b should have been attached
        # but we should have bailed once c ate the remaining quota
        expect(@course.attachments.count).to eql 2
      end

      it "doesn't interfere when the quota is 0 (unlimited)" do
        Attachment.stubs(:get_quota).returns({:quota => 0, :quota_used => 0})
        expect{ unzipper.process }.not_to raise_error
        expect(@course.attachments.count).to eql 4
      end

      it "lets incorrect central directory size slide if the quota isn't exceeded" do
        Attachment.stubs(:get_quota).returns({:quota => 15000, :quota_used => 0})
        expect{ unzipper.process }.not_to raise_error
        expect(@course.attachments.count).to eql 4
      end
    end

  end
end
