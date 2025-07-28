# frozen_string_literal: true

#
# Copyright (C) 2025 - present Instructure, Inc.
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

class Loaders::ModuleActiveOverridesLoader < GraphQL::Batch::Loader
  def perform(context_modules)
    GuardRail.activate(:secondary) do
      module_ids = context_modules.map(&:id)
      modules_with_overrides = AssignmentOverride
                               .where(context_module_id: module_ids, workflow_state: "active")
                               .distinct
                               .pluck(:context_module_id)
                               .to_set

      context_modules.each do |context_module|
        has_overrides = modules_with_overrides.include?(context_module.id)
        fulfill(context_module, has_overrides)
      end
    end
  end
end
