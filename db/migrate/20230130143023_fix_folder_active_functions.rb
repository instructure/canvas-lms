# frozen_string_literal: true

#
# Copyright (C) 2022 - present Instructure, Inc.
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

class FixFolderActiveFunctions < ActiveRecord::Migration[6.1]
  tag :predeploy

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

    execute("
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("folder_before_insert_verify_active_parent_folder__tr_fn")} () RETURNS trigger AS $$
      DECLARE
        parent_state text;
      BEGIN
        SELECT workflow_state INTO parent_state FROM folders WHERE folders.id = NEW.parent_folder_id FOR SHARE;
        if parent_state = 'deleted' then
          RAISE EXCEPTION 'Cannot create sub-folders in deleted folders --> %', NEW.parent_folder_id;
        end if;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;")

    set_search_path("attachment_before_insert_verify_active_folder__tr_fn")
    set_search_path("folder_before_insert_verify_active_parent_folder__tr_fn")
  end

  def down
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

    execute("
      CREATE OR REPLACE FUNCTION #{connection.quote_table_name("folder_before_insert_verify_active_parent_folder__tr_fn")} () RETURNS trigger AS $$
      DECLARE
        parent_state text;
      BEGIN
        SELECT workflow_state INTO parent_state FROM #{Folder.quoted_table_name} WHERE folders.id = NEW.parent_folder_id FOR SHARE;
        if parent_state = 'deleted' then
          RAISE EXCEPTION 'Cannot create sub-folders in deleted folders --> %', NEW.parent_folder_id;
        end if;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;")

    set_search_path("attachment_before_insert_verify_active_folder__tr_fn", "()", "DEFAULT")
    set_search_path("folder_before_insert_verify_active_parent_folder__tr_fn", "()", "DEFAULT")
  end
end
