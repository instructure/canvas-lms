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
      let(:migration_id) { "123" }

      before do
        course_model
        @migration = @course.content_migrations.create!
        attachment_model(context: @course, migration_id:)
      end

      it "imports an attachment" do
        data = {
          "file_map" => {
            "a" => {
              id: @attachment.id,
              migration_id:
            }
          }
        }

        display_name = @attachment.display_name

        Importers::AttachmentImporter.process_migration(data, @migration)

        expect(@migration.imported_migration_items).to eq [@attachment]
        expect(@attachment.context).to eq @course
        expect(@attachment.locked).to be_falsy
        expect(@attachment.display_name).to eq display_name
      end

      it "imports attachments when the migration id is in the files_to_import hash" do
        data = {
          "file_map" => {
            "a" => {
              id: @attachment.id,
              migration_id:,
              files_to_import: {
                migration_id => true
              }
            }
          }
        }

        expect(@migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)

        Importers::AttachmentImporter.process_migration(data, @migration)
      end

      it "finds attachments by migration id" do
        data = {
          "file_map" => {
            "a" => {
              migration_id:,
            }
          }
        }

        expect(@migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)

        Importers::AttachmentImporter.process_migration(data, @migration)
      end

      it "finds attachment from the path" do
        data = {
          "file_map" => {
            "a" => {
              migration_id:,
              path_name: "path/to/file"
            }
          }
        }

        @attachment.update(migration_id: nil)
        expect(@migration).to receive(:import_object?).with("attachments", migration_id).and_return(true)

        Importers::AttachmentImporter.process_migration(data, @migration)
      end

      it "uses files if attachments are not found on the migration" do
        data = {
          "file_map" => {
            "a" => {
              id: @attachment.id,
              migration_id:
            }
          }
        }

        expect(@migration).to receive(:import_object?).with("attachments", migration_id).and_return(false)
        expect(@migration).to receive(:import_object?).with("files", migration_id).and_return(true)

        Importers::AttachmentImporter.process_migration(data, @migration)
      end

      it "does not import files that are not part of the migration" do
        data = {
          "file_map" => {
            "a" => {
              id: @attachment.id,
              migration_id:,
              files_to_import: {}
            }
          }
        }

        expect(::Attachment).not_to receive(:where)

        Importers::AttachmentImporter.process_migration(data, @migration)
      end

      it "sets locked, file_state, and display_name when present" do
        data = {
          "file_map" => {
            "a" => {
              id: @attachment.id,
              migration_id:,
              locked: true,
              hidden: true,
              display_name: "display name"
            }
          }
        }

        Importers::AttachmentImporter.process_migration(data, @migration)
        expect(@attachment.reload.locked).to be_truthy
        expect(@attachment.hidden).to be_truthy
        expect(@attachment.display_name).to eq "display name"
      end

      it "locks folders" do
        data = {
          locked_folders: [
            "path1/foo",
            "path2/bar"
          ]
        }

        folder = Folder.root_folders(@course).first.sub_folders.create!(name: "path1", context: @course).sub_folders.create!(name: "foo", context: @course)

        Importers::AttachmentImporter.process_migration(data, @migration)
        expect(folder.reload.locked).to be_truthy
      end

      it "hidden_folders" do
        data = {
          hidden_folders: [
            "path1/foo",
            "path2/bar"
          ]
        }

        folder = Folder.root_folders(@course).first.sub_folders.create!(name: "path1", context: @course).sub_folders.create!(name: "foo", context: @course)

        Importers::AttachmentImporter.process_migration(data, @migration)
        expect(folder.reload.workflow_state).to eq "hidden"
      end

      it "re-activates deleted files that are imported" do
        MediaObject.create!(media_id: "maybe")
        attachment_model(uploaded_data: stub_file_data("test.m4v", "asdf", "video/mp4"), context: @course, media_entry_id: "maybe")

        data = {
          "file_map" => {
            "test.m4v" => {
              id: @attachment.id,
              migration_id:,
              display_name: "test.m4v"
            }
          }
        }

        @attachment.destroy
        Importers::AttachmentImporter.process_migration(data, @migration)
        expect(@attachment.reload.file_state).to eq "available"
      end

      describe "saving import failures" do
        it "saves import failures with display name" do
          data = {
            "file_map" => {
              "a" => {
                id: @attachment.id,
                migration_id:,
                display_name: "foo"
              }
            }
          }

          error = RuntimeError.new
          expect(::Attachment).to receive(:where).and_raise(error)

          Importers::AttachmentImporter.process_migration(data, @migration)
          expect(@migration.reload.migration_issues.pluck(:description)).to include("Import Error: File - \"foo\"")
        end

        it "saves import failures with path name" do
          data = {
            "file_map" => {
              "a" => {
                id: @attachment.id,
                migration_id:,
                path_name: "bar"
              }
            }
          }

          error = RuntimeError.new
          expect(::Attachment).to receive(:where).and_raise(error)

          Importers::AttachmentImporter.process_migration(data, @migration)
          expect(@migration.reload.migration_issues.pluck(:description)).to include("Import Error: File - \"bar\"")
        end
      end
    end
  end
end
