# Copyright (C) 2017 - present Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper.rb')

describe Attachments::GarbageCollector::FolderExports do
  let_once(:course) { Account.default.courses.create! }
  let_once(:folder) { Folder.root_folders(course).first }
  let_once(:att) do
    attachment_model(
      context: folder,
      folder: nil,
      uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
    )
  end

  it "destroys content and deletes objects" do
    expect(FileUtils).to receive(:rm).with(att.full_filename)

    Attachments::GarbageCollector::FolderExports.delete_content
    expect(att.reload).to be_deleted

    Attachments::GarbageCollector::FolderExports.delete_rows
    expect { att.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "destroys child attachments as well" do
    att2 = attachment_model(
      context: folder,
      folder: nil,
      root_attachment_id: att.id,
      uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
    )
    expect(att2.root_attachment_id).to eq att.id
    expect(FileUtils).to receive(:rm).with(att.full_filename)

    Attachments::GarbageCollector::FolderExports.delete_content
    expect(att.reload).to be_deleted
    expect(att2.reload).to be_deleted

    Attachments::GarbageCollector::FolderExports.delete_rows
    expect { att.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { att2.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "shifts child to be root if different context" do
    att2 = attachment_model(
      context: course,
      folder: nil,
      root_attachment_id: att.id,
      uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
    )
    expect(att2.root_attachment_id).to eq att.id
    expect(FileUtils).not_to receive(:rm).with(att.full_filename)

    Attachments::GarbageCollector::FolderExports.delete_content
    expect(att.reload).to be_deleted
    expect(att2.reload.root_attachment_id).to be_nil

    Attachments::GarbageCollector::FolderExports.delete_rows
    expect { att.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect(att2.reload).not_to be_deleted
  end
end
