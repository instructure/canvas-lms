#
# Copyright (C) 2014 Instructure, Inc.
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

require File.expand_path(File.dirname(__FILE__) + '../../../spec_helper.rb')

module Importers
  describe Importers::AttachmentImporter do

    describe '#process_migration', no_retry: true do
      let(:course) { ::Course.new }
      let(:course_id) { 1 }
      let(:migration) { ContentMigration.new(context: course) }
      let(:migration_id) { '123' }
      let(:attachment_id) { 456 }
      let(:attachment) { stub(:context= => true, :migration_id= => true, :save_without_broadcasting! => true) }

      before :each do
        course.stubs(:id).returns(course_id)
        migration.stubs(:import_object?).with('attachments', migration_id).returns(true)
      end

      it 'imports an attachment' do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id
                }
            }
        }

        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, id: attachment_id).returns(stub(first: attachment))
        migration.expects(:import_object?).with('attachments', migration_id).returns(true)
        attachment.expects(:context=).with(course)
        attachment.expects(:migration_id=).with(migration_id)
        attachment.expects(:locked=).never
        attachment.expects(:file_state=).never
        attachment.expects(:display_name=).never
        attachment.expects(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)

        migration.imported_migration_items.should == [attachment]
      end

      it "imports attachments when the migration id is in the files_to_import hash" do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id,
                    files_to_import: {
                        migration_id => true
                    }
                }
            }
        }

        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, id: attachment_id).returns(stub(first: attachment))
        migration.expects(:import_object?).with('attachments', migration_id).returns(true)
        attachment.expects(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "finds attachments by migration id" do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id,
                }
            }
        }

        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, id: attachment_id).returns(stub(first: nil))
        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, migration_id: migration_id).returns(stub(first: attachment))
        migration.expects(:import_object?).with('attachments', migration_id).returns(true)
        attachment.expects(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "finds attachment from the path" do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id,
                    path_name: "path/to/file"
                }
            }
        }

        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, id: attachment_id).returns(stub(first: nil))
        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, migration_id: migration_id).returns(stub(first: nil))
        ::Attachment.expects(:find_from_path).with("path/to/file", course).returns(attachment)
        migration.expects(:import_object?).with('attachments', migration_id).returns(true)
        attachment.expects(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "uses files if attachments are not found on the migration" do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id
                }
            }
        }

        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, id: attachment_id).returns(stub(first: attachment))
        migration.stubs(:import_object?).with('attachments', migration_id).returns(false)
        migration.stubs(:import_object?).with('files', migration_id).returns(true)

        attachment.expects(:save_without_broadcasting!)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "does not import files that are not part of the migration" do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id,
                    files_to_import: {}
                }
            }
        }

        ::Attachment.expects(:where).never

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "does not import files if there is a file_to_import key" do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id,
                    files_to_import: {
                    }
                }
            }
        }

        ::Attachment.expects(:where).never

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it 'sets locked, file_state, and display_name when present' do
        data = {
            'file_map' => {
                'a' => {
                    id: attachment_id,
                    migration_id: migration_id,
                    locked: true,
                    hidden: true,
                    display_name: "display name"
                }
            }
        }

        ::Attachment.expects(:where).with(context_type: "Course", context_id: course, id: attachment_id).returns(stub(first: attachment))
        attachment.expects(:locked=).with(true)
        attachment.expects(:file_state=).with('hidden')
        attachment.expects(:display_name=).with('display name')

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "locks folders" do
        data = {
            locked_folders: [
                "path1/foo",
                "path2/bar"
            ]
        }

        active_folders_association = stub()
        course.expects(:active_folders).returns(active_folders_association).twice
        folder = stub()
        active_folders_association.stubs(:where).with(full_name: "course files/path1/foo").returns(stub(first: folder))
        active_folders_association.stubs(:where).with(full_name: "course files/path2/bar").returns(stub(first: nil))
        folder.expects(:locked=).with(true)
        folder.expects(:save)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      it "hidden_folders" do
        data = {
            hidden_folders: [
                "path1/foo",
                "path2/bar"
            ]
        }

        active_folders_association = stub()
        course.expects(:active_folders).returns(active_folders_association).twice
        folder = stub()
        active_folders_association.stubs(:where).with(full_name: "course files/path1/foo").returns(stub(first: folder))
        active_folders_association.stubs(:where).with(full_name: "course files/path2/bar").returns(stub(first: nil))
        folder.expects(:workflow_state=).with("hidden")
        folder.expects(:save)

        Importers::AttachmentImporter.process_migration(data, migration)
      end

      describe "saving import failures" do
        it "saves import failures with display name" do
          data = {
              'file_map' => {
                  'a' => {
                      id: attachment_id,
                      migration_id: migration_id,
                      display_name: "foo"
                  }
              }
          }

          error = RuntimeError.new
          ::Attachment.expects(:where).raises(error)
          migration.expects(:add_import_warning).with(I18n.t('#migration.file_type', "File"), "foo", error)

          Importers::AttachmentImporter.process_migration(data, migration)
        end

        it "saves import failures with path name" do
          data = {
              'file_map' => {
                  'a' => {
                      id: attachment_id,
                      migration_id: migration_id,
                      path_name: "bar"
                  }
              }
          }

          error = RuntimeError.new
          ::Attachment.expects(:where).raises(error)
          migration.expects(:add_import_warning).with(I18n.t('#migration.file_type', "File"), "bar", error)

          Importers::AttachmentImporter.process_migration(data, migration)
        end
      end
    end
  end
end