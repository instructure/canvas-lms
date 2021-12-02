# frozen_string_literal: true

#
# Copyright (C) 2016 - present Instructure, Inc.
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

# gergich capture custom:./build/gergich/xsslint:Gergich::XSSLint "node script/xsslint.js"
class Gergich::XSSLint
  def run(output)
    # e.g. alerts.js:110: possibly XSS-able argument to `append()`
    pattern = /^([^:\n]+):(\d+): (.*)$/

    output.scan(pattern).map { |file, line, error|
      { path: file, message: "[xsslint] #{error}", position: line.to_i, severity: "error" }
    }.compact
  end
end
