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
module CC
  module ModuleMeta
    def create_module_meta(document=nil)
      return nil unless @course.context_modules.not_deleted.count > 0

      if document
        meta_file = nil
        rel_path = nil
      else
        meta_file = File.new(File.join(@canvas_resource_dir, CCHelper::MODULE_META), 'w')
        rel_path = File.join(CCHelper::COURSE_SETTINGS_DIR, CCHelper::MODULE_META)
        document = Builder::XmlMarkup.new(:target=>meta_file, :indent=>2)
      end

      module_id_map = {}
      document.instruct!
      document.modules(
              "xmlns" => CCHelper::CANVAS_NAMESPACE,
              "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
              "xsi:schemaLocation"=> "#{CCHelper::CANVAS_NAMESPACE} #{CCHelper::XSD_URI}"
      ) do |mods_node|
        @course.context_modules.not_deleted.each do |cm|

          unless export_object?(cm)
            # if the whole module isn't selected, check to see if a specific item is selected, and make sure that item gets exported
            cm.content_tags.not_deleted.each do |ct|
              if export_object?(ct) && !['ContextModuleSubHeader', 'ExternalUrl'].member?(ct.content_type) && ct.content
                add_item_to_export(ct.content)
              end
            end
            next
          end

          add_exported_asset(cm)

          mod_migration_id = CCHelper.create_key(cm)
          # context modules are in order and a pre-req can only reference
          # a previous module, so just adding as we go is okay
          module_id_map[cm.id] = mod_migration_id

          mods_node.module(:identifier=>mod_migration_id) do |m_node|
            m_node.title cm.name
            m_node.workflow_state cm.workflow_state
            m_node.position cm.position
            m_node.unlock_at CCHelper::ims_datetime(cm.unlock_at) if cm.unlock_at
            m_node.require_sequential_progress cm.require_sequential_progress.to_s unless cm.require_sequential_progress.nil?
            m_node.requirement_count cm.requirement_count if cm.requirement_count
            m_node.locked cm.locked_for?(@user).present?

            if cm.prerequisites && !cm.prerequisites.empty?
              m_node.prerequisites do |pre_reqs|
                cm.prerequisites.each do |pre_req|
                  pre_reqs.prerequisite(:type=>pre_req[:type]) do |pr|
                    pr.title pre_req[:name]
                    pr.identifierref module_id_map[pre_req[:id]]
                  end
                end
              end
            end

            ct_id_map = {}
            m_node.items do |items_node|
              cm.content_tags.not_deleted.each do |ct|
                ct_migration_id = CCHelper.create_key(ct)
                ct_id_map[ct.id] = ct_migration_id
                items_node.item(:identifier=>ct_migration_id) do |item_node|
                  unless ['ContextModuleSubHeader', 'ExternalUrl'].member? ct.content_type
                    add_item_to_export(ct.content)
                  end
                  item_node.content_type ct.content_type
                  item_node.workflow_state ct.workflow_state
                  item_node.title ct.title
                  item_node.identifierref CCHelper.create_key(ct.content_or_self) unless ct.content_type == 'ContextModuleSubHeader'
                  if ct.content_type == "ContextExternalTool"
                    item_node.url ct.url
                    if ct.content && ct.content.context != @course
                      item_node.global_identifierref ct.content.id
                    end
                  end
                  item_node.url ct.url if ct.content_type == 'ExternalUrl'
                  item_node.position ct.position
                  item_node.new_tab ct.new_tab
                  item_node.indent ct.indent
                end
              end
            end

            if cm.completion_requirements && !cm.completion_requirements.empty?
              m_node.completionRequirements do |crs_node|
                cm.completion_requirements.each do |c_req|
                  crs_node.completionRequirement(:type=>c_req[:type]) do |cr_node|
                    cr_node.min_score c_req[:min_score] unless c_req[:min_score].blank?
                    cr_node.identifierref ct_id_map[c_req[:id]]
                  end
                end
              end
            end

          end
        end
      end
      meta_file.close if meta_file
      rel_path
    end
  end
end
