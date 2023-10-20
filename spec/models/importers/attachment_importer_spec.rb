# frozen_string_literal: true

#
# Copyright (C) 2014 - present Instructure, Inc.
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

module Importers
  describe AttachmentImporter do
    describe "#process_migration", :no_retry do
      let(:course) { ::Course.new }
      let(:course_id) { 1 }
      let(:migration) { ContentMigration.new(context: course) }
      let(:migration_id) { "123" }
      let(:attachment_id) { 456 }
      let(:attachment) do
        double(:context= => true,
               :migration_id= => true,
               :migration_id => migration_id,
               :save_without_broadcasting! => true,
               :set_publish_state_for_usage_rights => nil,
               :mark_as_importing! => nil,
               :handle_duplicates => nil)
      end

      before do
        allow(course).to receive(:id).and_return(course_id)
        allow(migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)
      end

      it "imports an attachment" do
        data = {
          "file_map" => {
            "a" => {
              id: attachment_id,
              migration_id:
            }
          }
        }

        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, id: attachment_id).and_return(double(first: attachment))
        expect(migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)
        expect(attachment).to receive(:context=).with(course)
        expect(attachment).to receive(:migration_id=).with(migration_id)
        expect(attachment).not_to receive(:locked=)
        expect(attachment).not_to receive(:file_state=)
        expect(attachment).not_to receive(:display_name=)
        expect(attachment).to receive(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)

        expect(migration.imported_migration_items).to eq [attachment]
      end

      it "imports attachments when the migration id is in the files_to_import hash" do
        data = {
          "file_map" => {
            "a" => {
              id: attachment_id,
              migration_id:,
              files_to_import: {
                migration_id => true
              }
            }
          }
        }

        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, id: attachment_id).and_return(double(first: attachment))
        expect(migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)
        expect(attachment).to receive(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "finds attachments by migration id" do
        data = {
          "file_map" => {
            "a" => {
              id: attachment_id,
              migration_id:,
            }
          }
        }

        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, id: attachment_id).and_return(double(first: nil))
        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, migration_id:).and_return(double(first: attachment))
        expect(migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)
        expect(attachment).to receive(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "finds attachment from the path" do
        data = {
          "file_map" => {
            "a" => {
              id: attachment_id,
              migration_id:,
              path_name: "path/to/file"
            }
          }
        }

        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, id: attachment_id).and_return(double(first: nil))
        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, migration_id:).and_return(double(first: nil))
        expect(::Attachment).to receive(:find_from_path).with("path/to/file", course).and_return(attachment)
        expect(migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)
        expect(attachment).to receive(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "uses files if attachments are not found on the migration" do
        data = {
          "file_map" => {
            "a" => {
              id: attachment_id,
              migration_id:
            }
          }
        }

        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, id: attachment_id).and_return(double(first: attachment))
        allow(migration).to receive(:import_object?).with("attachments", migration_id).and_return(false)
        allow(migration).to receive(:import_object?).with("files", migration_id).and_return(true)

        expect(attachment).to receive(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "does not import files that are not part of the migration" do
        data = {
          "file_map" => {
            "a" => {
              id: attachment_id,
              migration_id:,
              files_to_import: {}
            }
          }
        }

        expect(::Attachment).not_to receive(:where)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "sets locked, file_state, and display_name when present" do
        data = {
          "file_map" => {
            "a" => {
              id: attachment_id,
              migration_id:,
              locked: true,
              hidden: true,
              display_name: "display name"
            }
          }
        }

        expect(::Attachment).to receive(:where).with(context_type: "Course", context_id: course, id: attachment_id).and_return(double(first: attachment))
        expect(attachment).to receive(:locked=).with(true)
        expect(attachment).to receive(:file_state=).with("hidden")
        expect(attachment).to receive(:display_name=).with("display name")

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "locks folders" do
        data = {
          locked_folders: [
            "path1/foo",
            "path2/bar"
          ]
        }

        active_folders_association = double
        expect(course).to receive(:active_folders).and_return(active_folders_association).twice
        folder = double
        allow(active_folders_association).to receive(:where).with(full_name: "course files/path1/foo").and_return(double(first: folder))
        allow(active_folders_association).to receive(:where).with(full_name: "course files/path2/bar").and_return(double(first: nil))
        expect(folder).to receive(:locked=).with(true)
        expect(folder).to receive(:save)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "hidden_folders" do
        data = {
          hidden_folders: [
            "path1/foo",
            "path2/bar"
          ]
        }

        active_folders_association = double
        expect(course).to receive(:active_folders).and_return(active_folders_association).twice
        folder = double
        allow(active_folders_association).to receive(:where).with(full_name: "course files/path1/foo").and_return(double(first: folder))
        allow(active_folders_association).to receive(:where).with(full_name: "course files/path2/bar").and_return(double(first: nil))
        expect(folder).to receive(:workflow_state=).with("hidden")
        expect(folder).to receive(:save)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      describe "saving import failures" do
        it "saves import failures with display name" do
          data = {
            "file_map" => {
              "a" => {
                id: attachment_id,
                migration_id:,
                display_name: "foo"
              }
            }
          }

          error = RuntimeError.new
          expect(::Attachment).to receive(:where).and_raise(error)
          expect(migration).to receive(:add_import_warning).with(I18n.t("#migration.file_type", "File"), "foo", error)

          Importers::AttachmentImporter.process_migration(data, migration)
        end

        it "saves import failures with path name" do
          data = {
            "file_map" => {
              "a" => {
                id: attachment_id,
                migration_id:,
                path_name: "bar"
              }
            }
          }

          error = RuntimeError.new
          expect(::Attachment).to receive(:where).and_raise(error)
          expect(migration).to receive(:add_import_warning).with(I18n.t("#migration.file_type", "File"), "bar", error)

          Importers::AttachmentImporter.process_migration(data, migration)
        end
      end
    end
  end
end
