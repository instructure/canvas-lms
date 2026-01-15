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

class RubricAssessmentCSVImporter
  include RubricImporterErrors

  def initialize(attachment, rubric, rubric_association)
    @attachment = attachment
    @rubric = rubric
    @rubric_association = rubric_association
  end
  attr_reader :attachment

  def parse
    assessment_by_student = Hash.new { |hash, key| hash[key] = [] }
    criteria_assessment_indices = {}
    @criteria_ratings_lookup = build_criteria_ratings_lookup if @rubric_association.hide_points

    csv_stream do |row|
      criteria_assessment_indices = parse_assessment_headers(row) if criteria_assessment_indices.empty?
      assessment_by_student[row["Student Id"]] = parse_row(row, criteria_assessment_indices)
    end

    assessment_by_student
  end

  def build_criteria_ratings_lookup
    @rubric.criteria.each_with_object({}) do |criterion, hash|
      hash[criterion[:id]] = criterion[:ratings]&.each_with_object({}) do |rating, ratings_hash|
        ratings_hash[rating[:description]] = rating[:points]
      end || {}
    end
  end

  def parse_assessment_headers(row)
    criteria_name_indices = @rubric.criteria.each_with_object({}) do |obj, hash|
      hash[obj[:description]] = { id: obj[:id] }
    end

    criteria_separator = " - "

    row.headers.each_with_index do |header, index|
      next if header.nil?

      before, separator, after = header.rpartition(criteria_separator)

      if criteria_name_indices[before] && separator == criteria_separator
        criteria_name_indices[before][after] = index
      end
    end

    criteria_name_indices
  end

  def parse_row(row, criteria_assessment_indices)
    criteria_assessment_indices.each.filter_map do |_, criteria_indices|
      next if criteria_indices[:id].nil?

      assessment_hash = {
        id: criteria_indices[:id],
        comments: row[criteria_indices["Comments"]]
      }

      rating_description = row[criteria_indices["Rating"]]

      if @rubric_association.hide_points && @criteria_ratings_lookup
        # When points are hidden, use hash lookup to find the rating points by description
        if rating_description && @criteria_ratings_lookup[criteria_indices[:id]]
          assessment_hash[:points] = @criteria_ratings_lookup[criteria_indices[:id]][rating_description]
        end
      else
        assessment_hash[:points] = row[criteria_indices["Points"]]
      end

      unless @rubric.free_form_criterion_comments
        assessment_hash[:rating] = rating_description
      end

      assessment_hash
    end
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
