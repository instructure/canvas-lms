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
#

class RubricCSVImporter
  include RubricImporterErrors
  def initialize(attachment)
    @attachment = attachment
  end
  attr_reader :attachment

  def parse
    rubric_by_name = Hash.new { |hash, key| hash[key] = [] }
    rating_indices = {}

    csv_stream do |row|
      rating_indices = parse_rating_headers(row) if rating_indices.empty?
      rubric_by_name[row["Rubric Name"]] << parse_row(row, rating_indices)
    end

    rubric_by_name
  end

  def parse_rating_headers(row)
    rating_indices = {
      description_indices: [],
      long_description_indices: [],
      points_indices: []
    }

    row.headers.each_with_index do |header, index|
      next if header.nil?

      if header.downcase.include?("rating name")
        rating_indices[:description_indices] << index
      elsif header.downcase.include?("rating description")
        rating_indices[:long_description_indices] << index
      elsif header.downcase.include?("rating points")
        rating_indices[:points_indices] << index
      end
    end

    rating_indices
  end

  def parse_row(row, rating_indices)
    ratings = rating_indices[:description_indices].map.with_index do |header_index, index|
      rating_description = row[header_index]
      next if rating_description.nil?

      {
        description: rating_description,
        long_description: row[rating_indices[:long_description_indices][index]],
        points: row[rating_indices[:points_indices][index]].tr(",", ".").to_f.round(2)
      }
    end.compact

    new_row = {
      description: row["Criteria Name"],
      long_description: row["Criteria Description"],
      ratings:
    }

    unless row["Criteria Enable Range"].nil?
      new_row[:criterion_use_range] = ["true", "1"].include?(row["Criteria Enable Range"].downcase)
    end

    new_row
  end

  def csv_stream(&)
    csv_file = attachment.open
    csv_parse_options = {
      col_sep: ",",
      headers: true
    }
    CSV.foreach(csv_file.path, **csv_parse_options, &)
  end
end
