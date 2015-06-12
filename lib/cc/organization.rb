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
  class Organization
    include CCHelper

    def initialize(manifest, manifest_node)
      @manifest = manifest
      @manifest_node = manifest_node
      @course = @manifest.course
      @root_item = nil
    end
    
    def self.create_organizations(manifest, manifest_node)
      r = new(manifest, manifest_node)
      r.create_organizations
    end
    
    def create_organizations
      @manifest_node.organizations do |orgs|
        orgs = orgs
        orgs.organization(
                :identifier => 'org_1',
                :structure => 'rooted-hierarchy'
        ) do |org|
          org.item(:identifier=>"LearningModules") do |root_item|
            @root_item = root_item
            @course.context_modules.not_deleted.each do |cm|
              next unless @manifest.export_object?(cm)
              add_module(cm)
            end
          end
        end
      end
    end
    
    def add_module(cm)
      @root_item.item(:identifier=>CCHelper.create_key(cm)) do |module_node|
        module_node.title cm.name
        cm.content_tags.not_deleted.each do |ct|
          attributes = {:identifier=>CCHelper.create_key(ct)}
          unless ct.content_type == 'ContextModuleSubHeader'
            attributes[:identifierref] = CCHelper.create_key(ct.content)
          end
          if ct.content_type == 'ExternalUrl'
            # Need to create web link objects in the resources
            link = {
                    :migration_id => CCHelper.create_key(ct, 'weblink'),
                    :title=> ct.title,
                    :url => ct.url}
            @manifest.weblinks << link
            attributes[:identifierref] = link[:migration_id]
          elsif ct.content_type == 'ContextExternalTool'
            attributes[:identifierref] = attributes[:identifier]
            attributes[:identifier] = CCHelper.create_key(ct, "module_item")
          end
          module_node.item(attributes) do |tag_node|
            tag_node.title ct.title
          end
        end
      end
    end
  end
end
