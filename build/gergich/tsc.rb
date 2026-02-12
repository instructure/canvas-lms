# frozen_string_literal: true

#
# Copyright (C) 2026 - present Instructure, Inc.
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

# gergich capture custom:./build/gergich/tsc:Gergich::TSC "yarn tsc"
class Gergich::TSC
  def run(output)
    # TypeScript errors look like:
    # ui/features/webzip_export/react/App.tsx(94,22): error TS2532: Object is possibly 'undefined'.
    pattern = /^([^:\n]+?)\((\d+),\d+\): error (TS\d+): (.*)$/

    output.scan(pattern).filter_map do |file, line, error_code, message|
      {
        path: file,
        message: "[#{error_code}] #{message}",
        position: line.to_i,
        severity: "error"
      }
    end
  end
end
