# frozen_string_literal: true

#
# Copyright (C) 2024 - present Instructure, Inc.
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

module GradingSchemeSerializer
  JSON_METHODS = %i[context_name].freeze
  def to_grading_scheme_summary_json(grading_standard)
    {
      title: grading_standard.title,
      id: grading_standard.id.to_s,
      context_type: grading_standard.context_type
    }.as_json
  end

  def default_to_json(user, context)
    grading_standard = default_canvas_grading_standard(context)
    base_grading_scheme_json(grading_standard, user)
  end

  def to_grading_scheme_json(grading_standard, user)
    base_grading_scheme_json(grading_standard, user).tap do |json|
      # instead of using the JSON convention for boolean properties
      json["assessed_assignment"] = grading_standard.assessed_assignment?
    end
  end

  def base_grading_scheme_json(grading_standard, user)
    grading_standard.as_json(methods: JSON_METHODS,
                             include_root: false,
                             only: json_serialized_fields,
                             permissions: { user: }).tap do |json|
      # because GradingStandard serializes its id as a number instead of a string
      json["id"] = json["id"].to_s
      json["data"] = formatted_data(grading_standard)
    end
  end

  private

  # because GradingStandard serializes its data rows to JSON as an array of arrays: [["A", .90], ["B", .80]]
  # instead of our desired format of an array of objects with name/value pairs [{name: "A", value: .90], {name: "B", value: .80}]
  def formatted_data(grading_standard)
    grading_standard.data.map do |grading_standard_data_row|
      { name: grading_standard_data_row[0],
        value: grading_standard_data_row[1] }
    end
  end
end
