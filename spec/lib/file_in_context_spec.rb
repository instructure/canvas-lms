# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

describe FileInContext do
  before do
    course_model
    folder_model(name: "course files")
    @course.folders << @folder
    @course.save!
    @course.reload
  end

  context "#attach" do
    it "creates files with the supplied filename escaped for s3" do
      s3_storage!

      filename = File.expand_path(File.join(__dir__, "../fixtures/files/escaping_test[0].txt"))
      attachment = FileInContext.attach(@course, filename, folder: @folder)
      allow(attachment).to receive(:filename=) do |new_name|
        write_attribute(:filename, sanitize_filename(new_name))
      end
      expect(attachment.filename).to eq "escaping_test%5B0%5D.txt"
      expect(attachment).to be_published
    end

    describe "duplication handling" do
      before do
        @filename = File.expand_path(File.join(__dir__, "../fixtures/files/a_file.txt"))
        @md5 = "2b00042f7481c7b056c4b410d28f33cf"
        @sha512 = "8d3fffddf79e9a232ffd19f9ccaa4d6b37a6a243dbe0f23137b108a043d9da13121a9b505c804956b22e93c7f93969f4a7ba8ddea45bf4aab0bebc8f814e0991"
      end

      it "doesn't duplicate attachments if the right hash is provided" do
        FileInContext.attach(@course, @filename, folder: @folder)
        FileInContext.attach(@course, @filename, folder: @folder, md5: @md5)
        expect(@course.attachments.count).to eq 1
      end

      it "doesn't duplicate attachments by comparing md5 hashes when sha512 finds nothing" do
        attachment = FileInContext.attach(@course, @filename, folder: @folder)
        attachment.update(md5: @md5)

        # Making sure no additions to before blocks mess this up
        expect(@course.attachments.find_by(md5: @sha512)).to be_falsey

        FileInContext.attach(@course, @filename, folder: @folder, md5: @sha512)
        expect(@course.attachments.count).to eq 1
      end

      it "doesn't duplicate attachments by comparing sha512 hashes when md5 finds nothing" do
        attachment = FileInContext.attach(@course, @filename, folder: @folder)
        attachment.update(md5: @sha512)

        # Making sure no additions to before blocks mess this up
        expect(@course.attachments.find_by(md5: @md5)).to be_falsey

        FileInContext.attach(@course, @filename, folder: @folder, md5: @md5)
        expect(@course.attachments.count).to eq 1
      end
    end

    describe "usage rights required" do
      before do
        @course.usage_rights_required = true
        @course.save!
        @filename = File.expand_path(File.join(File.dirname(__FILE__), %w[.. fixtures files a_file.txt]))
      end

      it "creates files in unpublished state" do
        attachment = FileInContext.attach(@course, @filename)
        expect(attachment).not_to be_published
      end

      it "creates files as published in non-course context" do
        assignment = @course.assignments.create!
        attachment = FileInContext.attach(assignment, @filename)
        expect(attachment).to be_published
      end
    end
  end
end
