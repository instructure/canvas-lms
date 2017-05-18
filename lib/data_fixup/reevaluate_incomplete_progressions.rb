#
# Copyright (C) 2015 - present Instructure, Inc.
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

module DataFixup
  module ReevaluateIncompleteProgressions
    def self.run
      current_column = 'context_module_progressions.current'
      scope = ContextModuleProgression.where(:workflow_state => ['unlocked', 'started']).where(:current => false)

      ContextModuleProgression.find_ids_in_ranges do |min_id, max_id|
        scope.where(:id => min_id..max_id).preload(:context_module).each do |progression|
          progression.evaluate!
        end
      end
    end
  end
end