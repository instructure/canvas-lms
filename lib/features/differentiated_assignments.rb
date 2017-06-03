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

module Features
  module DifferentiatedAssignments
    class ModuleEvaluator < Struct.new(:course_id)
      def perform
        ContextModuleProgression.joins(:context_module).readonly(false).
          where(:context_modules => { :context_type => 'Course', :context_id => course_id}).
          find_each do |prog|
            prog.mark_as_outdated!
          end
      end
    end
  end
end
