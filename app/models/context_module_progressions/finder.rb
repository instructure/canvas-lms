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

module ContextModuleProgressions
  class Finder
    def self.find_or_create_for_context_and_user(context, user)
      modules = context.context_modules.where(workflow_state: "active").to_a

      existing_progressions = ContextModuleProgression
                              .where(user_id: user)
                              .where(context_module_id: modules)
                              .index_by(&:context_module_id)

      modules.map do |mod|
        progression = if existing_progressions.include?(mod.id)
                        existing_progressions[mod.id]
                      else
                        create_module_progression(mod, user)
                      end
        progression.context_module = mod
        progression
      end
    end

    def self.create_module_progression(mod, user)
      GuardRail.activate(:primary) do
        ContextModuleProgression.unique_constraint_retry do |retry_count|
          progression = mod.context_module_progressions.where(user_id: user).first if retry_count > 0
          progression || mod.context_module_progressions.create!(user:)
        end
      end
    end
  end
end
