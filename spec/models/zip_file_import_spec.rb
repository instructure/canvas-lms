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

describe ZipFileImport do
  it "should process asynchronously into a folder" do
    course_with_teacher
    folder = Folder.root_folders(@course).first
    zf = @course.zip_file_imports.create!(:folder => folder)
    zf.attachment = attachment_model(:uploaded_data => stub_file_data("attachments.zip", File.read(Rails.root+"spec/fixtures/attachments.zip"), "application/zip"))
    zf.attachment.update_attributes(:context => zf)
    zf.save!
    zf.process
    expect(zf.reload.progress).to be_nil
    expect(zf.state).to eq :created
    run_jobs
    expect(zf.reload.state).to eq :imported
    expect(zf.progress).to eq 1.0
    expect(folder.attachments.active.map(&:display_name)).to eq ["first_entry.txt"]
    expect(folder.sub_folders.active.count).to eq 1
    sub = folder.sub_folders.active.first
    expect(sub.name).to eq "adir"
    expect(sub.attachments.active.map(&:display_name)).to eq ["second_entry.txt"]
  end
end

