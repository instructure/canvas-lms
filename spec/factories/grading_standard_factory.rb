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

module Factories
  def grading_standard_for(context, opts={})
    @standard = context.grading_standards.create!(
      title: opts[:title] || "My Grading Standard",
      standard_data: {
        "scheme_0" => { name: "A", value: "0.9" },
        "scheme_1" => { name: "B", value: "0.8" },
        "scheme_2" => { name: "C", value: "0.7" },
        "scheme_3" => { name: "D", value: "0.0" }
      }
    )
  end
end
