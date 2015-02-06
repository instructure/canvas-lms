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

module Importers
  class AttachmentImporter < Importer

    self.item_class = Attachment

    def self.process_migration(data, migration)
      created_usage_rights_map = {}
      attachments = data['file_map'] ? data['file_map']: {}
      attachments = attachments.with_indifferent_access
      attachments.values.each do |att|
        if !att['is_folder'] && (migration.import_object?("attachments", att['migration_id']) || migration.import_object?("files", att['migration_id']))
          begin
            import_from_migration(att, migration.context, migration, nil, created_usage_rights_map)
          rescue
            migration.add_import_warning(I18n.t('#migration.file_type', "File"), (att[:display_name] || att[:path_name]), $!)
          end
        end
      end

      if data[:locked_folders]
         data[:locked_folders].each do |path|
           # TODO i18n
           if f = migration.context.active_folders.where(full_name: "course files/#{path}").first
             f.locked = true
             f.save
           end
         end
      end

      if data[:hidden_folders]
        data[:hidden_folders].each do |path|
          # TODO i18n
          if f = migration.context.active_folders.where(full_name: "course files/#{path}").first
            f.workflow_state = 'hidden'
            f.save
          end
        end
      end
    end

    private

    def self.import_from_migration(hash, context, migration=nil, item=nil, created_usage_rights_map={})
      return nil if hash[:files_to_import] && !hash[:files_to_import][hash[:migration_id]]
      item ||= Attachment.where(context_type: context.class.to_s, context_id: context, id: hash[:id]).first
      item ||= Attachment.where(context_type: context.class.to_s, context_id: context, migration_id: hash[:migration_id]).first # if hash[:migration_id]
      item ||= Attachment.find_from_path(hash[:path_name], context)
      if item
        item.context = context
        item.migration_id = hash[:migration_id]
        item.locked = true if hash[:locked]
        item.file_state = 'hidden' if hash[:hidden]
        item.display_name = hash[:display_name] if hash[:display_name]
        item.usage_rights_id = find_or_create_usage_rights(context, hash[:usage_rights], created_usage_rights_map) if hash[:usage_rights]
        item.save_without_broadcasting!
        migration.add_imported_item(item) if migration
      end
      item
    end

    def self.find_or_create_usage_rights(context, usage_rights_hash, created_usage_rights_map)
      attrs = usage_rights_hash.slice('use_justification', 'license', 'legal_copyright')
      key = attrs.values_at('use_justification', 'license', 'legal_copyright').join('/')
      id = created_usage_rights_map[key]
      return id if id

      usage_rights = context.usage_rights.create!(attrs)
      created_usage_rights_map[key] = usage_rights.id
    end

  end
end
