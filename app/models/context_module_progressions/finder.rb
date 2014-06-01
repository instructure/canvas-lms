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

module ContextModuleProgressions
  class Finder
    def self.find_or_create_for_module_and_user(context_module, user)
      modules = ContextModule
        .where(workflow_state: 'active')
        .where(context_type: context_module.context_type, context_id: context_module.context_id)

      existing_progressions = ContextModuleProgression
        .where(user_id: user)
        .where(context_module_id: modules.map(&:id))
        .index_by(&:context_module_id)

      modules.map do |mod|
        if existing_progressions.include?(mod.id)
          progression = existing_progressions[mod.id]
        else
          progression = mod.context_module_progressions.create!(user: user)
        end
        progression.context_module = mod
        progression
      end
    end
  end
end
