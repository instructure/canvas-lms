# Copyright (C) 2016 Instructure, Inc.
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

module Lti
  module ContentMigrationService
    def self.enabled?
      Setting.get('enable_lti_content_migration', 'false') == 'true'
    end

    def self.begin_exports(course, options = {})
      # TODO: handle selectivity
      # if opts[:selective]... app/models/conditional_release/migration_service.rb:10

      # Select tools with proper configs
      configured_tools = []
      Shackles.activate(:slave) do
        ContextExternalTool.all_tools_for(course).find_each do |tool|
          configured_tools << tool if tool.content_migration_configured?
        end
      end

      exports = {}

      configured_tools.each do |tool|
        migrator = Lti::ContentMigrationService::Migrator.new(course, tool)
        migrator.start!
        exports["lti_#{tool.id}"] = migrator if migrator.successfully_started?
      end

      exports
    end
  end
end
