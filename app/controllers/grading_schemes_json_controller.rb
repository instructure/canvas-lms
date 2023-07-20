# frozen_string_literal: true

#
# Copyright (C) 2023 - present Instructure, Inc.
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

class GradingSchemesJsonController < ApplicationController
  JSON_METHODS =
    %i[assessed_assignment? context_name].freeze
  GRADING_SCHEMES_LIMIT = 100
  before_action :require_context
  before_action :require_user
  def detail_list
    if authorized_action(@context, @current_user, @context.grading_standard_read_permission)
      grading_standards = GradingStandard.for(@context).sorted.limit(GRADING_SCHEMES_LIMIT)
      respond_to do |format|
        format.json do
          render json: grading_standards.map { |grading_standard|
            GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user)
          }
        end
      end
    end
  end

  def summary_list
    if authorized_action(@context, @current_user, @context.grading_standard_read_permission)
      grading_standards = GradingStandard.for(@context).sorted.limit(GRADING_SCHEMES_LIMIT)
      respond_to do |format|
        format.json do
          render json: grading_standards.map { |grading_standard|
                         GradingSchemesJsonController.to_grading_scheme_summary_json(grading_standard)
                       }
        end
      end
    end
  end

  def show
    if authorized_action(@context, @current_user, @context.grading_standard_read_permission)
      grading_standard = GradingStandard.for(@context).find(params[:id])
      respond_to do |format|
        format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
      end
    end
  end

  def show_default_grading_scheme
    respond_to do |format|
      format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(GradingSchemesJsonController.default_canvas_grading_standard(@context), @current_user) }
    end
  end

  def create
    if authorized_action(@context, @current_user, :manage_grades)
      grading_standard = @context.grading_standards.build(grading_scheme_payload)

      respond_to do |format|
        if grading_standard.save
          format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
        else
          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def update
    grading_standard = GradingStandard.for(@context).find(params[:id])
    if authorized_action(grading_standard, @current_user, :manage)
      grading_standard.user = @current_user

      respond_to do |format|
        if grading_standard.update(grading_scheme_payload)
          format.json { render json: GradingSchemesJsonController.to_grading_scheme_json(grading_standard, @current_user) }
        else
          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def destroy
    grading_standard = GradingStandard.for(@context).find(params[:id])
    if authorized_action(grading_standard, @current_user, :manage)
      respond_to do |format|
        if grading_standard.destroy
          format.json { render json: {} }
        else
          format.json { render json: grading_standard.errors, status: :bad_request }
        end
      end
    end
  end

  def self.to_grading_scheme_summary_json(grading_standard)
    {
      title: grading_standard.title,
      id: grading_standard.id.to_s
    }.as_json
  end

  def self.to_grading_scheme_json(grading_standard, user)
    grading_standard.as_json({ methods: JSON_METHODS,
                               include_root: false }
                             .merge(only: json_serialized_fields,
                                    permissions: { user: }))
                    .tap do |json|
      # because GradingStandard generates the JSON property with a '?' on the end of it,
      # instead of using the JSON convention for boolean properties
      json["assessed_assignment"] = json["assessed_assignment?"]
      json.delete "assessed_assignment?"

      # because GradingStandard serializes its id as a number instead of a string
      json["id"] = json["id"].to_s

      # because GradingStandard serializes its data rows to JSON as an array of arrays: [["A", .90], ["B", .80]]
      # instead of our desired format of an array of objects with name/value pairs [{name: "A", value: .90], {name: "B", value: .80}]
      json["data"] = grading_standard["data"].map { |grading_standard_data_row| { name: grading_standard_data_row[0], value: grading_standard_data_row[1] } }
    end
  end

  def self.to_grading_standard_data(grading_scheme_json_data)
    # converts a GradingScheme UI model's data field format from:
    # [{"name": "A", "value": .94}, {"name": "B", "value": .84}, ]
    # to the GradingStandard ActiveRecord's data field format:
    # { "A" => 0.94, "B" => .84, }
    grading_standard_data = {}
    grading_scheme_json_data.map do |grading_scheme_data_row|
      grading_standard_data[grading_scheme_data_row["name"]] = grading_scheme_data_row["value"]
    end
    grading_standard_data
  end

  def self.json_serialized_fields
    if Account.site_admin.feature_enabled?(:points_based_grading_schemes)
      %w[id title scaling_factor points_based context_type context_id]
    else
      %w[id title context_type context_id]
    end
  end

  def self.default_canvas_grading_standard(context)
    grading_standard_data = GradingStandard.default_grading_standard
    props = {}
    props["title"] = I18n.t("Default Canvas Grading Scheme")
    props["data"] = grading_standard_data
    if Account.site_admin.feature_enabled?(:points_based_grading_schemes)
      props["scaling_factor"] = 1.0
      props["points_based"] = false
    end
    context.grading_standards.build(props)
  end

  private

  def grading_scheme_payload
    if Account.site_admin.feature_enabled?(:points_based_grading_schemes)
      { title: params[:title],
        data: GradingSchemesJsonController.to_grading_standard_data(params[:data]),
        points_based: params[:points_based],
        scaling_factor: params[:scaling_factor] }
    else
      { title: params[:title],
        data: GradingSchemesJsonController.to_grading_standard_data(params[:data]) }
    end
  end
end
