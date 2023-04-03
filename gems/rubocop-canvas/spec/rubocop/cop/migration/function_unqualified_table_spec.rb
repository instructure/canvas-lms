# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

describe RuboCop::Cop::Migration::FunctionUnqualifiedTable do
  subject(:cop) { described_class.new }

  context "create function" do
    it "complains if a function is created with a schema qualified table name" do
      inspect_source(<<~'RUBY')
        class MyMigration < ActiveRecord::Migration
          def up
            execute("
              CREATE OR REPLACE FUNCTION #{connection.quote_table_name("attachment_before_insert_verify_active_folder__tr_fn")} () RETURNS trigger AS $$
              DECLARE
                folder_state text;
              BEGIN
                SELECT workflow_state INTO folder_state FROM #{Folder.quoted_table_name} WHERE folders.id = NEW.folder_id FOR SHARE;
                if folder_state = 'deleted' then
                  RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
                end if;
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;")
          end
        end
      RUBY

      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq <<~'TEXT'.tr("\n", " ")
        Migration/FunctionUnqualifiedTable: Use unqualified table names in function creation to be compatible with beta/test refresh.
        (ie: `folders` and not `#{Folder.quoted_table_name}`))
      TEXT
      expect(cop.offenses.first.severity.name).to eq(:error)
    end

    it "does not complain on functions without a schema qualified table name" do
      inspect_source(<<~'RUBY')
        class MyMigration < ActiveRecord::Migration
          def up
            execute("
              CREATE OR REPLACE FUNCTION #{connection.quote_table_name("attachment_before_insert_verify_active_folder__tr_fn")} () RETURNS trigger AS $$
              DECLARE
                folder_state text;
              BEGIN
                SELECT workflow_state INTO folder_state FROM folders WHERE folders.id = NEW.folder_id FOR SHARE;
                if folder_state = 'deleted' then
                  RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
                end if;
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;")
          end
        end
      RUBY

      expect(cop.offenses.size).to eq 0
    end

    it "finds function creation with white space" do
      inspect_source(<<~'RUBY')
        class MyMigration < ActiveRecord::Migration
          def up
            execute("
              CREATE OR REPLACE
              FUNCTION function_name () RETURNS trigger AS $$
              DECLARE
                folder_state text;
              BEGIN
                SELECT workflow_state INTO folder_state FROM #{Folder.quoted_table_name} WHERE folders.id = NEW.folder_id FOR SHARE;
                if folder_state = 'deleted' then
                  RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
                end if;
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;")
          end
        end
      RUBY

      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq <<~'TEXT'.tr("\n", " ")
        Migration/FunctionUnqualifiedTable: Use unqualified table names in function creation to be compatible with beta/test refresh.
        (ie: `folders` and not `#{Folder.quoted_table_name}`))
      TEXT
      expect(cop.offenses.first.severity.name).to eq(:error)
    end

    it "finds function creation without replace" do
      inspect_source(<<~'RUBY')
        class MyMigration < ActiveRecord::Migration
          def up
            execute("
              CREATE FUNCTION function_name () RETURNS trigger AS $$
              DECLARE
                folder_state text;
              BEGIN
                SELECT workflow_state INTO folder_state FROM #{Folder.quoted_table_name} WHERE folders.id = NEW.folder_id FOR SHARE;
                if folder_state = 'deleted' then
                  RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
                end if;
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;")
          end
        end
      RUBY

      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq <<~'TEXT'.tr("\n", " ")
        Migration/FunctionUnqualifiedTable: Use unqualified table names in function creation to be compatible with beta/test refresh.
        (ie: `folders` and not `#{Folder.quoted_table_name}`))
      TEXT
      expect(cop.offenses.first.severity.name).to eq(:error)
    end

    it "finds function replacement without create" do
      inspect_source(<<~'RUBY')
        class MyMigration < ActiveRecord::Migration
          def up
            execute("
              REPLACE FUNCTION function_name () RETURNS trigger AS $$
              DECLARE
                folder_state text;
              BEGIN
                SELECT workflow_state INTO folder_state FROM #{Folder.quoted_table_name} WHERE folders.id = NEW.folder_id FOR SHARE;
                if folder_state = 'deleted' then
                  RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
                end if;
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;")
          end
        end
      RUBY

      expect(cop.offenses.size).to eq 1
      expect(cop.messages.first).to eq <<~'TEXT'.tr("\n", " ")
        Migration/FunctionUnqualifiedTable: Use unqualified table names in function creation to be compatible with beta/test refresh.
        (ie: `folders` and not `#{Folder.quoted_table_name}`))
      TEXT
      expect(cop.offenses.first.severity.name).to eq(:error)
    end

    it "does not complain on non-function creation" do
      inspect_source(<<~'RUBY')
        class MyMigration < ActiveRecord::Migration
          def up
            execute("
              CREATE OR REPLACE TRIGGER
              FUNCTION #{connection.quote_table_name("attachment_before_insert_verify_active_folder__tr_fn")} () RETURNS trigger AS $$
              DECLARE
                folder_state text;
              BEGIN
                SELECT workflow_state INTO folder_state FROM FROM #{Folder.quoted_table_name} WHERE folders.id = NEW.folder_id FOR SHARE;
                if folder_state = 'deleted' then
                  RAISE EXCEPTION 'Cannot create attachments in deleted folders --> %', NEW.folder_id;
                end if;
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;")
          end
        end
      RUBY

      expect(cop.offenses.size).to eq 0
    end

    it "does not complain on function creation separate from some other execution" do
      inspect_source(<<~'RUBY')
        class MyMigration < ActiveRecord::Migration
          def up
            execute("
              CREATE OR REPLACE FUNCTION #{connection.quote_table_name("folder_before_insert_verify_active_parent_folder__tr_fn")} () RETURNS trigger AS $$
              DECLARE
                parent_state text;
              BEGIN
                SELECT workflow_state INTO parent_state FROM folder WHERE folders.id = NEW.parent_folder_id FOR SHARE;
                if parent_state = 'deleted' then
                  RAISE EXCEPTION 'Cannot create sub-folders in deleted folders --> %', NEW.parent_folder_id;
                end if;
                RETURN NEW;
              END;
              $$ LANGUAGE plpgsql;")

            execute("
              CREATE TRIGGER folder_before_insert_verify_active_parent_folder__tr
                BEFORE INSERT ON #{Folder.quoted_table_name}
                FOR EACH ROW
                EXECUTE PROCEDURE #{connection.quote_table_name("folder_before_insert_verify_active_parent_folder__tr_fn")}()")
          end
        end
      RUBY

      expect(cop.offenses.size).to eq 0
    end
  end
end
