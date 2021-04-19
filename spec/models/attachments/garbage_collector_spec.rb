# frozen_string_literal: true

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

require 'spec_helper'

describe Attachments::GarbageCollector do
  describe 'FolderContextType' do
    let_once(:course) { Account.default.courses.create! }
    let_once(:folder) { Folder.root_folders(course).first }
    let(:att) do
      attachment_model(
        context: folder,
        folder: nil,
        uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
      )
    end
    let_once(:gc) { Attachments::GarbageCollector::FolderContextType.new }

    before do
      local_storage!
    end

    it "destroys content and deletes objects" do
      expect(FileUtils).to receive(:rm).with(att.full_filename)

      gc.delete_content
      expect(att.reload).to be_deleted

      gc.delete_rows
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

      gc.delete_content
      expect(att.reload).to be_deleted
      expect(att2.reload).to be_deleted

      gc.delete_rows
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

      gc.delete_content
      expect(att.reload).to be_deleted
      expect(att2.reload.root_attachment_id).to be_nil
      expect(att2.reload.store.exists?).to be_truthy

      gc.delete_rows
      expect { att.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(att2.reload).not_to be_deleted
    end

    it "doesn't worry about deleted children" do
      att2 = attachment_model(
        context: course,
        folder: nil,
        root_attachment_id: att.id,
        uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
      )
      expect(att2.root_attachment_id).to eq att.id
      att2.destroy

      gc.delete_content
      expect(att.reload).to be_deleted
      expect(att2.reload.root_attachment_id).not_to be_nil
    end

    it "doesn't change anything with dry_run: true" do
      dry_run_gc = Attachments::GarbageCollector::FolderContextType.new(dry_run: true)
      expect(FileUtils).not_to receive(:rm).with(att.full_filename)

      dry_run_gc.delete_content
      expect(att.reload).not_to be_deleted
      expect(att.store.exists?).to be_truthy
    end
  end

  describe 'ContentExportContextType' do
    let_once(:course) { Account.default.courses.create! }
    let_once(:export) { course.content_exports.create! }
    let(:att) do
      attachment_model(
        context: export,
        folder: nil,
        uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
      )
    end
    let_once(:gc) { Attachments::GarbageCollector::ContentExportContextType.new(older_than: 1.day.ago) }

    it "only deletes older than given timestamp" do
      gc.delete_content
      expect(att.reload).not_to be_deleted

      Attachment.where(id: att.id).update_all(created_at: 2.days.ago)
      gc.delete_content
      expect(att.reload).to be_deleted
    end

    it "doesn't delete if a child attachment isn't old enough" do
      Attachment.where(id: att.id).update_all(created_at: 2.days.ago)
      export2 = course.content_exports.create!
      att2 = attachment_model(
        context: export2,
        folder: nil,
        root_attachment_id: att.id,
        uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
      )

      gc.delete_content
      expect(att.reload).not_to be_deleted
      expect(att2.reload).not_to be_deleted
    end

    it "properly delineates child attachment age" do
      export2 = course.content_exports.create!
      att2 = attachment_model(
        context: export2,
        folder: nil,
        root_attachment_id: att.id,
        uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
      )
      export3 = course.content_exports.create!
      att3 = attachment_model(
        context: export3,
        folder: nil,
        uploaded_data: stub_file_data("folder2.zip", "hi2", "application/zip")
      )
      Attachment.where(id: [att.id, att3.id]).update_all(created_at: 2.days.ago)

      gc.delete_content
      expect(att.reload).not_to be_deleted
      expect(att2.reload).not_to be_deleted
      expect(att3.reload).to be_deleted
    end

    it "doesn't delete if content export is from a direct share" do
      export = course.content_exports.create!
      att = attachment_model(
        context: export,
        folder: nil,
        root_attachment_id: nil,
        uploaded_data: stub_file_data("folder.zip", "hi", "application/zip")
      )
      export.attachment = att
      export.save
      Attachment.where(id: att.id).update_all(created_at: 1.year.ago)
      SentContentShare.create!(name: 'content export', read_state: 'read', user: user_model, content_export: export)

      gc.delete_content
      expect(att.reload).not_to be_deleted
    end

    it "nulls out ContentExport attachment_ids" do
      Attachment.where(id: att.id).update_all(created_at: 2.days.ago)
      gc.delete_content
      expect(att.reload).to be_deleted

      gc.delete_rows
      expect(export.reload.attachment_id).to be_nil
      expect { att.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
